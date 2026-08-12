import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'astra_3d_surface.dart';

/// Primary interactive button for ASTRA.
/// Composes [Astra3DSurface] — all press / haptic / depth logic lives there.
///
/// Preferred usage: pass a [palette] from [AstraMaterials] (e.g. AstraMaterials.dark,
/// AstraMaterials.lime, AstraMaterials.orange) to guarantee design-system conformance.
/// Individual color overrides are still supported for fine-grained control.
class Astra3DButton extends StatelessWidget {
  const Astra3DButton({
    super.key,
    this.label,
    this.child,
    this.onPressed,
    this.onTap,
    this.icon,
    this.expand = false,
    this.width,
    this.height = 56,
    this.depth = AstraDepth.medium,
    this.color = AstraColors.lime,
    this.depthColor,
    this.borderColor,
    this.textColor,
    this.borderRadius = AstraRadii.md,
    // Pass a palette to override all four color slots at once
    this.palette,
  });

  final String? label;
  final Widget? child;
  final VoidCallback? onPressed;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool expand;
  final double? width;
  final double height;
  final double depth;

  /// Face color. For accent buttons pass AstraColors.lime / .violet / .amber / .cyan.
  /// For neutral buttons pass AstraDepthColors.neutralFace.
  /// Ignored when [palette] is provided.
  final Color color;

  /// Opaque extrusion color. If null, auto-selected from AstraDepthColors map.
  /// Ignored when [palette] is provided.
  final Color? depthColor;

  /// Neutral edge color. If null, auto-selected from AstraDepthColors map.
  /// Ignored when [palette] is provided.
  final Color? borderColor;

  /// Content color. If null, auto-selected. Ignored when [palette] is provided.
  final Color? textColor;
  final double borderRadius;

  /// When provided, [color], [depthColor], [borderColor], [textColor] are
  /// all overridden by the palette. Prefer this for design-system conformance.
  final AstraMaterialPalette? palette;

  // ── depth lookup: face → canonical opaque depth ───────────────────────────
  static Color _depthFor(Color face) {
    if (face == AstraColors.lime)       return AstraDepthColors.limeDepth;
    if (face == AstraColors.softGreen)  return AstraDepthColors.softGreenDepth;
    if (face == AstraColors.violet)     return AstraDepthColors.violetDepth;
    if (face == AstraColors.amber)      return AstraDepthColors.amberDepth;
    if (face == AstraColors.cyan)       return AstraDepthColors.cyanDepth;
    if (face == AstraColors.orange)     return AstraDepthColors.orangeDepth;
    if (face == AstraColors.red)        return AstraDepthColors.redDepth;
    if (face == AstraDepthColors.neutralFace) return AstraDepthColors.neutralDepth;
    if (face == AstraDepthColors.darkFace)    return AstraDepthColors.darkDepth;
    if (face == AstraDepthColors.ghostFace)   return AstraDepthColors.ghostDepth;
    return AstraDepthColors.neutralDepth;
  }

  static Color _borderFor(Color face) {
    if (face == AstraColors.lime)       return AstraDepthColors.limeBorder;
    if (face == AstraColors.softGreen)  return AstraDepthColors.softGreenBorder;
    if (face == AstraColors.violet)     return AstraDepthColors.violetBorder;
    if (face == AstraColors.amber)      return AstraDepthColors.amberBorder;
    if (face == AstraColors.cyan)       return AstraDepthColors.cyanBorder;
    if (face == AstraColors.orange)     return AstraDepthColors.orangeBorder;
    if (face == AstraColors.red)        return AstraDepthColors.redBorder;
    if (face == AstraDepthColors.neutralFace) return AstraDepthColors.neutralBorder;
    if (face == AstraDepthColors.darkFace)    return AstraDepthColors.darkBorder;
    if (face == AstraDepthColors.ghostFace)   return AstraDepthColors.ghostBorder;
    return AstraDepthColors.neutralBorder;
  }

  static Color _fgFor(Color face) {
    // Light accent faces need dark text
    if (face == AstraColors.lime || face == AstraColors.softGreen ||
        face == AstraColors.amber) {
      return const Color(0xFF151515);
    }
    // White text on saturated dark-ish accents
    if (face == AstraColors.orange || face == AstraColors.red) {
      return Colors.white;
    }
    // Default: light text on dark/charcoal
    return AstraColors.textPrimary;
  }

  @override
  Widget build(BuildContext context) {
    final action = onPressed ?? onTap;

    // Palette overrides individual color params
    final faceColor   = palette?.face   ?? color;
    final depthCol    = palette?.depth  ?? depthColor ?? _depthFor(faceColor);
    final borderCol   = palette?.border ?? borderColor ?? _borderFor(faceColor);
    final fgColor     = palette?.content ?? textColor ?? _fgFor(faceColor);

    final content = child ??
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: fgColor, size: 18),
              const SizedBox(width: 8),
            ],
            if (label != null)
              Text(
                label!.toUpperCase(),
                style: AstraText.label(color: fgColor, size: 11),
              ),
          ],
        );

    return SizedBox(
      width: expand ? double.infinity : width,
      child: Astra3DSurface(
        faceColor: faceColor,
        depthColor: depthCol,
        borderColor: borderCol,
        depthOffset: depth,
        borderRadius: borderRadius,
        onTap: action,
        enabled: action != null,
        child: SizedBox(
          height: height,
          child: Center(
            child: IconTheme(
              data: IconThemeData(color: fgColor),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}

/// Icon-only physical button. Used for the chat Send button and icon actions.
/// Renders a square [size]×[size] physical surface with centered icon.
class Astra3DIconButton extends StatelessWidget {
  const Astra3DIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 48,
    this.iconSize = 20,
    this.depth = AstraDepth.small,
    this.faceColor = AstraDepthColors.neutralFace,
    this.depthColor = AstraDepthColors.neutralDepth,
    this.borderColor = AstraDepthColors.neutralBorder,
    this.iconColor = AstraColors.textPrimary,
    this.borderRadius = AstraRadii.md,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final double depth;
  final Color faceColor;
  final Color depthColor;
  final Color borderColor;
  final Color iconColor;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Astra3DSurface(
      faceColor: faceColor,
      depthColor: depthColor,
      borderColor: borderColor,
      depthOffset: depth,
      borderRadius: borderRadius,
      onTap: onTap,
      enabled: onTap != null,
      child: SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Icon(icon, size: iconSize, color: iconColor),
        ),
      ),
    );
  }
}

/// Selectable filter chip built on Astra3DSurface.
/// Active: lime face / depth. Inactive: neutral (dark) face / depth.
class AstraFilterPill extends StatelessWidget {
  const AstraFilterPill({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
    this.depth = AstraDepth.small,
    // Allow callers to override the active palette (e.g. violet for Panchang filters)
    this.activePalette,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;
  final double depth;
  final AstraMaterialPalette? activePalette;

  @override
  Widget build(BuildContext context) {
    final ap = activePalette ?? AstraMaterials.lime;
    return Astra3DSurface(
      faceColor:   active ? ap.face   : AstraDepthColors.neutralFace,
      depthColor:  active ? ap.depth  : AstraDepthColors.neutralDepth,
      borderColor: active ? ap.border : AstraDepthColors.neutralBorder,
      depthOffset: depth,
      borderRadius: AstraRadii.md,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Text(
          label,
          style: AstraText.label(
            size: 12,
            color: active ? ap.content : AstraColors.textMuted,
          ),
        ),
      ),
    );
  }
}


