import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// AI insight card with animated sparkle indicator and two optional action buttons.
class AstraInsightCard extends StatefulWidget {
  final String insight;
  final String? primaryAction;
  final String? secondaryAction;
  final VoidCallback? onPrimary;
  final VoidCallback? onSecondary;

  const AstraInsightCard({
    super.key,
    required this.insight,
    this.primaryAction,
    this.secondaryAction,
    this.onPrimary,
    this.onSecondary,
  });

  @override
  State<AstraInsightCard> createState() => _AstraInsightCardState();
}

class _AstraInsightCardState extends State<AstraInsightCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.6, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.secondary.withAlpha(18),
            AppTheme.accentPurple.withAlpha(12),
            AppTheme.surfaceElevated.withAlpha(200),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.secondary.withAlpha(40),
          width: 1,
        ),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulse,
                builder: (context2, _) => Transform.rotate(
                  angle: math.pi * 0.05 * math.sin(_pulseCtrl.value * math.pi),
                  child: Icon(
                    Icons.auto_awesome,
                    size: 14,
                    color: AppTheme.secondary.withAlpha(
                      (_pulse.value * 255).toInt(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'ASTRA INSIGHT',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.secondary,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '"${widget.insight}"',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppTheme.textSecondary,
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),
          if (widget.primaryAction != null || widget.secondaryAction != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (widget.primaryAction != null)
                  GestureDetector(
                    onTap: widget.onPrimary,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.secondary.withAlpha(25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppTheme.secondary.withAlpha(60), width: 1),
                      ),
                      child: Text(
                        widget.primaryAction!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.secondary,
                        ),
                      ),
                    ),
                  ),
                if (widget.secondaryAction != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: widget.onSecondary,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceRaised,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.secondaryAction!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
