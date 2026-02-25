import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math' as math;
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/workout_provider.dart';
import '../providers/workout_progress_provider.dart';
import '../models/exercise.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/video_player_widget.dart';
import 'workout_summary_screen.dart';
import 'package:confetti/confetti.dart';

class TodayWorkoutScreen extends StatefulWidget {
  const TodayWorkoutScreen({super.key});

  @override
  State<TodayWorkoutScreen> createState() => _TodayWorkoutScreenState();
}

class _TodayWorkoutScreenState extends State<TodayWorkoutScreen>
    with SingleTickerProviderStateMixin {
  int _currentExerciseIndex = 0;
  List<List<bool>> _completedSets = [];
  bool _isResting = false;
  int _remainingSeconds = 0;
  Timer? _timer;
  DateTime? _startTime;

  late PageController _pageController;
  late ConfettiController _confettiController;
  late AnimationController _celebrationController;

  int _lastCompletedSet = -1;
  Timer? _saveDebouncer;
  bool _hasCheckedProgress = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Verificar progreso pendiente después de que se construya el widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPendingProgress();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _saveDebouncer?.cancel();
    _pageController.dispose();
    _confettiController.dispose();
    _celebrationController.dispose();
    super.dispose();
  }

  Future<void> _checkPendingProgress() async {
    if (_hasCheckedProgress) return;
    _hasCheckedProgress = true;

    final authProvider = context.read<AuthProvider>();
    final progressProvider = context.read<WorkoutProgressProvider>();
    final workoutProvider = context.read<WorkoutProvider>();

    if (authProvider.currentUser?.assignedWorkoutId == null) return;

    await progressProvider.loadProgress(authProvider.currentUser!.id);

    if (progressProvider.hasProgress) {
      final progress = progressProvider.currentProgress!;
      final workout = workoutProvider
          .getWorkoutById(authProvider.currentUser!.assignedWorkoutId!);

      if (workout != null && progress.workoutId == workout.id) {
        _showRestoreDialog(progress, workout.name);
      } else {
        // Si el progreso es de otra rutina, eliminarlo
        await progressProvider.deleteProgress();
      }
    }
  }

  void _showRestoreDialog(progress, String workoutName) {
    final progressPercent = progress.progressPercentage.toInt();
    final timeAgo = _getTimeAgoText(progress.timeSinceUpdate);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Rutina Incompleta Encontrada',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              workoutName,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Iniciada $timeAgo',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.fitness_center,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Progreso: $progressPercent%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progressPercent / 100,
              backgroundColor: AppColors.background,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Empezar de cero
              context.read<WorkoutProgressProvider>().deleteProgress();
            },
            child: const Text(
              'Empezar de Cero',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Restaurar progreso
              _restoreProgress(progress);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
            ),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  void _restoreProgress(progress) {
    setState(() {
      _completedSets = progress.completedSets;
      _currentExerciseIndex = progress.exerciseIndex;
      _startTime = progress.startedAt;
    });

    // Animar al ejercicio correcto
    if (_pageController.hasClients) {
      _pageController.jumpToPage(_currentExerciseIndex);
    }

    HapticFeedback.mediumImpact();
  }

  String _getTimeAgoText(Duration duration) {
    if (duration.inMinutes < 60) {
      return 'hace ${duration.inMinutes} minutos';
    } else if (duration.inHours < 24) {
      return 'hace ${duration.inHours} horas';
    } else {
      return 'hace ${duration.inDays} días';
    }
  }

  void _startRestTimer(int seconds) {
    HapticFeedback.mediumImpact();
    setState(() {
      _isResting = true;
      _remainingSeconds = seconds;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
          // Haptic feedback en los últimos 3 segundos
          if (_remainingSeconds <= 3 && _remainingSeconds > 0) {
            HapticFeedback.selectionClick();
          }
        } else {
          _isResting = false;
          HapticFeedback.heavyImpact();
          timer.cancel();
        }
      });
    });
  }

  void _toggleSet(int exerciseIndex, int setIndex) {
    final isCompleted = _completedSets[exerciseIndex][setIndex];

    setState(() {
      _completedSets[exerciseIndex][setIndex] = !isCompleted;
      if (!isCompleted) {
        _lastCompletedSet = setIndex;
      }
    });

    // Auto-guardar progreso (con debounce de 2 segundos)
    _saveProgressDebounced();

    if (!isCompleted) {
      HapticFeedback.heavyImpact();
      _celebrationController.forward(from: 0);

      // Iniciar descanso si no es la última serie
      final totalSets = _completedSets[exerciseIndex].length;
      if (setIndex < totalSets - 1) {
        final workout = context.read<WorkoutProvider>().getWorkoutById(
            context.read<AuthProvider>().currentUser!.assignedWorkoutId!);
        final restSeconds = workout?.exercises[exerciseIndex].restSeconds ?? 60;
        _startRestTimer(restSeconds);
      }
    } else {
      HapticFeedback.lightImpact();
    }
  }

  void _saveProgressDebounced() {
    _saveDebouncer?.cancel();
    _saveDebouncer = Timer(const Duration(seconds: 2), () {
      _saveProgressToDatabase();
    });
  }

  Future<void> _saveProgressToDatabase() async {
    final authProvider = context.read<AuthProvider>();
    final progressProvider = context.read<WorkoutProgressProvider>();

    if (authProvider.currentUser?.assignedWorkoutId == null) return;
    if (_completedSets.isEmpty) return;

    try {
      await progressProvider.saveProgress(
        userId: authProvider.currentUser!.id,
        workoutId: authProvider.currentUser!.assignedWorkoutId!,
        exerciseIndex: _currentExerciseIndex,
        completedSets: _completedSets,
      );
    } catch (e) {
      debugPrint('Error saving progress: $e');
    }
  }

  void _nextExercise(Exercise currentExercise, workout) {
    if (_currentExerciseIndex < _completedSets.length - 1) {
      HapticFeedback.mediumImpact();
      setState(() {
        _currentExerciseIndex++;
      });
      _pageController.animateToPage(
        _currentExerciseIndex,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      _showWorkoutSummary(workout);
    }
  }

  void _previousExercise() {
    if (_currentExerciseIndex > 0) {
      HapticFeedback.mediumImpact();
      setState(() {
        _currentExerciseIndex--;
      });
      _pageController.animateToPage(
        _currentExerciseIndex,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _showWorkoutSummary(workout) {
    // Mostrar confetti de celebración
    _confettiController.play();
    HapticFeedback.heavyImpact();

    Future.delayed(const Duration(milliseconds: 500), () {
      HapticFeedback.heavyImpact();
    });

    final endTime = DateTime.now();
    final durationMinutes =
        _startTime != null ? endTime.difference(_startTime!).inMinutes : 0;

    final caloriesBurned = (durationMinutes * 5).toInt();

    double totalVolume = 0;
    for (var exercise in workout.exercises) {
      final estimatedWeight = _estimateWeight(exercise.name);
      totalVolume += (exercise.sets * exercise.reps * estimatedWeight);
    }

    // Esperar a que termine el confetti antes de navegar
    Future.delayed(const Duration(seconds: 2), () {
      if (context.mounted) {
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
    });
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

    // Calcular sets totales completados
    int totalCompletedSets = 0;
    int totalSets = 0;
    for (var sets in _completedSets) {
      totalCompletedSets += sets.where((s) => s).length;
      totalSets += sets.length;
    }

    return Stack(
      children: [
        Scaffold(
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
            actions: [
              // Contador de sets totales
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primary),
                    ),
                    child: Text(
                      '$totalCompletedSets/$totalSets',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              // Progress Bar Animado
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                tween: Tween<double>(begin: 0, end: progress),
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value,
                  backgroundColor: AppColors.surface,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 6,
                ),
              ),

              // Navigation Arrows + PageView
              Expanded(
                child: Stack(
                  children: [
                    // PageView con swipe
                    PageView.builder(
                      controller: _pageController,
                      itemCount: workout.exercises.length,
                      onPageChanged: (index) {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _currentExerciseIndex = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        final exercise = workout.exercises[index];
                        return _buildExerciseContent(exercise, index, workout);
                      },
                    ),

                    // Botones de navegación lateral
                    if (_currentExerciseIndex > 0)
                      Positioned(
                        left: 8,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: IconButton(
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.surface.withOpacity(0.9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.chevron_left,
                                  color: AppColors.primary),
                            ),
                            onPressed: _previousExercise,
                          ),
                        ),
                      ),
                    if (_currentExerciseIndex < workout.exercises.length - 1)
                      Positioned(
                        right: 8,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: IconButton(
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.surface.withOpacity(0.9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.chevron_right,
                                  color: AppColors.primary),
                            ),
                            onPressed: () =>
                                _nextExercise(currentExercise, workout),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Confetti de celebración
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: math.pi / 2,
            emissionFrequency: 0.05,
            numberOfParticles: 50,
            gravity: 0.3,
            colors: const [
              AppColors.primary,
              Colors.blue,
              Colors.green,
              Colors.orange,
              Colors.pink,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseContent(Exercise exercise, int exerciseIndex, workout) {
    final completedSets = _completedSets[exerciseIndex];
    final allSetsCompleted = completedSets.every((s) => s);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise Counter con animación
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TweenAnimationBuilder<int>(
                duration: const Duration(milliseconds: 400),
                tween: IntTween(begin: 0, end: exerciseIndex + 1),
                builder: (context, value, child) => Text(
                  'Ejercicio $value de ${workout.exercises.length}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (allSetsCompleted)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle,
                          size: 16, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text(
                        'COMPLETO',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Exercise Name con animación
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              exercise.name,
              key: ValueKey(exercise.name),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Muscle Group Tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary),
            ),
            child: Text(
              exercise.muscleGroup.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                letterSpacing: 1,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Video del ejercicio
          if (exercise.videoUrl != null && exercise.videoUrl!.isNotEmpty)
            Container(
              constraints: const BoxConstraints(
                maxHeight: 400, // Máximo para videos muy largos
              ),
              child: VideoPlayerWidget(
                videoUrl: exercise.videoUrl!,
                autoPlay: false,
                looping: true,
                exerciseName: exercise.name,
                showFullscreenButton: true,
              ),
            )
          else
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
                      Icons.videocam_off_outlined,
                      size: 64,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Video no disponible',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 24),

          // Description
          if (exercise.description != null) ...[
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
              exercise.description!,
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
                value: exercise.sets.toString(),
              ),
              const SizedBox(width: 12),
              _InfoCard(
                icon: Icons.repeat,
                label: 'Reps',
                value: exercise.reps.toString(),
              ),
              const SizedBox(width: 12),
              _InfoCard(
                icon: Icons.timer,
                label: 'Descanso',
                value: '${exercise.restSeconds}s',
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Rest Timer Circular Mejorado
          if (_isResting && exerciseIndex == _currentExerciseIndex) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
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
                  const SizedBox(height: 24),

                  // Tiempo restante
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _remainingSeconds.toString(),
                        style: TextStyle(
                          fontSize: 80,
                          fontWeight: FontWeight.bold,
                          color: _remainingSeconds <= 3
                              ? Colors.red
                              : AppColors.primary,
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

                  const SizedBox(height: 24),

                  // Botón para saltar descanso
                  TextButton(
                    onPressed: () {
                      _timer?.cancel();
                      setState(() {
                        _isResting = false;
                        _remainingSeconds = 0;
                      });
                      HapticFeedback.lightImpact();
                    },
                    child: const Text(
                      'Saltar Descanso',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Sets Checklist con animaciones
          const Text(
            'Marca las series completadas:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),

          ...List.generate(exercise.sets, (setIndex) {
            final isCompleted = completedSets[setIndex];
            final isLastCompleted = setIndex == _lastCompletedSet;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ScaleTransition(
                scale: isLastCompleted && isCompleted
                    ? _celebrationController
                    : const AlwaysStoppedAnimation(1.0),
                child: InkWell(
                  onTap: () => _toggleSet(exerciseIndex, setIndex),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppColors.primary.withOpacity(0.2)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            isCompleted ? AppColors.primary : AppColors.surface,
                        width: 2,
                      ),
                      boxShadow: isCompleted
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) {
                            return ScaleTransition(
                              scale: animation,
                              child: child,
                            );
                          },
                          child: Icon(
                            isCompleted
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            key: ValueKey(isCompleted),
                            color: isCompleted
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Serie ${setIndex + 1}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color:
                                isCompleted ? AppColors.primary : Colors.white,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${exercise.reps} reps',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 32),

          // Next Exercise Button
          PrimaryButton(
            text: exerciseIndex < workout.exercises.length - 1
                ? 'SIGUIENTE EJERCICIO'
                : 'FINALIZAR RUTINA',
            onPressed: () => _nextExercise(exercise, workout),
            icon: exerciseIndex < workout.exercises.length - 1
                ? Icons.arrow_forward
                : Icons.check,
          ),

          const SizedBox(height: 16),
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
