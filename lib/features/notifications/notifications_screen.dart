import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/navigation/safe_pop.dart';
import 'notifications_service.dart';

/// "hace 5 min", "hace 3 h", "ayer", "12/10".
String timeAgo(DateTime t, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final d = n.difference(t);
  if (d.inMinutes < 1) return 'ahora';
  if (d.inMinutes < 60) return 'hace ${d.inMinutes} min';
  if (d.inHours < 24) return 'hace ${d.inHours} h';
  if (d.inDays == 1) return 'ayer';
  if (d.inDays < 7) return 'hace ${d.inDays} días';
  return '${t.day}/${t.month}';
}

IconData _iconFor(String? tag) => switch (tag) {
      'comment' => Icons.chat_bubble_outline,
      'session_done' => Icons.check_circle_outline,
      'org_payment' || 'org_billing' => Icons.receipt_long_outlined,
      final t? when t.startsWith('membership') => Icons.event_outlined,
      _ => Icons.notifications_none,
    };

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<AppNotification>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<AppNotification>> _load() async {
    final list = await NotificationsService.list();
    // Al abrir la bandeja todo queda leído (el punto sigue visible en esta
    // vista para distinguir lo nuevo).
    NotificationsService.markAllRead();
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Avisos'),
        leading: IconButton(
          tooltip: 'Volver',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.popOrGo('/profile'),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() => _future = _load());
          await _future;
        },
        child: FutureBuilder<List<AppNotification>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return ListView(children: [
                _Empty(
                    title: 'No se pudieron cargar',
                    body: 'Revisa tu conexión y desliza hacia abajo.'),
              ]);
            }
            final items = snap.data ?? const [];
            if (items.isEmpty) {
              return ListView(children: const [
                _Empty(
                    title: 'Todo al día',
                    body:
                        'Aquí aparecen comentarios, entrenos de tus socios, pagos y vencimientos de los últimos 30 días.'),
              ]);
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: AppColors.surface),
              itemBuilder: (context, i) {
                final n = items[i];
                final route = n.route;
                return ListTile(
                  onTap: route == null ? null : () => context.push(route),
                  leading: Icon(_iconFor(n.tag),
                      color: n.read
                          ? AppColors.textSecondary
                          : AppColors.primaryText),
                  title: Text(n.title,
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight:
                              n.read ? FontWeight.w500 : FontWeight.w800)),
                  subtitle: Text('${n.body}\n${timeAgo(n.createdAt)}',
                      style: TextStyle(
                          color: AppColors.textSecondary, height: 1.35)),
                  isThreeLine: true,
                  trailing: n.read
                      ? null
                      : Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle),
                        ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final String title;
  final String body;
  const _Empty({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 96, 32, 32),
      child: Column(
        children: [
          Text(title,
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(body,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, height: 1.4)),
        ],
      ),
    );
  }
}
