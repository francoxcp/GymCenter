import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/l10n/app_l10n.dart';
import '../models/workout_session.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/workout_session_provider.dart';
import '../../../shared/widgets/shimmer_loading.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHistory();
    });
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final sessionProvider =
        Provider.of<WorkoutSessionProvider>(context, listen: false);

    if (authProvider.currentUser != null) {
      await sessionProvider.loadSessions(
        authProvider.currentUser!.id,
        forceRefresh: true,
      );
      if (!mounted) return;
      setState(() {
        _sessions = sessionProvider.sessions;
      });
    } else {
      setState(() => _sessions = []);
    }

    if (!mounted) return;
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
        title: Text(AppL10n.of(context).workoutHistory),
      ),
      body: _isLoading
          ? ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: 8,
              itemBuilder: (context, index) => const ShimmerListTile(),
            )
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
                      Text(
                        AppL10n.of(context).recentSessions,
                        style: const TextStyle(
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
            AppColors.primary.withValues(alpha: 0.2),
            AppColors.cardBackground,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            AppL10n.of(context).generalSummary,
            style: const TextStyle(
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
                AppL10n.of(context).totalWorkoutsLabel,
                Colors.blue,
              ),
              _buildStatItem(
                Icons.access_time,
                '${(totalMinutes / 60).toStringAsFixed(1)}h',
                AppL10n.of(context).totalTimeLabel,
                Colors.orange,
              ),
              _buildStatItem(
                Icons.calendar_today,
                completedThisWeek.toString(),
                AppL10n.of(context).thisWeek,
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
            color: color.withValues(alpha: 0.2),
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

    final l10n = AppL10n.of(context);
    String dateText;
    if (difference == 0) {
      dateText = l10n.todayLabel;
    } else if (difference == 1) {
      dateText = l10n.yesterdayLabel;
    } else if (difference < 7) {
      dateText = l10n.daysAgoLabel(difference);
    } else {
      dateText = '${date.day}/${date.month}/${date.year}';
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
    final totalSets = session.exercisesCompleted
        .fold<int>(0, (sum, e) => sum + e.setsCompleted.length);
    final doneSets = session.exercisesCompleted
        .fold<int>(0, (sum, e) => sum + e.setsCompleted.where((b) => b).length);
    final completionRate = totalSets == 0
        ? (session.isCompleted ? 1.0 : 0.0)
        : doneSets / totalSets;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: session.isCompleted
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.5))
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
                  color: AppColors.primary.withValues(alpha: 0.2),
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
                    Text(
                      AppL10n.of(context).completeWorkoutLabel,
                      style: const TextStyle(
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
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: Colors.green, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        AppL10n.of(context).completedLabel,
                        style: const TextStyle(
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
                AppL10n.of(context)
                    .exercisesCount(session.exercisesCompleted.length),
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
                completionRate >= 1.0
                    ? Colors.green
                    : completionRate >= 0.6
                        ? Colors.orange
                        : AppColors.primary,
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            totalSets > 0
                ? '$doneSets/$totalSets series � ${(completionRate * 100).toInt()}% completado'
                : AppL10n.of(context)
                    .percentCompleted((completionRate * 100).toInt()),
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
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 20),
            Text(
              AppL10n.of(context).noHistoryYet,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              AppL10n.of(context).noHistoryBody,
              style: const TextStyle(
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
              child: Text(
                AppL10n.of(context).exploreWorkouts,
                style: const TextStyle(
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
}
