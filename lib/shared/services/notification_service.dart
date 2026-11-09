import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_10y.dart' as tz;
import '../web/web_bridge.dart';
import 'web_push_service.dart';

/// Servicio centralizado para gestionar notificaciones.
///
/// - Android/iOS: notificaciones locales programadas
///   (flutter_local_notifications).
/// - Web (PWA): notificaciones inmediatas vía service worker y
///   recordatorios programados vía Web Push desde Supabase
///   (ver [WebPushService]).
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Perezoso: en web el plugin nativo nunca se instancia.
  late final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isInitialized = false;

  /// Mapa offset UTC → zona IANA representativa.
  static String _ianaFromOffset(Duration offset) {
    final hours = offset.inHours;
    const map = {
      -12: 'Etc/GMT+12',
      -11: 'Pacific/Pago_Pago',
      -10: 'Pacific/Honolulu',
      -9: 'America/Anchorage',
      -8: 'America/Los_Angeles',
      -7: 'America/Denver',
      -6: 'America/Chicago',
      -5: 'America/New_York',
      -4: 'America/Caracas',
      -3: 'America/Sao_Paulo',
      -2: 'Atlantic/South_Georgia',
      -1: 'Atlantic/Azores',
      0: 'Europe/London',
      1: 'Europe/Paris',
      2: 'Europe/Berlin',
      3: 'Europe/Moscow',
      4: 'Asia/Dubai',
      5: 'Asia/Karachi',
      6: 'Asia/Dhaka',
      7: 'Asia/Bangkok',
      8: 'Asia/Shanghai',
      9: 'Asia/Tokyo',
      10: 'Australia/Sydney',
      11: 'Pacific/Noumea',
      12: 'Pacific/Auckland',
    };
    return map[hours] ?? 'Etc/UTC';
  }

  // ── Deep links ──────────────────────────────────────────────────────────
  GoRouter? _router;
  String? _pendingPayload;

  /// Registra el router para poder navegar al tocar notificaciones.
  static void setRouter(GoRouter router) {
    _instance._router = router;
    // Si había un payload pendiente (app abierta desde notificación en estado cerrado)
    final pending = _instance._pendingPayload;
    if (pending != null) {
      _instance._pendingPayload = null;
      _instance._handlePayload(pending);
    }
  }

  void _handlePayload(String payload) {
    final route = _routeForPayload(payload);
    if (route != null) _router?.go(route);
  }

  static String? _routeForPayload(String? payload) {
    switch (payload) {
      case 'workout_reminder':
        return '/today-workout';
      case 'progress_report':
        return '/progress';
      case 'achievement':
        return '/achievements';
    }
    return null;
  }

  /// Inicializa el servicio de notificaciones.
  /// Seguro de llamar múltiples veces — idempotente.
  /// Si falla, deja _isInitialized = false para poder reintentar.
  Future<void> initialize() async {
    if (_isInitialized) return;

    if (kIsWeb) {
      // En web no hay plugin nativo: el service worker (web/sw.js) se
      // registra desde gc_bridge.js. Si ya hay permiso, refrescar la
      // suscripción push por si el navegador la rotó.
      _isInitialized = true;
      WebPushService().ensureSubscribed();
      return;
    }

    try {
      // Inicializar zonas horarias — latest_10y carga solo ±10 años (mucho más rápido)
      tz.initializeTimeZones();
      try {
        final localName = DateTime.now().timeZoneName;
        tz.setLocalLocation(tz.getLocation(localName));
      } catch (_) {
        // timeZoneName devuelve abreviaturas (VET, EST...) que tz no reconoce.
        // Elegir zona IANA por offset UTC del dispositivo como fallback.
        final offset = DateTime.now().timeZoneOffset;
        final fallback = _ianaFromOffset(offset);
        debugPrint(
            '⚠️ Timezone lookup failed, using offset-based fallback: $fallback');
        tz.setLocalLocation(tz.getLocation(fallback));
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

      // Manejar lanzamiento desde notificación cuando la app estaba completamente cerrada
      final launchDetails =
          await _notifications.getNotificationAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp == true) {
        final payload = launchDetails!.notificationResponse?.payload;
        if (payload != null) {
          if (_router != null) {
            _handlePayload(payload);
          } else {
            _pendingPayload = payload;
          }
        }
      }

      _isInitialized = true;
    } catch (e, st) {
      // No marcar como inicializado — se puede reintentar en el próximo ciclo.
      // Las funciones que dependen de this lo manejan con try/catch propio.
      debugPrint('❌ NotificationService.initialize() falló: $e');
      debugPrint('$st');
    }
  }

  /// Maneja el tap en una notificación (app en primer o segundo plano)
  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    debugPrint('Notificación tocada: $payload');
    if (payload == null) return;
    if (_router != null) {
      _handlePayload(payload);
    } else {
      // Router aún no listo (race condition al arrancar) → guardar y navegar cuando esté listo
      _pendingPayload = payload;
    }
  }

  /// Solicita permisos de notificación (principalmente para iOS)
  Future<bool> requestPermissions() async {
    if (kIsWeb) {
      return WebPushService().requestPermissionAndSubscribe();
    }
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
    // Garantizar inicialización antes de mostrar
    await initialize();

    if (kIsWeb) {
      await WebBridge.showNotification(
        title: title,
        body: body,
        tag: payload ?? 'gymlab-$id',
        url: _routeForPayload(payload) ?? '/',
      );
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'gymlab_channel',
      'GYMLAB',
      channelDescription: 'Notificaciones de GYMLAB',
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

  /// Programa notificaciones diarias recurrentes
  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
    String? payload,
  }) async {
    // En web las notificaciones programadas las envía el servidor (Web Push)
    if (kIsWeb) return;

    // Garantizar inicialización antes de programar
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'gymlab_channel',
      'GYMLAB',
      channelDescription: 'Notificaciones de GYMLAB',
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

    try {
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
    } on PlatformException catch (e) {
      if (e.code == 'exact_alarms_not_permitted') {
        await _notifications.zonedSchedule(
          id,
          title,
          body,
          tz.TZDateTime.from(scheduledDate, tz.local),
          details,
          payload: payload,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } else {
        rethrow;
      }
    }
  }

  /// Cancela todas las notificaciones
  Future<void> cancelAllNotifications() async {
    if (kIsWeb) return; // El servidor respeta notifications_enabled
    await _notifications.cancelAll();
  }

  // IDs de notificaciones predefinidos
  static const int workoutReminderId = 1;
  static const int achievementId = 100; // Base ID para logros
  /// Programa recordatorio de entrenamiento.
  /// Si se pasa [userId], personaliza el mensaje según los días sin entrenar.
  Future<void> scheduleWorkoutReminder({
    required TimeOfDay time,
    String? userId,
  }) async {
    if (kIsWeb) {
      // El mensaje personalizado lo arma la Edge Function al enviarlo.
      await WebPushService().ensureSubscribed();
      await WebPushService().syncReminder(time);
      return;
    }

    String title = '💪 Hora de entrenar';
    String body = '¡No olvides tu rutina de hoy! Tu cuerpo te lo agradecerá.';

    if (userId != null) {
      try {
        final lastSession = await _supabase
            .from('workout_sessions')
            .select('completed_at')
            .eq('user_id', userId)
            .order('completed_at', ascending: false)
            .limit(1)
            .maybeSingle();

        if (lastSession != null) {
          final lastDate =
              DateTime.tryParse(lastSession['completed_at'] as String? ?? '')
                  ?.toLocal();
          if (lastDate != null) {
            final daysSince = DateTime.now().difference(lastDate).inDays;
            if (daysSince >= 2) {
              title = '¿Todo bien? 💪';
              body =
                  'Llevas $daysSince días sin entrenar. ¡Hoy es un buen día para retomar!';
            }
          }
        } else {
          title = '¡Empieza hoy! 💪';
          body = '¿Listo para tu primera sesión? ¡Tu cuerpo te lo agradecerá!';
        }
      } catch (e) {
        debugPrint('⚠️ Error querying last session for notification: $e');
      }
    }

    await scheduleDailyNotification(
      id: workoutReminderId,
      title: title,
      body: body,
      time: time,
      payload: 'workout_reminder',
    );
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

}
