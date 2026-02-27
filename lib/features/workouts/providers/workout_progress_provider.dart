import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/workout_progress.dart';

class WorkoutProgressProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  WorkoutProgress? _currentProgress;
  bool _isLoading = false;

  WorkoutProgress? get currentProgress => _currentProgress;
  bool get isLoading => _isLoading;
  bool get hasProgress =>
      _currentProgress != null && !_currentProgress!.isExpired;

  // ID del workout completado HOY (flag en memoria, se resetea al reiniciar la app)
  String? _completedWorkoutIdToday;
  String? get completedWorkoutIdToday => _completedWorkoutIdToday;

  void clearTodayCompletion() {
    _completedWorkoutIdToday = null;
    notifyListeners();
  }

  // Cargar progreso del usuario actual
  Future<void> loadProgress(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase
          .from('workout_progress')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        _currentProgress = WorkoutProgress.fromJson(response);

        // Si está expirado, eliminarlo automáticamente
        if (_currentProgress!.isExpired) {
          await deleteProgress();
          _currentProgress = null;
        }
      } else {
        _currentProgress = null;
      }
    } catch (e) {
      debugPrint('Error loading workout progress: $e');
      _currentProgress = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Guardar o actualizar progreso
  Future<void> saveProgress({
    required String userId,
    required String workoutId,
    required int exerciseIndex,
    required List<List<bool>> completedSets,
  }) async {
    try {
      final data = {
        'user_id': userId,
        'workout_id': workoutId,
        'exercise_index': exerciseIndex,
        'completed_sets': completedSets,
      };

      // Usar upsert para insertar o actualizar
      final response = await _supabase
          .from('workout_progress')
          .upsert(data, onConflict: 'user_id')
          .select()
          .single();

      _currentProgress = WorkoutProgress.fromJson(response);
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving workout progress: $e');
      rethrow;
    }
  }

  // Eliminar progreso (al completar rutina o descartar)
  Future<void> deleteProgress() async {
    if (_currentProgress == null) return;

    try {
      await _supabase
          .from('workout_progress')
          .delete()
          .eq('id', _currentProgress!.id);

      _currentProgress = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting workout progress: $e');
      rethrow;
    }
  }

  // Limpiar progreso sin notificar (para uso interno)
  void clearProgress() {
    _currentProgress = null;
    notifyListeners();
  }

  // Verificar si el progreso pertenece a un workout específico
  bool isProgressForWorkout(String workoutId) {
    return _currentProgress?.workoutId == workoutId && hasProgress;
  }

  // Completar workout y guardarlo en workout_sessions
  Future<void> completeWorkout({
    required String userId,
    required String workoutId,
    required int durationMinutes,
    required int exercisesCompleted,
    int caloriesBurned = 0,
    double totalVolumeKg = 0,
  }) async {
    try {
      // Guardar sesión en workout_sessions
      await _supabase.from('workout_sessions').insert({
        'user_id': userId,
        'workout_id': workoutId,
        'completed_at': DateTime.now().toIso8601String(),
        'duration_minutes': durationMinutes,
        'exercises_completed': exercisesCompleted,
        'calories_burned': caloriesBurned,
        'total_volume_kg': totalVolumeKg,
      });

      debugPrint('✅ Workout session guardada en base de datos');

      // Guardar el ID del progreso ANTES de borrarlo en memoria
      final progressId = _currentProgress?.id;

      // Limpiar TODO en memoria de forma atómica — el banner desaparece en el mismo rebuild
      _completedWorkoutIdToday = workoutId;
      _currentProgress = null;
      notifyListeners();

      // Eliminar progreso temporal de la BD (después del rebuild de UI)
      if (progressId != null) {
        await _supabase.from('workout_progress').delete().eq('id', progressId);
        debugPrint('🗑️ Progreso temporal eliminado de BD (id=$progressId)');
      }

      return;
    } catch (e) {
      debugPrint('❌ Error al completar workout: $e');
      rethrow;
    }
  }

  // Obtener la próxima sesión programada
  Future<Map<String, dynamic>?> getNextScheduledWorkout(String userId) async {
    try {
      // Obtener día de la semana actual (1 = Lunes, 7 = Domingo)
      final today = DateTime.now();
      final currentDayOfWeek = today.weekday;

      // Buscar próxima sesión en user_workout_schedule
      final scheduleResponse = await _supabase
          .from('user_workout_schedule')
          .select('day_of_week, workout_id')
          .eq('user_id', userId)
          .order('day_of_week');

      if (scheduleResponse.isEmpty) return null;

      final schedule = scheduleResponse as List;

      debugPrint(
          '📅 getNextScheduledWorkout: currentDayOfWeek=$currentDayOfWeek (hoy=${[
        '',
        'Lun',
        'Mar',
        'Mié',
        'Jue',
        'Vie',
        'Sáb',
        'Dom'
      ][currentDayOfWeek]})');
      debugPrint(
          '📅 Días en BD: ${schedule.map((s) => '${s['day_of_week']}').join(', ')}');

      // Encontrar el próximo día
      int? nextDay;
      String? nextWorkoutId;

      // Buscar primer día mayor al actual
      for (var item in schedule) {
        final dayOfWeek = item['day_of_week'] as int;
        if (dayOfWeek > currentDayOfWeek) {
          nextDay = dayOfWeek;
          nextWorkoutId = item['workout_id'];
          break;
        }
      }

      // Si no hay días mayores, tomar el primer día de la semana siguiente
      if (nextDay == null && schedule.isNotEmpty) {
        nextDay = schedule.first['day_of_week'] as int;
        nextWorkoutId = schedule.first['workout_id'];
      }

      if (nextDay == null || nextWorkoutId == null) return null;

      // Calcular cuántos días faltan
      int daysUntilNext;
      if (nextDay > currentDayOfWeek) {
        daysUntilNext = nextDay - currentDayOfWeek;
      } else {
        daysUntilNext = (7 - currentDayOfWeek) + nextDay;
      }

      final nextDate = today.add(Duration(days: daysUntilNext));

      return {
        'day_of_week': nextDay,
        'workout_id': nextWorkoutId,
        'date': nextDate,
        'days_until': daysUntilNext,
      };
    } catch (e) {
      debugPrint('❌ Error al obtener próxima sesión: $e');
      return null;
    }
  }
}
