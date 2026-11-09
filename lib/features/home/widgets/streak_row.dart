import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Semanas seguidas con al menos un entreno. La semana actual cuenta si ya
/// entrenó; si aún no, la racha sigue viva desde la semana pasada.
int weeklyStreak(List<DateTime> sessions, DateTime now) {
  DateTime monday(DateTime d) {
    return DateTime(d.year, d.month, d.day - (d.weekday - 1));
  }

  final weeks = {for (final s in sessions) monday(s.toLocal())};
  var cursor = monday(now);
  if (!weeks.contains(cursor)) {
    cursor = DateTime(cursor.year, cursor.month, cursor.day - 7);
  }
  var n = 0;
  while (weeks.contains(cursor)) {
    n++;
    // Restar 7 días por calendario (no por horas) evita saltos por cambio de hora.
    cursor = DateTime(cursor.year, cursor.month, cursor.day - 7);
  }
  return n;
}

class StreakRow extends StatelessWidget {
  final List<DateTime> sessions;
  const StreakRow({super.key, required this.sessions});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final streak = weeklyStreak(sessions, now);
    final month = sessions
        .where((s) {
          final d = s.toLocal();
          return d.year == now.year && d.month == now.month;
        })
        .length;
    return Row(
      children: [
        _Num(
          value: '$streak',
          label: streak == 1 ? 'semana seguida' : 'semanas seguidas',
          accent: streak > 0,
        ),
        const SizedBox(width: 24),
        _Num(value: '$month', label: 'entrenos este mes'),
      ],
    );
  }
}

class _Num extends StatelessWidget {
  final String value;
  final String label;
  final bool accent;
  const _Num({required this.value, required this.label, this.accent = false});

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(value,
              style: TextStyle(
                  color: accent ? AppColors.primaryText : AppColors.textPrimary,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  height: 1,
                  fontFeatures: const [FontFeature.tabularFigures()])),
          const SizedBox(width: 6),
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text(label,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ),
        ],
      );
}
