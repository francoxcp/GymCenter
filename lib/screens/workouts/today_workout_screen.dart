import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../config/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/workout_provider.dart';
import '../../models/exercise.dart';
import '../../widgets/primary_button.dart';
import 'workout_summary_screen.dart';

class TodayWorkoutScreen extends StatefulWidget {
  const TodayWorkoutScreen({super.key});

  @override
  State<TodayWorkoutScreen> createState() => _TodayWorkoutScreenState();
}

class _TodayWorkoutScreenState extends State<TodayWorkoutScreen> {
  int _currentExerciseIndex = 0;
  List<List<bool>> _completedSets = [];
  bool _isResting = false;
  int _remainingSeconds = 0;
  Timer? _timer;
  DateTime? _startTime;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startRestTimer(int seconds) {
    setState(() {
      _isResting = true;
      _remainingSeconds = seconds;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _isResting = false;
          timer.cancel();
        }
      });
    });
  }

  void _toggleSet(int exerciseIndex, int setIndex) {
    setState(() {
      _completedSets[exerciseIndex][setIndex] =
          !_completedSets[exerciseIndex][setIndex];
    });
  }

  void _nextExercise(Exercise currentExercise, workout) {
    if (_currentExerciseIndex < _completedSets.length - 1) {
      setState(() {
        _currentExerciseIndex++;
      });
    } else {
      _showWorkoutSummary(workout);
    }
  }

  void _showWorkoutSummary(workout) {
    final endTime = DateTime.now();
    final durationMinutes =
        _startTime != null ? endTime.difference(_startTime!).inMinutes : 0;

    // Calcular calorías quemadas (estimación: 5 cal/min)
    final caloriesBurned = (durationMinutes * 5).toInt();

    // Calcular volumen total (estimación basada en ejercicios)
    double totalVolume = 0;
    for (var exercise in workout.exercises) {
      final estimatedWeight = _estimateWeight(exercise.name);
      totalVolume += (exercise.sets * exercise.reps * estimatedWeight);
    }

    // Navegar a la pantalla de resumen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => WorkoutSummaryScreen(
          workout: workout,
          durationMinutes: durationMinutes,
          caloriesBurned: caloriesBurned,
          totalVolume: totalVolume,
        ),
      ),
    );
  }

  int _estimateWeight(String exerciseName) {
    final name = exerciseName.toLowerCase();
    if (name.contains('sentadilla') || name.contains('squat')) return 85;
    if (name.contains('press') || name.contains('banco')) return 85;
    if (name.contains('peso muerto') || name.contains('deadlift')) return 90;
    if (name.contains('remo')) return 110;
    if (name.contains('dominada') || name.contains('pull')) return 0;
    if (name.contains('burpee') || name.contains('jumping')) return 0;
    return 50;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final workoutProvider = Provider.of<WorkoutProvider>(context);
    final currentUser = authProvider.currentUser;

    if (currentUser?.assignedWorkoutId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mi Rutina de Hoy'),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.fitness_center_outlined,
                  size: 80,
                  color: AppColors.textSecondary,
                ),
                SizedBox(height: 24),
                Text(
                  'No tienes rutina asignada',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12),
                Text(
                  'Contacta a tu entrenador para que te asigne una rutina',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final workout =
        workoutProvider.getWorkoutById(currentUser!.assignedWorkoutId!);

    if (workout == null || workout.exercises.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mi Rutina de Hoy'),
        ),
        body: const Center(
          child: Text(
            'Error al cargar la rutina',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    // Inicializar sets completados
    if (_completedSets.isEmpty) {
      _completedSets = workout.exercises
          .map((e) => List.generate(e.sets, (_) => false))
          .toList();
      _startTime = DateTime.now();
    }

    final currentExercise = workout.exercises[_currentExerciseIndex];
    final progress = (_currentExerciseIndex + 1) / workout.exercises.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'MI RUTINA DE HOY',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              workout.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Progress Bar
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.surface,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 6,
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Exercise Counter
                  Text(
                    'Ejercicio ${_currentExerciseIndex + 1} de ${workout.exercises.length}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Exercise Name
                  Text(
                    currentExercise.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Muscle Group Tag
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primary),
                    ),
                    child: Text(
                      currentExercise.muscleGroup.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        letterSpacing: 1,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Video Placeholder
                  Container(
                    height: 220,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.play_circle_outline,
                            size: 80,
                            color: AppColors.primary,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Video Tutorial',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Description
                  if (currentExercise.description != null) ...[
                    const Text(
                      'Instrucciones:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentExercise.description!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Sets Info
                  Row(
                    children: [
                      _InfoCard(
                        icon: Icons.fitness_center,
                        label: 'Series',
                        value: currentExercise.sets.toString(),
                      ),
                      const SizedBox(width: 12),
                      _InfoCard(
                        icon: Icons.repeat,
                        label: 'Reps',
                        value: currentExercise.reps.toString(),
                      ),
                      const SizedBox(width: 12),
                      _InfoCard(
                        icon: Icons.timer,
                        label: 'Descanso',
                        value: '${currentExercise.restSeconds}s',
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Rest Timer
                  if (_isResting) ...[
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'DESCANSANDO',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _remainingSeconds.toString(),
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const Text(
                            'segundos',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Sets Checklist
                  const Text(
                    'Marca las series completadas:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ...List.generate(currentExercise.sets, (setIndex) {
                    final isCompleted =
                        _completedSets[_currentExerciseIndex][setIndex];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () {
                          _toggleSet(_currentExerciseIndex, setIndex);
                          if (!isCompleted &&
                              setIndex < currentExercise.sets - 1) {
                            _startRestTimer(currentExercise.restSeconds);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? AppColors.primary.withOpacity(0.2)
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isCompleted
                                  ? AppColors.primary
                                  : AppColors.surface,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isCompleted
                                    ? Icons.check_circle
                                    : Icons.circle_outlined,
                                color: isCompleted
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                                size: 28,
                              ),
                              const SizedBox(width: 16),
                              Text(
                                'Serie ${setIndex + 1}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isCompleted
                                      ? AppColors.primary
                                      : Colors.white,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${currentExercise.reps} reps',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 32),

                  // Next Exercise Button
                  PrimaryButton(
                    text: _currentExerciseIndex < workout.exercises.length - 1
                        ? 'SIGUIENTE EJERCICIO'
                        : 'FINALIZAR RUTINA',
                    onPressed: () => _nextExercise(currentExercise, workout),
                    icon: _currentExerciseIndex < workout.exercises.length - 1
                        ? Icons.arrow_forward
                        : Icons.check,
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
