import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../models/user.dart';
import '../../organization/models/organization.dart';
import '../../organization/services/organization_service.dart';
import '../../../config/supabase_config.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/services/offline_cache_service.dart';
import '../../../shared/services/web_push_service.dart';
import '../../chat/chat_service.dart';
import '../../../shared/services/offline_sync_queue.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  User? _currentUser;
  bool _isLoading = false;
  // true mientras se verifica la sesión guardada al arrancar — evita el flash de login
  bool _isInitializing = true;
  StreamSubscription<AuthState>? _authSubscription;

  // Rate limiting local para login (backoff exponencial)
  int _loginAttempts = 0;
  DateTime? _lockoutUntil;
  static const int _maxAttempts = 5;
  // Lockout base: cada bloqueo duplica la duración (30s, 60s, 120s…)
  int _loginLockoutMultiplier = 1;
  static const Duration _lockoutBase = Duration(seconds: 30);

  // Claves para persistir el rate limiting en almacenamiento cifrado
  static const _kLockoutUntil = 'login_lockout_until';
  static const _kLockoutMultiplier = 'login_lockout_multiplier';
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // Rate limiting para register y forgot password
  int _registerAttempts = 0;
  DateTime? _registerLockoutUntil;
  int _forgotPwdAttempts = 0;
  DateTime? _forgotPwdLockoutUntil;

  // true cuando el usuario llegó desde un enlace de recuperación de contraseña
  bool _isPasswordRecovery = false;

  // true cuando el registro fue exitoso pero requiere confirmación de email
  bool _pendingEmailConfirmation = false;

  bool get isAuthenticated => _isAuthenticated;
  User? get currentUser => _currentUser;

  // Multi-cliente: organización del usuario y rol de plataforma
  Organization? _org;
  bool _isPlatformAdmin = false;
  Organization? get organization => _org;
  bool get isPlatformAdmin => _isPlatformAdmin;
  /// Usuario sin gimnasio/entrenador todavía (registro sin código).
  /// Mientras se aplica una invitación pendiente tras registrarse o iniciar
  /// sesión: evita mostrar "¿Con quién entrenas?" por unos segundos.
  bool _joiningOrganization = false;
  bool get isJoiningOrganization => _joiningOrganization;
  void markJoiningOrganization(bool value, {bool notify = true}) {
    if (_joiningOrganization == value) return;
    _joiningOrganization = value;
    if (notify) notifyListeners();
  }

  bool get needsOrganization =>
      _isAuthenticated && _currentUser != null && _currentUser!.orgId == null;
  bool get isOrgSuspended => _org?.isSuspended ?? false;
  bool get isIndependent => _org?.isIndependent ?? false;

  Future<void> _loadOrgContext() async {
    final orgId = _currentUser?.orgId;
    try {
      final results = await Future.wait([
        orgId == null
            ? Future<Organization?>.value(null)
            : OrganizationService.loadMine(orgId,
                withBilling: _currentUser?.role == 'admin'),
        OrganizationService.isPlatformAdmin(),
      ]);
      _org = results[0] as Organization?;
      _isPlatformAdmin = results[1] as bool;
    } catch (e) {
      debugPrint('No se pudo cargar la organización: $e');
    }
  }

  /// Recarga la organización (tras subir logo, pagar, etc.).
  Future<void> reloadOrganization() async {
    await _loadOrgContext();
    notifyListeners();
  }
  /// Dueño del gimnasio (control total).
  bool get isAdmin => _currentUser?.role == 'admin';
  /// Entrenador: gestiona solo a sus socios.
  bool get isTrainer => _currentUser?.role == 'trainer';
  /// Dueño o entrenador: accede al panel de gestión.
  bool get isStaff => isAdmin || isTrainer;
  bool get isLoading => _isLoading;
  bool get isInitializing => _isInitializing;
  bool get isPasswordRecovery => _isPasswordRecovery;
  bool get pendingEmailConfirmation => _pendingEmailConfirmation;
  /// Inicio según el rol: el dueño ve el panel, el entrenador su "Hoy"
  /// (quién entrenó y quién falta) y el socio su entreno del día.
  String get initialRoute => isPlatformAdmin
      ? '/platform'
      : isAdmin
      ? AppConstants.adminRoute
      : isTrainer
          ? '/admin/today'
          : AppConstants.homeRoute;

  /// true cuando el usuario autenticado aún no ha completado el onboarding
  /// de datos de fitness (edad, peso y sexo son los campos mínimos).
  bool get needsOnboarding =>
      _isAuthenticated &&
      !isStaff &&
      _currentUser != null &&
      (_currentUser!.age == null ||
          _currentUser!.weightKg == null ||
          _currentUser!.sex == null);

  AuthProvider() {
    _loadPersistedRateLimit();
    _initAuthListener();
  }

  /// Carga el bloqueo de login guardado en sesiones anteriores.
  Future<void> _loadPersistedRateLimit() async {
    try {
      final until = await _storage.read(key: _kLockoutUntil);
      final multiplier = await _storage.read(key: _kLockoutMultiplier);
      if (until != null) {
        final dt = DateTime.tryParse(until);
        if (dt != null && dt.isAfter(DateTime.now())) {
          _lockoutUntil = dt;
        }
      }
      if (multiplier != null) {
        _loginLockoutMultiplier = int.tryParse(multiplier) ?? 1;
      }
    } catch (_) {}
  }

  /// Persiste el estado de bloqueo en almacenamiento cifrado.
  Future<void> _persistRateLimit() async {
    try {
      if (_lockoutUntil != null) {
        await _storage.write(
            key: _kLockoutUntil, value: _lockoutUntil!.toIso8601String());
      } else {
        await _storage.delete(key: _kLockoutUntil);
      }
      await _storage.write(
          key: _kLockoutMultiplier, value: _loginLockoutMultiplier.toString());
    } catch (_) {}
  }

  void _initAuthListener() {
    // Escuchar cambios de autenticación
    _authSubscription = SupabaseConfig.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (data.event == AuthChangeEvent.passwordRecovery && session != null) {
        // El usuario llegó desde el enlace de reset password en su correo.
        // Supabase establece una sesión temporal de recuperación — marcar el
        // flag para que el router redirija a /change-password en lugar de home.
        _isPasswordRecovery = true;
        _loadCurrentUser(session.user.id);
      } else if (session != null) {
        _loadCurrentUser(session.user.id);
      } else if (data.event == AuthChangeEvent.signedOut) {
        _isPasswordRecovery = false;
        _clearSessionData();
      }
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

  /// Verifica el enlace de recuperación de contraseña enviado por correo
  /// (`/reset-password?token_hash=...&type=recovery`).
  ///
  /// Se usa token_hash en lugar del flujo PKCE porque en iPhone la PWA
  /// instalada y Safari no comparten almacenamiento: el enlace del correo
  /// se abre en Safari y PKCE fallaría. token_hash funciona en cualquier
  /// navegador.
  Future<bool> verifyRecoveryToken(String tokenHash) async {
    _isPasswordRecovery = true;
    try {
      final res = await SupabaseConfig.auth.verifyOTP(
        tokenHash: tokenHash,
        type: OtpType.recovery,
      );
      final session = res.session;
      if (session == null) {
        _isPasswordRecovery = false;
        notifyListeners();
        return false;
      }
      await _loadCurrentUser(session.user.id);
      return true;
    } catch (e) {
      debugPrint('verifyRecoveryToken error: $e');
      _isPasswordRecovery = false;
      notifyListeners();
      return false;
    }
  }

  /// Limpia el flag de recuperación de contraseña una vez que el usuario
  /// completó el cambio de contraseña desde el enlace de email.
  void clearPasswordRecovery() {
    _isPasswordRecovery = false;
    notifyListeners();
  }

  Future<void> _loadCurrentUser(String userId) async {
    try {
      final response = await SupabaseConfig.client
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      _currentUser = User.fromJson(response);
      await _loadOrgContext();
      _isAuthenticated = true;
      _isInitializing = false;
      notifyListeners();
      // Copia local para poder abrir la app sin conexión
      unawaited(OfflineCacheService().saveUser(response));
      unawaited(OfflineSyncQueue.instance.flush());
    } catch (e) {
      // Sin conexión: usar el perfil guardado si hay una sesión válida
      if (OfflineSyncQueue.isNetworkError(e)) {
        final cached = await OfflineCacheService().loadUser(userId);
        if (cached != null) {
          _currentUser = User.fromJson(cached);
          _isAuthenticated = true;
          _isInitializing = false;
          notifyListeners();
          return;
        }
      }
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
        _loginLockoutMultiplier = 1;
        await _persistRateLimit();
        await _loadCurrentUser(response.user!.id);
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _loginAttempts++;
      if (_loginAttempts >= _maxAttempts) {
        _lockoutUntil =
            DateTime.now().add(_lockoutBase * _loginLockoutMultiplier);
        _loginLockoutMultiplier =
            (_loginLockoutMultiplier * 2).clamp(1, 32); // max ~16 min
        _loginAttempts = 0;
        await _persistRateLimit();
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _loginAttempts++;
      if (_loginAttempts >= _maxAttempts) {
        _lockoutUntil =
            DateTime.now().add(_lockoutBase * _loginLockoutMultiplier);
        _loginLockoutMultiplier =
            (_loginLockoutMultiplier * 2).clamp(1, 32); // max ~16 min
        _loginAttempts = 0;
        await _persistRateLimit();
      }
      _isLoading = false;
      notifyListeners();
      debugPrint('❌ Login error: $e');
      rethrow;
    }
  }

  Future<bool> register(String email, String password, String name,
      {String? trainerCode}) async {
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
        emailRedirectTo: SupabaseConfig.emailConfirmRedirect,
        // El rol NUNCA se envía desde el cliente: el trigger handle_new_user
        // asigna siempre 'user' (ver database/web_pwa_migration.sql).
        data: {
          'name': name,
          // Si trae código, la base de datos lo vincula con su entrenador
          if (trainerCode != null && trainerCode.trim().isNotEmpty)
            'trainer_code': trainerCode.trim().toUpperCase(),
        },
      );

      if (response.user != null && response.session != null) {
        // Email confirmation desactivado en Supabase: sesión activa inmediata
        _pendingEmailConfirmation = false;
        await Future.delayed(AppConstants.userCreationDelay);
        await _loadCurrentUser(response.user!.id);
        _isLoading = false;
        notifyListeners();
        return true;
      } else if (response.user != null && response.session == null) {
        // Email confirmation activado: el usuario debe confirmar su correo
        _pendingEmailConfirmation = true;
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _pendingEmailConfirmation = false;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _registerAttempts++;
      if (_registerAttempts >= _maxAttempts) {
        _registerLockoutUntil = DateTime.now().add(_lockoutBase);
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

      await SupabaseConfig.auth.resetPasswordForEmail(
        email,
        redirectTo: SupabaseConfig.passwordResetRedirect,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _forgotPwdAttempts++;
      if (_forgotPwdAttempts >= _maxAttempts) {
        _forgotPwdLockoutUntil = DateTime.now().add(_lockoutBase);
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
      // Quitar la suscripción push de este navegador antes de cerrar sesión
      // (con la sesión aún activa para que RLS permita borrarla).
      await WebPushService().unsubscribe();
      ChatService.stopListening();
      await SupabaseConfig.auth.signOut();
      await _clearSessionData();
    } catch (e) {
      debugPrint('Logout error: $e');
    }
  }

  /// Limpia datos del usuario de memoria y SharedPreferences.
  /// Evita filtración de datos en dispositivos compartidos.
  Future<void> _clearSessionData() async {
    _isAuthenticated = false;
    _currentUser = null;
    _org = null;
    _isPlatformAdmin = false;
    notifyListeners();
    try {
      await OfflineCacheService().clearCache();
      final prefs = await SharedPreferences.getInstance();
      // Limpiar timer de workouts y preferencias de sesión
      final keys = prefs.getKeys().where(
            (k) =>
                k.startsWith('workout_timer_') ||
                k == 'last_progress_report_date',
          );
      for (final key in keys) {
        await prefs.remove(key);
      }
    } catch (e) {
      debugPrint('Error clearing session data: $e');
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
    String? goal,
  }) async {
    if (_currentUser == null) return;
    try {
      await SupabaseConfig.client.from('users').update({
        'age': age,
        'weight_kg': weightKg,
        'height_cm': heightCm,
        'sex': sex,
        if (goal != null) 'goal': goal,
      }).eq('id', _currentUser!.id);

      _currentUser = _currentUser!.copyWith(
        age: age,
        weightKg: weightKg,
        heightCm: heightCm,
        sex: sex,
        goal: goal ?? _currentUser!.goal,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error saving onboarding data: $e');
      rethrow;
    }
  }

  // ── Entrenador ──────────────────────────────────────────────────────────

  /// Socio: se vincula con su entrenador usando el código.
  /// Devuelve el nombre del entrenador; lanza excepción si el código no es válido.
  Future<String> linkTrainerByCode(String code) async {
    final name = await SupabaseConfig.client
        .rpc('link_trainer_by_code', params: {'p_code': code.trim()});
    await refreshUser();
    return name as String;
  }

  /// Entrenador/dueño: genera un código nuevo.
  Future<void> regenerateTrainerCode() async {
    await SupabaseConfig.client.rpc('regenerate_my_trainer_code');
    await refreshUser();
  }

  /// Nombre del entrenador del socio actual (o null).
  /// Nombre y teléfono (WhatsApp) del entrenador del socio.
  Future<({String? name, String? phone})> loadTrainerContact() async {
    final trainerId = _currentUser?.trainerId;
    if (trainerId == null) return (name: null, phone: null);
    try {
      final row = await SupabaseConfig.client
          .from('users')
          .select('name, phone')
          .eq('id', trainerId)
          .maybeSingle();
      return (name: row?['name'] as String?, phone: row?['phone'] as String?);
    } catch (_) {
      return (name: await loadTrainerName(), phone: null);
    }
  }

  Future<String?> loadTrainerName() async {
    final trainerId = _currentUser?.trainerId;
    if (trainerId == null) return null;
    try {
      final row = await SupabaseConfig.client
          .from('users')
          .select('name')
          .eq('id', trainerId)
          .maybeSingle();
      return row?['name'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<void> refreshUser() async {
    if (_currentUser != null) {
      await _loadCurrentUser(_currentUser!.id);
    }
  }
}
