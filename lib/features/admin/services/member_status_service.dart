import '../../../config/supabase_config.dart';
import '../../auth/models/user.dart';
import '../models/member_status.dart';

/// Lo que el dueño y el entrenador necesitan saber de sus socios en una sola
/// consulta (RLS ya limita a los socios que le tocan a cada uno).
class MembersSnapshot {
  final Map<String, MemberStatus> status;

  /// Socios que entrenaron hoy (id → hora del último entreno de hoy).
  final Map<String, DateTime> trainedToday;

  /// Entrenos completados desde el lunes (todos los socios).
  final int sessionsThisWeek;

  const MembersSnapshot({
    required this.status,
    required this.trainedToday,
    required this.sessionsThisWeek,
  });

  static const empty =
      MembersSnapshot(status: {}, trainedToday: {}, sessionsThisWeek: 0);

  static MembersSnapshot build({
    required List<User> members,
    required List<({String userId, DateTime at})> sessions,
    required Map<String, int> plannedByUser,
    required DateTime now,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final byUser = <String, List<DateTime>>{};
    final trainedToday = <String, DateTime>{};
    var week = 0;
    final ids = {for (final m in members) m.id};
    for (final s in sessions) {
      if (!ids.contains(s.userId)) continue;
      final at = s.at.toLocal();
      byUser.putIfAbsent(s.userId, () => []).add(at);
      final day = DateTime(at.year, at.month, at.day);
      if (!day.isBefore(weekStart)) week++;
      if (day == today) {
        final prev = trainedToday[s.userId];
        if (prev == null || at.isAfter(prev)) trainedToday[s.userId] = at;
      }
    }
    return MembersSnapshot(
      status: {
        for (final m in members)
          m.id: MemberStatus.compute(
            userId: m.id,
            plannedPerWeek: plannedByUser[m.id] ?? 0,
            sessions: byUser[m.id] ?? const [],
            now: now,
            joinedAt: m.createdAt,
          ),
      },
      trainedToday: trainedToday,
      sessionsThisWeek: week,
    );
  }
}

class MemberStatusService {
  MemberStatusService._();

  static Future<MembersSnapshot> load(List<User> members) async {
    final since = DateTime.now().subtract(const Duration(days: 35));
    final results = await Future.wait([
      SupabaseConfig.client
          .from('workout_sessions')
          .select('user_id, completed_at')
          .gte('completed_at', since.toUtc().toIso8601String()),
      SupabaseConfig.client.from('user_workout_schedule').select('user_id'),
    ]);
    final sessions = <({String userId, DateTime at})>[];
    for (final r in results[0] as List) {
      final d = DateTime.tryParse(r['completed_at'] as String? ?? '');
      if (d == null) continue;
      sessions.add((userId: r['user_id'] as String, at: d));
    }
    final planned = <String, int>{};
    for (final r in results[1] as List) {
      final id = r['user_id'] as String;
      planned[id] = (planned[id] ?? 0) + 1;
    }
    return MembersSnapshot.build(
      members: members,
      sessions: sessions,
      plannedByUser: planned,
      now: DateTime.now(),
    );
  }
}
