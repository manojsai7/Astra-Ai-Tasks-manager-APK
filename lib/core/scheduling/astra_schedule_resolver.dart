import '../../models/task.dart';
import '../../services/assistant/astra_recurrence_engine.dart';

/// Canonical, deterministic view of a task's schedule at a specific instant.
///
/// Every consumer that needs to answer "when is this task?" should use this
/// object rather than inspecting Task.dueDate directly.
class AstraResolvedSchedule {
  final DateTime? effectiveDueAt;
  final DateTime? nextOccurrence;
  final String? dueTime;
  final RecurrenceRule? recurrence;
  final DateTime? recurrenceStart;
  final DateTime? recurrenceEnd;
  final bool isRecurring;
  final bool isPast;
  final bool isUpcoming;
  final bool shouldScheduleReminder;

  const AstraResolvedSchedule({
    required this.effectiveDueAt,
    required this.nextOccurrence,
    required this.dueTime,
    required this.recurrence,
    required this.recurrenceStart,
    required this.recurrenceEnd,
    required this.isRecurring,
    required this.isPast,
    required this.isUpcoming,
    required this.shouldScheduleReminder,
  });
}

/// Single source of truth for task scheduling semantics.
class AstraScheduleResolver {
  const AstraScheduleResolver({this.recurrenceEngine = const AstraRecurrenceEngine()});

  final AstraRecurrenceEngine recurrenceEngine;

  AstraResolvedSchedule resolve(Task task, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final recurrence = task.recurrenceRule;
    final isRecurring = recurrence != null && recurrence.frequency != RecurrenceFrequency.none;

    if (isRecurring) {
      final next = recurrenceEngine.nextOccurrence(recurrence, reference);
      final hasNext = next != null;
      return AstraResolvedSchedule(
        effectiveDueAt: next,
        nextOccurrence: next,
        dueTime: task.dueTime ?? _formatTime(recurrence.hour, recurrence.minute),
        recurrence: recurrence,
        recurrenceStart: recurrence.startDate,
        recurrenceEnd: recurrence.endDate,
        isRecurring: true,
        isPast: !hasNext,
        isUpcoming: hasNext,
        shouldScheduleReminder: hasNext && next.isAfter(reference),
      );
    }

    final effective = _resolveOneShot(task);
    final isPast = effective != null && !effective.isAfter(reference);
    final isUpcoming = effective != null && effective.isAfter(reference);

    return AstraResolvedSchedule(
      effectiveDueAt: effective,
      nextOccurrence: null,
      dueTime: task.dueTime,
      recurrence: null,
      recurrenceStart: null,
      recurrenceEnd: null,
      isRecurring: false,
      isPast: isPast,
      isUpcoming: isUpcoming,
      shouldScheduleReminder: isUpcoming,
    );
  }

  DateTime? _resolveOneShot(Task task) {
    if (task.startAt != null) return task.startAt;
    if (task.dueDate == null) return null;
    if (task.dueTime == null || task.dueTime!.trim().isEmpty) return task.dueDate;

    final parts = task.dueTime!.split(':');
    if (parts.length != 2) return task.dueDate;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null || hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return task.dueDate;
    }

    return DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day, hour, minute);
  }

  String _formatTime(int hour, int minute) =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}
