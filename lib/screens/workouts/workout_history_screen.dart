import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme/app_theme.dart';
import '../../models/workout_session.dart';
import 'package:intl/intl.dart';

class WorkoutHistoryScreen extends StatefulWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  State<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends State<WorkoutHistoryScreen> {
  List<WorkoutSession> _sessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);

    // TODO: Load from Supabase
    // final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // final sessions = await loadWorkoutSessions(authProvider.currentUser!.id);

    // Datos de ejemplo
    await Future.delayed(const Duration(seconds: 1));
    _sessions = _getExampleSessions();

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Historial de Entrenamientos'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _sessions.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadHistory,
                  color: AppColors.primary,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildStatsOverview(),
                      const SizedBox(height: 24),
                      const Text(
                        'Sesiones Recientes',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._buildGroupedSessions(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatsOverview() {
    final totalSessions = _sessions.length;
    final totalMinutes = _sessions.fold<int>(
      0,
      (sum, session) => sum + session.durationMinutes,
    );
    final completedThisWeek = _sessions.where((s) {
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      return s.date.isAfter(weekAgo);
    }).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.2),
            AppColors.cardBackground,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text(
            'Resumen General',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                Icons.fitness_center,
                totalSessions.toString(),
                'Entrenamientos',
                Colors.blue,
              ),
              _buildStatItem(
                Icons.access_time,
                '${(totalMinutes / 60).toStringAsFixed(1)}h',
                'Tiempo total',
                Colors.orange,
              ),
              _buildStatItem(
                Icons.calendar_today,
                completedThisWeek.toString(),
                'Esta semana',
                Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  List<Widget> _buildGroupedSessions() {
    final grouped = <String, List<WorkoutSession>>{};

    for (var session in _sessions) {
      final dateKey = DateFormat('yyyy-MM-dd').format(session.date);
      grouped.putIfAbsent(dateKey, () => []).add(session);
    }

    final widgets = <Widget>[];
    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    for (var dateKey in sortedDates) {
      final date = DateTime.parse(dateKey);
      final sessions = grouped[dateKey]!;

      widgets.add(_buildDateHeader(date));
      widgets.add(const SizedBox(height: 12));

      for (var session in sessions) {
        widgets.add(_buildSessionCard(session));
        widgets.add(const SizedBox(height: 12));
      }

      widgets.add(const SizedBox(height: 8));
    }

    return widgets;
  }

  Widget _buildDateHeader(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    String dateText;
    if (difference == 0) {
      dateText = 'Hoy';
    } else if (difference == 1) {
      dateText = 'Ayer';
    } else if (difference < 7) {
      dateText = 'Hace $difference días';
    } else {
      dateText = DateFormat('dd MMM yyyy', 'es').format(date);
    }

    return Text(
      dateText,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildSessionCard(WorkoutSession session) {
    final completionRate = session.exercisesCompleted.isEmpty
        ? 0.0
        : session.exercisesCompleted
                .where((e) => e.setsCompleted.contains(true))
                .length /
            session.exercisesCompleted.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: session.isCompleted
            ? Border.all(color: AppColors.primary.withOpacity(0.5))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.fitness_center,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Entrenamiento Completo', // TODO: Get workout name
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      DateFormat('HH:mm').format(session.date),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (session.isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Completado',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildSessionDetail(
                Icons.access_time,
                '${session.durationMinutes} min',
              ),
              const SizedBox(width: 20),
              _buildSessionDetail(
                Icons.repeat,
                '${session.exercisesCompleted.length} ejercicios',
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: completionRate,
              backgroundColor: AppColors.background,
              valueColor: AlwaysStoppedAnimation<Color>(
                completionRate == 1.0 ? Colors.green : AppColors.primary,
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(completionRate * 100).toStringAsFixed(0)}% completado',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionDetail(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 16),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 100,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 20),
            const Text(
              'Sin historial aún',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Completa tu primer entrenamiento\npara ver tu progreso aquí',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => context.go('/workouts'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Explorar entrenamientos',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<WorkoutSession> _getExampleSessions() {
    final now = DateTime.now();
    return [
      WorkoutSession(
        id: '1',
        userId: 'user1',
        workoutId: 'workout1',
        date: now.subtract(const Duration(hours: 2)),
        durationMinutes: 45,
        exercisesCompleted: [
          ExerciseProgress(
              exerciseId: 'ex1', setsCompleted: [true, true, true]),
          ExerciseProgress(
              exerciseId: 'ex2', setsCompleted: [true, true, true]),
          ExerciseProgress(
              exerciseId: 'ex3', setsCompleted: [true, true, false]),
        ],
        isCompleted: true,
      ),
      WorkoutSession(
        id: '2',
        userId: 'user1',
        workoutId: 'workout1',
        date: now.subtract(const Duration(days: 1)),
        durationMinutes: 38,
        exercisesCompleted: [
          ExerciseProgress(
              exerciseId: 'ex1', setsCompleted: [true, true, true]),
          ExerciseProgress(
              exerciseId: 'ex2', setsCompleted: [true, true, true]),
        ],
        isCompleted: true,
      ),
      WorkoutSession(
        id: '3',
        userId: 'user1',
        workoutId: 'workout2',
        date: now.subtract(const Duration(days: 3)),
        durationMinutes: 52,
        exercisesCompleted: [
          ExerciseProgress(
              exerciseId: 'ex4', setsCompleted: [true, true, true, true]),
          ExerciseProgress(
              exerciseId: 'ex5', setsCompleted: [true, true, true]),
        ],
        isCompleted: true,
      ),
    ];
  }
}
