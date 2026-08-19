import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/task/astra_schedule_item.dart';
import 'task_provider.dart';

/// Available view modes for ASTRA Schedule.
enum ScheduleViewMode {
  agenda,
  day,
  week,
  month;

  String get label {
    switch (this) {
      case ScheduleViewMode.agenda:
        return 'AGENDA';
      case ScheduleViewMode.day:
        return 'DAY';
      case ScheduleViewMode.week:
        return 'WEEK';
      case ScheduleViewMode.month:
        return 'MONTH';
    }
  }
}

/// Selected schedule view mode (Default: AGENDA).
final scheduleViewModeProvider = StateProvider<ScheduleViewMode>((ref) {
  return ScheduleViewMode.agenda;
});

/// Centralized selected date for Schedule screen.
final scheduleSelectedDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

/// Provider for calculating schedule window start/end based on view mode and selected date.
final scheduleWindowProvider = Provider<({DateTime start, DateTime end})>((ref) {
  final viewMode = ref.watch(scheduleViewModeProvider);
  final selectedDate = ref.watch(scheduleSelectedDateProvider);

  switch (viewMode) {
    case ScheduleViewMode.agenda:
      // Agenda looks 30 days ahead from selected date (or 3 days back for recent items)
      final start = DateTime(selectedDate.year, selectedDate.month, selectedDate.day).subtract(const Duration(days: 2));
      final end = start.add(const Duration(days: 35));
      return (start: start, end: end);

    case ScheduleViewMode.day:
      final start = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
      final end = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 23, 59, 59);
      return (start: start, end: end);

    case ScheduleViewMode.week:
      // Start from Monday of the selected week
      final weekday = selectedDate.weekday; // 1 = Mon, 7 = Sun
      final monday = selectedDate.subtract(Duration(days: weekday - 1));
      final start = DateTime(monday.year, monday.month, monday.day);
      final end = start.add(const Duration(days: 7)).subtract(const Duration(seconds: 1));
      return (start: start, end: end);

    case ScheduleViewMode.month:
      final start = DateTime(selectedDate.year, selectedDate.month, 1);
      final nextMonth = DateTime(selectedDate.year, selectedDate.month + 1, 1);
      final end = nextMonth.subtract(const Duration(seconds: 1));
      return (start: start, end: end);
  }
});

/// Combines Drift tasks, recurring occurrences, and external events into a unified schedule list.
final unifiedScheduleItemsProvider = Provider<List<AstraScheduleItem>>((ref) {
  final taskListAsync = ref.watch(taskListProvider);
  final window = ref.watch(scheduleWindowProvider);

  final tasks = taskListAsync.value ?? [];

  return AstraScheduleItem.buildSchedule(
    tasks: tasks,
    windowStart: window.start,
    windowEnd: window.end,
    includeCompleted: true,
  );
});
