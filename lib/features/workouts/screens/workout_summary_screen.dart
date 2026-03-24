import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../../core/theme/app_theme.dart';
import '../../../core/l10n/app_l10n.dart';
import '../../../core/utils/unit_converter.dart';
import '../models/workout.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/providers/user_provider.dart';
import '../providers/workout_provider.dart';
import '../providers/workout_progress_provider.dart';
import '../providers/workout_session_provider.dart';
import '../../progress/providers/achievements_provider.dart';
import '../../progress/providers/body_measurement_provider.dart';

class WorkoutSummaryScreen extends StatefulWidget {
  final Workout workout;
  final int durationMinutes;
  final int caloriesBurned;
  final double totalVolume;
  final List<List<bool>>? completedSets;

  const WorkoutSummaryScreen({
    super.key,
    required this.workout,
    required this.durationMinutes,
    required this.caloriesBurned,
    required this.totalVolume,
    this.completedSets,
  });

  @override
  State<WorkoutSummaryScreen> createState() => _WorkoutSummaryScreenState();
}

class _WorkoutSummaryScreenState extends State<WorkoutSummaryScreen> {
  Map<String, dynamic>? _nextWorkout;
  bool _isLoadingNextWorkout = true;
  bool _isSaving = true; // bloquea el bot�n hasta que la sesi�n quede guardada
  late final int _motivationalIndex = math.Random().nextInt(8);

  @override
  void initState() {
    super.initState();

    // Guardar sesi�n y actualizar estad�sticas
    _saveWorkoutSession();

    // Cargar pr�xima sesi�n programada
    _loadNextWorkout();
  }

  Future<void> _saveWorkoutSession() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final progressProvider =
          Provider.of<WorkoutProgressProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = authProvider.currentUser?.id;

      if (userId == null) return;

      debugPrint(
          '?? _saveWorkoutSession: userId=$userId workoutId=${widget.workout.id}');

      // Guardar sesi�n en workout_sessions y actualizar estad�sticas
      // Construir datos de ejercicios con series reales si est�n disponibles
      List<Map<String, dynamic>>? exercisesData;
      if (widget.completedSets != null &&
          widget.completedSets!.length == widget.workout.exercises.length) {
        exercisesData = List.generate(widget.workout.exercises.length, (i) {
          return {
            'exerciseId': widget.workout.exercises[i].id,
            'setsCompleted': widget.completedSets![i],
          };
        });
      }

      await progressProvider.completeWorkout(
        userId: userId,
        workoutId: widget.workout.id,
        durationMinutes: widget.durationMinutes,
        exercisesCompleted: widget.workout.exercises.length,
        caloriesBurned: widget.caloriesBurned,
        totalVolumeKg: widget.totalVolume,
        exercisesData: exercisesData,
      );

      // Refrescar WorkoutSessionProvider solo si el widget sigue montado
      // (el usuario puede haber navegado a inicio antes de que terminara)
      if (mounted) {
        final sessionProvider =
            Provider.of<WorkoutSessionProvider>(context, listen: false);
        await sessionProvider.loadSessions(userId, forceRefresh: true);

        // Calcular stats reales desde las sesiones actualizadas
        if (mounted) {
          final sessions = sessionProvider.sessions;
          final totalCompleted = sessions.length;
          final uniqueDays = sessions
              .map((s) {
                final d = s.date.toLocal();
                return DateTime(d.year, d.month, d.day);
              })
              .toSet()
              .length;

          await userProvider.updateUserStats(
            userId,
            completedWorkouts: totalCompleted,
            activeDays: uniqueDays,
          );
        }
      }

      // Refrescar usuario para obtener estad�sticas actualizadas
      if (mounted) await authProvider.refreshUser();

