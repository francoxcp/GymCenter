import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FunctionException;
import '../../auth/models/user.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../config/supabase_config.dart';
import '../../../core/constants/app_constants.dart';

class UserProvider extends ChangeNotifier {
  List<User> _users = [];
  User? _currentUser;
  String _searchQuery = '';
  bool _isLoading = false;
  AuthProvider? _authProvider;

  List<User> get users => _users;
  User? get currentUser => _currentUser;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;

  // No cargar en el constructor — los datos se cargan de forma lazy en las pantallas

  void setAuthProvider(AuthProvider authProvider) {
    _authProvider = authProvider;
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

      // Actualizar AuthProvider si es el usuario actual
      if (_authProvider?.currentUser?.id == userId) {
        await _authProvider!.refreshUser();
      }
    } catch (e) {
      debugPrint('Error assigning workout: $e');
      rethrow;
    }
  }

  /// Asigna una rutina a un día específico (delete + insert)
  Future<void> assignWorkoutToDay(
      String userId, int dayOfWeek, String workoutId) async {
    try {
      // Eliminar la asignación existente para ese día (si existe)
      await SupabaseConfig.client
          .from('user_workout_schedule')
          .delete()
          .eq('user_id', userId)
          .eq('day_of_week', dayOfWeek);

      // Insertar la nueva asignación
      await SupabaseConfig.client.from('user_workout_schedule').insert({
        'user_id': userId,
        'day_of_week': dayOfWeek,
        'workout_id': workoutId,
      });

      // Actualizar assigned_workout_id con la rutina más reciente
      await SupabaseConfig.client
          .from(AppConstants.usersTable)
          .update({'assigned_workout_id': workoutId}).eq('id', userId);

      final userIndex = _users.indexWhere((u) => u.id == userId);
      if (userIndex != -1) {
        _users[userIndex] =
            _users[userIndex].copyWith(assignedWorkoutId: workoutId);
      }
      if (_authProvider?.currentUser?.id == userId) {
        await _authProvider!.refreshUser();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error assignWorkoutToDay: $e');
      rethrow;
    }
  }

  /// Sincroniza solo el campo assigned_workout_id del usuario (sin tocar el horario).
  /// Pasa null para limpiar la referencia cuando el usuario no tiene ninguna rutina en la semana.
  Future<void> syncAssignedWorkout(String userId, String? workoutId) async {
    try {
      await SupabaseConfig.client
          .from(AppConstants.usersTable)
          .update({'assigned_workout_id': workoutId}).eq('id', userId);

      final idx = _users.indexWhere((u) => u.id == userId);
      if (idx != -1) {
        _users[idx] = _users[idx].copyWith(assignedWorkoutId: workoutId);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error syncAssignedWorkout: $e');
      rethrow;
    }
  }

  /// Quita la rutina de un día específico (lo pone en "Descanso")
  Future<void> removeWorkoutFromDay(String userId, int dayOfWeek) async {
    try {
      await SupabaseConfig.client
          .from('user_workout_schedule')
          .delete()
          .eq('user_id', userId)
          .eq('day_of_week', dayOfWeek);

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error removeWorkoutFromDay: $e');
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

  /// El dueño asigna (o quita, con null) el entrenador de un socio.
  Future<void> assignTrainer(String userId, String? trainerId) async {
    await SupabaseConfig.client
        .from(AppConstants.usersTable)
        .update({'trainer_id': trainerId}).eq('id', userId);
    final i = _users.indexWhere((u) => u.id == userId);
    if (i != -1) {
      _users[i] = _users[i].copyWith(trainerId: trainerId);
      notifyListeners();
    }
  }

  /// Da de alta un socio (Edge Function create-member).
  /// Devuelve null si salió bien, o un código de error.
  Future<String?> createMember({
    required String name,
    required String email,
    required String password,
    String? trainerId,
  }) async {
    try {
      final res = await SupabaseConfig.client.functions.invoke(
        'create-member',
        body: {
          'name': name.trim(),
          'email': email.trim(),
          'password': password,
          if (trainerId != null) 'trainer_id': trainerId,
        },
      );
      final data = res.data;
      if (data is Map && data['error'] != null) return data['error'] as String;
      await loadUsers();
      return null;
    } on FunctionException catch (e) {
      final details = e.details;
      if (details is Map && details['error'] is String) {
        return details['error'] as String;
      }
      debugPrint('createMember error: ${e.status} ${e.details}');
      return 'create_failed';
    } catch (e) {
      debugPrint('createMember error: $e');
      return 'create_failed';
    }
  }

  /// Asigna una contraseña temporal a un socio (y activa su cuenta si no
  /// estaba confirmada). Devuelve null si salió bien, o un código de error.
  Future<String?> resetMemberPassword(String userId, String password) async {
    try {
      final res = await SupabaseConfig.client.functions.invoke(
        'reset-member-password',
        body: {'user_id': userId, 'password': password},
      );
      final data = res.data;
      if (data is Map && data['error'] != null) return data['error'] as String;
      return null;
    } on FunctionException catch (e) {
      final details = e.details;
      if (details is Map && details['error'] is String) {
        return details['error'] as String;
      }
      return 'reset_failed';
    } catch (e) {
      debugPrint('resetMemberPassword error: $e');
      return 'reset_failed';
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

  /// Elimina por completo a un usuario (cuenta de acceso + perfil + datos)
  /// mediante la Edge Function delete-member. Antes solo se borraba el
  /// perfil y la persona podía seguir iniciando sesión.
  Future<void> deleteUser(String userId) async {
    try {
      final res = await SupabaseConfig.client.functions
          .invoke('delete-member', body: {'user_id': userId});
      final data = res.data;
      if (data is Map && data['error'] != null) {
        throw Exception(data['error']);
      }
      _users.removeWhere((u) => u.id == userId);
      notifyListeners();
      await loadUsers();
    } on FunctionException catch (e) {
      debugPrint('Error deleting user: ${e.status} ${e.details}');
      final details = e.details;
      throw Exception(details is Map ? details['error'] : 'delete_failed');
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

    // Actualizar lista local de inmediato para que la UI refleje el cambio sin esperar loadUsers
    final idx = _users.indexWhere((u) => u.id == userId);
    if (idx != -1) {
      _users[idx] = _users[idx].copyWith(
        assignedWorkoutId: null,
        assignedMealPlanId: null,
      );
    }
    notifyListeners();

    // Actualizar AuthProvider si es el usuario actual
    if (_authProvider?.currentUser?.id == userId) {
      await _authProvider!.refreshUser();
    }
  }
}
