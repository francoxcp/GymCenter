import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/l10n/app_l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/navigation/safe_pop.dart';
import '../../auth/providers/auth_provider.dart';
import '../../workouts/services/progression_engine.dart';

/// Control semanal del entrenamiento.
///
/// - Cumplimiento de la semana (entrenamientos hechos vs días planificados).
/// - Entrenamientos y volumen de las últimas 8 semanas.
/// - Evolución de cada ejercicio (peso máximo, 1RM estimado, tendencia) y la
///   sugerencia de progresión para la próxima sesión.
///
/// El socio la ve para sí mismo; el admin puede abrirla para cualquier socio
/// (`userId`), gracias a las políticas de lectura de admin.
class TrainingControlScreen extends StatefulWidget {
  final String? userId;
  final String? userName;

  const TrainingControlScreen({super.key, this.userId, this.userName});

  @override
  State<TrainingControlScreen> createState() => _TrainingControlScreenState();
}

class _WeekStats {
  final DateTime weekStart;
  int sessions = 0;
  int completedSets = 0;
  double volumeLbs = 0;
  _WeekStats(this.weekStart);
}

class _ExerciseStats {
  final String name;
  final List<ExerciseSession> sessions; // más reciente primero
  final ProgressionSuggestion? suggestion;
  _ExerciseStats(this.name, this.sessions, this.suggestion);

  double? get lastTopLbs =>
      sessions.isEmpty ? null : (sessions.first.topWeightKg ?? 0) * kKgToLbs;
  double? get prevTopLbs => sessions.length < 2
      ? null
      : (sessions[1].topWeightKg ?? 0) * kKgToLbs;
  double? get best1RmLbs {
    final vs = sessions.map((s) => s.best1RmKg).whereType<double>();
    if (vs.isEmpty) return null;
    return vs.reduce((a, b) => a > b ? a : b) * kKgToLbs;
  }
}

class _TrainingControlScreenState extends State<TrainingControlScreen> {
  static const _weeks = 8;

  bool _loading = true;
  String? _error;
  int _plannedDays = 0;
  List<_WeekStats> _weekStats = [];
  List<_ExerciseStats> _exercises = [];
  bool _showVolume = false;

  String? get _targetUserId =>
      widget.userId ??
      Provider.of<AuthProvider>(context, listen: false).currentUser?.id;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  static DateTime _weekStart(DateTime d) {
    final local = DateTime(d.year, d.month, d.day);
    return local.subtract(Duration(days: local.weekday - 1));
  }

