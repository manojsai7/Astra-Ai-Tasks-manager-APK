import '../../models/task.dart';
import '../assistant/astra_recurrence_engine.dart';

/// Unified representation for temporal presentation in ASTRA Schedule / Agenda.
///
/// Combines Tasks with dates, Reminders, and Calendar events into a single
/// temporal model without duplicating database storage.
class AstraScheduleItem {
  final String id;
  final String title;
  final DateTime startAt;
  final DateTime? endAt;
  final String itemType; // 'task' | 'reminder' | 'event' | 'panchang'
  final String priority; // 'low' | 'medium' | 'high' | 'critical'
  final String? organization;
  final RecurrenceRule? recurrenceRule;
  final bool isCompleted;
  final String? originalTaskId;
  final String? description;
  final String source; // 'local' | 'google' | 'panchang'
  final bool isOverdue;

  const AstraScheduleItem({
    required this.id,
    required this.title,
    required this.startAt,
    this.endAt,
    required this.itemType,
    this.priority = 'medium',
    this.organization,
    this.recurrenceRule,
    this.isCompleted = false,
    this.originalTaskId,
    this.description,
    this.source = 'local',
    this.isOverdue = false,
  });

  bool get isPanchang => itemType == 'panchang' || source == 'panchang';
  bool get isGoogle => source == 'google';
  bool get isRecurring => recurrenceRule != null && recurrenceRule!.frequency != RecurrenceFrequency.none;

  /// Factory converter from a domain [Task].
  factory AstraScheduleItem.fromTask(
    Task task, {
    DateTime? occurrence,
    DateTime? now,
  }) {
    final effectiveStart = occurrence ?? task.startAt ?? task.dueDate ?? DateTime.now();
    DateTime? effectiveEnd = task.endAt;
    if (task.isDuration && occurrence != null && task.startAt != null && task.endAt != null) {
      final duration = task.endAt!.difference(task.startAt!);
      effectiveEnd = occurrence.add(duration);
    }

    final current = now ?? DateTime.now();
    final overdue = !task.isCompleted && effectiveStart.isBefore(DateTime(current.year, current.month, current.day));

    return AstraScheduleItem(
      id: task.id,
      title: task.title,
      startAt: effectiveStart,
      endAt: effectiveEnd,
      itemType: task.isDuration ? 'event' : (task.recurrenceRule != null ? 'task' : 'task'),
      priority: task.priority,
      organization: task.organization,
      recurrenceRule: task.recurrenceRule,
      isCompleted: task.isCompleted,
      originalTaskId: task.id,
      description: task.description,
      source: task.source == 'calendar' ? 'google' : 'local',
      isOverdue: overdue,
    );
  }

  /// Factory converter for Google Calendar event.
  factory AstraScheduleItem.fromGoogleCalendar({
    required String id,
    required String title,
    required DateTime startAt,
    DateTime? endAt,
    String? description,
    String? location,
  }) {
    return AstraScheduleItem(
      id: 'gcal-$id',
      title: title,
      startAt: startAt,
      endAt: endAt ?? startAt.add(const Duration(hours: 1)),
      itemType: 'event',
      priority: 'medium',
      organization: location,
      isCompleted: false,
      originalTaskId: null,
      description: description,
      source: 'google',
    );
  }

  /// Factory converter for Panchang entry.
  factory AstraScheduleItem.fromPanchang({
    required String id,
    required String title,
    required DateTime date,
    String? description,
  }) {
    return AstraScheduleItem(
      id: 'panchang-$id',
      title: title,
      startAt: DateTime(date.year, date.month, date.day, 6, 0),
      endAt: DateTime(date.year, date.month, date.day, 20, 0),
      itemType: 'panchang',
      priority: 'low',
      isCompleted: false,
      originalTaskId: null,
      description: description,
      source: 'panchang',
    );
  }

  /// Builds a unified chronologically sorted schedule from tasks, external events, and panchang.
  static List<AstraScheduleItem> buildSchedule({
    required List<Task> tasks,
    List<AstraScheduleItem> externalEvents = const [],
    required DateTime windowStart,
    required DateTime windowEnd,
    bool includeCompleted = true,
    DateTime? now,
  }) {
    final items = <AstraScheduleItem>[];
    const recurrenceEngine = AstraRecurrenceEngine();
    final current = now ?? DateTime.now();

    for (final task in tasks) {
      if (!includeCompleted && task.isCompleted) continue;

      // 1. Recurring tasks: expand occurrences in window
      if (task.recurrenceRule != null &&
          task.recurrenceRule!.frequency != RecurrenceFrequency.none) {
        var cursor = windowStart.subtract(const Duration(seconds: 1));
        while (true) {
          final next = recurrenceEngine.nextOccurrence(task.recurrenceRule!, cursor);
          if (next == null || next.isAfter(windowEnd)) break;
          items.add(AstraScheduleItem.fromTask(task, occurrence: next, now: current));
          cursor = next;
        }
        continue;
      }

      // 2. Date-range / Duration tasks
      if (task.startAt != null && task.endAt != null) {
        if (task.endAt!.isAfter(windowStart) && task.startAt!.isBefore(windowEnd)) {
          items.add(AstraScheduleItem.fromTask(task, now: current));
        }
        continue;
      }

      // 3. One-shot deadline / scheduled date
      final targetDate = task.dueDate ?? task.startAt;
      if (targetDate != null) {
        if ((targetDate.isAfter(windowStart) || targetDate.isAtSameMomentAs(windowStart)) &&
            (targetDate.isBefore(windowEnd) || targetDate.isAtSameMomentAs(windowEnd))) {
          items.add(AstraScheduleItem.fromTask(task, now: current));
        }
      }
    }

    // Add external Google / Panchang items in window
    for (final ext in externalEvents) {
      if (ext.startAt.isBefore(windowEnd) && (ext.endAt == null || ext.endAt!.isAfter(windowStart))) {
        items.add(ext);
      }
    }

    // Sort chronologically
    items.sort((a, b) => a.startAt.compareTo(b.startAt));
    return items;
  }
}
