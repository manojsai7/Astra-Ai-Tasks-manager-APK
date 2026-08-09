import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Premium Dark Palette – Matte Finish
  static const Color background = Color(0xFF0D0D14);
  static const Color backgroundGradient = Color(0xFF15151F);
  static const Color surface = Color(0xFF16161F);
  static const Color surfaceElevated = Color(0xFF1E1E2A);
  static const Color surfaceGlow = Color(0xFF2A2A3A);
  
  // Primary – Refined Indigo
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryLight = Color(0xFF8B83FF);
  static const Color primaryDark = Color(0xFF4C44CC);
  
  // Accents – Muted but vibrant
  static const Color accent = Color(0xFF00C9A7);
  static const Color accentGlow = Color(0xFF00D4AA);
  
  // Semantic – Soft but clear
  static const Color success = Color(0xFF00D26A);
  static const Color error = Color(0xFFFF5A5A);
  static const Color warning = Color(0xFFFFAB40);
  
  // Text – Hierarchical
  static const Color textPrimary = Color(0xFFF5F5FA);
  static const Color textSecondary = Color(0xFFA8A8B8);
  static const Color textMuted = Color(0xFF6A6A7A);
  
  // Opponent/Competitive accent
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
    
    cardTheme: CardThemeData(
      color: surfaceElevated,
      elevation: 6,
      shadowColor: Colors.black.withAlpha(153),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    ),
    
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: textPrimary),
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
    ),
    
    textTheme: TextTheme(
      displayLarge: GoogleFonts.inter(
        fontSize: 48,
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
        letterSpacing: 0.3,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: textMuted,
        letterSpacing: 0.5,
      ),
    ),
    
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surface,
      selectedItemColor: primary,
      unselectedItemColor: textMuted,
      selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.3),
      unselectedLabelStyle: TextStyle(fontSize: 11),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      shape: CircleBorder(),
      elevation: 8,
    ),
    
    chipTheme: ChipThemeData(
      backgroundColor: surfaceElevated,
      selectedColor: primary.withAlpha(51),
      labelStyle: const TextStyle(color: textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide.none,
      ),
    ),
  );
}
