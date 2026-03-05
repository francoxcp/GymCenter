import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/services/notification_service.dart';
import '../../../shared/services/progress_report_service.dart';
import '../../auth/providers/auth_provider.dart';

class UserPreferences {
  final String userId;
  final bool onboardingCompleted;
  final Map<String, dynamic>? onboardingData;
  final bool notificationsEnabled;
  final bool workoutReminders;
  final bool achievementAlerts;
  final bool progressReports;
  final String theme; // 'light', 'dark', 'system'
  final String units; // 'metric', 'imperial'
  final String language; // 'es', 'en'
  final DateTime createdAt;
  final DateTime updatedAt;

  UserPreferences({
    required this.userId,
    required this.onboardingCompleted,
    this.onboardingData,
    required this.notificationsEnabled,
    required this.workoutReminders,
    required this.achievementAlerts,
    required this.progressReports,
    required this.theme,
    required this.units,
    required this.language,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      userId: json['user_id'],
      onboardingCompleted: json['onboarding_completed'] ?? false,
      onboardingData: json['onboarding_data'],
      notificationsEnabled: json['notifications_enabled'] ?? true,
      workoutReminders: json['workout_reminders'] ?? true,
      achievementAlerts: json['achievement_alerts'] ?? true,
      progressReports: json['progress_reports'] ?? true,
      theme: json['theme'] ?? 'system',
      units: json['units'] ?? 'metric',
      language: json['language'] ?? 'es',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'onboarding_completed': onboardingCompleted,
      'onboarding_data': onboardingData,
      'notifications_enabled': notificationsEnabled,
      'workout_reminders': workoutReminders,
      'achievement_alerts': achievementAlerts,
      'progress_reports': progressReports,
      'theme': theme,
      'units': units,
      'language': language,
    };
  }

  /// Usado para operaciones .update() de Supabase.
  /// NOTA: progress_reports está excluido hasta que se ejecute en Supabase:
  ///   ALTER TABLE user_preferences ADD COLUMN IF NOT EXISTS progress_reports BOOLEAN DEFAULT TRUE;
  /// Una vez ejecutado, agrégalo de vuelta aquí.
  Map<String, dynamic> toUpdateJson() {
    return {
      'onboarding_completed': onboardingCompleted,
      'onboarding_data': onboardingData,
      'notifications_enabled': notificationsEnabled,
      'workout_reminders': workoutReminders,
      'achievement_alerts': achievementAlerts,
      'theme': theme,
      'units': units,
      'language': language,
      'progress_reports': progressReports,
    };
  }

