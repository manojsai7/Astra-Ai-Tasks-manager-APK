// lib/services/task/astra_schedule_resolver.dart
// Canonical Scheduling Resolver (Phase 5D.4)
// Enforces ASTRA Blueprint Section 3.3 (One Source of Truth) & Section 7 (Canonical Scheduling Architecture).

enum AstraScheduleBucket {
  overdue,
  today,
  tomorrow,
  upcoming,
  unscheduled,
  completed,
}

enum AstraReminderRejectionReason {
  none,
  taskCompleted,
  noTargetTimestamp,
  pastDueTime,
  outsideRecurrenceWindow,
}

class AstraResolvedSchedule {
  final DateTime? effectiveDueAt;
  final DateTime? nextOccurrence;
  final String? dueTime;
  final DateTime? recurrenceStart;
  final DateTime? recurrenceEnd;
  final DateTime? effectiveReminderAt;
  final bool isRecurring;
  final bool isOverdue;
  final bool isToday;
  final bool isTomorrow;
  final bool isUpcoming;
  final bool isPast;
  final bool shouldScheduleReminder;
  final AstraReminderRejectionReason rejectionReason;
  final AstraScheduleBucket bucket;

  const AstraResolvedSchedule({
    required this.effectiveDueAt,
    required this.nextOccurrence,
    required this.dueTime,
    required this.recurrenceStart,
    required this.recurrenceEnd,
    required this.effectiveReminderAt,
    required this.isRecurring,
    required this.isOverdue,
    required this.isToday,
    required this.isTomorrow,
    required this.isUpcoming,
    required this.isPast,
    required this.shouldScheduleReminder,
    required this.rejectionReason,
    required this.bucket,
  });
}

/// Authoritative domain resolver for all ASTRA scheduling decisions:
/// Creation, Editing, Assistant Execution, Task Filtering, Schedule Views,
/// Reminder Eligibility, Completion (DONE), Snooze (+10m), and Backup Restore.
class AstraScheduleResolver {
  const AstraScheduleResolver._();

  /// Unified entrypoint supporting both dynamic `task` objects (via duck-typed or typed properties)
  /// and explicit field parameters so both PR #3 and PR #4 call sites work without conflict.
  static AstraResolvedSchedule resolve({
    dynamic task,
    bool? isCompleted,
    DateTime? dueDate,
    String? dueTime,
    bool? isRecurring,
    DateTime? Function(DateTime anchorNow)? computeNextOccurrence,
    DateTime? recurrenceStart,
    DateTime? recurrenceEnd,
    DateTime? explicitRemindAt,
    int? reminderOffsetMinutes,
    DateTime? snoozedUntil,
    DateTime? now,
  }) {
    final DateTime refNow = now ?? DateTime.now();

    final bool resolvedCompleted =
        isCompleted ??
        _readBool(task, () => task.isCompleted) ??
        (_readString(task, () => task.status) == 'completed');

    final DateTime? resolvedDueDate =
        dueDate ??
        _readDateTime(task, () => task.dueDate) ??
        _readDateTime(task, () => task.dueAt);

    final String? resolvedDueTime =
        dueTime ?? _readString(task, () => task.dueTime);

    final String? rawRuleJson = _readString(
      task,
      () => task.recurrenceRuleJson,
    );

    final bool resolvedRecurring =
        isRecurring ??
        (rawRuleJson != null &&
            rawRuleJson.trim().isNotEmpty &&
            !rawRuleJson.contains('"none"'));

    final DateTime? resolvedRemindAt =
        explicitRemindAt ?? _readDateTime(task, () => task.remindAt);

    return resolveFields(
      isCompleted: resolvedCompleted,
      dueDate: resolvedDueDate,
      dueTime: resolvedDueTime,
      isRecurring: resolvedRecurring,
      computeNextOccurrence: computeNextOccurrence,
      recurrenceStart: recurrenceStart,
      recurrenceEnd: recurrenceEnd,
      explicitRemindAt: resolvedRemindAt,
      reminderOffsetMinutes: reminderOffsetMinutes,
      snoozedUntil: snoozedUntil,
      now: refNow,
    );
  }

