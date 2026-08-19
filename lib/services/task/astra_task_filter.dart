import '../../core/time/astra_time_service.dart';
import '../../models/task.dart';
import '../assistant/astra_recurrence_engine.dart';

/// Centralized, deterministic filtering and bucketing logic for ASTRA tasks.
///
/// Implements the canonical rules for:
/// - Active task determination
/// - Canonical Upcoming predicate (one-shot, date-range, and recurring)
/// - Overdue and My Day predicates
/// - Temporal bucketing (Today, Tomorrow, This Week, Later, No Due Date)
class AstraTaskFilter {
  const AstraTaskFilter();

  static const AstraRecurrenceEngine _recurrenceEngine = AstraRecurrenceEngine();

  /// Default upcoming horizon: 365 days ahead.
  static const Duration defaultUpcomingHorizon = Duration(days: 365);

  /// Checks if a task is active (pending or in progress, not completed or cancelled).
  static bool isActive(Task task) {
    if (task.isCompleted) return false;
    if (task.status == 'completed' || task.status == 'cancelled') return false;
    return true;
  }

  /// Canonical definition of an UPCOMING task:
  /// - Status is active/pending (not completed, not cancelled)
  /// - Has a valid future occurrence/deadline/range intersecting `(now, now + horizon]`
  /// - Respects recurring next occurrence, date range intervals, and one-shot deadlines.
  static bool isUpcoming(
    Task task, {
    AstraTimeService? timeService,
    DateTime? referenceTime,
    Duration? horizon = defaultUpcomingHorizon,
  }) {
    if (!isActive(task)) return false;

    final now = referenceTime ?? (timeService != null ? timeService.now() : DateTime.now());
    final horizonEnd = horizon != null ? now.add(horizon) : null;

    // 1. Recurring tasks: check next future occurrence strictly after now
    if (task.recurrenceRule != null &&
        task.recurrenceRule!.frequency != RecurrenceFrequency.none) {
      final nextOcc = _recurrenceEngine.nextOccurrence(task.recurrenceRule!, now);
      if (nextOcc == null) return false;
      if (!nextOcc.isAfter(now)) return false;
      if (horizonEnd != null && nextOcc.isAfter(horizonEnd)) return false;
      return true;
    }

    // 2. Date-range / Duration tasks: [startAt, endAt]
    if (task.startAt != null && task.endAt != null) {
      final start = task.startAt!;
      final end = task.endAt!;

      // If the entire interval ended in the past (<= now), it's not upcoming
      if (end.isBefore(now) || end.isAtSameMomentAs(now)) return false;

      // If it starts beyond the upcoming horizon, it's outside the window
      if (horizonEnd != null && start.isAfter(horizonEnd)) return false;

      // The interval intersects (now, now + horizon]
      return true;
    }

    // 3. One-shot deadline / scheduled date
    final due = task.dueDate ?? task.startAt;
    if (due != null) {
      if (!due.isAfter(now)) return false;
      if (horizonEnd != null && due.isAfter(horizonEnd)) return false;
      return true;
    }

    // 4. No date task
    return false;
  }

  /// Determines if an active task is Overdue (strictly before today's 00:00).
  static bool isOverdue(
    Task task, {
    AstraTimeService? timeService,
    DateTime? referenceTime,
  }) {
    if (!isActive(task)) return false;

    final now = referenceTime ?? (timeService != null ? timeService.now() : DateTime.now());
    final todayStart = DateTime(now.year, now.month, now.day);

    // Date range task: overdue only if the end date is before today
    if (task.startAt != null && task.endAt != null) {
      return task.endAt!.isBefore(todayStart);
    }

    // One-shot task
    final due = task.dueDate ?? task.startAt;
    if (due != null) {
      return due.isBefore(todayStart);
    }

    return false;
  }

