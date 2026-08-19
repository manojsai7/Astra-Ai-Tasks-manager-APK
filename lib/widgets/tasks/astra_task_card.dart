import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../models/task.dart';
import '../../services/haptics/astra_haptics.dart';
import '../../theme/app_theme.dart';

/// Clean, high-density tactile task row conforming to ASTRA UX 2.0.
class AstraTaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onComplete;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onStatusCycle;
  final void Function(String subtaskId)? onToggleSubtask;

  AstraTaskCard({
    required this.task,
    required this.onComplete,
    this.onEdit,
    this.onDelete,
    this.onStatusCycle,
    this.onToggleSubtask,
  }) : super(key: ValueKey(task.id));

  Color _priorityColor() => switch (task.priority.toLowerCase()) {
        'urgent' => const Color(0xFFA855F7),
        'high' => AstraColors.red,
        'medium' => AstraColors.amber,
        _ => AstraColors.cyan,
      };

  bool get _isOverdue {
    if (task.isCompleted || task.dueDate == null) return false;
    final now = DateTime.now();
    return task.dueDate!.isBefore(DateTime(now.year, now.month, now.day));
  }

  /// Returns true if the description is useful, non-empty, non-redundant, and non-malformed.
  bool get _shouldShowDescription {
    if (task.description == null) return false;
    final desc = task.description!.trim();
    if (desc.isEmpty) return false;

    // Filter out useless/malformed tiny strings (e.g. "t", "/", "-", ".")
    if (desc.length <= 1) return false;

    final titleLower = task.title.trim().toLowerCase();
    final descLower = desc.toLowerCase();

    // Filter out identical or redundant description (e.g. "Dear students" / "Dear students")
    if (descLower == titleLower) return false;
    if (titleLower.startsWith(descLower) && descLower.length > 4) return false;
    if (descLower.startsWith(titleLower) && titleLower.length > 4) return false;

    return true;
  }

  String? _formatDateSubtitle() {
    if (task.recurrenceRule != null) {
      final freq = task.recurrenceRule!.frequency.name.toLowerCase();
      final timeStr = DateFormat('h:mm a').format(
        DateTime(2026, 1, 1, task.recurrenceRule!.hour, task.recurrenceRule!.minute),
      );
      String base;
      if (freq == 'weekdays') {
        base = 'Weekdays · $timeStr';
      } else if (freq == 'daily') {
        base = 'Daily · $timeStr';
      } else if (freq == 'weekly') {
        base = 'Weekly · $timeStr';
      } else if (freq == 'monthly') {
        base = 'Monthly · $timeStr';
      } else {
        base = 'Repeats · $timeStr';
      }

      if (task.recurrenceRule!.endDate != null) {
        base += ' · until ${DateFormat('d MMM').format(task.recurrenceRule!.endDate!)}';
      }
      return base;
    }

    if (task.isDuration && task.startAt != null && task.endAt != null) {
      final days = task.endAt!.difference(task.startAt!).inDays + 1;
      return '${DateFormat('d MMM').format(task.startAt!)} – ${DateFormat('d MMM').format(task.endAt!)} · $days Days';
    }

    if (task.dueDate != null) {
      final due = task.dueDate!;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final taskDay = DateTime(due.year, due.month, due.day);
      final difference = taskDay.difference(today).inDays;
      final timeStr = DateFormat('h:mm a').format(due);

      if (difference == 0) return 'Today · $timeStr';
      if (difference == 1) return 'Tomorrow · $timeStr';
      if (difference == -1) return 'Yesterday · $timeStr';
      if (difference > 1 && difference < 7) {
        return '${DateFormat('EEE').format(due)} · $timeStr';
      }
      return '${DateFormat('d MMM').format(due)} · $timeStr';
    }

    if (task.dueTime != null) {
      try {
        final parts = task.dueTime!.split(':');
        final h = int.parse(parts[0]);
        final m = int.parse(parts[1]);
        return DateFormat('h:mm a').format(DateTime(2026, 1, 1, h, m));
      } catch (_) {
        return task.dueTime;
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final color = _priorityColor();
    final isOverdue = _isOverdue;
    final dateStr = _formatDateSubtitle();
    final hasValidDescription = _shouldShowDescription;

    final cardContent = Container(
      margin: const EdgeInsets.only(bottom: 7),
      decoration: BoxDecoration(
        color: task.isCompleted ? AstraColors.surface0 : AstraColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: task.isCompleted
              ? AstraColors.borderSoft
              : isOverdue
                  ? AstraDepthColors.redBorder
                  : AstraColors.edgeSoft,
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: AstraColors.depth,
            offset: Offset(0, 2.5),
            blurRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Priority color indicator bar
                Container(
                  width: 3.5,
                  height: hasValidDescription ? 52 : 38,
                  decoration: BoxDecoration(
                    color: task.isCompleted
                        ? AstraColors.textDisabled
                        : isOverdue
                            ? AstraColors.red
                            : color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 6),

                // Tactile Circle Checkbox with >= 44dp touch target
                GestureDetector(
                  key: const Key('task_card_checkbox'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    AstraHaptics.success();
                    onComplete();
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: task.isCompleted
                              ? AstraColors.lime
                              : (isOverdue ? AstraColors.red : color.withAlpha(200)),
                          width: 1.8,
                        ),
                        color: task.isCompleted ? AstraColors.lime : Colors.transparent,
                      ),
                      child: task.isCompleted
                          ? const Icon(LucideIcons.check, size: 14, color: Colors.black)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 4),

                // Main Details Column
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Prominent 1-2 line title with clean truncation
                      Text(
                        task.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                          color: task.isCompleted
                              ? AstraColors.textMuted
                              : AstraColors.textPrimary,
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: AstraColors.textMuted,
                        ),
                      ),

                      // Bounded non-redundant description preview (max 2 lines)
                      if (hasValidDescription) ...[
                        const SizedBox(height: 2),
                        Text(
                          task.description!.trim(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AstraColors.textMuted,
                            height: 1.25,
                          ),
                        ),
                      ],

                      const SizedBox(height: 4),

                      // Compact Metadata Row (Date, Recurrence, Org, Subtasks)
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 3,
                        children: [
                          // Due Date or Recurrence
                          if (dateStr != null)
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 160),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    task.recurrenceRule != null
                                        ? LucideIcons.repeat
                                        : (isOverdue ? LucideIcons.alertCircle : LucideIcons.clock),
                                    size: 11,
                                    color: isOverdue
                                        ? AstraColors.red
                                        : (task.recurrenceRule != null
                                            ? AstraColors.cyan
                                            : AstraColors.textMuted),
                                  ),
                                  const SizedBox(width: 3.5),
                                  Flexible(
                                    child: Text(
                                      dateStr,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w500,
                                        color: isOverdue
                                            ? AstraColors.red
                                            : (task.recurrenceRule != null
                                                ? AstraColors.cyan
                                                : AstraColors.textMuted),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Organization tag with safe max width
                          if (task.organization != null && task.organization!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: AstraColors.surface2,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AstraColors.edgeSoft, width: 0.8),
                              ),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 90),
                                child: Text(
                                  task.organization!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w600,
                                    color: AstraColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),

                          // Category tag
                          if (task.category != null && task.category!.isNotEmpty && task.organization == null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: AstraColors.surface2,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AstraColors.edgeSoft, width: 0.8),
                              ),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 90),
                                child: Text(
                                  '#${task.category}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w600,
                                    color: AstraColors.cyan,
                                  ),
                                ),
                              ),
                            ),

                          // Subtasks summary count
                          if (task.subtasks.isNotEmpty)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(LucideIcons.listTodo, size: 10.5, color: AstraColors.textMuted),
                                const SizedBox(width: 2.5),
                                Text(
                                  '${task.subtasks.completedCount}/${task.subtasks.length}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AstraColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                if (task.isImportant) ...[
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(Icons.star_rounded, size: 15, color: Color(0xFFFEF08A)),
                  ),
                ],

                // Right Status / Priority Badge
                if (onStatusCycle != null)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onStatusCycle,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: AstraColors.surface2,
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: AstraColors.edgeSoft, width: 0.8),
                      ),
                      child: Text(
                        task.isCompleted ? 'DONE' : task.priority.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: task.isCompleted ? AstraColors.lime : color,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: AstraColors.surface2,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: AstraColors.edgeSoft, width: 0.8),
                    ),
                    child: Text(
                      task.isCompleted ? 'DONE' : task.priority.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: task.isCompleted ? AstraColors.lime : color,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),

                if (onDelete != null)
                  IconButton(
                    icon: const Icon(LucideIcons.trash2, size: 15, color: AstraColors.textDisabled),
                    onPressed: () {
                      AstraHaptics.delete();
                      onDelete!();
                    },
                    padding: const EdgeInsets.only(left: 4),
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 44),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Delete task',
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    // Wrap with Dismissible for native Swipe Right (Complete) and Swipe Left (Delete)
    return Dismissible(
      key: ValueKey('dismissible_${task.id}'),
      direction: DismissDirection.horizontal,
      background: Container(
        margin: const EdgeInsets.only(bottom: 7),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: AstraColors.lime.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AstraColors.lime.withValues(alpha: 0.4)),
        ),
        child: const Row(
          children: [
            Icon(LucideIcons.checkCheck, color: AstraColors.lime, size: 20),
            SizedBox(width: 8),
            Text(
              'COMPLETE',
              style: TextStyle(
                color: AstraColors.lime,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 7),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: AstraColors.red.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AstraColors.red.withValues(alpha: 0.4)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'DELETE',
              style: TextStyle(
                color: AstraColors.red,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
            SizedBox(width: 8),
            Icon(LucideIcons.trash2, color: AstraColors.red, size: 20),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          AstraHaptics.success();
          onComplete();
          return false;
        } else if (direction == DismissDirection.endToStart) {
          if (onDelete != null) {
            AstraHaptics.delete();
            onDelete!();
            return true;
          }
          return false;
        }
        return false;
      },
      child: cardContent,
    );
  }
}
