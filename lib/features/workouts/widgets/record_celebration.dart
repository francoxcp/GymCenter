import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/services/share_helper.dart';

/// Celebración de récord personal: el número nuevo entra grande con un
/// estallido de rayos. Se cierra sola a los 4 s o con un toque.
Future<void> showRecordCelebration(
  BuildContext context, {
  required String exerciseName,
  required String weightLabel,
  String? previousLabel,
}) {
  HapticFeedback.heavyImpact();
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Cerrar',
    barrierColor: Colors.black87,
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (ctx, _, __) => _RecordCelebration(
      exerciseName: exerciseName,
      weightLabel: weightLabel,
      previousLabel: previousLabel,
    ),
    transitionBuilder: (ctx, a, _, child) =>
        FadeTransition(opacity: a, child: child),
  );
}

class _RecordCelebration extends StatefulWidget {
  final String exerciseName;
  final String weightLabel;
  final String? previousLabel;
  const _RecordCelebration({
    required this.exerciseName,
    required this.weightLabel,
    this.previousLabel,
  });

  @override
  State<_RecordCelebration> createState() => _RecordCelebrationState();
}

class _RecordCelebrationState extends State<_RecordCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();
  bool _closed = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 4), _close);
  }

  void _close() {
    if (_closed || !mounted) return;
    _closed = true;
    Navigator.of(context).maybePop();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return GestureDetector(
      onTap: _close,
      child: Material(
        color: Colors.transparent,
        child: Center(
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final t = reduceMotion ? 1.0 : _c.value;
              final pop = Curves.elasticOut.transform(t.clamp(0.0, 1.0));
              return SizedBox(
                width: 320,
                height: 380,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (!reduceMotion)
                      CustomPaint(
                        size: const Size(320, 320),
                        painter: _BurstPainter(t, AppColors.primary),
                      ),
                    Transform.scale(
                      scale: 0.6 + 0.4 * pop,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('NUEVO RÉCORD',
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 3)),
                          const SizedBox(height: 6),
                          Text(widget.weightLabel,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 64,
                                  fontWeight: FontWeight.w900,
                                  height: 1,
                                  fontFeatures: [FontFeature.tabularFigures()])),
                          const SizedBox(height: 8),
                          Text(widget.exerciseName,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700)),
                          if (widget.previousLabel != null) ...[
                            const SizedBox(height: 4),
                            Text('Antes: ${widget.previousLabel}',
                                style: const TextStyle(
                                    color: Colors.white60, fontSize: 13)),
                          ],
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      child: Opacity(
                        opacity: t,
                        child: Row(
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                _closed = true;
                                ShareHelper.shareOther(
                                    'Nuevo récord en ${widget.exerciseName}: ${widget.weightLabel}');
                                Navigator.of(context).maybePop();
                              },
                              icon: Icon(Icons.ios_share,
                                  color: AppColors.primary, size: 18),
                              label: const Text('Compartir',
                                  style: TextStyle(color: Colors.white)),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: _close,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.onPrimary,
                              ),
                              child: const Text('Seguir',
                                  style: TextStyle(fontWeight: FontWeight.w800)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Rayos que salen del centro y se desvanecen.
class _BurstPainter extends CustomPainter {
  final double t;
  final Color color;
  _BurstPainter(this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4
      ..color = color.withValues(alpha: (1 - t).clamp(0.0, 1.0));
    const rays = 14;
    final r0 = 60 + 70 * Curves.easeOut.transform(t);
    final r1 = r0 + 26 * (1 - t) + 6;
    for (var i = 0; i < rays; i++) {
      final a = (i / rays) * 2 * math.pi;
      final d = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(c + d * r0, c + d * r1, paint);
    }
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.t != t;
}
