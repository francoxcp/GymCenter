import 'package:flutter/material.dart';

/// Design system spacing constants for consistent UI
class AppSpacing {
  // Base spacing unit (4px)
  static const double unit = 4.0;

  // Common spacing values
  static const double xs = unit; // 4px
  static const double sm = unit * 2; // 8px
  static const double md = unit * 3; // 12px
  static const double lg = unit * 4; // 16px
  static const double xl = unit * 5; // 20px
  static const double xxl = unit * 6; // 24px
  static const double xxxl = unit * 7; // 28px
  static const double huge = unit * 8; // 32px

  // Padding presets
  static const double screenPaddingHorizontal = xl; // 20px
  static const double screenPaddingVertical = xl; // 20px
  static const double cardPadding = lg; // 16px
  static const double listItemPadding = md; // 12px

  // Margins
  static const double sectionMargin = xxl; // 24px
  static const double itemMargin = md; // 12px

  // Border radius
  static const double radiusXs = xs; // 4px
  static const double radiusSm = sm; // 8px
  static const double radiusMd = md; // 12px
  static const double radiusLg = lg; // 16px
  static const double radiusXl = xl; // 20px
  static const double radiusFull = 999; // Fully rounded

  // Icon sizes
  static const double iconXs = 16.0;
  static const double iconSm = 20.0;
  static const double iconMd = 24.0;
  static const double iconLg = 28.0;
  static const double iconXl = 32.0;
  static const double iconXxl = 40.0;

  // Button heights
  static const double buttonHeightSm = 36.0;
  static const double buttonHeightMd = 44.0;
  static const double buttonHeightLg = 52.0;
}

/// Typography scale constants
class AppTypography {
  // Font sizes
  static const double fontXs = 10.0;
  static const double fontSm = 12.0;
  static const double fontMd = 14.0;
  static const double fontLg = 16.0;
  static const double fontXl = 18.0;
  static const double fontXxl = 20.0;
  static const double font3xl = 24.0;
  static const double font4xl = 28.0;
  static const double font5xl = 32.0;

  // Line heights
  static const double lineHeightTight = 1.2;
  static const double lineHeightNormal = 1.5;
  static const double lineHeightRelaxed = 1.75;

  // Letter spacing
  static const double letterSpacingTight = -0.5;
  static const double letterSpacingNormal = 0.0;
  static const double letterSpacingWide = 0.5;
  static const double letterSpacingWider = 1.0;
  static const double letterSpacingWidest = 1.5;
}

/// Animation duration constants
class AppDurations {
  static const int fast = 150;
  static const int normal = 200;
  static const int medium = 300;
  static const int slow = 400;
  static const int slower = 600;
  static const int slowest = 800;
}

/// Animation curve presets
class AppCurves {
  // All curves are from Flutter's Curves class
  static const easeIn = Curves.easeIn;
  static const easeOut = Curves.easeOut;
  static const easeInOut = Curves.easeInOut;
  static const easeOutCubic = Curves.easeOutCubic;
  static const easeInCubic = Curves.easeInCubic;
  static const bounceOut = Curves.bounceOut;
  static const elasticOut = Curves.elasticOut;
}

/// Shadow presets
class AppShadows {
  static List<BoxShadow> get sm => [
        BoxShadow(
          color: const Color(0xFF000000).withOpacity(0.05),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get md => [
        BoxShadow(
          color: const Color(0xFF000000).withOpacity(0.1),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get lg => [
        BoxShadow(
          color: const Color(0xFF000000).withOpacity(0.15),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get xl => [
        BoxShadow(
          color: const Color(0xFF000000).withOpacity(0.2),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];
}
