import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Asteria App Theme
/// Sophisticated minimalist aesthetic with warm, elegant colors
class AsteriaTheme {
  // ==================== COLOR PALETTE ====================

  // Background Colors - Warm, sophisticated tones
  static const Color backgroundPrimary = Color(0xFFF8F5F0); // Warm beige/cream
  static const Color backgroundSecondary = Color(
    0xFFF5F2ED,
  ); // Slightly darker beige
  static const Color backgroundTertiary = Color(0xFFF0EDE8); // Subtle variation

  // Primary Colors - Rich terracotta/burnt orange
  static const Color primaryColor = Color(0xFFA0522D); // Terracotta
  static const Color primaryLight = Color(0xFFCD5C5C); // Lighter terracotta
  static const Color primaryDark = Color(0xFF8B4513); // Darker terracotta

  // Secondary Colors - Sophisticated charcoal
  static const Color secondaryColor = Color(0xFF2F2F2F); // Dark charcoal
  static const Color secondaryLight = Color(0xFF4A4A4A); // Medium charcoal
  static const Color secondaryDark = Color(0xFF1A1A1A); // Dark charcoal

  // Accent Colors - Clean white for contrast
  static const Color accentColor = Color(0xFFFFFFFF); // Pure white
  static const Color accentLight = Color(0xFFF8F8F8); // Off-white
  static const Color accentDark = Color(0xFFE8E8E8); // Light grey

  // Text Colors - Sophisticated, readable tones
  static const Color textPrimary = Color(0xFF1A1A1A); // Dark charcoal
  static const Color textSecondary = Color(0xFF4A4A4A); // Medium grey
  static const Color textTertiary = Color(0xFF757575); // Light grey
  static const Color textOnPrimary = Color(0xFFFFFFFF); // White on dark

  // Dark Mode Palette
  static const Color backgroundPrimaryDark = Color(0xFF0F0F0F);
  static const Color backgroundSecondaryDark = Color(0xFF181818);
  static const Color backgroundTertiaryDark = Color(0xFF202020);
  static const Color accentColorDark = Color(0xFFFFFFFF);
  static const Color textPrimaryDark = Color(0xFFF5F5F5);
  static const Color textSecondaryDark = Color(0xFFB9B9B9);
  static const Color textTertiaryDark = Color(0xFF8C8C8C);

  // Additional Colors - Muted, sophisticated
  static const Color successColor = Color(0xFF4CAF50); // Clean green
  static const Color warningColor = Color(0xFFFF9800); // Orange
  static const Color errorColor = Color(0xFFE57373); // Soft red
  static const Color infoColor = Color(0xFF64B5F6); // Clean blue

  // Shadow Colors - Subtle, clean shadows
  static const Color shadowLight = Color(0x0A000000); // Very light black
  static const Color shadowMedium = Color(0x15000000); // Light black
  static const Color shadowDark = Color(0x25000000); // Medium black

  // ==================== BORDER RADIUS ====================
  static const double radiusSmall = 8.0; // Subtle rounding
  static const double radiusMedium = 12.0; // Standard rounding
  static const double radiusLarge = 16.0; // Generous rounding
  static const double radiusXLarge = 24.0; // Pill-shaped elements

  // ==================== SPACING ====================
  static const double spacingXSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;
  static const double spacingXXLarge = 48.0;

  // ==================== ELEVATION ====================
  static const double elevationLow = 1.0; // Subtle elevation
  static const double elevationMedium = 2.0; // Standard elevation
  static const double elevationHigh = 4.0; // High elevation
  static const double elevationXHigh = 8.0; // Maximum elevation

  // ==================== TEXT STYLES ====================

  // Display Styles - Serif for elegance
  static const TextStyle displayLarge = TextStyle(
    fontFamily: 'Playfair Display', // Elegant serif
    fontSize: 57,
    fontWeight: FontWeight.w400, // Lighter weight for sophistication
    height: 1.1,
    letterSpacing: -0.5,
    color: textPrimary,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: 'Playfair Display',
    fontSize: 45,
    fontWeight: FontWeight.w400,
    height: 1.15,
    letterSpacing: -0.25,
    color: textPrimary,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: 'Playfair Display',
    fontSize: 36,
    fontWeight: FontWeight.w400,
    height: 1.2,
    color: textPrimary,
  );

