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
  final String? invalidReason;

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
    this.invalidReason,
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
      final hasNext = next != null && next.isAfter(reference);
      return AstraResolvedSchedule(
        effectiveDueAt: next,
        nextOccurrence: next,
        dueTime: task.dueTime ?? _formatTime(recurrence.hour, recurrence.minute),
        recurrence: recurrence,
        recurrenceStart: recurrence.startDate,
        recurrenceEnd: recurrence.endDate,
        isRecurring: true,
        isPast: false,
        isUpcoming: hasNext,
        shouldScheduleReminder: hasNext,
        invalidReason: next == null ? 'no_future_occurrence' : null,
      );
    }

    final effective = _resolveOneShot(task);
    if (effective == null) {
      return AstraResolvedSchedule(
        effectiveDueAt: null,
        nextOccurrence: null,
        dueTime: task.dueTime,
        recurrence: null,
        recurrenceStart: null,
        recurrenceEnd: null,
        isRecurring: false,
        isPast: false,
        isUpcoming: false,
        shouldScheduleReminder: false,
      );
    }

    final isFuture = effective.isAfter(reference);
    return AstraResolvedSchedule(
      effectiveDueAt: effective,
      nextOccurrence: null,
      dueTime: task.dueTime,
      recurrence: null,
      recurrenceStart: null,
      recurrenceEnd: null,
      isRecurring: false,
      isPast: !isFuture,
      isUpcoming: isFuture,
      shouldScheduleReminder: isFuture,
      invalidReason: isFuture ? null : 'past_time',
    );
  }

  /// Resolves a task that carries a standalone dueTime independently from its
  /// date anchor. If a date is present, the two are combined into one instant.
  DateTime? _resolveOneShot(Task task) {
    final anchor = task.dueDate;
    if (task.startAt != null && task.endAt != null) {
      return task.startAt;
    }
    if (anchor == null) return task.startAt;
    final rawTime = task.dueTime?.trim();
    if (rawTime == null || rawTime.isEmpty) return anchor;

    final parts = rawTime.split(':');
    if (parts.length != 2) return anchor;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null || hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return anchor;
    }

    return DateTime(anchor.year, anchor.month, anchor.day, hour, minute);
  }

  String _formatTime(int hour, int minute) =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}
