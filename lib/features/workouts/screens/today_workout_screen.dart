import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/l10n/app_l10n.dart';
import '../../../shared/widgets/app_snackbar.dart';
import 'dart:async';
import 'dart:convert';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/workout_provider.dart';
import '../providers/workout_progress_provider.dart';
import '../models/exercise.dart';
import '../models/workout.dart';
import '../models/workout_progress.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/video_player_widget.dart';
import 'workout_summary_screen.dart';
import '../services/workout_completion.dart';
import '../../../features/progress/providers/body_measurement_provider.dart';
import '../../../shared/services/unsaved_changes_guard.dart';
import '../../../shared/services/offline_cache_service.dart';
import '../../../shared/services/offline_sync_queue.dart';
import '../services/progression_engine.dart';
import '../widgets/record_celebration.dart';
import '../services/calorie_estimator.dart';

class TodayWorkoutScreen extends StatefulWidget {
  /// Si se pasa, se ejecuta esta rutina en lugar de la asignada (modo extra).
  final String? extraWorkoutId;

  const TodayWorkoutScreen({super.key, this.extraWorkoutId});

  @override
  State<TodayWorkoutScreen> createState() => _TodayWorkoutScreenState();
}

class _TodayWorkoutScreenState extends State<TodayWorkoutScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  int _currentExerciseIndex = 0;
  List<List<bool>> _completedSets = [];
  bool _isResting = false;
  int _remainingSeconds = 0;
  Timer? _timer;
  bool _isPaused = false;
  int _accumulatedSeconds = 0; // segundos activos acumulados
  DateTime? _resumeTime; // inicio del segmento activo actual

  late PageController _pageController;
  late AnimationController _celebrationController;

  int _lastCompletedSet = -1;
  Timer? _saveDebouncer;
  bool _hasCheckedProgress = false;

  // Estado de resumen al completar rutina
  bool _workoutCompleted = false;
  Workout? _summaryWorkout;
  int _summaryDurationMinutes = 0;
  int _summaryCaloriesBurned = 0;
  double _summaryTotalVolume = 0;

  // -- Historial de peso por ejercicio ---------------------------------------
  // [exerciseIndex][setIndex] → peso en kg (null = no ingresado)
  Map<int, Map<int, double?>> _setWeights = {};
  // Pesos de la última sesión cargados desde DB (no se modifican durante la sesión)
  Map<int, Map<int, double?>> _lastSessionWeights = {};
  bool _hasLoadedWeights = false;

  // PR histórico por ejercicio (max weight ever logged)
  Map<int, double> _exercisePRs = {};
  // Repeticiones REALES por serie: [exerciseIndex][setIndex] → reps
  final Map<int, Map<int, int>> _setReps = {};
  // Historial completo por ejercicio (para la progresión inteligente)
  Map<int, List<SetLog>> _historyByExercise = {};
  // Sugerencias ya aplicadas en esta sesión (oculta la tarjeta)
  final Set<int> _appliedSuggestions = {};
  // Ejercicios que superaron su PR en esta sesión
  final Set<int> _newPRsThisSession = {};
  // Pre-caché de videos: solo se lanza una vez por sesión
  bool _videosCacheStarted = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Registrar el inicio del segmento activo
    _resumeTime = DateTime.now();
    WidgetsBinding.instance.addObserver(this);

    // Guard de navegación: interceptar taps en la barra inferior durante la rutina
    UnsavedChangesGuard.register(() async {
      if (_workoutCompleted) return true;
      if (!mounted) return true;
      final choice = await _showExitWorkoutDialog();
      await _handleExitChoice(choice);
      return false; // siempre bloqueamos; la navegación la manejamos nosotros
    });

    // Verificar progreso pendiente después de que se construya el widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Ensure exercises are loaded before the workout begins
      final authProvider = context.read<AuthProvider>();
      final workoutProvider = context.read<WorkoutProvider>();
      final effectiveId =
          widget.extraWorkoutId ?? authProvider.currentUser?.assignedWorkoutId;
      if (effectiveId != null) {
        workoutProvider.ensureExercisesLoaded(effectiveId);
      }
      _checkPendingProgress();
    });
  }

  @override
  void dispose() {
    UnsavedChangesGuard.unregister();
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _saveDebouncer?.cancel();
    _pageController.dispose();
    _celebrationController.dispose();
    super.dispose();
  }

  // -- Ciclo de vida de la app: auto-pausa al ir a segundo plano --------------
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_workoutCompleted) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      if (!_isPaused) _pauseWorkout(auto: true);
    }
  }

  // -- Cronómetro activo ------------------------------------------------------
  int _getActiveDurationSeconds() {
    if (_isPaused || _resumeTime == null) return _accumulatedSeconds;
    return _accumulatedSeconds +
        DateTime.now().difference(_resumeTime!).inSeconds;
  }

  void _pauseWorkout({bool auto = false}) {
    if (_isPaused) return;
    _timer?.cancel();
    setState(() {
      _accumulatedSeconds = _getActiveDurationSeconds();
      _isPaused = true;
      _isResting = false;
    });
    unawaited(_saveTimerLocally());
    _saveProgressDebounced();
    if (!auto) HapticFeedback.mediumImpact();
  }

  void _resumeWorkout() {
    if (!_isPaused) return;
    setState(() {
      _resumeTime = DateTime.now();
      _isPaused = false;
    });
    HapticFeedback.mediumImpact();
  }

  String _timerKey() {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.id ?? '';
    final workoutId = widget.extraWorkoutId ??
        authProvider.currentUser?.assignedWorkoutId ??
        '';
    return 'workout_timer_${userId}_$workoutId';
  }

  Future<void> _saveTimerLocally() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_timerKey(), _accumulatedSeconds);
  }

  Future<void> _loadTimerLocally() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt(_timerKey()) ?? 0;
    // Solo aplicar si supera el acumulado actual (evita retroceder el timer
    // cuando se restaura progreso desde BD con un valor mayor).
    if (saved > _accumulatedSeconds) {
      setState(() => _accumulatedSeconds = saved);
    }
  }

  Future<void> _clearTimerLocally() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_timerKey());
    await prefs.remove(_setsKey());
  }

  // ── Pesos y repeticiones de la sesión en curso (para retomar) ──────────
  String _setsKey() => _timerKey().replaceFirst('workout_timer_', 'workout_sets_');

  /// Valores de esta sesión recuperados al retomar; se aplican encima de los
  /// pesos de la sesión anterior aunque esos lleguen después.
  Map<int, Map<int, double?>> _resumedWeights = {};
  Map<int, Map<int, int>> _resumedReps = {};

  Future<void> _saveSetsLocally() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _setsKey(),
        jsonEncode({
          'day': DateTime.now().toIso8601String().substring(0, 10),
          'w': {
            for (final e in _setWeights.entries)
              '${e.key}': {for (final x in e.value.entries) '${x.key}': x.value}
          },
          'r': {
            for (final e in _setReps.entries)
              '${e.key}': {for (final x in e.value.entries) '${x.key}': x.value}
          },
        }));
  }

  Future<void> _loadSetsLocally() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_setsKey());
    if (raw == null) return;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      if (j['day'] != DateTime.now().toIso8601String().substring(0, 10)) return;
      _resumedWeights = {
        for (final e in (j['w'] as Map).entries)
          int.parse(e.key as String): {
            for (final x in (e.value as Map).entries)
              int.parse(x.key as String): (x.value as num?)?.toDouble()
          }
      };
      _resumedReps = {
        for (final e in (j['r'] as Map).entries)
          int.parse(e.key as String): {
            for (final x in (e.value as Map).entries)
              int.parse(x.key as String): (x.value as num).toInt()
          }
      };
      if (mounted) setState(_applyResumedSets);
    } catch (_) {}
  }

  void _applyResumedSets() {
    for (final e in _resumedWeights.entries) {
      _setWeights[e.key] ??= {};
      _setWeights[e.key]!.addAll(e.value);
    }
    for (final e in _resumedReps.entries) {
      _setReps[e.key] ??= {};
      _setReps[e.key]!.addAll(e.value);
    }
  }

  /// Pre-descarga todos los videos de la rutina en background.
  /// No bloquea — se ejecuta una sola vez por sesión.
  void _preCacheVideos(List<Exercise> exercises) {
    if (kIsWeb) return; // En web el navegador gestiona la caché de video
    final cache = DefaultCacheManager();
    for (final ex in exercises) {
      final url = ex.videoUrl;
      if (url != null && url.isNotEmpty) {
        cache.getFileFromCache(url).then((info) {
          if (info == null) {
            // No está en caché ? descargar en background silenciosamente
            cache.downloadFile(url).ignore();
          }
        }).ignore();
      }
    }
  }

  Future<void> _checkPendingProgress() async {
    if (_hasCheckedProgress) return;
    _hasCheckedProgress = true;

    final authProvider = context.read<AuthProvider>();
    final progressProvider = context.read<WorkoutProgressProvider>();
    final workoutProvider = context.read<WorkoutProvider>();

    // Cargar Últimos pesos usados para este workout
    final effectiveId =
        widget.extraWorkoutId ?? authProvider.currentUser?.assignedWorkoutId;
    final userId = authProvider.currentUser?.id;
    if (effectiveId != null && userId != null) {
      unawaited(_loadLastWeights(workoutId: effectiveId, userId: userId));
    }

    // Si es rutina extra, no restaurar progreso guardado de la rutina asignada
    if (widget.extraWorkoutId != null) return;

    if (authProvider.currentUser?.assignedWorkoutId == null) return;

    await progressProvider.loadProgress(authProvider.currentUser!.id);

    if (progressProvider.hasProgress) {
      final progress = progressProvider.currentProgress!;
      final workout = workoutProvider
          .getWorkoutById(authProvider.currentUser!.assignedWorkoutId!);

      if (workout != null && progress.workoutId == workout.id) {
        // Verificar si el progreso es del mismo día
        final progressDate = DateTime(
          progress.updatedAt.year,
          progress.updatedAt.month,
          progress.updatedAt.day,
        );
        final today = DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
        );

        if (progressDate.isBefore(today)) {
          // El progreso es de un día anterior, eliminarlo automáticamente
          debugPrint('??? Progreso del día anterior detectado, eliminando...');
          await progressProvider.deleteProgress();
          debugPrint('? Progreso anterior eliminado');
        } else if (progress.timeSinceUpdate.inHours < 3) {
          // Lo dejó hace poco: seguir directo donde quedó, sin preguntar
          _restoreProgress(progress);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  'Sigues en el ejercicio ${progress.exerciseIndex + 1} de ${workout.exercises.length}'),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Empezar de cero',
                textColor: AppColors.primary,
                onPressed: _startOver,
              ),
            ));
          }
        } else {
          // Del mismo día pero hace horas: preguntar
          _showRestoreDialog(progress, workout.name);
        }
      } else {
        // Si el progreso es de otra rutina, eliminarlo
        await progressProvider.deleteProgress();
      }
    }
  }

  void _showRestoreDialog(WorkoutProgress progress, String workoutName) {
    final progressPercent = progress.progressPercentage.toInt();
    final timeAgo = _getTimeAgoText(progress.timeSinceUpdate);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          AppL10n.of(context).incompleteWorkoutFound,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              workoutName,
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppL10n.of(context).startedLabel(timeAgo),
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.fitness_center,
                  color: AppColors.primaryText,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  AppL10n.of(context).progressLabel(progressPercent),
                  style: TextStyle(
                    color: AppColors.textPrimary,
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
                  AlwaysStoppedAnimation<Color>(AppColors.primary),
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
            child: Text(
              AppL10n.of(context).startFromScratch,
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
            child: Text(AppL10n.of(context).continueAction),
          ),
        ],
      ),
    );
  }

  void _startOver() {
    context.read<WorkoutProgressProvider>().deleteProgress();
    _clearTimerLocally();
    _resumedWeights = {};
    _resumedReps = {};
    setState(() {
      _completedSets = [
        for (final row in _completedSets) List<bool>.filled(row.length, false)
      ];
      _setReps.clear();
      _currentExerciseIndex = 0;
      _accumulatedSeconds = 0;
      _resumeTime = DateTime.now();
    });
    if (_pageController.hasClients) _pageController.jumpToPage(0);
  }

  void _restoreProgress(progress) {
    setState(() {
      _completedSets = progress.completedSets;
      // Clamp index to valid bounds in case exercises were modified after saving
      _currentExerciseIndex = _completedSets.isNotEmpty
          ? progress.exerciseIndex.clamp(0, _completedSets.length - 1)
          : 0;
      // Restaurar segundos acumulados guardados (si existen en BD)
      if (progress.accumulatedSeconds > 0) {
        _accumulatedSeconds = progress.accumulatedSeconds;
      }
      _resumeTime = DateTime.now();
      _isPaused = false;
    });
    // Pesos y repeticiones que ya había anotado hoy
    _loadSetsLocally();
    // También cargar timer local (SharedPrefs) en paralelo
    _loadTimerLocally().then((_) {
      // Si SharedPrefs tiene un valor mayor, usarlo
      setState(() => _resumeTime = DateTime.now());
    });

    if (_pageController.hasClients) {
      _pageController.jumpToPage(_currentExerciseIndex);
    }

    HapticFeedback.mediumImpact();
  }

  String _getTimeAgoText(Duration duration) {
    if (duration.inMinutes < 60) {
      return AppL10n.of(context).minutesAgoLabel(duration.inMinutes);
    } else if (duration.inHours < 24) {
      return AppL10n.of(context).hoursAgoLabel(duration.inHours);
    } else {
      return AppL10n.of(context).daysAgoLowerLabel(duration.inDays);
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
          // Haptic feedback en los Últimos 3 segundos
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

    // Registro en un toque: si la serie se marca como hecha sin peso
    // anotado, usar el sugerido por la progresión, el de la serie anterior
    // o el que indicó el entrenador. Así la progresión siempre aprende.
    double? autoWeight;
    if (!isCompleted && _setWeights[exerciseIndex]?[setIndex] == null) {
      autoWeight = _autoWeightFor(exerciseIndex, setIndex);
    }

    setState(() {
      _completedSets[exerciseIndex][setIndex] = !isCompleted;
      if (!isCompleted) {
        _lastCompletedSet = setIndex;
        if (autoWeight != null) {
          _setWeights[exerciseIndex] ??= {};
          _setWeights[exerciseIndex]![setIndex] = autoWeight;
        }
      }
    });

    // Auto-guardar progreso (con debounce de 2 segundos)
    _saveProgressDebounced();

    // Récord con el peso sugerido (la progresión subió el peso)
    final prevPr = _exercisePRs[exerciseIndex];
    if (!isCompleted &&
        autoWeight != null &&
        autoWeight > 0 &&
        prevPr != null &&
        autoWeight > prevPr) {
      final alreadyCelebrated = _newPRsThisSession.contains(exerciseIndex);
      _exercisePRs[exerciseIndex] = autoWeight;
      _newPRsThisSession.add(exerciseIndex);
      final name = _exerciseNameAt(exerciseIndex);
      if (!alreadyCelebrated && name != null) {
        showRecordCelebration(
          context,
          exerciseName: name,
          weightLabel: _fmtWeight(autoWeight),
          previousLabel: _fmtWeight(prevPr),
        );
      }
    }

    if (!isCompleted) {
      HapticFeedback.heavyImpact();
      _celebrationController.forward(from: 0);

      // Iniciar descanso al completar cualquier serie,
      // excepto cuando es la Última serie del Último ejercicio
      final totalSets = _completedSets[exerciseIndex].length;
      final isLastExercise = exerciseIndex == _completedSets.length - 1;
      final isLastSet = setIndex == totalSets - 1;

      if (!(isLastExercise && isLastSet)) {
        final effectiveId = widget.extraWorkoutId ??
            context.read<AuthProvider>().currentUser?.assignedWorkoutId;
        final workout = effectiveId != null
            ? context.read<WorkoutProvider>().getWorkoutById(effectiveId)
            : null;
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
      _saveSetsLocally();
    });
  }

  Future<void> _onManualPause() async {
    _pauseWorkout();
    final choice = await _showExitWorkoutDialog();
    if (choice == 'stay' || choice == null) {
      _resumeWorkout();
    } else {
      await _handleExitChoice(choice);
    }
  }

  // -- Diálogo de salida ----------------------------------------------------
  Future<String?> _showExitWorkoutDialog() async {
    return showDialog<String>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: SizedBox.expand(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.pause_circle_outline_rounded,
                color: AppColors.primaryText,
                size: 80,
              ),
              const SizedBox(height: 16),
              Text(
                AppL10n.of(context).routineInCourseTitle,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppL10n.of(context).whatDoYouWantToDo,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(ctx, 'stay'),
                icon: Icon(Icons.arrow_back_rounded, color: Colors.black),
                label: Text(
                  AppL10n.of(context).continueRoutine,
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () => Navigator.pop(ctx, 'save_later'),
                icon: Icon(
                  Icons.exit_to_app_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                label: Text(
                  AppL10n.of(context).continueLater,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Divider(
                color: AppColors.textPrimary.withValues(alpha: 0.12),
                indent: 48,
                endIndent: 48,
                height: 1,
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => Navigator.pop(ctx, 'terminate'),
                icon: Icon(
                  Icons.stop_circle_outlined,
                  color: Colors.redAccent,
                  size: 20,
                ),
                label: Text(
                  AppL10n.of(context).endRoutine,
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleExitChoice(String? choice) async {
    if (!mounted) return;
    if (choice == 'save_later') {
      await _saveProgressToDatabase();
      await _savePartialWeights(); // guardar pesos ingresados hasta ahora
      if (mounted) context.go('/workouts');
    } else if (choice == 'terminate') {
      // Leer el workout antes del await para no cruzar un async gap con context
      final effectiveId = widget.extraWorkoutId ??
          context.read<AuthProvider>().currentUser?.assignedWorkoutId;
      final partialWorkout = effectiveId != null
          ? context.read<WorkoutProvider>().getWorkoutById(effectiveId)
          : null;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            AppL10n.of(context).endRoutineTitle,
            style: TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.bold),
          ),
          content: Text(
            AppL10n.of(context).endRoutineConfirm,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(AppL10n.of(context).cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: AppColors.textPrimary,
              ),
              child: Text(AppL10n.of(context).endAction),
            ),
          ],
        ),
      );
      if (confirmed == true && mounted) {
        // Solo se cierra si está todo registrado; si no, se muestra qué falta.
        if (partialWorkout != null) {
          await _tryFinish(partialWorkout, fromExitMenu: true);
        } else {
          // Fallback: sin workout cargado, salir directamente
          final progressProvider = context.read<WorkoutProgressProvider>();
          await _savePartialWeights();
          await progressProvider.deleteProgress();
          if (mounted) context.go('/workouts');
        }
      }
    }
    // 'stay' o null → no hace nada
  }

  /// Guarda los pesos ingresados en esta sesión en exercise_set_logs,
  /// independientemente de si la rutina se completó o se abandonó.
  Future<void> _savePartialWeights() async {
    if (_setWeights.isEmpty) return;
    if (!mounted) return;
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.id;
    final effectiveId =
        widget.extraWorkoutId ?? authProvider.currentUser?.assignedWorkoutId;
    if (userId == null || effectiveId == null) return;
    final workout = context.read<WorkoutProvider>().getWorkoutById(effectiveId);
    if (workout == null) return;
    await _saveSetWeights(
        workoutId: effectiveId, userId: userId, workout: workout);
  }

  Future<void> _saveProgressToDatabase() async {
    final authProvider = context.read<AuthProvider>();
    final progressProvider = context.read<WorkoutProgressProvider>();

    final effectiveSaveId =
        widget.extraWorkoutId ?? authProvider.currentUser?.assignedWorkoutId;
    if (effectiveSaveId == null) return;
    if (_completedSets.isEmpty) return;

    try {
      await progressProvider.saveProgress(
        userId: authProvider.currentUser!.id,
        workoutId: effectiveSaveId,
        exerciseIndex: _currentExerciseIndex,
        completedSets: _completedSets,
        accumulatedSeconds: _getActiveDurationSeconds(),
      );
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, AppL10n.of(context).couldNotSaveProgress);
      }
    }
  }

  void _nextExercise(Exercise currentExercise, Workout workout) {
    debugPrint(
        '?? _nextExercise: currentIndex=$_currentExerciseIndex, total=${_completedSets.length}');

    if (_currentExerciseIndex < _completedSets.length - 1) {
      debugPrint('Avanzando al siguiente ejercicio');
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
      _tryFinish(workout);
    }
  }

  List<PendingExercise> _pendingFor(Workout workout) =>
      WorkoutCompletion.pending(
        names: workout.exercises.map((e) => e.name).toList(),
        completed: _completedSets,
        weights: _setWeights,
        weightRequired:
            workout.exercises.map((e) => !_isCardioExercise(e)).toList(),
      );

  /// Solo deja terminar con todas las series hechas y sus pesos anotados.
  Future<void> _tryFinish(Workout workout, {bool fromExitMenu = false}) async {
    final pending = _pendingFor(workout);
    if (pending.isEmpty) {
      _showWorkoutSummary(workout);
      return;
    }
    HapticFeedback.mediumImpact();
    final en = AppL10n.of(context).isEn;
    final total = WorkoutCompletion.totalMissing(pending);
    final plural = total == 1 ? '' : 's';
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.75),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Row(children: [
                    Icon(Icons.playlist_add_check,
                        color: Colors.orangeAccent, size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        en
                            ? '$total set$plural left to log'
                            : 'Te falta${total == 1 ? '' : 'n'} $total serie$plural por registrar',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 6),
                Text(
                  en
                      ? 'To finish, mark every set as done and log the weight you used.'
                      : 'Para terminar, marca cada serie como hecha y anota el peso que usaste.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final p in pending)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          minVerticalPadding: 10,
                          title: Text(p.name,
                              style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            [
                              if (p.unfinishedSets.isNotEmpty)
                                '${en ? 'Not done' : 'Sin hacer'}: ${p.unfinishedSets.join(', ')}',
                              if (p.setsWithoutWeight.isNotEmpty)
                                '${en ? 'No weight' : 'Sin peso'}: ${p.setsWithoutWeight.join(', ')}',
                            ].join(' · '),
                            style: TextStyle(color: Colors.orangeAccent),
                          ),
                          trailing: TextButton(
                            onPressed: () =>
                                Navigator.pop(ctx, 'go:${p.index}'),
                            child: Text(en ? 'Go' : 'Ir'),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () =>
                        Navigator.pop(ctx, 'go:${pending.first.index}'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      en ? 'Complete pending sets' : 'Completar lo pendiente',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                if (fromExitMenu) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx, 'save_later'),
                      style: TextButton.styleFrom(
                          minimumSize: const Size.fromHeight(48)),
                      child: Text(en
                          ? 'Save and continue later'
                          : 'Guardar y continuar después'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    if (!mounted) return;
    if (choice == 'save_later') {
      await _handleExitChoice('save_later');
      return;
    }
    if (fromExitMenu) _resumeWorkout();
    if (choice != null && choice.startsWith('go:')) {
      final idx = int.tryParse(choice.substring(3)) ?? 0;
      setState(() => _currentExerciseIndex = idx);
      if (_pageController.hasClients) {
        _pageController.animateToPage(idx,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic);
      }
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

  void _showWorkoutSummary(Workout workout) {
    HapticFeedback.heavyImpact();

    // Tiempo activo real (excluye pausas)
    final durationMinutes = _getActiveDurationSeconds() ~/ 60;
    _clearTimerLocally(); // limpiar timer guardado

    // Guardar pesos por serie en segundo plano
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.id;
    final workoutId =
        widget.extraWorkoutId ?? authProvider.currentUser?.assignedWorkoutId;
    if (userId != null && workoutId != null) {
      unawaited(_saveSetWeights(
          workoutId: workoutId, userId: userId, workout: workout));
    }

    // Obtener peso: medidas corporales ? perfil de usuario ? default 70kg
    final measurementProvider = context.read<BodyMeasurementProvider>();
    final authUser = context.read<AuthProvider>().currentUser;
    final userWeightKg = measurementProvider.latestMeasurement?.weight ??
        authUser?.weightKg ??
        70.0;

    // CÁlculo de calorías mejorado con datos del perfil de usuario
    final caloriesBurned = _estimateCalories(
      workout,
      durationMinutes,
      userWeightKg,
    );

    // Volumen real: solo series que el usuario completó × peso que realmente usó.
    // Si no ingresó peso en una serie, se usa el peso programado como fallback.
    double totalVolume = 0;
    for (int i = 0; i < workout.exercises.length; i++) {
      final exercise = workout.exercises[i];
      final completedSetsList =
          i < _completedSets.length ? _completedSets[i] : <bool>[];
      for (int j = 0; j < completedSetsList.length; j++) {
        if (completedSetsList[j]) {
          final actualWeight = _setWeights[i]?[j] ??
              (exercise.weight > 0
                  ? exercise.weight /
                      _kgToLbs // exercise.weight está en lbs, convertir a kg
                  : _estimateWeight(exercise.name).toDouble());
          totalVolume += actualWeight * exercise.reps;
        }
      }
    }

    setState(() {
      _workoutCompleted = true;
      _summaryWorkout = workout;
      _summaryDurationMinutes = durationMinutes;
      _summaryCaloriesBurned = caloriesBurned;
      _summaryTotalVolume = totalVolume;
    });
  }

  int _estimateCalories(Workout workout, int durationMinutes, double weightKg) {
    if (durationMinutes == 0) return 0;

    // -- Datos del usuario ------------------------------------------------------
    final authUser = context.read<AuthProvider>().currentUser;
    final exercises = workout.exercises;
    final cardio = exercises.where(_isCardioExercise).length;
    return CalorieEstimator.estimate(
      minutes: durationMinutes,
      weightKg: weightKg,
      heightCm: authUser?.heightCm?.toDouble(),
      age: authUser?.age,
      sex: authUser?.sex,
      cardioRatio: exercises.isEmpty ? 0 : cardio / exercises.length,
    );
  }

  /// Detecta si un ejercicio es cardiovascular usando múltiples señales:
  /// 1. Campo muscleGroup == 'Cardio' (señal primaria, más fiable)
  /// 2. Nombre del ejercicio contra lista de palabras clave (ES + EN)
  bool _isCardioExercise(Exercise exercise) {
    // Señal primaria: grupo muscular clasificado como Cardio en la DB
    if (exercise.muscleGroup.toLowerCase() == 'cardio') return true;

    // Señal secundaria: keywords en el nombre
    final name = exercise.name.toLowerCase();
    const keywords = [
      // Español
      'burpee', 'salto', 'saltar', 'carrera', 'correr', 'trote',
      'trotar', 'bicicleta', 'cuerda', 'comba', 'cardio', 'hiit',
      'sprint', 'escalador', 'escaladora', 'aeróbico', 'aerobico',
      'elíptica', 'eliptica', 'remo', 'nadar', 'natación', 'natacion',
      'step', 'zumba', 'baile', 'bailar', 'patinar',
      // English
      'jump', 'jumping', 'run', 'running', 'jog', 'jogging',
      'bike', 'cycling', 'rope', 'mountain climber', 'box jump',
      'star jump', 'skipping', 'aerobic', 'elliptical', 'row',
      'rowing', 'swim', 'swimming', 'dance', 'skate',
      'high knee', 'butt kick', 'sprint', 'treadmill',
    ];
    return keywords.any((k) => name.contains(k));
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

  // -- Peso por serie ----------------------------------------------------------------

  Future<void> _loadLastWeights({
    required String workoutId,
    required String userId,
  }) async {
    if (_hasLoadedWeights) return;
    _hasLoadedWeights = true;
    try {
      List<dynamic> logs;
      try {
        final supabase = Supabase.instance.client;
        logs = await supabase
            .from('exercise_set_logs')
            .select('*')
            .eq('user_id', userId)
            .eq('workout_id', workoutId)
            .order('logged_at', ascending: false)
            .limit(600);
        unawaited(OfflineCacheService().saveSetLogs(workoutId, logs));
      } catch (e) {
        // Sin conexión: usar el historial guardado en el dispositivo
        logs = await OfflineCacheService().loadSetLogs(workoutId) ?? [];
      }

      final Map<int, Map<int, double?>> weights = {};
      final Map<int, double> prs = {};
      final Map<int, List<SetLog>> history = {};
      // La respuesta está ordenada desc ? la primera entrada de cada combo es la más reciente
      for (final log in logs) {
        final exIdx = log['exercise_index'] as int;
        final setIdx = log['set_index'] as int;
        final weightKg = (log['weight_kg'] as num?)?.toDouble();
        history
            .putIfAbsent(exIdx, () => [])
            .add(SetLog.fromJson((log as Map).cast<String, dynamic>()));
        if (!(weights.containsKey(exIdx) &&
            weights[exIdx]!.containsKey(setIdx))) {
          weights[exIdx] ??= {};
          weights[exIdx]![setIdx] = weightKg;
        }
        // PR = máximo histórico por ejercicio
        if (weightKg != null) {
          if (!prs.containsKey(exIdx) || weightKg > prs[exIdx]!) {
            prs[exIdx] = weightKg;
          }
        }
      }
      if (mounted) {
        // Copia profunda para conservar los valores de la última sesión sin mutarlos
        final lastSession = <int, Map<int, double?>>{};
        for (final e in weights.entries) {
          lastSession[e.key] = Map<int, double?>.from(e.value);
        }
        setState(() {
          _setWeights = weights;
          _applyResumedSets();
          _lastSessionWeights = lastSession;
          _exercisePRs = prs;
          _historyByExercise = history;
        });
      }
    } catch (e) {
      debugPrint('Error cargando Últimos pesos: $e');
    }
  }

  Future<void> _saveSetWeights({
    required String workoutId,
    required String userId,
    required Workout workout,
  }) async {
    try {
      if (_setWeights.isEmpty) return;
      final logs = <Map<String, dynamic>>[];
      final now = DateTime.now().toIso8601String();
      for (final exEntry in _setWeights.entries) {
        final exIdx = exEntry.key;
        final exercise =
            exIdx < workout.exercises.length ? workout.exercises[exIdx] : null;
        for (final setEntry in exEntry.value.entries) {
          if (setEntry.value != null) {
            final setIdx = setEntry.key;
            final completed = exIdx < _completedSets.length &&
                setIdx < _completedSets[exIdx].length &&
                _completedSets[exIdx][setIdx];
            logs.add({
              'user_id': userId,
              'workout_id': workoutId,
              'exercise_index': exIdx,
              'set_index': setIdx,
              'exercise_name': exercise?.name ?? '',
              'weight_kg': setEntry.value,
              // Reps reales (si el usuario las ajustó) o las planificadas
              'reps': _setReps[exIdx]?[setIdx] ?? exercise?.reps,
              'target_reps': exercise?.reps,
              'completed': completed,
              'logged_at': now,
            });
          }
        }
      }
      if (logs.isNotEmpty) {
        // Se encola automáticamente si no hay conexión
        await OfflineSyncQueue.instance.insert('exercise_set_logs', logs);
        // Mantener el historial local al día para las sugerencias offline
        final cached =
            await OfflineCacheService().loadSetLogs(workoutId) ?? <dynamic>[];
        unawaited(OfflineCacheService()
            .saveSetLogs(workoutId, [...logs, ...cached].take(600).toList()));
        debugPrint('Pesos guardados: ${logs.length} registros');
      }
    } catch (e) {
      debugPrint('Error guardando pesos: $e');
      if (mounted) {
        AppSnackbar.error(context, AppL10n.of(context).couldNotSaveWeights);
      }
    }
  }

  // Internamente los pesos se almacenan en kg; la UI los muestra en lbs.
  static const double _kgToLbs = 2.20462;
  static double _toLbs(double kg) => kg * _kgToLbs;
  static double _toKg(double lbs) => lbs / _kgToLbs;

  String _fmtWeight(double kg) {
    final lbs = _toLbs(kg);
    return lbs == lbs.roundToDouble()
        ? '${lbs.toInt()} lbs'
        : '${lbs.toStringAsFixed(1)} lbs';
  }

  void _showWeightDialog(int exerciseIndex, int setIndex, Exercise exercise) {
    // Peso de la sesión anterior para ESTA serie específica (puede diferir
    // de otras series del mismo ejercicio)
    final lastSessionWeight = _lastSessionWeights[exerciseIndex]?[setIndex];
    final currentWeight = _setWeights[exerciseIndex]?[setIndex];
    final pr = _exercisePRs[exerciseIndex];
    final adminWeight = exercise.weight > 0 ? exercise.weight : null;

    // Pre-rellenar: peso ya ingresado en esta sesión > último de esta serie > vacío
    final suggestion = currentWeight ??
        lastSessionWeight ??
        _autoWeightFor(exerciseIndex, setIndex);
    final suggestionLbs = suggestion != null ? _toLbs(suggestion) : null;
    final suggestionText = suggestionLbs != null
        ? (suggestionLbs == suggestionLbs.roundToDouble()
            ? suggestionLbs.toInt().toString()
            : suggestionLbs.toStringAsFixed(1))
        : '';

    final controller = TextEditingController(text: suggestionText);
    // Repeticiones reales de esta serie (por defecto, las planificadas)
    var repsValue = _setReps[exerciseIndex]?[setIndex] ?? exercise.reps;

    void saveWeight(String rawText, void Function() closeSheet,
        {bool bodyweight = false}) {
      if (bodyweight) rawText = '';
      final inputLbs = double.tryParse(rawText.replaceAll(',', '.'));
      if (rawText.trim().isNotEmpty && inputLbs == null) {
        AppSnackbar.error(context, AppL10n.of(context).enterValidNumber);
        return;
      }
      if (inputLbs != null && inputLbs <= 0) {
        AppSnackbar.error(context, AppL10n.of(context).weightMustBePositive);
        return;
      }
      // 0 = peso corporal (cuenta como registrado, no como récord)
      final double? weight =
          bodyweight ? 0.0 : (inputLbs != null ? _toKg(inputLbs) : null);
      final isNewPR =
          weight != null && weight > 0 && (pr == null || weight > pr);
      final alreadyCelebrated = _newPRsThisSession.contains(exerciseIndex);
      setState(() {
        _setWeights[exerciseIndex] ??= {};
        _setWeights[exerciseIndex]![setIndex] = weight;
        _setReps[exerciseIndex] ??= {};
        _setReps[exerciseIndex]![setIndex] = repsValue;
        if (isNewPR) {
          _exercisePRs[exerciseIndex] = weight;
          _newPRsThisSession.add(exerciseIndex);
        }
      });
      closeSheet();
      // Se celebra solo si supera una marca anterior (la primera vez que
      // registra un ejercicio no es "récord") y una vez por ejercicio.
      if (isNewPR && pr != null && !alreadyCelebrated) {
        showRecordCelebration(
          context,
          exerciseName: exercise.name,
          weightLabel: _fmtWeight(weight),
          previousLabel: _fmtWeight(pr),
        );
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // se redimensiona al subir el teclado
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          // sube el sheet cuando el teclado aparece
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                const SizedBox(height: 10),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),

                // Título: "Serie 2 — Peso usado"
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Text(
                        AppL10n.of(context).weightSetTitle(setIndex + 1),
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      // Referencias compactas (última sesión de ESTA serie, PR)
                      if (lastSessionWeight != null)
                        _CompactRef(
                          icon: Icons.history,
                          value: _fmtWeight(lastSessionWeight),
                          color: AppColors.primaryText,
                        ),
                      if (pr != null && pr != lastSessionWeight) ...[
                        const SizedBox(width: 8),
                        _CompactRef(
                          icon: Icons.emoji_events,
                          value: _fmtWeight(pr),
                          color: Colors.amber,
                        ),
                      ],
                      if (adminWeight != null &&
                          lastSessionWeight == null &&
                          pr == null) ...[
                        const SizedBox(width: 8),
                        _CompactRef(
                          icon: Icons.fitness_center,
                          // adminWeight ya está en lbs (ingresado por el admin)
                          value: adminWeight == adminWeight.roundToDouble()
                              ? '${adminWeight.toInt()} lbs'
                              : '${adminWeight.toStringAsFixed(1)} lbs',
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Campo principal — grande, centrado, texto pre-seleccionado
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: TextField(
                    controller: controller,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    autofocus: true,
                    textAlign: TextAlign.center,
                    onTap: () {
                      // Seleccionar todo el texto al abrir para facilitar reemplazo
                      controller.selection = TextSelection(
                        baseOffset: 0,
                        extentOffset: controller.text.length,
                      );
                    },
                    onSubmitted: (val) =>
                        saveWeight(val, () => Navigator.pop(ctx)),
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1,
                    ),
                    decoration: InputDecoration(
                      hintText: '0',
                      hintStyle: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                      suffixText: 'lbs',
                      suffixStyle: TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      border: InputBorder.none,
                      enabledBorder: UnderlineInputBorder(
                        borderSide:
                            BorderSide(color: AppColors.primaryText, width: 2),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide:
                            BorderSide(color: AppColors.primaryText, width: 2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Repeticiones realizadas (para la progresión inteligente)
                StatefulBuilder(
                  builder: (ctx2, setSheetState) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Text(
                          AppL10n.of(context).isEn
                              ? 'Reps done'
                              : 'Reps hechas',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
 tooltip: 'Restar',
                          onPressed: repsValue > 0
                              ? () => setSheetState(() => repsValue--)
                              : null,
                          icon: const Icon(Icons.remove_circle_outline),
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(
                          width: 44,
                          child: Text(
                            '$repsValue',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: repsValue < exercise.reps
                                  ? Colors.orangeAccent
                                  : AppColors.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
 tooltip: 'Sumar',
                          onPressed: () => setSheetState(() => repsValue++),
                          icon: const Icon(Icons.add_circle_outline),
                          color: AppColors.primaryText,
                        ),
                        Text(
                          '/ ${exercise.reps}',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Peso corporal (flexiones, dominadas, abdominales…)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => saveWeight('', () => Navigator.pop(ctx),
                          bodyweight: true),
                      icon: const Icon(Icons.accessibility_new, size: 20),
                      label: Text(AppL10n.of(context).isEn
                          ? 'Bodyweight (no extra load)'
                          : 'Peso corporal (sin carga)'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        minimumSize: const Size.fromHeight(48),
                        side: BorderSide(
                            color: AppColors.textSecondary
                                .withValues(alpha: 0.4)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Botón Listo
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () =>
                          saveWeight(controller.text, () => Navigator.pop(ctx)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        AppL10n.of(context).save,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() => controller.dispose());
  }

  /// Peso (kg) para una serie marcada sin peso anotado, o null si no hay
  /// ninguna referencia (ejercicio nuevo sin peso del entrenador).
  String? _exerciseNameAt(int exerciseIndex) {
    final id = widget.extraWorkoutId ??
        context.read<AuthProvider>().currentUser?.assignedWorkoutId;
    final w = id != null ? context.read<WorkoutProvider>().getWorkoutById(id) : null;
    if (w == null || exerciseIndex >= w.exercises.length) return null;
    return w.exercises[exerciseIndex].name;
  }

  double? _autoWeightFor(int exerciseIndex, int setIndex) {
    // 1. Serie anterior de este ejercicio en la sesión actual
    for (var i = setIndex - 1; i >= 0; i--) {
      final w = _setWeights[exerciseIndex]?[i];
      if (w != null) return w;
    }
    // 2. Sugerencia de progresión (o última sesión)
    final history = _historyByExercise[exerciseIndex];
    final effectiveId = widget.extraWorkoutId ??
        context.read<AuthProvider>().currentUser?.assignedWorkoutId;
    final workout = effectiveId != null
        ? context.read<WorkoutProvider>().getWorkoutById(effectiveId)
        : null;
    if (workout == null || exerciseIndex >= workout.exercises.length) {
      return null;
    }
    final exercise = workout.exercises[exerciseIndex];
    if (history != null && history.isNotEmpty) {
      final s = ProgressionEngine.suggest(
        logs: history,
        targetSets: exercise.sets,
        targetReps: exercise.reps,
        lowerBody:
            ProgressionEngine.isLowerBody(exercise.muscleGroup, exercise.name),
      );
      if (s != null) return s.suggestedWeightKg;
    }
    // 3. Peso indicado por el entrenador (en lbs)
    if (exercise.weight > 0) return exercise.weight / kKgToLbs;
    return null;
  }

  // -- Progresión inteligente ------------------------------------------------

  Widget _buildProgressionCard(Exercise exercise, int exerciseIndex) {
    if (_appliedSuggestions.contains(exerciseIndex)) {
      return const SizedBox.shrink();
    }
    final history = _historyByExercise[exerciseIndex];
    if (history == null || history.isEmpty) return const SizedBox.shrink();
    final suggestion = ProgressionEngine.suggest(
      logs: history,
      targetSets: exercise.sets,
      targetReps: exercise.reps,
      lowerBody: ProgressionEngine.isLowerBody(
          exercise.muscleGroup, exercise.name),
    );
    if (suggestion == null) return const SizedBox.shrink();

    final isEn = AppL10n.of(context).isEn;
    final next = _fmtWeight(suggestion.suggestedWeightKg);
    final last = _fmtWeight(suggestion.lastWeightKg);
    final done =
        '${suggestion.lastCompletedSets}/${suggestion.lastTargetSets}';

    late final IconData icon;
    late final Color color;
    late final String title;
    late final String detail;
    switch (suggestion.action) {
      case ProgressionAction.increase:
        icon = Icons.trending_up;
        color = AppColors.success;
        title = isEn ? 'Go up to $next today' : 'Hoy sube a $next';
        detail = isEn
            ? 'Last time you completed every set of ${suggestion.targetReps} reps with $last.'
            : 'La última vez completaste todas las series de ${suggestion.targetReps} reps con $last.';
        break;
      case ProgressionAction.maintain:
        icon = Icons.trending_flat;
        color = AppColors.primary;
        title = isEn ? 'Stay at $last' : 'Mantén $last';
        detail = isEn
            ? 'Last time $done sets reached ${suggestion.targetReps} reps. Complete them all to move up.'
            : 'La última vez lograste $done series de ${suggestion.targetReps} reps. Complétalas todas para subir.';
        break;
      case ProgressionAction.deload:
        icon = Icons.trending_down;
        color = Colors.orangeAccent;
        title = isEn ? 'Deload: use $next' : 'Descarga: usa $next';
        detail = isEn
            ? 'Two sessions in a row without completing $last. Go lighter today, focus on form and build back up.'
            : 'Dos sesiones seguidas sin completar $last. Baja hoy, cuida la técnica y vuelve a subir.';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          if (suggestion.action != ProgressionAction.maintain)
            TextButton(
              onPressed: () => _applySuggestion(
                  exerciseIndex, exercise.sets, suggestion.suggestedWeightKg),
              child: Text(
                isEn ? 'Apply' : 'Aplicar',
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  /// Pone el peso sugerido en todas las series aún no completadas.
  void _applySuggestion(int exerciseIndex, int sets, double weightKg) {
    HapticFeedback.mediumImpact();
    setState(() {
      _setWeights[exerciseIndex] ??= {};
      for (var i = 0; i < sets; i++) {
        final done = exerciseIndex < _completedSets.length &&
            i < _completedSets[exerciseIndex].length &&
            _completedSets[exerciseIndex][i];
        if (!done) _setWeights[exerciseIndex]![i] = weightKg;
      }
      _appliedSuggestions.add(exerciseIndex);
    });
  }

  /// Bottom sheet con historial de las Últimas sesiones del ejercicio.
  Future<void> _showExerciseHistory(
      int exerciseIndex, String exerciseName) async {
    final userId =
        Provider.of<AuthProvider>(context, listen: false).currentUser?.id;
    final workoutId = widget.extraWorkoutId ??
        Provider.of<AuthProvider>(context, listen: false)
            .currentUser
            ?.assignedWorkoutId;
    if (userId == null || workoutId == null) return;

    final supabase = Supabase.instance.client;
    List logs = [];
    try {
      logs = await supabase
          .from('exercise_set_logs')
          .select('set_index, weight_kg, reps, logged_at')
          .eq('user_id', userId)
          .eq('workout_id', workoutId)
          .eq('exercise_index', exerciseIndex)
          .order('logged_at', ascending: false)
          .limit(30);
    } catch (e) {
      debugPrint('Error loading set history: $e');
    }

    if (!mounted) return;

    // Agrupar por fecha (día)
    final Map<String, List<Map>> byDate = {};
    for (final log in logs) {
      final dt = DateTime.tryParse(log['logged_at'] as String? ?? '');
      if (dt == null) continue;
      final key =
          '${dt.toLocal().day}/${dt.toLocal().month}/${dt.toLocal().year}';
      byDate[key] ??= [];
      byDate[key]!.add(Map.from(log));
    }
    final sessions = byDate.entries.toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, scroll) => Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        exerciseName,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    // PR badge
                    if (_exercisePRs.containsKey(exerciseIndex))
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: Colors.amber.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.emoji_events, color: Color(0xFFFFB800), size: 16),
                            const SizedBox(width: 4),
                            Text(
                              _fmtWeight(_exercisePRs[exerciseIndex]!),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Divider(height: 24, color: AppColors.surface),
              Expanded(
                child: sessions.isEmpty
                    ? Center(
                        child: Text(
                          AppL10n.of(context).noPreviousHistory,
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 14),
                        ),
                      )
                    : ListView.builder(
                        controller: scroll,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: sessions.length,
                        itemBuilder: (_, i) {
                          final date = sessions[i].key;
                          final sets = sessions[i].value;
                          final maxW = sets
                              .map((s) =>
                                  (s['weight_kg'] as num?)?.toDouble() ?? 0.0)
                              .fold(0.0, (a, b) => a > b ? a : b);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        date,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        children: sets.map((s) {
                                          final w = (s['weight_kg'] as num?)
                                              ?.toDouble();
                                          final r = s['reps'] as int?;
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: AppColors.cardBackground,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              w != null
                                                  ? '${_fmtWeight(w)}${r != null ? ' × $r' : ''}'
                                                  : '–',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textPrimary.withValues(alpha: 0.7),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                                ),
                                if (maxW > 0)
                                  Text(
                                    _fmtWeight(maxW),
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryText,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Si la rutina fue completada, mostrar la pantalla de resumen directamente
    if (_workoutCompleted && _summaryWorkout != null) {
      return WorkoutSummaryScreen(
        workout: _summaryWorkout!,
        durationMinutes: _summaryDurationMinutes,
        caloriesBurned: _summaryCaloriesBurned,
        totalVolume: _summaryTotalVolume,
        completedSets: _completedSets,
        newRecords: _newPRsThisSession.length,
      );
    }

    final authProvider = Provider.of<AuthProvider>(context);
    final workoutProvider = Provider.of<WorkoutProvider>(context);
    final currentUser = authProvider.currentUser;

    final effectiveWorkoutId =
        widget.extraWorkoutId ?? currentUser?.assignedWorkoutId;

    if (effectiveWorkoutId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppL10n.of(context).myTodayWorkout),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.fitness_center_outlined,
                size: 80,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 24),
              Text(
                AppL10n.of(context).noAssignedWorkout,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                AppL10n.of(context).contactTrainer,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final workout = workoutProvider.getWorkoutById(effectiveWorkoutId);

    if (workout == null || workout.exercises.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppL10n.of(context).myTodayWorkout),
        ),
        body: Center(
          child: Text(
            AppL10n.of(context).loadingWorkoutError,
            style: TextStyle(color: AppColors.textPrimary),
          ),
        ),
      );
    }

    // Inicializar sets completados
    if (_completedSets.isEmpty) {
      _completedSets = workout.exercises
          .map((e) => List.generate(e.sets, (_) => false))
          .toList();
    }

    // Pre-descargar todos los videos en background una sola vez
    if (!_videosCacheStarted) {
      _videosCacheStarted = true;
      _preCacheVideos(workout.exercises);
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

    return PopScope(
      canPop: _workoutCompleted,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final choice = await _showExitWorkoutDialog();
        await _handleExitChoice(choice);
      },
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppL10n.of(context).myWorkoutHeader,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    workout.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              actions: [
                // Botón pausa / reanudar
                IconButton(
                  onPressed: _isPaused ? _resumeWorkout : _onManualPause,
                  icon: Icon(
                    _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                    color:
                        _isPaused ? AppColors.primaryText : AppColors.textSecondary,
                  ),
                  tooltip: _isPaused
                      ? AppL10n.of(context).resumeTooltip
                      : AppL10n.of(context).pauseTooltip,
                ),
                // Contador de sets totales
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primaryText),
                      ),
                      child: Text(
                        '$totalCompletedSets/$totalSets',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryText,
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
                        AlwaysStoppedAnimation<Color>(AppColors.primary),
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
                          return _buildExerciseContent(
                              exercise, index, workout);
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
 tooltip: 'Anterior',
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.surface.withValues(alpha: 0.9),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.chevron_left,
                                    color: AppColors.primaryText),
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
 tooltip: 'Siguiente',
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.surface.withValues(alpha: 0.9),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.chevron_right,
                                    color: AppColors.primaryText),
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
          // - Overlay de PAUSA eliminado: el botón pause ahora usa _onManualPause
        ],
      ), // Stack
    ); // PopScope
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
                  AppL10n.of(context)
                      .exerciseProgress(value, workout.exercises.length),
                  style: TextStyle(
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
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primaryText),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle,
                          size: 16, color: AppColors.primaryText),
                      const SizedBox(width: 4),
                      Text(
                        AppL10n.of(context).completedLabel.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryText,
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
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Muscle Group Tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primaryText),
            ),
            child: Text(
              exercise.muscleGroup.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryText,
                letterSpacing: 1,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Notas del ejercicio (visible antes del video)
          if (exercise.description != null)
            Builder(builder: (context) {
              final filtered = exercise.description!
                  .split('\n')
                  .where((line) => !RegExp(
                        r'^\s*(equipo|equipment)\s*:',
                        caseSensitive: false,
                      ).hasMatch(line))
                  .join('\n')
                  .trim();
              if (filtered.isEmpty) return const SizedBox.shrink();
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryText.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline,
                        size: 16, color: AppColors.primaryText),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        filtered,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

          // Video del ejercicio
          if (exercise.videoUrl != null && exercise.videoUrl!.isNotEmpty)
            Container(
              // Corto y en bucle, sin sonido: se ve la técnica sin tocar
              // nada. "Ver en grande" lo abre a pantalla completa.
              constraints: const BoxConstraints(maxHeight: 260),
              child: VideoPlayerWidget(
                videoUrl: exercise.videoUrl!,
                // Solo se reproduce el del ejercicio en pantalla
                autoPlay: exerciseIndex == _currentExerciseIndex,
                muted: true,
                looping: true,
                exerciseName: exercise.name,
                thumbnailUrl: exercise.thumbnailUrl,
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
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.videocam_off_outlined,
                      size: 64,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppL10n.of(context).videoUnavailable,
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

          // Sets Info
          Row(
            children: [
              _InfoCard(
                icon: Icons.fitness_center,
                label: AppL10n.of(context).setsLabel,
                value: exercise.sets.toString(),
              ),
              const SizedBox(width: 12),
              _InfoCard(
                icon: Icons.repeat,
                label: AppL10n.of(context).repsLabel,
                value: exercise.reps.toString(),
              ),
              const SizedBox(width: 12),
              _InfoCard(
                icon: Icons.timer,
                label: AppL10n.of(context).restLabel,
                value: '${exercise.restSeconds}s',
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Rest Timer Circular Mejorado
          if (_isResting && exerciseIndex == _currentExerciseIndex) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryText, width: 2),
              ),
              child: Column(
                children: [
                  Text(
                    AppL10n.of(context).restingTitle,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryText,
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
                              : AppColors.primaryText,
                        ),
                      ),
                      Text(
                        AppL10n.of(context).secondsLabel,
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
                    child: Text(
                      AppL10n.of(context).skipRest,
                      style: TextStyle(
                        color: AppColors.primaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // -- Progresión inteligente: peso sugerido para hoy --
          _buildProgressionCard(exercise, exerciseIndex),

          // -- Barra de referencia (PR + sugerencia admin + historial) --
          _ExerciseReferenceBar(
            onHistoryTap: () =>
                _showExerciseHistory(exerciseIndex, exercise.name),
          ),
          const SizedBox(height: 16),

          // Sets Checklist con animaciones
          Text(
            AppL10n.of(context).markCompletedSets,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
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
                child: Semantics(
                  button: true,
                  checked: isCompleted,
                  label: 'Serie ${setIndex + 1}, '
                      '${isCompleted ? 'hecha' : 'pendiente'}'
                      '${_setWeights[exerciseIndex]?[setIndex] == null ? ', sin peso' : _setWeights[exerciseIndex]![setIndex] == 0 ? ', peso corporal' : ', ${_fmtWeight(_setWeights[exerciseIndex]![setIndex]!)}'}',
                  onTapHint: isCompleted ? 'desmarcar' : 'marcar como hecha',
                  child: InkWell(
                  onTap: () => _toggleSet(exerciseIndex, setIndex),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppColors.primary.withValues(alpha: 0.2)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            isCompleted ? AppColors.primaryText : AppColors.surface,
                        width: 2,
                      ),
                      boxShadow: isCompleted
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
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
                                ? AppColors.primaryText
                                : AppColors.textSecondary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          AppL10n.of(context).setNumber(setIndex + 1),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color:
                                isCompleted ? AppColors.primaryText : AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        _WeightChip(
                          weight: _setWeights[exerciseIndex]?[setIndex],
                          suggested: isCompleted ||
                                  _isCardioExercise(exercise) ||
                                  _setWeights[exerciseIndex]?[setIndex] != null
                              ? null
                              : _autoWeightFor(exerciseIndex, setIndex),
                          reps: _setReps[exerciseIndex]?[setIndex] ??
                              exercise.reps,
                          belowTarget: (_setReps[exerciseIndex]?[setIndex] ??
                                  exercise.reps) <
                              exercise.reps,
                          isNewPR: _newPRsThisSession.contains(exerciseIndex) &&
                              _setWeights[exerciseIndex]?[setIndex] ==
                                  _exercisePRs[exerciseIndex],
                          missing: isCompleted &&
                              !_isCardioExercise(exercise) &&
                              _setWeights[exerciseIndex]?[setIndex] == null,
                          onTap: () => _showWeightDialog(
                              exerciseIndex, setIndex, exercise),
                        ),
                      ],
                    ),
                  ),
                )),
              ),
            );
          }),

          const SizedBox(height: 32),

          // Next Exercise Button
          PrimaryButton(
            text: exerciseIndex < workout.exercises.length - 1
                ? AppL10n.of(context).nextExercise
                : AppL10n.of(context).finishRoutine,
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
            Icon(icon, color: AppColors.primaryText, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
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

/// Muestra las reps del ejercicio y un chip para ingresar el peso usado.
// -- Barra de referencia PR / sugerencia admin -------------------------------
class _ExerciseReferenceBar extends StatelessWidget {
  final VoidCallback onHistoryTap;

  const _ExerciseReferenceBar({
    required this.onHistoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: _HistoryButton(onTap: onHistoryTap),
    );
  }
}

class _HistoryButton extends StatelessWidget {
  final VoidCallback onTap;
  const _HistoryButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_rounded,
                size: 15, color: AppColors.textSecondary),
            SizedBox(width: 4),
            Text(
              'Historial',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Referencia compacta (ícono + valor) para la barra superior del weight sheet.
class _CompactRef extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _CompactRef({
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _WeightChip extends StatelessWidget {
  final double? weight;
  /// Peso sugerido (kg) que se usará al marcar la serie con un toque.
  final double? suggested;
  final int reps;
  final bool isNewPR;
  final bool belowTarget;
  final bool missing;
  final VoidCallback onTap;

  const _WeightChip({
    required this.weight,
    this.suggested,
    required this.reps,
    required this.onTap,
    this.isNewPR = false,
    this.belowTarget = false,
    this.missing = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasWeight = weight != null;
    final shown = weight ?? suggested;
    // weight está en kg internamente; mostrar en lbs
    final lbs = shown != null ? shown * 2.20462 : null;
    final weightLabel = shown == 0
        ? 'corporal'
        : lbs != null
        ? (lbs == lbs.roundToDouble()
            ? '${lbs.toInt()} lbs'
            : '${lbs.toStringAsFixed(1)} lbs')
        : '+ peso';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$reps reps',
          style: TextStyle(
            fontSize: 14,
            color: belowTarget ? Colors.orangeAccent : AppColors.textSecondary,
            fontWeight: belowTarget ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isNewPR
                  ? Colors.amber.withValues(alpha: 0.18)
                  : hasWeight
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isNewPR
                    ? Colors.amber
                    : hasWeight
                        ? AppColors.primaryText
                        : missing
                            ? Colors.orangeAccent
                            : AppColors.textSecondary.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isNewPR) ...[
                  const Icon(Icons.emoji_events, color: Color(0xFFFFB800), size: 14),
                  const SizedBox(width: 4),
                ],
                Text(
                  weightLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isNewPR
                        ? Colors.amber
                        : hasWeight
                            ? AppColors.primaryText
                            : missing
                                ? Colors.orangeAccent
                                : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
