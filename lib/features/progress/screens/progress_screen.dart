import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/l10n/app_l10n.dart';
import '../../auth/providers/auth_provider.dart';
import '../../workouts/providers/workout_session_provider.dart';
import '../providers/body_measurement_provider.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  String _selectedPeriod = 'Semana';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshData());
  }

  Future<void> _refreshData() async {
    final measurementProvider =
        Provider.of<BodyMeasurementProvider>(context, listen: false);
    final sessionProvider =
        Provider.of<WorkoutSessionProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    await Future.wait([
      measurementProvider.loadMeasurements(),
      if (authProvider.currentUser?.id != null)
        sessionProvider.loadSessions(authProvider.currentUser!.id,
            forceRefresh: true),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppL10n.of(context).myProgress),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
            tooltip: 'Ajustes',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: AppColors.primary,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Período selector
            _buildPeriodSelector(),
            const SizedBox(height: 24),

            // Racha actual
            _buildStreakCard(),
            const SizedBox(height: 20),

            // Estadísticas generales
            _buildStatsGrid(),
            const SizedBox(height: 24),

            // Gráfico de peso (placeholder)
            _buildWeightChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    final l10n = AppL10n.of(context);
    final periods = l10n.periodKeys;

    return Row(
      children: periods.map((period) {
        final isSelected = _selectedPeriod == period;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedPeriod = period),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color:
                    isSelected ? AppColors.primary : AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                l10n.periodLabel(period),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStreakCard() {
    final sessionProvider = Provider.of<WorkoutSessionProvider>(context);
    final currentStreak = sessionProvider.getCurrentStreak();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.withOpacity(0.3),
            AppColors.cardBackground,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.local_fire_department,
                  color: Colors.orange, size: 40),
              const SizedBox(width: 12),
              Text(
                AppL10n.of(context).currentStreakLabel,
                style: const TextStyle(
                  fontSize: 18,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$currentStreak',
            style: const TextStyle(
              fontSize: 60,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1,
            ),
          ),
          Text(
            AppL10n.of(context).consecutiveDaysLabel(currentStreak),
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Builder(builder: (context) {
            final l10n = AppL10n.of(context);
            return Text(
              currentStreak == 0
                  ? l10n.startStreakToday
                  : currentStreak < 7
                      ? l10n.keepGoing
                      : currentStreak < 30
                          ? l10n.incredibleStreak
                          : l10n.unstoppableStreak,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final sessionProvider = Provider.of<WorkoutSessionProvider>(context);
    final measurementProvider = Provider.of<BodyMeasurementProvider>(context);

    // Calcular estadísticas del período seleccionado
    final days = _selectedPeriod == 'Semana'
        ? 7
        : _selectedPeriod == 'Mes'
            ? 30
            : _selectedPeriod == 'Año'
                ? 365
                : 10000; // "Todo" = 10000 días (~27 años)

    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    final periodSessions = sessionProvider.sessions
        .where((s) => s.date.isAfter(cutoffDate))
        .toList();

    final totalWorkouts = periodSessions.length;
    final totalMinutes =
        periodSessions.fold<int>(0, (sum, s) => sum + s.durationMinutes);
    final totalHours = (totalMinutes / 60).toStringAsFixed(1);

    // Sumar calorías reales guardadas en cada sesión (calculadas con MET + peso real)
    final totalCalories =
        periodSessions.fold<int>(0, (sum, s) => sum + s.caloriesBurned);

    // Obtener peso actual y cambio de peso del período seleccionado
    final periodMeasurements = measurementProvider
        .getMeasurementsByPeriod(days)
        .where((m) => m.weight != null)
        .toList();

    final currentWeight = measurementProvider.latestMeasurement?.weight;
    final firstWeightInPeriod =
        periodMeasurements.isNotEmpty && periodMeasurements.last.weight != null
            ? periodMeasurements.last.weight
            : null;
    final periodWeightChange =
        currentWeight != null && firstWeightInPeriod != null
            ? currentWeight - firstWeightInPeriod
            : null;

    final l10n = AppL10n.of(context);
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: [
        _buildStatCard(
          l10n.workoutsLabel,
          '$totalWorkouts',
          Icons.fitness_center,
          Colors.blue,
          totalWorkouts > 0
              ? l10n.inPeriod(_selectedPeriod)
              : l10n.noWorkoutsYet,
        ),
        _buildStatCard(
          l10n.totalTimeStatLabel,
          totalMinutes > 0 ? '${totalHours}h' : '0h',
          Icons.access_time,
          Colors.orange,
          totalMinutes > 0
              ? l10n.inPeriod(_selectedPeriod)
              : l10n.notTrainedYet,
        ),
        _buildStatCard(
          l10n.caloriesStatLabel,
          totalCalories > 0 ? totalCalories.toString() : '0',
          Icons.local_fire_department,
          Colors.red,
          totalCalories > 0
              ? l10n.inPeriod(_selectedPeriod)
              : l10n.startBurningCalories,
        ),
        _buildStatCard(
          l10n.weightStatLabel,
          currentWeight != null
              ? '${currentWeight.toStringAsFixed(1)} kg'
              : '--',
          Icons.monitor_weight,
          Colors.green,
          periodWeightChange != null
              ? '${periodWeightChange > 0 ? '+' : ''}${periodWeightChange.toStringAsFixed(1)} kg ${l10n.inPeriod(_selectedPeriod)}'
              : l10n.addMeasurementsHint,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildWeightChart() {
    final measurementProvider = Provider.of<BodyMeasurementProvider>(context);
    final days = _selectedPeriod == 'Semana'
        ? 7
        : _selectedPeriod == 'Mes'
            ? 30
            : _selectedPeriod == 'Año'
                ? 365
                : 10000; // "Todo" = 10000 días (~27 años)

    final measurements = measurementProvider.getMeasurementsByPeriod(days);

    // Filtrar solo medidas con peso
    final weightData =
        measurements.where((m) => m.weight != null).toList().reversed.toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                weightData.isEmpty
                    ? AppL10n.of(context).recentActivityLabel
                    : AppL10n.of(context).weightProgressLabel,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Icon(
                weightData.isEmpty ? Icons.bar_chart : Icons.show_chart,
                color: AppColors.primary,
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Gráfico real con fl_chart
          if (weightData.isEmpty)
            _buildSessionsFrequencyChart(days)
          else
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 5,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: AppColors.textSecondary.withOpacity(0.1),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}kg',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 &&
                              value.toInt() < weightData.length) {
                            final date = weightData[value.toInt()].date;
                            return Text(
                              '${date.day}/${date.month}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: (weightData.length - 1).toDouble(),
                  minY: weightData
                          .map((m) => m.weight!)
                          .reduce((a, b) => a < b ? a : b) -
                      5,
                  maxY: weightData
                          .map((m) => m.weight!)
                          .reduce((a, b) => a > b ? a : b) +
                      5,
                  lineBarsData: [
                    LineChartBarData(
                      spots: weightData
                          .asMap()
                          .entries
                          .map((entry) => FlSpot(
                                entry.key.toDouble(),
                                entry.value.weight!,
                              ))
                          .toList(),
                      isCurved: true,
                      color: AppColors.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: AppColors.primary,
                            strokeWidth: 2,
                            strokeColor: AppColors.cardBackground,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.primary.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSessionsFrequencyChart(int days) {
    final sessionProvider = Provider.of<WorkoutSessionProvider>(context);
    final now = DateTime.now();
    final cutoff =
        days >= 10000 ? DateTime(2000) : now.subtract(Duration(days: days));

    final periodSessions =
        sessionProvider.sessions.where((s) => s.date.isAfter(cutoff)).toList();

    // Decide grouping: day (week), week (month), month (year/all)
    final groupByDay = days <= 7;
    final groupByWeek = days > 7 && days <= 31;

    // Build frequency buckets
    List<MapEntry<String, int>> buckets;
    if (groupByDay) {
      // Last 7 days, one bucket per day
      buckets = List.generate(7, (i) {
        final d = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: 6 - i));
        final count = periodSessions.where((s) {
          final sd = s.date.toLocal();
          return sd.year == d.year && sd.month == d.month && sd.day == d.day;
        }).length;
        final label = ['L', 'M', 'X', 'J', 'V', 'S', 'D'][d.weekday - 1];
        return MapEntry(label, count);
      });
    } else if (groupByWeek) {
      // Last 4-5 weeks
      const weekCount = 5;
      buckets = List.generate(weekCount, (i) {
        final weekStart = DateTime(now.year, now.month, now.day).subtract(
            Duration(days: (weekCount - 1 - i) * 7 + now.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        final count = periodSessions.where((s) {
          final sd = DateTime(s.date.toLocal().year, s.date.toLocal().month,
              s.date.toLocal().day);
          return !sd.isBefore(weekStart) && !sd.isAfter(weekEnd);
        }).length;
        return MapEntry('S${i + 1}', count);
      });
    } else {
      // Last 12 months
      buckets = List.generate(12, (i) {
        final month = DateTime(now.year, now.month - 11 + i);
        final count = periodSessions.where((s) {
          final sd = s.date.toLocal();
          return sd.year == month.year && sd.month == month.month;
        }).length;
        final labels = [
          'Ene',
          'Feb',
          'Mar',
          'Abr',
          'May',
          'Jun',
          'Jul',
          'Ago',
          'Sep',
          'Oct',
          'Nov',
          'Dic'
        ];
        return MapEntry(labels[(month.month - 1) % 12], count);
      });
    }

    final maxY = buckets.isEmpty
        ? 1.0
        : buckets
            .map((e) => e.value)
            .reduce((a, b) => a > b ? a : b)
            .toDouble();
    final hasAny = periodSessions.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.bar_chart,
                color: AppColors.primary.withOpacity(0.7), size: 16),
            const SizedBox(width: 6),
            Text(
              AppL10n.of(context).workoutFrequencyLabel,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary.withOpacity(0.8),
                fontStyle: FontStyle.italic,
              ),
            ),
            const Spacer(),
            Text(
              hasAny
                  ? AppL10n.of(context).sessionsCount(periodSessions.length)
                  : AppL10n.of(context).noData,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.primary.withOpacity(0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 160,
          child: hasAny
              ? BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: (maxY + 1).toDouble(),
                    barTouchData: BarTouchData(enabled: false),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 1,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: AppColors.textSecondary.withOpacity(0.08),
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= buckets.length) {
                              return const Text('');
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                buckets[idx].key,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    barGroups: List.generate(buckets.length, (i) {
                      final count = buckets[i].value;
                      return BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: count.toDouble(),
                            color: count > 0
                                ? AppColors.primary
                                : AppColors.primary.withOpacity(0.15),
                            width: groupByDay ? 20 : 14,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4)),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: maxY + 1,
                              color: AppColors.textSecondary.withOpacity(0.05),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.fitness_center,
                          size: 48,
                          color: AppColors.textSecondary.withOpacity(0.25)),
                      const SizedBox(height: 10),
                      Text(
                        AppL10n.of(context).completeWorkoutForStats,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary.withOpacity(0.5),
                          fontSize: 13,
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
