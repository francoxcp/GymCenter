import 'package:flutter/material.dart';
import '../../auth/models/user.dart';
import '../../../config/supabase_config.dart';
import '../../../core/constants/app_constants.dart';

class UserProvider extends ChangeNotifier {
  List<User> _users = [];
  User? _currentUser;
  String _searchQuery = '';
  bool _isLoading = false;

  List<User> get users => _users;
  User? get currentUser => _currentUser;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;

  UserProvider() {
    loadUsers();
    loadCurrentUser();
  }

  Future<void> loadCurrentUser() async {
    try {
      final currentUserId = SupabaseConfig.client.auth.currentUser?.id;
      if (currentUserId == null) return;

      final response = await SupabaseConfig.client
          .from(AppConstants.usersTable)
          .select()
          .eq('id', currentUserId)
          .single();

      _currentUser = User.fromJson(response);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading current user: $e');
    }
  }

  Future<void> loadUsers() async {
    try {
      debugPrint('🔄 Cargando usuarios desde Supabase...');
      _isLoading = true;
      notifyListeners();

      final response = await SupabaseConfig.client
          .from(AppConstants.usersTable)
          .select()
          .order(AppConstants.createdAtField, ascending: false);

      _users = (response as List).map((json) => User.fromJson(json)).toList();

      debugPrint('✅ Usuarios cargados: ${_users.length}');
      for (var user in _users) {
        debugPrint('   - ${user.name} (${user.email}) - Role: ${user.role}');
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('❌ Error loading users: $e');
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  List<User> get filteredUsers {
    if (_searchQuery.isEmpty) {
      return _users;
    }
    return _users.where((user) {
      return user.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.email.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Future<void> assignWorkout(String userId, String workoutId) async {
    try {
      await SupabaseConfig.client
          .from(AppConstants.usersTable)
          .update({'assigned_workout_id': workoutId}).eq('id', userId);

      // Actualizar localmente
      final userIndex = _users.indexWhere((u) => u.id == userId);
      if (userIndex != -1) {
        _users[userIndex] = _users[userIndex].copyWith(
          assignedWorkoutId: workoutId,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error assigning workout: $e');
      rethrow;
    }
  }

  Future<void> assignMealPlan(String userId, String mealPlanId) async {
    try {
      await SupabaseConfig.client
          .from(AppConstants.usersTable)
          .update({'assigned_meal_plan_id': mealPlanId}).eq('id', userId);

      // Actualizar localmente
      final userIndex = _users.indexWhere((u) => u.id == userId);
      if (userIndex != -1) {
        _users[userIndex] = _users[userIndex].copyWith(
          assignedMealPlanId: mealPlanId,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error assigning meal plan: $e');
      rethrow;
    }
  }

  Future<void> assignBoth(
      String userId, String workoutId, String mealPlanId) async {
    try {
      await SupabaseConfig.client.from('users').update({
        'assigned_workout_id': workoutId,
        'assigned_meal_plan_id': mealPlanId,
      }).eq('id', userId);

      // Actualizar localmente
      final userIndex = _users.indexWhere((u) => u.id == userId);
      if (userIndex != -1) {
        _users[userIndex] = _users[userIndex].copyWith(
          assignedWorkoutId: workoutId,
          assignedMealPlanId: mealPlanId,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error assigning workout and meal plan: $e');
      rethrow;
    }
  }

  Future<void> assignWorkoutByDay(
      String userId, String workoutId, List<int> days) async {
    try {
      for (final day in days) {
        await SupabaseConfig.client.from('user_workout_schedule').upsert({
          'user_id': userId,
          'day_of_week': day,
          'workout_id': workoutId,
        });
      }
      // Recargar usuarios o rutinas si es necesario
      notifyListeners();
    } catch (e) {
      debugPrint('Error assigning workout by day: $e');
      rethrow;
    }
  }

  Future<void> updateUserStats(
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
          .from('users')
          .update(updates)
          .eq('id', userId);

      // Actualizar localmente
      final userIndex = _users.indexWhere((u) => u.id == userId);
      if (userIndex != -1) {
        _users[userIndex] = _users[userIndex].copyWith(
          activeDays: activeDays,
          completedWorkouts: completedWorkouts,
          level: level,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating user stats: $e');
      rethrow;
    }
  }

  User? getUserById(String userId) {
    try {
      return _users.firstWhere((u) => u.id == userId);
    } catch (e) {
      return null;
    }
  }

  Future<void> updateUser(
    String userId, {
    String? name,
    String? photoUrl,
    String? role,
  }) async {
    try {
      final Map<String, dynamic> updates = {};
      if (name != null) updates['name'] = name;
      if (photoUrl != null) updates['photo_url'] = photoUrl;
      if (role != null) updates['role'] = role;

      if (updates.isEmpty) return;

      await SupabaseConfig.client
          .from('users')
          .update(updates)
          .eq('id', userId);

      await loadUsers();
    } catch (e) {
      debugPrint('Error updating user: $e');
      rethrow;
    }
  }

  Future<void> toggleUserStatus(String userId, bool isActive) async {
    try {
      await SupabaseConfig.client
          .from('users')
          .update({'is_active': isActive}).eq('id', userId);

      await loadUsers();
    } catch (e) {
      debugPrint('Error toggling user status: $e');
      rethrow;
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      // Esto también eliminará el usuario de auth.users debido a CASCADE
      await SupabaseConfig.client.from('users').delete().eq('id', userId);

      await loadUsers();
    } catch (e) {
      debugPrint('Error deleting user: $e');
      rethrow;
    }
  }

  /// Obtiene la rutina asignada para el usuario en el día actual
  Future<String?> getTodayWorkoutId(String userId) async {
    final now = DateTime.now();
    // Lunes=1, ..., Sábado=6
    final today = now.weekday;
    if (today < 1 || today > 6) return null; // Solo lunes a sábado
    final response = await SupabaseConfig.client
        .from('user_workout_schedule')
        .select('workout_id')
        .eq('user_id', userId)
        .eq('day_of_week', today)
        .maybeSingle();
    return response != null ? response['workout_id'] as String? : null;
  }

  /// Obtiene todas las rutinas asignadas para la semana
  Future<Map<int, String>> getWeekWorkouts(String userId) async {
    final response = await SupabaseConfig.client
        .from('user_workout_schedule')
        .select('day_of_week, workout_id')
        .eq('user_id', userId);
    final Map<int, String> weekWorkouts = {};
    for (final item in response as List) {
      weekWorkouts[item['day_of_week'] as int] = item['workout_id'] as String;
    }
    return weekWorkouts;
  }

  /// Limpia todas las asignaciones de rutina y plan de un usuario
  Future<void> clearUserAssignments(String userId) async {
    // Limpiar campos en tabla users
    await SupabaseConfig.client.from(AppConstants.usersTable).update({
      'assigned_workout_id': null,
      'assigned_meal_plan_id': null,
    }).eq('id', userId);
    // Eliminar asignaciones de rutina por día
    await SupabaseConfig.client
        .from('user_workout_schedule')
        .delete()
        .eq('user_id', userId);
    notifyListeners();
  }
}
