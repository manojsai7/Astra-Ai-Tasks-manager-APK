import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Timeline task item with colored node, vertical connector line, time, and task details.
class AstraTimelineItem extends StatelessWidget {
  final String time;
  final String title;
  final String? subtitle;
  final Color nodeColor;
  final bool isLast;
  final bool isCompleted;

  const AstraTimelineItem({
    super.key,
    required this.time,
    required this.title,
    this.subtitle,
    this.nodeColor = AppTheme.primary,
    this.isLast = false,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time column
          SizedBox(
            width: 52,
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                time,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isCompleted
                      ? AppTheme.textMuted
                      : AppTheme.textSecondary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Node + line column
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? AppTheme.textMuted.withAlpha(80)
                      : nodeColor,
                  boxShadow: isCompleted
                      ? null
                      : [
                          BoxShadow(
                            color: nodeColor.withAlpha(60),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1.5,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: AppTheme.borderFaint,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),

          // Content column
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isCompleted
                          ? AppTheme.textMuted
                          : AppTheme.textPrimary,
                      decoration:
                          isCompleted ? TextDecoration.lineThrough : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                      ),
                      maxLines: 1,
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
