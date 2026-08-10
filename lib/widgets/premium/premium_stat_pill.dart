import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class PremiumStatPill extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color iconColor;

  const PremiumStatPill({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.iconColor = AppTheme.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.s10,
        vertical: AppTheme.s6,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceGlass,
        borderRadius: BorderRadius.circular(AppTheme.r16),
        border: Border.all(
          color: AppTheme.borderSubtle,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: AppTheme.s6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(width: AppTheme.s4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
