import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/web/web_bridge.dart';

/// Datos de la tarjeta para compartir al terminar una rutina.
class ShareSummaryData {
  final String workoutName;
  final String memberName;
  final int durationMinutes;
  /// Duración exacta (tiempo activo, sin pausas). Si es null se usan minutos.
  final int? durationSeconds;
  final int? calories;
  final double volumeKg;
  final int setsDone;
  final int? repsDone;
  final int exercises;
  final int supersets;
  final int newRecords;
  /// Mejor serie: ejercicio, peso (kg) y repeticiones.
  final String? bestExercise;
  final double? bestWeightKg;
  final int? bestReps;
  final DateTime date;
  /// 'imperial' (lbs) o 'metric' (kg), según la preferencia del socio.
  final String units;
  /// Marca del gimnasio o entrenador (multi-cliente)
  final String brandName;
  final String? brandLogo;

  const ShareSummaryData({
    this.brandName = 'GYMLAB',
    this.brandLogo,
    required this.workoutName,
    required this.memberName,
    required this.durationMinutes,
    this.durationSeconds,
    this.calories,
    required this.volumeKg,
    required this.setsDone,
    this.repsDone,
    required this.exercises,
    this.supersets = 0,
    required this.newRecords,
    this.bestExercise,
    this.bestWeightKg,
    this.bestReps,
    required this.date,
    this.units = 'imperial',
  });

  /// "52:18" / "1:05:09"; sin segundos: "52 min".
  String get durationLabel {
    final secs = durationSeconds;
    if (secs == null) return '$durationMinutes';
    final h = secs ~/ 3600, m = (secs % 3600) ~/ 60, sec = secs % 60;
    String two(int v) => v.toString().padLeft(2, '0');
    return h > 0 ? '$h:${two(m)}:${two(sec)}' : '$m:${two(sec)}';
  }

  bool get metric => units != 'imperial';
  String get unit => metric ? 'kg' : 'lbs';
  double weight(double kg) => metric ? kg : kg * 2.20462;

  /// Volumen corto: 12.4k / 860.
  String get volumeLabel {
    final v = weight(volumeKg);
    return v >= 10000
        ? '${(v / 1000).toStringAsFixed(1)}k'
        : v.toStringAsFixed(0);
  }
}

/// Muestra la vista previa de la tarjeta y el botón para compartirla
/// (WhatsApp, Instagram, etc. desde la hoja nativa del teléfono).
Future<void> showShareSummarySheet(
    BuildContext context, ShareSummaryData data) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => _ShareSheet(data: data),
  );
}

class _ShareSheet extends StatefulWidget {
  final ShareSummaryData data;
  const _ShareSheet({required this.data});

  @override
  State<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<_ShareSheet> {
  final _cardKey = GlobalKey();
  bool _busy = false;

  Future<Uint8List?> _capture() async {
    final boundary =
        _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 3);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes?.buffer.asUint8List();
  }

