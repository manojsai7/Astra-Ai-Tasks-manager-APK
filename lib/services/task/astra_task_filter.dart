import '../../core/scheduling/astra_schedule_resolver.dart';
import '../../core/time/astra_time_service.dart';
import '../../models/task.dart';
import '../assistant/astra_recurrence_engine.dart';

/// Centralized task filtering/bucketing built on the canonical schedule resolver.
class AstraTaskFilter {
  const AstraTaskFilter();

  static const AstraScheduleResolver _resolver = AstraScheduleResolver();
  static const Duration defaultUpcomingHorizon = Duration(days: 365);

  static bool isActive(Task task) {
    if (task.isCompleted) return false;
    if (task.status == 'completed' || task.status == 'cancelled') return false;
    return true;
  }

  static AstraResolvedSchedule resolve(Task task, {DateTime? referenceTime}) =>
      _resolver.resolve(task, now: referenceTime);

  static bool isUpcoming(
    Task task, {
    AstraTimeService? timeService,
    DateTime? referenceTime,
    Duration? horizon = defaultUpcomingHorizon,
  }) {
    if (!isActive(task)) return false;
    final now = referenceTime ?? (timeService != null ? timeService.now() : DateTime.now());
    final schedule = resolve(task, referenceTime: now);
    if (!schedule.isUpcoming) return false;
    if (horizon != null && schedule.effectiveDueAt != null &&
        schedule.effectiveDueAt!.isAfter(now.add(horizon))) {
      return false;
    }
    return true;
  }

  /// A recurring task is never overdue merely because its stored seed dueDate
  /// is in the past. Its next valid occurrence is the authoritative target.
  static bool isOverdue(
    Task task, {
    AstraTimeService? timeService,
    DateTime? referenceTime,
  }) {
    if (!isActive(task)) return false;
    final now = referenceTime ?? (timeService != null ? timeService.now() : DateTime.now());
    final schedule = resolve(task, referenceTime: now);
    if (schedule.isRecurring) return false;
    return schedule.isPast;
  }

  static bool isMyDay(
    Task task, {
    AstraTimeService? timeService,
    DateTime? referenceTime,
  }) {
    if (!isActive(task)) return false;
    final now = referenceTime ?? (timeService != null ? timeService.now() : DateTime.now());
    if (isOverdue(task, referenceTime: now)) return true;
    return isToday(task, referenceTime: now);
  }

  static bool isToday(
    Task task, {
    AstraTimeService? timeService,
    DateTime? referenceTime,
  }) {
    if (!isActive(task)) return false;
    final now = referenceTime ?? (timeService != null ? timeService.now() : DateTime.now());
    final target = resolve(task, referenceTime: now).effectiveDueAt;
    if (target == null) return false;
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    return !target.isBefore(today) && target.isBefore(tomorrow);
  }

  static bool isImportant(Task task) => isActive(task) && task.isImportant;
  static bool isNoDate(Task task) => isActive(task) && task.isNoDate;

  static bool isInCustomList(Task task, String listName) {
    if (!isActive(task)) return false;
    return task.category?.toLowerCase().trim() == listName.toLowerCase().trim();
  }

  static DateTime? getEffectiveDate(Task task, {DateTime? now}) =>
      resolve(task, referenceTime: now).effectiveDueAt;

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
      if (task.status == 'cancelled') continue;

      final schedule = resolve(task, referenceTime: now);
      if (schedule.isRecurring) recurringTasks.add(task);

      // Recurring schedules are classified from nextOccurrence, never from a
      // historical dueDate. An expired recurrence window simply has no target.
      if (isOverdue(task, referenceTime: now)) {
        overdue.add(task);
        continue;
      }

      final target = schedule.effectiveDueAt;
      if (target == null) {
        noDateTasks.add(task);
        continue;
      }

      // Active duration/range tasks retain their interval semantics.
      if (!schedule.isRecurring && task.startAt != null && task.endAt != null) {
        final start = task.startAt!;
        final end = task.endAt!;
        if (start.isBefore(tomorrowStart) && !end.isBefore(todayStart)) {
          todayTasks.add(task);
          if (end.isAfter(tomorrowStart)) {
            if (end.isBefore(nextWeekStart)) thisWeekTasks.add(task);
            else laterTasks.add(task);
          }
        } else if (!start.isBefore(tomorrowStart) && start.isBefore(dayAfterTomorrowStart)) {
          tomorrowTasks.add(task);
        } else if (!start.isBefore(dayAfterTomorrowStart) && start.isBefore(nextWeekStart)) {
          thisWeekTasks.add(task);
        } else if (!start.isBefore(nextWeekStart)) {
          laterTasks.add(task);
        }
        continue;
      }

      if (!target.isBefore(todayStart) && target.isBefore(tomorrowStart)) {
        todayTasks.add(task);
      } else if (!target.isBefore(tomorrowStart) && target.isBefore(dayAfterTomorrowStart)) {
        tomorrowTasks.add(task);
      } else if (!target.isBefore(dayAfterTomorrowStart) && target.isBefore(nextWeekStart)) {
        thisWeekTasks.add(task);
      } else if (!target.isBefore(nextWeekStart)) {
        laterTasks.add(task);
      }
    }

    return TaskBuckets(
      overdue: overdue,
      todayTasks: todayTasks,
      tomorrowTasks: tomorrowTasks,
      thisWeekTasks: thisWeekTasks,
      laterTasks: laterTasks,
      noDateTasks: noDateTasks,
      recurringTasks: recurringTasks,
      completedTasks: completedTasks,
      importantTasks: tasks.where(isImportant).toList(),
      upcomingCount: tasks.where((t) => isUpcoming(t, referenceTime: now, horizon: horizon)).length,
      allActiveCount: tasks.where(isActive).length,
    );
  }
}

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