  /// Resolves the canonical schedule state from primitive task fields and a reference [now].
  ///
  /// Key Invariants (Blueprint Section 7):
  /// 1. Recurring tasks: A historical seed [dueDate] NEVER makes an active recurring task overdue
  ///    while a valid future [nextOccurrence] exists.
  /// 2. No date + time + recurrence ("Gym daily at 8 PM"): Valid recurring schedule anchored from [now].
  /// 3. Past one-shot tasks ("Exam today at 10 AM" when [now] is 3 PM): Classified as [overdue],
  ///    with [shouldScheduleReminder] = false and [rejectionReason] = [AstraReminderRejectionReason.pastDueTime].
  /// 4. Snooze isolation: If [snoozedUntil] is in the future, it overrides [effectiveReminderAt] for
  ///    the current occurrence without mutating the underlying recurrence rule or seed time.
  static AstraResolvedSchedule resolveFields({
    required bool isCompleted,
    required DateTime? dueDate,
    required String? dueTime,
    required bool isRecurring,
    required DateTime? Function(DateTime anchorNow)? computeNextOccurrence,
    required DateTime? recurrenceStart,
    required DateTime? recurrenceEnd,
    required DateTime? explicitRemindAt,
    required int? reminderOffsetMinutes,
    required DateTime? snoozedUntil,
    required DateTime now,
  }) {
    final String? normalizedDueTime = _normalizeTime(dueTime);

    if (isCompleted) {
      return AstraResolvedSchedule(
        effectiveDueAt: null,
        nextOccurrence: null,
        dueTime: normalizedDueTime,
        recurrenceStart: recurrenceStart,
        recurrenceEnd: recurrenceEnd,
        effectiveReminderAt: null,
        isRecurring: isRecurring,
        isOverdue: false,
        isToday: false,
        isTomorrow: false,
        isUpcoming: false,
        isPast: false,
        shouldScheduleReminder: false,
        rejectionReason: AstraReminderRejectionReason.taskCompleted,
        bucket: AstraScheduleBucket.completed,
      );
    }

    final DateTime? explicitDueAt = _combineDateAndTime(
      dueDate,
      normalizedDueTime,
    );
    DateTime? nextOccurrence;

    if (isRecurring) {
      if (recurrenceEnd != null && now.isAfter(_endOfDay(recurrenceEnd))) {
        nextOccurrence = null;
      } else if (explicitDueAt != null && explicitDueAt.isAfter(now)) {
        nextOccurrence = explicitDueAt;
      } else if (computeNextOccurrence != null) {
        nextOccurrence = computeNextOccurrence(now);
      } else if (normalizedDueTime != null) {
        nextOccurrence = _nextTimeAnchorFromNow(
          now: now,
          dueTime: normalizedDueTime,
          recurrenceStart: recurrenceStart,
          recurrenceEnd: recurrenceEnd,
        );
      }
    }

    final DateTime? effectiveDueAt = isRecurring
        ? nextOccurrence
        : explicitDueAt;

    if (effectiveDueAt == null) {
      return AstraResolvedSchedule(
        effectiveDueAt: null,
        nextOccurrence: null,
        dueTime: normalizedDueTime,
        recurrenceStart: recurrenceStart,
        recurrenceEnd: recurrenceEnd,
        effectiveReminderAt: null,
        isRecurring: isRecurring,
        isOverdue: false,
        isToday: false,
        isTomorrow: false,
        isUpcoming: false,
        isPast: false,
        shouldScheduleReminder: false,
        rejectionReason:
            isRecurring &&
                recurrenceEnd != null &&
                now.isAfter(_endOfDay(recurrenceEnd))
            ? AstraReminderRejectionReason.outsideRecurrenceWindow
            : AstraReminderRejectionReason.noTargetTimestamp,
        bucket: AstraScheduleBucket.unscheduled,
      );
    }

    final bool isPast = !effectiveDueAt.isAfter(now);
    final bool isOverdue = !isRecurring && isPast;

    final DateTime todayStart = DateTime(now.year, now.month, now.day);
    final DateTime tomorrowStart = todayStart.add(const Duration(days: 1));
    final DateTime dayAfterTomorrowStart = todayStart.add(
      const Duration(days: 2),
    );

    final bool isToday =
        !isOverdue &&
        !effectiveDueAt.isBefore(todayStart) &&
        effectiveDueAt.isBefore(tomorrowStart);
    final bool isTomorrow =
        !isOverdue &&
        !effectiveDueAt.isBefore(tomorrowStart) &&
        effectiveDueAt.isBefore(dayAfterTomorrowStart);
    final bool isUpcoming = !isOverdue && effectiveDueAt.isAfter(now);

    DateTime? candidateReminderAt;
    if (snoozedUntil != null && snoozedUntil.isAfter(now)) {
      candidateReminderAt = snoozedUntil;
    } else if (!isRecurring && explicitRemindAt != null) {
      candidateReminderAt = explicitRemindAt;
    } else if (reminderOffsetMinutes != null && reminderOffsetMinutes > 0) {
      candidateReminderAt = effectiveDueAt.subtract(
        Duration(minutes: reminderOffsetMinutes),
      );
    } else {
      candidateReminderAt = effectiveDueAt;
    }

    final bool shouldScheduleReminder = candidateReminderAt.isAfter(now);

    final AstraReminderRejectionReason rejectionReason = shouldScheduleReminder
        ? AstraReminderRejectionReason.none
        : AstraReminderRejectionReason.pastDueTime;

    final AstraScheduleBucket bucket;
    if (isOverdue) {
      bucket = AstraScheduleBucket.overdue;
    } else if (isToday) {
      bucket = AstraScheduleBucket.today;
    } else if (isTomorrow) {
      bucket = AstraScheduleBucket.tomorrow;
    } else {
      bucket = AstraScheduleBucket.upcoming;
    }

    return AstraResolvedSchedule(
      effectiveDueAt: effectiveDueAt,
      nextOccurrence: nextOccurrence,
      dueTime: normalizedDueTime,
      recurrenceStart: recurrenceStart,
      recurrenceEnd: recurrenceEnd,
      effectiveReminderAt: shouldScheduleReminder ? candidateReminderAt : null,
      isRecurring: isRecurring,
      isOverdue: isOverdue,
      isToday: isToday,
      isTomorrow: isTomorrow,
      isUpcoming: isUpcoming,
      isPast: isPast,
      shouldScheduleReminder: shouldScheduleReminder,
      rejectionReason: rejectionReason,
      bucket: bucket,
    );
  }

