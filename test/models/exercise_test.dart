import 'package:flutter_test/flutter_test.dart';
import 'package:chamos_fitness_center/models/exercise.dart';

void main() {
  group('Exercise Model Tests', () {
    test('Exercise should be created from JSON', () {
      final json = {
        'id': '1',
        'name': 'Press de banca',
        'instructions': 'Acostarse en el banco y empujar la barra',
        'sets': 3,
        'reps': 12,
        'rest_time': 60,
        'video_url': 'https://example.com/video.mp4',
        'muscle_group': 'Pecho',
        'difficulty': 'Intermedio',
      };

      final exercise = Exercise.fromJson(json);

      expect(exercise.id, '1');
      expect(exercise.name, 'Press de banca');
      expect(exercise.description, 'Acostarse en el banco y empujar la barra');
      expect(exercise.sets, 3);
      expect(exercise.reps, 12);
      expect(exercise.restSeconds, 60);
      expect(exercise.videoUrl, 'https://example.com/video.mp4');
      expect(exercise.muscleGroup, 'Pecho');
      expect(exercise.difficulty, 'Intermedio');
    });

    test('Exercise should convert to JSON', () {
      final exercise = Exercise(
        id: '1',
        name: 'Sentadilla',
        sets: 4,
        reps: 10,
        restSeconds: 90,
        muscleGroup: 'Piernas',
        difficulty: 'Avanzado',
        description: 'Bajar hasta que los muslos estén paralelos',
        videoUrl: 'https://example.com/squat.mp4',
      );

      final json = exercise.toJson();

      expect(json['id'], '1');
      expect(json['name'], 'Sentadilla');
      expect(json['sets'], 4);
      expect(json['reps'], 10);
      expect(json['restSeconds'], 90);
      expect(json['muscleGroup'], 'Piernas');
      expect(json['difficulty'], 'Avanzado');
      expect(json['videoUrl'], 'https://example.com/squat.mp4');
    });

    test('Exercise should handle missing optional fields', () {
      final json = {
        'id': '1',
        'name': 'Plancha',
        'sets': 3,
        'reps': 30,
      };

      final exercise = Exercise.fromJson(json);

      expect(exercise.id, '1');
      expect(exercise.name, 'Plancha');
      expect(exercise.description, isNull);
      expect(exercise.videoUrl, isNull);
      expect(exercise.restSeconds, 60); // Default value
      expect(exercise.muscleGroup, 'General'); // Default value
      expect(exercise.difficulty, 'Intermedio'); // Default value
    });

    test('Exercise should parse reps as string', () {
      final json = {
        'id': '1',
        'name': 'Dominadas',
        'sets': 3,
        'reps': '8', // String instead of int
        'muscle_group': 'Espalda',
      };

      final exercise = Exercise.fromJson(json);

      expect(exercise.reps, 8);
    });

    test('Exercise should use default reps if parsing fails', () {
      final json = {
        'id': '1',
        'name': 'Burpees',
        'sets': 3,
        'reps': 'invalid', // Invalid string
        'muscle_group': 'Cardio',
      };

      final exercise = Exercise.fromJson(json);

      expect(exercise.reps, 12); // Default value
    });
  });
}
