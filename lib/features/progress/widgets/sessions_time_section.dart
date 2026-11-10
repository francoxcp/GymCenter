import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../workouts/models/workout_session.dart';
import '../../workouts/providers/workout_provider.dart';
import '../../workouts/providers/workout_session_provider.dart';
import '../../workouts/services/calorie_estimator.dart';
import '../models/body_measurement.dart';
import '../providers/body_measurement_provider.dart';

String fmtMinutes(int m) {
  if (m < 60) return '$m min';
  final h = m ~/ 60;
  final r = m % 60;
  return r == 0 ? '$h h' : '$h h $r min';
}

const _wd = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
const _mo = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];

/// Totales por rutina (tiempo total y promedio).
class RoutineTotals {
  final String workoutId;
  final int sessions;
  final int minutes;
  final int calories;
  const RoutineTotals(this.workoutId, this.sessions, this.minutes, this.calories);
  int get avgMinutes => sessions == 0 ? 0 : (minutes / sessions).round();
}

/// Clave de agrupación: el id de la rutina o, si se borró, su nombre.
String routineKey(WorkoutSession s) =>
    s.workoutId.isNotEmpty ? s.workoutId : 'name:${s.workoutName ?? ''}';

List<RoutineTotals> totalsByRoutine(
    List<WorkoutSession> sessions, int Function(WorkoutSession) kcal) {
  final map = <String, List<WorkoutSession>>{};
  for (final s in sessions) {
    map.putIfAbsent(routineKey(s), () => []).add(s);
  }
  final out = [
    for (final e in map.entries)
      RoutineTotals(
        e.key,
        e.value.length,
        e.value.fold(0, (a, s) => a + s.durationMinutes),
        e.value.fold(0, (a, s) => a + kcal(s)),
      )
  ]..sort((a, b) => b.minutes.compareTo(a.minutes));
  return out;
}

/// Tiempos por rutina y por día, con calorías estimadas según su peso,
/// altura, edad y género.
class SessionsTimeSection extends StatefulWidget {
  const SessionsTimeSection({super.key});

  @override
  State<SessionsTimeSection> createState() => _SessionsTimeSectionState();
}

class _SessionsTimeSectionState extends State<SessionsTimeSection> {
  bool _byDay = true;
  int _showDays = 10;

  @override
  Widget build(BuildContext context) {
    final sessions = context.watch<WorkoutSessionProvider>().sessions.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final workouts = context.watch<WorkoutProvider>();
    final me = context.watch<AuthProvider>().currentUser;
    final weight =
        context.watch<BodyMeasurementProvider>().latestOf(MeasureField.weight) ??
            me?.weightKg;

    /// Las sesiones guardan sus calorías; las viejas sin dato se estiman.
    int kcal(WorkoutSession s) => s.caloriesBurned > 0
        ? s.caloriesBurned
        : CalorieEstimator.estimate(
            minutes: s.durationMinutes,
            weightKg: weight,
            heightCm: me?.heightCm?.toDouble(),
            age: me?.age,
            sex: me?.sex,
          );
    final savedNames = {
      for (final s in sessions)
        if (s.workoutName != null) routineKey(s): s.workoutName!,
    };
    String name(String key) =>
        workouts.getWorkoutById(key)?.name ?? savedNames[key] ?? 'Rutina';

    final totalMin = sessions.fold<int>(0, (a, s) => a + s.durationMinutes);
    final totalKcal = sessions.fold<int>(0, (a, s) => a + kcal(s));
    final missingData = me?.age == null || me?.heightCm == null || weight == null;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text('TIEMPO Y CALORÍAS',
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2)),
            ),
            SegmentedButton<bool>(
              showSelectedIcon: false,
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
              segments: const [
                ButtonSegment(value: true, label: Text('Por día')),
                ButtonSegment(value: false, label: Text('Por rutina')),
              ],
              selected: {_byDay},
              onSelectionChanged: (v) => setState(() => _byDay = v.first),
            ),
          ]),
          const SizedBox(height: 12),
          if (sessions.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text('Cuando termines tu primera rutina verás aquí cuánto duró y cuánto quemaste.',
                  style: TextStyle(color: AppColors.textSecondary, height: 1.4)),
            )
          else ...[
            Row(children: [
              _Big(fmtMinutes(totalMin), 'en total'),
              _Big('$totalKcal', 'kcal estimadas'),
            ]),
            const SizedBox(height: 8),
            if (_byDay) ...[
              for (final s in sessions.take(_showDays))
                _Row(
                  title: name(routineKey(s)),
                  subtitle:
                      '${_wd[s.date.weekday - 1]} ${s.date.day} ${_mo[s.date.month - 1]}',
                  minutes: s.durationMinutes,
                  kcal: kcal(s),
                ),
              if (sessions.length > _showDays)
                TextButton(
                  onPressed: () => setState(() => _showDays += 20),
                  child: const Text('Ver más días'),
                ),
            ] else
              for (final t in totalsByRoutine(sessions, kcal))
                _Row(
                  title: name(t.workoutId),
                  subtitle:
                      '${t.sessions} ${t.sessions == 1 ? 'vez' : 'veces'} · promedio ${fmtMinutes(t.avgMinutes)}',
                  minutes: t.minutes,
                  kcal: t.calories,
                ),
          ],
          if (missingData && sessions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8, top: 4),
              child: Text(
                  'Para una estimación más exacta completa tu edad, altura y peso en tu perfil.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            ),
        ],
      ),
    );
  }
}

class _Big extends StatelessWidget {
  final String value;
  final String label;
  const _Big(this.value, this.label);
  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value,
              style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  height: 1.1)),
          Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ]),
      );
}

class _Row extends StatelessWidget {
  final String title;
  final String subtitle;
  final int minutes;
  final int kcal;
  const _Row({required this.title, required this.subtitle, required this.minutes, required this.kcal});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
              Text(subtitle, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(fmtMinutes(minutes),
                style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w900)),
            Text('$kcal kcal', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ]),
        ]),
      );
}
