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

  /// MET de la sesión según cómo se entrenó de verdad (Compendio de
  /// Actividad Física 2024):
  ///  - Pesas con descansos largos (≤ 0,2 series/min) → 3,5 (ligero/moderado).
  ///  - Ritmo alto (≥ 0,45 series/min) → 6,0 (vigoroso). Entre ambos, lineal.
  ///  - Superseries: menos descanso, suben hasta +0,5 (máximo 6,0).
  ///  - Cardio (8,0) se mezcla en proporción a los ejercicios de cardio.
  static double metForSession({
    required int setsDone,
    required double minutes,
    double cardioRatio = 0,
    double supersetRatio = 0,
  }) {
    if (minutes <= 0) return metFor(cardioRatio: cardioRatio);
    final density = setsDone / minutes;
    final t = ((density - 0.2) / (0.45 - 0.2)).clamp(0.0, 1.0);
    final strength =
        (3.5 + 2.5 * t + 0.5 * supersetRatio.clamp(0.0, 1.0)).clamp(3.5, 6.0);
    final c = cardioRatio.clamp(0.0, 1.0);
    return strength * (1 - c) + 8.0 * c;
  }

  /// Igual que [estimate] pero con la duración en segundos y un MET ya
  /// calculado (p. ej. con [metForSession]).
  static int estimateSession({
    required int seconds,
    required double met,
    double? weightKg,
    double? heightCm,
    int? age,
    String? sex,
  }) {
    if (seconds <= 0) return 0;
    final b = bmr(
      weightKg: weightKg ?? 70,
      heightCm: heightCm ?? 170,
      age: age ?? 30,
      sex: sex,
    );
    return ((b / 1440) * met * (seconds / 60)).round();
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
