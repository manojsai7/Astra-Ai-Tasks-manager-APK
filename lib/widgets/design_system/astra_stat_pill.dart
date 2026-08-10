import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Compact rounded-pill stat chip: icon + value + optional label.
class AstraStatPill extends StatelessWidget {
  final IconData icon;
  final String value;
  final String? label;
  final Color? iconColor;

  const AstraStatPill({
    super.key,
    required this.icon,
    required this.value,
    this.label,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? AppTheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.surfaceGlass,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: AppTheme.borderSubtle, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (label != null) ...[
            const SizedBox(width: 4),
            Text(
              label!,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
