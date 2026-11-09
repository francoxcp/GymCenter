/// Estimación de calorías de un entreno.
///
/// Usa el gasto en reposo de la persona (Mifflin-St Jeor, la fórmula más
/// precisa para adultos) y los MET del Compendio de Actividad Física:
///   kcal = (BMR / 1440) × MET × minutos
/// Con BMR propio, 1 MET equivale al gasto en reposo de esa persona (MET
/// corregido), que acerca la estimación más que usar 3,5 ml/kg/min fijo.
class CalorieEstimator {
  CalorieEstimator._();

  /// Pesas: 5,0 (moderado). Cardio: 8,0 (vigoroso). Mezcla proporcional.
  static double metFor({double cardioRatio = 0}) =>
      5.0 + 3.0 * cardioRatio.clamp(0.0, 1.0);

  /// Gasto en reposo (kcal/día). Sin sexo conocido se promedia.
  static double bmr({
    required double weightKg,
    required double heightCm,
    required int age,
    String? sex,
  }) {
    final base = 10 * weightKg + 6.25 * heightCm - 5 * age;
    return switch (sex) {
      'male' => base + 5,
      'female' => base - 161,
      _ => base - 78,
    };
  }

  static int estimate({
    required int minutes,
    double? weightKg,
    double? heightCm,
    int? age,
    String? sex,
    double cardioRatio = 0,
  }) {
    if (minutes <= 0) return 0;
    final b = bmr(
      weightKg: weightKg ?? 70,
      heightCm: heightCm ?? 170,
      age: age ?? 30,
      sex: sex,
    );
    return ((b / 1440) * metFor(cardioRatio: cardioRatio) * minutes).round();
  }
}
