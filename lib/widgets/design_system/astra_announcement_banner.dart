import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'astra_3d_surface.dart';

/// Semantic variants for [AstraAnnouncementBanner].
enum AstraBannerVariant { success, info, warning, promotion, permission, error }

/// A full-width solid-color physical strip for system-level notifications,
/// permission prompts, and promotional announcements.
///
/// Visual language:
///   solid face color (semantic) → opaque depth below → neutral text
///   Optional CTA is itself a small physical button nested inside.
///
/// Usage:
/// ```dart
/// AstraAnnouncementBanner(
///   variant: AstraBannerVariant.permission,
///   message: 'Allow notifications to stay on schedule.',
///   ctaLabel: 'ALLOW',
///   onCtaTap: () { ... },
///   onDismiss: () { ... },
/// )
/// ```
class AstraAnnouncementBanner extends StatelessWidget {
  const AstraAnnouncementBanner({
    super.key,
    required this.message,
    this.variant = AstraBannerVariant.info,
    this.ctaLabel,
    this.onCtaTap,
    this.onDismiss,
    this.icon,
    // Override palette entirely if desired
    this.palette,
  });

  final String message;
  final AstraBannerVariant variant;
  final String? ctaLabel;
  final VoidCallback? onCtaTap;
  final VoidCallback? onDismiss;
  final IconData? icon;
  final AstraMaterialPalette? palette;

  AstraMaterialPalette get _palette => palette ?? _variantPalette;

  AstraMaterialPalette get _variantPalette => switch (variant) {
        AstraBannerVariant.success    => AstraMaterials.softGreen,
        AstraBannerVariant.permission => AstraMaterials.softGreen,
        AstraBannerVariant.info       => AstraMaterials.cyan,
        AstraBannerVariant.warning    => AstraMaterials.amber,
        AstraBannerVariant.promotion  => AstraMaterials.orange,
        AstraBannerVariant.error      => AstraMaterials.red,
      };

  IconData get _defaultIcon => switch (variant) {
        AstraBannerVariant.success    => Icons.check_circle_outline,
        AstraBannerVariant.permission => Icons.notifications_outlined,
        AstraBannerVariant.info       => Icons.info_outline,
        AstraBannerVariant.warning    => Icons.warning_amber_outlined,
        AstraBannerVariant.promotion  => Icons.local_fire_department_outlined,
        AstraBannerVariant.error      => Icons.error_outline,
      };

  @override
  Widget build(BuildContext context) {
    final p = _palette;

    return Container(
      // Depth layer: opaque color below the face strip
      decoration: BoxDecoration(
        color: p.depth,
      ),
      child: Container(
        // Face strip: full-width solid color
        margin: const EdgeInsets.only(bottom: 4), // 4px depth visible below
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: p.face),
        child: Row(
          children: [
            Icon(icon ?? _defaultIcon, size: 18, color: p.content),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: p.content,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ),
            if (ctaLabel != null && onCtaTap != null) ...[
              const SizedBox(width: 10),
              // Mini physical button inside the banner
              Astra3DSurface(
                faceColor: p.content,
                depthColor: p.depth,
                borderColor: p.border,
                depthOffset: AstraDepth.small,
                borderRadius: AstraRadii.sm,
                onTap: onCtaTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Text(
                    ctaLabel!,
                    style: TextStyle(
                      color: p.face,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
            if (onDismiss != null) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onDismiss,
                child: Icon(Icons.close, size: 16, color: p.content),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
