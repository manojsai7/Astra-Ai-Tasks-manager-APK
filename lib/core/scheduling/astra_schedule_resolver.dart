import '../../models/task.dart';
import '../../models/task_intent.dart';
import '../../services/assistant/astra_recurrence_engine.dart';

/// Immutable representation of a fully resolved, canonical schedule state for a task.
///
/// Single source of truth for:
/// - Task bucketing (Overdue, Today, Tomorrow, This Week, Later, No Date)
/// - Recurrence evaluation and next valid occurrence
/// - Reminder scheduling and past-time alarm rejection
/// - Task card display subtitles and status badges
class AstraResolvedSchedule {
  /// The effective instant for this task's active/current cycle.
  /// For recurring tasks: points to the current active or next valid occurrence.
  /// For one-shot tasks: the combined due date + time.
  /// Null if unscheduled (no date).
  final DateTime? effectiveDueAt;

  /// The next upcoming occurrence strictly after reference time (now).
  /// For recurring tasks: next valid future occurrence.
  /// For one-shot tasks: equal to effectiveDueAt if in future, null if in past.
  final DateTime? nextOccurrence;

  /// Normalized 'HH:mm' string (e.g. '20:00') if time is specified.
  final String? dueTime;

  /// Event / duration boundaries if applicable.
  final DateTime? startAt;
  final DateTime? endAt;

  /// Active recurrence rule, if any and not ended.
  final RecurrenceRule? recurrence;
  final DateTime? recurrenceStart;
  final DateTime? recurrenceEnd;

  /// Classification flags
  final bool isRecurring;
  final bool isDuration;
  final bool isPast;
  final bool isUpcoming;
  final bool isOverdue;
  final bool isToday;
  final bool isTomorrow;

  /// Reminder evaluation
  final bool shouldScheduleReminder;
  final DateTime? reminderScheduleInstant;
  final String? reminderRejectionReason; // 'past' | 'disabled' | 'unscheduled' | null

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
  String toString() {
    return 'AstraResolvedSchedule('
        'effectiveDueAt: $effectiveDueAt, '
        'nextOcc: $nextOccurrence, '
        'isRecurring: $isRecurring, '
        'isUpcoming: $isUpcoming, '
        'isOverdue: $isOverdue, '
        'isToday: $isToday, '
        'isTomorrow: $isTomorrow, '
        'shouldScheduleReminder: $shouldScheduleReminder, '
        'reminderInstant: $reminderScheduleInstant, '
        'rejection: $reminderRejectionReason)';
  }
}

/// Pure, deterministic canonical scheduling engine for ASTRA.
///
/// Implements all ASTRA Phase 5D.4 invariants:
/// 1. Recurring tasks NEVER become overdue due to a stale seed date.
/// 2. Bounded recurrence is evaluated strictly within [startDate, endDate].
/// 3. Expired one-shot deadlines are marked overdue, but reminders for past instants are strictly rejected.
/// 4. No-date + time + recurrence resolves dynamically without synthetic date anchors.
/// 5. Completed recurring tasks advance to the next valid cycle on the same DB row.
class AstraScheduleResolver {
  const AstraScheduleResolver();

  static const AstraRecurrenceEngine _recurrenceEngine = AstraRecurrenceEngine();

  /// Resolves the canonical schedule state for a [Task] or [TaskIntent] against a reference [now].
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

    // Extract input fields with fallback priority: explicit args -> task -> intent
    final rawDueDate = dueDate ?? task?.dueDate ?? intent?.dueDate;
    final rawDueTime = dueTime ?? task?.dueTime ?? intent?.dueTime;
    final rawStartAt = startAt ?? task?.startAt ?? intent?.startAt;
    final rawEndAt = endAt ?? task?.endAt ?? intent?.endAt;
    final rawRecurrence = recurrenceRule ?? task?.recurrenceRule ?? intent?.recurrenceRule;
    final taskCompleted = isCompleted ||
        task?.isCompleted == true ||
        task?.status == 'completed' ||
        intent?.status == 'completed' ||
        status == 'completed';

    // If completed or cancelled, return a terminal inactive schedule
    if (taskCompleted || status == 'cancelled') {
      return AstraResolvedSchedule(
        effectiveDueAt: rawDueDate ?? rawStartAt,
        dueTime: rawDueTime,
        startAt: rawStartAt,
        endAt: rawEndAt,
        recurrence: rawRecurrence,
        isRecurring: rawRecurrence != null && rawRecurrence.frequency != RecurrenceFrequency.none,
        isPast: true,
        isUpcoming: false,
        isOverdue: false,
        isToday: false,
        isTomorrow: false,
        shouldScheduleReminder: false,
        reminderRejectionReason: 'completed',
      );
    }

