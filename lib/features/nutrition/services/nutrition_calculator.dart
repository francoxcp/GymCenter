import 'dart:math' as math;

import '../models/nutrition_profile.dart';

export '../models/nutrition_profile.dart';

/// Objetivo del plan según la etiqueta guardada en `users.goal` (kGoals).
NutritionGoal goalFromLabel(String? label) => switch (label) {
      'Perder peso' => NutritionGoal.cut,
      'Ganar músculo' => NutritionGoal.gain,
      _ => NutritionGoal.maintain,
    };

/// Etiqueta de `users.goal` para un objetivo; "Mejorar salud" se conserva
/// si el socio confirma mantener.
String goalToLabel(NutritionGoal g, {String? current}) => switch (g) {
      NutritionGoal.cut => 'Perder peso',
      NutritionGoal.gain => 'Ganar músculo',
      NutritionGoal.maintain =>
        current == 'Mejorar salud' ? 'Mejorar salud' : 'Mantener peso',
    };

/// Tiempos de comida según cuántas comidas hace al día (3 a 5).
List<MealSlot> slotsFor(int mealsPerDay) => switch (mealsPerDay.clamp(3, 5)) {
      3 => const [MealSlot.breakfast, MealSlot.lunch, MealSlot.dinner],
      4 => const [
          MealSlot.breakfast,
          MealSlot.lunch,
          MealSlot.snackPm,
          MealSlot.dinner,
        ],
      _ => MealSlot.values,
    };

const _shares = {
  3: [.30, .40, .30],
  4: [.25, .35, .10, .30],
  5: [.25, .10, .30, .10, .25],
};

/// Calorías, proteína, grasa y carbohidratos del día, repartidos por comida.
///
/// Gasto en reposo: Mifflin-St Jeor. Proteína: ISSN 2017 (1,4–2,0 g/kg para
/// quien entrena; más en déficit). Menores de 18: sin déficit.
DailyTargets computeTargets(NutritionProfile p) {
  final sexTerm = switch (p.sex) { 'male' => 5.0, 'female' => -161.0, _ => -78.0 };
  final bmr = 10 * p.weightKg + 6.25 * p.heightCm - 5 * p.age + sexTerm;

  final base = switch (p.activity) {
    ActivityLevel.sedentary => 1.20,
    ActivityLevel.standing => 1.375,
    ActivityLevel.physical => 1.55,
  };
  final factor =
      math.min(base + 0.035 * p.trainingDays.clamp(0, 6), 1.9);

  final goal = p.isMinor && p.goal == NutritionGoal.cut
      ? NutritionGoal.maintain
      : p.goal;
  final goalFactor = switch (goal) {
    NutritionGoal.maintain => 1.0,
    NutritionGoal.gain => p.isMinor ? 1.05 : 1.10,
    NutritionGoal.cut => 0.80,
  };

  final floor = math.max(bmr * 1.1, p.sex == 'male' ? 1500.0 : 1200.0);
  var kcal = ((bmr * factor * goalFactor) / 50).round() * 50;
  if (kcal < floor) kcal = (floor / 50).ceil() * 50;

  final perKg = switch (goal) {
    NutritionGoal.maintain => 1.6,
    NutritionGoal.gain => 1.8,
    NutritionGoal.cut => 2.0,
  };
  final protein = math.min((perKg * p.weightKg).round(), 220);
  final fat = math.max(kcal * 0.25 / 9, 0.6 * p.weightKg).round();
  final carb = math.max(((kcal - protein * 4 - fat * 9) / 4).round(), 0);

  final slots = slotsFor(p.mealsPerDay);
  final shares = _shares[slots.length]!;
  return DailyTargets(
    kcal: kcal,
    proteinG: protein,
    fatG: fat,
    carbG: carb,
    meals: [
      for (var i = 0; i < slots.length; i++)
        MealTarget(slots[i], (kcal * shares[i]).round(),
            (protein * shares[i]).round()),
    ],
  );
}
