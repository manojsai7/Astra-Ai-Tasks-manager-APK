import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/haptics/astra_haptics.dart';
import '../../services/task/astra_schedule_item.dart';
import 'astra_agenda_view.dart';

/// Month calendar view with top grid and bottom selected day agenda.
class AstraMonthView extends ConsumerWidget {
  final List<AstraScheduleItem> items;
  final DateTime selectedDate;
  final Function(DateTime date) onDateSelected;

  const AstraMonthView({
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
    final year = selectedDate.year;
    final month = selectedDate.month;
    final firstDayOfMonth = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final startWeekday = firstDayOfMonth.weekday; // 1 = Mon, 7 = Sun
    final now = DateTime.now();

    // Day cells (leading blanks + month days)
    final totalCells = ((startWeekday - 1) + daysInMonth + 6) ~/ 7 * 7;

    // Filter items for selected date
    final selectedDayItems = items.where((it) => _isSameDay(it.startAt, selectedDate)).toList();

    return Column(
      children: [
        // Month Grid Container
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: Color(0xFF12141A),
            border: Border(bottom: BorderSide(color: Color(0xFF1E222B))),
          ),
          child: Column(
            children: [
              // Weekday Names
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((letter) {
                  return SizedBox(
                    width: 36,
                    child: Center(
                      child: Text(
                        letter,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),

              // Days Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: totalCells,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                  childAspectRatio: 1.3,
                ),
                itemBuilder: (context, index) {
                  final dayOffset = index - (startWeekday - 1);
                  if (dayOffset < 0 || dayOffset >= daysInMonth) {
                    return const SizedBox.shrink();
                  }

                  final dayNum = dayOffset + 1;
                  final dayDate = DateTime(year, month, dayNum);
                  final isSelected = _isSameDay(dayDate, selectedDate);
                  final isToday = _isSameDay(dayDate, now);
                  final dayCount = items.where((it) => _isSameDay(it.startAt, dayDate)).length;

                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      AstraHaptics.selection();
                      onDateSelected(dayDate);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF1E2433)
                            : (isToday ? const Color(0x1A00E5FF) : Colors.transparent),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF00E5FF)
                              : (isToday ? const Color(0x4D00E5FF) : Colors.transparent),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$dayNum',
                            style: TextStyle(
                              color: isSelected ? Colors.white : (isToday ? const Color(0xFFCEFF00) : Colors.white70),
                              fontSize: 13,
                              fontWeight: isSelected || isToday ? FontWeight.w700 : FontWeight.w500,
                              fontFamily: 'Inter',
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: dayCount > 0
                                  ? (isSelected ? const Color(0xFF00E5FF) : const Color(0xFF38BDF8))
                                  : Colors.transparent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        // Selected Day Schedule Items
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
