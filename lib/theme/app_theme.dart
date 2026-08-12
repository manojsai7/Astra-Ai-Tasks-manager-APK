import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AstraColors {
  static const background = Color(0xFF151515);

  static const surface0 = Color(0xFF1B1B1B);
  static const surface1 = Color(0xFF242424);
  static const surface = Color(0xFF242424);
  static const surface2 = Color(0xFF2B2B2B);
  static const surfaceElevated = Color(0xFF2B2B2B);
  static const surface3 = Color(0xFF303030);
  static const surfaceGlass = Color(0xFF303030);
  static const surfaceRaised = Color(0xFF363636);

  static const border = Color(0xFF464646);
  static const borderSubtle = Color(0xFF4A4A4A);
  static const edge = Color(0xFF4A4A4A);
  static const borderSoft = Color(0xFF363636);
  static const borderFaint = Color(0xFF383838);
  static const edgeSoft = Color(0xFF383838);

  static const depth = Color(0xFF0C0C0C);

  static const textPrimary = Color(0xFFF2F2EE);
  static const text = Color(0xFFF2F2EE);
  static const textSecondary = Color(0xFF969696);
  static const textMuted = Color(0xFF8C8C8C);
  static const textDisabled = Color(0xFF5F5F5F);
  static const textDim = Color(0xFF666666);

  // ── Accent palette ─────────────────────────────────────────
  static const lime      = Color(0xFFB6FF00); // ASTRA brand / primary action
  static const softGreen = Color(0xFFB0FB62); // streak / invites / secondary positive
  static const cyan      = Color(0xFF20B7D8); // AI system / info
  static const amber     = Color(0xFFFFC64D); // sunrise / solar / soft warning
  static const violet    = Color(0xFF8F7BFF); // Panchang lunar / special
  static const orange    = Color(0xFFFF661B); // promotion / streak / celebration
  static const red       = Color(0xFFF04A4A); // error / destructive
}

abstract final class AstraAccent {
  static const primary = AstraColors.lime;
  // Slightly muted lime for secondary emphasis (tasks, chips, completed badges).
  // Keeps brand lime #B6FF00 canonical while reducing visual noise.
  static const primaryMuted = Color(0xFF9ED600);
  static const panchangLunar = AstraColors.violet;
  static const sunrise = AstraColors.amber;
  static const urgent = AstraColors.red;
  static const info = AstraColors.cyan;
}

/// Pre-computed opaque depth/border values for the face→depth→border system.
/// Rule: no component may derive depth via withOpacity, withValues(alpha:),
/// blending, or transparent overlays. Use these tokens directly.
abstract final class AstraDepthColors {
  // ── Lime (primary brand) ──────────────────────────────────────────
  static const limeFace   = AstraColors.lime;          // #B6FF00
  static const limeDepth  = Color(0xFF637F00);         // dark olive extrusion
  static const limeBorder = Color(0xFF4C4C42);         // neutral grey-lime edge

  // ── Violet (Panchang lunar / Tithi) ──────────────────────────────
  static const violetFace   = AstraColors.violet;      // #8F7BFF
  static const violetDepth  = Color(0xFF4A3E9F);       // deep violet extrusion
  static const violetBorder = Color(0xFF3E3C50);       // muted violet-grey edge

  // ── Amber (sunrise / solar) ───────────────────────────────────────
  static const amberFace   = AstraColors.amber;        // #FFC64D
  static const amberDepth  = Color(0xFF8A6300);        // dark amber extrusion
  static const amberBorder = Color(0xFF504430);        // muted amber-grey edge

  // ── Cyan (info / system) ─────────────────────────────────────────
  static const cyanFace   = AstraColors.cyan;          // #20B7D8
  static const cyanDepth  = Color(0xFF0E6478);         // deep teal extrusion
  static const cyanBorder = Color(0xFF2B4048);         // muted teal-grey edge

