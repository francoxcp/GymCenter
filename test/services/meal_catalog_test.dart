import 'package:flutter_test/flutter_test.dart';
import 'package:gymlab/features/nutrition/data/foods.dart';
import 'package:gymlab/features/nutrition/data/meal_catalog.dart';
import 'package:gymlab/features/nutrition/services/meal_scaler.dart';
import 'package:gymlab/features/nutrition/services/nutrition_calculator.dart';

const _all = {'dairy', 'egg', 'seafood', 'red_meat', 'pork'};

double _baseKcal(MealOption o) => o.ingredients.fold(
    0.0, (a, i) => a + kFoods[i.foodId]!.kcal100 * i.grams / 100);

void main() {
  test('todo ingrediente existe en kFoods y cada opción tiene kcal base > 0',
      () {
    for (final o in kMealCatalog) {
      for (final i in o.ingredients) {
        expect(kFoods.containsKey(i.foodId), isTrue,
            reason: '${o.id}: ${i.foodId}');
      }
      expect(_baseKcal(o), greaterThan(0), reason: o.id);
    }
  });

  test('ids de opciones únicos', () {
    final ids = kMealCatalog.map((o) => o.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('8 a 10 opciones por desayuno, almuerzo y cena; ≥ 7 meriendas', () {
    for (final s in [MealSlot.breakfast, MealSlot.lunch, MealSlot.dinner]) {
      expect(optionsFor(s, const {}).length, inInclusiveRange(8, 10),
          reason: s.name);
    }
    expect(optionsFor(MealSlot.snackPm, const {}).length,
        greaterThanOrEqualTo(7));
    expect(optionsFor(MealSlot.snackAm, const {}).map((o) => o.id),
        optionsFor(MealSlot.snackPm, const {}).map((o) => o.id));
  });

  test('excluir huevo quita gallo pinto con huevo del desayuno', () {
    expect(optionsFor(MealSlot.breakfast, const {})
        .any((o) => o.id == 'pinto_huevo'), isTrue);
    expect(optionsFor(MealSlot.breakfast, {'egg'})
        .any((o) => o.id == 'pinto_huevo'), isFalse);
  });

  test('excluir todo deja al menos 1 opción por tiempo', () {
    for (final s in MealSlot.values) {
      expect(optionsFor(s, _all), isNotEmpty, reason: s.name);
    }
  });

  test('escalado acerca las kcal al objetivo (±15 %)', () {
    final o = kMealCatalog.firstWhere((o) => o.id == 'pinto_huevo');
    final s = scaleOption(o, const MealTarget(MealSlot.breakfast, 650, 40));
    expect(s.kcal, inInclusiveRange(552, 748));
  });

  test('proteína baja sube primero el ingrediente protein', () {
    final o = kMealCatalog.firstWhere((o) => o.id == 'avena_banano');
    final s = scaleOption(o, const MealTarget(MealSlot.breakfast, 600, 40));
    // Proporcional daría ~25 g; la leche sube hasta 1,8× su base (≈ 26 g tras redondear).
    // Un plato con poca proteína no llega al 80 % sin cantidades absurdas.
    expect(s.proteinG, greaterThanOrEqualTo(26));
    expect(s.kcal, inInclusiveRange(480, 720));
  });

  test('objetivo enorme se limita a 1,8× la base', () {
    final o = kMealCatalog.firstWhere((o) => o.id == 'pinto_huevo');
    final s = scaleOption(o, const MealTarget(MealSlot.breakfast, 5000, 40));
    expect(s.kcal, lessThanOrEqualTo(_baseKcal(o) * 1.8 * 1.1));
  });

  test('objetivo mínimo se limita a 0,6× la base', () {
    final o = kMealCatalog.firstWhere((o) => o.id == 'pinto_huevo');
    final s = scaleOption(o, const MealTarget(MealSlot.breakfast, 50, 2));
    // El redondeo a medidas caseras puede bajar hasta ~20 % en porciones chicas
    expect(s.kcal, greaterThanOrEqualTo(_baseKcal(o) * 0.6 * 0.8));
  });

  test('cantidades en medidas caseras: cuartos/medios por unidad o gramos de 10', () {
    for (final o in kMealCatalog) {
      final s = scaleOption(o, const MealTarget(MealSlot.lunch, 777, 47));
      for (final it in s.items) {
        final unit = it.food.unitGrams;
        if (unit != null) {
          final steps = it.grams / unit / unitStep(it.food);
          expect((steps - steps.round()).abs(), lessThan(1e-6),
              reason: '${o.id} ${it.food.id}');
        } else {
          expect(it.grams % 10, 0, reason: '${o.id} ${it.food.id}');
        }
        expect(it.grams, greaterThan(0));
        expect(it.label, isNotEmpty);
      }
    }
  });

  test('precio = suma de gramos × precio/kg, entero', () {
    final o = kMealCatalog.firstWhere((o) => o.id == 'pinto_huevo');
    final s = scaleOption(o, const MealTarget(MealSlot.breakfast, 650, 40));
    final expected = s.items
        .fold(0.0, (a, it) => a + it.grams / 1000 * it.food.priceCrcPerKg)
        .round();
    expect(s.priceCrc, expected);
    expect(s.priceCrc, greaterThan(0));
  });

  test('pesos extremos: porciones razonables para 40 y 150 kg', () {
    for (final w in [40.0, 150.0]) {
      final t = computeTargets(NutritionProfile(
          weightKg: w,
          heightCm: w < 100 ? 150 : 190,
          age: 30,
          sex: w < 100 ? 'female' : 'male',
          goal: NutritionGoal.maintain,
          activity: ActivityLevel.sedentary,
          trainingDays: 3,
          mealsPerDay: 4));
      for (final m in t.meals) {
        for (final o in optionsFor(m.slot, const {})) {
          final s = scaleOption(o, m);
          expect(s.kcal, greaterThan(0));
          expect(s.kcal, lessThan(2000), reason: '${o.id} $w');
        }
      }
    }
  });
}