  Future<void> _load() async {
    final uid = _targetUserId;
    if (uid == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final client = Supabase.instance.client;
    final now = DateTime.now();
    final firstWeek =
        _weekStart(now).subtract(const Duration(days: 7 * (_weeks - 1)));
    final since = now.subtract(const Duration(days: 120));

    try {
      final results = await Future.wait([
        client
            .from('exercise_set_logs')
            .select('*')
            .eq('user_id', uid)
            .gte('logged_at', since.toUtc().toIso8601String())
            .order('logged_at', ascending: false)
            .limit(4000),
        client
            .from('workout_sessions')
            .select('completed_at')
            .eq('user_id', uid)
            .gte('completed_at', firstWeek.toUtc().toIso8601String()),
        client.from('user_workout_schedule').select('id').eq('user_id', uid),
      ]);

      final logs = (results[0] as List)
          .map((e) => SetLog.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
      final sessions = results[1] as List;
      final schedule = results[2] as List;

      // ── Semanas ──────────────────────────────────────────────────────
      final weeks = [
        for (var i = 0; i < _weeks; i++)
          _WeekStats(firstWeek.add(Duration(days: 7 * i))),
      ];
      int weekIndex(DateTime d) =>
          _weekStart(d).difference(firstWeek).inDays ~/ 7;

      for (final s in sessions) {
        final d = DateTime.tryParse(s['completed_at'] as String? ?? '')
            ?.toLocal();
        if (d == null) continue;
        final i = weekIndex(d);
        if (i >= 0 && i < _weeks) weeks[i].sessions++;
      }

      // ── Ejercicios (agrupados por nombre) ───────────────────────────
      final byName = <String, List<SetLog>>{};
      for (final l in logs) {
        final key = l.exerciseName.trim();
        if (key.isEmpty) continue;
        byName.putIfAbsent(key, () => []).add(l);
      }
      final exercises = <_ExerciseStats>[];
      for (final entry in byName.entries) {
        final exSessions = ProgressionEngine.groupSessions(entry.value);
        for (final es in exSessions) {
          final i = weekIndex(es.date);
          if (i >= 0 && i < _weeks) {
            weeks[i].completedSets += es.completedSets;
            weeks[i].volumeLbs += es.volumeKg * kKgToLbs;
          }
        }
        ProgressionSuggestion? suggestion;
        if (exSessions.isNotEmpty) {
          final last = exSessions.first;
          final target = last.sets
                  .map((s) => s.targetReps ?? s.reps)
                  .whereType<int>()
                  .fold<int>(0, (a, b) => a > b ? a : b);
          if (target > 0) {
            suggestion = ProgressionEngine.suggest(
              logs: entry.value,
              targetSets: last.sets.length,
              targetReps: target,
              lowerBody: ProgressionEngine.isLowerBody('', entry.key),
            );
          }
        }
        exercises.add(_ExerciseStats(entry.key, exSessions, suggestion));
      }
      exercises.sort((a, b) => b.sessions.first.date.compareTo(a.sessions.first.date));

      if (!mounted) return;
      setState(() {
        _weekStats = weeks;
        _exercises = exercises;
        _plannedDays = schedule.length;
        _loading = false;
      });
    } catch (e) {
      debugPrint('TrainingControl error: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  String _fmtLbs(double? lbs) {
    if (lbs == null) return '—';
    return lbs == lbs.roundToDouble()
        ? '${lbs.toInt()} lbs'
        : '${lbs.toStringAsFixed(1)} lbs';
  }

  String _fmtVolume(double lbs) {
    if (lbs >= 1000) return '${(lbs / 1000).toStringAsFixed(1)}k lbs';
    return '${lbs.round()} lbs';
  }

  @override
  Widget build(BuildContext context) {
    final isEn = AppL10n.of(context).isEn;
    final title = widget.userName != null
        ? (isEn ? 'Training · ${widget.userName}' : 'Control · ${widget.userName}')
        : (isEn ? 'Weekly training control' : 'Control semanal');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
 tooltip: 'Atrás',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context
              .popOrGo(widget.userId != null ? '/admin/users' : '/progress'),
        ),
        title: Text(title),
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(color: AppColors.primaryText))
          : _error != null
              ? _buildError(isEn)
              : RefreshIndicator(
                  color: AppColors.primaryText,
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildThisWeek(isEn),
                      const SizedBox(height: 20),
                      _buildWeeksChart(isEn),
                      const SizedBox(height: 24),
                      Text(
                        isEn ? 'EXERCISES' : 'EJERCICIOS',
                        style: TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (_exercises.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            isEn
                                ? 'No weights logged yet. Log the weight of each set during your workout to see your progress here.'
                                : 'Aún no hay pesos registrados. Anota el peso de cada serie durante tu rutina para ver aquí tu progreso.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: AppColors.textSecondary, height: 1.4),
                          ),
                        )
                      else
                        ..._exercises.map((e) => _buildExerciseTile(e, isEn)),
                    ],
                  ),
                ),
    );
  }

  Widget _buildError(bool isEn) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded,
                color: AppColors.textSecondary, size: 48),
            const SizedBox(height: 16),
            Text(
              isEn
                  ? 'Could not load your training data. Check your connection.'
                  : 'No se pudieron cargar tus datos. Revisa tu conexión.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
              ),
              child: Text(isEn ? 'Retry' : 'Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(18),
        ),
        child: child,
      );

  Widget _buildThisWeek(bool isEn) {
    final week = _weekStats.isNotEmpty ? _weekStats.last : null;
    final done = week?.sessions ?? 0;
    final planned = _plannedDays;
    final ratio = planned > 0 ? (done / planned).clamp(0.0, 1.0) : 0.0;

    Widget stat(String value, String label) => Expanded(
          child: Column(
            children: [
              Text(value,
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 11)),
            ],
          ),
        );

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEn ? 'This week' : 'Esta semana',
            style: TextStyle(
                color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                planned > 0 ? '$done/$planned' : '$done',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  planned > 0
                      ? (isEn ? 'planned workouts done' : 'entrenamientos del plan')
                      : (isEn ? 'workouts' : 'entrenamientos'),
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          if (planned > 0) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 8,
                backgroundColor: AppColors.surface,
                color: ratio >= 1 ? AppColors.success : AppColors.primaryText,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              stat('${week?.completedSets ?? 0}',
                  isEn ? 'sets done' : 'series hechas'),
              stat(_fmtVolume(week?.volumeLbs ?? 0),
                  isEn ? 'volume lifted' : 'volumen levantado'),
              stat(
                  '${_exercises.where((e) => e.suggestion?.action == ProgressionAction.increase).length}',
                  isEn ? 'ready to go up' : 'listos para subir'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeksChart(bool isEn) {
    final values = _weekStats
        .map((w) => _showVolume ? w.volumeLbs : w.sessions.toDouble())
        .toList();
    final maxY = values.fold<double>(0, (a, b) => a > b ? a : b);

    Widget toggle(String label, bool selected, VoidCallback onTap) =>
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(label,
                style: TextStyle(
                  color: selected ? Colors.black : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                )),
          ),
        );

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isEn ? 'Last 8 weeks' : 'Últimas 8 semanas',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.bold),
                ),
              ),
              toggle(isEn ? 'Workouts' : 'Entrenos', !_showVolume,
                  () => setState(() => _showVolume = false)),
              const SizedBox(width: 6),
              toggle(isEn ? 'Volume' : 'Volumen', _showVolume,
                  () => setState(() => _showVolume = true)),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                maxY: maxY <= 0 ? 1 : maxY * 1.2,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                      _showVolume ? _fmtVolume(rod.toY) : '${rod.toY.toInt()}',
                      TextStyle(
                          color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= _weekStats.length) {
                          return const SizedBox.shrink();
                        }
                        final d = _weekStats[i].weekStart;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '${d.day}/${d.month}',
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < values.length; i++)
                    BarChartGroupData(x: i, barRods: [
                      BarChartRodData(
                        toY: values[i],
                        width: 16,
                        color: i == values.length - 1
                            ? AppColors.primary
                            : AppColors.primaryText.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ]),
                ],
              ),
            ),
          ),
          if (!_showVolume && _plannedDays > 0) ...[
            const SizedBox(height: 8),
            Text(
              isEn
                  ? 'Plan: $_plannedDays workouts per week'
                  : 'Plan: $_plannedDays entrenamientos por semana',
              style:
                  TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExerciseTile(_ExerciseStats e, bool isEn) {
    final last = e.lastTopLbs;
    final prev = e.prevTopLbs;
    IconData trendIcon = Icons.trending_flat;
    Color trendColor = AppColors.textSecondary;
    if (last != null && prev != null) {
      if (last > prev + 0.1) {
        trendIcon = Icons.trending_up;
        trendColor = AppColors.success;
      } else if (last < prev - 0.1) {
        trendIcon = Icons.trending_down;
        trendColor = Colors.orangeAccent;
      }
    }

    String? hint;
    final s = e.suggestion;
    if (s != null) {
      switch (s.action) {
        case ProgressionAction.increase:
          hint = isEn
              ? 'Next: go up to ${_fmtLbs(s.suggestedWeightLbs)}'
              : 'Próxima: subir a ${_fmtLbs(s.suggestedWeightLbs)}';
          break;
        case ProgressionAction.maintain:
          hint = isEn
              ? 'Next: stay at ${_fmtLbs(s.suggestedWeightLbs)}'
              : 'Próxima: mantener ${_fmtLbs(s.suggestedWeightLbs)}';
          break;
        case ProgressionAction.deload:
          hint = isEn
              ? 'Next: deload to ${_fmtLbs(s.suggestedWeightLbs)}'
              : 'Próxima: descarga a ${_fmtLbs(s.suggestedWeightLbs)}';
          break;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        onTap: () => _showExerciseDetail(e, isEn),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(e.name,
            style: TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        subtitle: Text(
          [
            '${isEn ? 'Top' : 'Máx'}: ${_fmtLbs(last)}',
            if (hint != null) hint,
          ].join(' · '),
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        trailing: Icon(trendIcon, color: trendColor),
      ),
    );
  }

  void _showExerciseDetail(_ExerciseStats e, bool isEn) {
    final chronological = e.sessions.reversed.toList();
    final topSpots = <FlSpot>[];
    final rmSpots = <FlSpot>[];
    for (var i = 0; i < chronological.length; i++) {
      final t = chronological[i].topWeightKg;
      final rm = chronological[i].best1RmKg;
      if (t != null) topSpots.add(FlSpot(i.toDouble(), t * kKgToLbs));
      if (rm != null) rmSpots.add(FlSpot(i.toDouble(), rm * kKgToLbs));
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, scroll) => Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(e.name,
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 19,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                '${isEn ? 'Best estimated 1RM' : 'Mejor 1RM estimado'}: ${_fmtLbs(e.best1RmLbs?.roundToDouble())}',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 18),
              if (topSpots.length >= 2)
                SizedBox(
                  height: 190,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      titlesData: const FlTitlesData(
                        topTitles:
                            AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles:
                            AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles:
                            AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles:
                              SideTitles(showTitles: true, reservedSize: 40),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: topSpots,
                          isCurved: true,
                          color: AppColors.primaryText,
                          barWidth: 3,
                          dotData: const FlDotData(show: true),
                        ),
                        if (rmSpots.length >= 2)
                          LineChartBarData(
                            spots: rmSpots,
                            isCurved: true,
                            color: Colors.lightBlueAccent,
                            barWidth: 2,
                            dashArray: [6, 4],
                            dotData: const FlDotData(show: false),
                          ),
                      ],
                    ),
                  ),
                )
              else
                Text(
                  isEn
                      ? 'Log at least two sessions to see the chart.'
                      : 'Registra al menos dos sesiones para ver la gráfica.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              if (topSpots.length >= 2) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    _legend(AppColors.primary,
                        isEn ? 'Top weight' : 'Peso máximo'),
                    const SizedBox(width: 16),
                    _legend(Colors.lightBlueAccent,
                        isEn ? 'Estimated 1RM' : '1RM estimado'),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              ...e.sessions.take(12).map((s) {
                final sets = s.sets
                    .map((x) =>
                        '${_fmtLbs(x.weightKg == null ? null : x.weightKg! * kKgToLbs)}×${x.reps ?? '-'}${x.completed ? '' : ' ✗'}')
                    .join('  ');
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${s.date.day}/${s.date.month}/${s.date.year}',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(sets,
                          style: TextStyle(
                              color: AppColors.textPrimary, fontSize: 13)),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _legend(Color c, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 12,
              height: 3,
              decoration: BoxDecoration(
                  color: c, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 6),
          Text(label,
              style:
                  TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ],
      );
}