  // ── Red (error / warning) ────────────────────────────────────────
  static const redFace   = AstraColors.red;            // #F04A4A
  static const redDepth  = Color(0xFF7A1E1E);          // dark red extrusion
  static const redBorder = Color(0xFF4A2A2A);          // muted red-grey edge

  // ── Neutral (grey/black buttons — secondary actions) ─────────────
  static const neutralFace   = Color(0xFF242424);      // charcoal face
  static const neutralDepth  = Color(0xFF111111);      // near-black extrusion
  static const neutralBorder = Color(0xFF4A4A4A);      // grey edge

  // ── Neutral dark (ghost / tertiary) ──────────────────────────────
  static const ghostFace   = Color(0xFF1B1B1B);
  static const ghostDepth  = Color(0xFF0D0D0D);
  static const ghostBorder = Color(0xFF3A3A3A);

  // ── Orange (promotion / streak / celebration) ─────────────────────
  static const orangeFace   = AstraColors.orange;      // #FF661B
  static const orangeDepth  = Color(0xFFA73D10);       // dark burnt orange extrusion
  static const orangeBorder = Color(0xFF5E4638);       // muted orange-grey edge

  // ── Soft Green (streak / invites / secondary positive) ───────────
  static const softGreenFace   = AstraColors.softGreen; // #B0FB62
  static const softGreenDepth  = Color(0xFF648F3A);     // forest green extrusion
  static const softGreenBorder = Color(0xFF526B46);     // muted green-grey edge

  // ── Dark (back-button reference style — grey underside) ──────────
  // face near-black, depth intentionally grey — not black, not lime
  static const darkFace   = Color(0xFF171717);
  static const darkDepth  = Color(0xFF777777); // the grey physical underside
  static const darkBorder = Color(0xFF777777);
}

abstract final class AstraDepth {
  static const small = 3.0;
  static const medium = 6.0;
  static const large = 8.0;
}

/// The canonical material specification for a physical 3D surface.
/// Every component that renders face+depth+border should receive one of these.
///
/// Rule: No screen or widget may create ad-hoc face/depth/border color triplets.
/// Always use a token from [AstraMaterials].
class AstraMaterialPalette {
  final Color face;
  final Color depth;
  final Color border;
  // Text/icon color that reads clearly against [face]
  final Color content;

  const AstraMaterialPalette({
    required this.face,
    required this.depth,
    required this.border,
    required this.content,
  });
}

/// Canonical material presets. Use these everywhere instead of raw Color literals.
abstract final class AstraMaterials {
  /// Charcoal secondary surface — back, secondary buttons, utility controls.
  static const neutral = AstraMaterialPalette(
    face:    AstraDepthColors.neutralFace,
    depth:   AstraDepthColors.neutralDepth,
    border:  AstraDepthColors.neutralBorder,
    content: AstraColors.textPrimary,
  );

  /// Near-black face with intentional grey underside — reference back-button style.
  static const dark = AstraMaterialPalette(
    face:    AstraDepthColors.darkFace,
    depth:   AstraDepthColors.darkDepth,
    border:  AstraDepthColors.darkBorder,
    content: AstraColors.textPrimary,
  );

  /// Brand primary action (ASTRA lime).
  static const lime = AstraMaterialPalette(
    face:    AstraDepthColors.limeFace,
    depth:   AstraDepthColors.limeDepth,
    border:  AstraDepthColors.limeBorder,
    content: Color(0xFF151515),
  );

  /// Positive secondary / streak / invites.
  static const softGreen = AstraMaterialPalette(
    face:    AstraDepthColors.softGreenFace,
    depth:   AstraDepthColors.softGreenDepth,
    border:  AstraDepthColors.softGreenBorder,
    content: Color(0xFF151515),
  );

  /// AI system / informational.
  static const cyan = AstraMaterialPalette(
    face:    AstraDepthColors.cyanFace,
    depth:   AstraDepthColors.cyanDepth,
    border:  AstraDepthColors.cyanBorder,
    content: Color(0xFF151515),
  );

