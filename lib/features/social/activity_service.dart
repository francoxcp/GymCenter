import '../../config/supabase_config.dart';

/// Entreno terminado que aparece en el feed del entrenador/dueño.
class FeedItem {
  final String sessionId;
  final String userId;
  final String userName;
  final String? photoUrl;
  final String workoutName;
  final int durationMinutes;
  final double volumeKg;
  final DateTime completedAt;
  final int commentCount;

  const FeedItem({
    required this.sessionId,
    required this.userId,
    required this.userName,
    required this.photoUrl,
    required this.workoutName,
    required this.durationMinutes,
    required this.volumeKg,
    required this.completedAt,
    required this.commentCount,
  });

  factory FeedItem.fromJson(Map<String, dynamic> j) {
    final user = j['users'] as Map<String, dynamic>?;
    final workout = j['workouts'] as Map<String, dynamic>?;
    final comments = j['session_comments'];
    var count = 0;
    if (comments is List && comments.isNotEmpty) {
      count = (comments.first['count'] as num?)?.toInt() ?? 0;
    }
    return FeedItem(
      sessionId: j['id'] as String,
      userId: j['user_id'] as String,
      userName: (user?['name'] as String?) ?? 'Socio',
      photoUrl: user?['photo_url'] as String?,
      workoutName: (workout?['name'] as String?) ?? 'Rutina',
      durationMinutes: (j['duration_minutes'] as num?)?.toInt() ?? 0,
      volumeKg: (j['total_volume_kg'] as num?)?.toDouble() ?? 0,
      completedAt:
          DateTime.tryParse(j['completed_at'] as String? ?? '')?.toLocal() ??
              DateTime.now(),
      commentCount: count,
    );
  }
}

class SessionComment {
  final String id;
  final String sessionId;
  final String authorId;
  final String authorName;
  final String body;
  final DateTime createdAt;

  const SessionComment({
    required this.id,
    required this.sessionId,
    required this.authorId,
    required this.authorName,
    required this.body,
    required this.createdAt,
  });

  factory SessionComment.fromJson(Map<String, dynamic> j) => SessionComment(
        id: j['id'] as String,
        sessionId: j['session_id'] as String,
        authorId: j['author_id'] as String,
        authorName:
            ((j['users'] as Map<String, dynamic>?)?['name'] as String?) ?? '',
        body: j['body'] as String? ?? '',
        createdAt:
            DateTime.tryParse(j['created_at'] as String? ?? '')?.toLocal() ??
                DateTime.now(),
      );
}

/// Acceso a Supabase del feed y los comentarios. La seguridad la imponen
/// las políticas RLS (ver database/ux_feed_membership_migration.sql).
class ActivityService {
  ActivityService._();

  static const _feedSelect =
      'id, user_id, duration_minutes, total_volume_kg, completed_at, '
      'users(name, photo_url), '
      'workouts(name), session_comments(count)';

  /// Entrenos terminados de los socios visibles para el usuario actual
  /// (dueño: todos; entrenador: los suyos), excluyendo los propios.
  static Future<List<FeedItem>> loadFeed({
    int limit = 30,
    DateTime? before,
  }) async {
    final me = SupabaseConfig.client.auth.currentUser?.id;
    var q = SupabaseConfig.client.from('workout_sessions').select(_feedSelect);
    if (me != null) q = q.neq('user_id', me);
    if (before != null) {
      q = q.lt('completed_at', before.toUtc().toIso8601String());
    }
    final rows = await q.order('completed_at', ascending: false).limit(limit);
    return (rows as List)
        .map((r) => FeedItem.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  static Future<List<SessionComment>> loadComments(String sessionId) async {
    final rows = await SupabaseConfig.client
        .from('session_comments')
        .select('id, session_id, author_id, body, created_at, '
            'users(name)')
        .eq('session_id', sessionId)
        .order('created_at');
    return (rows as List)
        .map((r) => SessionComment.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  static Future<void> addComment(String sessionId, String body) async {
    final me = SupabaseConfig.client.auth.currentUser?.id;
    if (me == null) throw StateError('Sin sesión');
    final text = body.trim();
    if (text.isEmpty) return;
    await SupabaseConfig.client.from('session_comments').insert({
      'session_id': sessionId,
      'author_id': me,
      'body': text.length > 500 ? text.substring(0, 500) : text,
    });
  }

  static Future<void> deleteComment(String id) async {
    await SupabaseConfig.client.from('session_comments').delete().eq('id', id);
  }

}
