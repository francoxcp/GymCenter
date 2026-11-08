import 'package:flutter_test/flutter_test.dart';
import 'package:chamos_fitness_center/features/workouts/services/workout_completion.dart';

void main() {
  group('WorkoutCompletion.pending', () {
    test('todo hecho y con peso → sin pendientes', () {
      final p = WorkoutCompletion.pending(
        names: ['Press', 'Sentadilla'],
        completed: [
          [true, true],
          [true, true, true],
        ],
        weights: {
          0: {0: 40, 1: 40},
          1: {0: 60, 1: 60, 2: 60},
        },
        weightRequired: [true, true],
      );
      expect(p, isEmpty);
    });

    test('series sin marcar y sin peso se reportan por separado', () {
      final p = WorkoutCompletion.pending(
        names: ['Press', 'Sentadilla'],
        completed: [
          [true, false],
          [true, true],
        ],
        weights: {
          0: {0: 40},
          1: {0: 60, 1: null},
        },
        weightRequired: [true, true],
      );
      expect(p.length, 2);
      expect(p[0].unfinishedSets, [2]);
      expect(p[0].setsWithoutWeight, isEmpty);
      expect(p[1].setsWithoutWeight, [2]);
      expect(WorkoutCompletion.totalMissing(p), 2);
    });

    test('peso corporal (0) cuenta como registrado', () {
      final p = WorkoutCompletion.pending(
        names: ['Flexiones'],
        completed: [
          [true, true],
        ],
        weights: {
          0: {0: 0, 1: 0},
        },
        weightRequired: [true],
      );
      expect(p, isEmpty);
    });

    test('cardio no exige peso', () {
      final p = WorkoutCompletion.pending(
        names: ['Bicicleta'],
        completed: [
          [true],
        ],
        weights: {},
        weightRequired: [false],
      );
      expect(p, isEmpty);
    });
  });
}
