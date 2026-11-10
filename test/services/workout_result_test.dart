import 'package:flutter_test/flutter_test.dart';
import 'package:gymlab/features/workouts/models/exercise.dart';
import 'package:gymlab/features/workouts/services/calorie_estimator.dart';
import 'package:gymlab/features/workouts/services/workout_result.dart';
import 'package:gymlab/features/workouts/screens/today_workout_screen.dart' show TodayWorkoutTimer;
import 'package:gymlab/features/workouts/screens/workout_summary_screen.dart' show compactWeight;

Exercise ex(String n, {int sets = 3, int reps = 10, double lbs = 0, String? group, String muscle = 'Piernas'}) =>
    Exercise(id: n, name: n, sets: sets, reps: reps, weight: lbs, muscleGroup: muscle, supersetGroup: group);

void main() {
  group('MET según cómo se entrenó', () {
    test('descansos largos → 3,5; ritmo alto → 6,0', () {
      expect(CalorieEstimator.metForSession(setsDone: 10, minutes: 60), 3.5);
      expect(CalorieEstimator.metForSession(setsDone: 30, minutes: 60), 6.0);
      final mid = CalorieEstimator.metForSession(setsDone: 20, minutes: 60);
      expect(mid, greaterThan(3.5));
      expect(mid, lessThan(6.0));
    });

    test('superseries suben el MET y nunca pasa de 6 en pesas', () {
      final normal = CalorieEstimator.metForSession(setsDone: 15, minutes: 50);
      final ss = CalorieEstimator.metForSession(setsDone: 15, minutes: 50, supersetRatio: 1);
      expect(ss, normal + 0.5);
      expect(CalorieEstimator.metForSession(setsDone: 40, minutes: 50, supersetRatio: 1), 6.0);
    });

    test('cardio mezcla hacia 8,0', () {
      expect(CalorieEstimator.metForSession(setsDone: 10, minutes: 60, cardioRatio: 1), 8.0);
    });

    test('calorías por segundos: 60 min a MET 5 ≈ BMR/1440 × 5 × 60', () {
      final kcal = CalorieEstimator.estimateSession(
          seconds: 3600, met: 5, weightKg: 70, heightCm: 170, age: 30, sex: 'male');
      // BMR = 700 + 1062,5 − 150 + 5 = 1617,5 → 1617,5/1440 × 300 = 337
      expect(kcal, 337);
    });
  });

  group('Resultado del entreno', () {
    final exercises = [
      ex('Prensa', sets: 2, reps: 15, lbs: 180),
      ex('Sissy', sets: 2, reps: 15, group: 'g'),
      ex('Saltos', sets: 2, reps: 10, group: 'g'),
    ];

    WorkoutResult run({Map<int, Map<int, double?>> w = const {}, Map<int, Map<int, int>> r = const {}}) =>
        WorkoutResult.compute(
          exercises: exercises,
          completed: [
            [true, true],
            [true, false],
            [false, false],
          ],
          weightsKg: w,
          reps: r,
          durationSeconds: 1265,
          isCardio: (e) => e.name == 'Saltos',
          bodyWeightKg: 70,
        );

    test('cuenta solo lo hecho, con reps reales', () {
      final res = run(r: {0: {1: 12}});
      expect(res.setsDone, 3);
      expect(res.exercisesDone, 2);
      expect(res.repsDone, 15 + 12 + 15);
      expect(res.supersets, 1);
    });

    test('volumen con peso anotado o el del entrenador, sin inventar', () {
      final res = run(w: {0: {0: 100}});
      // Serie 1: 100 kg × 15; serie 2: 180 lbs (81,65 kg) × 15; Sissy sin peso
      expect(res.volumeKg, closeTo(100 * 15 + 180 / 2.20462 * 15, 0.01));
      expect(res.bestSet!.exercise, 'Prensa');
      expect(res.bestSet!.weightKg, 100);
    });

    test('duración exacta y reloj', () {
      final res = run();
      expect(res.durationSeconds, 1265);
      expect(res.durationMinutes, 21);
      expect(WorkoutResult.clock(1265), '21:05');
      expect(WorkoutResult.clock(3909), '1:05:09');
      expect(res.calories, greaterThan(0));
    });
  });

  group('Cronómetro fuera de la app', () {
    final now = DateTime(2026, 11, 10, 18, 0);
    String saved(int acc, DateTime at, bool running) =>
        '{"acc":$acc,"at":${at.millisecondsSinceEpoch},"running":$running}';

    test('corriendo: suma el tiempo que estuvo fuera', () {
      expect(
          TodayWorkoutTimer.saved(
              saved(600, now.subtract(const Duration(minutes: 5)), true), now),
          900);
    });

    test('en pausa: no suma', () {
      expect(
          TodayWorkoutTimer.saved(
              saved(600, now.subtract(const Duration(hours: 2)), false), now),
          600);
    });

    test('tope de 3 horas fuera y formato anterior (int)', () {
      expect(
          TodayWorkoutTimer.saved(
              saved(0, now.subtract(const Duration(days: 1)), true), now),
          3 * 3600);
      expect(TodayWorkoutTimer.saved(420, now), 420);
      expect(TodayWorkoutTimer.saved(null, now), 0);
    });
  });

  group('Descanso al volver a la app', () {
    final now = DateTime(2026, 11, 10, 18, 0);
    String saved({required DateTime at, DateTime? restEnd}) =>
        '{"acc":300,"at":${at.millisecondsSinceEpoch},"running":true'
        '${restEnd != null ? ',"restEnd":${restEnd.millisecondsSinceEpoch}' : ''}}';

    test('si falta descanso, se retoma con la hora de fin', () {
      final end = now.add(const Duration(seconds: 47));
      expect(TodayWorkoutTimer.restEnd(saved(at: now, restEnd: end), now), end);
    });

    test('si ya terminó o no había, no hay descanso', () {
      expect(
          TodayWorkoutTimer.restEnd(
              saved(at: now, restEnd: now.subtract(const Duration(seconds: 1))), now),
          isNull);
      expect(TodayWorkoutTimer.restEnd(saved(at: now), now), isNull);
    });

    test('sesión guardada hace más de 3 h no se retoma', () {
      expect(TodayWorkoutTimer.recent(saved(at: now.subtract(const Duration(minutes: 20))), now), isTrue);
      expect(TodayWorkoutTimer.recent(saved(at: now.subtract(const Duration(hours: 4))), now), isFalse);
    });
  });

  test('volumen corto en las tarjetas del resumen', () {
    expect(compactWeight(17618 / 2.20462, 'imperial'), '17.6k');
    expect(compactWeight(400, 'imperial'), '882');
    expect(compactWeight(400, 'metric'), '400');
  });
}
