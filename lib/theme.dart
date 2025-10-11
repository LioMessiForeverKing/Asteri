import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Asteria App Theme
/// Paper-inspired animated cartoon aesthetic with warm, inviting colors
class AsteriaTheme {
  // ==================== COLOR PALETTE ====================

  // Background Colors - Warm paper tones
  static const Color backgroundPrimary = Color(0xFFFFFBF5);
  static const Color backgroundSecondary = Color(0xFFFFF8F0);
  static const Color backgroundTertiary = Color(0xFFFFF4E6);

  // Primary Colors - Warm coral/terracotta
  static const Color primaryColor = Color(0xFFE57A6F);
  static const Color primaryLight = Color(0xFFFF8B7B);
  static const Color primaryDark = Color(0xFFD0685E);

  // Secondary Colors - Soft purple
  static const Color secondaryColor = Color(0xFFB8A9D4);
  static const Color secondaryLight = Color(0xFFC9BFDF);
  static const Color secondaryDark = Color(0xFFA394C3);

  // Accent Colors - Playful yellow/gold
  static const Color accentColor = Color(0xFFFFD166);
  static const Color accentLight = Color(0xFFFFE699);
  static const Color accentDark = Color(0xFFE6BC5C);

  // Text Colors - Warm, readable tones
  static const Color textPrimary = Color(0xFF2D3142);
  static const Color textSecondary = Color(0xFF75747C);
  static const Color textTertiary = Color(0xFFA8A7AE);
  static const Color textOnPrimary = Color(0xFFFFFBF5);

  // Additional Colors
  static const Color successColor = Color(0xFF8FCB9B);
  static const Color warningColor = Color(0xFFFFB84D);
  static const Color errorColor = Color(0xFFE8747C);
  static const Color infoColor = Color(0xFF82B4D4);

  // Shadow Colors - Warm, soft shadows
  static const Color shadowLight = Color(0x15D0685E);
  static const Color shadowMedium = Color(0x25D0685E);
  static const Color shadowDark = Color(0x35D0685E);

  // ==================== BORDER RADIUS ====================
  static const double radiusSmall = 12.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 24.0;
  static const double radiusXLarge = 32.0;

  // ==================== SPACING ====================
  static const double spacingXSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;
  static const double spacingXXLarge = 48.0;

  // ==================== ELEVATION ====================
  static const double elevationLow = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationHigh = 8.0;
  static const double elevationXHigh = 12.0;

  // ==================== TEXT STYLES ====================

  // Display Styles - Quicksand
  static const TextStyle displayLarge = TextStyle(
    fontFamily: 'Quicksand',
    fontSize: 57,
    fontWeight: FontWeight.w700,
    height: 1.15,
    letterSpacing: -0.25,
    color: textPrimary,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: 'Quicksand',
    fontSize: 45,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: textPrimary,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: 'Quicksand',
    fontSize: 36,
    fontWeight: FontWeight.w600,
    height: 1.25,
    color: textPrimary,
  );

