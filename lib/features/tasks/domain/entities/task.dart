// Domain enums and entity representing a Task in ASTRA.

/// Type-safe domain representation of a Task's type.
enum TaskType {
  todo,
  event,
  reminder,
  application;

  /// Returns the uppercase string representation used in persistence.
  String get value => name.toUpperCase();

  /// Parses a string representation back to the matching enum value.
  /// Defaults to [TaskType.todo] if no match is found.
  static TaskType fromValue(String val) {
    final upper = val.toUpperCase();
    for (final type in TaskType.values) {
      if (type.value == upper) return type;
    }
    return TaskType.todo;
  }
}

/// Type-safe domain representation of a Task's priority.
enum TaskPriority {
  low,
  medium,
  high,
  urgent;

  /// Returns the uppercase string representation used in persistence.
  String get value => name.toUpperCase();

  /// Parses a string representation back to the matching enum value.
  /// Defaults to [TaskPriority.medium] if no match is found.
  static TaskPriority fromValue(String val) {
    final upper = val.toUpperCase();
    for (final priority in TaskPriority.values) {
      if (priority.value == upper) return priority;
    }
    return TaskPriority.medium;
  }
}

/// Type-safe domain representation of a Task's completion/status.
enum TaskStatus {
  pending,
  completed;

  /// Returns the uppercase string representation used in persistence.
  String get value => name.toUpperCase();

  /// Parses a string representation back to the matching enum value.
  /// Defaults to [TaskStatus.pending] if no match is found.
  static TaskStatus fromValue(String val) {
    final upper = val.toUpperCase();
    for (final status in TaskStatus.values) {
      if (status.value == upper) return status;
    }
    return TaskStatus.pending;
  }
}

/// Pure domain entity representing a Task.
/// Holds no dependencies on UI or database persistence frameworks.
class Task {
  final String id;
  final String? inboxItemId;
  final String title;
  final String? description;
  final TaskType taskType;
  final TaskPriority priority;
  final TaskStatus status;
  final DateTime? dueAt;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Task({
    required this.id,
    this.inboxItemId,
    required this.title,
    this.description,
    required this.taskType,
    required this.priority,
    required this.status,
    this.dueAt,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a copy of this task with modified properties.
  Task copyWith({
    String? title,
    String? description,
    TaskType? taskType,
    TaskPriority? priority,
    TaskStatus? status,
    DateTime? dueAt,
    DateTime? completedAt,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id,
      inboxItemId: inboxItemId,
      title: title ?? this.title,
      description: description ?? this.description,
      taskType: taskType ?? this.taskType,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      dueAt: dueAt ?? this.dueAt,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
