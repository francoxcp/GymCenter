import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/supabase_config.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_snackbar.dart';
import 'activity_service.dart';

/// Texto relativo corto: "ahora", "hace 5 min", "hace 3 h", "ayer", "12/10".
String timeAgo(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'ahora';
  if (d.inMinutes < 60) return 'hace ${d.inMinutes} min';
  if (d.inHours < 24) return 'hace ${d.inHours} h';
  if (d.inDays == 1) return 'ayer';
  if (d.inDays < 7) return 'hace ${d.inDays} días';
  return '${t.day}/${t.month}';
}

/// Respuestas rápidas del entrenador (un toque).
const quickReplies = [
  '👏 ¡Buen trabajo!',
  '🔥 ¡Vas con todo!',
  '💪 Sube un poco el peso la próxima',
  '🧘 Cuida la técnica',
];

/// Conversación de un entreno. [onChanged] se llama si se agregan o borran
/// comentarios (para refrescar contadores).
Future<void> showCommentsSheet(
  BuildContext context, {
  required String sessionId,
  required String title,
  bool showQuickReplies = false,
  VoidCallback? onChanged,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => _CommentsSheet(
      sessionId: sessionId,
      title: title,
      showQuickReplies: showQuickReplies,
      onChanged: onChanged,
    ),
  );
}

class _CommentsSheet extends StatefulWidget {
  final String sessionId;
  final String title;
  final bool showQuickReplies;
  final VoidCallback? onChanged;

  const _CommentsSheet({
    required this.sessionId,
    required this.title,
    required this.showQuickReplies,
    this.onChanged,
  });

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _ctrl = TextEditingController();
  List<SessionComment> _comments = [];
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final c = await ActivityService.loadComments(widget.sessionId);
      if (mounted) setState(() => _comments = c);
    } catch (_) {
      if (mounted) AppSnackbar.error(context, 'No se pudieron cargar');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ActivityService.addComment(widget.sessionId, text);
      _ctrl.clear();
      HapticFeedback.lightImpact();
      widget.onChanged?.call();
      await _load();
    } catch (_) {
      if (mounted) AppSnackbar.error(context, 'No se pudo enviar');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _delete(SessionComment c) async {
    try {
      await ActivityService.deleteComment(c.id);
      widget.onChanged?.call();
      await _load();
    } catch (_) {
      if (mounted) AppSnackbar.error(context, 'No se pudo borrar');
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = SupabaseConfig.client.auth.currentUser?.id;
    final mq = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: mq.size.height * 0.8),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 4),
                child: Row(children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(widget.title,
                          style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ]),
              ),
              Flexible(
                child: _loading
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : _comments.isEmpty
                        ? Padding(
                            padding: EdgeInsets.all(32),
                            child: Text(
                              'Aún no hay comentarios.\nEscribe el primero 👇',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            itemCount: _comments.length,
                            itemBuilder: (_, i) {
                              final c = _comments[i];
                              final mine = c.authorId == me;
                              return Align(
                                alignment: mine
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: GestureDetector(
                                  onLongPress: mine ? () => _delete(c) : null,
                                  child: Container(
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    constraints: BoxConstraints(
                                        maxWidth: mq.size.width * 0.75),
                                    decoration: BoxDecoration(
                                      color: mine
                                          ? AppColors.primary
                                              .withValues(alpha: 0.18)
                                          : AppColors.cardBackground,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${mine ? 'Tú' : c.authorName} · ${timeAgo(c.createdAt)}',
                                          style: TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 12),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(c.body,
                                            style: TextStyle(
                                                color: AppColors.textPrimary,
                                                fontSize: 15)),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
              if (widget.showQuickReplies)
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      for (final r in quickReplies)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ActionChip(
                            label: Text(r),
                            onPressed: _sending ? null : () => _send(r),
                          ),
                        ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
                child: Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      maxLength: 500,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _send,
                      decoration: const InputDecoration(
                        hintText: 'Escribe un comentario…',
                        counterText: '',
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton.filled(
                    tooltip: 'Enviar',
                    onPressed: _sending ? null : () => _send(_ctrl.text),
                    icon: const Icon(Icons.send),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(48, 48),
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
