/// Persistent reminder linked to a task — the source of truth for OS notifications.
enum ReminderStatus {
  scheduled,
  delivered,
  snoozed,
  completed,
  cancelled,
  failed,
  permissionRequired,
}

extension ReminderStatusX on ReminderStatus {
  String get name => switch (this) {
        ReminderStatus.scheduled => 'scheduled',
        ReminderStatus.delivered => 'delivered',
        ReminderStatus.snoozed => 'snoozed',
        ReminderStatus.completed => 'completed',
        ReminderStatus.cancelled => 'cancelled',
        ReminderStatus.failed => 'failed',
        ReminderStatus.permissionRequired => 'permissionRequired',
      };

  static ReminderStatus fromString(String value) => switch (value) {
        'scheduled' => ReminderStatus.scheduled,
        'delivered' => ReminderStatus.delivered,
        'snoozed' => ReminderStatus.snoozed,
        'completed' => ReminderStatus.completed,
        'cancelled' => ReminderStatus.cancelled,
        'failed' => ReminderStatus.failed,
        'permissionRequired' => ReminderStatus.permissionRequired,
        _ => ReminderStatus.failed,
      };

  bool get isActive =>
      this == ReminderStatus.scheduled || this == ReminderStatus.snoozed;
}

class Reminder {
  final String id;
  final String taskId;
  final DateTime scheduledAt;
  final String timezone;
  final int notificationId;
  final ReminderStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Reminder({
    required this.id,
    required this.taskId,
    required this.scheduledAt,
    required this.timezone,
    required this.notificationId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  Reminder copyWith({
    String? id,
    String? taskId,
    DateTime? scheduledAt,
    String? timezone,
    int? notificationId,
    ReminderStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Reminder(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      timezone: timezone ?? this.timezone,
      notificationId: notificationId ?? this.notificationId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Result of attempting to schedule a reminder notification.
enum ScheduleOutcome {
  scheduled,
  inexactScheduled,
  permissionRequired,
  pastTime,
  failed,
}

class ReminderScheduleResult {
  final Reminder? reminder;
  final ScheduleOutcome outcome;
  final String? message;

  const ReminderScheduleResult({
    this.reminder,
    required this.outcome,
    this.message,
  });

  bool get isSuccess =>
      outcome == ScheduleOutcome.scheduled ||
      outcome == ScheduleOutcome.inexactScheduled;
}
