import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─── Colors (Matiks-inspired) ──────────────────────────
  static const Color background = Color(0xFF0A0A0F);
  static const Color surface = Color(0xFF14141E);
  static const Color surfaceElevated = Color(0xFF1A1A28);
  static const Color surfaceGlass = Color(0xFF22223A);
  static const Color surfaceRaised = Color(0xFF2E2F44);

  static const Color primary = Color(0xFF7C65F4);
  static const Color primaryLight = Color(0xFF9B85FF);
  static const Color primaryDark = Color(0xFF5B4AC4);

  static const Color secondary = Color(0xFF06B6D4);
  static const Color secondaryLight = Color(0xFF22D3EE);

  static const Color accent = Color(0xFFF97316);
  static const Color accentGreen = Color(0xFFC6FF3D);
  static const Color accentOrange = Color(0xFFF97316);
  static const Color accentPurple = Color(0xFF8B7CF6);

  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF475569);

  static const Color borderSubtle = Color(0xFF2A2A3A);
  static const Color borderFaint = Color(0xFF1E1F30);

  // ─── Typography ──────────────────────────────────────────
  static const String displayFont = 'BebasNeue';
  static const String bodyFont = 'Montserrat';

  // ─── Spacing ─────────────────────────────────────────────
  static const double s2 = 2.0;
  static const double s4 = 4.0;
  static const double s6 = 6.0;
  static const double s8 = 8.0;
  static const double s10 = 10.0;
  static const double s12 = 12.0;
  static const double s16 = 16.0;
  static const double s20 = 20.0;
  static const double s24 = 24.0;
  static const double s32 = 32.0;
  static const double s40 = 40.0;
  static const double s48 = 48.0;

  // ─── Radius ──────────────────────────────────────────────
  static const double r8 = 8.0;
  static const double r12 = 12.0;
  static const double r16 = 16.0;
  static const double r20 = 20.0;
  static const double r24 = 24.0;

  // ─── Glass & Card Decorations ─────────────────────────────
  static BoxDecoration get glassCard => BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            surfaceElevated.withValues(alpha: 0.9),
            surface.withValues(alpha: 0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(r20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: -5,
            offset: const Offset(0, 4),
          ),
        ],
      );

  static BoxDecoration glassCardAccent({Color? accent}) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          surfaceElevated.withValues(alpha: 0.9),
          surface.withValues(alpha: 0.6),
        ],
      ),
      borderRadius: BorderRadius.circular(r20),
      border: Border.all(
        color: (accent ?? Colors.white).withValues(alpha: 0.08),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          blurRadius: 20,
          spreadRadius: -5,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static BoxDecoration get aiCard => BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            secondary.withValues(alpha: 0.15),
            surfaceElevated.withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(r20),
        border: Border.all(
          color: secondary.withValues(alpha: 0.3),
          width: 1,
        ),
      );

  static BoxDecoration primaryGlowCard = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        primary.withValues(alpha: 0.15),
        surfaceElevated.withValues(alpha: 0.9),
      ],
    ),
    borderRadius: BorderRadius.circular(r20),
    border: Border.all(
      color: primary.withValues(alpha: 0.3),
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: primary.withValues(alpha: 0.12),
        blurRadius: 30,
        spreadRadius: -8,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static BoxDecoration accentGreenCard = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        accentGreen.withValues(alpha: 0.1),
        surfaceElevated.withValues(alpha: 0.9),
      ],
    ),
    borderRadius: BorderRadius.circular(r20),
    border: Border.all(
      color: accentGreen.withValues(alpha: 0.25),
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: accentGreen.withValues(alpha: 0.1),
        blurRadius: 24,
        spreadRadius: -8,
      ),
    ],
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      surface: surface,
      primary: primary,
      secondary: secondary,
      tertiary: accentOrange,
      error: error,
      onSurface: textPrimary,
      onPrimary: Colors.white,
    ),
    scaffoldBackgroundColor: background,
    cardTheme: CardThemeData(
      color: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r20)),
      margin: const EdgeInsets.symmetric(horizontal: s16, vertical: s4),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      iconTheme: const IconThemeData(color: textPrimary),
      titleTextStyle: GoogleFonts.bebasNeue(
        color: textPrimary,
        fontSize: 24,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    ),
    textTheme: TextTheme(
      displayLarge: GoogleFonts.bebasNeue(fontSize: 48, color: textPrimary, letterSpacing: 1),
      displayMedium: GoogleFonts.bebasNeue(fontSize: 32, color: textPrimary, letterSpacing: 0.5),
      displaySmall: GoogleFonts.bebasNeue(fontSize: 24, color: textPrimary, letterSpacing: 0.3),
      headlineMedium: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w600, color: textPrimary),
      titleLarge: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
      titleMedium: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary),
      titleSmall: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
      bodyLarge: GoogleFonts.montserrat(fontSize: 16, color: textSecondary, height: 1.5),
      bodyMedium: GoogleFonts.montserrat(fontSize: 14, color: textSecondary, height: 1.5),
      bodySmall: GoogleFonts.montserrat(fontSize: 12, color: textMuted, height: 1.4),
      labelLarge: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600, color: textSecondary),
      labelSmall: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w500, color: textMuted, letterSpacing: 0.3),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surface,
      selectedItemColor: primary,
      unselectedItemColor: textMuted,
      selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.2),
      unselectedLabelStyle: TextStyle(fontSize: 11),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      shape: CircleBorder(),
      elevation: 4,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: surfaceElevated,
      selectedColor: primary.withValues(alpha: 0.15),
      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textSecondary),
      padding: const EdgeInsets.symmetric(horizontal: s12, vertical: s4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r24), side: BorderSide.none),
    ),
  );
}
