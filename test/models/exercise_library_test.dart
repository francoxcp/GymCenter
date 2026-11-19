import 'package:flutter_test/flutter_test.dart';
import 'package:gymlab/features/workouts/services/exercise_library_service.dart';
import 'package:gymlab/features/workouts/widgets/exercise_library.dart';
import 'package:gymlab/shared/widgets/exercise_media.dart';

void main() {
  group('LibraryExercise.fromRow', () {
    test('lleva el GIF y las instrucciones al ejercicio de la rutina', () {
      final e = LibraryExercise.fromRow({
        'name': ' Remo con mancuerna ',
        'muscle_group': 'Espalda',
        'default_sets': 4,
        'default_reps': 10,
        'default_rest': 90,
        'media_url': 'https://cdn.example.com/remo.gif',
        'instructions': 'Espalda recta.',
        'org_id': null,
      });
      final ex = e.toExercise();
      expect(ex.name, 'Remo con mancuerna');
      expect(ex.sets, 4);
      expect(ex.reps, 10);
      expect(ex.restSeconds, 90);
      expect(ex.videoUrl, 'https://cdn.example.com/remo.gif');
      expect(ex.description, 'Espalda recta.');
      expect(e.isOwn, isFalse);
    });

    test('sin video ni instrucciones quedan en null', () {
      final e = LibraryExercise.fromRow({
        'name': 'Plancha',
        'media_url': '  ',
        'org_id': 'abc',
      });
      expect(e.hasMedia, isFalse);
      expect(e.instructions, isNull);
      expect(e.muscle, 'General');
      expect(e.isOwn, isTrue);
    });
  });

  test('isImageMediaUrl distingue GIF de video', () {
    expect(isImageMediaUrl('https://x.com/a.gif'), isTrue);
    expect(isImageMediaUrl('https://x.com/a.GIF?token=1'), isTrue);
    expect(isImageMediaUrl('https://x.com/a.mp4'), isFalse);
    expect(isImageMediaUrl('https://x.com/videos/abc'), isFalse);
  });

  test('normalizeExerciseName ignora tildes y mayúsculas', () {
    expect(normalizeExerciseName(' Jalón Señor '), 'jalon senor');
  });
}
