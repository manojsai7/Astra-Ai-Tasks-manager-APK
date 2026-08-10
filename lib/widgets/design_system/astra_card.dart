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

  const AstraCard({
    super.key,
    required this.child,
    this.padding,
    this.variant = AstraCardVariant.normal,
    this.onTap,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? 20.0;
    final decoration = switch (variant) {
      AstraCardVariant.normal => BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: AppTheme.borderSubtle, width: 1),
        ),
      AstraCardVariant.glass => AppTheme.glassCard.copyWith(
          borderRadius: BorderRadius.circular(radius),
        ),
      AstraCardVariant.glow => AppTheme.primaryGlowCard.copyWith(
          borderRadius: BorderRadius.circular(radius),
        ),
      AstraCardVariant.ai => AppTheme.aiCard.copyWith(
          borderRadius: BorderRadius.circular(radius),
        ),
    };

    final inner = Container(
      padding: padding ?? const EdgeInsets.all(16),
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
