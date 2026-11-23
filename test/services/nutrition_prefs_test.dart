import 'package:flutter_test/flutter_test.dart';
import 'package:gymlab/features/nutrition/services/nutrition_prefs.dart';
import 'package:gymlab/features/auth/models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('guarda y recupera el perfil por usuario', () async {
    await NutritionPrefs.save('u1', {'activity_level': 'standing', 'meals_per_day': 3});
    final got = await NutritionPrefs.load('u1');
    expect(got!['activity_level'], 'standing');
    expect(got['meals_per_day'], 3);
    expect(got['_pending'], isFalse);
    expect(await NutritionPrefs.load('u2'), isNull);
  });

  test('un dato corrupto se ignora', () async {
    SharedPreferences.setMockInitialValues({'nutrition_profile_u1': '{no json'});
    expect(await NutritionPrefs.load('u1'), isNull);
  });

  test('pendiente hasta que se marca como sincronizado', () async {
    await NutritionPrefs.save('u1', {'meals_per_day': 3}, pending: true);
    expect(await NutritionPrefs.isPending('u1'), isTrue);
    await NutritionPrefs.markSynced('u1');
    expect(await NutritionPrefs.isPending('u1'), isFalse);
    expect((await NutritionPrefs.load('u1'))!['meals_per_day'], 3);
  });

  test('aplicar la copia local no borra la rutina asignada ni la fecha', () {
    final u = User(
      id: 'u1',
      email: 'a@b.c',
      name: 'Ana',
      role: 'user',
      assignedWorkoutId: 'w1',
      createdAt: DateTime(2026, 1, 1),
      mealsPerDay: 4,
    );
    final merged = applyNutritionPrefs(u, {
      'meals_per_day': 3,
      'food_avoid': ['dairy'],
      'activity_level': 'physical',
      'weight_kg': 75.0,
      'height_cm': 170,
      'age': 30,
      'sex': 'female',
      'goal': 'Perder peso',
    });
    expect(merged.assignedWorkoutId, 'w1');
    expect(merged.createdAt, DateTime(2026, 1, 1));
    expect(merged.mealsPerDay, 3);
    expect(merged.foodAvoid, ['dairy']);
    expect(merged.activityLevel, 'physical');
    expect(merged.weightKg, 75.0);
    expect(merged.goal, 'Perder peso');
  });

  group('effectiveWeight', () {
    test('peso del cuestionario más nuevo que la última medida gana', () {
      expect(
          effectiveWeight(
              measuredKg: 80,
              measuredAt: DateTime(2026, 11, 1),
              local: {'weight_kg': 75.0, 'saved_at': '2026-11-20T10:00:00'},
              userKg: 75),
          75);
    });
    test('medida más nueva que el cuestionario gana', () {
      expect(
          effectiveWeight(
              measuredKg: 82,
              measuredAt: DateTime(2026, 11, 21),
              local: {'weight_kg': 75.0, 'saved_at': '2026-11-20T10:00:00'},
              userKg: 75),
          82);
    });
    test('sin medidas ni copia local usa el de users', () {
      expect(effectiveWeight(userKg: 70), 70);
      expect(effectiveWeight(), isNull);
    });
  });
}
