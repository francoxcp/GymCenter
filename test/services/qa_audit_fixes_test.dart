import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:gymlab/core/utils/uuid_v4.dart';
import 'package:gymlab/features/progress/widgets/sessions_time_section.dart';
import 'package:gymlab/features/workouts/models/workout_session.dart';
import 'package:gymlab/features/workouts/services/workout_result.dart';

WorkoutResult _result(int seconds) => WorkoutResult(
      durationSeconds: seconds,
      setsDone: 1,
      exercisesDone: 1,
      supersets: 0,
      volumeKg: 0,
      repsDone: 0,
      bestSet: null,
      met: 3,
      calories: 0,
    );

WorkoutSession _s(String id, String? name, int min) => WorkoutSession(
      id: 'x',
      userId: 'u',
      workoutId: id,
      workoutName: name,
      date: DateTime(2026, 11, 10),
      durationMinutes: min,
    );

void main() {
  group('uuidV4', () {
    test('formato v4 válido y distinto cada vez', () {
      final re = RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');
      final a = uuidV4(), b = uuidV4();
      expect(re.hasMatch(a), isTrue, reason: a);
      expect(a, isNot(b));
      expect(uuidV4(Random(1)), uuidV4(Random(1)));
    });
  });

  group('duración en minutos', () {
    test('redondea y un entreno corto cuenta como 1 minuto', () {
      expect(_result(0).durationMinutes, 0);
      expect(_result(40).durationMinutes, 1);
      expect(_result(89).durationMinutes, 1);
      expect(_result(90).durationMinutes, 2);
      expect(_result(1265).durationMinutes, 21);
    });
  });

  group('sesión de una rutina borrada', () {
    test('workout_id nulo no rompe y conserva el nombre', () {
      final s = WorkoutSession.fromJson({
        'id': 's1',
        'userId': 'u',
        'workoutId': null,
        'workoutName': 'Pierna',
        'date': '2026-11-10T10:00:00Z',
      });
      expect(s.workoutId, '');
      expect(s.workoutName, 'Pierna');
      expect(s.toJson()['workoutName'], 'Pierna');
    });

    test('totales por rutina separan rutinas borradas por nombre', () {
      final totals = totalsByRoutine([
        _s('w1', 'Pecho', 30),
        _s('w1', 'Pecho', 20),
        _s('', 'Pierna', 40),
        _s('', 'Espalda', 10),
      ], (_) => 0);
      expect(totals.length, 3);
      expect(totals.first.workoutId, 'w1');
      expect(totals.first.minutes, 50);
      expect(totals.map((t) => t.workoutId), contains('name:Pierna'));
    });
  });
}