    // ── 1. Duration / Event Tasks (startAt & endAt provided) ─────────────────
    if (rawStartAt != null && rawEndAt != null) {
      final isEnded = rawEndAt.isBefore(current);
      final isOverdue = rawEndAt.isBefore(todayStart);
      final isUpcoming = rawEndAt.isAfter(current);
      final isToday = (rawStartAt.isBefore(tomorrowStart) && (rawEndAt.isAfter(todayStart) || rawEndAt.isAtSameMomentAs(todayStart)));
      final isTomorrow = !isToday && (rawStartAt.isAfter(tomorrowStart) || rawStartAt.isAtSameMomentAs(tomorrowStart)) && rawStartAt.isBefore(dayAfterTomorrowStart);

      DateTime? reminderInstant;
      bool shouldRemind = false;
      String? rejectionReason;

      if (reminderEnabled) {
        reminderInstant = rawStartAt.subtract(Duration(minutes: reminderOffsetMinutes));
        if (reminderInstant.isAfter(current)) {
          shouldRemind = true;
        } else {
          rejectionReason = 'past';
        }
      } else {
        rejectionReason = 'disabled';
      }

      return AstraResolvedSchedule(
        effectiveDueAt: rawStartAt,
        nextOccurrence: isUpcoming ? rawStartAt : null,
        dueTime: rawDueTime,
        startAt: rawStartAt,
        endAt: rawEndAt,
        isDuration: true,
        isPast: isEnded,
        isUpcoming: isUpcoming,
        isOverdue: isOverdue,
        isToday: isToday,
        isTomorrow: isTomorrow,
        shouldScheduleReminder: shouldRemind,
        reminderScheduleInstant: shouldRemind ? reminderInstant : null,
        reminderRejectionReason: rejectionReason,
      );
    }

    // ── 2. Recurring Tasks ──────────────────────────────────────────────────
    if (rawRecurrence != null && rawRecurrence.frequency != RecurrenceFrequency.none) {
      // Build normalized recurrence rule if time or dates need consolidation
      RecurrenceRule rule = rawRecurrence;
      if (rawDueTime != null && rawDueTime.contains(':')) {
        final parts = rawDueTime.split(':');
        final h = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        if (h != null && m != null && (rule.hour != h || rule.minute != m)) {
          rule = rule.copyWith(hour: h, minute: m);
        }
      }

      // Check if recurrence window has completely ended
      if (rule.isEnded || (rule.endDate != null && rule.endDate!.isBefore(current))) {
        return AstraResolvedSchedule(
          effectiveDueAt: rawDueDate,
          dueTime: rawDueTime,
          recurrence: rule,
          isRecurring: false,
          isPast: true,
          isUpcoming: false,
          isOverdue: rawDueDate != null && rawDueDate.isBefore(todayStart),
          isToday: false,
          isTomorrow: false,
          shouldScheduleReminder: false,
          reminderRejectionReason: 'recurrence_ended',
        );
      }

      // Calculate next valid occurrence strictly after now
      final nextOcc = _recurrenceEngine.nextOccurrence(rule, current);

      // Check if there was an occurrence scheduled for today
      final occToday = _recurrenceEngine.nextOccurrence(
        rule,
        todayStart.subtract(const Duration(seconds: 1)),
      );
      final bool hasTodayOcc = occToday != null &&
          (occToday.isAfter(todayStart) || occToday.isAtSameMomentAs(todayStart)) &&
          occToday.isBefore(tomorrowStart);

      final isUpcoming = nextOcc != null && nextOcc.isAfter(current);
      final isToday = nextOcc != null
          ? (nextOcc.year == current.year && nextOcc.month == current.month && nextOcc.day == current.day)
          : false;
      final isTomorrow = nextOcc != null
          ? (nextOcc.year == tomorrowStart.year && nextOcc.month == tomorrowStart.month && nextOcc.day == tomorrowStart.day)
          : false;

      // Invariant: Recurring active tasks are NEVER overdue from a stale seed date!
      const bool isOverdue = false;

      DateTime? reminderInstant;
      bool shouldRemind = false;
      String? rejectionReason;

      if (nextOcc != null) {
        if (reminderEnabled) {
          reminderInstant = nextOcc.subtract(Duration(minutes: reminderOffsetMinutes));
          if (reminderInstant.isAfter(current)) {
            shouldRemind = true;
          } else {
            // If the offset is in the past, but the occurrence itself is in the future, schedule at occurrence time
            if (nextOcc.isAfter(current) && reminderOffsetMinutes > 0) {
              reminderInstant = nextOcc;
              shouldRemind = true;
            } else {
              rejectionReason = 'past';
            }
          }
        } else {
          rejectionReason = 'disabled';
        }
      } else {
        rejectionReason = 'no_future_occurrence';
      }

      final normalizedTimeStr = '${rule.hour.toString().padLeft(2, '0')}:${rule.minute.toString().padLeft(2, '0')}';

      return AstraResolvedSchedule(
        effectiveDueAt: nextOcc ?? occToday ?? rawDueDate,
        nextOccurrence: nextOcc,
        dueTime: normalizedTimeStr,
        recurrence: rule,
        recurrenceStart: rule.startDate,
        recurrenceEnd: rule.endDate,
        isRecurring: true,
        isPast: nextOcc == null,
        isUpcoming: isUpcoming,
        isOverdue: isOverdue,
        isToday: isToday || (hasTodayOcc && nextOcc != null && isToday),
        isTomorrow: isTomorrow,
        shouldScheduleReminder: shouldRemind,
        reminderScheduleInstant: shouldRemind ? reminderInstant : null,
        reminderRejectionReason: rejectionReason,
      );
    }

