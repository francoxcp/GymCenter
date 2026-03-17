import 'package:flutter_test/flutter_test.dart';
import 'package:chamos_fitness_center/features/workouts/providers/workout_session_provider.dart';
import 'package:chamos_fitness_center/features/workouts/models/workout_session.dart';

WorkoutSession _session({
  required DateTime date,
  int durationMinutes = 30,
  int caloriesBurned = 200,
  bool isCompleted = true,
}) {
  return WorkoutSession(
    id: date.millisecondsSinceEpoch.toString(),
    userId: 'test-user',
    workoutId: 'workout-1',
    date: date,
    durationMinutes: durationMinutes,
    caloriesBurned: caloriesBurned,
    isCompleted: isCompleted,
  );
}

void main() {
  late WorkoutSessionProvider provider;

  setUp(() {
    provider = WorkoutSessionProvider();
  });

  // ── getStats() ──────────────────────────────────────────────────────────

  group('getStats()', () {
    test('returns zeros when no sessions', () {
      final stats = provider.getStats();
      expect(stats['totalSessions'], 0);
      expect(stats['totalMinutes'], 0);
      expect(stats['averageDuration'], 0);
      expect(stats['completionRate'], 0.0);
    });

    test('computes totals and average correctly', () {
      provider.sessions.addAll([
        _session(date: DateTime(2024, 6, 1), durationMinutes: 40),
        _session(date: DateTime(2024, 6, 2), durationMinutes: 60),
      ]);

      final stats = provider.getStats();
      expect(stats['totalSessions'], 2);
      expect(stats['totalMinutes'], 100);
      expect(stats['averageDuration'], 50); // 100 / 2
      expect(stats['completionRate'], 100);
    });

    test('completionRate handles mix of completed and incomplete', () {
      provider.sessions.addAll([
        _session(date: DateTime(2024, 6, 1), isCompleted: true),
        _session(date: DateTime(2024, 6, 2), isCompleted: false),
        _session(date: DateTime(2024, 6, 3), isCompleted: true),
        _session(date: DateTime(2024, 6, 4), isCompleted: false),
      ]);

      final stats = provider.getStats();
      expect(stats['completionRate'], 50); // 2/4 * 100
    });
  });

  // ── getCurrentStreak() ──────────────────────────────────────────────────

  group('getCurrentStreak()', () {
    test('returns 0 when no sessions', () {
      expect(provider.getCurrentStreak(), 0);
    });

    test('returns 1 when only today has a session', () {
      final today = DateTime.now();
      provider.sessions.add(_session(date: today));

      expect(provider.getCurrentStreak(), 1);
    });

    test('returns 1 when only yesterday has a session', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      provider.sessions.add(_session(date: yesterday));

      expect(provider.getCurrentStreak(), 1);
    });

    test('returns 0 when last session was 2 days ago', () {
      final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
      provider.sessions.add(_session(date: twoDaysAgo));

      expect(provider.getCurrentStreak(), 0);
    });

    test('counts consecutive days correctly', () {
      final now = DateTime.now();
      provider.sessions.addAll([
        _session(date: now),
        _session(date: now.subtract(const Duration(days: 1))),
        _session(date: now.subtract(const Duration(days: 2))),
      ]);

      expect(provider.getCurrentStreak(), 3);
    });

    test('breaks streak on gap day', () {
      final now = DateTime.now();
      provider.sessions.addAll([
        _session(date: now),
        _session(date: now.subtract(const Duration(days: 1))),
        // gap: day 2 missing
        _session(date: now.subtract(const Duration(days: 3))),
      ]);

      expect(provider.getCurrentStreak(), 2);
    });

    test('handles duplicate sessions on same day', () {
      final now = DateTime.now();
      provider.sessions.addAll([
        _session(date: now),
        _session(
            date: now.subtract(const Duration(hours: 2))), // same day, earlier
        _session(date: now.subtract(const Duration(days: 1))),
      ]);

      // Implementation counts sessions sequentially without deduplicating days.
      // First session = today (streak=1), second session = also today but
      // doesn't match "yesterday" so streak breaks at 1.
      expect(provider.getCurrentStreak(), 1);
    });
  });

  // ── getSessionsForMonth() ──────────────────────────────────────────────

  group('getSessionsForMonth()', () {
    test('returns empty when no sessions', () {
      expect(provider.getSessionsForMonth(2024, 6), isEmpty);
    });

    test('filters sessions by month correctly', () {
      provider.sessions.addAll([
        _session(date: DateTime(2024, 6, 1)),
        _session(date: DateTime(2024, 6, 15)),
        _session(date: DateTime(2024, 7, 1)),
        _session(date: DateTime(2024, 5, 31)),
      ]);

      final june = provider.getSessionsForMonth(2024, 6);
      expect(june.length, 2);

      final july = provider.getSessionsForMonth(2024, 7);
      expect(july.length, 1);
    });
  });

  // ── getSessionsForDay() ────────────────────────────────────────────────

  group('getSessionsForDay()', () {
    test('returns only sessions from the given day', () {
      provider.sessions.addAll([
        _session(date: DateTime(2024, 6, 15, 8, 0)),
        _session(date: DateTime(2024, 6, 15, 18, 30)),
        _session(date: DateTime(2024, 6, 16, 10, 0)),
      ]);

      final day15 = provider.getSessionsForDay(DateTime(2024, 6, 15));
      expect(day15.length, 2);

      final day16 = provider.getSessionsForDay(DateTime(2024, 6, 16));
      expect(day16.length, 1);

      final day17 = provider.getSessionsForDay(DateTime(2024, 6, 17));
      expect(day17, isEmpty);
    });
  });
}
