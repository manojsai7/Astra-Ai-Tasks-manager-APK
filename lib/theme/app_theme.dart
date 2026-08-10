import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Ultimate Premium Palette – Slate & Warm Amber
  static const Color background = Color(0xFF0B0D11);    // Deep slate
  static const Color surface = Color(0xFF13161A);       // Dark charcoal
  static const Color surfaceElevated = Color(0xFF1C2128); // Elevated
  static const Color surfaceGlass = Color(0xFF242A33);
  
  // Primary – Refined Indigo
  static const Color primary = Color(0xFF7C65F4);       // Softer, elegant indigo
  static const Color primaryLight = Color(0xFF9B85FF);
  static const Color primaryDark = Color(0xFF5B4AC4);
  
  // Accent – Warm Amber (energy without being loud)
  static const Color accent = Color(0xFFF97316);        // Premium orange/amber
  static const Color accentGlow = Color(0xFFFB923C);
  
  // Semantic – Clear & Professional
  static const Color success = Color(0xFF10B981);       // Emerald green
  static const Color error = Color(0xFFEF4444);         // Clean red
  static const Color warning = Color(0xFFF59E0B);       // Golden yellow
  
  // Text – Hierarchical (cool white to slate)
  static const Color textPrimary = Color(0xFFF1F5F9);   // Cool white
  static const Color textSecondary = Color(0xFF94A3B8); // Slate 400
  static const Color textMuted = Color(0xFF475569);     // Slate 600
  static const Color textInverse = Color(0xFF0B0D11);

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
