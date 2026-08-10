import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class PremiumSectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final bool showAccentBar;
  final Color? accentColor;

  const PremiumSectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.showAccentBar = false,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final barColor = accentColor ?? AppTheme.primary;

    return Row(
      children: [
        if (showAccentBar) ...[
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                  color: barColor.withValues(alpha: 0.5),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.s8),
        ],
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
                letterSpacing: -0.2,
              ),
        ),
        if (trailing != null) ...[
          const Spacer(),
          trailing!,
        ],
      ],
    );
  }
}
