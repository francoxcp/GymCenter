import 'package:flutter_test/flutter_test.dart';
import 'package:gymlab/features/nutrition/services/meal_choice_store.dart';
import 'package:gymlab/features/nutrition/services/nutrition_calculator.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('guarda la elección del día', () async {
    final now = DateTime(2026, 11, 22, 9);
    await MealChoiceStore.choose('u1', MealSlot.breakfast, 'pinto_huevo', now: now);
    await MealChoiceStore.choose('u1', MealSlot.lunch, 'casado_pollo', now: now);
    expect(await MealChoiceStore.today('u1', now: now), {
      MealSlot.breakfast: 'pinto_huevo',
      MealSlot.lunch: 'casado_pollo',
    });
  });

  test('se reinicia al cambiar de día', () async {
    await MealChoiceStore.choose('u1', MealSlot.breakfast, 'pinto_huevo',
        now: DateTime(2026, 11, 22, 9));
    expect(await MealChoiceStore.today('u1', now: DateTime(2026, 11, 23, 9)),
        isEmpty);
  });

  test('quitar la elección', () async {
    final now = DateTime(2026, 11, 22, 9);
    await MealChoiceStore.choose('u1', MealSlot.breakfast, 'pinto_huevo', now: now);
    await MealChoiceStore.choose('u1', MealSlot.breakfast, null, now: now);
    expect(await MealChoiceStore.today('u1', now: now), isEmpty);
  });

  group('defaultSlot', () {
    test('3 comidas a las 11:00 → almuerzo', () {
      expect(defaultSlot(DateTime(2026, 11, 22, 11), slotsFor(3)), MealSlot.lunch);
    });
    test('5 comidas a las 11:00 → merienda de la mañana', () {
      expect(defaultSlot(DateTime(2026, 11, 22, 11), slotsFor(5)), MealSlot.snackAm);
    });
    test('7:00 → desayuno; 21:00 → cena', () {
      expect(defaultSlot(DateTime(2026, 11, 22, 7), slotsFor(4)), MealSlot.breakfast);
      expect(defaultSlot(DateTime(2026, 11, 22, 21), slotsFor(4)), MealSlot.dinner);
    });
    test('4 comidas a las 16:00 → merienda de la tarde', () {
      expect(defaultSlot(DateTime(2026, 11, 22, 16), slotsFor(4)), MealSlot.snackPm);
    });
  });
}
