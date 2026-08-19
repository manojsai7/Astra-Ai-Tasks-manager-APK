import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../services/haptics/astra_haptics.dart';
import '../../services/task/astra_schedule_item.dart';
import 'astra_agenda_view.dart';

/// 7-day week schedule view with top weekday selector and selected day timeline.
class AstraWeekView extends ConsumerWidget {
  final List<AstraScheduleItem> items;
  final DateTime selectedDate;
  final Function(DateTime date) onDateSelected;

  const AstraWeekView({
    super.key,
    required this.items,
    required this.selectedDate,
    required this.onDateSelected,
  });

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Calculate Monday of current selected week
    final weekday = selectedDate.weekday; // 1 = Mon
    final monday = selectedDate.subtract(Duration(days: weekday - 1));
    final weekDays = List.generate(7, (i) => monday.add(Duration(days: i)));
    final now = DateTime.now();

    // Filter items for the selected day
    final selectedDayItems = items.where((item) => _isSameDay(item.startAt, selectedDate)).toList();

    return Column(
      children: [
        // Weekday Strip
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: const BoxDecoration(
            color: Color(0xFF12141A),
            border: Border(bottom: BorderSide(color: Color(0xFF1E222B))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekDays.map((day) {
              final isSelected = _isSameDay(day, selectedDate);
              final isToday = _isSameDay(day, now);
              final dayTaskCount = items.where((it) => _isSameDay(it.startAt, day)).length;

              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    AstraHaptics.selection();
                    onDateSelected(day);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF1C2230)
                          : (isToday ? const Color(0x1400E5FF) : Colors.transparent),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF00E5FF)
                            : (isToday ? const Color(0x4D00E5FF) : Colors.transparent),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat('E').format(day).substring(0, 1),
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFF00E5FF)
                                : (isToday ? const Color(0xFFCEFF00) : Colors.white38),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('d').format(day),
                          style: TextStyle(
                            color: isSelected ? Colors.white : (isToday ? Colors.white : Colors.white70),
                            fontSize: 15,
                            fontWeight: isSelected || isToday ? FontWeight.w700 : FontWeight.w500,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Dot indicator
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: dayTaskCount > 0
                                ? (isSelected ? const Color(0xFF00E5FF) : const Color(0xFF38BDF8))
                                : Colors.transparent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // Selected Day Schedule
        Expanded(
          child: AstraAgendaView(
            items: selectedDayItems,
            selectedDate: selectedDate,
          ),
        ),
      ],
    );
  }
}