  Future<void> _share() async {
    setState(() => _busy = true);
    try {
      final png = await _capture();
      if (png == null) return;
      const name = 'gymlab-entreno.png';
      final text = 'Entreno completado en ${widget.data.brandName}';
      if (kIsWeb) {
        final r = await WebBridge.shareFile(
            fileName: name, bytes: png, mimeType: 'image/png', text: text);
        if (r == 'downloaded' && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Imagen descargada. Súbela a tus historias.')));
        }
      } else {
        await Share.shareXFiles(
          [XFile.fromData(png, mimeType: 'image/png', name: name)],
          text: text,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: RepaintBoundary(
                key: _cardKey,
                child: SummaryShareCard(data: widget.data),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _busy ? null : _share,
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.ios_share),
                label: const Text('Compartir',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// La tarjeta siempre usa los colores de marca (fondo negro y amarillo),
// sin importar el tema elegido, porque es una imagen para redes sociales.
const _kYellow = Color(0xFFFFEB00);
const _kMuted = Color(0xFFB0B0B0);
const _kLine = Color(0xFF2A2A2A);

/// Tarjeta vertical 9:16 (historia de Instagram / estado de WhatsApp).
/// La duración es la protagonista; debajo, las marcas del día.
class SummaryShareCard extends StatelessWidget {
  final ShareSummaryData data;
  const SummaryShareCard({super.key, required this.data});

  static const _months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul',
    'ago', 'sep', 'oct', 'nov', 'dic'];

  @override
  Widget build(BuildContext context) {
    final d = data.date;
    final hour = '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    final date = '${d.day} ${_months[d.month - 1]} ${d.year} · $hour';
    final hasClock = data.durationSeconds != null;

    return MediaQuery(
      // La imagen no cambia con el tamaño de letra del teléfono
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Container(
        width: 300,
        height: 533,
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _kLine),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Marca
            Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: data.brandLogo != null
                    ? Image.network(data.brandLogo!, width: 28, height: 28, fit: BoxFit.cover)
                    : Image.asset('assets/icons/app_icon.png', width: 28, height: 28),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(data.brandName.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: _kYellow,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2)),
              ),
            ]),
            const SizedBox(height: 18),
            const Text('ENTRENO COMPLETADO',
                style: TextStyle(
                    color: _kMuted, fontSize: 10, letterSpacing: 2.5,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(data.workoutName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    height: 1.1,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text('${data.exercises} ejercicios',
                style: const TextStyle(color: _kMuted, fontSize: 12)),
            const SizedBox(height: 14),
            // Duración: la protagonista
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(data.durationLabel,
                  style: const TextStyle(
                      color: _kYellow,
                      fontSize: 60,
                      height: 0.95,
                      letterSpacing: -2,
                      fontWeight: FontWeight.w900,
                      fontFeatures: [FontFeature.tabularFigures()])),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(hasClock ? 'TIEMPO\nACTIVO' : 'MIN',
                    style: const TextStyle(
                        color: _kMuted, fontSize: 10, height: 1.2,
                        letterSpacing: 1.5, fontWeight: FontWeight.w700)),
              ),
            ]),
            const SizedBox(height: 18),
            // Marcas del día
            Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: _kLine), bottom: BorderSide(color: _kLine)),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(children: [
                Row(children: [
                  _stat(data.calories != null ? '${data.calories}' : '—', 'kcal estimadas'),
                  _stat(data.volumeLabel, '${data.unit} levantadas'),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  _stat('${data.setsDone}', 'series'),
                  _stat(data.repsDone != null ? '${data.repsDone}' : '${data.exercises}',
                      data.repsDone != null ? 'repeticiones' : 'ejercicios'),
                ]),
              ]),
            ),
            const SizedBox(height: 14),
            if (data.bestExercise != null && data.bestWeightKg != null) ...[
              const Text('MEJOR SERIE',
                  style: TextStyle(
                      color: _kMuted, fontSize: 10, letterSpacing: 2,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text.rich(
                TextSpan(children: [
                  TextSpan(text: '${data.bestExercise} · ',
                      style: const TextStyle(color: Colors.white)),
                  TextSpan(
                      text: '${data.weight(data.bestWeightKg!).toStringAsFixed(0)} ${data.unit}'
                          '${data.bestReps != null ? ' × ${data.bestReps}' : ''}',
                      style: const TextStyle(color: _kYellow, fontWeight: FontWeight.w900)),
                ]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
            ],
            Wrap(spacing: 6, runSpacing: 6, children: [
              if (data.newRecords > 0)
                _chip('${data.newRecords} RÉCORD${data.newRecords == 1 ? '' : 'S'}',
                    filled: true),
              if (data.supersets > 0)
                _chip('${data.supersets} SUPERSERIE${data.supersets == 1 ? '' : 'S'}'),
            ]),
            const Spacer(),
            Text(data.memberName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
            Text(date, style: const TextStyle(color: _kMuted, fontSize: 11)),
            const SizedBox(height: 6),
            const Text('kcal según peso, edad, sexo y ritmo del entreno',
                style: TextStyle(color: Color(0xFF6E6E6E), fontSize: 9)),
          ],
        ),
      ),
    );
  }

  Widget _stat(String value, String label) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    fontFeatures: [FontFeature.tabularFigures()])),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: _kMuted, fontSize: 11)),
          ],
        ),
      );

  Widget _chip(String text, {bool filled = false}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: filled ? _kYellow : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: filled ? _kYellow : _kLine),
        ),
        child: Text(text,
            style: TextStyle(
                color: filled ? Colors.black : _kMuted,
                fontSize: 9.5,
                letterSpacing: 1,
                fontWeight: FontWeight.w800)),
      );
}
