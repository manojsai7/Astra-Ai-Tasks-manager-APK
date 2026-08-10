import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class PremiumTimelineItem extends StatelessWidget {
  final String time;
  final String title;
  final String? subtitle;
  final Color nodeColor;
  final bool isLast;
  final bool isCompleted;

  const PremiumTimelineItem({
    super.key,
    required this.time,
    required this.title,
    this.subtitle,
    required this.nodeColor,
    this.isLast = false,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time label
          SizedBox(
            width: 60,
            child: Text(
              time,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isCompleted ? AppTheme.textMuted : AppTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.s8),

          // Node indicator + vertical connector line
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted ? AppTheme.surfaceGlass : nodeColor,
                  border: Border.all(
                    color: isCompleted ? AppTheme.textMuted : nodeColor,
                    width: 2,
                  ),
                  boxShadow: isCompleted
                      ? []
                      : [
                          BoxShadow(
                            color: nodeColor.withValues(alpha: 0.5),
                            blurRadius: 8,
                          ),
                        ],
                ),
                child: isCompleted
                    ? const Icon(Icons.check, size: 8, color: AppTheme.textMuted)
                    : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: AppTheme.borderSubtle,
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppTheme.s12),

          // Content body
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isCompleted ? AppTheme.textMuted : AppTheme.textPrimary,
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
