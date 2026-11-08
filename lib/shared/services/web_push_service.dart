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

  /// Clave pública VAPID. Opcional como --dart-define=VAPID_PUBLIC_KEY=...;
  /// si no se pasa, se obtiene de Supabase (RPC get_vapid_public_key), donde
  /// la genera automáticamente la Edge Function send-push.
  static const String _vapidFromBuild = String.fromEnvironment('VAPID_PUBLIC_KEY');
  String? _vapidCache;

  Future<String> _vapidPublicKey() async {
    if (_vapidFromBuild.isNotEmpty) return _vapidFromBuild;
    if (_vapidCache != null && _vapidCache!.isNotEmpty) return _vapidCache!;
    try {
      final key = await _supabase.rpc('get_vapid_public_key');
      if (key is String && key.isNotEmpty) _vapidCache = key;
    } catch (e) {
      debugPrint('WebPushService: no se pudo obtener la clave VAPID: $e');
    }
    return _vapidCache ?? '';
  }

  SupabaseClient get _supabase => Supabase.instance.client;

  /// 'supported' | 'unsupported' | 'ios-needs-install'
  String get support => kIsWeb ? WebBridge.notificationSupport : 'unsupported';

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
    if (!kIsWeb) return;
    if (WebBridge.notificationPermission != 'granted') return;
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final vapid = await _vapidPublicKey();
      if (vapid.isEmpty) return;
      final raw = await WebBridge.pushSubscribe(vapid);
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
