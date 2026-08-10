import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

/// Premium section header with optional accent bar and trailing widget.
class AstraSectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final bool showAccentBar;
  final Color? accentColor;

  const AstraSectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.showAccentBar = false,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppTheme.primary;
    return Row(
      children: [
        if (showAccentBar) ...[
          Container(
            width: 3,
            height: 16,
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
            style: GoogleFonts.montserrat(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.textMuted,
              letterSpacing: 1.2,
            ),
          ),
        ),
        ?trailing,

      ],
    );
  }
}
