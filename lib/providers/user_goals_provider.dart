import 'package:flutter/foundation.dart';
import '../config/supabase_config.dart';
import '../models/user_goal.dart';

class UserGoalsProvider extends ChangeNotifier {
  List<UserGoal> _goals = [];
  bool _isLoading = false;

  List<UserGoal> get goals => _goals;
  List<UserGoal> get activeGoals =>
      _goals.where((g) => g.isActive && !g.isExpired).toList();
  bool get isLoading => _isLoading;

  // Cargar metas del usuario
  Future<void> loadGoals(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await SupabaseConfig.client
          .from('user_goals')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      _goals =
          (response as List).map((json) => UserGoal.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error loading goals: $e');
      _goals = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Crear nueva meta
  Future<void> createGoal({
    required String userId,
    required String goalType,
    required String title,
    required double targetValue,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final data = {
        'user_id': userId,
        'goal_type': goalType,
        'title': title,
        'target_value': targetValue,
        'current_value': 0,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'is_active': true,
      };

      await SupabaseConfig.client.from('user_goals').insert(data);
      await loadGoals(userId);
    } catch (e) {
      debugPrint('Error creating goal: $e');
      rethrow;
    }
  }

  // Actualizar progreso de meta
  Future<void> updateGoalProgress(String goalId, double newValue) async {
    try {
      await SupabaseConfig.client
          .from('user_goals')
          .update({'current_value': newValue}).eq('id', goalId);

      // Actualizar localmente
      final index = _goals.indexWhere((g) => g.id == goalId);
      if (index != -1) {
        _goals[index] = _goals[index].copyWith(
          currentValue: newValue,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating goal progress: $e');
      rethrow;
    }
  }

  // Eliminar meta
  Future<void> deleteGoal(String goalId) async {
    try {
      await SupabaseConfig.client.from('user_goals').delete().eq('id', goalId);

      _goals.removeWhere((g) => g.id == goalId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting goal: $e');
      rethrow;
    }
  }

  // Desactivar meta
  Future<void> deactivateGoal(String goalId) async {
    try {
      await SupabaseConfig.client
          .from('user_goals')
          .update({'is_active': false}).eq('id', goalId);

      final index = _goals.indexWhere((g) => g.id == goalId);
      if (index != -1) {
        _goals[index] = _goals[index].copyWith(isActive: false);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error deactivating goal: $e');
      rethrow;
    }
  }

  // Recalcular progreso de meta de peso basado en calorías
  Future<void> recalculateWeightGoal(
      String userId, String goalId, DateTime startDate) async {
    try {
      // Obtener calorías quemadas desde la fecha de inicio
      final sessions = await SupabaseConfig.client
          .from('workout_sessions')
          .select('calories_burned')
          .eq('user_id', userId)
          .gte('completed_at', startDate.toIso8601String());

      // Sumar calorías totales
      int totalCalories = 0;
      for (var session in sessions as List) {
        totalCalories += (session['calories_burned'] as int?) ?? 0;
      }

      // Calcular kg perdidos: 7,700 cal = 1 kg
      final kgLost = totalCalories / 7700;

      await updateGoalProgress(goalId, kgLost);
    } catch (e) {
      debugPrint('Error recalculating weight goal: $e');
      rethrow;
    }
  }

  // Recalcular progreso de meta de calorías
  Future<void> recalculateCaloriesGoal(
      String userId, String goalId, DateTime startDate) async {
    try {
      final sessions = await SupabaseConfig.client
          .from('workout_sessions')
          .select('calories_burned')
          .eq('user_id', userId)
          .gte('completed_at', startDate.toIso8601String());

      int totalCalories = 0;
      for (var session in sessions as List) {
        totalCalories += (session['calories_burned'] as int?) ?? 0;
      }

      await updateGoalProgress(goalId, totalCalories.toDouble());
    } catch (e) {
      debugPrint('Error recalculating calories goal: $e');
      rethrow;
    }
  }

  // Recalcular progreso de meta de entrenamientos
  Future<void> recalculateWorkoutsGoal(
      String userId, String goalId, DateTime startDate) async {
    try {
      final sessions = await SupabaseConfig.client
          .from('workout_sessions')
          .select('completed_at')
          .eq('user_id', userId)
          .gte('completed_at', startDate.toIso8601String());

      // Contar días únicos con entrenamientos
      final uniqueDays = <String>{};
      for (var session in sessions as List) {
        final date = DateTime.parse(session['completed_at'] as String);
        uniqueDays.add('${date.year}-${date.month}-${date.day}');
      }

      await updateGoalProgress(goalId, uniqueDays.length.toDouble());
    } catch (e) {
      debugPrint('Error recalculating workouts goal: $e');
      rethrow;
    }
  }

  // Recalcular todas las metas activas del usuario
  Future<void> recalculateAllGoals(String userId) async {
    for (var goal in activeGoals) {
      switch (goal.goalType) {
        case 'weight':
          await recalculateWeightGoal(userId, goal.id, goal.startDate);
          break;
        case 'calories':
          await recalculateCaloriesGoal(userId, goal.id, goal.startDate);
          break;
        case 'workouts':
          await recalculateWorkoutsGoal(userId, goal.id, goal.startDate);
          break;
      }
    }
  }
}
