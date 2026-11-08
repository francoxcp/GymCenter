import 'package:flutter/material.dart';

export 'spacing.dart';

/// Paleta de un tema (oscuro o claro).
class AppPalette {
  final Brightness brightness;
  final Color primary;
  final Color onPrimary;
  final Color background;
  final Color surface;
  final Color cardBackground;
  final Color inputFill;
  final Color textPrimary;
  final Color textSecondary;
  final Color error;
  final Color success;
  final Color warning;

  const AppPalette({
    required this.brightness,
    required this.primary,
    required this.onPrimary,
    required this.background,
    required this.surface,
    required this.cardBackground,
    required this.inputFill,
    required this.textPrimary,
    required this.textSecondary,
    required this.error,
    required this.success,
    required this.warning,
  });

  static const dark = AppPalette(
    brightness: Brightness.dark,
    primary: Color(0xFFFFEB00), // Amarillo Chamos
    onPrimary: Color(0xFF000000),
    background: Color(0xFF0A0A0A),
    surface: Color(0xFF1A1A1A),
    cardBackground: Color(0xFF1E1E1E),
    inputFill: Color(0xFF252525),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFB0B0B0), // 7.7:1 sobre las tarjetas
    error: Color(0xFFFF5252),
    success: Color(0xFF4CAF50),
    warning: Color(0xFFFFA726),
  );

  /// Tema claro: el amarillo de marca no se lee sobre blanco, así que como
  /// color de acento se usa un dorado oscuro (≥3:1 sobre blanco y 6.5:1 con
  /// texto negro encima), según WCAG para iconos y texto grande.
  static const light = AppPalette(
    brightness: Brightness.light,
    primary: Color(0xFFAD8B00),
    onPrimary: Color(0xFF000000),
    background: Color(0xFFF4F4F6),
    surface: Color(0xFFFFFFFF),
    cardBackground: Color(0xFFFFFFFF),
    inputFill: Color(0xFFF0F0F2),
    textPrimary: Color(0xFF141414),
    textSecondary: Color(0xFF55595F), // 6.9:1 sobre blanco
    error: Color(0xFFC62828),
    success: Color(0xFF2E7D32),
    warning: Color(0xFFB45309),
  );
}

/// Colores de la app. Son dinámicos: dependen del tema elegido en Ajustes
/// (ver AppearanceProvider). Al cambiar de tema se reconstruye la app.
class AppColors {
  AppColors._();

  static AppPalette _p = AppPalette.dark;
  static AppPalette get palette => _p;
  static bool get isLight => _p.brightness == Brightness.light;
  static void usePalette(AppPalette p) => _p = p;

  static Color get primary => _p.primary;
  static Color get onPrimary => _p.onPrimary;
  static Color get background => _p.background;
  static Color get surface => _p.surface;
  static Color get cardBackground => _p.cardBackground;
  static Color get inputFill => _p.inputFill;
  static Color get textPrimary => _p.textPrimary;
  static Color get textSecondary => _p.textSecondary;
  static Color get error => _p.error;
  static Color get success => _p.success;
  static Color get warning => _p.warning;

  // Badges de nivel
  static Color get badgePrincipiante => _p.primary;
  static const Color badgeIntermedio = Color(0xFFFF9800);
  static const Color badgeAvanzado = Color(0xFFE91E63);
}

/// Tema de Material construido con la paleta activa.
ThemeData buildAppTheme() {
  final p = AppColors.palette;
  final dark = p.brightness == Brightness.dark;
  final outline = p.textPrimary.withValues(alpha: dark ? 0.25 : 0.22);
  return ThemeData(
    brightness: p.brightness,
    useMaterial3: true,
    scaffoldBackgroundColor: p.background,
    colorScheme: ColorScheme(
      brightness: p.brightness,
      primary: p.primary,
      onPrimary: p.onPrimary,
      secondary: p.primary,
      onSecondary: p.onPrimary,
      tertiary: p.primary,
      onTertiary: p.onPrimary,
      tertiaryContainer: p.surface,
      secondaryContainer: p.surface,
      surface: p.surface,
      onSurface: p.textPrimary,
      error: p.error,
      onError: Colors.white,
      outline: p.textPrimary.withValues(alpha: 0.25),
      outlineVariant: p.textPrimary.withValues(alpha: 0.16),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: p.background,
      foregroundColor: p.textPrimary,
      elevation: 0,
      iconTheme: IconThemeData(color: p.textPrimary),
      titleTextStyle: TextStyle(
        color: p.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: CardThemeData(
      color: p.cardBackground,
      elevation: dark ? 0 : 1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    dialogTheme: DialogThemeData(backgroundColor: p.surface),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: p.surface),
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: p.textPrimary),
      bodyMedium: TextStyle(color: p.textPrimary),
      bodySmall: TextStyle(color: p.textSecondary),
    ),
    // Objetivos táctiles de al menos 48×48 (accesibilidad)
    materialTapTargetSize: MaterialTapTargetSize.padded,
    visualDensity: VisualDensity.standard,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.inputFill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: outline, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: outline, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: p.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: p.error, width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            BorderSide(color: p.textPrimary.withValues(alpha: 0.1), width: 1),
      ),
      // Antes 25 % de opacidad (contraste insuficiente); ahora ≥4.5:1
      hintStyle: TextStyle(color: p.textSecondary),
      labelStyle: TextStyle(color: p.textSecondary),
      floatingLabelStyle: TextStyle(
        color: p.primary,
        fontWeight: FontWeight.w600,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
  );
}

class AppTheme {}
