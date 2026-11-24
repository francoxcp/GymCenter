import 'package:flutter_test/flutter_test.dart';
import 'package:gymlab/features/nutrition/services/nutrition_calculator.dart';
import 'package:gymlab/features/nutrition/services/portions.dart';

NutritionProfile p({
  double weight = 78,
  int height = 175,
  int age = 29,
  String sex = 'male',
  NutritionGoal goal = NutritionGoal.cut,
  int meals = 4,
}) =>
    NutritionProfile(
      weightKg: weight,
      heightCm: height,
      age: age,
      sex: sex,
      goal: goal,
      activity: ActivityLevel.sedentary,
      trainingDays: 5,
      mealsPerDay: meals,
    );

double _sum(Iterable<double> v) => v.fold(0.0, (a, b) => a + b);

void main() {
  test('las porciones por comida suman las del día, en medias porciones', () {
    for (final meals in [3, 4, 5]) {
      for (final g in NutritionGoal.values) {
        final day = dayPortions(p(goal: g, meals: meals));
        for (final grp in FoodGroup.values) {
          expect(_sum(day.meals.values.map((m) => m[grp])), day.total[grp],
              reason: '$meals comidas, $g, $grp');
          for (final m in day.meals.values) {
            expect((m[grp] * 2) % 1, 0, reason: '$grp medias porciones');
          }
        }
      }
    }
  });

  test('calorías y proteína cerca del objetivo', () {
    for (final g in NutritionGoal.values) {
      for (final prof in [
        p(goal: g),
        p(goal: g, weight: 60, height: 160, sex: 'female'),
        p(goal: g, weight: 110, height: 185),
      ]) {
        final t = computeTargets(prof);
        final day = dayPortions(prof);
        expect(day.total.kcal, closeTo(t.kcal, t.kcal * 0.08), reason: '$g kcal');
        expect(day.total.proteinG, closeTo(t.proteinG, t.proteinG * 0.12),
            reason: '$g proteína');
      }
    }
  });

  test('bajar grasa: más proteína y menos harina que subir masa', () {
    final cut = dayPortions(p(goal: NutritionGoal.cut)).total;
    final gain = dayPortions(p(goal: NutritionGoal.gain)).total;
    expect(gain[FoodGroup.harina], greaterThan(cut[FoodGroup.harina]));
    expect(cut.proteinG / cut.kcal, greaterThan(gain.proteinG / gain.kcal));
  });

  test('patrón de 4 comidas como el plan de referencia', () {
    final day = dayPortions(p(meals: 4));
    final b = day.meals[MealSlot.breakfast]!;
    final l = day.meals[MealSlot.lunch]!;
    final s = day.meals[MealSlot.snackPm]!;
    final d = day.meals[MealSlot.dinner]!;
    expect(b[FoodGroup.fruta], 1);
    expect(s[FoodGroup.fruta], 1);
    expect(s[FoodGroup.grasa], 0);
    expect(s[FoodGroup.harina], greaterThan(0));
    expect(s[FoodGroup.proteina], greaterThan(0));
    expect(l[FoodGroup.vegetal], greaterThan(0));
    expect(d[FoodGroup.vegetal], greaterThan(0));
    expect(l[FoodGroup.proteina], greaterThan(b[FoodGroup.proteina]));
    expect(day.meals.keys, slotsFor(4));
  });

  test('5 comidas: la merienda AM es solo fruta', () {
    final day = dayPortions(p(meals: 5));
    final am = day.meals[MealSlot.snackAm]!;
    expect(am[FoodGroup.fruta], 1);
    for (final g in [FoodGroup.harina, FoodGroup.proteina, FoodGroup.grasa]) {
      expect(am[g], 0);
    }
    expect(day.meals[MealSlot.breakfast]![FoodGroup.fruta], 0);
  });

  test('3 comidas: sin meriendas, todo repartido en las principales', () {
    final day = dayPortions(p(meals: 3));
    expect(day.meals.keys, [MealSlot.breakfast, MealSlot.lunch, MealSlot.dinner]);
  });

  test('etiqueta legible de porciones', () {
    const pz = Portions({
      FoodGroup.harina: 2,
      FoodGroup.proteina: 5,
      FoodGroup.vegetal: 0.5,
      FoodGroup.grasa: 2,
    });
    expect(pz.label, '2 harinas · 5 proteínas · ½ vegetal · 2 grasas');
    const one = Portions({FoodGroup.fruta: 1, FoodGroup.harina: 1.5});
    expect(one.label, '1½ harinas · 1 fruta');
  });
}
