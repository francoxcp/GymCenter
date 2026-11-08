import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../web/web_bridge.dart';

/// Notificaciones push para la versión web (PWA).
///
/// En web no se pueden programar notificaciones locales: los recordatorios
/// diarios y el reporte semanal los envía la Edge Function `send-push` de
/// Supabase (ver supabase/functions/send-push y docs/WEB_DEPLOY.md).
///
/// Este servicio:
/// - suscribe el navegador a Web Push y guarda la suscripción en
///   `push_subscriptions`;
/// - sincroniza la hora del recordatorio y la zona horaria en
///   `user_preferences` para que el servidor sepa cuándo enviar.
class WebPushService {
  WebPushService._();
  static final WebPushService _instance = WebPushService._();
  factory WebPushService() => _instance;

  /// Clave pública VAPID (se pasa con --dart-define=VAPID_PUBLIC_KEY=...).
  static const String vapidPublicKey = String.fromEnvironment('VAPID_PUBLIC_KEY');

  SupabaseClient get _supabase => Supabase.instance.client;

  /// 'supported' | 'unsupported' | 'ios-needs-install'
  String get support => kIsWeb ? WebBridge.notificationSupport : 'unsupported';

  bool get isConfigured => vapidPublicKey.isNotEmpty;

  /// Pide permiso al usuario (si hace falta) y registra la suscripción.
  Future<bool> requestPermissionAndSubscribe() async {
    if (!kIsWeb || support != 'supported') return false;
    var permission = WebBridge.notificationPermission;
    if (permission != 'granted') {
      permission = await WebBridge.requestNotificationPermission();
    }
    if (permission != 'granted') return false;
    await ensureSubscribed();
    return true;
  }

  /// Registra (o refresca) la suscripción push si ya hay permiso.
  Future<void> ensureSubscribed() async {
    if (!kIsWeb || !isConfigured) return;
    if (WebBridge.notificationPermission != 'granted') return;
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final raw = await WebBridge.pushSubscribe(vapidPublicKey);
      if (raw.isEmpty) return;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final keys = (json['keys'] as Map?)?.cast<String, dynamic>() ?? {};
      final endpoint = json['endpoint'] as String?;
      final p256dh = keys['p256dh'] as String?;
      final auth = keys['auth'] as String?;
      if (endpoint == null || p256dh == null || auth == null) return;
      // RPC: inserta o reasigna la suscripción al usuario actual
      // (por si el mismo navegador se usó antes con otra cuenta).
      await _supabase.rpc('claim_push_subscription', params: {
        'p_endpoint': endpoint,
        'p_p256dh': p256dh,
        'p_auth': auth,
      });
    } catch (e) {
      debugPrint('WebPushService.ensureSubscribed error: $e');
    }
  }

  /// Elimina la suscripción del navegador actual (al cerrar sesión).
  /// Debe llamarse ANTES de signOut para que RLS permita el borrado.
  Future<void> unsubscribe() async {
    if (!kIsWeb) return;
    try {
      final endpoint = await WebBridge.pushUnsubscribe();
      if (endpoint.isEmpty) return;
      await _supabase
          .from('push_subscriptions')
          .delete()
          .eq('endpoint', endpoint);
    } catch (e) {
      debugPrint('WebPushService.unsubscribe error: $e');
    }
  }

  /// Guarda la hora del recordatorio diario y la zona horaria del usuario.
  Future<void> syncReminder(TimeOfDay time) async {
    if (!kIsWeb) return;
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    try {
      await _supabase.from('user_preferences').update({
        'reminder_time': '$hh:$mm:00',
        'timezone': WebBridge.timeZone,
      }).eq('user_id', userId);
    } catch (e) {
      debugPrint('WebPushService.syncReminder error: $e');
    }
  }
}