      // Verificar y desbloquear logros
      if (mounted) {
        final achievementsProvider =
            Provider.of<AchievementsProvider>(context, listen: false);
        final sessionProvider2 =
            Provider.of<WorkoutSessionProvider>(context, listen: false);
        final measurementProvider =
            Provider.of<BodyMeasurementProvider>(context, listen: false);

        final totalWorkouts = sessionProvider2.sessions.length;
        final currentStreak = sessionProvider2.getCurrentStreak();

        double? weightLoss;
        final allMeasurements = measurementProvider.measurements;
        if (allMeasurements.length >= 2) {
          final firstWeight = allMeasurements.last.weight;
          final latestWeight = allMeasurements.first.weight;
          if (firstWeight != null && latestWeight != null) {
            weightLoss = firstWeight - latestWeight;
          }
        }

        final newlyUnlocked =
            await achievementsProvider.checkAndUnlockAchievements(
          totalWorkouts: totalWorkouts,
          currentStreak: currentStreak,
          weightLoss: weightLoss,
        );

        // Mostrar celebraci�n si se desbloquearon logros
        if (mounted && newlyUnlocked.isNotEmpty) {
          HapticFeedback.heavyImpact();
          _showAchievementCelebration(newlyUnlocked.length);
        }
      }
    } catch (e) {
      debugPrint('? Error al guardar sesi�n: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _loadNextWorkout() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final progressProvider =
          Provider.of<WorkoutProgressProvider>(context, listen: false);
      final userId = authProvider.currentUser?.id;

      if (userId == null) {
        setState(() => _isLoadingNextWorkout = false);
        return;
      }

      final nextWorkoutData =
          await progressProvider.getNextScheduledWorkout(userId);

      if (nextWorkoutData != null && mounted) {
        // Enriquecer el mapa con el nombre de la rutina
        final workoutProvider =
            Provider.of<WorkoutProvider>(context, listen: false);
        final workoutName = workoutProvider
            .getWorkoutById(nextWorkoutData['workout_id'] as String)
            ?.name;
        nextWorkoutData['name'] =
            workoutName; // null ? fallback en _buildNextWorkoutInfo
      }

      if (mounted) {
        setState(() {
          _nextWorkout = nextWorkoutData;
          _isLoadingNextWorkout = false;
        });
      }
    } catch (e) {
      debugPrint('? Error al cargar pr�xima sesi�n: $e');
      if (mounted) setState(() => _isLoadingNextWorkout = false);
    }
  }

  // M�todos auxiliares
  void _showAchievementCelebration(int count) {
    final l10n = AppL10n.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Row(
          children: [
            const Text('??', style: TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.achievementUnlockedTitle,
                style: const TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
          ],
        ),
        content: Text(
          l10n.achievementUnlockedMsgCount(count),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              l10n.awesomeButton,
              style: const TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int minutes) {
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
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

  Widget _buildNextWorkoutInfo() {
    if (_nextWorkout == null) return const SizedBox();
    final l10nDays = AppL10n.of(context);
    final name =
        (_nextWorkout?['name'] as String?) ?? l10nDays.nextWorkoutDefault;
    final date = _nextWorkout?['date'] as DateTime?;
    final daysUntil = (_nextWorkout?['days_until'] as int?) ?? 1;
    final dateStr = date != null
        ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}'
        : l10nDays.comingSoonLabel;
    final daysLabel = daysUntil == 0
        ? l10nDays.todayLabel
        : daysUntil == 1
            ? l10nDays.tomorrowLabel
            : l10nDays.inDaysWithDate(daysUntil, dateStr);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        const SizedBox(height: 4),
        Text(daysLabel,
            style:
                const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
      ],
    );
  }

  String _getNextWorkoutMessage() {
    final l10nMsg = AppL10n.of(context);
    if (_nextWorkout == null) return l10nMsg.nextWorkoutMsg1;
    return l10nMsg.nextWorkoutMsg2;
  }

  @override
  Widget build(BuildContext context) {
    const units = 'metric';
    final l10n = AppL10n.of(context);
    final motivationalMessages = l10n.motivationalMessages;
    final motivationalMessage =
        motivationalMessages[_motivationalIndex % motivationalMessages.length];
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.workoutSummaryTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header con imagen de celebraci�n
              Container(
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.background,
                      AppColors.background.withOpacity(0.9),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Bot�n cerrar
                    Positioned(
                      top: 16,
                      right: 16,
                      child: IconButton(
                        onPressed: () => context.go('/home'),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ),
                    // Imagen de celebraci�n (placeholder)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: const BoxDecoration(
                              color: AppColors.cardBackground,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.celebration,
                              size: 60,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Mensaje motivador
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Text(
                      motivationalMessage,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.workoutCompletedLine1,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    Text(
                      l10n.workoutCompletedLine2,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Estad�sticas en tarjetas amarillas
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            icon: Icons.timer,
                            label: l10n.timeStatLabel,
                            value: _formatDuration(widget.durationMinutes),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatCard(
                            icon: Icons.local_fire_department,
                            label: l10n.caloriesStatLabelUpper,
                            value: '${widget.caloriesBurned}',
                            unit: 'kcal',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatCard(
                            icon: Icons.fitness_center,
                            label: l10n.volumeStatLabel,
                            value: UnitConverter.weightValue(
                                widget.totalVolume, units),
                            unit: UnitConverter.weightUnit(units),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Resumen de Ejercicios
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.exerciseSummaryLabel,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.primary),
                          ),
                          child: Text(
                            '${widget.workout.exercises.length} ${l10n.totalStatLabel}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Lista de ejercicios completados
                    ...widget.workout.exercises.map((exercise) {
                      // Calcular volumen aproximado
                      final estimatedWeight = _estimateWeight(exercise.name);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: AppColors.primary,
                                size: 24,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      exercise.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${l10n.setsCount(exercise.sets)} � ${l10n.repsCount(exercise.reps)}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                UnitConverter.formatWeight(
                                    estimatedWeight.toDouble(), units),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 32),

                    // Pr�xima Sesi�n Programada
                    if (!_isLoadingNextWorkout && _nextWorkout != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.calendar_today,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  l10n.nextSessionLabel,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildNextWorkoutInfo(),
                            const SizedBox(height: 12),
                            Text(
                              _getNextWorkoutMessage(),
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],

                    // Bot�n Volver al Inicio
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving
                            ? null // bloqueado mientras guarda
                            : () async {
                                // Recarga final de sesiones antes de navegar
                                // por si el contexto estaba desmontado antes
                                final authProvider = Provider.of<AuthProvider>(
                                    context,
                                    listen: false);
                                final sessionProvider =
                                    Provider.of<WorkoutSessionProvider>(context,
                                        listen: false);
                                final userId = authProvider.currentUser?.id;
                                if (userId != null) {
                                  if (!mounted) return;
                                  await sessionProvider.loadSessions(
                                    userId,
                                    forceRefresh: true,
                                  );
                                }
                                if (context.mounted) context.go('/home');
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.black,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.home,
                                      color: Colors.black, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    l10n.backToHome,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget StatCard
class StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? unit;

  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.primary.withOpacity(0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            if (unit != null)
              Text(unit!,
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.primary)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
