import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color primary = Color(0xFFFFEB00); // Amarillo Chamos
  static const Color background = Color(0xFF0A0A0A); // Negro
  static const Color surface = Color(0xFF1A1A1A); // Gris oscuro
  static const Color cardBackground = Color(0xFF1E1E1E);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color error = Color(0xFFFF5252);
  static const Color success = Color(0xFF4CAF50);

  // Badges
  static const Color badgePrincipiante = Color(0xFFFFEB00);
  static const Color badgeIntermedio = Color(0xFFFF9800);
  static const Color badgeAvanzado = Color(0xFFE91E63);
}

/// Sistema de espaciado consistente
class AppSpacing {
  static const double xs = 4.0; // Extra small
  static const double sm = 8.0; // Small
  static const double md = 12.0; // Medium
  static const double lg = 16.0; // Large
  static const double xl = 20.0; // Extra large
  static const double xxl = 24.0; // 2X large
  static const double xxxl = 32.0; // 3X large
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.primary,
        tertiary: AppColors.primary,
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
      textTheme: GoogleFonts.poppinsTextTheme(
        const TextTheme(
          displayLarge: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary),
          displayMedium: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary),
          displaySmall: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary),
          headlineMedium: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary),
          titleLarge: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary),
          titleMedium: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary),
          bodyLarge: TextStyle(fontSize: 16, color: AppColors.textPrimary),
          bodyMedium: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          labelLarge: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
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
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.25)),
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
        floatingLabelStyle: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardTheme(
        color: AppColors.cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
}
