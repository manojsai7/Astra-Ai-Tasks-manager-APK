import '../../models/task.dart';
import '../../models/task_intent.dart';
import '../../services/assistant/astra_recurrence_engine.dart';

/// Immutable representation of a fully resolved, canonical schedule state for a task.
///
/// Single source of truth for task bucketing, recurrence evaluation, reminder
/// eligibility, and user-visible schedule state.
class AstraResolvedSchedule {
  final DateTime? effectiveDueAt;
  final DateTime? nextOccurrence;
  final String? dueTime;
  final DateTime? startAt;
  final DateTime? endAt;
  final RecurrenceRule? recurrence;
  final DateTime? recurrenceStart;
  final DateTime? recurrenceEnd;
  final bool isRecurring;
  final bool isDuration;
  final bool isPast;
  final bool isUpcoming;
  final bool isOverdue;
  final bool isToday;
  final bool isTomorrow;
  final bool shouldScheduleReminder;
  final DateTime? reminderScheduleInstant;
  final String? reminderRejectionReason;

  const AstraResolvedSchedule({
    this.effectiveDueAt,
    this.nextOccurrence,
    this.dueTime,
    this.startAt,
    this.endAt,
    this.recurrence,
    this.recurrenceStart,
    this.recurrenceEnd,
    this.isRecurring = false,
    this.isDuration = false,
    this.isPast = false,
    this.isUpcoming = false,
    this.isOverdue = false,
    this.isToday = false,
    this.isTomorrow = false,
    this.shouldScheduleReminder = false,
    this.reminderScheduleInstant,
    this.reminderRejectionReason,
  });

  @override
  String toString() => 'AstraResolvedSchedule('
      'effectiveDueAt: $effectiveDueAt, '
      'nextOccurrence: $nextOccurrence, '
      'isRecurring: $isRecurring, '
      'isUpcoming: $isUpcoming, '
      'isOverdue: $isOverdue, '
      'shouldScheduleReminder: $shouldScheduleReminder, '
      'reminderInstant: $reminderScheduleInstant, '
      'rejection: $reminderRejectionReason)';
}

/// Canonical scheduling engine for ASTRA.
///
/// Invariants:
/// - recurring tasks are classified from their next valid occurrence, never a stale seed date;
/// - one-shot past times are overdue but never scheduled as new alarms;
/// - no-date + time remains valid, including recurring tasks;
/// - date, time, recurrence, duration and reminder semantics are resolved together.
class AstraScheduleResolver {
  const AstraScheduleResolver();

  static const AstraRecurrenceEngine _recurrenceEngine = AstraRecurrenceEngine();

  static AstraResolvedSchedule resolve({
    Task? task,
    TaskIntent? intent,
    DateTime? dueDate,
    String? dueTime,
    DateTime? startAt,
    DateTime? endAt,
    RecurrenceRule? recurrenceRule,
    bool isCompleted = false,
    String? status,
    DateTime? now,
    int reminderOffsetMinutes = 0,
    bool reminderEnabled = true,
  }) {
    final current = now ?? DateTime.now();
    final todayStart = DateTime(current.year, current.month, current.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));
    final dayAfterTomorrowStart = tomorrowStart.add(const Duration(days: 1));

    final rawDueDate = dueDate ?? task?.dueDate ?? intent?.dueDate;
    final rawDueTime = dueTime ?? task?.dueTime ?? intent?.dueTime;
    final rawStartAt = startAt ?? task?.startAt ?? intent?.startAt;
    final rawEndAt = endAt ?? task?.endAt ?? intent?.endAt;
    final rawRecurrence = recurrenceRule ?? task?.recurrenceRule ?? intent?.recurrenceRule;
    final taskStatus = status ?? task?.status ?? intent?.status;
    final taskCompleted = isCompleted || task?.isCompleted == true || taskStatus == 'completed';

