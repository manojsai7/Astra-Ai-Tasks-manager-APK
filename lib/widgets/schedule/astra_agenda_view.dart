import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../providers/task_provider.dart';
import '../../services/haptics/astra_haptics.dart';
import '../../services/task/astra_schedule_item.dart';
import '../tasks/astra_task_creation_sheet.dart';

/// Chronological agenda view grouped by date sections.
class AstraAgendaView extends ConsumerWidget {
  final List<AstraScheduleItem> items;
  final DateTime selectedDate;
  final Function(DateTime date)? onDateSelected;

  const AstraAgendaView({
    super.key,
    required this.items,
    required this.selectedDate,
    this.onDateSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF161920),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF262B36)),
                ),
                child: const Icon(LucideIcons.calendarCheck, size: 28, color: Color(0xFF00E5FF)),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your schedule is clear',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'No tasks or events found in this window.',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Group items by calendar day
    final Map<DateTime, List<AstraScheduleItem>> grouped = {};
    for (final item in items) {
      final dayKey = DateTime(item.startAt.year, item.startAt.month, item.startAt.day);
      grouped.putIfAbsent(dayKey, () => []).add(item);
    }

    final sortedDays = grouped.keys.toList()..sort();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
      itemCount: sortedDays.length,
      itemBuilder: (context, index) {
        final day = sortedDays[index];
        final dayItems = grouped[day]!;

        String dayTitle;
        if (day == today) {
          dayTitle = 'TODAY · ';
        } else if (day == tomorrow) {
          dayTitle = 'TOMORROW · ';
        } else {
          dayTitle = DateFormat('EEEE, d MMMM').format(day).toUpperCase();
        }

        final isCurrentDay = day == today;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day Header
            Padding(
              padding: const EdgeInsets.only(top: 18, bottom: 10, left: 4),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 14,
                    decoration: BoxDecoration(
                      color: isCurrentDay ? const Color(0xFFCEFF00) : const Color(0xFF00E5FF),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    dayTitle,
                    style: TextStyle(
                      color: isCurrentDay ? const Color(0xFFCEFF00) : Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const Spacer(),
                  Text(
                    ' ',
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
            // Day Schedule Items
            ...dayItems.map((item) => _buildScheduleCard(context, ref, item)),
          ],
        );
      },
    );
  }

  Widget _buildScheduleCard(BuildContext context, WidgetRef ref, AstraScheduleItem item) {
    final isDone = item.isCompleted;
    final isGCal = item.isGoogle;
    final isPanch = item.isPanchang;

    Color accentColor = const Color(0xFF00E5FF); // default cool cyan
    IconData typeIcon = LucideIcons.checkSquare;
    String typeLabel = 'TASK';

    if (item.itemType == 'event' || item.endAt != null) {
      accentColor = const Color(0xFF38BDF8);
      typeIcon = LucideIcons.calendar;
      typeLabel = isGCal ? 'GOOGLE' : 'EVENT';
    } else if (item.isRecurring) {
      accentColor = const Color(0xFFA78BFA);
      typeIcon = LucideIcons.repeat;
      typeLabel = 'RECURRING';
    } else if (isPanch) {
      accentColor = const Color(0xFFF59E0B);
      typeIcon = LucideIcons.sparkles;
      typeLabel = 'PANCHANG';
    } else if (item.priority == 'high' || item.priority == 'critical') {
      accentColor = const Color(0xFFEF4444);
      typeIcon = LucideIcons.alertCircle;
      typeLabel = 'IMPORTANT';
    }

    final startTimeFmt = DateFormat('h:mm a').format(item.startAt);
    final timeStr = item.endAt != null
        ? ' – '
        : startTimeFmt;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF14171E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: item.isOverdue
              ? const Color(0x66EF4444)
              : const Color(0xFF222733),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            await AstraHaptics.light();
            if (context.mounted && item.originalTaskId != null) {
              final tasksAsync = ref.read(taskListProvider);
              final taskList = tasksAsync.value ?? [];
              final matched = taskList.where((t) => t.id == item.originalTaskId);
              if (matched.isNotEmpty) {
                AstraTaskDetailSheet.edit(context, task: matched.first);
              }
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Completion checkbox / Type indicator
                if (!isPanch && !isGCal)
                  GestureDetector(
                    onTap: () async {
                      if (item.originalTaskId != null) {
                        await AstraHaptics.success();
                        await ref.read(taskNotifierProvider.notifier).toggleComplete(item.originalTaskId!);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2, right: 12),
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDone ? const Color(0xFFCEFF00) : Colors.transparent,
                          border: Border.all(
                            color: isDone ? const Color(0xFFCEFF00) : const Color(0xFF3F4756),
                            width: 1.5,
                          ),
                        ),
                        child: isDone
                            ? const Icon(Icons.check, size: 14, color: Colors.black)
                            : null,
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(top: 2, right: 12),
                    child: Icon(typeIcon, size: 18, color: accentColor),
                  ),

                // Title & Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          color: isDone ? Colors.white38 : Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          decoration: isDone ? TextDecoration.lineThrough : null,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          // Time
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.clock, size: 12, color: Colors.white54),
                              const SizedBox(width: 4),
                              Text(
                                timeStr,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ),

                          // Type pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: accentColor.withValues(alpha: 0.3), width: 0.5),
                            ),
                            child: Text(
                              typeLabel,
                              style: TextStyle(
                                color: accentColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),

                          // Organization / location
                          if (item.organization != null && item.organization!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E232E),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item.organization!,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),

                          // Overdue badge
                          if (item.isOverdue)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0x33EF4444),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'OVERDUE',
                                style: TextStyle(
                                  color: Color(0xFFEF4444),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
