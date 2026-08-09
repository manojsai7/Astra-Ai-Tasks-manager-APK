import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Premium Dark Palette – Zinc inspired
  static const Color background = Color(0xFF0C0C12);
  static const Color backgroundGradient = Color(0xFF15151F);
  static const Color surface = Color(0xFF14141C);
  static const Color surfaceElevated = Color(0xFF1C1C28);
  static const Color surfaceGlow = Color(0xFF28283A);
  
  // Zinc Primary
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryLight = Color(0xFF8B83FF);
  static const Color primaryDark = Color(0xFF4C44CC);
  
  // Zinc Accents
  static const Color accent = Color(0xFF00C9A7);
  static const Color accentGlow = Color(0xFF00D4AA);
  
  // Semantic – Professional colors
  static const Color success = Color(0xFF00D26A);
  static const Color error = Color(0xFFFF5A5A);
  static const Color warning = Color(0xFFFFAB40);
  
  // Text – Clean hierarchy
  static const Color textPrimary = Color(0xFFF5F5FA);
  static const Color textSecondary = Color(0xFFA8A8B8);
  static const Color textMuted = Color(0xFF6A6A7A);
  static const Color textInverse = Color(0xFF0C0C12);

  static const Color opponent = Color(0xFFFF6B6B);

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      surface: surface,
      primary: primary,
      secondary: accent,
      error: error,
      onSurface: textPrimary,
      onPrimary: Colors.white,
    ),
    scaffoldBackgroundColor: background,
    fontFamily: GoogleFonts.inter().fontFamily,
    
    // Premium Card Theme
    cardTheme: CardThemeData(
      color: surfaceElevated,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.white.withAlpha(10),
          width: 1,
        ),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    ),
    
    // AppBar – clean, transparent
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: textPrimary),
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
      ),
    ),
    
    // Typography – tight hierarchy
    textTheme: TextTheme(
      displayLarge: GoogleFonts.inter(
        fontSize: 40,
        fontWeight: FontWeight.bold,
        color: textPrimary,
        letterSpacing: -1,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: -0.5,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: -0.3,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: -0.2,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        color: textSecondary,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        color: textSecondary,
        height: 1.5,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: primary,
        letterSpacing: 0.2,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textMuted,
        letterSpacing: 0.3,
      ),
    ),
    
    // Bottom Navigation Theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surface,
      selectedItemColor: primary,
      unselectedItemColor: textMuted,
      selectedLabelStyle: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
      unselectedLabelStyle: TextStyle(fontSize: 11),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    
    // FAB
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      shape: CircleBorder(),
      elevation: 4,
    ),
    
    // Chip
    chipTheme: ChipThemeData(
      backgroundColor: surfaceElevated,
      selectedColor: primary.withAlpha(38),
      labelStyle: const TextStyle(
        color: textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide.none,
      ),
    ),
  );
}
