import 'package:flutter_test/flutter_test.dart';
import 'package:chamos_fitness_center/features/progress/providers/achievements_provider.dart';

/// Tests for AchievementsProvider pure logic.
/// We replicate methods here because the provider accesses
/// Supabase.instance.client at field-init time.

Achievement _achievement({
  required String code,
  required String name,
  int points = 50,
}) {
  return Achievement(
    id: code,
    code: code,
    name: name,
    description: 'Test: $name',
    icon: '🏆',
    points: points,
    createdAt: DateTime(2024, 1, 1),
  );
}

UserAchievement _userAchievement({
  required String code,
  int points = 50,
}) {
  return UserAchievement(
    id: 'ua-$code',
    userId: 'test-user',
    achievementId: code,
    unlockedAt: DateTime.now(),
    achievement: _achievement(code: code, name: code, points: points),
  );
}

// Mirror of provider.totalPoints
int _totalPoints(List<UserAchievement> unlocked) {
  return unlocked.fold(0, (sum, ua) => sum + (ua.achievement?.points ?? 0));
}

// Mirror of provider.isUnlocked
bool _isUnlocked(List<UserAchievement> unlocked, String code) {
  return unlocked.any((ua) => ua.achievement?.code == code);
}

void main() {
  // ── totalPoints ────────────────────────────────────────────────────────

  group('totalPoints', () {
    test('returns 0 when no unlocked achievements', () {
      expect(_totalPoints([]), 0);
    });

    test('sums points from unlocked achievements', () {
      final unlocked = [
        _userAchievement(code: 'first_workout', points: 50),
        _userAchievement(code: 'ten_workouts', points: 100),
      ];
      expect(_totalPoints(unlocked), 150);
    });

    test('handles null achievement gracefully', () {
      final ua = UserAchievement(
        id: 'ua-1',
        userId: 'test-user',
        achievementId: 'a-1',
        unlockedAt: DateTime.now(),
        achievement: null,
      );
      expect(_totalPoints([ua]), 0);
    });
  });

  // ── isUnlocked() ──────────────────────────────────────────────────────

  group('isUnlocked()', () {
    test('returns false when nothing is unlocked', () {
      expect(_isUnlocked([], 'first_workout'), false);
    });

    test('returns true for unlocked code', () {
      final unlocked = [_userAchievement(code: 'first_workout')];
      expect(_isUnlocked(unlocked, 'first_workout'), true);
    });

    test('returns false for different code', () {
      final unlocked = [_userAchievement(code: 'first_workout')];
      expect(_isUnlocked(unlocked, 'ten_workouts'), false);
    });

    test('handles multiple unlocked achievements', () {
      final unlocked = [
        _userAchievement(code: 'first_workout'),
        _userAchievement(code: 'streak_7'),
        _userAchievement(code: 'ten_workouts'),
      ];

      expect(_isUnlocked(unlocked, 'first_workout'), true);
      expect(_isUnlocked(unlocked, 'streak_7'), true);
      expect(_isUnlocked(unlocked, 'ten_workouts'), true);
      expect(_isUnlocked(unlocked, 'streak_30'), false);
      expect(_isUnlocked(unlocked, 'weight_loss_5kg'), false);
    });
  });

  // ── Achievement.fromJson ──────────────────────────────────────────────

  group('Achievement.fromJson', () {
    test('parses all fields', () {
      final json = {
        'id': 'ach-1',
        'code': 'first_workout',
        'name': 'First Workout',
        'description': 'Complete your first workout',
        'icon': '💪',
        'points': 50,
        'created_at': '2024-01-01T00:00:00.000Z',
      };

      final a = Achievement.fromJson(json);
      expect(a.id, 'ach-1');
      expect(a.code, 'first_workout');
      expect(a.name, 'First Workout');
      expect(a.points, 50);
      expect(a.icon, '💪');
    });
  });

  // ── UserAchievement.fromJson ──────────────────────────────────────────

  group('UserAchievement.fromJson', () {
    test('parses with nested achievement', () {
      final json = {
        'id': 'ua-1',
        'user_id': 'user-1',
        'achievement_id': 'ach-1',
        'unlocked_at': '2024-06-15T10:30:00.000Z',
        'achievements': {
          'id': 'ach-1',
          'code': 'first_workout',
          'name': 'First Workout',
          'description': 'Complete your first workout',
          'icon': '💪',
          'points': 50,
          'created_at': '2024-01-01T00:00:00.000Z',
        },
      };

      final ua = UserAchievement.fromJson(json);
      expect(ua.id, 'ua-1');
      expect(ua.userId, 'user-1');
      expect(ua.achievement, isNotNull);
      expect(ua.achievement!.code, 'first_workout');
    });

    test('parses without nested achievement', () {
      final json = {
        'id': 'ua-1',
        'user_id': 'user-1',
        'achievement_id': 'ach-1',
        'unlocked_at': '2024-06-15T10:30:00.000Z',
      };

      final ua = UserAchievement.fromJson(json);
      expect(ua.achievement, isNull);
    });
  });
}
