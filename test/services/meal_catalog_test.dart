import 'package:flutter_test/flutter_test.dart';
import 'package:gymlab/features/nutrition/data/foods.dart';
import 'package:gymlab/features/nutrition/services/meal_scaler.dart';
import 'package:gymlab/features/nutrition/services/nutrition_calculator.dart';
import 'package:gymlab/features/nutrition/services/portions.dart';

const _all = {'dairy', 'egg', 'seafood', 'red_meat', 'pork'};

const _lunch = Portions({
  FoodGroup.harina: 2,
  FoodGroup.proteina: 5,
  FoodGroup.vegetal: 1,
  FoodGroup.grasa: 1,
});

MealTarget _t(MealSlot s, Portions p) =>
    MealTarget(s, p.kcal.round(), p.proteinG.round(), portions: p);

NutritionProfile _prof(NutritionGoal g, double w) => NutritionProfile(
      weightKg: w,
      heightCm: w < 70 ? 160 : 178,
      age: 30,
      sex: w < 70 ? 'female' : 'male',
      goal: g,
      activity: ActivityLevel.standing,
      trainingDays: 4,
      mealsPerDay: 5,
    );

void main() {
  test('cada componente usa un alimento con porción de ese grupo', () {
    for (final o in kMealCatalog) {
      for (final c in o.components) {
        final f = kFoods[c.foodId];
        expect(f, isNotNull, reason: '${o.id}: ${c.foodId}');
        expect(f!.group, c.group, reason: '${o.id}: ${c.foodId}');
        expect(f.portionGrams, greaterThan(0), reason: c.foodId);
      }
    }
  });

  test('ids únicos y partes de cada grupo que suman 1', () {
    final ids = kMealCatalog.map((o) => o.id).toList();
    expect(ids.toSet().length, ids.length);
    for (final o in kMealCatalog) {
      final byGroup = <FoodGroup, double>{};
      for (final c in o.components) {
        byGroup[c.group] = (byGroup[c.group] ?? 0) + c.share;
      }
      byGroup.forEach((g, sum) =>
          expect(sum, closeTo(1, 1e-9), reason: '${o.id} $g'));
    }
  });

  test('platos principales y meriendas traen harina y proteína; merienda AM fruta', () {
    for (final o in kMealCatalog) {
      final groups = o.components.map((c) => c.group).toSet();
      for (final s in o.slots) {
        if (s == MealSlot.snackAm) {
          expect(groups, {FoodGroup.fruta}, reason: o.id);
        } else {
          expect(groups, containsAll([FoodGroup.harina, FoodGroup.proteina]),
              reason: '${o.id} en ${s.name}');
        }
      }
    }
  });

  test('variedad: 10–12 por desayuno, almuerzo y cena; ≥8 meriendas; ≥6 frutas', () {
    for (final s in [MealSlot.breakfast, MealSlot.lunch, MealSlot.dinner]) {
      expect(optionsFor(s, const {}).length, inInclusiveRange(10, 12),
          reason: s.name);
    }
    expect(optionsFor(MealSlot.snackPm, const {}).length,
        greaterThanOrEqualTo(8));
    expect(optionsFor(MealSlot.snackAm, const {}).length,
        greaterThanOrEqualTo(6));
  });

  test('excluir todo deja al menos 2 opciones por comida', () {
    for (final s in MealSlot.values) {
      expect(optionsFor(s, _all).length, greaterThanOrEqualTo(2),
          reason: s.name);
    }
  });

  test('casado medido: cantidades exactas según las porciones', () {
    final o = kMealCatalog.firstWhere((o) => o.id == 'casado_pollo');
    final s = scaleOption(o, _t(MealSlot.lunch, _lunch));
    String label(String id) =>
        s.items.firstWhere((i) => i.food.id == id).label;
    expect(label('arroz'), '⅓ taza de arroz');
    expect(label('frijoles'), '⅓ taza de frijoles');
    expect(label('pollo'), '150 g de pechuga de pollo (cocida)');
    expect(s.items.any((i) => i.food.id == 'ensalada'), isTrue);
    expect(s.items.any((i) => i.food.id == 'aceite'), isTrue);
  });

  test('si el plato no trae grasa, vegetal o fruta, se agregan por defecto', () {
    final o = kMealCatalog.firstWhere((o) => o.id == 'galletas_queso');
    final p = const Portions({
      FoodGroup.harina: 1,
      FoodGroup.proteina: 3,
      FoodGroup.fruta: 1,
    });
    final s = scaleOption(o, _t(MealSlot.snackPm, p));
    expect(s.items.map((i) => i.food.id), contains('fruta'));
    expect(s.items.map((i) => i.food.id), isNot(contains('aceite')));
  });

  test('calorías y proteína reales cerca de las de las porciones', () {
    for (final g in NutritionGoal.values) {
      for (final w in [60.0, 80.0, 105.0]) {
        final day = dayPortions(_prof(g, w));
        day.meals.forEach((slot, pz) {
          for (final o in optionsFor(slot, const {})) {
            final s = scaleOption(o, _t(slot, pz));
            expect(s.kcal, closeTo(pz.kcal, pz.kcal * 0.35 + 40),
                reason: '${o.id} $g $w kcal');
            expect(s.proteinG, closeTo(pz.proteinG, pz.proteinG * 0.35 + 5),
                reason: '${o.id} $g $w proteína');
          }
        });
      }
    }
  });

  test('medidas caseras: tercios/cuartos de taza, medias unidades o gramos de 10', () {
    for (final o in kMealCatalog) {
      for (final slot in o.slots) {
        final s = scaleOption(o, _t(slot, _lunch));
        for (final it in s.items) {
          expect(isHouseholdMeasure(it.food, it.grams), isTrue,
              reason: '${o.id} ${it.food.id} ${it.grams}');
          expect(it.grams, greaterThan(0));
          expect(it.label, isNotEmpty);
        }
      }
    }
  });

  test('excluir huevo quita los platos con huevo', () {
    for (final o in optionsFor(MealSlot.breakfast, {'egg'})) {
      expect(o.components.any((c) => c.foodId == 'huevo'), isFalse,
          reason: o.id);
    }
  });

  test('medidas caseras admitidas', () {
    final arroz = kFoods['arroz']!;
    expect(isHouseholdMeasure(arroz, arroz.unitGrams! / 3), isTrue);
    expect(isHouseholdMeasure(arroz, arroz.unitGrams! * 0.75), isTrue);
    expect(isHouseholdMeasure(arroz, arroz.unitGrams! * 0.4), isFalse);
    final huevo = kFoods['huevo']!;
    expect(isHouseholdMeasure(huevo, 75), isTrue);
    expect(isHouseholdMeasure(huevo, 60), isFalse);
    expect(isHouseholdMeasure(kFoods['pollo']!, 150), isTrue);
    expect(isHouseholdMeasure(kFoods['pollo']!, 155), isFalse);
  });
}
