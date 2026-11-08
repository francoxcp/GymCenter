import 'package:flutter_test/flutter_test.dart';
import 'package:chamos_fitness_center/features/workouts/services/progression_engine.dart';

double lbs(double v) => v / kKgToLbs;

List<SetLog> session(DateTime day, double weightLbs, List<int> reps,
    {List<bool>? completed, int target = 10}) {
  return [
    for (var i = 0; i < reps.length; i++)
      SetLog(
        setIndex: i,
        weightKg: lbs(weightLbs),
        reps: reps[i],
        targetReps: target,
        completed: completed?[i] ?? true,
        loggedAt: day.add(Duration(minutes: i)),
      ),
  ];
}

void main() {
  final d1 = DateTime(2026, 11, 2, 18);
  final d2 = DateTime(2026, 11, 5, 18);

  group('ProgressionEngine.suggest', () {
    test('sin historial devuelve null', () {
      expect(
        ProgressionEngine.suggest(
            logs: const [], targetSets: 3, targetReps: 10, lowerBody: false),
        isNull,
      );
    });

    test('todas las series completas → sube 5 lbs (tren superior)', () {
      final s = ProgressionEngine.suggest(
        logs: session(d2, 100, [10, 10, 10]),
        targetSets: 3,
        targetReps: 10,
        lowerBody: false,
      )!;
      expect(s.action, ProgressionAction.increase);
      expect(s.suggestedWeightLbs, closeTo(105, 0.01));
    });

    test('tren inferior sube 10 lbs', () {
      final s = ProgressionEngine.suggest(
        logs: session(d2, 200, [8, 8, 8], target: 8),
        targetSets: 3,
        targetReps: 8,
        lowerBody: true,
      )!;
      expect(s.action, ProgressionAction.increase);
      expect(s.suggestedWeightLbs, closeTo(210, 0.01));
    });

    test('faltaron reps → mantener peso', () {
      final s = ProgressionEngine.suggest(
        logs: session(d2, 100, [10, 9, 7]),
        targetSets: 3,
        targetReps: 10,
        lowerBody: false,
      )!;
      expect(s.action, ProgressionAction.maintain);
      expect(s.suggestedWeightLbs, closeTo(100, 0.01));
      expect(s.lastCompletedSets, 1);
    });

    test('serie sin completar → mantener', () {
      final s = ProgressionEngine.suggest(
        logs: session(d2, 100, [10, 10, 10], completed: [true, true, false]),
        targetSets: 3,
        targetReps: 10,
        lowerBody: false,
      )!;
      expect(s.action, ProgressionAction.maintain);
    });

    test('dos fallos seguidos con el mismo peso → descarga ~10%', () {
      final s = ProgressionEngine.suggest(
        logs: [
          ...session(d1, 100, [10, 8, 7]),
          ...session(d2, 100, [10, 9, 6]),
        ],
        targetSets: 3,
        targetReps: 10,
        lowerBody: false,
      )!;
      expect(s.action, ProgressionAction.deload);
      expect(s.suggestedWeightLbs, closeTo(90, 0.01));
    });

    test('fallo después de subir de peso → mantener, no descarga', () {
      final s = ProgressionEngine.suggest(
        logs: [
          ...session(d1, 100, [10, 10, 10]),
          ...session(d2, 105, [10, 9, 8]),
        ],
        targetSets: 3,
        targetReps: 10,
        lowerBody: false,
      )!;
      expect(s.action, ProgressionAction.maintain);
      expect(s.suggestedWeightLbs, closeTo(105, 0.01));
    });

    test('registros antiguos sin reps reales ni "completed" cuentan como logrados',
        () {
      final logs = [
        for (var i = 0; i < 3; i++)
          SetLog(
              setIndex: i,
              weightKg: lbs(50),
              reps: null,
              loggedAt: d2.add(Duration(minutes: i))),
      ];
      final s = ProgressionEngine.suggest(
          logs: logs, targetSets: 3, targetReps: 12, lowerBody: false)!;
      expect(s.action, ProgressionAction.increase);
      expect(s.suggestedWeightLbs, closeTo(55, 0.01));
    });
  });

  group('groupSessions', () {
    test('agrupa por día y se queda con el registro más reciente por serie', () {
      final logs = [
        SetLog(setIndex: 0, weightKg: 40, reps: 10, loggedAt: d2),
        SetLog(
            setIndex: 0,
            weightKg: 45,
            reps: 10,
            loggedAt: d2.add(const Duration(hours: 1))),
        SetLog(setIndex: 0, weightKg: 35, reps: 10, loggedAt: d1),
      ];
      final sessions = ProgressionEngine.groupSessions(logs);
      expect(sessions.length, 2);
      expect(sessions.first.sets.single.weightKg, 45);
      expect(sessions.last.sets.single.weightKg, 35);
    });
  });

  group('utilidades', () {
    test('1RM estimado (Epley)', () {
      final s = SetLog(setIndex: 0, weightKg: 100, reps: 10, loggedAt: d1);
      expect(s.estimated1RmKg, closeTo(133.33, 0.01));
    });

    test('redondeo a 2.5 lbs', () {
      expect(ProgressionEngine.roundLbs(103.4), 102.5);
      expect(ProgressionEngine.roundLbs(104), 105);
    });

    test('detección de tren inferior', () {
      expect(ProgressionEngine.isLowerBody('Piernas', 'Prensa'), isTrue);
      expect(ProgressionEngine.isLowerBody('General', 'Sentadilla libre'), isTrue);
      expect(ProgressionEngine.isLowerBody('Pecho', 'Press banca'), isFalse);
    });
  });
}
