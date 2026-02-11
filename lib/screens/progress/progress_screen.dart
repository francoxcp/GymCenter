import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../config/theme/app_theme.dart';
import '../../providers/body_measurement_provider.dart';
import '../../providers/achievements_provider.dart';
import '../../providers/workout_session_provider.dart';
import '../../providers/user_provider.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  String _selectedPeriod = 'Mes';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final measurementProvider =
          Provider.of<BodyMeasurementProvider>(context, listen: false);
      final sessionProvider =
          Provider.of<WorkoutSessionProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      measurementProvider.loadMeasurements();
      if (userProvider.currentUser?.id != null) {
        sessionProvider.loadSessions(userProvider.currentUser!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
            tooltip: 'Ajustes',
          ),
        ],
      ),
      body: ListView(
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
          const SizedBox(height: 24),

          // Logros recientes
          _buildRecentAchievements(),
          const SizedBox(height: 24),

          // Botón para medidas corporales
          _buildBodyMeasurementsButton(),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    final periods = ['Semana', 'Mes', 'Año', 'Todo'];

    return Row(
      children: periods.map((period) {
        final isSelected = _selectedPeriod == period;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedPeriod = period),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color:
                    isSelected ? AppColors.primary : AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                period,
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
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.local_fire_department, color: Colors.orange, size: 40),
              SizedBox(width: 12),
              Text(
                'Racha Actual',
                style: TextStyle(
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
            currentStreak == 1 ? 'día consecutivo' : 'días consecutivos',
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            currentStreak == 0
                ? 'Comienza tu racha hoy 💪'
                : currentStreak < 7
                    ? '¡Sigue así! 🎉'
                    : currentStreak < 30
                        ? '¡Increíble racha! 🔥'
                        : '¡Eres imparable! 🏆',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.orange,
              fontWeight: FontWeight.bold,
            ),
          ),
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
                : 10000;

    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    final periodSessions = sessionProvider.sessions
        .where((s) => s.date.isAfter(cutoffDate))
        .toList();

    final totalWorkouts = periodSessions.length;
    final totalMinutes =
        periodSessions.fold<int>(0, (sum, s) => sum + s.durationMinutes);
    final totalHours = (totalMinutes / 60).toStringAsFixed(1);

    // Calcular calorías (estimado: 5 cal/min)
    final totalCalories = totalMinutes * 5;

    // Obtener peso actual y cambio de peso
    final currentWeight = measurementProvider.latestMeasurement?.weight;
    final firstMeasurement = measurementProvider.measurements.isNotEmpty
        ? measurementProvider.measurements.last.weight
        : null;
    final totalWeightChange = currentWeight != null && firstMeasurement != null
        ? currentWeight - firstMeasurement
        : null;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: [
        _buildStatCard(
          'Entrenamientos',
          '$totalWorkouts',
          Icons.fitness_center,
          Colors.blue,
          totalWorkouts > 0
              ? 'en ${_selectedPeriod.toLowerCase()}'
              : 'Comienza tu primer entrenamiento',
        ),
        _buildStatCard(
          'Tiempo Total',
          totalMinutes > 0 ? '${totalHours}h' : '0h',
          Icons.access_time,
          Colors.orange,
          totalMinutes > 0
              ? 'en ${_selectedPeriod.toLowerCase()}'
              : 'Aún no has entrenado',
        ),
        _buildStatCard(
          'Calorías',
          totalCalories > 0 ? totalCalories.toString() : '0',
          Icons.local_fire_department,
          Colors.red,
          totalCalories > 0
              ? 'quemadas en ${_selectedPeriod.toLowerCase()}'
              : 'Comienza a quemar calorías',
        ),
        _buildStatCard(
          'Peso',
          currentWeight != null
              ? '${currentWeight.toStringAsFixed(1)} kg'
              : '--',
          Icons.monitor_weight,
          Colors.green,
          totalWeightChange != null
              ? '${totalWeightChange > 0 ? '+' : ''}${totalWeightChange.toStringAsFixed(1)} kg desde inicio'
              : 'Agrega medidas para seguimiento',
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
    final measurements = measurementProvider.getMeasurementsByPeriod(
      _selectedPeriod == 'Semana'
          ? 7
          : _selectedPeriod == 'Mes'
              ? 30
              : _selectedPeriod == 'Año'
                  ? 365
                  : 1000,
    );

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
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progreso de Peso',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Icon(Icons.show_chart, color: AppColors.primary, size: 24),
            ],
          ),
          const SizedBox(height: 20),
          // Gráfico real con fl_chart
          if (weightData.isEmpty)
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.insert_chart_outlined,
                      size: 60,
                      color: AppColors.textSecondary.withOpacity(0.3),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Agrega medidas para ver tu progreso',
                      style: TextStyle(
                        color: AppColors.textSecondary.withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
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

  Widget _buildRecentAchievements() {
    final achievementsProvider = Provider.of<AchievementsProvider>(context);
    final recentAchievements =
        achievementsProvider.unlockedAchievements.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Logros Recientes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              '${achievementsProvider.unlockedCount}/${achievementsProvider.totalCount}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (recentAchievements.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'Completa entrenamientos para desbloquear logros',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary.withOpacity(0.6),
                ),
              ),
            ),
          )
        else
          ...recentAchievements.map((userAchievement) {
            final achievement = userAchievement.achievement;
            if (achievement == null) return const SizedBox.shrink();

            // Determinar color e ícono según el código del logro
            Color color = AppColors.primary;
            IconData icon = Icons.emoji_events;

            if (achievement.code.contains('workout')) {
              color = Colors.blue;
              icon = Icons.fitness_center;
            } else if (achievement.code.contains('streak')) {
              color = Colors.orange;
              icon = Icons.local_fire_department;
            } else if (achievement.code.contains('week')) {
              color = Colors.yellow;
              icon = Icons.calendar_today;
            } else if (achievement.code.contains('weight')) {
              color = Colors.green;
              icon = Icons.trending_down;
            }

            // Calcular hace cuánto se desbloqueó
            final difference =
                DateTime.now().difference(userAchievement.unlockedAt);
            String timeAgo;
            if (difference.inDays > 0) {
              timeAgo =
                  'Hace ${difference.inDays} día${difference.inDays > 1 ? 's' : ''}';
            } else if (difference.inHours > 0) {
              timeAgo =
                  'Hace ${difference.inHours} hora${difference.inHours > 1 ? 's' : ''}';
            } else {
              timeAgo = 'Hace unos momentos';
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          achievement.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              timeAgo,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '• ${achievement.points} pts',
                              style: TextStyle(
                                fontSize: 12,
                                color: color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildBodyMeasurementsButton() {
    return GestureDetector(
      onTap: () => context.push('/body-measurements'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.straighten,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Medidas Corporales',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Registra y sigue tus medidas',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