  // Headline Styles - Quicksand
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: 'Quicksand',
    fontSize: 32,
    fontWeight: FontWeight.w600,
    height: 1.25,
    color: textPrimary,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: 'Quicksand',
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: textPrimary,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: 'Quicksand',
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.35,
    color: textPrimary,
  );

  // Title Styles - Quicksand
  static const TextStyle titleLarge = TextStyle(
    fontFamily: 'Quicksand',
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.35,
    color: textPrimary,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: 'Quicksand',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5,
    letterSpacing: 0.15,
    color: textPrimary,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: 'Quicksand',
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.45,
    letterSpacing: 0.1,
    color: textPrimary,
  );

  // Body Styles - Figtree
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'Figtree',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.5,
    color: textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'Figtree',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.45,
    letterSpacing: 0.25,
    color: textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: 'Figtree',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: 0.4,
    color: textSecondary,
  );

  // Label Styles - Quicksand
  static const TextStyle labelLarge = TextStyle(
    fontFamily: 'Quicksand',
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.45,
    letterSpacing: 0.1,
    color: textPrimary,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: 'Quicksand',
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.35,
    letterSpacing: 0.5,
    color: textPrimary,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: 'Quicksand',
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.45,
    letterSpacing: 0.5,
    color: textSecondary,
  );

  // ==================== THEME DATA ====================

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Color Scheme
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: primaryColor,
        onPrimary: textOnPrimary,
        primaryContainer: primaryLight,
        onPrimaryContainer: textPrimary,
        secondary: secondaryColor,
        onSecondary: textOnPrimary,
        secondaryContainer: secondaryLight,
        onSecondaryContainer: textPrimary,
        tertiary: accentColor,
        onTertiary: textPrimary,
        tertiaryContainer: accentLight,
        onTertiaryContainer: textPrimary,
        error: errorColor,
        onError: textOnPrimary,
        errorContainer: Color(0xFFF8D7DA),
        onErrorContainer: textPrimary,
        surface: backgroundPrimary,
        onSurface: textPrimary,
        surfaceContainerHighest: backgroundSecondary,
        onSurfaceVariant: textSecondary,
        outline: Color(0xFFD4CFC9),
        outlineVariant: Color(0xFFE8E4DE),
        shadow: shadowMedium,
        scrim: Color(0x50000000),
        inverseSurface: textPrimary,
        onInverseSurface: backgroundPrimary,
        inversePrimary: primaryLight,
      ),

      // Scaffold Background
      scaffoldBackgroundColor: backgroundPrimary,

      // Text Theme
      textTheme: const TextTheme(
        displayLarge: displayLarge,
        displayMedium: displayMedium,
        displaySmall: displaySmall,
        headlineLarge: headlineLarge,
        headlineMedium: headlineMedium,
        headlineSmall: headlineSmall,
        titleLarge: titleLarge,
        titleMedium: titleMedium,
        titleSmall: titleSmall,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
        labelLarge: labelLarge,
        labelMedium: labelMedium,
        labelSmall: labelSmall,
      ),

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: elevationMedium,
        centerTitle: false,
        backgroundColor: backgroundPrimary,
        foregroundColor: textPrimary,
        surfaceTintColor: Colors.transparent,
        shadowColor: shadowMedium,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          fontFamily: 'Quicksand',
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
      ),

      // Card Theme - Paper-like cards
      cardTheme: CardThemeData(
        elevation: elevationMedium,
        color: backgroundSecondary,
        surfaceTintColor: Colors.transparent,
        shadowColor: shadowMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
        margin: const EdgeInsets.all(spacingSmall),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: elevationMedium,
          backgroundColor: primaryColor,
          foregroundColor: textOnPrimary,
          disabledBackgroundColor: textTertiary,
          disabledForegroundColor: backgroundPrimary,
          shadowColor: shadowMedium,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLarge,
            vertical: spacingMedium,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Quicksand',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          disabledForegroundColor: textTertiary,
          side: const BorderSide(color: primaryColor, width: 2),
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLarge,
            vertical: spacingMedium,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Quicksand',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          disabledForegroundColor: textTertiary,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingMedium,
            vertical: spacingSmall,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Quicksand',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: elevationHigh,
        backgroundColor: accentColor,
        foregroundColor: textPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(radiusMedium)),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: backgroundSecondary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingMedium,
          vertical: spacingMedium,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: Color(0xFFE8E4DE), width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: Color(0xFFE8E4DE), width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: errorColor, width: 2.5),
        ),
        labelStyle: const TextStyle(
          fontFamily: 'Figtree',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
        hintStyle: const TextStyle(
          fontFamily: 'Figtree',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textTertiary,
        ),
        errorStyle: const TextStyle(
          fontFamily: 'Figtree',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: errorColor,
        ),
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        elevation: elevationXHigh,
        backgroundColor: backgroundPrimary,
        surfaceTintColor: Colors.transparent,
        shadowColor: shadowDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
        titleTextStyle: const TextStyle(
          fontFamily: 'Quicksand',
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        contentTextStyle: const TextStyle(
          fontFamily: 'Figtree',
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: const BottomSheetThemeData(
        elevation: elevationXHigh,
        backgroundColor: backgroundPrimary,
        surfaceTintColor: Colors.transparent,
        shadowColor: shadowDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(radiusLarge),
          ),
        ),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: backgroundSecondary,
        selectedColor: primaryLight,
        disabledColor: textTertiary,
        secondarySelectedColor: secondaryLight,
        padding: const EdgeInsets.symmetric(
          horizontal: spacingMedium,
          vertical: spacingSmall,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        labelStyle: const TextStyle(
          fontFamily: 'Quicksand',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        secondaryLabelStyle: const TextStyle(
          fontFamily: 'Quicksand',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE8E4DE),
        thickness: 1,
        space: spacingMedium,
      ),

      // Icon Theme
      iconTheme: const IconThemeData(color: textPrimary, size: 24),

      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return textTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryLight;
          }
          return Color(0xFFE8E4DE);
        }),
      ),

      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(textOnPrimary),
        side: const BorderSide(color: primaryColor, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      // Radio Theme
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return textSecondary;
        }),
      ),

      // Slider Theme
      sliderTheme: const SliderThemeData(
        activeTrackColor: primaryColor,
        inactiveTrackColor: Color(0xFFE8E4DE),
        thumbColor: primaryColor,
        overlayColor: Color(0x20E57A6F),
        valueIndicatorColor: primaryColor,
        valueIndicatorTextStyle: TextStyle(
          fontFamily: 'Quicksand',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textOnPrimary,
        ),
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryColor,
        linearTrackColor: Color(0xFFE8E4DE),
        circularTrackColor: Color(0xFFE8E4DE),
      ),

      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textPrimary,
        contentTextStyle: const TextStyle(
          fontFamily: 'Figtree',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: backgroundPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: elevationMedium,
      ),

      // Tooltip Theme
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: textPrimary,
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Figtree',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: backgroundPrimary,
        ),
      ),
    );
  }

  // ==================== CUSTOM DECORATIONS ====================

  /// Paper card decoration with warm shadows
  static BoxDecoration paperCardDecoration({
    Color? backgroundColor,
    double? elevation,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? backgroundSecondary,
      borderRadius: BorderRadius.circular(radiusLarge),
      boxShadow: [
        BoxShadow(
          color: shadowMedium,
          offset: Offset(0, elevation ?? elevationMedium),
          blurRadius: (elevation ?? elevationMedium) * 2,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: shadowLight,
          offset: Offset(0, (elevation ?? elevationMedium) / 2),
          blurRadius: elevation ?? elevationMedium,
          spreadRadius: -1,
        ),
      ],
    );
  }

  /// Elevated paper decoration with higher shadow
  static BoxDecoration elevatedPaperDecoration({Color? backgroundColor}) {
    return BoxDecoration(
      color: backgroundColor ?? backgroundPrimary,
      borderRadius: BorderRadius.circular(radiusLarge),
      boxShadow: const [
        BoxShadow(
          color: shadowDark,
          offset: Offset(0, elevationHigh),
          blurRadius: elevationHigh * 2,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: shadowMedium,
          offset: Offset(0, elevationMedium),
          blurRadius: elevationMedium * 2,
          spreadRadius: -2,
        ),
      ],
    );
  }

  /// Subtle inner shadow decoration (for pressed states)
  static BoxDecoration insetPaperDecoration({Color? backgroundColor}) {
    return BoxDecoration(
      color: backgroundColor ?? backgroundTertiary,
      borderRadius: BorderRadius.circular(radiusMedium),
      boxShadow: const [
        BoxShadow(
          color: shadowLight,
          offset: Offset(0, 2),
          blurRadius: 4,
          spreadRadius: -2,
        ),
      ],
    );
  }

  /// Gradient overlay for special sections
  static BoxDecoration gradientOverlayDecoration({List<Color>? colors}) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors:
            colors ??
            [backgroundPrimary, backgroundSecondary, backgroundTertiary],
      ),
      borderRadius: BorderRadius.circular(radiusLarge),
    );
  }
}