  /// Panchang lunar / special contextual.
  static const violet = AstraMaterialPalette(
    face:    AstraDepthColors.violetFace,
    depth:   AstraDepthColors.violetDepth,
    border:  AstraDepthColors.violetBorder,
    content: Color(0xFF151515),
  );

  /// Sunrise / auspicious / soft warning.
  static const amber = AstraMaterialPalette(
    face:    AstraDepthColors.amberFace,
    depth:   AstraDepthColors.amberDepth,
    border:  AstraDepthColors.amberBorder,
    content: Color(0xFF151515),
  );

  /// Promotion / streak / celebration / high-energy non-danger.
  static const orange = AstraMaterialPalette(
    face:    AstraDepthColors.orangeFace,
    depth:   AstraDepthColors.orangeDepth,
    border:  AstraDepthColors.orangeBorder,
    content: Color(0xFFFFFFFF),
  );

  /// Destructive / error.
  static const red = AstraMaterialPalette(
    face:    AstraDepthColors.redFace,
    depth:   AstraDepthColors.redDepth,
    border:  AstraDepthColors.redBorder,
    content: Color(0xFFFFFFFF),
  );
}


abstract final class AstraSpacing {
  static const xs = 6.0;
  static const sm = 10.0;
  static const md = 16.0;
  static const lg = 22.0;
  static const xl = 30.0;
  static const xxl = 42.0;
}

abstract final class AstraRadii {
  static const sm = 10.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const pill = 999.0;
}

abstract final class AstraMotion {
  static const fast = Duration(milliseconds: 110);
  static const press = Duration(milliseconds: 110);
  static const normal = Duration(milliseconds: 220);
  static const standard = Duration(milliseconds: 220);
  static const page = Duration(milliseconds: 300);
  static const slow = Duration(milliseconds: 420);

  static const pressCurve = Curves.easeOut;
  static const standardCurve = Curves.easeOutCubic;
  static const curve = Curves.easeOutCubic;
}

enum PanchangVisualType { lunar, solar, festival, fasting, auspicious, warning }

abstract final class PanchangTheme {
  static Color colorFor(PanchangVisualType type) => switch (type) {
        PanchangVisualType.lunar     => AstraColors.violet,     // lunar / moon phase
        PanchangVisualType.solar     => AstraColors.amber,      // sunrise / solar events
        PanchangVisualType.festival  => AstraColors.orange,     // celebration / high-energy
        PanchangVisualType.fasting   => AstraColors.red,        // Ekadashi / fasting (urgency)
        PanchangVisualType.auspicious=> AstraColors.softGreen,  // positive, but not brand lime
        PanchangVisualType.warning   => AstraColors.red,        // warnings
      };
}

abstract final class AstraText {
  static TextStyle displayXL({Color color = AstraColors.textPrimary, double size = 56}) =>
      GoogleFonts.bebasNeue(fontSize: size, height: .92, letterSpacing: .5, color: color);

  static TextStyle displayL({Color color = AstraColors.textPrimary, double size = 42}) =>
      GoogleFonts.bebasNeue(fontSize: size, height: .92, letterSpacing: .5, color: color);

  static TextStyle displayM({Color color = AstraColors.textPrimary, double size = 30}) =>
      GoogleFonts.bebasNeue(fontSize: size, height: .95, letterSpacing: .5, color: color);

  static TextStyle section({Color color = AstraColors.textPrimary, double size = 24}) =>
      GoogleFonts.bebasNeue(fontSize: size, height: 1.0, letterSpacing: .5, color: color);

  static TextStyle body({Color color = AstraColors.textPrimary, double size = 16}) =>
      GoogleFonts.inter(fontSize: size, height: 1.25, color: color);

  static TextStyle label({Color color = AstraColors.textSecondary, double size = 14}) =>
      GoogleFonts.inter(fontSize: size, fontWeight: FontWeight.w600, letterSpacing: 1.1, color: color);