  // Headline Styles - Serif for main headings
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: 'Playfair Display',
    fontSize: 32,
    fontWeight: FontWeight.w400,
    height: 1.2,
    color: textPrimary,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: 'Playfair Display',
    fontSize: 28,
    fontWeight: FontWeight.w400,
    height: 1.25,
    color: textPrimary,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: 'Playfair Display',
    fontSize: 24,
    fontWeight: FontWeight.w400,
    height: 1.3,
    color: textPrimary,
  );

  // Title Styles - Clean sans-serif
  static const TextStyle titleLarge = TextStyle(
    fontFamily: 'Inter', // Clean, modern sans-serif
    fontSize: 22,
    fontWeight: FontWeight.w500,
    height: 1.3,
    color: textPrimary,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.1,
    color: textPrimary,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.1,
    color: textPrimary,
  );

  // Body Styles - Clean sans-serif
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.15,
    color: textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: 0.1,
    color: textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.3,
    letterSpacing: 0.1,
    color: textSecondary,
  );

  // Label Styles - Clean sans-serif
  static const TextStyle labelLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.1,
    color: textPrimary,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.3,
    letterSpacing: 0.1,
    color: textPrimary,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: 'Inter',
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.3,
    letterSpacing: 0.1,
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

      // AppBar Theme - Clean and minimal
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: elevationLow,
        centerTitle: false,
        backgroundColor: backgroundPrimary,
        foregroundColor: textPrimary,
        surfaceTintColor: Colors.transparent,
        shadowColor: shadowLight,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          fontFamily: 'Playfair Display',
          fontSize: 24,
          fontWeight: FontWeight.w400,
          color: textPrimary,
        ),
      ),

      // Card Theme - Clean, minimal cards
      cardTheme: CardThemeData(
        elevation: elevationLow,
        color: backgroundSecondary,
        surfaceTintColor: Colors.transparent,
        shadowColor: shadowLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        margin: const EdgeInsets.all(spacingSmall),
      ),

      // Elevated Button Theme - Dark sophisticated style
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: elevationLow,
          backgroundColor: secondaryColor, // Dark charcoal background
          foregroundColor: accentColor, // White text
          disabledBackgroundColor: textTertiary,
          disabledForegroundColor: backgroundPrimary,
          shadowColor: shadowMedium,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingXLarge,
            vertical: spacingMedium,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusXLarge), // Pill shape
            side: const BorderSide(
              color: Color(0xFFE0E0E0),
              width: 1,
            ), // Light border
          ),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
          ),
        ),
      ),

      // Outlined Button Theme - Terracotta outline
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          disabledForegroundColor: textTertiary,
          side: const BorderSide(color: primaryColor, width: 1.5),
          padding: const EdgeInsets.symmetric(
            horizontal: spacingXLarge,
            vertical: spacingMedium,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusXLarge),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
          ),
        ),
      ),

      // Text Button Theme - Clean minimal style
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
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
          ),
        ),
      ),

      // Floating Action Button Theme - Terracotta accent
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: elevationMedium,
        backgroundColor: primaryColor, // Terracotta
        foregroundColor: accentColor, // White
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(radiusLarge)),
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

  static ThemeData get darkTheme {
    final textTheme = TextTheme(
      displayLarge: displayLarge.copyWith(color: textPrimaryDark),
      displayMedium: displayMedium.copyWith(color: textPrimaryDark),
      displaySmall: displaySmall.copyWith(color: textPrimaryDark),
      headlineLarge: headlineLarge.copyWith(color: textPrimaryDark),
      headlineMedium: headlineMedium.copyWith(color: textPrimaryDark),
      headlineSmall: headlineSmall.copyWith(color: textPrimaryDark),
      titleLarge: titleLarge.copyWith(color: textPrimaryDark),
      titleMedium: titleMedium.copyWith(color: textPrimaryDark),
      titleSmall: titleSmall.copyWith(color: textPrimaryDark),
      bodyLarge: bodyLarge.copyWith(color: textPrimaryDark),
      bodyMedium: bodyMedium.copyWith(color: textPrimaryDark),
      bodySmall: bodySmall.copyWith(color: textSecondaryDark),
      labelLarge: labelLarge.copyWith(color: textPrimaryDark),
      labelMedium: labelMedium.copyWith(color: textSecondaryDark),
      labelSmall: labelSmall.copyWith(color: textTertiaryDark),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: primaryLight,
        onPrimary: Colors.white,
        primaryContainer: primaryDark,
        onPrimaryContainer: Colors.white,
        secondary: accentColorDark,
        onSecondary: Colors.black,
        secondaryContainer: backgroundSecondaryDark,
        onSecondaryContainer: accentColorDark,
        tertiary: backgroundTertiaryDark,
        onTertiary: accentColorDark,
        tertiaryContainer: backgroundSecondaryDark,
        onTertiaryContainer: accentColorDark,
        error: errorColor,
        onError: Colors.white,
        errorContainer: Color(0xFF8A1C1C),
        onErrorContainer: Colors.white,
        surface: backgroundPrimaryDark,
        onSurface: textPrimaryDark,
        surfaceContainerHighest: backgroundSecondaryDark,
        onSurfaceVariant: textSecondaryDark,
        outline: Color(0xFF3A3A3A),
        outlineVariant: Color(0xFF2A2A2A),
        shadow: shadowDark,
        scrim: Color(0x90000000),
        inverseSurface: Colors.white,
        onInverseSurface: Colors.black,
        inversePrimary: primaryLight,
      ),
      scaffoldBackgroundColor: backgroundPrimaryDark,
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        elevation: elevationLow,
        scrolledUnderElevation: elevationLow,
        centerTitle: false,
        backgroundColor: backgroundPrimaryDark,
        foregroundColor: textPrimaryDark,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: elevationLow,
        color: backgroundSecondaryDark,
        surfaceTintColor: Colors.transparent,
        shadowColor: shadowDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        margin: const EdgeInsets.all(spacingSmall),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: backgroundSecondaryDark,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF2E2E2E),
        thickness: 1,
        space: spacingMedium,
      ),
    );
  }

  // ==================== CUSTOM DECORATIONS ====================

  /// Clean card decoration with subtle shadows
  static BoxDecoration cleanCardDecoration({
    Color? backgroundColor,
    double? elevation,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? backgroundSecondary,
      borderRadius: BorderRadius.circular(radiusMedium),
      boxShadow: [
        BoxShadow(
          color: shadowLight,
          offset: Offset(0, elevation ?? elevationLow),
          blurRadius: (elevation ?? elevationLow) * 2,
          spreadRadius: 0,
        ),
      ],
    );
  }

  /// Elevated card decoration for important elements
  static BoxDecoration elevatedCardDecoration({
    Color? backgroundColor,
    double? elevation,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? backgroundPrimary,
      borderRadius: BorderRadius.circular(radiusMedium),
      boxShadow: [
        BoxShadow(
          color: shadowMedium,
          offset: Offset(0, elevation ?? elevationMedium),
          blurRadius: (elevation ?? elevationMedium) * 2,
          spreadRadius: 0,
        ),
      ],
    );
  }

  /// Pill-shaped decoration for buttons and special elements
  static BoxDecoration pillDecoration({
    Color? backgroundColor,
    double? elevation,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? backgroundSecondary,
      borderRadius: BorderRadius.circular(radiusXLarge),
      boxShadow: [
        BoxShadow(
          color: shadowLight,
          offset: Offset(0, elevation ?? elevationLow),
          blurRadius: (elevation ?? elevationLow) * 2,
          spreadRadius: 0,
        ),
      ],
    );
  }

  /// Subtle border decoration
  static BoxDecoration borderDecoration({
    Color? backgroundColor,
    Color? borderColor,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? backgroundPrimary,
      borderRadius: BorderRadius.circular(radiusMedium),
      border: Border.all(
        color: borderColor ?? const Color(0xFFE0E0E0),
        width: 1,
      ),
    );
  }

  // ==================== LEGACY DECORATION METHODS ====================
  // These methods are kept for backward compatibility with existing pages

  /// Legacy paper card decoration - now uses clean card style
  static BoxDecoration paperCardDecoration({
    Color? backgroundColor,
    double? elevation,
  }) {
    return cleanCardDecoration(
      backgroundColor: backgroundColor,
      elevation: elevation,
    );
  }

  /// Legacy elevated paper decoration - now uses elevated card style
  static BoxDecoration elevatedPaperDecoration({Color? backgroundColor}) {
    return elevatedCardDecoration(backgroundColor: backgroundColor);
  }

  /// Legacy gradient overlay decoration - now uses clean gradient
  static BoxDecoration gradientOverlayDecoration({List<Color>? colors}) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors ?? [backgroundPrimary, backgroundSecondary],
      ),
      borderRadius: BorderRadius.circular(radiusMedium),
    );
  }

  // ==================== ANIMATION UTILITIES ====================

  /// Standard animation durations - subtle and refined
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationMedium = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  static const Duration animationVerySlow = Duration(milliseconds: 800);

  /// Standard animation curves - elegant and smooth
  static const Curve curveElegant = Curves.easeInOutCubic;
  static const Curve curveSmooth = Curves.easeOutQuart;
  static const Curve curveSubtle = Curves.easeInOut;
  static const Curve curveGentle = Curves.easeOutCubic;

  /// Create a staggered animation delay
  static Duration staggeredDelay(
    int index, {
    Duration baseDelay = const Duration(milliseconds: 50),
  }) {
    return Duration(milliseconds: baseDelay.inMilliseconds * index);
  }

  /// Create a subtle fade animation value
  static double fadeValue(
    double animationValue, {
    double minOpacity = 0.0,
    double maxOpacity = 1.0,
  }) {
    return minOpacity +
        (maxOpacity - minOpacity) *
            (0.5 + 0.5 * math.sin(animationValue * math.pi));
  }

  /// Create a gentle scale animation value
  static double scaleValue(
    double animationValue, {
    double minScale = 0.95,
    double maxScale = 1.0,
  }) {
    return minScale +
        (maxScale - minScale) *
            (0.5 + 0.5 * math.sin(animationValue * math.pi));
  }

  /// Create a smooth slide animation value
  static double slideValue(
    double animationValue, {
    double minOffset = 0.0,
    double maxOffset = 1.0,
  }) {
    return minOffset +
        (maxOffset - minOffset) *
            (0.5 + 0.5 * math.sin(animationValue * math.pi));
  }
}
