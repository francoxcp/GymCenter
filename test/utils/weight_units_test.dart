import 'package:flutter_test/flutter_test.dart';
import 'package:gymlab/core/utils/weight_units.dart';
import 'package:gymlab/features/workouts/models/exercise.dart';
import 'package:gymlab/features/workouts/services/progression_engine.dart';

void main() {
  group('WeightUnit', () {
    test('parse: kg o lbs por defecto', () {
      expect(WeightUnit.parse('kg'), WeightUnit.kg);
      expect(WeightUnit.parse('KG'), WeightUnit.kg);
      expect(WeightUnit.parse('lbs'), WeightUnit.lbs);
      expect(WeightUnit.parse(null), WeightUnit.lbs);
    });

    test('convierte y formatea', () {
      expect(WeightUnit.kg.toKg(45), 45);
      expect(WeightUnit.lbs.toKg(100), closeTo(45.36, 0.01));
      expect(WeightUnit.kg.formatKg(45), '45 kg');
      expect(WeightUnit.lbs.formatKg(9.07), '20 lbs');
      expect(WeightUnit.kg.format(22.5), '22.5 kg');
    });

    test('redondeo a discos', () {
      expect(WeightUnit.kg.roundToPlates(46.1), 46.25);
      expect(WeightUnit.lbs.roundToPlates(103.4), 102.5);
    });
  });

  group('Exercise con unidad', () {
    test('un ejercicio en kg muestra y guarda en kg', () {
      final e = Exercise.fromJson({
        'id': '1',
        'name': 'Press inclinado',
        'sets': 4,
        'reps': '12',
        'muscle_group': 'Pecho',
        'weight_kg': 45,
        'weight_unit': 'kg',
      });
      expect(e.weightUnit, WeightUnit.kg);
      expect(e.weight, 45);
      expect(e.weightKgForDb, 45);
      expect(e.weightLabel, '45 kg');
    });

    test('sin weight_unit se asume lbs (datos anteriores)', () {
      final e = Exercise.fromJson({
        'id': '1',
        'name': 'Laterales',
        'sets': 4,
        'reps': '12',
        'muscle_group': 'Hombros',
        'weight_kg': 9.07,
      });
      expect(e.weightUnit, WeightUnit.lbs);
      expect(e.weight, closeTo(20, 0.1));
    });

    test('la caché local conserva la unidad', () {
      final e = Exercise(
          id: '1',
          name: 'Prensa',
          sets: 4,
          reps: 12,
          muscleGroup: 'Piernas',
          weight: 100,
          weightUnit: WeightUnit.kg);
      final back = Exercise.fromJson(e.toJson());
      expect(back.weightUnit, WeightUnit.kg);
      expect(back.weight, 100);
      expect(back.weightKg, 100);
    });
  });

  test('progresión en kg sube 2.5 kg (superior) y 5 kg (inferior)', () {
    final day = DateTime(2026, 11, 2, 18);
    final logs = [
      for (var i = 0; i < 3; i++)
        SetLog(
            setIndex: i,
            weightKg: 40,
            reps: 10,
            targetReps: 10,
            loggedAt: day.add(Duration(minutes: i))),
    ];
    final upper = ProgressionEngine.suggest(
        logs: logs,
        targetSets: 3,
        targetReps: 10,
        lowerBody: false,
        unit: WeightUnit.kg)!;
    expect(upper.suggestedWeightKg, closeTo(42.5, 0.001));
    final lower = ProgressionEngine.suggest(
        logs: logs,
        targetSets: 3,
        targetReps: 10,
        lowerBody: true,
        unit: WeightUnit.kg)!;
    expect(lower.suggestedWeightKg, closeTo(45, 0.001));
  });
}
