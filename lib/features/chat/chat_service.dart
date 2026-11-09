import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/supabase_config.dart';

enum SendState { sent, sending, failed }

class ChatMessage {
  final String id;
  final String memberId;
  final String trainerId;
  final String senderId;
  final String body;
  final String? sessionId;
  final DateTime createdAt;
  final DateTime? readAt;

  /// Solo para mensajes propios aún no confirmados por el servidor.
  final SendState state;

  const ChatMessage({
    required this.id,
    required this.memberId,
    required this.trainerId,
    required this.senderId,
    required this.body,
    this.sessionId,
    required this.createdAt,
    this.readAt,
    this.state = SendState.sent,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id: j['id'] as String,
        memberId: j['member_id'] as String,
        trainerId: j['trainer_id'] as String,
        senderId: j['sender_id'] as String,
        body: j['body'] as String,
        sessionId: j['session_id'] as String?,
        createdAt: DateTime.parse(j['created_at'] as String).toLocal(),
        readAt: j['read_at'] == null
            ? null
            : DateTime.parse(j['read_at'] as String).toLocal(),
      );

  ChatMessage copyWith({DateTime? readAt, SendState? state}) => ChatMessage(
        id: id,
        memberId: memberId,
        trainerId: trainerId,
        senderId: senderId,
        body: body,
        sessionId: sessionId,
        createdAt: createdAt,
        readAt: readAt ?? this.readAt,
        state: state ?? this.state,
      );
}

/// Fila de la lista de chats del entrenador.
class ChatSummary {
  final String memberId;
  final String name;
  final String? photoUrl;
  final String? lastBody;
  final DateTime? lastAt;
  final bool lastFromMe;
  final int unread;

  const ChatSummary({
    required this.memberId,
    required this.name,
    this.photoUrl,
    this.lastBody,
    this.lastAt,
    this.lastFromMe = false,
    this.unread = 0,
  });

  factory ChatSummary.fromJson(Map<String, dynamic> j) => ChatSummary(
        memberId: j['member_id'] as String,
        name: (j['name'] as String?) ?? 'Socio',
        photoUrl: j['photo_url'] as String?,
        lastBody: j['last_body'] as String?,
        lastAt: j['last_at'] == null
            ? null
            : DateTime.parse(j['last_at'] as String).toLocal(),
        lastFromMe: (j['last_from_me'] as bool?) ?? false,
        unread: (j['unread'] as num?)?.toInt() ?? 0,
      );
}

/// Inserta un mensaje recibido o confirmado en la lista ordenada, sin
/// duplicar y reemplazando el borrador local equivalente.
List<ChatMessage> mergeMessage(List<ChatMessage> list, ChatMessage m) {
  final out = [...list];
  final byId = out.indexWhere((x) => x.id == m.id);
  if (byId >= 0) {
    out[byId] = m;
    return out;
  }
  final draft = out.indexWhere((x) =>
      x.state != SendState.sent && x.senderId == m.senderId && x.body == m.body);
  if (draft >= 0) out.removeAt(draft);
  out.add(m);
  out.sort((a, b) => a.createdAt.compareTo(b.createdAt));
  return out;
}

/// Mensajes socio ↔ entrenador (database/chat_migration.sql).
class ChatService {
  ChatService._();

  static SupabaseClient get _db => SupabaseConfig.client;

  /// No leídos para la pestaña Chat/Chats.
  static final ValueNotifier<int> unread = ValueNotifier<int>(0);

  static RealtimeChannel? _global;
  static String? _globalFor;

  static Future<void> refreshUnread() async {
    try {
      final n = await _db.rpc('chat_unread_count');
      unread.value = (n as num?)?.toInt() ?? 0;
    } catch (_) {}
  }

  /// Escucha mensajes nuevos para mantener el contador al día.
  static void startListening({required String userId, required bool asTrainer}) {
    final key = '$userId-$asTrainer';
    if (_globalFor == key) return;
    stopListening();
    _globalFor = key;
    refreshUnread();
    _global = _db
        .channel('dm-badge-$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'direct_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: asTrainer ? 'trainer_id' : 'member_id',
            value: userId,
          ),
          callback: (_) => refreshUnread(),
        )
        .subscribe();
  }

  static void stopListening() {
    final c = _global;
    _global = null;
    _globalFor = null;
    if (c != null) _db.removeChannel(c);
    unread.value = 0;
  }

  static Future<List<ChatMessage>> thread(String memberId, String trainerId) async {
    final rows = await _db
        .from('direct_messages')
        .select()
        .eq('member_id', memberId)
        .eq('trainer_id', trainerId)
        .order('created_at', ascending: false)
        .limit(200);
    return (rows as List)
        .map((r) => ChatMessage.fromJson(Map<String, dynamic>.from(r as Map)))
        .toList()
        .reversed
        .toList();
  }

  static Future<ChatMessage> send({
    required String memberId,
    required String trainerId,
    required String body,
    String? sessionId,
  }) async {
    final row = await _db
        .from('direct_messages')
        .insert({
          'member_id': memberId,
          'trainer_id': trainerId,
          'sender_id': _db.auth.currentUser!.id,
          'body': body.trim(),
          if (sessionId != null) 'session_id': sessionId,
        })
        .select()
        .single();
    return ChatMessage.fromJson(row);
  }

  static Future<void> markRead(String memberId) async {
    try {
      await _db.rpc('mark_chat_read', params: {'p_member': memberId});
      await refreshUnread();
    } catch (_) {}
  }

  static Future<List<ChatSummary>> myChats() async {
    final rows = await _db.rpc('my_chats');
    return (rows as List)
        .map((r) => ChatSummary.fromJson(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  /// Canal en tiempo real de una conversación.
  static RealtimeChannel watchThread(
    String memberId,
    void Function(ChatMessage m) onMessage,
  ) {
    return _db
        .channel('dm-thread-$memberId-${DateTime.now().microsecondsSinceEpoch}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'direct_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'member_id',
            value: memberId,
          ),
          callback: (p) {
            if (p.newRecord.isEmpty) return;
            try {
              onMessage(ChatMessage.fromJson(p.newRecord));
            } catch (_) {}
          },
        )
        .subscribe();
  }

  static Future<void> unwatch(RealtimeChannel c) => _db.removeChannel(c);
}
