/// Defines multi-moment notification reminder strategies for tasks.
///
/// A single Task record can have multiple notification schedules (e.g. 10m prep, 4m warning, 0m main)
/// without creating duplicate task entries in the database.
enum ReminderStrategy {
  normal,
  important,
  deadline,
  critical,
}

extension ReminderStrategyX on ReminderStrategy {
  /// Offsets before the event due time when notifications should be scheduled.
  List<Duration> get offsets => switch (this) {
        ReminderStrategy.normal => const [Duration.zero],
        ReminderStrategy.important => const [
            Duration(minutes: 10),
            Duration(minutes: 4),
            Duration.zero,
          ],
        ReminderStrategy.deadline => const [
            Duration(minutes: 30),
            Duration(minutes: 10),
            Duration.zero,
          ],
        ReminderStrategy.critical => const [
            Duration(minutes: 30),
            Duration(minutes: 10),
            Duration.zero,
          ],
      };

  String get name => switch (this) {
        ReminderStrategy.normal => 'NORMAL',
        ReminderStrategy.important => 'IMPORTANT',
        ReminderStrategy.deadline => 'DEADLINE',
        ReminderStrategy.critical => 'CRITICAL',
      };

  static ReminderStrategy fromString(String? name) {
    if (name == null) return ReminderStrategy.normal;
    return switch (name.toUpperCase()) {
      'IMPORTANT' => ReminderStrategy.important,
      'DEADLINE' => ReminderStrategy.deadline,
      'CRITICAL' => ReminderStrategy.critical,
      _ => ReminderStrategy.normal,
    };
  }

  /// Maps semantic event classification (eventType, action, priority, isDeadline)
  /// to appropriate ReminderStrategy without relying purely on keywords.
  static ReminderStrategy resolve({
    String? eventType,
    String? action,
    String? priority,
    bool isDeadline = false,
  }) {
    final normPriority = priority?.toLowerCase().trim() ?? '';
    final normEvent = eventType?.toUpperCase().trim() ?? '';

    if (normPriority == 'critical') {
      return ReminderStrategy.critical;
    }
    if (isDeadline || normEvent == 'DEADLINE') {
      return ReminderStrategy.deadline;
    }
    if (normEvent == 'EXAM' ||
        normEvent == 'INTERVIEW' ||
        normEvent == 'MEETING' ||
        normEvent == 'SESSION' ||
        normPriority == 'high' ||
        normPriority == 'urgent') {
      return ReminderStrategy.important;
    }
    return ReminderStrategy.normal;
  }
}
