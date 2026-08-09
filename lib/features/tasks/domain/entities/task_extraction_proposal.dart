import 'task.dart';

/// Structured AI proposal generated from raw text analysis.
///
/// Contains fields extracted by AI which must be validated and confirmed
/// by the user before being persisted as a Task.
class TaskExtractionProposal {
  final String title;
  final String? description;
  final TaskType taskType;
  final TaskPriority priority;
  final String? dateExpression;
  final String? timeExpression;
  final double confidence;
  final bool requiresReview;
  final String? uncertaintyReason;

  const TaskExtractionProposal({
    required this.title,
    this.description,
    required this.taskType,
    required this.priority,
    this.dateExpression,
    this.timeExpression,
    required this.confidence,
    required this.requiresReview,
    this.uncertaintyReason,
  });

  /// Factory method to build a proposal from a JSON structure.
  factory TaskExtractionProposal.fromJson(Map<String, dynamic> json) {
    return TaskExtractionProposal(
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      taskType: TaskType.fromValue(json['taskType'] as String? ?? ''),
      priority: TaskPriority.fromValue(json['priority'] as String? ?? ''),
      dateExpression: json['dateExpression'] as String?,
      timeExpression: json['timeExpression'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      requiresReview: json['requiresReview'] as bool? ?? true,
      uncertaintyReason: json['uncertaintyReason'] as String?,
    );
  }

  /// Converts this proposal instance to a Map for serialization/transport.
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'taskType': taskType.value,
      'priority': priority.value,
      'dateExpression': dateExpression,
      'timeExpression': timeExpression,
      'confidence': confidence,
      'requiresReview': requiresReview,
      'uncertaintyReason': uncertaintyReason,
    };
  }
}
