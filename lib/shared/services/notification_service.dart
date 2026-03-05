import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

/// Servicio centralizado para gestionar notificaciones locales
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Inicializa el servicio de notificaciones
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Inicializar zonas horarias (solo las necesarias — mucho más rápido)
    tz.initializeTimeZones();
    // Usar la zona local del dispositivo si está disponible, si no Caracas
    try {
      final localName = DateTime.now().timeZoneName;
      tz.setLocalLocation(tz.getLocation(localName));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('America/Caracas'));
    }

    // Configuración para Android
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configuración para iOS
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
  }

  /// Maneja el tap en una notificación
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notificación tocada: ${response.payload}');
    // Aquí puedes navegar a una pantalla específica según el payload
  }

  /// Solicita permisos de notificación (principalmente para iOS)
  Future<bool> requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final result = await _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return result ?? false;
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      final result = await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      return result ?? false;
    }
    return true;
  }

  /// Muestra una notificación inmediata
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'chamos_fitness_channel',
      'Chamos Fitness',
      channelDescription: 'Notificaciones de Chamos Fitness Center',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, body, details, payload: payload);
  }

  /// Programa una notificación para una hora específica
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'chamos_fitness_channel',
      'Chamos Fitness',
      channelDescription: 'Notificaciones de Chamos Fitness Center',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  /// Programa notificaciones diarias recurrentes
  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'chamos_fitness_channel',
      'Chamos Fitness',
      channelDescription: 'Notificaciones de Chamos Fitness Center',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // Si la hora ya pasó hoy, programar para mañana
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Cancela una notificación específica
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// Cancela todas las notificaciones
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Obtiene las notificaciones pendientes
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  // IDs de notificaciones predefinidos
  static const int workoutReminderId = 1;
  static const int morningReminderId = 2;
  static const int eveningReminderId = 3;
  static const int achievementId = 100; // Base ID para logros
  static const int progressReportId = 50;

  /// Programa recordatorio de entrenamiento
  Future<void> scheduleWorkoutReminder({
    required TimeOfDay time,
  }) async {
    await scheduleDailyNotification(
      id: workoutReminderId,
      title: '💪 Hora de entrenar',
      body: '¡No olvides tu rutina de hoy! Tu cuerpo te lo agradecerá.',
      time: time,
      payload: 'workout_reminder',
    );
  }

  /// Cancela recordatorio de entrenamiento
  Future<void> cancelWorkoutReminder() async {
    await cancelNotification(workoutReminderId);
  }

  /// Muestra notificación de logro desbloqueado
  Future<void> showAchievementNotification({
    required String achievementName,
    required int points,
  }) async {
    await showNotification(
      id: achievementId + DateTime.now().millisecondsSinceEpoch % 100,
      title: '🏆 ¡Logro Desbloqueado!',
      body: '$achievementName (+$points pts)',
      payload: 'achievement',
    );
  }

  /// Programa reporte de progreso semanal (cada domingo a las 9 AM)
  Future<void> scheduleWeeklyProgressReport() async {
    // Calcular el próximo domingo
    final now = DateTime.now();
    final daysUntilSunday = (DateTime.sunday - now.weekday) % 7;
    final nextSunday = DateTime(
      now.year,
      now.month,
      now.day + (daysUntilSunday == 0 ? 7 : daysUntilSunday),
      9,
      0,
    );

    const androidDetails = AndroidNotificationDetails(
      'chamos_progress_channel',
      'Reportes de Progreso',
      channelDescription: 'Reportes semanales de progreso de Chamos Fitness Center',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      progressReportId,
      '📊 Reporte semanal',
      'Abre la app para ver tu resumen de esta semana.',
      tz.TZDateTime.from(nextSunday, tz.local),
      details,
      payload: 'progress_report',
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  /// Cancela reporte semanal
  Future<void> cancelWeeklyProgressReport() async {
    await cancelNotification(progressReportId);
  }
}
