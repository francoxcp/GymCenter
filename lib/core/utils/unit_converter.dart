/// Utility for converting between metric and imperial units.
class UnitConverter {
  static const double _kgToLbs = 2.20462;

  //  Unit labels
  static String weightUnit(String units) => units == 'imperial' ? 'lbs' : 'kg';

  //  Conversion
  static double convertWeight(double kg, String units) =>
      units == 'imperial' ? kg * _kgToLbs : kg;

  //  Formatted strings
  static String formatWeight(double kg, String units, {int decimals = 1}) {
    final val = convertWeight(kg, units);
    return '${val.toStringAsFixed(decimals)} ${weightUnit(units)}';
  }

  static String formatWeightChange(double kgDelta, String units,
      {int decimals = 1}) {
    final val = convertWeight(kgDelta, units);
    final sign = val > 0 ? '+' : '';
    return '$sign${val.toStringAsFixed(decimals)} ${weightUnit(units)}';
  }

  /// Display value only (no unit label), converted from kg.
  static String weightValue(double kg, String units, {int decimals = 1}) =>
      convertWeight(kg, units).toStringAsFixed(decimals);

}
