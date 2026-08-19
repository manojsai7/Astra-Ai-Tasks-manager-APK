import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../providers/schedule_provider.dart';
import '../services/haptics/astra_haptics.dart';
import '../services/task/astra_schedule_item.dart';
import '../widgets/schedule/astra_agenda_view.dart';
import '../widgets/schedule/astra_day_view.dart';
import '../widgets/schedule/astra_week_view.dart';
import '../widgets/schedule/astra_month_view.dart';
import '../widgets/tasks/astra_task_creation_sheet.dart';

/// Full-featured ASTRA Schedule & Agenda Screen.
class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewMode = ref.watch(scheduleViewModeProvider);
    final selectedDate = ref.watch(scheduleSelectedDateProvider);
    final items = ref.watch(unifiedScheduleItemsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: Title & Sync / Plus
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  const Text(
                    'ASTRA SCHEDULE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const Spacer(),
                  // Add Button
                  GestureDetector(
                    key: const Key('schedule_add_button'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      AstraHaptics.light();
                      AstraTaskDetailSheet.create(context, initialDate: selectedDate);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF191D26),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF262C38)),
                      ),
                      child: const Icon(LucideIcons.plus, size: 18, color: Color(0xFF00E5FF)),
                    ),
                  ),
                ],
              ),
            ),

            // Date Navigation Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  // Prev
                  IconButton(
                    icon: const Icon(LucideIcons.chevronLeft, size: 20, color: Colors.white70),
                    onPressed: () async {
                      await AstraHaptics.selection();
                      final current = ref.read(scheduleSelectedDateProvider);
                      final mode = ref.read(scheduleViewModeProvider);
                      Duration delta;
                      switch (mode) {
                        case ScheduleViewMode.agenda:
                        case ScheduleViewMode.day:
                          delta = const Duration(days: 1);
                          break;
                        case ScheduleViewMode.week:
                          delta = const Duration(days: 7);
                          break;
                        case ScheduleViewMode.month:
                          final prevMonth = DateTime(current.year, current.month - 1, current.day);
                          ref.read(scheduleSelectedDateProvider.notifier).state = prevMonth;
                          return;
                      }
                      ref.read(scheduleSelectedDateProvider.notifier).state = current.subtract(delta);
                    },
                  ),

                  // Today button
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        await AstraHaptics.selection();
                        final now = DateTime.now();
                        ref.read(scheduleSelectedDateProvider.notifier).state = DateTime(now.year, now.month, now.day);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161922),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF262B37)),
                        ),
                        child: Center(
                          child: Text(
                            DateFormat('EEEE, d MMMM yyyy').format(selectedDate),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Next
                  IconButton(
                    icon: const Icon(LucideIcons.chevronRight, size: 20, color: Colors.white70),
                    onPressed: () async {
                      await AstraHaptics.selection();
                      final current = ref.read(scheduleSelectedDateProvider);
                      final mode = ref.read(scheduleViewModeProvider);
                      Duration delta;
                      switch (mode) {
                        case ScheduleViewMode.agenda:
                        case ScheduleViewMode.day:
                          delta = const Duration(days: 1);
                          break;
                        case ScheduleViewMode.week:
                          delta = const Duration(days: 7);
                          break;
                        case ScheduleViewMode.month:
                          final nextMonth = DateTime(current.year, current.month + 1, current.day);
                          ref.read(scheduleSelectedDateProvider.notifier).state = nextMonth;
                          return;
                      }
                      ref.read(scheduleSelectedDateProvider.notifier).state = current.add(delta);
                    },
                  ),
                ],
              ),
            ),

            // View Mode Switcher
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF14171E),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF222733)),
                ),
                child: Row(
                  children: ScheduleViewMode.values.map((mode) {
                    final isSelected = mode == viewMode;
                    return Expanded(
                      child: GestureDetector(
                        key: Key('view_mode_${mode.name}'),
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          AstraHaptics.selection();
                          ref.read(scheduleViewModeProvider.notifier).state = mode;
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF222938) : Colors.transparent,
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF00E5FF) : Colors.transparent,
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              mode.label,
                              style: TextStyle(
                                color: isSelected ? const Color(0xFF00E5FF) : Colors.white60,
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                letterSpacing: 0.8,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Active View Body
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: KeyedSubtree(
                  key: ValueKey('${viewMode.name}_${selectedDate.millisecondsSinceEpoch}'),
                  child: _buildViewContent(ref, viewMode, items, selectedDate),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewContent(
    WidgetRef ref,
    ScheduleViewMode mode,
    List<AstraScheduleItem> items,
    DateTime selectedDate,
  ) {
    switch (mode) {
      case ScheduleViewMode.agenda:
        return AstraAgendaView(
          items: items,
          selectedDate: selectedDate,
          onDateSelected: (date) {
            ref.read(scheduleSelectedDateProvider.notifier).state = date;
          },
        );
      case ScheduleViewMode.day:
        return AstraDayView(
          items: items,
          selectedDate: selectedDate,
        );
      case ScheduleViewMode.week:
        return AstraWeekView(
          items: items,
          selectedDate: selectedDate,
          onDateSelected: (date) {
            ref.read(scheduleSelectedDateProvider.notifier).state = date;
          },
        );
      case ScheduleViewMode.month:
        return AstraMonthView(
          items: items,
          selectedDate: selectedDate,
          onDateSelected: (date) {
            ref.read(scheduleSelectedDateProvider.notifier).state = date;
          },
        );
    }
  }
}
