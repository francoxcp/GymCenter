import 'package:flutter/material.dart';
import '../../core/l10n/app_l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../features/workouts/models/workout.dart';

/// Muestra la próxima rutina programada en estilo "próximamente".
/// Se usa cuando el usuario ya completó la rutina del día de hoy.
class ComingSoonWorkoutCard extends StatelessWidget {
  final Workout workout;

  /// Texto que describe cuándo estará disponible, p.ej. "Disponible mañana"
  /// o "Disponible el miércoles".
  final String availableLabel;

  /// Si [compact] es true, muestra un card pequeño tipo fila (para listas).
  final bool compact;

  const ComingSoonWorkoutCard({
    super.key,
    required this.workout,
    this.availableLabel = '',
    this.compact = false,
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
      child: compact ? _buildCompact(context) : _buildFull(context),
    );
  }

  Widget _buildCompact(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.green.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: const Icon(Icons.check, size: 20, color: Colors.green),
          ),
          const SizedBox(width: 12),
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
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(Icons.timer_outlined,
                        size: 12,
                        color: AppColors.textSecondary.withValues(alpha: 0.7)),
                    const SizedBox(width: 3),
                    Text(
                      '${workout.duration} min',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(Icons.calendar_today_outlined,
                        size: 12, color: AppColors.primary.withValues(alpha: 0.7)),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        availableLabel.isNotEmpty
                            ? availableLabel
                            : l10n.availableTomorrow,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.primary.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Text(
              l10n.goodJob,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.primary.withValues(alpha: 0.85),
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFull(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.22),
          width: 1.2,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila superior: ícono de logro + badge "¡Buen trabajo!"
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.45),
                    width: 1.5,
                  ),
                ),
                child: const Icon(Icons.check_circle_outline,
                    size: 22, color: Colors.green),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.workoutCompletedBanner,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.green.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  l10n.goodJob,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary.withValues(alpha: 0.9),
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 12),

          // Nombre de la rutina
          Text(
            l10n.nextRoutineLabelUpper,
            style: TextStyle(
              fontSize: 10,
              color: AppColors.primary.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            workout.name,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.white.withValues(alpha: 0.75),
              letterSpacing: 0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 10),

          // Info de duración, ejercicios y cuándo disponible
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                icon: Icons.timer_outlined,
                label: '${workout.duration} min',
              ),
              _InfoChip(
                icon: Icons.fitness_center,
                label: l10n.exerciseCountSimple(workout.exerciseCount),
              ),
              _InfoChip(
                icon: Icons.calendar_today_outlined,
                label: availableLabel.isNotEmpty
                    ? availableLabel
                    : l10n.availableTomorrow,
                highlight: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool highlight;

  const _InfoChip({
    required this.icon,
    required this.label,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = highlight
        ? AppColors.primary.withValues(alpha: 0.85)
        : AppColors.textSecondary.withValues(alpha: 0.75);
    final bg = highlight
        ? AppColors.primary.withValues(alpha: 0.1)
        : Colors.white.withValues(alpha: 0.05);
    final border = highlight
        ? AppColors.primary.withValues(alpha: 0.3)
        : Colors.white.withValues(alpha: 0.08);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: highlight ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
