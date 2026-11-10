import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/l10n/app_l10n.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../providers/workout_provider.dart';
import '../models/superset.dart';
import '../widgets/superset_editor.dart';
import '../providers/workout_progress_provider.dart';
import '../../auth/providers/auth_provider.dart';
import 'edit_workout_screen.dart';
import '../../../shared/navigation/safe_pop.dart';

class WorkoutDetailReadonlyScreen extends StatefulWidget {
  final String workoutId;

  const WorkoutDetailReadonlyScreen({
    super.key,
    required this.workoutId,
  });

  @override
  State<WorkoutDetailReadonlyScreen> createState() =>
      _WorkoutDetailReadonlyScreenState();
}

class _WorkoutDetailReadonlyScreenState
    extends State<WorkoutDetailReadonlyScreen> {
  bool _isPopping = false;

  void _navigateBack() {
    if (_isPopping) return;
    _isPopping = true;
    context.popOrGo('/workouts');
  }

  @override
  void initState() {
    super.initState();
    // Cargar ejercicios al abrir la pantalla (si no están en memoria)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkoutProvider>().ensureExercisesLoaded(widget.workoutId);
    });
  }

  Future<void> _handlePlay(
    BuildContext context,
    WorkoutProgressProvider progressProvider,
  ) async {
    final assignedId =
        context.read<AuthProvider>().currentUser?.assignedWorkoutId;
    if (widget.workoutId == assignedId) {
      context.push('/today-workout');
      return;
    }
    if (progressProvider.hasProgress) {
      final l10n = AppL10n.of(context);
      final choice = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(l10n.routineInProgressTitle,
              style: TextStyle(color: AppColors.textPrimary)),
          content: Text(
            l10n.routineInProgressMsg,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'cancel'),
              child: Text(l10n.cancel,
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'continue_assigned'),
              child: Text(l10n.continueInProgress,
                  style: TextStyle(color: AppColors.primaryText)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'start_extra'),
              child: Text(l10n.startThisLabel,
                  style: TextStyle(color: AppColors.textPrimary)),
            ),
          ],
        ),
      );
      if (!context.mounted) return;
      if (choice == 'continue_assigned') {
        context.push('/today-workout');
      } else if (choice == 'start_extra') {
        context.push('/today-workout?workoutId=${widget.workoutId}');
      }
    } else {
      context.push('/today-workout?workoutId=${widget.workoutId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final workoutProvider = Provider.of<WorkoutProvider>(context);
    final workout = workoutProvider.getWorkoutById(widget.workoutId);

    if (workout == null) {
      final l10n = AppL10n.of(context);
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.workoutLabel),
        ),
        body: Center(
          child: Text(
            l10n.routineNotFound,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return Consumer2<AuthProvider, WorkoutProgressProvider>(
      builder: (context, authProvider, progressProvider, _) {
        final l10n = AppL10n.of(context);
        final currentUserId = authProvider.currentUser?.id;
        final canManage =
            authProvider.isAdmin || workout.createdBy == currentUserId;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _navigateBack();
          },
          child: Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: l10n.goBackTooltip,
                onPressed: _navigateBack,
              ),
              title: Text(
                workout.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Barra de acciones fija al fondo
            bottomNavigationBar: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Iniciar Rutina — siempre visible
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
                        label: Text(
                          l10n.startRoutine,
                          style: const TextStyle(
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
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        EditWorkoutScreen(workout: workout),
                                  ),
                                );
                                if (result == true && context.mounted) {
                                  context.popOrGo('/workouts');
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primaryText,
                                side:
                                    BorderSide(color: AppColors.primaryText),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              label: Text(l10n.edit),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                if (_isPopping) return;
                                final wp = context.read<WorkoutProvider>();
                                final shouldDelete = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    backgroundColor: AppColors.surface,
                                    title: Text(
                                      l10n.deleteRoutineTitle,
                                      style:
                                          TextStyle(color: AppColors.textPrimary),
                                    ),
                                    content: Text(
                                      l10n.deleteWorkoutConfirm(workout.name),
                                      style: TextStyle(
                                          color: AppColors.textSecondary),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: Text(
                                            AppL10n.of(context).cancelLabel,
                                            style: TextStyle(
                                                color:
                                                    AppColors.textSecondary)),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: Text(
                                            AppL10n.of(context).deleteConfirm,
                                            style: TextStyle(
                                                color: Colors.redAccent)),
                                      ),
                                    ],
                                  ),
                                );
                                if (shouldDelete == true && context.mounted) {
                                  try {
                                    await wp.deleteWorkout(widget.workoutId);
                                    if (context.mounted) {
                                      AppSnackbar.success(context,
                                          AppL10n.of(context).routineDeletedOk);
                                      context.popOrGo('/workouts');
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      AppSnackbar.error(
                                          context,
                                          AppL10n.of(context)
                                              .errorDeleting(e.toString()));
                                    }
                                  }
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.redAccent,
                                side: BorderSide(
                                    color: Colors.redAccent
                                        .withValues(alpha: 0.6)),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                              icon: const Icon(Icons.delete_outline, size: 18),
                              label: Text(l10n.delete),
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
                          AppColors.primary.withValues(alpha: 0.3),
                          AppColors.background,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.fitness_center,
                          size: 80,
                          color: AppColors.primaryText,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          workout.name,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildInfoCard(
                              l10n.durationLabel,
                              '${workout.duration} min',
                              Icons.access_time,
                            ),
                            _buildInfoCard(
                              l10n.exercisesLabel,
                              '${workout.exerciseCount}',
                              Icons.fitness_center,
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
                        Text(
                          l10n.routineExercises,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (workout.exercises.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Text(
                                l10n.noExercises,
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
                            final span =
                                supersetSpanAt(workout.exercises, index);
                            final card = _ExerciseCard(
                              number: index + 1,
                              letter: span?.labelFor(index),
                              name: exercise.name,
                              sets: exercise.sets,
                              reps: exercise.reps,
                              seconds: exercise.durationSeconds,
                              restTime: exercise.restSeconds,
                            );
                            if (span == null) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: card,
                              );
                            }
                            // Superserie: cabecera + riel que une los ejercicios
                            return Padding(
                              padding: EdgeInsets.only(
                                  bottom: index == span.end ? 12 : 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (index == span.start)
                                    SupersetHeader(
                                      size: span.size,
                                      kind: groupKindAt(workout.exercises, index),
                                      rounds: exercise.sets,
                                      restSeconds: exercise.restSeconds,
                                      innerRestSeconds: exercise.groupRestSeconds,
                                    ),
                                  Container(
                                    padding: EdgeInsets.only(
                                        left: 8,
                                        bottom: index == span.end ? 0 : 8),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        left: BorderSide(
                                            color: AppColors.primary,
                                            width: kSupersetRailWidth),
                                      ),
                                    ),
                                    child: card,
                                  ),
                                ],
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
            border: Border.all(color: AppColors.primaryText.withValues(alpha: 0.3)),
          ),
          child: Icon(
            icon,
            color: AppColors.primaryText,
            size: 30,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
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
  final String? letter; // A, B, C… dentro de una superserie
  final String name;
  final int sets;
  final int reps;
  /// > 0 si el ejercicio va por tiempo.
  final int seconds;
  final int restTime;

  const _ExerciseCard({
    required this.number,
    this.letter,
    required this.name,
    required this.sets,
    required this.reps,
    this.seconds = 0,
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
          color: AppColors.primaryText.withValues(alpha: 0.2),
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
                letter ?? '$number',
                style: TextStyle(
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (letter == null) ...[
                      _buildDetail(
                          Icons.repeat, AppL10n.of(context).setsCount(sets)),
                      const SizedBox(width: 16),
                    ],
                    _buildDetail(Icons.fitness_center,
                        seconds > 0
                            ? '$seconds s'
                            : AppL10n.of(context).repsCount(reps)),
                    if (letter == null) ...[
                      const SizedBox(width: 16),
                      _buildDetail(Icons.timer, '${restTime}s'),
                    ],
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
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