    // ── 3. One-Shot Scheduled Tasks (Date, Time, or Date+Time) ────────────────
    if (rawDueDate != null || rawDueTime != null) {
      DateTime effectiveInstant;
      int hour = 9;
      int minute = 0;
      bool hasExplicitTime = false;

      if (rawDueTime != null && rawDueTime.contains(':')) {
        final parts = rawDueTime.split(':');
        hour = int.tryParse(parts[0]) ?? 9;
        minute = int.tryParse(parts[1]) ?? 0;
        hasExplicitTime = true;
      } else if (rawDueDate != null && (rawDueDate.hour != 0 || rawDueDate.minute != 0)) {
        hour = rawDueDate.hour;
        minute = rawDueDate.minute;
        hasExplicitTime = true;
      }

      if (rawDueDate != null) {
        effectiveInstant = DateTime(rawDueDate.year, rawDueDate.month, rawDueDate.day, hour, minute);
      } else {
        // Floating time without date (e.g. "8 PM") -> dynamically anchor to today (or tomorrow if past)
        final todayCandidate = DateTime(current.year, current.month, current.day, hour, minute);
        effectiveInstant = todayCandidate.isAfter(current) ? todayCandidate : todayCandidate.add(const Duration(days: 1));
      }

      final isPast = effectiveInstant.isBefore(current);
      final isUpcoming = effectiveInstant.isAfter(current);
      // Overdue if the scheduled date is strictly before today's 00:00 (or if past today with time elapsed)
      final isOverdue = effectiveInstant.isBefore(todayStart);
      final isToday = effectiveInstant.isAfter(todayStart) && effectiveInstant.isBefore(tomorrowStart) ||
          effectiveInstant.isAtSameMomentAs(todayStart);
      final isTomorrow = (effectiveInstant.isAfter(tomorrowStart) || effectiveInstant.isAtSameMomentAs(tomorrowStart)) &&
          effectiveInstant.isBefore(dayAfterTomorrowStart);

      DateTime? reminderInstant;
      bool shouldRemind = false;
      String? rejectionReason;

      if (reminderEnabled) {
        reminderInstant = effectiveInstant.subtract(Duration(minutes: reminderOffsetMinutes));
        if (reminderInstant.isAfter(current)) {
          shouldRemind = true;
        } else {
          // Reject past alarms strictly
          rejectionReason = 'past';
        }
      } else {
        rejectionReason = 'disabled';
      }

      final normalizedTimeStr = hasExplicitTime
          ? '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}'
          : null;

      return AstraResolvedSchedule(
        effectiveDueAt: effectiveInstant,
        nextOccurrence: isUpcoming ? effectiveInstant : null,
        dueTime: normalizedTimeStr,
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

    // ── 4. Unscheduled / No Date Tasks ───────────────────────────────────────
    return const AstraResolvedSchedule(
      effectiveDueAt: null,
      nextOccurrence: null,
      dueTime: null,
      isRecurring: false,
      isDuration: false,
      isPast: false,
      isUpcoming: false,
      isOverdue: false,
      isToday: false,
      isTomorrow: false,
      shouldScheduleReminder: false,
      reminderRejectionReason: 'unscheduled',
    );
  }

  /// Calculates the next occurrence after a completed occurrence [completedOcc] for recurring tasks.
  static DateTime? resolveNextOccurrenceAfter(
    RecurrenceRule rule,
    DateTime completedOcc, {
    DateTime? now,
  }) {
    if (rule.frequency == RecurrenceFrequency.none) return null;
    final current = now ?? DateTime.now();
    // Search strictly after max(completedOcc, current - 1s) to avoid returning an already-passed instant
    final searchAfter = completedOcc.isAfter(current) ? completedOcc : current;
    return _recurrenceEngine.nextOccurrence(rule, searchAfter);
  }
}
