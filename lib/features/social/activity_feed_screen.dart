import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/navigation/safe_pop.dart';
import 'activity_service.dart';
import 'comments_sheet.dart';

/// Feed de entrenos terminados de los socios (entrenador: los suyos;
/// dueño: todos), con comentarios y respuestas rápidas.
class ActivityFeedScreen extends StatefulWidget {
  const ActivityFeedScreen({super.key});

  @override
  State<ActivityFeedScreen> createState() => _ActivityFeedScreenState();
}

class _ActivityFeedScreenState extends State<ActivityFeedScreen> {
  final List<FeedItem> _items = [];
  final _scroll = ScrollController();
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _refresh();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 300) {
        _loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final items = await ActivityService.loadFeed();
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(items);
        _hasMore = items.length >= 30;
      });
    } catch (_) {
      if (mounted) setState(() => _error = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _items.isEmpty) return;
    _loadingMore = true;
    try {
      final more =
          await ActivityService.loadFeed(before: _items.last.completedAt);
      if (!mounted) return;
      setState(() {
        _items.addAll(more);
        _hasMore = more.length >= 30;
      });
    } catch (_) {
      // se reintenta al seguir desplazando
    } finally {
      _loadingMore = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Atrás',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.popOrGo('/admin'),
        ),
        title: const Text('Actividad de socios'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.primary,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error
                ? _Message(
                    icon: Icons.wifi_off,
                    text: 'No se pudo cargar la actividad.',
                    action: 'Reintentar',
                    onAction: _refresh,
                  )
                : _items.isEmpty
                    ? const _Message(
                        icon: Icons.dynamic_feed,
                        text:
                            'Aquí verás cada entreno que terminen tus socios, '
                            'para felicitarlos o corregirlos con un comentario.\n\n'
                            'Comparte tu código de entrenador para que se vinculen.',
                      )
                    : ListView.separated(
                        controller: _scroll,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => _FeedCard(
                          item: _items[i],
                          onOpen: () => showCommentsSheet(
                            context,
                            sessionId: _items[i].sessionId,
                            title:
                                '${_items[i].userName} · ${_items[i].workoutName}',
                            showQuickReplies: true,
                            onChanged: _refresh,
                          ),
                          onProfile: () => context
                              .push('/admin/user-progress/${_items[i].userId}'),
                        ),
                      ),
      ),
    );
  }
}

class _FeedCard extends StatelessWidget {
  final FeedItem item;
  final VoidCallback onOpen;
  final VoidCallback onProfile;

  const _FeedCard(
      {required this.item, required this.onOpen, required this.onProfile});

  @override
  Widget build(BuildContext context) {
    final lbs = item.volumeKg * 2.20462;
    final initial =
        item.userName.isNotEmpty ? item.userName[0].toUpperCase() : '?';
    return Semantics(
      button: true,
      label: '${item.userName} terminó ${item.workoutName}, '
          '${timeAgo(item.completedAt)}. ${item.commentCount} comentarios',
      child: Material(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  GestureDetector(
                    onTap: onProfile,
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.primary,
                      backgroundImage: item.photoUrl != null
                          ? NetworkImage(item.photoUrl!)
                          : null,
                      child: item.photoUrl == null
                          ? Text(initial,
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold))
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(children: [
                            TextSpan(
                                text: item.userName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            const TextSpan(text: ' terminó '),
                            TextSpan(
                                text: item.workoutName,
                                style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600)),
                          ]),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 15),
                        ),
                        Text(timeAgo(item.completedAt),
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12)),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  _Chip(Icons.timer_outlined, '${item.durationMinutes} min'),
                  const SizedBox(width: 8),
                  _Chip(Icons.fitness_center, '${lbs.toStringAsFixed(0)} lbs'),
                  const Spacer(),
                  Icon(
                    item.commentCount > 0
                        ? Icons.chat_bubble
                        : Icons.chat_bubble_outline,
                    size: 20,
                    color: item.commentCount > 0
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    item.commentCount > 0
                        ? '${item.commentCount}'
                        : 'Comentar',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Chip(this.icon, this.text);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 15, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(text,
              style:
                  const TextStyle(color: Colors.white, fontSize: 13)),
        ]),
      );
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String text;
  final String? action;
  final VoidCallback? onAction;

  const _Message(
      {required this.icon, required this.text, this.action, this.onAction});

  @override
  Widget build(BuildContext context) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        children: [
          const SizedBox(height: 60),
          Icon(icon, size: 56, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 15, height: 1.4)),
          if (action != null) ...[
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(onPressed: onAction, child: Text(action!)),
            ),
          ],
        ],
      );
}
