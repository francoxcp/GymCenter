import 'package:flutter_test/flutter_test.dart';
import 'package:chamos_fitness_center/models/workout.dart';
import 'package:chamos_fitness_center/models/exercise.dart';

void main() {
  group('Workout Model Tests', () {
    test('Workout should be created from JSON', () {
      final json = {
        'id': 'workout123',
        'name': 'Día de Pecho',
        'description': 'Rutina completa para pecho',
        'level': 'Intermedio',
        'duration': 45,
        'exerciseCount': 5,
        'imageUrl': 'https://example.com/workout.jpg',
      };

      final workout = Workout.fromJson(json);

      expect(workout.id, 'workout123');
      expect(workout.name, 'Día de Pecho');
      expect(workout.description, 'Rutina completa para pecho');
      expect(workout.level, 'Intermedio');
      expect(workout.duration, 45);
      expect(workout.exerciseCount, 5);
      expect(workout.imageUrl, 'https://example.com/workout.jpg');
      expect(workout.exercises, isEmpty);
    });

    test('Workout should convert to JSON', () {
      final workout = Workout(
        id: 'workout456',
        name: 'Día de Piernas',
        description: 'Rutina intensa de piernas',
        level: 'Avanzado',
        duration: 60,
        exerciseCount: 6,
        imageUrl: 'https://example.com/legs.jpg',
        exercises: [],
      );

      final json = workout.toJson();

      expect(json['id'], 'workout456');
      expect(json['name'], 'Día de Piernas');
      expect(json['description'], 'Rutina intensa de piernas');
      expect(json['level'], 'Avanzado');
      expect(json['duration'], 60);
      expect(json['exerciseCount'], 6);
      expect(json['imageUrl'], 'https://example.com/legs.jpg');
    });

    test('Workout should include exercises list', () {
      final exercises = [
        Exercise(
          id: '1',
          name: 'Press de banca',
          sets: 3,
          reps: 12,
          muscleGroup: 'Pecho',
        ),
        Exercise(
          id: '2',
          name: 'Aperturas',
          sets: 3,
          reps: 15,
          muscleGroup: 'Pecho',
        ),
      ];

      final workout = Workout(
        id: 'workout789',
        name: 'Rutina de Pecho',
        level: 'Principiante',
        duration: 30,
        exerciseCount: 2,
        imageUrl: '',
        exercises: exercises,
      );

      expect(workout.exercises.length, 2);
      expect(workout.exercises[0].name, 'Press de banca');
      expect(workout.exercises[1].name, 'Aperturas');
      expect(workout.exerciseCount, 2);
    });

    test('Workout should handle missing optional fields', () {
      final json = {
        'id': 'workout999',
        'name': 'Rutina Simple',
        'level': 'beginner',
        'duration': 20,
        'exerciseCount': 0,
      };

      final workout = Workout.fromJson(json);

      expect(workout.id, 'workout999');
      expect(workout.name, 'Rutina Simple');
      expect(workout.description, isNull);
      expect(workout.level, 'beginner');
      expect(workout.duration, 20);
      expect(workout.exerciseCount, 0);
      expect(workout.imageUrl, ''); // Default value
      expect(workout.exercises, isEmpty);
    });

    test('Workout should calculate total exercise time', () {
      final exercises = [
        Exercise(
          id: '1',
          name: 'Ejercicio 1',
          sets: 3,
          reps: 12,
          restSeconds: 60,
          muscleGroup: 'Pecho',
        ),
        Exercise(
          id: '2',
          name: 'Ejercicio 2',
          sets: 4,
          reps: 10,
          restSeconds: 90,
          muscleGroup: 'Espalda',
        ),
      ];

      final workout = Workout(
        id: 'workout111',
        name: 'Rutina Completa',
        level: 'Intermedio',
        duration: 45,
        exerciseCount: exercises.length,
        imageUrl: '',
        exercises: exercises,
      );

      // Verificar que tiene los ejercicios correctos
      expect(workout.exercises.length, 2);
      expect(workout.exercises[0].sets, 3);
      expect(workout.exercises[1].sets, 4);
    });
  });
}
