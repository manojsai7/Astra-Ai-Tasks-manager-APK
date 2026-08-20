import '../../core/scheduling/astra_schedule_resolver.dart';
import '../../core/time/astra_time_service.dart';
import '../../models/task.dart';

/// Centralized, deterministic filtering and bucketing logic for ASTRA tasks.
///
/// Fully powered by [AstraScheduleResolver] as the single canonical source of truth for:
/// - Active task determination
/// - Canonical Upcoming predicate (one-shot, date-range, and recurring)
/// - Overdue and My Day predicates
/// - Temporal bucketing (Today, Tomorrow, This Week, Later, No Due Date)
class AstraTaskFilter {
  const AstraTaskFilter();

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
  static bool isUpcoming(
    Task task, {
    AstraTimeService? timeService,
    DateTime? referenceTime,
    Duration? horizon = defaultUpcomingHorizon,
  }) {
    if (!isActive(task)) return false;

    final now = referenceTime ?? (timeService != null ? timeService.now() : DateTime.now());
    final resolved = AstraScheduleResolver.resolve(task: task, now: now);

    if (!resolved.isUpcoming) return false;

    if (horizon != null && resolved.nextOccurrence != null) {
      final horizonEnd = now.add(horizon);
      if (resolved.nextOccurrence!.isAfter(horizonEnd)) return false;
    }

    return true;
  }

  /// Determines if an active task is Overdue.
  /// Note: Recurring tasks with future occurrences are NEVER overdue from a stale seed date!
  static bool isOverdue(
    Task task, {
    AstraTimeService? timeService,
    DateTime? referenceTime,
  }) {
    if (!isActive(task)) return false;

    final now = referenceTime ?? (timeService != null ? timeService.now() : DateTime.now());
    final resolved = AstraScheduleResolver.resolve(task: task, now: now);
    return resolved.isOverdue;
  }

  /// Determines if an active task belongs to "My Day" (Overdue OR scheduled for Today).
  static bool isMyDay(
    Task task, {
    AstraTimeService? timeService,
    DateTime? referenceTime,
  }) {
    if (!isActive(task)) return false;

    final now = referenceTime ?? (timeService != null ? timeService.now() : DateTime.now());
    final resolved = AstraScheduleResolver.resolve(task: task, now: now);

    return resolved.isOverdue || resolved.isToday;
  }

  /// Determines if an active task is scheduled for Today.
  static bool isToday(
    Task task, {
    AstraTimeService? timeService,
    DateTime? referenceTime,
  }) {
    if (!isActive(task)) return false;

    final now = referenceTime ?? (timeService != null ? timeService.now() : DateTime.now());
    final resolved = AstraScheduleResolver.resolve(task: task, now: now);
    return resolved.isToday;
  }

  /// Determines if an active task is scheduled for Tomorrow.
  static bool isTomorrow(
    Task task, {
    AstraTimeService? timeService,
    DateTime? referenceTime,
  }) {
    if (!isActive(task)) return false;

    final now = referenceTime ?? (timeService != null ? timeService.now() : DateTime.now());
    final resolved = AstraScheduleResolver.resolve(task: task, now: now);
    return resolved.isTomorrow;
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
    final resolved = AstraScheduleResolver.resolve(task: task, now: current);
    return resolved.nextOccurrence ?? resolved.effectiveDueAt;
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

      final resolved = AstraScheduleResolver.resolve(task: task, now: now);

      if (resolved.isRecurring) {
        recurringTasks.add(task);
      }

      // Check overdue first
      if (resolved.isOverdue) {
        overdue.add(task);
        continue;
      }

      // Date range / Duration tasks
      if (resolved.isDuration && resolved.startAt != null && resolved.endAt != null) {
        final start = resolved.startAt!;
        final end = resolved.endAt!;

        if (resolved.isToday) {
          todayTasks.add(task);
        }

        if (start.isBefore(tomorrowStart) && end.isAfter(tomorrowStart)) {
          if (end.isBefore(nextWeekStart)) {
            thisWeekTasks.add(task);
          } else {
            laterTasks.add(task);
          }
        } else if (resolved.isTomorrow) {
          tomorrowTasks.add(task);
        } else if ((start.isAfter(dayAfterTomorrowStart) || start.isAtSameMomentAs(dayAfterTomorrowStart)) &&
            start.isBefore(nextWeekStart)) {
          thisWeekTasks.add(task);
        } else if (start.isAfter(nextWeekStart) || start.isAtSameMomentAs(nextWeekStart)) {
          laterTasks.add(task);
        }
        continue;
      }

      // Recurring and one-shot tasks with target dates
      final targetDate = resolved.nextOccurrence ?? resolved.effectiveDueAt;
      if (targetDate != null) {
        if (resolved.isToday) {
          todayTasks.add(task);
        } else if (resolved.isTomorrow) {
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
