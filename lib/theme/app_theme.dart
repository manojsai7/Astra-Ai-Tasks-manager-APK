import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Premium Dark Palette
  static const Color background = Color(0xFF0A0A12);
  static const Color surface = Color(0xFF12121E);
  static const Color surfaceElevated = Color(0xFF1A1A2E);
  static const Color surfaceGlass = Color(0xFF1E1E32);
  
  // Premium Primary – Refined Indigo
  static const Color primary = Color(0xFF6366F1);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4F46E5);
  
  // Premium Accents – Muted but Vibrant
  static const Color accent = Color(0xFF06B6D4);
  static const Color accentGlow = Color(0xFF22D3EE);
  
  // Semantic – Professional Colors
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  
  // Text – Hierarchical
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF475569);
  static const Color textInverse = Color(0xFF0A0A12);

  // Glassmorphism effect
  static BoxDecoration glassCard = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        surfaceGlass.withAlpha(153),
        surfaceGlass.withAlpha(76),
      ],
    ),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: Colors.white.withAlpha(15),
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: primary.withAlpha(13),
        blurRadius: 30,
        spreadRadius: -10,
      ),
    ],
  );

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
    fontFamily: GoogleFonts.montserrat().fontFamily,
    
    // Card Theme – Glassmorphism
    cardTheme: CardThemeData(
      color: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    ),
    
    // AppBar – Minimal
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      iconTheme: const IconThemeData(color: textPrimary),
      titleTextStyle: GoogleFonts.montserrat(
        color: textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
      ),
    ),
    
    // Premium Typography
    textTheme: TextTheme(
      // Headlines – Bebas Neue for impact
      displayLarge: GoogleFonts.bebasNeue(
        fontSize: 48,
        color: textPrimary,
        letterSpacing: 1,
      ),
      displayMedium: GoogleFonts.bebasNeue(
        fontSize: 32,
        color: textPrimary,
        letterSpacing: 0.5,
      ),
      headlineMedium: GoogleFonts.bebasNeue(
        fontSize: 24,
        color: textPrimary,
        letterSpacing: 0.3,
      ),
      
      // Body – Montserrat for readability
      titleLarge: GoogleFonts.montserrat(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: -0.2,
      ),
      titleMedium: GoogleFonts.montserrat(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: textPrimary,
        letterSpacing: -0.1,
      ),
      bodyLarge: GoogleFonts.montserrat(
        fontSize: 16,
        color: textSecondary,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.montserrat(
        fontSize: 14,
        color: textSecondary,
        height: 1.5,
      ),
      
      // Labels
      labelLarge: GoogleFonts.montserrat(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: primary,
        letterSpacing: 0.2,
      ),
      labelSmall: GoogleFonts.montserrat(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: textMuted,
        letterSpacing: 0.3,
      ),
    ),
    
    // Bottom Navigation – Premium
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: surface,
      selectedItemColor: primary,
      unselectedItemColor: textMuted,
      selectedLabelStyle: GoogleFonts.montserrat(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
      unselectedLabelStyle: GoogleFonts.montserrat(
        fontSize: 11,
      ),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    
    // Floating Action Button – Clean
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      shape: CircleBorder(),
      elevation: 4,
    ),
    
    // Chip – Subtle
    chipTheme: ChipThemeData(
      backgroundColor: surfaceElevated,
      selectedColor: primary.withAlpha(38),
      labelStyle: GoogleFonts.montserrat(
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
