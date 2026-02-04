import 'package:flutter/material.dart';
import '../models/user.dart';
import '../config/supabase_config.dart';
import '../config/app_constants.dart';

class UserProvider extends ChangeNotifier {
  List<User> _users = [];
  String _searchQuery = '';
  bool _isLoading = false;

  List<User> get users => _users;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;

  UserProvider() {
    loadUsers();
  }

  Future<void> loadUsers() async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await SupabaseConfig.client
          .from(AppConstants.usersTable)
          .select()
          .order(AppConstants.createdAtField, ascending: false);

      _users = (response as List).map((json) => User.fromJson(json)).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Error loading users: $e');
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
}
