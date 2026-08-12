import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Section header with vertical lime indicator pill and display header text.
class AstraSectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final Widget? trailing;
  final bool showAccentBar;
  final Color? accentColor;
  final VoidCallback? onActionTap;

  const AstraSectionHeader({
    super.key,
    required this.title,
    this.action,
    this.trailing,
    this.showAccentBar = true,
    this.accentColor,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AstraColors.lime;
    return Row(
      children: [
        if (showAccentBar) ...[
          Container(
            width: 4,
            height: 28,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Text(
            title.toUpperCase(),
            style: AstraText.displayM(color: AstraColors.textPrimary),
          ),
        ),
        if (action != null)
          GestureDetector(
            onTap: onActionTap,
            child: Text(
              action!,
              style: AstraText.label(color: AstraColors.cyan, size: 13),
            ),
          ),
        ?trailing,
      ],
    );
  }
}

