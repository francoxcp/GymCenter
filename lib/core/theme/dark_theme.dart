import 'package:flutter/material.dart';

class AppColors {
  // Background colors
  static const Color background = Color(0xFF0F0F0F);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color cardBackground = Color(0xFF1E1E1E);

  // Primary color
  static const Color primary = Color(0xFFFFEB00);

  // Text colors
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF9E9E9E);

  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFEF5350);
  static const Color warning = Color(0xFFFFA726);

  // Badge colors
  static const Color badgePrincipiante = Color(0xFF4CAF50);
  static const Color badgeIntermedio = Color(0xFFFFA726);
  static const Color badgeAvanzado = Color(0xFFEF5350);
}

final darkTheme = ThemeData(
  brightness: Brightness.dark,
  useMaterial3: true,
  scaffoldBackgroundColor: AppColors.background,
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFFFFEB00),
    secondary: Color(0xFFFFEB00),
    tertiary: Color(0xFFFFEB00),
    tertiaryContainer: AppColors.surface,
    secondaryContainer: AppColors.surface,
    surface: AppColors.surface,
    error: AppColors.error,
    onPrimary: Colors.black,
    onSecondary: Colors.black,
    onTertiary: Colors.black,
    onSurface: AppColors.textPrimary,
    outline: Color(0x40FFFFFF),
    outlineVariant: Color(0x28FFFFFF),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.background,
    elevation: 0,
    iconTheme: IconThemeData(color: Colors.white),
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  ),
  cardTheme: const CardTheme(
    color: AppColors.cardBackground,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: AppColors.textPrimary),
    bodyMedium: TextStyle(color: AppColors.textPrimary),
    bodySmall: TextStyle(color: AppColors.textSecondary),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF252525),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.25), width: 1.5),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.25), width: 1.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.error, width: 1.5),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1),
    ),
    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.25)),
    labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
    floatingLabelStyle: const TextStyle(
      color: AppColors.primary,
      fontWeight: FontWeight.w600,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  ),
);
