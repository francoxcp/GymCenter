import 'package:flutter/material.dart';
import '../config/theme/app_theme.dart';
import '../models/user_goal.dart';

class GoalProgressCard extends StatelessWidget {
  final UserGoal goal;
  final VoidCallback? onTap;

  const GoalProgressCard({
    super.key,
    required this.goal,
    this.onTap,
  });

  Color _getProgressColor() {
    if (goal.isCompleted) return Colors.green;
    if (goal.progressPercentage >= 75) return AppColors.primary;
    if (goal.progressPercentage >= 50) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _getProgressColor().withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text(
                  goal.icon,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (goal.isExpired)
                        const Text(
                          'Vencida',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      else
                        Text(
                          '${goal.daysRemaining} días restantes',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  '${goal.progressPercentage.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _getProgressColor(),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Barra de progreso
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: goal.progressPercentage / 100,
                backgroundColor: AppColors.surface,
                valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor()),
                minHeight: 12,
              ),
            ),

            const SizedBox(height: 12),

            // Valores
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${goal.currentValue.toStringAsFixed(goal.goalType == 'workouts' ? 0 : 1)} / ${goal.targetValue.toStringAsFixed(goal.goalType == 'workouts' ? 0 : 1)} ${goal.unit}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                if (!goal.isCompleted && !goal.isExpired)
                  Text(
                    'Faltan ${goal.remainingValue.toStringAsFixed(goal.goalType == 'workouts' ? 0 : 1)} ${goal.unit}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 8),

            // Mensaje motivacional
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              decoration: BoxDecoration(
                color: _getProgressColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                goal.motivationalMessage,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _getProgressColor(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
