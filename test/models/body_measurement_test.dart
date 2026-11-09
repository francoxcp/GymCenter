import 'package:flutter_test/flutter_test.dart';
import 'package:gymlab/features/progress/models/body_measurement.dart';
import 'package:gymlab/features/workouts/services/calorie_estimator.dart';

void main() {
  group('BodyMeasurement', () {
    test('fromJson lee todas las medidas', () {
      final m = BodyMeasurement.fromJson({
        'id': '1',
        'user_id': 'u',
        'date': '2026-11-01T00:00:00',
        'weight': 80.5,
        'body_fat': 18,
        'waist': 85,
        'biceps_left': 35,
        'biceps_right': 35.5,
        'calf': 38,
        'recorded_by': 't',
      });
      expect(m.weight, 80.5);
      expect(m.bodyFat, 18.0);
      expect(m.valueOf(MeasureField.bicepsRight), 35.5);
      expect(m.valueOf(MeasureField.calf), 38.0);
      expect(m.valueOf(MeasureField.neck), isNull);
      expect(m.recordedBy, 't');
    });

    test('toJson no manda id vacío y usa las columnas nuevas', () {
      final m = BodyMeasurement.fromValues(
        userId: 'u',
        date: DateTime(2026, 11, 1),
        values: {MeasureField.weight: 79.0, MeasureField.thighLeft: 55.0},
      );
      final j = m.toJson();
      expect(j.containsKey('id'), isFalse);
      expect(j['thigh_left'], 55.0);
      expect(j.containsKey('biceps'), isFalse);
      expect(j.containsKey('height'), isFalse);
      expect(m.isEmpty, isFalse);
    });

    test('hay 12 medidas en 4 grupos', () {
      expect(MeasureField.values.length, 12);
      expect(MeasureField.groups, ['Cuerpo', 'Tronco', 'Brazos', 'Piernas']);
      expect(MeasureField.waist.lowerIsBetter, isTrue);
      expect(MeasureField.chest.lowerIsBetter, isFalse);
    });
  });

  group('CalorieEstimator', () {
    test('Mifflin-St Jeor', () {
      // Hombre 80 kg, 180 cm, 30 años: 10·80 + 6.25·180 − 5·30 + 5 = 1780
      expect(CalorieEstimator.bmr(weightKg: 80, heightCm: 180, age: 30, sex: 'male'), 1780);
      expect(CalorieEstimator.bmr(weightKg: 60, heightCm: 165, age: 30, sex: 'female'), 1320.25);
    });

    test('60 min de pesas ≈ 5 MET del gasto en reposo', () {
      // 1780/1440 × 5 × 60 = 370.8
      expect(
          CalorieEstimator.estimate(
              minutes: 60, weightKg: 80, heightCm: 180, age: 30, sex: 'male'),
          371);
      expect(CalorieEstimator.estimate(minutes: 0), 0);
    });

    test('más cardio, más calorías', () {
      final pesas = CalorieEstimator.estimate(minutes: 45);
      final cardio = CalorieEstimator.estimate(minutes: 45, cardioRatio: 1);
      expect(cardio, greaterThan(pesas));
    });
  });
}
