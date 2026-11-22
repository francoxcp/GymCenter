import 'package:flutter_test/flutter_test.dart';
import 'package:gymlab/features/nutrition/models/nutrition_profile.dart';
import 'package:gymlab/features/nutrition/services/nutrition_calculator.dart';

NutritionProfile p({
  double weight = 70,
  int height = 170,
  int age = 30,
  String sex = 'male',
  NutritionGoal goal = NutritionGoal.maintain,
  ActivityLevel act = ActivityLevel.sedentary,
  int days = 3,
  int meals = 4,
}) =>
    NutritionProfile(
      weightKg: weight,
      heightCm: height,
      age: age,
      sex: sex,
      goal: goal,
      activity: act,
      trainingDays: days,
      mealsPerDay: meals,
    );

void main() {
  test('hombre 78 kg 175 cm 29 a, sentado, 3 días, subir masa, 4 comidas', () {
    final t = computeTargets(p(
        weight: 78,
        height: 175,
        age: 29,
        goal: NutritionGoal.gain,
        days: 3,
        meals: 4));
    expect(t.kcal, 2500);
    expect(t.proteinG, 140);
    expect(t.fatG, 69);
    expect(t.carbG, 330);
    expect(t.meals.map((m) => m.slot), [
      MealSlot.breakfast,
      MealSlot.lunch,
      MealSlot.snackPm,
      MealSlot.dinner,
    ]);
    expect(t.meals.map((m) => m.kcal), [625, 875, 250, 750]);
    expect(t.meals.map((m) => m.proteinG).reduce((a, b) => a + b),
        closeTo(140, 2));
  });

  test('mujer en déficit respeta el piso (reposo × 1,1, redondeo hacia arriba)',
      () {
    final t = computeTargets(p(
        weight: 60,
        height: 160,
        age: 30,
        sex: 'female',
        goal: NutritionGoal.cut,
        days: 0,
        meals: 3));
    expect(t.kcal, 1450);
    expect(t.proteinG, 120);
  });

  test('menor de 18: cut se trata como mantener y gain como ×1,05', () {
    final base = p(
        weight: 60,
        height: 170,
        age: 16,
        act: ActivityLevel.standing,
        days: 3,
        meals: 4);
    final m = computeTargets(base.copyWith(goal: NutritionGoal.maintain)).kcal;
    expect(base.isMinor, isTrue);
    expect(computeTargets(base.copyWith(goal: NutritionGoal.cut)).kcal, m);
    expect(computeTargets(base.copyWith(goal: NutritionGoal.gain)).kcal,
        closeTo(m * 1.05, 50));
  });

  test('sexo other usa el promedio entre hombre y mujer', () {
    final male = computeTargets(p(sex: 'male')).kcal;
    final female = computeTargets(p(sex: 'female')).kcal;
    final other = computeTargets(p(sex: 'other')).kcal;
    expect(other, lessThan(male));
    expect(other, greaterThan(female));
  });

  test('días de entreno máx. 6 y factor tope 1,9', () {
    final six = computeTargets(p(act: ActivityLevel.physical, days: 6)).kcal;
    final seven = computeTargets(p(act: ActivityLevel.physical, days: 7)).kcal;
    expect(seven, six);
    // physical 1,55 + 0,21 = 1,76 < 1,9; con 1,9 de tope no se supera
    final bmr = 10 * 70 + 6.25 * 170 - 5 * 30 + 5;
    expect(six, lessThanOrEqualTo(bmr * 1.9 + 50));
  });

  test('pesos extremos: proteína ≤ 220 g y grasa ≥ 0,6 g/kg', () {
    final heavy = computeTargets(
        p(weight: 150, height: 190, goal: NutritionGoal.cut));
    expect(heavy.proteinG, 220);
    expect(heavy.fatG, greaterThanOrEqualTo(90));
    final light = computeTargets(
        p(weight: 40, height: 150, sex: 'female', goal: NutritionGoal.cut));
    expect(light.kcal, greaterThanOrEqualTo(1200));
    expect(light.fatG, greaterThanOrEqualTo(24));
    expect(light.carbG, greaterThan(0));
  });

  test('reparto 3/4/5 comidas', () {
    expect(slotsFor(3), [MealSlot.breakfast, MealSlot.lunch, MealSlot.dinner]);
    expect(slotsFor(4),
        [MealSlot.breakfast, MealSlot.lunch, MealSlot.snackPm, MealSlot.dinner]);
    expect(slotsFor(5), MealSlot.values);
    final t = computeTargets(p(meals: 5));
    final total = t.kcal;
    expect(t.meals.map((m) => m.kcal), [
      (total * .25).round(),
      (total * .10).round(),
      (total * .30).round(),
      (total * .10).round(),
      (total * .25).round(),
    ]);
    final t3 = computeTargets(p(meals: 3));
    expect(t3.meals.map((m) => m.kcal),
        [(t3.kcal * .3).round(), (t3.kcal * .4).round(), (t3.kcal * .3).round()]);
  });

  test('goalFromLabel / goalToLabel conservan Mejorar salud', () {
    expect(goalFromLabel('Perder peso'), NutritionGoal.cut);
    expect(goalFromLabel('Ganar músculo'), NutritionGoal.gain);
    expect(goalFromLabel('Mejorar salud'), NutritionGoal.maintain);
    expect(goalFromLabel(null), NutritionGoal.maintain);
    expect(goalToLabel(NutritionGoal.maintain, current: 'Mejorar salud'),
        'Mejorar salud');
    expect(goalToLabel(NutritionGoal.maintain), 'Mantener peso');
    expect(goalToLabel(NutritionGoal.cut), 'Perder peso');
    expect(goalToLabel(NutritionGoal.gain), 'Ganar músculo');
  });

  test('ActivityLevel ida y vuelta con la BD', () {
    for (final a in ActivityLevel.values) {
      expect(ActivityLevel.fromDb(a.db), a);
    }
    expect(ActivityLevel.fromDb(null), isNull);
    expect(ActivityLevel.fromDb('x'), isNull);
  });
}
