import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/l10n/app_l10n.dart';
import '../providers/achievements_provider.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final provider = Provider.of<AchievementsProvider>(context, listen: false);
    await Future.wait([
      provider.loadAllAchievements(),
      provider.loadUnlockedAchievements(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final provider = Provider.of<AchievementsProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.recentAchievementsLabel),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        child: provider.isLoading && provider.allAchievements.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildHeader(provider),
                  const SizedBox(height: 24),
                  _buildAchievementsList(provider, l10n),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader(AchievementsProvider provider) {
    final l10n = AppL10n.of(context);
    final progress = provider.totalCount > 0
        ? provider.unlockedCount / provider.totalCount
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.withOpacity(0.3),
            AppColors.cardBackground,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.emoji_events, color: Colors.amber, size: 48),
          const SizedBox(height: 12),
          Text(
            '${provider.totalPoints}',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1,
            ),
          ),
          Text(
            l10n.totalPoints,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${provider.unlockedCount}/${provider.totalCount}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.unlockedLabel,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.background,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsList(AchievementsProvider provider, AppL10n l10n) {
    if (provider.allAchievements.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Text(
            l10n.achievementsUnlockHint,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return Column(
      children: provider.allAchievements.map((achievement) {
        final unlocked = provider.isUnlocked(achievement.code);
        final userAchievement = unlocked
            ? provider.unlockedAchievements.firstWhere(
                (ua) => ua.achievement?.code == achievement.code,
              )
            : null;

        return _buildAchievementCard(achievement, unlocked, userAchievement);
      }).toList(),
    );
  }

  Widget _buildAchievementCard(
    Achievement achievement,
    bool unlocked,
    UserAchievement? userAchievement,
  ) {
    final l10n = AppL10n.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: unlocked
            ? Border.all(color: Colors.amber.withOpacity(0.5), width: 1)
            : null,
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: unlocked
                  ? Colors.amber.withOpacity(0.2)
                  : AppColors.background,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                achievement.icon,
                style: TextStyle(
                  fontSize: 28,
                  color: unlocked ? null : Colors.grey,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: unlocked ? Colors.white : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  achievement.description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (unlocked && userAchievement != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(userAchievement.unlockedAt, l10n),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.amber.withOpacity(0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Points
          Column(
            children: [
              Text(
                '+${achievement.points}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: unlocked ? Colors.amber : AppColors.textSecondary,
                ),
              ),
              Text(
                l10n.isEn ? 'pts' : 'pts',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              if (unlocked)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child:
                      Icon(Icons.check_circle, color: Colors.amber, size: 20),
                )
              else
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Icon(Icons.lock_outline,
                      color: AppColors.textSecondary, size: 20),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date, AppL10n l10n) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 0) {
      return l10n.timeAgoLabel(diff.inDays, 0);
    }
    return l10n.timeAgoLabel(0, diff.inHours);
  }
}
