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
  final double volumeKg;
  final int setsDone;
  final int exercises;
  final int newRecords;
  final DateTime date;
  /// Marca del gimnasio o entrenador (multi-cliente)
  final String brandName;
  final String? brandLogo;

  const ShareSummaryData({
    this.brandName = 'GYMLAB',
    this.brandLogo,
    required this.workoutName,
    required this.memberName,
    required this.durationMinutes,
    required this.volumeKg,
    required this.setsDone,
    required this.exercises,
    required this.newRecords,
    required this.date,
  });
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

/// Tarjeta vertical (formato historia) con los datos del entreno.
class SummaryShareCard extends StatelessWidget {
  final ShareSummaryData data;
  const SummaryShareCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final lbs = data.volumeKg * 2.20462;
    final volume = lbs >= 1000
        ? '${(lbs / 1000).toStringAsFixed(1)}k'
        : lbs.toStringAsFixed(0);
    const months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago',
      'sep', 'oct', 'nov', 'dic'];
    final date =
        '${data.date.day} ${months[data.date.month - 1]} ${data.date.year}';
    return Container(
      width: 300,
      height: 480,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A1A), Color(0xFF000000)],
        ),
        border: Border.all(color: _kYellow, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: data.brandLogo != null
                  ? Image.network(data.brandLogo!, width: 36, height: 36, fit: BoxFit.cover)
                  : Image.asset('assets/icons/app_icon.png', width: 36, height: 36),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(data.brandName.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: _kYellow,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5)),
            ),
          ]),
          const Spacer(),
          const Text('ENTRENO COMPLETADO',
              style: TextStyle(
                  color: Colors.white70, fontSize: 12, letterSpacing: 2)),
          const SizedBox(height: 6),
          Text(data.workoutName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  height: 1.1,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 20),
          Row(children: [
            _stat('${data.durationMinutes}', 'min'),
            _stat(volume, 'lbs'),
            _stat('${data.setsDone}', 'series'),
          ]),
          if (data.newRecords > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber),
              ),
              child: Text(
                '🏆 ${data.newRecords} récord${data.newRecords == 1 ? '' : 's'} personal${data.newRecords == 1 ? '' : 'es'}',
                style: const TextStyle(
                    color: Colors.amber, fontWeight: FontWeight.bold),
              ),
            ),
          ],
          const Spacer(),
          Text(data.memberName,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600)),
          Text(date,
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: const TextStyle(
                    color: _kYellow,
                    fontSize: 26,
                    fontWeight: FontWeight.w900)),
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      );
}