  UserPreferences copyWith({
    bool? onboardingCompleted,
    Map<String, dynamic>? onboardingData,
    bool? notificationsEnabled,
    bool? workoutReminders,
    bool? achievementAlerts,
    bool? progressReports,
    String? theme,
    String? units,
    String? language,
  }) {
    return UserPreferences(
      userId: userId,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      onboardingData: onboardingData ?? this.onboardingData,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      workoutReminders: workoutReminders ?? this.workoutReminders,
      achievementAlerts: achievementAlerts ?? this.achievementAlerts,
      progressReports: progressReports ?? this.progressReports,
      theme: theme ?? this.theme,
      units: units ?? this.units,
      language: language ?? this.language,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

class PreferencesProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  UserPreferences? _preferences;
  bool _isLoading = false;
  String? _error;
  String? _lastUserId; // para detectar cambios de usuario

  UserPreferences? get preferences => _preferences;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasCompletedOnboarding => _preferences?.onboardingCompleted ?? false;

  /// Locale actual derivada del idioma guardado en preferencias.
  Locale get appLocale {
    final lang = _preferences?.language ?? 'es';
    return Locale(lang);
  }

  /// Llamado por el ProxyProvider en main.dart cuando AuthProvider cambia.
  /// Carga las preferencias automáticamente al iniciar sesión.
  void onAuthChanged(AuthProvider auth) {
    final userId = auth.currentUser?.id;
    if (userId != null && userId != _lastUserId) {
      _lastUserId = userId;
      loadPreferences();
    } else if (userId == null) {
      _lastUserId = null;
      _preferences = null;
      notifyListeners();
    }
  }

  /// Cargar preferencias del usuario actual
  Future<void> loadPreferences() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      final response = await _supabase
          .from('user_preferences')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        _preferences = UserPreferences.fromJson(response);
      }
    } catch (e) {
      _error = 'Error al cargar preferencias: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();

      // Si el usuario tiene reportes de progreso habilitados,
      // verificar si corresponde enviar el resumen semanal.
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null && (_preferences?.progressReports ?? false)) {
        ProgressReportService().checkAndSend(
          userId: userId,
          isEnglish: (_preferences?.language ?? 'es') == 'en',
        );
      }
    }
  }

  /// Actualizar preferencias
  Future<bool> updatePreferences(UserPreferences newPreferences) async {
    // Actualización optimista: aplica el cambio en memoria YA para que la UI
    // se actualice de forma instantánea sin esperar la red.
    final previous = _preferences;
    _preferences = newPreferences;
    _error = null;
    notifyListeners();

    try {
      await _supabase
          .from('user_preferences')
          .update(newPreferences.toUpdateJson())
          .eq('user_id', newPreferences.userId);

      return true;
    } catch (e) {
      // Si falla la red, revertir al estado anterior
      _preferences = previous;
      _error = 'Error al actualizar preferencias: $e';
      debugPrint(_error);
      notifyListeners();
      return false;
    }
  }

  /// Completar onboarding
  Future<bool> completeOnboarding(Map<String, dynamic> data) async {
    if (_preferences == null) return false;

    final updated = _preferences!.copyWith(
      onboardingCompleted: true,
      onboardingData: data,
    );

    return await updatePreferences(updated);
  }

  /// Alternar notificaciones
  Future<bool> toggleNotifications(bool enabled) async {
    if (_preferences == null) return false;

    final notificationService = NotificationService();

    if (enabled) {
      // Solicitar permisos si se habilitan las notificaciones
      final hasPermission = await notificationService.requestPermissions();
      if (!hasPermission) {
        _error = 'No se otorgaron permisos de notificación';
        notifyListeners();
        return false;
      }
    } else {
      // Cancelar todas las notificaciones si se deshabilitan
      await notificationService.cancelAllNotifications();
    }

    final updated = _preferences!.copyWith(
      notificationsEnabled: enabled,
    );

    return await updatePreferences(updated);
  }

  /// Alternar recordatorios de entrenamiento
  Future<bool> toggleWorkoutReminders(bool enabled, {TimeOfDay? time}) async {
    if (_preferences == null) return false;

    final notificationService = NotificationService();

    if (enabled && _preferences!.notificationsEnabled) {
      final reminderTime = time ?? const TimeOfDay(hour: 18, minute: 0);
      await notificationService.scheduleWorkoutReminder(time: reminderTime);
    } else {
      await notificationService.cancelWorkoutReminder();
    }

    final updated = _preferences!.copyWith(
      workoutReminders: enabled,
    );

    return await updatePreferences(updated);
  }

  /// Alternar alertas de logros
  Future<bool> toggleAchievementAlerts(bool enabled) async {
    if (_preferences == null) return false;

    final updated = _preferences!.copyWith(
      achievementAlerts: enabled,
    );

    return await updatePreferences(updated);
  }

  /// Alternar reportes de progreso
  Future<bool> toggleProgressReports(bool enabled) async {
    if (_preferences == null) return false;

    final notificationService = NotificationService();

    if (enabled && _preferences!.notificationsEnabled) {
      // Programar la notificación semanal del domingo
      await notificationService.scheduleWeeklyProgressReport();
      // Enviar un reporte inmediato para que el usuario vea que funciona
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        ProgressReportService().sendNow(
          userId: userId,
          isEnglish: (_preferences?.language ?? 'es') == 'en',
        );
      }
    } else {
      await notificationService.cancelWeeklyProgressReport();
    }

    final updated = _preferences!.copyWith(
      progressReports: enabled,
    );

    return await updatePreferences(updated);
  }

  /// Cambiar tema
  Future<bool> changeTheme(String theme) async {
    if (_preferences == null) return false;

    final updated = _preferences!.copyWith(theme: theme);
    return await updatePreferences(updated);
  }

  /// Cambiar unidades
  Future<bool> changeUnits(String units) async {
    if (_preferences == null) return false;

    final updated = _preferences!.copyWith(units: units);
    return await updatePreferences(updated);
  }

  /// Cambiar idioma
  Future<bool> changeLanguage(String language) async {
    if (_preferences == null) return false;

    final updated = _preferences!.copyWith(language: language);
    return await updatePreferences(updated);
  }
}
