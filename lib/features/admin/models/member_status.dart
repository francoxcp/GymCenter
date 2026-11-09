import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Estado de constancia de un socio (semáforo del entrenador).
/// [fresh]: se unió hace poco y todavía no entrena (no es una alerta).
enum MemberLight { red, yellow, green, fresh }

/// Días en los que un socio sin entrenos cuenta como nuevo, no como ausente.
const int kNewMemberDays = 7;

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

  /// Mismo estado con otro número de días planificados (tras asignar rutinas).
  MemberStatus withPlanned(int planned, {DateTime? joinedAt, DateTime? now}) {
    final n = now ?? DateTime.now();
    return MemberStatus(
      userId: userId,
      plannedPerWeek: planned,
      sessionsThisWeek: sessionsThisWeek,
      lastSession: lastSession,
      light: _lightFor(
        daysSince: daysSinceLast(n),
        planned: planned,
        thisWeek: sessionsThisWeek,
        today: DateTime(n.year, n.month, n.day),
        joinedAt: joinedAt,
        keepFresh: light == MemberLight.fresh,
      ),
    );
  }

  static MemberLight _lightFor({
    required int? daysSince,
    required int planned,
    required int thisWeek,
    required DateTime today,
    DateTime? joinedAt,
    bool keepFresh = false,
  }) {
    final isNew = daysSince == null &&
        (keepFresh ||
            (joinedAt != null &&
                today.difference(joinedAt.toLocal()).inDays < kNewMemberDays));
    if (isNew) return MemberLight.fresh;
    final expectedSoFar = (planned * today.weekday / 7).floor();
    if (daysSince == null || daysSince >= 7) return MemberLight.red;
    if (daysSince >= 4 || (planned > 0 && thisWeek < expectedSoFar)) {
      return MemberLight.yellow;
    }
    return MemberLight.green;
  }

  /// Reglas del semáforo:
  /// - Nuevo: se unió hace menos de 7 días y aún no entrena.
  /// - 🔴 nunca entrenó o lleva 7+ días sin venir.
  /// - 🟡 lleva 4+ días sin venir, o va por debajo de lo esperado según el
  ///   día de la semana (p. ej. plan de 4: el jueves debería llevar 2).
  /// - 🟢 al día.
  static MemberStatus compute({
    required String userId,
    required int plannedPerWeek,
    required List<DateTime> sessions,
    required DateTime now,
    DateTime? joinedAt,
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
    final light = _lightFor(
      daysSince: daysSince,
      planned: plannedPerWeek,
      thisWeek: thisWeek,
      today: today,
      joinedAt: joinedAt,
    );

    return MemberStatus(
      userId: userId,
      plannedPerWeek: plannedPerWeek,
      sessionsThisWeek: thisWeek,
      lastSession: last,
      light: light,
    );
  }
}

/// Color del semáforo.
Color memberLightColor(MemberLight l) => switch (l) {
      MemberLight.red => AppColors.error,
      MemberLight.yellow => AppColors.warning,
      MemberLight.green => AppColors.success,
      MemberLight.fresh => AppColors.primaryText,
    };
