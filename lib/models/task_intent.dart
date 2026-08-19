import 'package:uuid/uuid.dart';
import '../services/assistant/astra_command.dart';
import '../services/assistant/astra_recurrence_engine.dart';
import 'task.dart';

/// Unified domain representation for task/reminder/event creation.
///
/// Serves as the single contract produced by:
/// 1. Manual UI Creation Sheet ([AstraTaskCreationSheet])
/// 2. Natural Language Intent Engines (ASTRA Local Brain & ML Resolvers)
/// 3. Document / Email Intelligence Analyzers
class TaskIntent {
  final String? id;
  final String title;
  final String? description;
  final String taskType; // 'task' | 'reminder' | 'event'
  final DateTime? dueDate;
  final String? dueTime; // 'HH:mm' e.g. '20:00'
  final DateTime? startAt;
  final DateTime? endAt;
  final RecurrenceRule? recurrenceRule;
  final String priority; // 'low' | 'medium' | 'high'
  final String status; // 'pending' | 'active'
  final String? category;
  final String? organization;
  final String source; // 'manual' | 'assistant' | 'email' | 'calendar'
  final List<SubTask> subtasks;

  const TaskIntent({
    this.id,
    required this.title,
    this.description,
    this.taskType = 'task',
    this.dueDate,
    this.dueTime,
    this.startAt,
    this.endAt,
    this.recurrenceRule,
    this.priority = 'medium',
    this.status = 'pending',
    this.category,
    this.organization,
    this.source = 'manual',
    this.subtasks = const [],
  });

  /// Converts this intent into a domain [Task] ready for Drift SQLite persistence.
  Task toTask({DateTime? now}) {
    final effectiveNow = now ?? DateTime.now();
    final effectiveId = id ?? const Uuid().v4();

    // Determine effective status: active if scheduled or event, otherwise pending
    final effectiveStatus = status == 'completed'
        ? 'completed'
        : (dueDate != null || dueTime != null || startAt != null || recurrenceRule != null
            ? 'active'
            : status);

    return Task(
      id: effectiveId,
      title: title.trim(),
      description: description?.trim().isEmpty == true ? null : description?.trim(),
      dueDate: dueDate,
      dueTime: dueTime,
      startAt: startAt,
      endAt: endAt,
      status: effectiveStatus,
      priority: priority,
      subtasks: subtasks,
      createdAt: effectiveNow,
      updatedAt: effectiveNow,
      source: source,
      category: category,
      organization: organization,
      recurrenceRule: recurrenceRule,
    );
  }

  TaskIntent copyWith({
    String? id,
    String? title,
    String? description,
    String? taskType,
    DateTime? dueDate,
    String? dueTime,
    DateTime? startAt,
    DateTime? endAt,
    RecurrenceRule? recurrenceRule,
    String? priority,
    String? status,
    String? category,
    String? organization,
    String? source,
    List<SubTask>? subtasks,
    bool clearRecurrenceRule = false,
  }) {
    return TaskIntent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      taskType: taskType ?? this.taskType,
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime ?? this.dueTime,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      recurrenceRule: clearRecurrenceRule ? null : (recurrenceRule ?? this.recurrenceRule),
      priority: priority ?? this.priority,
      status: status ?? this.status,
      category: category ?? this.category,
      organization: organization ?? this.organization,
      source: source ?? this.source,
      subtasks: subtasks ?? this.subtasks,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'title': title,
        'description': description,
        'taskType': taskType,
        'dueDate': dueDate?.toIso8601String(),
        'dueTime': dueTime,
        'startAt': startAt?.toIso8601String(),
        'endAt': endAt?.toIso8601String(),
        if (recurrenceRule != null) 'recurrenceRule': recurrenceRule!.toMap(),
        'priority': priority,
        'status': status,
        'category': category,
        'organization': organization,
        'source': source,
        'subtasks': subtasks.map((s) => s.toJson()).toList(),
      };

  factory TaskIntent.fromJson(Map<String, dynamic> json) {
    RecurrenceRule? recurrence;
    if (json['recurrenceRule'] != null) {
      try {
        if (json['recurrenceRule'] is Map<String, dynamic>) {
          recurrence = RecurrenceRule.fromMap(json['recurrenceRule'] as Map<String, dynamic>);
        } else if (json['recurrenceRule'] is String) {
          recurrence = RecurrenceRule.fromJson(json['recurrenceRule'] as String);
        }
      } catch (_) {}
    }

    List<SubTask> parsedSubtasks = [];
    if (json['subtasks'] != null && json['subtasks'] is List) {
      parsedSubtasks = (json['subtasks'] as List)
          .map((s) => SubTask.fromJson(s as Map<String, dynamic>))
          .toList();
    }

    return TaskIntent(
      id: json['id'] as String?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      taskType: json['taskType'] as String? ?? 'task',
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate'] as String) : null,
      dueTime: json['dueTime'] as String?,
      startAt: json['startAt'] != null ? DateTime.parse(json['startAt'] as String) : null,
      endAt: json['endAt'] != null ? DateTime.parse(json['endAt'] as String) : null,
      recurrenceRule: recurrence,
      priority: json['priority'] as String? ?? 'medium',
      status: json['status'] as String? ?? 'pending',
      category: json['category'] as String?,
      organization: json['organization'] as String?,
      source: json['source'] as String? ?? 'manual',
      subtasks: parsedSubtasks,
    );
  }

  factory TaskIntent.fromAstraCommand(AstraCommand command) {
    String taskType = 'task';
    if (command.intent == 'CREATE_REMINDER') {
      taskType = 'reminder';
    } else if (command.intent == 'CREATE_CALENDAR_EVENT' ||
        command.eventType == 'INTERVIEW' ||
        command.eventType == 'WORKSHOP' ||
        command.eventType == 'MEETING') {
      taskType = 'event';
    }

    RecurrenceRule? recurrence;
    if (command.recurrence != 'NONE' && command.recurrence.isNotEmpty) {
      recurrence = const AstraRecurrenceEngine().parse(command.originalText);
    }

    return TaskIntent(
      title: command.title,
      description: null,
      taskType: taskType,
      dueDate: command.temporal.deadline ??
          (taskType != 'event' ? command.temporal.eventStart : null),
      startAt: command.temporal.eventStart,
      endAt: command.temporal.eventEnd,
      recurrenceRule: recurrence,
      priority: command.priority,
      status: (command.temporal.eventStart != null ||
              command.temporal.deadline != null ||
              recurrence != null)
          ? 'active'
          : 'pending',
      organization: command.organization,
      source: 'assistant',
    );
  }
}
