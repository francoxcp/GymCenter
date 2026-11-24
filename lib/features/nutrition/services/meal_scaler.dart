import 'dart:math' as math;

import '../data/foods.dart';
import '../data/meal_catalog.dart';
import '../models/nutrition_profile.dart';
import 'portions.dart';

export '../data/meal_catalog.dart';

/// Un alimento con su cantidad y cómo decirla en casa.
class ScaledItem {
  final Food food;
  final double grams;
  final String label;
  const ScaledItem(this.food, this.grams, this.label);
}

/// Un plato con las cantidades de esta persona en esta comida.
class ScaledOption {
  final MealOption option;
  final List<ScaledItem> items;
  final int kcal;
  final int proteinG;
  final int priceCrc;
  const ScaledOption(
      this.option, this.items, this.kcal, this.proteinG, this.priceCrc);
}

/// Platos de un tiempo de comida sin lo que el socio no come.
List<MealOption> optionsFor(MealSlot slot, Set<String> avoid) => [
      for (final o in kMealCatalog)
        if (o.slots.contains(slot) && o.tags.intersection(avoid).isEmpty) o,
    ];

/// Alimento que se agrega si la comida pide un grupo que el plato no trae.
const _defaults = {
  FoodGroup.grasa: 'aceite',
  FoodGroup.vegetal: 'ensalada',
  FoodGroup.fruta: 'fruta',
};

/// Cantidades del plato [o] para las porciones de [t]: cada alimento recibe
/// porciones del grupo × su parte × gramos por porción, en medidas caseras.
ScaledOption scaleOption(MealOption o, MealTarget t) {
  final pz = t.portions ?? const Portions({});
  final present = {for (final c in o.components) c.group};
  final parts = [
    for (final c in o.components) (kFoods[c.foodId]!, pz[c.group] * c.share),
    for (final e in _defaults.entries)
      if (!present.contains(e.key) && pz[e.key] > 0)
        (kFoods[e.value]!, pz[e.key]),
  ];

  final items = <ScaledItem>[];
  for (final (food, portions) in parts) {
    if (portions <= 0) continue;
    final g = _round(food, portions * food.portionGrams);
    items.add(ScaledItem(food, g, _label(food, g)));
  }
  double sum(double Function(Food) per100) =>
      items.fold(0.0, (a, it) => a + per100(it.food) * it.grams / 100);
  return ScaledOption(
    o,
    items,
    sum((f) => f.kcal100).round(),
    sum((f) => f.protein100).round(),
    items
        .fold<double>(0, (a, it) => a + it.grams / 1000 * it.food.priceCrcPerKg)
        .round(),
  );
}

/// Fracciones de taza admitidas (en doceavos): ¼ ⅓ ½ ⅔ ¾.
bool _niceTwelfth(int k) => k % 3 == 0 || k % 4 == 0;

/// ¿[grams] es una medida casera válida para [f]? Tercios y cuartos en
/// medidas grandes (taza, plátano), medias unidades en las pequeñas
/// (huevo, tortilla) y gramos de 10 sin medida.
bool isHouseholdMeasure(Food f, double grams) {
  final unit = f.unitGrams;
  if (unit == null) return grams > 0 && (grams % 10).abs() < 1e-6;
  final units = grams / unit;
  if (unit >= 100) {
    final k = units * 12;
    return (k - k.round()).abs() < 1e-6 && k.round() > 0 && _niceTwelfth(k.round());
  }
  final h = units * 2;
  return (h - h.round()).abs() < 1e-6 && h.round() > 0;
}

/// Lleva [grams] a la medida casera más cercana.
double _round(Food f, double grams) {
  final unit = f.unitGrams;
  if (unit == null) return math.max(10, (grams / 10).round() * 10).toDouble();
  final units = grams / unit;
  if (unit >= 100) {
    var best = 3; // ¼ como mínimo
    for (var k = 3; k <= 12 * 20; k++) {
      if (!_niceTwelfth(k)) continue;
      if ((k / 12 - units).abs() < (best / 12 - units).abs()) best = k;
    }
    return best / 12 * unit;
  }
  return math.max(1, (units * 2).round()) / 2 * unit;
}

String _label(Food f, double grams) {
  final unit = f.unitGrams;
  if (unit == null) return '${grams.round()} g de ${f.name}';
  final units = grams / unit;
  final whole = units.floor();
  final frac = switch (((units - whole) * 12).round()) {
    3 => '¼',
    4 => '⅓',
    6 => '½',
    8 => '⅔',
    9 => '¾',
    _ => '',
  };
  final qty = whole == 0 ? frac : '$whole$frac';
  return '$qty ${units > 1 ? f.unitPlural : f.unit}';
}
