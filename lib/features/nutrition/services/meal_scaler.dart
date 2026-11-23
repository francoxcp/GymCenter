import 'dart:math' as math;

import '../data/foods.dart';
import '../data/meal_catalog.dart';
import '../models/nutrition_profile.dart';

export '../data/meal_catalog.dart';

/// Un ingrediente con su cantidad ajustada y cómo decirla en casa.
class ScaledItem {
  final Food food;
  final double grams;
  final String label;
  const ScaledItem(this.food, this.grams, this.label);
}

/// Una opción con porciones ajustadas al objetivo de esa comida.
class ScaledOption {
  final MealOption option;
  final List<ScaledItem> items;
  final int kcal;
  final int proteinG;
  final int priceCrc;
  const ScaledOption(
      this.option, this.items, this.kcal, this.proteinG, this.priceCrc);
}

/// Opciones de un tiempo de comida sin lo que el socio no come.
/// Las dos meriendas comparten opciones.
List<MealOption> optionsFor(MealSlot slot, Set<String> avoid) => [
      for (final o in kMealCatalog)
        if (o.slots.contains(slot) && o.tags.intersection(avoid).isEmpty) o,
    ];

const _minFactor = 0.6;
const _maxFactor = 1.8;

/// Ajusta las porciones de [o] a las calorías y proteína de [t].
///
/// Escala todo por igual (0,6–1,8×). Si la proteína queda bajo el 80 % del
/// objetivo, sube los ingredientes proteicos (hasta 1,8× su base) y baja los
/// carbohidratos para no pasarse de calorías. Redondea a medidas caseras.
ScaledOption scaleOption(MealOption o, MealTarget t) {
  final base = [for (final i in o.ingredients) i.grams];
  double kcalOf(List<double> g) => _sum(o, g, (f) => f.kcal100);
  double proteinOf(List<double> g) => _sum(o, g, (f) => f.protein100);

  final factor = (t.kcal / kcalOf(base)).clamp(_minFactor, _maxFactor);
  final grams = [for (final b in base) b * factor];

  final wanted = t.proteinG * 0.8;
  final protein = proteinOf(grams);
  if (protein < wanted) {
    final kcalBefore = kcalOf(grams);
    var missing = wanted - protein;
    for (var i = 0; i < grams.length && missing > 0; i++) {
      if (o.ingredients[i].role != IngredientRole.protein) continue;
      final food = kFoods[o.ingredients[i].foodId]!;
      final room = math.max(0.0, base[i] * _maxFactor - grams[i]);
      final add = math.min(room, missing / food.protein100 * 100);
      grams[i] += add;
      missing -= add * food.protein100 / 100;
    }
    // Compensar calorías bajando carbohidratos (no menos de la mitad)
    var extra = kcalOf(grams) - kcalBefore;
    for (var i = 0; i < grams.length && extra > 0; i++) {
      if (o.ingredients[i].role != IngredientRole.carb) continue;
      final food = kFoods[o.ingredients[i].foodId]!;
      final cut = math.min(grams[i] * 0.5, extra / food.kcal100 * 100);
      grams[i] -= cut;
      extra -= cut * food.kcal100 / 100;
    }
  }

  final items = <ScaledItem>[];
  for (var i = 0; i < grams.length; i++) {
    final food = kFoods[o.ingredients[i].foodId]!;
    final g = _round(food, grams[i]);
    items.add(ScaledItem(food, g, _label(food, g)));
  }
  final rounded = [for (final it in items) it.grams];
  final price = items.fold<double>(
      0, (a, it) => a + it.grams / 1000 * it.food.priceCrcPerKg);
  return ScaledOption(o, items, kcalOf(rounded).round(),
      proteinOf(rounded).round(), price.round());
}

double _sum(MealOption o, List<double> grams, double Function(Food) per100) {
  var total = 0.0;
  for (var i = 0; i < grams.length; i++) {
    total += per100(kFoods[o.ingredients[i].foodId]!) * grams[i] / 100;
  }
  return total;
}

/// Paso de redondeo en unidades: cuartos para medidas grandes (taza,
/// plátano), medias para las pequeñas (huevo, tortilla).
double unitStep(Food f) => (f.unitGrams ?? 0) >= 100 ? 0.25 : 0.5;

/// Medida casera redondeada; sin medida, gramos de 10.
double _round(Food f, double grams) {
  final unit = f.unitGrams;
  if (unit != null) {
    final step = unitStep(f);
    final steps = math.max(1, (grams / unit / step).round());
    return steps * step * unit;
  }
  return math.max(10, (grams / 10).round() * 10).toDouble();
}

String _label(Food f, double grams) {
  final unit = f.unitGrams;
  if (unit == null) return '${grams.round()} g de ${f.name}';
  final units = grams / unit;
  final whole = units.floor();
  final frac = switch (((units - whole) * 4).round()) {
    1 => '¼',
    2 => '½',
    3 => '¾',
    _ => '',
  };
  final qty = whole == 0 ? frac : '$whole$frac';
  return '$qty ${units > 1 ? f.unitPlural : f.unit}';
}
