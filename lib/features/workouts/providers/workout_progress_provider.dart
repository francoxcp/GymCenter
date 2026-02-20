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
}