  static TextStyle caption({Color color = AstraColors.textDisabled, double size = 12}) =>
      GoogleFonts.inter(fontSize: size, fontWeight: FontWeight.w500, color: color);

  static TextStyle metric({Color color = AstraColors.textPrimary, double size = 15}) =>
      GoogleFonts.inter(fontSize: size, fontWeight: FontWeight.w700, color: color);
}

class AstraTheme {
  static ThemeData dark() => AppTheme.darkTheme;

  static TextStyle display({double size = 42, Color color = AstraColors.textPrimary}) =>
      GoogleFonts.bebasNeue(fontSize: size, height: .92, letterSpacing: .5, color: color);

  static TextStyle label({double size = 14, Color color = AstraColors.textMuted}) =>
      GoogleFonts.inter(fontSize: size, fontWeight: FontWeight.w600, letterSpacing: 1.1, color: color);

  static TextStyle body({double size = 16, Color color = AstraColors.textPrimary}) =>
      GoogleFonts.inter(fontSize: size, height: 1.25, color: color);
}

class AppTheme {
  // ─── Colors (Matiks-inspired) ──────────────────────────
  static const Color background = Color(0xFF151515);
  static const Color surface = Color(0xFF242424);
  static const Color surfaceElevated = Color(0xFF2B2B2B);
  static const Color surfaceGlass = Color(0xFF303030);
  static const Color surfaceRaised = Color(0xFF363636);

  // Solidified Lime (tactile & balanced, not blinding neon)
  static const Color primary = Color(0xFFAEDB00);
  static const Color primaryLight = Color(0xFFC6ED52);
  static const Color primaryDark = Color(0xFF6D8900);

  static const Color secondary = Color(0xFF20B7D8);
  static const Color secondaryLight = Color(0xFF76DCF1);

  static const Color accent = Color(0xFFFFC64D);
  static const Color accentGreen = Color(0xFFAEDB00);
  static const Color accentOrange = Color(0xFFC9874F);
  static const Color accentPurple = Color(0xFF8F7BFF);

  static const Color success = Color(0xFF6EAE87);
  static const Color warning = Color(0xFFFFC64D);
  static const Color error = Color(0xFFF04A4A);

  static const Color textPrimary = Color(0xFFF9F9F4);
  static const Color textSecondary = Color(0xFFB8B8B0);
  static const Color textMuted = Color(0xFF8C8C8C);

  static const Color borderSubtle = Color(0xFF4A4A4A);
  static const Color borderFaint = Color(0xFF383838);

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
        color: surface,
        borderRadius: BorderRadius.circular(r20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      );

  static BoxDecoration glassCardAccent({Color? accent}) {
    return BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(r20),
      border: Border.all(
        color: (accent ?? Colors.white).withValues(alpha: 0.08),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          blurRadius: 0,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static BoxDecoration get aiCard => BoxDecoration(
      color: surface,
        borderRadius: BorderRadius.circular(r20),
        border: Border.all(
          color: secondary.withValues(alpha: 0.3),
          width: 1,
        ),
      );

  static BoxDecoration primaryGlowCard = BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(r20),
    border: Border.all(
      // Reduced alpha: accent communicates state, not the whole card
      color: primary.withValues(alpha: 0.15),
      width: 1,
    ),
    boxShadow: const [
      // Opaque depth shadow — no glow, just grounding
      BoxShadow(
        color: Color(0xFF0C0C0C),
        blurRadius: 0,
        offset: Offset(0, 5),
      ),
    ],
  );

  static BoxDecoration accentGreenCard = BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(r20),
    border: Border.all(
      color: accentGreen.withValues(alpha: 0.25),
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: accentGreen.withValues(alpha: 0.1),
        blurRadius: 0,
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
      onPrimary: Colors.black,
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
      foregroundColor: Colors.black,
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
