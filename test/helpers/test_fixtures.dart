import 'package:astra/models/task.dart';
import 'package:astra/services/assistant/astra_command.dart';
import 'package:astra/services/assistant/astra_recurrence_engine.dart';

/// Test fixture generator for standard test models.
class TestFixtures {
  /// Creates a standard Task instance with customizable overrides.
  static Task createTask({
    String id = 'test-task-1',
    String title = 'Test Task',
    String? description,
    DateTime? dueDate,
    String priority = 'medium',
    String status = 'active',
    int order = 0,
    List<SubTask> subtasks = const [],
    String source = 'assistant',
    String? sourceId,
    String? category,
    String? organization,
    DateTime? createdAt,
    DateTime? completedAt,
    RecurrenceRule? recurrenceRule,
  }) {
    return Task(
      id: id,
      title: title,
      description: description,
      dueDate: dueDate,
      priority: priority,
      status: status,
      order: order,
      subtasks: subtasks,
      source: source,
      sourceId: sourceId,
      category: category,
      organization: organization,
      createdAt: createdAt ?? DateTime.now(),
      completedAt: completedAt,
      recurrenceRule: recurrenceRule,
    );
  }

  /// Creates a standard AstraCommand instance with sensible defaults.
  static AstraCommand createCommand({
    String intent = 'CREATE_TASK',
    String eventType = 'OTHER',
    String title = 'Test Command Task',
    String? action,
    String? organization,
    AstraTemporal? temporal,
    String recurrence = 'NONE',
    String priority = 'medium',
    double modelConfidence = 0.95,
    double semanticConfidence = 0.95,
    bool requiresConfirmation = false,
    String route = 'EXECUTE',
    String originalText = 'test original text',
  }) {
    return AstraCommand(
      intent: intent,
      eventType: eventType,
      title: title,
      action: action,
      organization: organization,
      temporal: temporal ??
          AstraTemporal(
            eventStart: DateTime(2026, 8, 15, 10, 0),
            timezone: 'Asia/Kolkata',
            recurrence: recurrence,
          ),
      recurrence: recurrence,
      priority: priority,
      modelConfidence: modelConfidence,
      semanticConfidence: semanticConfidence,
      requiresConfirmation: requiresConfirmation,
      route: route,
      originalText: originalText,
    );
  }
}
