import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'astra_3d_surface.dart';

/// Primary interactive button for ASTRA.
/// Composes [Astra3DSurface] — all press / haptic / depth logic lives there.
///
/// Color presets:
///   Primary lime:   color: AstraColors.lime  (default depth auto-selected)
///   Neutral grey:   color: AstraDepthColors.neutralFace
///   Ghost:          color: AstraDepthColors.ghostFace
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
    // Explicit depth color — must be an opaque AstraDepthColors token.
    // Never pass a transparent/alpha-blended value here.
    this.depthColor,
    this.borderColor,
    this.textColor,
    this.borderRadius = AstraRadii.md,
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
  final Color color;

  /// Opaque extrusion color. If null, auto-selected from AstraDepthColors map.
  final Color? depthColor;

  /// Neutral edge color. If null, auto-selected from AstraDepthColors map.
  final Color? borderColor;

  final Color? textColor;
  final double borderRadius;

  // ── depth lookup: face → canonical opaque depth ───────────────────────────
  static Color _depthFor(Color face) {
    if (face == AstraColors.lime)   return AstraDepthColors.limeDepth;
    if (face == AstraColors.violet) return AstraDepthColors.violetDepth;
    if (face == AstraColors.amber)  return AstraDepthColors.amberDepth;
    if (face == AstraColors.cyan)   return AstraDepthColors.cyanDepth;
    if (face == AstraColors.red)    return AstraDepthColors.redDepth;
    // Neutral & ghost shades
    if (face == AstraDepthColors.neutralFace) return AstraDepthColors.neutralDepth;
    if (face == AstraDepthColors.ghostFace)   return AstraDepthColors.ghostDepth;
    // Fallback: safe near-black extrusion
    return AstraDepthColors.neutralDepth;
  }

  static Color _borderFor(Color face) {
    if (face == AstraColors.lime)   return AstraDepthColors.limeBorder;
    if (face == AstraColors.violet) return AstraDepthColors.violetBorder;
    if (face == AstraColors.amber)  return AstraDepthColors.amberBorder;
    if (face == AstraColors.cyan)   return AstraDepthColors.cyanBorder;
    if (face == AstraColors.red)    return AstraDepthColors.redBorder;
    if (face == AstraDepthColors.neutralFace) return AstraDepthColors.neutralBorder;
    if (face == AstraDepthColors.ghostFace)   return AstraDepthColors.ghostBorder;
    return AstraDepthColors.neutralBorder;
  }

  static Color _fgFor(Color face) {
    // Light accent faces need dark text; charcoal faces need light text
    return (face == AstraColors.lime || face == AstraColors.amber)
        ? Colors.black
        : AstraColors.textPrimary;
  }

  @override
  Widget build(BuildContext context) {
    final action = onPressed ?? onTap;
    final fgColor = textColor ?? _fgFor(color);
    final effectiveDepth = depthColor ?? _depthFor(color);
    final effectiveBorder = borderColor ?? _borderFor(color);

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
        faceColor: color,
        depthColor: effectiveDepth,
        borderColor: effectiveBorder,
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
/// Active: lime face / depth. Inactive: neutral face / depth.
class AstraFilterPill extends StatelessWidget {
  const AstraFilterPill({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
    this.depth = AstraDepth.small,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;
  final double depth;

  @override
  Widget build(BuildContext context) {
    return Astra3DSurface(
      faceColor: active ? AstraDepthColors.limeFace : AstraDepthColors.neutralFace,
      depthColor: active ? AstraDepthColors.limeDepth : AstraDepthColors.neutralDepth,
      borderColor: active ? AstraDepthColors.limeBorder : AstraDepthColors.neutralBorder,
      depthOffset: depth,
      borderRadius: AstraRadii.md,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Text(
          label,
          style: AstraText.label(
            size: 12,
            color: active ? Colors.black : AstraColors.textMuted,
          ),
        ),
      ),
    );
  }
}


