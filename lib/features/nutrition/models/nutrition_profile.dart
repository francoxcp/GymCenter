import '../services/portions.dart';

/// Objetivo del plan de alimentación.
enum NutritionGoal { maintain, gain, cut }

/// Actividad fuera del gimnasio.
enum ActivityLevel {
  sedentary,
  standing,
  physical;

  /// Valor guardado en `users.activity_level`.
  String get db => name;

  static ActivityLevel? fromDb(String? v) {
    for (final a in values) {
      if (a.name == v) return a;
    }
    return null;
  }
}

/// Tiempos de comida del día, en orden.
enum MealSlot {
  breakfast('Desayuno'),
  snackAm('Merienda'),
  lunch('Almuerzo'),
  snackPm('Merienda'),
  dinner('Cena');

  const MealSlot(this.label);
  final String label;
}

/// Datos con los que se calcula el plan de un socio.
class NutritionProfile {
  final double weightKg;
  final int heightCm;
  final int age;
  final String sex; // 'male' | 'female' | 'other'
  final NutritionGoal goal;
  final ActivityLevel activity;
  final int trainingDays;
  final int mealsPerDay;
  final Set<String> avoid;

  const NutritionProfile({
    required this.weightKg,
    required this.heightCm,
    required this.age,
    required this.sex,
    required this.goal,
    required this.activity,
    required this.trainingDays,
    required this.mealsPerDay,
    this.avoid = const {},
  });

  bool get isMinor => age < 18;

  NutritionProfile copyWith({
    NutritionGoal? goal,
    double? weightKg,
    Set<String>? avoid,
  }) =>
      NutritionProfile(
        weightKg: weightKg ?? this.weightKg,
        heightCm: heightCm,
        age: age,
        sex: sex,
        goal: goal ?? this.goal,
        activity: activity,
        trainingDays: trainingDays,
        mealsPerDay: mealsPerDay,
        avoid: avoid ?? this.avoid,
      );
}

/// Calorías y proteína de un tiempo de comida.
class MealTarget {
  final MealSlot slot;
  final int kcal;
  final int proteinG;

  /// Porciones de intercambio de esta comida (las usa el recetario).
  final Portions? portions;
  const MealTarget(this.slot, this.kcal, this.proteinG, {this.portions});
}

/// Objetivos del día completo.
class DailyTargets {
  final int kcal;
  final int proteinG;
  final int fatG;
  final int carbG;
  final List<MealTarget> meals;
  const DailyTargets({
    required this.kcal,
    required this.proteinG,
    required this.fatG,
    required this.carbG,
    required this.meals,
  });
}
