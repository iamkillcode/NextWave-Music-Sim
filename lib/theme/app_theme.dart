import 'package:flutter/material.dart';

/// Comprehensive design system for NextWave Music Sim
/// Provides standardized colors, typography, spacing, and component styles
class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  // ============ COLOR PALETTE ============
  
  /// Background colors - Deep blacks and dark greys
  static const Color backgroundDark = Color(0xFF0A0E14);
  static const Color backgroundElevated = Color(0xFF13171E);
  static const Color surfaceDark = Color(0xFF1A1F28);
  static const Color surfaceElevated = Color(0xFF232933);
  
  /// Primary neon colors - Glowing green and purple
  static const Color neonGreen = Color(0xFF00FF88);
  static const Color neonGreenDim = Color(0xFF00CC6A);
  static const Color neonPurple = Color(0xFFBB00FF);
  static const Color neonPurpleDim = Color(0xFF9900CC);
  
  /// Legacy colors (maintained for compatibility)
  static const Color primaryCyan = Color(0xFF00FFAA);
  static const Color primaryCyanDim = Color(0xFF00CC88);
  static const Color accentBlue = Color(0xFF00D4FF);
  
  /// Status colors - Vibrant and glowing
  static const Color successGreen = Color(0xFF00FF88);
  static const Color warningOrange = Color(0xFFFFAA00);
  static const Color errorRed = Color(0xFFFF0066);
  static const Color infoBlue = Color(0xFF00CCFF);
  
  /// Chart/Data visualization colors
  static const Color chartGold = Color(0xFFFFD700);
  static const Color chartSilver = Color(0xFFC0C0C0);
  static const Color chartBronze = Color(0xFFCD7F32);
  static const Color chartPurple = Color(0xFFBB00FF);
  static const Color chartPink = Color(0xFFFF0088);
  
  /// Text colors - Crisp white and glowing accents
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B8C3);
  static const Color textTertiary = Color(0xFF7A8291);
  static const Color textDisabled = Color(0xFF4A5261);
  static const Color textGlow = Color(0xFF00FF88); // For highlighted text
  
  /// Border colors - Subtle with neon accents
  static const Color borderDefault = Color(0xFF2A2F3A);
  static const Color borderMuted = Color(0xFF1F242E);
  static const Color borderGlow = Color(0xFF00FF88); // Neon green border
  static const Color borderPurple = Color(0xFFBB00FF); // Neon purple border
  
  /// Overlay colors
  static const Color overlayLight = Color(0x0DFFFFFF);
  static const Color overlayMedium = Color(0x1AFFFFFF);
  static const Color overlayHeavy = Color(0x33FFFFFF);
  
  /// Gradient colors
  static const LinearGradient neonGreenGradient = LinearGradient(
    colors: [Color(0xFF004D2E), Color(0xFF00FF88)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  
  static const LinearGradient neonPurpleGradient = LinearGradient(
    colors: [Color(0xFF4D0066), Color(0xFFBB00FF)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  
  static const LinearGradient mixedNeonGradient = LinearGradient(
    colors: [Color(0xFF00FF88), Color(0xFF00CCFF), Color(0xFFBB00FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // ============ TYPOGRAPHY ============
  // Futuristic, clean, and highly legible font styles
  
  /// Display styles (64px+) - Bold and futuristic
  static const TextStyle displayLarge = TextStyle(
    fontSize: 64,
    fontWeight: FontWeight.w900,
    color: textPrimary,
    height: 1.1,
    letterSpacing: -1.5,
  );
  
  static const TextStyle displayMedium = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.w900,
    color: textPrimary,
    height: 1.1,
    letterSpacing: -1.0,
  );
  
  /// Heading styles (24-32px) - Strong presence
  static const TextStyle headingLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: textPrimary,
    height: 1.2,
    letterSpacing: 0.5,
  );
  
  static const TextStyle headingMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: textPrimary,
    height: 1.2,
    letterSpacing: 0.5,
  );
  
  static const TextStyle headingSmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    height: 1.3,
    letterSpacing: 0.5,
  );
  
  /// Title styles (18-20px) - Clear hierarchy
  static const TextStyle titleLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    height: 1.3,
    letterSpacing: 0.3,
  );
  
  static const TextStyle titleMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    height: 1.3,
    letterSpacing: 0.3,
  );
  
  /// Body styles (14-16px) - Highly legible
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: textPrimary,
    height: 1.5,
    letterSpacing: 0.2,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textPrimary,
    height: 1.5,
    letterSpacing: 0.2,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: textSecondary,
    height: 1.5,
    letterSpacing: 0.2,
  );
  
  /// Label styles (11-13px) - Uppercase for emphasis
  static const TextStyle labelLarge = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: textSecondary,
    height: 1.3,
    letterSpacing: 1.2,
  );
  
  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: textSecondary,
    height: 1.3,
    letterSpacing: 1.0,
  );
  
  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: textTertiary,
    height: 1.3,
    letterSpacing: 1.0,
  );
  
  // ============ SPACING SYSTEM ============
  
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;
  static const double space48 = 48.0;
  static const double space64 = 64.0;
  
  // ============ BORDER RADIUS ============
  
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;
  static const double radiusFull = 9999.0;
  
  // ============ SHADOWS ============
  
  static const List<BoxShadow> shadowSmall = [
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];
  
  static const List<BoxShadow> shadowMedium = [
    BoxShadow(
      color: Color(0x4D000000),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];
  
  static const List<BoxShadow> shadowLarge = [
    BoxShadow(
      color: Color(0x66000000),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];
  
  /// Glowing neon shadows for progress bars and highlights
  static const List<BoxShadow> shadowGlowGreen = [
    BoxShadow(
      color: Color(0x8000FF88),
      blurRadius: 24,
      spreadRadius: 2,
    ),
  ];
  
  static const List<BoxShadow> shadowGlowPurple = [
    BoxShadow(
      color: Color(0x80BB00FF),
      blurRadius: 24,
      spreadRadius: 2,
    ),
  ];
  
  static const List<BoxShadow> shadowGlowMixed = [
    BoxShadow(
      color: Color(0x6000FF88),
      blurRadius: 20,
      spreadRadius: 1,
    ),
    BoxShadow(
      color: Color(0x60BB00FF),
      blurRadius: 20,
      spreadRadius: 1,
      offset: Offset(4, 4),
    ),
  ];
  
  // ============ COMPONENT STYLES ============
  
  /// Card decoration with enhanced depth
  static BoxDecoration cardDecoration({
    Color? color,
    BorderRadius? borderRadius,
    Border? border,
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      color: color ?? surfaceDark,
      borderRadius: borderRadius ?? BorderRadius.circular(radiusMedium),
      border: border ?? Border.all(color: borderDefault, width: 1.5),
      boxShadow: boxShadow ?? shadowMedium,
    );
  }
  
  /// Glassmorphic card decoration with subtle glow
  static BoxDecoration glassmorphicDecoration({
    double opacity = 0.08,
    BorderRadius? borderRadius,
    bool withGlow = false,
  }) {
    return BoxDecoration(
      color: textPrimary.withOpacity(opacity),
      borderRadius: borderRadius ?? BorderRadius.circular(radiusMedium),
      border: Border.all(
        color: withGlow ? borderGlow.withOpacity(0.3) : textPrimary.withOpacity(0.15),
        width: 1.5,
      ),
      boxShadow: withGlow ? shadowGlowGreen : shadowSmall,
    );
  }
  
  /// Progress bar decoration with neon glow
  static BoxDecoration progressBarDecoration({
    required Gradient gradient,
    bool withGlow = true,
  }) {
    return BoxDecoration(
      gradient: gradient,
      borderRadius: BorderRadius.circular(radiusFull),
      boxShadow: withGlow ? shadowGlowGreen : [],
    );
  }
  
  /// Button styles with neon gradients
  static BoxDecoration primaryButtonDecoration({bool isPressed = false}) {
    return BoxDecoration(
      gradient: const LinearGradient(
        colors: [neonGreen, Color(0xFF00CCFF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(radiusMedium),
      boxShadow: isPressed ? [] : shadowGlowGreen,
    );
  }
  
  static BoxDecoration secondaryButtonDecoration({bool isHovered = false}) {
    return BoxDecoration(
      color: isHovered ? surfaceElevated : surfaceDark,
      borderRadius: BorderRadius.circular(radiusMedium),
      border: Border.all(
        color: isHovered ? borderGlow : borderDefault,
        width: 1.5,
      ),
      boxShadow: isHovered ? shadowSmall : [],
    );
  }
  
  /// Input field decoration
  static InputDecoration inputDecoration({
    String? labelText,
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: surfaceDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: borderDefault),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: borderDefault),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: borderGlow, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: errorRed),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: space16,
        vertical: space12,
      ),
    );
  }
  
  // ============ MATERIAL THEME DATA ============
  
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: backgroundDark,
    colorScheme: const ColorScheme.dark(
      primary: neonGreen,
      secondary: neonPurple,
      surface: surfaceDark,
      error: errorRed,
      onPrimary: backgroundDark,
      onSecondary: textPrimary,
      onSurface: textPrimary,
      onError: textPrimary,
    ),
    textTheme: const TextTheme(
      displayLarge: displayLarge,
      displayMedium: displayMedium,
      headlineLarge: headingLarge,
      headlineMedium: headingMedium,
      headlineSmall: headingSmall,
      titleLarge: titleLarge,
      titleMedium: titleMedium,
      bodyLarge: bodyLarge,
      bodyMedium: bodyMedium,
      bodySmall: bodySmall,
      labelLarge: labelLarge,
      labelMedium: labelMedium,
      labelSmall: labelSmall,
    ),
    cardTheme: CardThemeData(
      color: surfaceDark,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        side: const BorderSide(color: borderDefault),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: backgroundElevated,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: headingSmall,
      iconTheme: IconThemeData(color: textPrimary),
    ),
    iconTheme: const IconThemeData(
      color: textSecondary,
      size: 24,
    ),
    dividerTheme: const DividerThemeData(
      color: borderDefault,
      thickness: 1,
      space: 1,
    ),
  );
  
  // ============ ANIMATIONS ============
  
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  
  static const Curve animationCurve = Curves.easeInOutCubic;
}
