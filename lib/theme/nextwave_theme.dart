import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// NextWave Music Sim - Retro-Modern Arcade Theme System
/// Classic tycoon game meets modern arcade rhythm sim aesthetic
class NextWaveTheme {
  // ════════════════════════════════════════════════════════════════
  // 🎨 COLOR PALETTE - Classic Retro-Modern Hybrid
  // ════════════════════════════════════════════════════════════════

  // Base Colors
  static const Color backgroundDark = Color(0xFF0B0D17); // Midnight navy
  static const Color surfaceDark = Color(0xFF161B22);
  static const Color surfaceMedium = Color(0xFF1C2128);

  // Accent Colors - Neon/Electric
  static const Color electricGold = Color(0xFFFFD966);
  static const Color neonCyan = Color(0xFF00E5FF);
  static const Color crimsonRed = Color(0xFFFF5252);
  static const Color neonPurple = Color(0xFFBB86FC);
  static const Color successGreen = Color(0xFF00E676);
  static const Color warningOrange = Color(0xFFFF9800);

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textTertiary = Color(0xFF808080);

  // ════════════════════════════════════════════════════════════════
  // 🎨 GRADIENTS
  // ════════════════════════════════════════════════════════════════

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFD966), Color(0xFFFFA000)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cyanGradient = LinearGradient(
    colors: [Color(0xFF00E5FF), Color(0xFF00B8D4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleBlueGradient = LinearGradient(
    colors: [Color(0xFFBB86FC), Color(0xFF6200EA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient crimsonGradient = LinearGradient(
    colors: [Color(0xFFFF5252), Color(0xFFD32F2F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF0B0D17), Color(0xFF1A1D2E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF00E676), Color(0xFF00C853)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ════════════════════════════════════════════════════════════════
  // 📝 TYPOGRAPHY
  // ════════════════════════════════════════════════════════════════

  static TextTheme get textTheme {
    return TextTheme(
      // Headings - Orbitron (futuristic, bold)
      displayLarge: GoogleFonts.orbitron(
        fontSize: 32,
        fontWeight: FontWeight.w900,
        color: textPrimary,
        letterSpacing: 1.5,
      ),
      displayMedium: GoogleFonts.orbitron(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: textPrimary,
        letterSpacing: 1.2,
      ),
      displaySmall: GoogleFonts.orbitron(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: 1.0,
      ),

      // Titles - Exo 2 (modern, clean)
      headlineLarge: GoogleFonts.exo2(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      headlineMedium: GoogleFonts.exo2(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      headlineSmall: GoogleFonts.exo2(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),

      // Body - Poppins (readable, friendly)
      bodyLarge: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      ),
      bodyMedium: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textSecondary,
      ),
      bodySmall: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: textTertiary,
      ),

      // Labels
      labelLarge: GoogleFonts.montserrat(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: 0.5,
      ),
      labelMedium: GoogleFonts.montserrat(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textSecondary,
        letterSpacing: 0.5,
      ),
      labelSmall: GoogleFonts.montserrat(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: textTertiary,
        letterSpacing: 0.5,
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // 🎨 THEME DATA
  // ════════════════════════════════════════════════════════════════

  static ThemeData get theme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundDark,

      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: electricGold,
        secondary: neonCyan,
        tertiary: neonPurple,
        error: crimsonRed,
        surface: surfaceDark,
        onPrimary: Color(0xFF000000),
        onSecondary: Color(0xFF000000),
        onSurface: textPrimary,
      ),

      // Typography
      textTheme: textTheme,

      // Card Theme
      cardTheme: const CardThemeData(
        color: surfaceDark,
        elevation: 0,
      ),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.orbitron(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: electricGold,
          foregroundColor: const Color(0xFF000000),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          textStyle: GoogleFonts.exo2(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceMedium,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: neonCyan.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: neonCyan.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: neonCyan, width: 2),
        ),
        labelStyle: GoogleFonts.poppins(color: textSecondary),
        hintStyle: GoogleFonts.poppins(color: textTertiary),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // ✨ BOX DECORATIONS
  // ════════════════════════════════════════════════════════════════

  static BoxDecoration glowBox({
    required Color glowColor,
    double glowRadius = 20,
    double borderRadius = 16,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: glowColor.withOpacity(0.5), width: 1),
      boxShadow: [
        BoxShadow(
          color: glowColor.withOpacity(0.3),
          blurRadius: glowRadius,
          spreadRadius: 2,
        ),
      ],
    );
  }

  static BoxDecoration cardDecoration({
    Color? color,
    Gradient? gradient,
    Color? borderColor,
    double borderRadius = 16,
  }) {
    return BoxDecoration(
      color: gradient == null ? (color ?? surfaceDark) : null,
      gradient: gradient,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? neonCyan.withOpacity(0.2),
        width: 1,
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // 🎬 ANIMATION DURATIONS
  // ════════════════════════════════════════════════════════════════

  static const Duration fastDuration = Duration(milliseconds: 150);
  static const Duration normalDuration = Duration(milliseconds: 250);
  static const Duration slowDuration = Duration(milliseconds: 400);

  static const Curve bounceCurve = Curves.easeOutBack;
  static const Curve smoothCurve = Curves.easeInOut;
}
