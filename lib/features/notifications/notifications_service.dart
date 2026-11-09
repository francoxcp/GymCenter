import 'package:flutter/foundation.dart';

import '../../config/supabase_config.dart';

class AppNotification {
  final int id;
  final String title;
  final String body;
  final String? url;
  final String? tag;
  final DateTime createdAt;
  final bool read;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    this.url,
    this.tag,
    required this.createdAt,
    required this.read,
  });

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: (j['id'] as num).toInt(),
        title: (j['title'] as String?) ?? '',
        body: (j['body'] as String?) ?? '',
        url: j['url'] as String?,
        tag: j['tag'] as String?,
        createdAt: DateTime.parse(j['created_at'] as String).toLocal(),
        read: (j['read'] as bool?) ?? false,
      );

  /// Ruta interna (go_router) a la que lleva el aviso, o null si es externa.
  String? get route {
    final u = url;
    if (u == null || u.isEmpty) return null;
    if (u.startsWith('/')) return u;
    final parsed = Uri.tryParse(u);
    if (parsed == null || parsed.path.isEmpty) return null;
    return parsed.hasQuery ? '${parsed.path}?${parsed.query}' : parsed.path;
  }
}

/// Bandeja de avisos: lo mismo que llega por push, guardado 30 días.
/// Funciones SQL en database/ux_roles_migration.sql.
class NotificationsService {
  NotificationsService._();

  /// Contador de no leídos para la campana (se refresca al abrir pantallas).
  static final ValueNotifier<int> unread = ValueNotifier<int>(0);

  static Future<void> refreshUnread() async {
    try {
      final n = await SupabaseConfig.client.rpc('my_unread_notifications');
      unread.value = (n as num?)?.toInt() ?? 0;
    } catch (_) {
      // Sin red o migración aún no aplicada: la campana queda sin número.
    }
  }

  static Future<List<AppNotification>> list({int limit = 40}) async {
    final rows = await SupabaseConfig.client
        .rpc('my_notifications', params: {'p_limit': limit});
    return (rows as List)
        .map((r) => AppNotification.fromJson(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  static Future<void> markAllRead() async {
    try {
      await SupabaseConfig.client.rpc('mark_my_notifications_read');
      unread.value = 0;
    } catch (_) {}
  }
}
