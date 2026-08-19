import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/task_provider.dart';
import '../../services/haptics/astra_haptics.dart';
import '../../services/task/astra_schedule_item.dart';
import '../tasks/astra_task_creation_sheet.dart';

/// 24-hour vertical timeline view for a single selected day.
class AstraDayView extends ConsumerStatefulWidget {
  final List<AstraScheduleItem> items;
  final DateTime selectedDate;

  const AstraDayView({
    super.key,
    required this.items,
    required this.selectedDate,
  });

  @override
  ConsumerState<AstraDayView> createState() => _AstraDayViewState();
}

class _AstraDayViewState extends ConsumerState<AstraDayView> {
  final ScrollController _scrollController = ScrollController();
  static const double _hourHeight = 64.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final now = DateTime.now();
      if (_isSameDay(widget.selectedDate, now)) {
        final targetOffset = ((now.hour - 1).clamp(0, 23)) * _hourHeight;
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(targetOffset);
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday = _isSameDay(widget.selectedDate, now);

    // Filter items belonging to this selected date
    final dayItems = widget.items.where((item) {
      return _isSameDay(item.startAt, widget.selectedDate);
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.only(bottom: 90),
          child: SizedBox(
            height: 24 * _hourHeight,
            child: Stack(
              children: [
                // 1. Hour Lines & Labels
                ...List.generate(24, (hour) {
                  final top = hour * _hourHeight;
                  final timeLabel = DateFormat('h a').format(DateTime(2026, 1, 1, hour));

                  return Positioned(
                    top: top,
                    left: 0,
                    right: 0,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 60,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: Text(
                              timeLabel,
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 1,
                            color: const Color(0xFF1E222B),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                // 2. Current Time Line Indicator
                if (isToday)
                  Positioned(
                    top: (now.hour + (now.minute / 60.0)) * _hourHeight,
                    left: 54,
                    right: 0,
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFCEFF00),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 2,
                            color: const Color(0xFFCEFF00),
                          ),
                        ),
                      ],
                    ),
                  ),

                // 3. Schedule Item Blocks
                ...dayItems.map((item) {
                  final startFraction = item.startAt.hour + (item.startAt.minute / 60.0);
                  final top = startFraction * _hourHeight;

                  double height = 48.0;
                  if (item.endAt != null && item.endAt!.isAfter(item.startAt)) {
                    final durationHours = item.endAt!.difference(item.startAt).inMinutes / 60.0;
                    height = (durationHours * _hourHeight).clamp(44.0, 240.0);
                  }

                  return Positioned(
                    top: top,
                    left: 68,
                    right: 16,
                    height: height,
                    child: _buildTimelineCard(context, item, height),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimelineCard(BuildContext context, AstraScheduleItem item, double height) {
    Color barColor = const Color(0xFF00E5FF);
    if (item.isGoogle) barColor = const Color(0xFF38BDF8);
    if (item.isPanchang) barColor = const Color(0xFFF59E0B);
    if (item.isRecurring) barColor = const Color(0xFFA78BFA);
    if (item.priority == 'high' || item.priority == 'critical') barColor = const Color(0xFFEF4444);

    final isCompact = height < 60;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161922),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: barColor.withValues(alpha: 0.4), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: item.isCompleted ? Colors.white38 : Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                          fontFamily: 'Inter',
                        ),
                      ),
                      if (!isCompact) ...[
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('h:mm a').format(item.startAt),
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
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
