import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class PremiumProgressBar extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final double height;
  final Color? fillColor;
  final Color? backgroundColor;

  const PremiumProgressBar({
    super.key,
    required this.value,
    this.height = 6.0,
    this.fillColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final clampedVal = value.clamp(0.0, 1.0);
    final color = fillColor ?? AppTheme.primary;
    final bg = backgroundColor ?? AppTheme.borderFaint;

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                width: constraints.maxWidth * clampedVal,
                height: height,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.7),
                      color,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(height / 2),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 6,
                      spreadRadius: -1,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