  /// Determines if an active task belongs to "My Day" (Overdue OR scheduled for Today).
  static bool isMyDay(
    Task task, {
    AstraTimeService? timeService,
    DateTime? referenceTime,
  }) {
    if (!isActive(task)) return false;

    final now = referenceTime ?? (timeService != null ? timeService.now() : DateTime.now());
    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));

    // Overdue tasks are surfaced in My Day
    if (isOverdue(task, referenceTime: now)) return true;

    // Recurring task occurrence for today
    if (task.recurrenceRule != null &&
        task.recurrenceRule!.frequency != RecurrenceFrequency.none) {
      final occ = _recurrenceEngine.nextOccurrence(
        task.recurrenceRule!,
        todayStart.subtract(const Duration(seconds: 1)),
      );
      if (occ != null && occ.isBefore(tomorrowStart) && (occ.isAfter(todayStart) || occ.isAtSameMomentAs(todayStart))) {
        return true;
      }
      return false;
    }

    // Date range task intersecting today
    if (task.startAt != null && task.endAt != null) {
      return task.startAt!.isBefore(tomorrowStart) &&
          (task.endAt!.isAfter(todayStart) || task.endAt!.isAtSameMomentAs(todayStart));
    }

    // One-shot task due today
    final due = task.dueDate ?? task.startAt;
    if (due != null) {
      return (due.isAfter(todayStart) || due.isAtSameMomentAs(todayStart)) &&
          due.isBefore(tomorrowStart);
    }

    return false;
  }

  /// Determines if an active task is scheduled for Today.
  static bool isToday(
    Task task, {
    AstraTimeService? timeService,
    DateTime? referenceTime,
  }) {
    if (!isActive(task)) return false;

    final now = referenceTime ?? (timeService != null ? timeService.now() : DateTime.now());
    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));

    // Recurring task occurrence for today
    if (task.recurrenceRule != null &&
        task.recurrenceRule!.frequency != RecurrenceFrequency.none) {
      final occ = _recurrenceEngine.nextOccurrence(
        task.recurrenceRule!,
        todayStart.subtract(const Duration(seconds: 1)),
      );
      if (occ != null && occ.isBefore(tomorrowStart) && (occ.isAfter(todayStart) || occ.isAtSameMomentAs(todayStart))) {
        return true;
      }
      return false;
    }

    // Date range task intersecting today
    if (task.startAt != null && task.endAt != null) {
      return task.startAt!.isBefore(tomorrowStart) &&
          (task.endAt!.isAfter(todayStart) || task.endAt!.isAtSameMomentAs(todayStart));
    }

    // One-shot task due today
    final due = task.dueDate ?? task.startAt;
    if (due != null) {
      return (due.isAfter(todayStart) || due.isAtSameMomentAs(todayStart)) &&
          due.isBefore(tomorrowStart);
    }

    return false;
  }

  /// Determines if an active task is Important (high or critical priority).
  static bool isImportant(Task task) {
    if (!isActive(task)) return false;
    return task.isImportant;
  }

  /// Determines if an active task has No Date.
  static bool isNoDate(Task task) {
    if (!isActive(task)) return false;
    return task.isNoDate;
  }

  /// Determines if a task belongs to a custom list (by category).
  static bool isInCustomList(Task task, String listName) {
    if (!isActive(task)) return false;
    return task.category?.toLowerCase().trim() == listName.toLowerCase().trim();
  }

  /// Calculates effective next date / time for display or sorting purposes.
  static DateTime? getEffectiveDate(
    Task task, {
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    if (task.recurrenceRule != null &&
        task.recurrenceRule!.frequency != RecurrenceFrequency.none) {
      return _recurrenceEngine.nextOccurrence(task.recurrenceRule!, current) ??
          task.dueDate ??
          task.startAt;
    }
    return task.startAt ?? task.dueDate;
  }

  /// Categorizes a list of tasks into standard sections.
  static TaskBuckets categorize(
    List<Task> tasks, {
    AstraTimeService? timeService,
    DateTime? referenceTime,
    Duration? horizon = defaultUpcomingHorizon,
  }) {
    final now = referenceTime ?? (timeService != null ? timeService.now() : DateTime.now());
    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));
    final dayAfterTomorrowStart = tomorrowStart.add(const Duration(days: 1));
    final nextWeekStart = todayStart.add(const Duration(days: 7));

    final overdue = <Task>[];
    final todayTasks = <Task>[];
    final tomorrowTasks = <Task>[];
    final thisWeekTasks = <Task>[];
    final laterTasks = <Task>[];
    final noDateTasks = <Task>[];
    final recurringTasks = <Task>[];
    final completedTasks = <Task>[];

    for (final task in tasks) {
      if (task.isCompleted || task.status == 'completed') {
        completedTasks.add(task);
        continue;
      }

      if (task.status == 'cancelled') {
        continue;
      }

      if (task.recurrenceRule != null &&
          task.recurrenceRule!.frequency != RecurrenceFrequency.none) {
        recurringTasks.add(task);
      }

      // Check overdue first
      if (isOverdue(task, referenceTime: now)) {
        overdue.add(task);
        continue;
      }

      // Date range tasks
      if (task.startAt != null && task.endAt != null) {
        final start = task.startAt!;
        final end = task.endAt!;

        // If it covers today
        if (start.isBefore(tomorrowStart) && (end.isAfter(todayStart) || end.isAtSameMomentAs(todayStart))) {
          todayTasks.add(task);
        }

        // If it extends into or starts in upcoming days
        if (start.isBefore(tomorrowStart) && end.isAfter(tomorrowStart)) {
          // Ongoing multi-day event continuing tomorrow / this week
          if (end.isBefore(nextWeekStart)) {
            thisWeekTasks.add(task);
          } else {
            laterTasks.add(task);
          }
        } else if ((start.isAfter(tomorrowStart) || start.isAtSameMomentAs(tomorrowStart)) &&
            start.isBefore(dayAfterTomorrowStart)) {
          tomorrowTasks.add(task);
        } else if ((start.isAfter(dayAfterTomorrowStart) || start.isAtSameMomentAs(dayAfterTomorrowStart)) &&
            start.isBefore(nextWeekStart)) {
          thisWeekTasks.add(task);
        } else if (start.isAfter(nextWeekStart) || start.isAtSameMomentAs(nextWeekStart)) {
          laterTasks.add(task);
        }
        continue;
      }

      // Recurring task bucketing
      if (task.recurrenceRule != null &&
          task.recurrenceRule!.frequency != RecurrenceFrequency.none) {
        // Occurrence for today
        final occToday = _recurrenceEngine.nextOccurrence(
          task.recurrenceRule!,
          todayStart.subtract(const Duration(seconds: 1)),
        );
        if (occToday != null &&
            (occToday.isAfter(todayStart) || occToday.isAtSameMomentAs(todayStart)) &&
            occToday.isBefore(tomorrowStart)) {
          todayTasks.add(task);
        }

        // Occurrence strictly after now
        final nextFutureOcc = _recurrenceEngine.nextOccurrence(task.recurrenceRule!, now);
        if (nextFutureOcc != null) {
          if ((nextFutureOcc.isAfter(tomorrowStart) || nextFutureOcc.isAtSameMomentAs(tomorrowStart)) &&
              nextFutureOcc.isBefore(dayAfterTomorrowStart)) {
            tomorrowTasks.add(task);
          } else if ((nextFutureOcc.isAfter(dayAfterTomorrowStart) || nextFutureOcc.isAtSameMomentAs(dayAfterTomorrowStart)) &&
              nextFutureOcc.isBefore(nextWeekStart)) {
            thisWeekTasks.add(task);
          } else if (nextFutureOcc.isAfter(nextWeekStart) || nextFutureOcc.isAtSameMomentAs(nextWeekStart)) {
            laterTasks.add(task);
          }
        }
        continue;
      }

      // One-shot deadline / scheduled date
      final targetDate = task.dueDate ?? task.startAt;
      if (targetDate != null) {
        if ((targetDate.isAfter(todayStart) || targetDate.isAtSameMomentAs(todayStart)) &&
            targetDate.isBefore(tomorrowStart)) {
          todayTasks.add(task);
        } else if ((targetDate.isAfter(tomorrowStart) || targetDate.isAtSameMomentAs(tomorrowStart)) &&
            targetDate.isBefore(dayAfterTomorrowStart)) {
          tomorrowTasks.add(task);
        } else if ((targetDate.isAfter(dayAfterTomorrowStart) || targetDate.isAtSameMomentAs(dayAfterTomorrowStart)) &&
            targetDate.isBefore(nextWeekStart)) {
          thisWeekTasks.add(task);
        } else if (targetDate.isAfter(nextWeekStart) || targetDate.isAtSameMomentAs(nextWeekStart)) {
          laterTasks.add(task);
        }
        continue;
      }

      // No due date or target date
      noDateTasks.add(task);
    }

    final upcomingCount = tasks.where((t) => isUpcoming(t, referenceTime: now, horizon: horizon)).length;
    final importantTasks = tasks.where(isImportant).toList();

    return TaskBuckets(
      overdue: overdue,
      todayTasks: todayTasks,
      tomorrowTasks: tomorrowTasks,
      thisWeekTasks: thisWeekTasks,
      laterTasks: laterTasks,
      noDateTasks: noDateTasks,
      recurringTasks: recurringTasks,
      completedTasks: completedTasks,
      importantTasks: importantTasks,
      upcomingCount: upcomingCount,
      allActiveCount: tasks.where(isActive).length,
    );
  }
}

/// Container for categorized task buckets.
class TaskBuckets {
  final List<Task> overdue;
  final List<Task> todayTasks;
  final List<Task> tomorrowTasks;
  final List<Task> thisWeekTasks;
  final List<Task> laterTasks;
  final List<Task> noDateTasks;
  final List<Task> recurringTasks;
  final List<Task> completedTasks;
  final List<Task> importantTasks;
  final int upcomingCount;
  final int allActiveCount;

  const TaskBuckets({
    required this.overdue,
    required this.todayTasks,
    required this.tomorrowTasks,
    required this.thisWeekTasks,
    required this.laterTasks,
    required this.noDateTasks,
    required this.recurringTasks,
    required this.completedTasks,
    this.importantTasks = const [],
    required this.upcomingCount,
    required this.allActiveCount,
  });

  int get importantCount => importantTasks.length;
  int get noDateCount => noDateTasks.length;
}
