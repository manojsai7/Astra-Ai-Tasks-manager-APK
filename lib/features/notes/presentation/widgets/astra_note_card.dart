import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../services/haptics/astra_haptics.dart';
import '../../../../theme/app_theme.dart';
import '../../domain/models/astra_note.dart';

class AstraNoteCard extends StatelessWidget {
  final AstraNote note;
  final VoidCallback onTap;
  final VoidCallback onTogglePin;

  const AstraNoteCard({
    super.key,
    required this.note,
    required this.onTap,
    required this.onTogglePin,
  });

  @override
  Widget build(BuildContext context) {
    final completedCount = note.checklist.where((c) => c.isDone).length;
    final totalChecklist = note.checklist.length;

    return GestureDetector(
      onTap: () {
        AstraHaptics.light();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: note.isPinned ? AstraColors.surface1 : AstraColors.surface0,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: note.isPinned ? AstraColors.lime.withValues(alpha: 0.4) : AstraColors.edgeSoft,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Row: Pinned Icon & Organization
            Row(
              children: [
                if (note.organization != null && note.organization!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AstraColors.cyan.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AstraColors.cyan.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      note.organization!.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: AstraColors.cyan,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    AstraHaptics.selection();
                    onTogglePin();
                  },
                  child: Icon(
                    note.isPinned ? LucideIcons.pin : LucideIcons.pinOff,
                    size: 15,
                    color: note.isPinned ? AstraColors.lime : AstraColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Title
            if (note.title.isNotEmpty)
              Text(
                note.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AstraColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

            if (note.title.isNotEmpty && note.body.isNotEmpty) const SizedBox(height: 4),

            // Body preview
            if (note.body.isNotEmpty)
              Text(
                note.body,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AstraColors.textSecondary,
                  height: 1.35,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

            const SizedBox(height: 10),

            // Bottom Badges: Checklist progress & Tags
            Row(
              children: [
                if (totalChecklist > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: completedCount == totalChecklist
                          ? AstraColors.lime.withValues(alpha: 0.15)
                          : AstraColors.surface2,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          completedCount == totalChecklist ? LucideIcons.circleCheck : LucideIcons.checkSquare,
                          size: 11,
                          color: completedCount == totalChecklist ? AstraColors.lime : AstraColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$completedCount/$totalChecklist',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: completedCount == totalChecklist ? AstraColors.lime : AstraColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                if (note.tags.isNotEmpty)
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: note.tags.map((tag) {
                          return Container(
                            margin: const EdgeInsets.only(right: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AstraColors.surface2,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '#$tag',
                              style: const TextStyle(fontSize: 9.5, color: AstraColors.textMuted),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
