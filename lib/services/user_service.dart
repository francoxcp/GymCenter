import '../config/supabase_config.dart';
import '../config/app_constants.dart';
import '../models/user.dart';

/// Servicio para operaciones relacionadas con usuarios
class UserService {
  /// Obtiene todos los usuarios ordenados por fecha de creación
  static Future<List<User>> getAllUsers() async {
    try {
      final response = await SupabaseConfig.client
          .from(AppConstants.usersTable)
          .select()
          .order(AppConstants.createdAtField, ascending: false);

      return (response as List).map((json) => User.fromJson(json)).toList();
    } catch (e) {
      throw Exception('${AppConstants.errorLoadingUsers}: $e');
    }
  }

  /// Obtiene un usuario por ID
  static Future<User> getUserById(String userId) async {
    try {
      final response = await SupabaseConfig.client
          .from(AppConstants.usersTable)
          .select()
          .eq('id', userId)
          .single();

      return User.fromJson(response);
    } catch (e) {
      throw Exception('Error al obtener usuario: $e');
    }
  }

  /// Asigna una rutina a un usuario
  static Future<void> assignWorkout(String userId, String workoutId) async {
    try {
      await SupabaseConfig.client
          .from(AppConstants.usersTable)
          .update({'assigned_workout_id': workoutId}).eq('id', userId);
    } catch (e) {
      throw Exception('${AppConstants.errorAssigning} rutina: $e');
    }
  }

  /// Asigna un plan de comida a un usuario
  static Future<void> assignMealPlan(String userId, String mealPlanId) async {
    try {
      await SupabaseConfig.client
          .from(AppConstants.usersTable)
          .update({'assigned_meal_plan_id': mealPlanId}).eq('id', userId);
    } catch (e) {
      throw Exception('${AppConstants.errorAssigning} plan de comida: $e');
    }
  }

  /// Asigna rutina y plan de comida a un usuario
  static Future<void> assignBoth(
    String userId,
    String workoutId,
    String mealPlanId,
  ) async {
    try {
      await SupabaseConfig.client.from(AppConstants.usersTable).update({
        'assigned_workout_id': workoutId,
        'assigned_meal_plan_id': mealPlanId,
      }).eq('id', userId);
    } catch (e) {
      throw Exception('${AppConstants.errorAssigning} rutina y plan: $e');
    }
  }

  /// Actualiza las estadísticas de un usuario
  static Future<void> updateUserStats(
    String userId, {
    int? activeDays,
    int? completedWorkouts,
    String? level,
  }) async {
    try {
      final Map<String, dynamic> updates = {};
      if (activeDays != null) updates['active_days'] = activeDays;
      if (completedWorkouts != null) {
        updates['completed_workouts'] = completedWorkouts;
      }
      if (level != null) updates['level'] = level;

      if (updates.isEmpty) return;

      await SupabaseConfig.client
          .from(AppConstants.usersTable)
          .update(updates)
          .eq('id', userId);
    } catch (e) {
      throw Exception('Error al actualizar estadísticas: $e');
    }
  }
}
