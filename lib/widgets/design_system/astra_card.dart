import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../core/motion.dart';

/// Base premium card widget used throughout ASTRA.
/// Supports [variant] to switch between normal/glow/ai styles.
class AstraCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final AstraCardVariant variant;
  final VoidCallback? onTap;
  final double? borderRadius;
  final double radius;
  final Color borderColor;

  const AstraCard({
    super.key,
    required this.child,
    this.padding,
    this.variant = AstraCardVariant.normal,
    this.onTap,
    this.borderRadius,
    this.radius = AstraRadii.lg,
    this.borderColor = AstraColors.edgeSoft,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? radius;
    final decoration = switch (variant) {
      AstraCardVariant.normal => BoxDecoration(
          color: AstraColors.surface,
          borderRadius: BorderRadius.circular(effectiveRadius),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: const [
            BoxShadow(color: AstraColors.depth, offset: Offset(0, 5), blurRadius: 0),
            BoxShadow(color: Color(0x44000000), offset: Offset(0, 8), blurRadius: 18),
          ],
        ),
      AstraCardVariant.glass => AppTheme.glassCard.copyWith(
          borderRadius: BorderRadius.circular(effectiveRadius),
        ),
      AstraCardVariant.glow => AppTheme.primaryGlowCard.copyWith(
          borderRadius: BorderRadius.circular(effectiveRadius),
        ),
      AstraCardVariant.ai => AppTheme.aiCard.copyWith(
          borderRadius: BorderRadius.circular(effectiveRadius),
        ),
    };

    final inner = Container(
      padding: padding ?? const EdgeInsets.all(AstraSpacing.lg),
      decoration: decoration,
      child: child,
    );

    if (onTap != null) {
      return AstraPressScale(
        onTap: onTap,
        child: inner,
      );
    }
    return inner;
  }
}


enum AstraCardVariant { normal, glass, glow, ai }
