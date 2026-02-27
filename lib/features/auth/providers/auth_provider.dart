import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../models/user.dart';
import '../../../config/supabase_config.dart';
import '../../../core/constants/app_constants.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  User? _currentUser;
  bool _isLoading = false;

  bool get isAuthenticated => _isAuthenticated;
  User? get currentUser => _currentUser;
  bool get isAdmin => _currentUser?.role == 'admin';
  bool get isLoading => _isLoading;
  String get initialRoute =>
      isAdmin ? AppConstants.adminRoute : AppConstants.homeRoute;

  AuthProvider() {
    _initAuthListener();
  }

  void _initAuthListener() {
    // Escuchar cambios de autenticación
    SupabaseConfig.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        _loadCurrentUser(session.user.id);
      } else if (data.event == AuthChangeEvent.signedOut) {
        // Solo limpiar sesión cuando el cierre es explícito (logout manual)
        _isAuthenticated = false;
        _currentUser = null;
        notifyListeners();
      }
      // Otros eventos con session==null (ej: tokenRefreshFailed momentáneo)
      // no cierran la sesión — Supabase reintentará el refresh automáticamente
    });

    // Verificar si ya hay sesión activa al arrancar
    final session = SupabaseConfig.auth.currentSession;
    if (session != null) {
      _loadCurrentUser(session.user.id);
    }
  }

  Future<void> _loadCurrentUser(String userId) async {
    try {
      debugPrint('🔍 Loading user with ID: $userId');
      final response = await SupabaseConfig.client
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      debugPrint('✅ User data loaded: ${response.toString()}');
      debugPrint('📋 assigned_workout_id: ${response['assigned_workout_id']}');
      _currentUser = User.fromJson(response);
      _isAuthenticated = true;
      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR loading user: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      debugPrint('🔐 Attempting login for: $email');

      final response = await SupabaseConfig.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        debugPrint('✅ Login successful, loading user data...');
        await _loadCurrentUser(response.user!.id);
        _isLoading = false;
        notifyListeners();
        return true;
      }

      debugPrint('⚠️ Login failed: No user returned');
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('❌ Login error: $e');
      rethrow; // Re-lanzar para que el UI pueda mostrar el error apropiado
    }
  }

  Future<bool> register(String email, String password, String name) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await SupabaseConfig.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'role': 'user',
        },
      );

      if (response.user != null) {
        // El trigger handle_new_user() en Supabase creará el registro en users
        await Future.delayed(AppConstants.userCreationDelay);
        await _loadCurrentUser(response.user!.id);
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Register error: $e');
      rethrow;
    }
  }

  Future<bool> forgotPassword(String email) async {
    try {
      _isLoading = true;
      notifyListeners();

      await SupabaseConfig.auth.resetPasswordForEmail(email);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Forgot password error: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await SupabaseConfig.auth.signOut();
      _isAuthenticated = false;
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Logout error: $e');
    }
  }

  void updateUser(User user) {
    _currentUser = user;
    notifyListeners();
  }

  Future<void> refreshUser() async {
    if (_currentUser != null) {
      await _loadCurrentUser(_currentUser!.id);
    }
  }
}