    if (taskCompleted || taskStatus == 'cancelled') {
      return AstraResolvedSchedule(
        effectiveDueAt: rawDueDate ?? rawStartAt,
        dueTime: rawDueTime,
        startAt: rawStartAt,
        endAt: rawEndAt,
        recurrence: rawRecurrence,
        isRecurring: rawRecurrence != null && rawRecurrence.frequency != RecurrenceFrequency.none,
        isPast: true,
        shouldScheduleReminder: false,
        reminderRejectionReason: 'completed',
      );
    }

    // 1. Duration / event semantics.
    if (rawStartAt != null && rawEndAt != null) {
      final isUpcoming = rawEndAt.isAfter(current);
      final isPast = !isUpcoming;
      final isOverdue = rawEndAt.isBefore(current);
      final isToday = rawStartAt.isBefore(tomorrowStart) && rawEndAt.isAfter(todayStart);
      final isTomorrow = !isToday && rawStartAt.isBefore(dayAfterTomorrowStart) && rawEndAt.isAfter(tomorrowStart);

      final reminderInstant = reminderEnabled
          ? rawStartAt.subtract(Duration(minutes: reminderOffsetMinutes))
          : null;
      final shouldRemind = reminderInstant != null && reminderInstant.isAfter(current);

      return AstraResolvedSchedule(
        effectiveDueAt: rawStartAt,
        nextOccurrence: isUpcoming ? rawStartAt : null,
        dueTime: rawDueTime,
        startAt: rawStartAt,
        endAt: rawEndAt,
        isDuration: true,
        isPast: isPast,
        isUpcoming: isUpcoming,
        isOverdue: isOverdue,
        isToday: isToday,
        isTomorrow: isTomorrow,
        shouldScheduleReminder: shouldRemind,
        reminderScheduleInstant: shouldRemind ? reminderInstant : null,
        reminderRejectionReason: !reminderEnabled ? 'disabled' : (!shouldRemind ? 'past' : null),
      );
    }

    // 2. Recurrence semantics are authoritative over stale dueDate values.
    if (rawRecurrence != null && rawRecurrence.frequency != RecurrenceFrequency.none) {
      var rule = rawRecurrence;
      if (rawDueTime != null && rawDueTime.contains(':')) {
        final parts = rawDueTime.split(':');
        final hour = int.tryParse(parts.first);
        final minute = int.tryParse(parts.length > 1 ? parts[1] : '0');
        if (hour != null && minute != null && (rule.hour != hour || rule.minute != minute)) {
          rule = rule.copyWith(hour: hour, minute: minute);
        }
      }

      final nextOcc = _recurrenceEngine.nextOccurrence(rule, current);
      final hasFutureOccurrence = nextOcc != null && nextOcc.isAfter(current);
      final isToday = hasFutureOccurrence &&
          nextOcc!.year == current.year && nextOcc.month == current.month && nextOcc.day == current.day;
      final isTomorrow = hasFutureOccurrence &&
          nextOcc!.year == tomorrowStart.year &&
          nextOcc.month == tomorrowStart.month &&
          nextOcc.day == tomorrowStart.day;

      DateTime? reminderInstant;
      bool shouldRemind = false;
      String? rejectionReason;
      if (!reminderEnabled) {
        rejectionReason = 'disabled';
      } else if (nextOcc == null) {
        rejectionReason = 'no_future_occurrence';
      } else {
        reminderInstant = nextOcc.subtract(Duration(minutes: reminderOffsetMinutes));
        if (reminderInstant.isAfter(current)) {
          shouldRemind = true;
        } else if (nextOcc.isAfter(current)) {
          // Never schedule a past offset. The occurrence itself remains valid.
          reminderInstant = nextOcc;
          shouldRemind = true;
        } else {
          rejectionReason = 'past';
        }
      }

      final normalizedTime = '${rule.hour.toString().padLeft(2, '0')}:${rule.minute.toString().padLeft(2, '0')}';

      return AstraResolvedSchedule(
        effectiveDueAt: nextOcc ?? rawDueDate,
        nextOccurrence: nextOcc,
        dueTime: normalizedTime,
        recurrence: rule,
        recurrenceStart: rule.startDate,
        recurrenceEnd: rule.endDate,
        isRecurring: true,
        isPast: nextOcc == null,
        isUpcoming: hasFutureOccurrence,
        // Recurrence does not become overdue merely because a seed dueDate is stale.
        isOverdue: false,
        isToday: isToday,
        isTomorrow: isTomorrow,
        shouldScheduleReminder: shouldRemind,
        reminderScheduleInstant: shouldRemind ? reminderInstant : null,
        reminderRejectionReason: rejectionReason,
      );
    }

