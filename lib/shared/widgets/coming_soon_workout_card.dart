import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../features/workouts/models/workout.dart';

/// Muestra la próxima rutina programada en estilo "próximamente".
/// Se usa cuando el usuario ya completó la rutina del día de hoy.
class ComingSoonWorkoutCard extends StatelessWidget {
  final Workout workout;

  /// Texto que describe cuándo estará disponible, p.ej. "Disponible mañana"
  /// o "Disponible el miércoles".
  final String availableLabel;

  const ComingSoonWorkoutCard({
    super.key,
    required this.workout,
    this.availableLabel = 'Disponible mañana',
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 400),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 10 * (1 - value)),
          child: child,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.18),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            // Ícono izquierdo con checkmark
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.green.withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              child: const Icon(Icons.check, size: 20, color: Colors.green),
            ),
            const SizedBox(width: 12),
            // Texto central
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    workout.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withOpacity(0.65),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.timer_outlined,
                          size: 12,
                          color: AppColors.textSecondary.withOpacity(0.7)),
                      const SizedBox(width: 3),
                      Text(
                        '${workout.duration} min',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(Icons.calendar_today_outlined,
                          size: 12,
                          color: AppColors.primary.withOpacity(0.7)),
                      const SizedBox(width: 3),
                      Text(
                        availableLabel,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.primary.withOpacity(0.85),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Badge derecho
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                ),
              ),
              child: Text(
                '¡Buen trabajo!',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary.withOpacity(0.85),
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
