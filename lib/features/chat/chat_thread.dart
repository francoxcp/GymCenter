import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show RealtimeChannel;

import '../../core/theme/app_theme.dart';
import '../../shared/services/share_helper.dart';
import 'chat_service.dart';

const trainerQuickReplies = [
  '¡Buen trabajo!',
  'Sube peso la próxima',
  'Cuida la técnica',
  '¿Cómo te sentiste?',
];

/// "Hoy", "Ayer", "Lunes", "12/10".
String dayLabel(DateTime d, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final a = DateTime(d.year, d.month, d.day);
  final b = DateTime(n.year, n.month, n.day);
  final diff = b.difference(a).inDays;
  if (diff == 0) return 'Hoy';
  if (diff == 1) return 'Ayer';
  const names = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
  if (diff < 7) return names[d.weekday - 1];
  return '${d.day}/${d.month}${d.year == n.year ? '' : '/${d.year}'}';
}

String _hhmm(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// Conversación entre un socio y su entrenador actual. La usan los dos.
class ChatThread extends StatefulWidget {
  final String memberId;
  final String trainerId;
  final String meId;
  final bool showQuickReplies;

  /// Texto para el estado vacío ("Escríbele a Yamil…").
  final String emptyHint;

  const ChatThread({
    super.key,
    required this.memberId,
    required this.trainerId,
    required this.meId,
    required this.emptyHint,
    this.showQuickReplies = false,
  });

  @override
  State<ChatThread> createState() => _ChatThreadState();
}

class _ChatThreadState extends State<ChatThread> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  List<ChatMessage> _messages = [];
  bool _loading = true;
  bool _error = false;
  RealtimeChannel? _channel;
  Timer? _readDebounce;

  @override
  void initState() {
    super.initState();
    _load();
    _channel = ChatService.watchThread(widget.memberId, _onIncoming);
  }

  @override
  void dispose() {
    final c = _channel;
    if (c != null) ChatService.unwatch(c);
    _readDebounce?.cancel();
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final list = await ChatService.thread(widget.memberId, widget.trainerId);
      if (!mounted) return;
      setState(() {
        _messages = list;
        _loading = false;
        _error = false;
      });
      _markRead();
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = true;
        });
      }
    }
  }

  void _onIncoming(ChatMessage m) {
    if (!mounted || m.trainerId != widget.trainerId) return;
    setState(() => _messages = mergeMessage(_messages, m));
    if (m.senderId != widget.meId && m.readAt == null) {
      HapticFeedback.selectionClick();
      _markRead();
    }
  }

  void _markRead() {
    final pending = _messages
        .any((m) => m.senderId != widget.meId && m.readAt == null);
    if (!pending) {
      ChatService.refreshUnread();
      return;
    }
    _readDebounce?.cancel();
    _readDebounce = Timer(const Duration(milliseconds: 400),
        () => ChatService.markRead(widget.memberId));
  }

  Future<void> _send([String? text, ChatMessage? retry]) async {
    final body = (text ?? retry?.body ?? _ctrl.text).trim();
    if (body.isEmpty) return;
    if (text == null && retry == null) _ctrl.clear();
    final draft = retry?.copyWith(state: SendState.sending) ??
        ChatMessage(
          id: 'local-${DateTime.now().microsecondsSinceEpoch}',
          memberId: widget.memberId,
          trainerId: widget.trainerId,
          senderId: widget.meId,
          body: body,
          createdAt: DateTime.now(),
          state: SendState.sending,
        );
    setState(() {
      _messages = [..._messages.where((m) => m.id != draft.id), draft];
    });
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final saved = await ChatService.send(
          memberId: widget.memberId,
          trainerId: widget.trainerId,
          body: body,
        );
        if (!mounted) return;
        setState(() {
          _messages = mergeMessage(
              _messages.where((m) => m.id != draft.id).toList(), saved);
        });
        return;
      } catch (_) {
        if (attempt == 0) await Future.delayed(const Duration(seconds: 3));
      }
    }
    if (!mounted) return;
    setState(() {
      _messages = [
        for (final m in _messages)
          m.id == draft.id ? m.copyWith(state: SendState.failed) : m
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    final lastMineRead = _messages.lastIndexWhere(
        (m) => m.senderId == widget.meId && m.readAt != null);
    final lastMine = _messages.lastIndexWhere((m) => m.senderId == widget.meId);

    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error) {
      body = Center(
        child: TextButton.icon(
          onPressed: () {
            setState(() => _loading = true);
            _load();
          },
          icon: const Icon(Icons.refresh),
          label: const Text('No se pudo cargar. Reintentar'),
        ),
      );
    } else if (_messages.isEmpty) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(widget.emptyHint,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 15, height: 1.4)),
        ),
      );
    } else {
      final n = _messages.length;
      body = ListView.builder(
        controller: _scroll,
        reverse: true,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        itemCount: n,
        itemBuilder: (context, ri) {
          final i = n - 1 - ri;
          final m = _messages[i];
          final prev = i > 0 ? _messages[i - 1] : null;
          final newDay = prev == null ||
              dayLabel(prev.createdAt) != dayLabel(m.createdAt);
          return Column(
            children: [
              if (newDay)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(dayLabel(m.createdAt).toUpperCase(),
                      style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2)),
                ),
              _Bubble(
                message: m,
                mine: m.senderId == widget.meId,
                showSeen: i == lastMineRead && lastMineRead == lastMine,
                onRetry: () => _send(null, m),
              ),
            ],
          );
        },
      );
    }

    return Column(
      children: [
        Expanded(child: body),
        if (widget.showQuickReplies && !_loading)
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final r in trainerQuickReplies)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ActionChip(
                      label: Text(r, style: const TextStyle(fontSize: 12)),
                      onPressed: () => _send(r),
                    ),
                  ),
              ],
            ),
          ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 8, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    minLines: 1,
                    maxLines: 5,
                    maxLength: 2000,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: 'Escribe un mensaje',
                      counterText: '',
                      filled: true,
                      fillColor: AppColors.inputFill,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _ctrl,
                  builder: (_, v, __) => IconButton.filled(
                    tooltip: 'Enviar',
                    onPressed: v.text.trim().isEmpty ? null : () => _send(),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      minimumSize: const Size(46, 46),
                    ),
                    icon: const Icon(Icons.send),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage message;
  final bool mine;
  final bool showSeen;
  final VoidCallback onRetry;
  const _Bubble({
    required this.message,
    required this.mine,
    required this.showSeen,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final m = message;
    final fg = mine ? AppColors.onPrimary : AppColors.textPrimary;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78),
        child: Column(
          crossAxisAlignment:
              mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onLongPress: () => ShareHelper.copy(context, m.body),
              onTap: m.state == SendState.failed ? onRetry : null,
              child: Opacity(
                opacity: m.state == SendState.sending ? 0.6 : 1,
                child: Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                  decoration: BoxDecoration(
                    color: mine ? AppColors.primary : AppColors.cardBackground,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(mine ? 18 : 4),
                      bottomRight: Radius.circular(mine ? 4 : 18),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (m.sessionId != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.fitness_center,
                                size: 12, color: fg.withValues(alpha: 0.7)),
                            const SizedBox(width: 4),
                            Text('Sobre un entreno',
                                style: TextStyle(
                                    color: fg.withValues(alpha: 0.7),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700)),
                          ]),
                        ),
                      Text(m.body,
                          style: TextStyle(color: fg, fontSize: 15, height: 1.3)),
                      const SizedBox(height: 2),
                      Text(_hhmm(m.createdAt),
                          style: TextStyle(
                              color: fg.withValues(alpha: 0.6), fontSize: 10)),
                    ],
                  ),
                ),
              ),
            ),
            if (m.state == SendState.failed)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text('No se envió · toca para reintentar',
                    style: TextStyle(color: AppColors.error, fontSize: 11)),
              )
            else if (showSeen)
              Padding(
                padding: const EdgeInsets.only(top: 2, right: 4),
                child: Text('Visto',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 11)),
              ),
          ],
        ),
      ),
    );
  }
}
