import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme.dart';

/// Preferencias visuales del dispositivo: tema claro/oscuro y tamaño de
/// texto. Se guardan localmente y se aplican antes del primer frame.
class AppearanceProvider extends ChangeNotifier {
  static const _kLight = 'appearance_light';
  static const _kScale = 'appearance_text_scale';

  /// Tamaños de texto ofrecidos en Ajustes.
  static final scales = <double, String>{
    1.0: 'Normal',
    1.15: 'Grande',
    1.3: 'Muy grande',
  };

  bool _light = false;
  double _textScale = 1.0;

  bool get light => _light;
  double get textScale => _textScale;

  /// Cambia cada vez que hay que reconstruir la app (cambio de paleta).
  int _revision = 0;
  int get revision => _revision;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _light = prefs.getBool(_kLight) ?? false;
      final s = prefs.getDouble(_kScale) ?? 1.0;
      _textScale = scales.containsKey(s) ? s : 1.0;
    } catch (_) {}
  }

  /// Aplica la paleta. Las pantallas de acceso siempre van en oscuro
  /// (marca), el tema claro aplica con la sesión iniciada.
  bool apply({required bool signedIn}) {
    final p = _light && signedIn ? AppPalette.light : AppPalette.dark;
    if (identical(AppColors.palette, p)) return false;
    AppColors.usePalette(p);
    _revision++;
    return true;
  }

  Future<void> setLight(bool value) async {
    if (_light == value) return;
    _light = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kLight, value);
    } catch (_) {}
  }

  Future<void> setTextScale(double value) async {
    if (_textScale == value) return;
    _textScale = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_kScale, value);
    } catch (_) {}
  }

  /// Escala final: la del sistema por la elegida, con tope para que los
  /// diseños no se rompan.
  TextScaler scalerFor(BuildContext context) {
    final system = MediaQuery.textScalerOf(context).scale(1.0);
    final v = (system * _textScale).clamp(1.0, 1.6);
    return TextScaler.linear(v);
  }
}