    // 3. One-shot deadline / floating time semantics.
    if (rawDueDate != null || rawDueTime != null) {
      var hour = 0;
      var minute = 0;
      var hasExplicitTime = false;

      if (rawDueTime != null && rawDueTime.contains(':')) {
        final parts = rawDueTime.split(':');
        hour = int.tryParse(parts[0]) ?? 0;
        minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
        hasExplicitTime = true;
      } else if (rawDueDate != null && (rawDueDate.hour != 0 || rawDueDate.minute != 0)) {
        hour = rawDueDate.hour;
        minute = rawDueDate.minute;
        hasExplicitTime = true;
      }

      DateTime effectiveInstant;
      if (rawDueDate != null) {
        if (hasExplicitTime) {
          effectiveInstant = DateTime(rawDueDate.year, rawDueDate.month, rawDueDate.day, hour, minute);
        } else {
          // All-day due date: treat the end of the selected date as the effective deadline.
          effectiveInstant = DateTime(rawDueDate.year, rawDueDate.month, rawDueDate.day, 23, 59, 59);
        }
      } else {
        final todayCandidate = DateTime(current.year, current.month, current.day, hour, minute);
        effectiveInstant = todayCandidate.isAfter(current)
            ? todayCandidate
            : todayCandidate.add(const Duration(days: 1));
      }

      final isUpcoming = effectiveInstant.isAfter(current);
      final isPast = !isUpcoming;
      final isToday = effectiveInstant.isAfter(todayStart) && effectiveInstant.isBefore(tomorrowStart);
      final isTomorrow = !isToday &&
          (effectiveInstant.isAtSameMomentAs(tomorrowStart) || effectiveInstant.isAfter(tomorrowStart)) &&
          effectiveInstant.isBefore(dayAfterTomorrowStart);
      final isOverdue = !isUpcoming && effectiveInstant.isBefore(current);

      DateTime? reminderInstant;
      bool shouldRemind = false;
      String? rejectionReason;
      if (!reminderEnabled) {
        rejectionReason = 'disabled';
      } else {
        reminderInstant = effectiveInstant.subtract(Duration(minutes: reminderOffsetMinutes));
        if (reminderInstant.isAfter(current)) {
          shouldRemind = true;
        } else {
          rejectionReason = 'past';
        }
      }

      final normalizedTime = hasExplicitTime
          ? '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}'
          : null;

      return AstraResolvedSchedule(
        effectiveDueAt: effectiveInstant,
        nextOccurrence: isUpcoming ? effectiveInstant : null,
        dueTime: normalizedTime,
        isPast: isPast,
        isUpcoming: isUpcoming,
        isOverdue: isOverdue,
        isToday: isToday,
        isTomorrow: isTomorrow,
        shouldScheduleReminder: shouldRemind,
        reminderScheduleInstant: shouldRemind ? reminderInstant : null,
        reminderRejectionReason: rejectionReason,
      );
    }

    return const AstraResolvedSchedule(
      effectiveDueAt: null,
      nextOccurrence: null,
      dueTime: null,
      reminderRejectionReason: 'unscheduled',
    );
  }

  static DateTime? resolveNextOccurrenceAfter(
    RecurrenceRule rule,
    DateTime completedOcc, {
    DateTime? now,
  }) {
    if (rule.frequency == RecurrenceFrequency.none) return null;
    final current = now ?? DateTime.now();
    final searchAfter = completedOcc.isAfter(current) ? completedOcc : current;
    return _recurrenceEngine.nextOccurrence(rule, searchAfter);
  }
}
