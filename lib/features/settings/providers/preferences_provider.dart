import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/services/notification_service.dart';
import '../../../shared/services/progress_report_service.dart';
import '../../auth/providers/auth_provider.dart';

const _kReminderHour = 'workout_reminder_hour';
const _kReminderMinute = 'workout_reminder_minute';

class UserPreferences {
  final String userId;
  final bool onboardingCompleted;
  final Map<String, dynamic>? onboardingData;
  final bool notificationsEnabled;
  final bool workoutReminders;
  final bool achievementAlerts;
  final bool progressReports;
  final String theme; // 'light', 'dark', 'system'
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
  TimeOfDay _workoutReminderTime = const TimeOfDay(hour: 18, minute: 0);

  UserPreferences? get preferences => _preferences;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasCompletedOnboarding => _preferences?.onboardingCompleted ?? false;
  TimeOfDay get workoutReminderTime => _workoutReminderTime;

  /// Locale actual derivada del idioma guardado en preferencias.
  Locale get appLocale {
    final lang = _preferences?.language ?? 'es';
    return Locale(lang);
  }

  /// Llamado por el ProxyProvider en main.dart cuando AuthProvider cambia.
  /// Carga las preferencias automáticamente al iniciar sesión.
  /// Usa addPostFrameCallback para evitar notifyListeners durante build.
  void onAuthChanged(AuthProvider auth) {
    final userId = auth.currentUser?.id;
    if (userId != null && userId != _lastUserId) {
      _lastUserId = userId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        loadPreferences();
      });
    } else if (userId == null && _lastUserId != null) {
      _lastUserId = null;
      _preferences = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  /// Carga la hora guardada de SharedPreferences
  Future<void> _loadReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt(_kReminderHour);
    final minute = prefs.getInt(_kReminderMinute);
    if (hour != null && minute != null) {
      _workoutReminderTime = TimeOfDay(hour: hour, minute: minute);
    }
  }

  /// Guarda la hora en SharedPreferences y reprograma la notificación
  Future<void> updateWorkoutReminderTime(TimeOfDay time) async {
    _workoutReminderTime = time;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kReminderHour, time.hour);
    await prefs.setInt(_kReminderMinute, time.minute);
    if (_preferences?.notificationsEnabled == true &&
        _preferences?.workoutReminders == true) {
      await NotificationService().scheduleWorkoutReminder(
        time: time,
        userId: _supabase.auth.currentUser?.id,
      );
    }
  }

  /// Cargar preferencias del usuario actual
  Future<void> loadPreferences() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Cargar hora guardada localmente en paralelo
    await _loadReminderTime();

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

      // Re-programar recordatorio diario si está habilitado
      // (necesario tras un reinicio del sistema o reinstalación)
      if (_preferences?.notificationsEnabled == true &&
          _preferences?.workoutReminders == true) {
        await NotificationService().scheduleWorkoutReminder(
          time: _workoutReminderTime,
          userId: _supabase.auth.currentUser?.id,
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
      final reminderTime = time ?? _workoutReminderTime;
      await notificationService.scheduleWorkoutReminder(
        time: reminderTime,
        userId: _supabase.auth.currentUser?.id,
      );
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

  /// Cambiar idioma
  Future<bool> changeLanguage(String language) async {
    if (_preferences == null) return false;

    final updated = _preferences!.copyWith(language: language);
    return await updatePreferences(updated);
  }
}
