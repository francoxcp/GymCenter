import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../models/user.dart';
import '../../../config/supabase_config.dart';
import '../../../core/constants/app_constants.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  User? _currentUser;
  bool _isLoading = false;
  // true mientras se verifica la sesión guardada al arrancar — evita el flash de login
  bool _isInitializing = true;
  StreamSubscription<AuthState>? _authSubscription;

  // Rate limiting local para login
  int _loginAttempts = 0;
  DateTime? _lockoutUntil;
  static const int _maxAttempts = 5;
  static const Duration _lockoutDuration = Duration(seconds: 30);

  // Rate limiting para register y forgot password
  int _registerAttempts = 0;
  DateTime? _registerLockoutUntil;
  int _forgotPwdAttempts = 0;
  DateTime? _forgotPwdLockoutUntil;

  bool get isAuthenticated => _isAuthenticated;
  User? get currentUser => _currentUser;
  bool get isAdmin => _currentUser?.role == 'admin';
  bool get isLoading => _isLoading;
  bool get isInitializing => _isInitializing;
  String get initialRoute =>
      isAdmin ? AppConstants.adminRoute : AppConstants.homeRoute;

  /// true cuando el usuario autenticado aún no ha completado el onboarding
  /// de datos de fitness (edad, peso y sexo son los campos mínimos).
  bool get needsOnboarding =>
      _isAuthenticated &&
      !isAdmin &&
      _currentUser != null &&
      (_currentUser!.age == null ||
          _currentUser!.weightKg == null ||
          _currentUser!.sex == null);

  AuthProvider() {
    _initAuthListener();
  }

  void _initAuthListener() {
    // Escuchar cambios de autenticación
    _authSubscription = SupabaseConfig.auth.onAuthStateChange.listen((data) {
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
    } else {
      // Sin sesión guardada: inicialización completa, mostrar login
      _isInitializing = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadCurrentUser(String userId) async {
    try {
      final response = await SupabaseConfig.client
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      _currentUser = User.fromJson(response);
      _isAuthenticated = true;
      _isInitializing = false;
      notifyListeners();
    } catch (e) {
      _isInitializing = false;
      debugPrint('❌ ERROR loading user: $e');
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    // Rate limiting local
    if (_lockoutUntil != null && DateTime.now().isBefore(_lockoutUntil!)) {
      final remaining = _lockoutUntil!.difference(DateTime.now()).inSeconds;
      throw Exception(
        'Demasiados intentos. Espera ${remaining}s antes de intentar de nuevo.',
      );
    }

    try {
      _isLoading = true;
      notifyListeners();

      final response = await SupabaseConfig.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        _loginAttempts = 0;
        _lockoutUntil = null;
        await _loadCurrentUser(response.user!.id);
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _loginAttempts++;
      if (_loginAttempts >= _maxAttempts) {
        _lockoutUntil = DateTime.now().add(_lockoutDuration);
        _loginAttempts = 0;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _loginAttempts++;
      if (_loginAttempts >= _maxAttempts) {
        _lockoutUntil = DateTime.now().add(_lockoutDuration);
        _loginAttempts = 0;
      }
      _isLoading = false;
      notifyListeners();
      debugPrint('❌ Login error: $e');
      rethrow;
    }
  }

  Future<bool> register(String email, String password, String name) async {
    // Rate limiting
    if (_registerLockoutUntil != null &&
        DateTime.now().isBefore(_registerLockoutUntil!)) {
      throw Exception('Demasiados intentos. Espera 30 segundos.');
    }

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
      _registerAttempts++;
      if (_registerAttempts >= _maxAttempts) {
        _registerLockoutUntil = DateTime.now().add(_lockoutDuration);
        _registerAttempts = 0;
      }
      _isLoading = false;
      notifyListeners();
      debugPrint('Register error: $e');
      rethrow;
    }
  }

  Future<bool> forgotPassword(String email) async {
    // Rate limiting
    if (_forgotPwdLockoutUntil != null &&
        DateTime.now().isBefore(_forgotPwdLockoutUntil!)) {
      throw Exception('Demasiados intentos. Espera 30 segundos.');
    }

    try {
      _isLoading = true;
      notifyListeners();

      await SupabaseConfig.auth.resetPasswordForEmail(email);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _forgotPwdAttempts++;
      if (_forgotPwdAttempts >= _maxAttempts) {
        _forgotPwdLockoutUntil = DateTime.now().add(_lockoutDuration);
        _forgotPwdAttempts = 0;
      }
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

  /// Guarda los datos de fitness del onboarding en Supabase y actualiza el modelo local.
  Future<void> saveOnboardingData({
    required int age,
    required double weightKg,
    required int heightCm,
    required String sex,
    required String level,
  }) async {
    if (_currentUser == null) return;
    try {
      await SupabaseConfig.client.from('users').update({
        'age': age,
        'weight_kg': weightKg,
        'height_cm': heightCm,
        'sex': sex,
        'level': level,
      }).eq('id', _currentUser!.id);

      _currentUser = _currentUser!.copyWith(
        age: age,
        weightKg: weightKg,
        heightCm: heightCm,
        sex: sex,
        level: level,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error saving onboarding data: $e');
      rethrow;
    }
  }

  Future<void> refreshUser() async {
    if (_currentUser != null) {
      await _loadCurrentUser(_currentUser!.id);
    }
  }
}
