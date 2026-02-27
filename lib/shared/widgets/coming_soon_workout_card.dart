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
      duration: const Duration(milliseconds: 500),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - value)),
          child: child,
        ),
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.25),
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge "PRÓXIMAMENTE"
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time_filled,
                        size: 13,
                        color: AppColors.primary.withOpacity(0.9),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'PRÓXIMAMENTE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary.withOpacity(0.9),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Nombre de la rutina (atenuado)
                Text(
                  workout.name,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withOpacity(0.7),
                    letterSpacing: 0.3,
                  ),
                ),

                const SizedBox(height: 10),

                // Duración + ejercicios
                Row(
                  children: [
                    Icon(Icons.timer,
                        size: 17,
                        color: AppColors.textSecondary.withOpacity(0.7)),
                    const SizedBox(width: 5),
                    Text(
                      '${workout.duration} min',
                      style: TextStyle(
                        color: AppColors.textSecondary.withOpacity(0.8),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Icon(Icons.fitness_center,
                        size: 17,
                        color: AppColors.textSecondary.withOpacity(0.7)),
                    const SizedBox(width: 5),
                    Text(
                      '${workout.exercises.length} ejercicios',
                      style: TextStyle(
                        color: AppColors.textSecondary.withOpacity(0.8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Etiqueta de disponibilidad
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: AppColors.primary.withOpacity(0.7),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      availableLabel,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.primary.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Botón desactivado — no se puede iniciar hoy
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.05),
                      disabledBackgroundColor: Colors.white.withOpacity(0.07),
                      disabledForegroundColor:
                          AppColors.textSecondary.withOpacity(0.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: AppColors.textSecondary.withOpacity(0.2),
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_clock,
                          size: 18,
                          color: AppColors.textSecondary.withOpacity(0.5),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '¡BUEN TRABAJO HOY!',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            color: AppColors.textSecondary.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Checkmark verde (esquina superior derecha)
          Positioned(
            top: 14,
            right: 14,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.green.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.check,
                size: 18,
                color: Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
