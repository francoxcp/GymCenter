import 'package:flutter_test/flutter_test.dart';
import 'package:gymlab/features/nutrition/services/nutrition_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('guarda y recupera el perfil por usuario', () async {
    await NutritionPrefs.save('u1', {'activity_level': 'standing', 'meals_per_day': 3});
    expect(await NutritionPrefs.load('u1'),
        {'activity_level': 'standing', 'meals_per_day': 3});
    expect(await NutritionPrefs.load('u2'), isNull);
  });

  test('un dato corrupto se ignora', () async {
    SharedPreferences.setMockInitialValues({'nutrition_profile_u1': '{no json'});
    expect(await NutritionPrefs.load('u1'), isNull);
  });
}
