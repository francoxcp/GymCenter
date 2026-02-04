import 'package:flutter_test/flutter_test.dart';
import 'package:chamos_fitness_center/models/workout_session.dart';

void main() {
  group('WorkoutSession Model Tests', () {
    test('fromJson creates WorkoutSession instance correctly', () {
      final json = {
        'id': '1',
        'userId': 'user123',
        'workoutId': 'workout456',
        'date': '2024-01-15T10:30:00.000Z',
        'durationMinutes': 45,
        'exercisesCompleted': [
          {
            'exerciseId': 'ex1',
            'setsCompleted': [true, true, false],
            'notes': 'Buena forma',
          },
          {
            'exerciseId': 'ex2',
            'setsCompleted': [true, true, true],
          },
        ],
        'isCompleted': true,
      };

      final session = WorkoutSession.fromJson(json);

      expect(session.id, '1');
      expect(session.userId, 'user123');
      expect(session.workoutId, 'workout456');
      expect(session.date.year, 2024);
      expect(session.durationMinutes, 45);
      expect(session.exercisesCompleted.length, 2);
      expect(session.exercisesCompleted[0].exerciseId, 'ex1');
      expect(session.exercisesCompleted[0].setsCompleted, [true, true, false]);
      expect(session.exercisesCompleted[0].notes, 'Buena forma');
      expect(session.exercisesCompleted[1].exerciseId, 'ex2');
      expect(session.isCompleted, true);
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': '1',
        'userId': 'user123',
        'workoutId': 'workout456',
        'date': '2024-01-15T10:30:00.000Z',
      };

      final session = WorkoutSession.fromJson(json);

      expect(session.id, '1');
      expect(session.userId, 'user123');
      expect(session.workoutId, 'workout456');
      expect(session.durationMinutes, 0); // default
      expect(session.exercisesCompleted, isEmpty); // default empty list
      expect(session.isCompleted, false); // default
    });

    test('toJson converts WorkoutSession to JSON correctly', () {
      final session = WorkoutSession(
        id: '1',
        userId: 'user123',
        workoutId: 'workout456',
        date: DateTime(2024, 1, 15, 10, 30),
        durationMinutes: 45,
        exercisesCompleted: [
          ExerciseProgress(
            exerciseId: 'ex1',
            setsCompleted: [true, true, false],
            notes: 'Buena forma',
          ),
        ],
        isCompleted: true,
      );

      final json = session.toJson();

      expect(json['id'], '1');
      expect(json['userId'], 'user123');
      expect(json['workoutId'], 'workout456');
      expect(json['date'], isNotEmpty);
      expect(json['durationMinutes'], 45);
      expect(json['exercisesCompleted'], isNotEmpty);
      expect(json['isCompleted'], true);
    });

    test('creates WorkoutSession with defaults', () {
      final session = WorkoutSession(
        id: '1',
        userId: 'user123',
        workoutId: 'workout456',
        date: DateTime.now(),
      );

      expect(session.id, '1');
      expect(session.userId, 'user123');
      expect(session.workoutId, 'workout456');
      expect(session.durationMinutes, 0);
      expect(session.exercisesCompleted, isEmpty);
      expect(session.isCompleted, false);
    });

    test('ExerciseProgress fromJson works correctly', () {
      final json = {
        'exerciseId': 'ex1',
        'setsCompleted': [true, true, false],
        'notes': 'Test notes',
      };

      final progress = ExerciseProgress.fromJson(json);

      expect(progress.exerciseId, 'ex1');
      expect(progress.setsCompleted, [true, true, false]);
      expect(progress.notes, 'Test notes');
    });

    test('ExerciseProgress handles missing notes', () {
      final json = {
        'exerciseId': 'ex1',
        'setsCompleted': [true, false],
      };

      final progress = ExerciseProgress.fromJson(json);

      expect(progress.exerciseId, 'ex1');
      expect(progress.setsCompleted, [true, false]);
      expect(progress.notes, isNull);
    });
  });
}