  static bool? _readBool(dynamic obj, bool? Function() getter) {
    if (obj == null) return null;
    try {
      return getter();
    } catch (_) {
      return null;
    }
  }

  static String? _readString(dynamic obj, String? Function() getter) {
    if (obj == null) return null;
    try {
      return getter();
    } catch (_) {
      return null;
    }
  }

  static DateTime? _readDateTime(dynamic obj, DateTime? Function() getter) {
    if (obj == null) return null;
    try {
      return getter();
    } catch (_) {
      return null;
    }
  }

  static String? _normalizeTime(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final parts = trimmed.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  static DateTime? _combineDateAndTime(DateTime? date, String? normalizedTime) {
    if (date == null) return null;
    if (normalizedTime == null) return date;
    final parts = normalizedTime.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  static DateTime? _nextTimeAnchorFromNow({
    required DateTime now,
    required String dueTime,
    required DateTime? recurrenceStart,
    required DateTime? recurrenceEnd,
  }) {
    final parts = dueTime.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    DateTime baseDate = DateTime(now.year, now.month, now.day, hour, minute);
    if (recurrenceStart != null) {
      final startCandidate = DateTime(
        recurrenceStart.year,
        recurrenceStart.month,
        recurrenceStart.day,
        hour,
        minute,
      );
      if (startCandidate.isAfter(baseDate)) {
        baseDate = startCandidate;
      }
    }

    if (!baseDate.isAfter(now)) {
      baseDate = baseDate.add(const Duration(days: 1));
    }

    if (recurrenceEnd != null && baseDate.isAfter(_endOfDay(recurrenceEnd))) {
      return null;
    }
    return baseDate;
  }

  static DateTime _endOfDay(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59, 999);
}
