/// Unidad de peso de un ejercicio: depende del equipo (mancuernas en lbs,
/// máquinas o discos en kg). En la base de datos el peso siempre se guarda
/// en kg; la unidad solo decide cómo se muestra y se escribe.
enum WeightUnit {
  lbs,
  kg;

  static const double lbsPerKg = 2.20462;

  static WeightUnit parse(Object? value) =>
      value?.toString().toLowerCase() == 'kg' ? WeightUnit.kg : WeightUnit.lbs;

  String get label => this == WeightUnit.kg ? 'kg' : 'lbs';

  WeightUnit get other => this == WeightUnit.kg ? WeightUnit.lbs : WeightUnit.kg;

  /// kg → valor en esta unidad.
  double fromKg(double kg) => this == WeightUnit.kg ? kg : kg * lbsPerKg;

  /// Valor en esta unidad → kg.
  double toKg(double value) => this == WeightUnit.kg ? value : value / lbsPerKg;

  /// Paso de los botones +/− del editor.
  double get step => this == WeightUnit.kg ? 2.5 : 5;

  /// Incremento de la progresión inteligente.
  double increment({required bool lowerBody}) => this == WeightUnit.kg
      ? (lowerBody ? 5 : 2.5)
      : (lowerBody ? 10 : 5);

  /// Redondeo a lo que se puede cargar: 2.5 lbs o 1.25 kg.
  double roundToPlates(double value) {
    final inc = this == WeightUnit.kg ? 1.25 : 2.5;
    return (value / inc).round() * inc;
  }

  /// "45 kg", "22.5 lbs" (sin decimales si es entero).
  String format(double value) {
    final rounded = (value * 10).round() / 10;
    final text = rounded == rounded.roundToDouble()
        ? rounded.toInt().toString()
        : rounded.toStringAsFixed(1);
    return '$text $label';
  }

  /// Peso guardado en kg mostrado en esta unidad.
  String formatKg(double kg) => format(fromKg(kg));
}
