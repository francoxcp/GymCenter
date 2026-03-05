/// Utility for converting between metric and imperial units.
class UnitConverter {
  static const double _kgToLbs = 2.20462;
  static const double _cmToIn = 0.393701;

  //  Unit labels
  static String weightUnit(String units) => units == 'imperial' ? 'lbs' : 'kg';

  static String lengthUnit(String units) => units == 'imperial' ? 'in' : 'cm';

  //  Conversion
  static double convertWeight(double kg, String units) =>
      units == 'imperial' ? kg * _kgToLbs : kg;

  static double convertLength(double cm, String units) =>
      units == 'imperial' ? cm * _cmToIn : cm;

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

  static String formatLength(double cm, String units, {int decimals = 1}) {
    final val = convertLength(cm, units);
    return '${val.toStringAsFixed(decimals)} ${lengthUnit(units)}';
  }

  static String formatLengthChange(double cmDelta, String units,
      {int decimals = 1}) {
    final val = convertLength(cmDelta, units);
    final sign = val > 0 ? '+' : '';
    return '$sign${val.toStringAsFixed(decimals)} ${lengthUnit(units)}';
  }

  /// Display value only (no unit label), converted from kg.
  static String weightValue(double kg, String units, {int decimals = 1}) =>
      convertWeight(kg, units).toStringAsFixed(decimals);

  /// Display value only (no unit label), converted from cm.
  static String lengthValue(double cm, String units, {int decimals = 1}) =>
      convertLength(cm, units).toStringAsFixed(decimals);
}
