import 'dart:math' as math;

import '../models/nutrition_profile.dart';
import 'nutrition_calculator.dart';

/// Grupos del sistema de intercambio que usan las nutricionistas.
enum FoodGroup {
  harina('harina', 'harinas', 15, 3, 1, 80),
  proteina('proteína', 'proteínas', 0, 7, 3, 55),
  grasa('grasa', 'grasas', 0, 0, 5, 45),
  fruta('fruta', 'frutas', 15, 0, 0, 60),
  vegetal('vegetal', 'vegetales', 5, 2, 0, 25);

  const FoodGroup(this.singular, this.plural, this.carbG, this.proteinG,
      this.fatG, this.kcal);
  final String singular;
  final String plural;

  // Valor de una porción de intercambio
  final double carbG;
  final double proteinG;
  final double fatG;
  final double kcal;
}

/// Porciones por grupo (en medias porciones).
class Portions {
  final Map<FoodGroup, double> _v;
  const Portions(this._v);

  double operator [](FoodGroup g) => _v[g] ?? 0;

  double get kcal =>
      FoodGroup.values.fold(0.0, (a, g) => a + this[g] * g.kcal);
  double get proteinG =>
      FoodGroup.values.fold(0.0, (a, g) => a + this[g] * g.proteinG);

  bool get isEmpty => FoodGroup.values.every((g) => this[g] == 0);

  /// "2 harinas · 5 proteínas · ½ vegetal · 2 grasas"
  String get label {
    const order = [
      FoodGroup.harina,
      FoodGroup.proteina,
      FoodGroup.vegetal,
      FoodGroup.grasa,
      FoodGroup.fruta,
    ];
    return [
      for (final g in order)
        if (this[g] > 0)
          '${fmtPortion(this[g])} ${this[g] > 1 ? g.plural : g.singular}',
    ].join(' · ');
  }
}

/// 0.5 → "½", 1.5 → "1½", 2 → "2".
String fmtPortion(double v) {
  final whole = v.floor();
  final half = v - whole >= 0.5;
  if (whole == 0) return half ? '½' : '0';
  return half ? '$whole½' : '$whole';
}

/// Porciones del día y su reparto por comida.
class DayPortions {
  final Portions total;
  final Map<MealSlot, Portions> meals;
  const DayPortions(this.total, this.meals);
}

double _half(double v) => (v * 2).round() / 2;

/// Calcula las porciones del día a partir de calorías y macros
/// ([computeTargets]) y las reparte con el patrón de un plan de nutricionista:
/// desayuno harina + proteína + grasa (+ fruta); merienda AM fruta;
/// almuerzo y cena harinas + proteína + vegetal + grasa; merienda PM harina +
/// proteína + fruta.
DayPortions dayPortions(NutritionProfile p) {
  final t = computeTargets(p);
  final goal = p.isMinor && p.goal == NutritionGoal.cut
      ? NutritionGoal.maintain
      : p.goal;

  final veg = goal == NutritionGoal.gain ? 3.0 : 2.0;
  const fruit = 2.0;

  // Primero una estimación de harinas por carbohidratos, luego se ajustan
  // proteínas, grasas y por último harinas para cuadrar las calorías.
  // Proteína primero (como arma una nutricionista): la mayor parte de la
  // proteína del día sale de carnes, huevo, queso o yogur; el resto lo
  // aportan harinas y vegetales. Las harinas completan las calorías.
  final animalShare = switch (goal) {
    NutritionGoal.cut => 0.80,
    NutritionGoal.maintain => 0.70,
    NutritionGoal.gain => 0.65,
  };
  final proteina =
      math.max(6.0, _half(t.proteinG * animalShare / FoodGroup.proteina.proteinG));
  // Al menos una grasa por comida principal (la de cocinar)
  final grasa = math.max(3.0, _half((t.fatG - 3 * proteina) / 5));
  final harina = math.max(
      3.0, _half((t.kcal - 55 * proteina - 45 * grasa - 60 * fruit - 25 * veg) / 80));

  final total = Portions({
    FoodGroup.harina: harina,
    FoodGroup.proteina: proteina,
    FoodGroup.grasa: grasa,
    FoodGroup.fruta: fruit,
    FoodGroup.vegetal: veg,
  });

  final slots = slotsFor(p.mealsPerDay);
  final hasPm = slots.contains(MealSlot.snackPm);
  final hasAm = slots.contains(MealSlot.snackAm);

  // Partes de cada grupo por comida (patrón de referencia con 4 comidas)
  final shares = <FoodGroup, Map<MealSlot, double>>{
    FoodGroup.harina: {
      MealSlot.breakfast: 1,
      MealSlot.lunch: 2,
      if (hasPm) MealSlot.snackPm: 1,
      MealSlot.dinner: 1,
    },
    FoodGroup.proteina: {
      MealSlot.breakfast: 3,
      MealSlot.lunch: 5,
      if (hasPm) MealSlot.snackPm: 3,
      MealSlot.dinner: 5,
    },
    FoodGroup.grasa: {
      MealSlot.breakfast: 1,
      MealSlot.lunch: 1,
      MealSlot.dinner: 1,
    },
    FoodGroup.vegetal: {MealSlot.lunch: 1, MealSlot.dinner: 1},
  };

  final out = {for (final s in slots) s: <FoodGroup, double>{}};
  shares.forEach((group, parts) => _distribute(total[group], parts, group, out));

  // Frutas: una con el desayuno (o en la merienda AM) y otra por la tarde
  // (merienda PM; con 3 comidas, en el almuerzo).
  out[hasAm ? MealSlot.snackAm : MealSlot.breakfast]![FoodGroup.fruta] = 1;
  out[hasPm ? MealSlot.snackPm : MealSlot.lunch]![FoodGroup.fruta] = 1;

  return DayPortions(total, {
    for (final s in slots) s: Portions(Map.of(out[s]!)),
  });
}

/// Reparte [amount] en medias porciones según [parts], sin perder ni sobrar
/// (método del mayor residuo).
void _distribute(double amount, Map<MealSlot, double> parts, FoodGroup group,
    Map<MealSlot, Map<FoodGroup, double>> out) {
  final sum = parts.values.fold(0.0, (a, b) => a + b);
  final halves = (amount * 2).round();
  final exact = {
    for (final e in parts.entries) e.key: halves * e.value / sum,
  };
  final floor = {for (final e in exact.entries) e.key: e.value.floor()};
  var left = halves - floor.values.fold(0, (a, b) => a + b);
  final byRemainder = exact.keys.toList()
    ..sort((a, b) =>
        (exact[b]! - floor[b]!).compareTo(exact[a]! - floor[a]!));
  for (final s in byRemainder) {
    if (left <= 0) break;
    floor[s] = floor[s]! + 1;
    left--;
  }
  for (final e in floor.entries) {
    out[e.key]![group] = e.value / 2;
  }
}
