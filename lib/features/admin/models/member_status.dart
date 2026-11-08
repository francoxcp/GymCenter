/// Estado de constancia de un socio (semáforo del entrenador).
enum MemberLight { red, yellow, green }

class MemberStatus {
  final String userId;
  final int plannedPerWeek; // días con rutina en su plan
  final int sessionsThisWeek;
  final DateTime? lastSession;
  final MemberLight light;

  const MemberStatus({
    required this.userId,
    required this.plannedPerWeek,
    required this.sessionsThisWeek,
    required this.lastSession,
    required this.light,
  });

  int? daysSinceLast(DateTime now) => lastSession == null
      ? null
      : DateTime(now.year, now.month, now.day)
          .difference(DateTime(
              lastSession!.year, lastSession!.month, lastSession!.day))
          .inDays;

  /// Reglas del semáforo:
  /// - 🔴 nunca entrenó o lleva 7+ días sin venir.
  /// - 🟡 lleva 4+ días sin venir, o va por debajo de lo esperado según el
  ///   día de la semana (p. ej. plan de 4: el jueves debería llevar 2).
  /// - 🟢 al día.
  static MemberStatus compute({
    required String userId,
    required int plannedPerWeek,
    required List<DateTime> sessions,
    required DateTime now,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    DateTime? last;
    var thisWeek = 0;
    for (final s in sessions) {
      final d = s.toLocal();
      if (last == null || d.isAfter(last)) last = d;
      if (!DateTime(d.year, d.month, d.day).isBefore(weekStart)) thisWeek++;
    }

    final daysSince = last == null
        ? null
        : today.difference(DateTime(last.year, last.month, last.day)).inDays;
    final expectedSoFar = (plannedPerWeek * today.weekday / 7).floor();

    MemberLight light;
    if (daysSince == null || daysSince >= 7) {
      light = MemberLight.red;
    } else if (daysSince >= 4 ||
        (plannedPerWeek > 0 && thisWeek < expectedSoFar)) {
      light = MemberLight.yellow;
    } else {
      light = MemberLight.green;
    }

    return MemberStatus(
      userId: userId,
      plannedPerWeek: plannedPerWeek,
      sessionsThisWeek: thisWeek,
      lastSession: last,
      light: light,
    );
  }
}
