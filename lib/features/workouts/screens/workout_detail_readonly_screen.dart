import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/workout_provider.dart';
import '../providers/workout_progress_provider.dart';
import '../../auth/providers/auth_provider.dart';
import 'edit_workout_screen.dart';

class WorkoutDetailReadonlyScreen extends StatelessWidget {
  final String workoutId;

  const WorkoutDetailReadonlyScreen({
    super.key,
    required this.workoutId,
  });

  Future<void> _handlePlay(
    BuildContext context,
    WorkoutProgressProvider progressProvider,
  ) async {
    final assignedId =
        context.read<AuthProvider>().currentUser?.assignedWorkoutId;
    if (workoutId == assignedId) {
      context.push('/today-workout');
      return;
    }
    if (progressProvider.hasProgress) {
      final choice = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Rutina en Progreso',
              style: TextStyle(color: Colors.white)),
          content: const Text(
            'Tienes una rutina en curso. ¿Quieres continuar esa o iniciar esta como extra?',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'cancel'),
              child: const Text('Cancelar',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'continue_assigned'),
              child: const Text('Continuar en progreso',
                  style: TextStyle(color: AppColors.primary)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'start_extra'),
              child: const Text('Iniciar esta',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (!context.mounted) return;
      if (choice == 'continue_assigned') {
        context.push('/today-workout');
      } else if (choice == 'start_extra') {
        context.push('/today-workout?workoutId=$workoutId');
      }
    } else {
      context.push('/today-workout?workoutId=$workoutId');
    }
  }

  Color _getLevelColor(String level) {
    switch (level) {
      case 'Principiante':
        return AppColors.badgePrincipiante;
      case 'Intermedio':
        return AppColors.badgeIntermedio;
      case 'Avanzado':
        return AppColors.badgeAvanzado;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final workoutProvider = Provider.of<WorkoutProvider>(context);
    final workout = workoutProvider.getWorkoutById(workoutId);

    if (workout == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Rutina'),
        ),
        body: const Center(
          child: Text(
            'Rutina no encontrada',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return Consumer2<AuthProvider, WorkoutProgressProvider>(
      builder: (context, authProvider, progressProvider, _) {
        final currentUserId = authProvider.currentUser?.id;
        final canManage =
            authProvider.isAdmin || workout.createdBy == currentUserId;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            title: Text(workout.name),
          ),
          // Barra de acciones fija al fondo
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ▶ Iniciar Rutina — siempre visible
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () => _handlePlay(context, progressProvider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded, size: 26),
                      label: const Text(
                        'INICIAR RUTINA',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                  // Editar / Eliminar — solo si admin o dueño
                  if (canManage) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final wp = context.read<WorkoutProvider>();
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      EditWorkoutScreen(workout: workout),
                                ),
                              );
                              if (result == true && context.mounted) {
                                wp.loadWorkouts(
                                  forceRefresh: true,
                                  userId: currentUserId,
                                  isAdmin: authProvider.isAdmin,
                                );
                                context.pop();
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text('Editar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final wp = context.read<WorkoutProvider>();
                              final shouldDelete = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: AppColors.surface,
                                  title: const Text(
                                    '¿Eliminar rutina?',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  content: Text(
                                    '¿Estás seguro de eliminar "${workout.name}"? Esta acción no se puede deshacer.',
                                    style: const TextStyle(
                                        color: AppColors.textSecondary),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text('Cancelar',
                                          style: TextStyle(
                                              color: AppColors.textSecondary)),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('Eliminar',
                                          style: TextStyle(
                                              color: Colors.redAccent)),
                                    ),
                                  ],
                                ),
                              );
                              if (shouldDelete == true && context.mounted) {
                                try {
                                  await wp.deleteWorkout(workoutId);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Rutina eliminada correctamente'),
                                        backgroundColor: AppColors.primary,
                                      ),
                                    );
                                    context.pop();
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error al eliminar: $e'),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: BorderSide(
                                  color: Colors.redAccent.withOpacity(0.6)),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: const Text('Eliminar'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.3),
                        AppColors.background,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.fitness_center,
                        size: 80,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        workout.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _getLevelColor(workout.level),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          workout.level.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildInfoCard(
                            'Duración',
                            '${workout.duration} min',
                            Icons.access_time,
                          ),
                          _buildInfoCard(
                            'Ejercicios',
                            '${workout.exerciseCount}',
                            Icons.fitness_center,
                          ),
                          _buildInfoCard(
                            'Nivel',
                            workout.level,
                            Icons.trending_up,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Ejercicios
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ejercicios de la Rutina',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (workout.exercises.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Text(
                              'No hay ejercicios',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        )
                      else
                        ...workout.exercises.asMap().entries.map((entry) {
                          final index = entry.key;
                          final exercise = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ExerciseCard(
                              number: index + 1,
                              name: exercise.name,
                              sets: exercise.sets,
                              reps: exercise.reps,
                              restTime: exercise.restSeconds,
                            ),
                          );
                        }),
                      // Espacio para que el contenido no quede tapado por la barra
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 30,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final int number;
  final String name;
  final int sets;
  final int reps;
  final int restTime;

  const _ExerciseCard({
    required this.number,
    required this.name,
    required this.sets,
    required this.reps,
    required this.restTime,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildDetail(Icons.repeat, '$sets series'),
                    const SizedBox(width: 16),
                    _buildDetail(Icons.fitness_center, '$reps reps'),
                    const SizedBox(width: 16),
                    _buildDetail(Icons.timer, '${restTime}s'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetail(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
