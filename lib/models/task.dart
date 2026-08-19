import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../services/assistant/astra_recurrence_engine.dart';

class SubTask {
  final String id;
  final String name;
  final bool isCompleted;

  const SubTask({
    required this.id,
    required this.name,
    this.isCompleted = false,
  });

  factory SubTask.create(String name) {
    return SubTask(
      id: const Uuid().v4(),
      name: name,
      isCompleted: false,
    );
  }

  SubTask copyWith({
    String? id,
    String? name,
    bool? isCompleted,
  }) {
    return SubTask(
      id: id ?? this.id,
      name: name ?? this.name,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'isCompleted': isCompleted,
      };

  factory SubTask.fromJson(Map<String, dynamic> json) => SubTask(
        id: json['id'] as String,
        name: json['name'] as String,
        isCompleted: json['isCompleted'] as bool? ?? false,
      );
}

class Task {
  final String id;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final String? dueTime; // 'HH:mm' e.g. '20:00'
  final DateTime? startAt;
  final DateTime? endAt;
  final String status; // 'pending' | 'active' | 'completed' | 'cancelled'
  final String priority; // 'low' | 'medium' | 'high'
  final int order;
  final List<SubTask> subtasks;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? updatedAt;
  final String? source; // 'manual', 'email', 'calendar', 'assistant'
  final String? sourceId;
  final String? category;
  final String? organization;
  final RecurrenceRule? recurrenceRule;

  Task({
    required this.id,
    required this.title,
    this.description,
    this.dueDate,
    this.dueTime,
    this.startAt,
    this.endAt,
    this.status = 'pending',
    this.priority = 'medium',
    this.order = 0,
    this.subtasks = const [],
    required this.createdAt,
    this.completedAt,
    this.updatedAt,
    this.source,
    this.sourceId,
    this.category,
    this.organization,
    this.recurrenceRule,
  });

  // Backward compatibility getter
  bool get isCompleted => status == 'completed';
  bool get isActive => status != 'completed' && status != 'cancelled' && !isCompleted;
  bool get isImportant => priority == 'high' || priority == 'critical';
  bool get hasDate => dueDate != null || startAt != null || (recurrenceRule != null && recurrenceRule!.frequency != RecurrenceFrequency.none);
  bool get isNoDate => !hasDate;

  // Duration & deadline helper getters
  bool get isDuration => startAt != null && endAt != null;
  bool get isDeadline => dueDate != null && startAt == null;
  DateTime? get effectiveTargetDate => startAt ?? dueDate;

  String? get durationFormatted {
    if (!isDuration) return null;
    final days = endAt!.difference(startAt!).inDays + 1;
    final startFmt = DateFormat('d MMM').format(startAt!);
    final endFmt = DateFormat('d MMM').format(endAt!);
    return '$startFmt – $endFmt · $days Days';
  }

  factory Task.create({
    required String title,
    String? description,
    DateTime? dueDate,
    String? dueTime,
    DateTime? startAt,
    DateTime? endAt,
    String priority = 'medium',
    String status = 'pending',
    int order = 0,
    List<SubTask> subtasks = const [],
    String? source,
    String? sourceId,
    String? category,
    String? organization,
    RecurrenceRule? recurrenceRule,
  }) {
    final now = DateTime.now();
    return Task(
      id: const Uuid().v4(),
      title: title,
      description: description,
      dueDate: dueDate,
      dueTime: dueTime,
      startAt: startAt,
      endAt: endAt,
      priority: priority,
      status: status,
      order: order,
      subtasks: subtasks,
      createdAt: now,
      completedAt: status == 'completed' ? now : null,
      updatedAt: now,
      source: source,
      sourceId: sourceId,
      category: category,
      organization: organization,
      recurrenceRule: recurrenceRule,
    );
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    String? dueTime,
    DateTime? startAt,
    DateTime? endAt,
    String? status,
    String? priority,
    int? order,
    List<SubTask>? subtasks,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? completedAt,
    DateTime? updatedAt,
    String? source,
    String? sourceId,
    String? category,
    String? organization,
    RecurrenceRule? recurrenceRule,
    bool clearRecurrenceRule = false,
  }) {
    final newStatus = status ?? (isCompleted != null ? (isCompleted ? 'completed' : 'pending') : this.status);
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime ?? this.dueTime,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      status: newStatus,
      priority: priority ?? this.priority,
      order: order ?? this.order,
      subtasks: subtasks ?? this.subtasks,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? (newStatus == 'completed' ? (this.completedAt ?? DateTime.now()) : null),
      updatedAt: updatedAt ?? DateTime.now(),
      source: source ?? this.source,
      sourceId: sourceId ?? this.sourceId,
      category: category ?? this.category,
      organization: organization ?? this.organization,
      recurrenceRule: clearRecurrenceRule ? null : (recurrenceRule ?? this.recurrenceRule),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'dueDate': dueDate?.toIso8601String(),
        'dueTime': dueTime,
        'startAt': startAt?.toIso8601String(),
        'endAt': endAt?.toIso8601String(),
        'status': status,
        'priority': priority,
        'order': order,
        'subtasks': subtasks.map((s) => s.toJson()).toList(),
        'isCompleted': isCompleted,
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'source': source,
        'sourceId': sourceId,
        'category': category,
        'organization': organization,
        if (recurrenceRule != null) 'recurrenceRule': recurrenceRule!.toMap(),
      };

  factory Task.fromJson(Map<String, dynamic> json) {
    List<SubTask> parsedSubtasks = [];
    if (json['subtasks'] != null && json['subtasks'] is List) {
      parsedSubtasks = (json['subtasks'] as List)
          .map((s) => SubTask.fromJson(s as Map<String, dynamic>))
          .toList();
    }

    final bool legacyCompleted = json['isCompleted'] as bool? ?? false;
    final String parsedStatus = json['status'] as String? ?? (legacyCompleted ? 'completed' : 'pending');

    RecurrenceRule? parsedRecurrence;
    if (json['recurrenceRule'] != null) {
      try {
        if (json['recurrenceRule'] is Map<String, dynamic>) {
          parsedRecurrence = RecurrenceRule.fromMap(json['recurrenceRule'] as Map<String, dynamic>);
        } else if (json['recurrenceRule'] is String) {
          parsedRecurrence = RecurrenceRule.fromJson(json['recurrenceRule'] as String);
        }
      } catch (e) {
        debugPrint('[Task.fromJson] Error parsing recurrenceRule: $e');
      }
    }

    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate'] as String) : null,
      dueTime: json['dueTime'] as String?,
      startAt: json['startAt'] != null ? DateTime.parse(json['startAt'] as String) : null,
      endAt: json['endAt'] != null ? DateTime.parse(json['endAt'] as String) : null,
      status: parsedStatus,
      priority: json['priority'] as String? ?? 'medium',
      order: json['order'] as int? ?? 0,
      subtasks: parsedSubtasks,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : DateTime.now(),
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
      source: json['source'] as String?,
      sourceId: json['sourceId'] as String?,
      category: json['category'] as String?,
      organization: json['organization'] as String?,
      recurrenceRule: parsedRecurrence,
    );
  }
}

// ─── Status Extension ─────────────────────────────────────────────

extension TaskStatusExtension on String {
  bool get isPending => this == 'pending';
  bool get isActive => this == 'active';
  bool get isCompleted => this == 'completed';
  bool get isCancelled => this == 'cancelled';

  String get displayName {
    switch (this) {
      case 'pending':
        return 'Pending';
      case 'active':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return this;
    }
  }

  String get emoji {
    switch (this) {
      case 'pending':
        return '⏳';
      case 'active':
        return '🚀';
      case 'completed':
        return '✅';
      case 'cancelled':
        return '❌';
      default:
        return '';
    }
  }

  String nextStatus() {
    switch (this) {
      case 'pending':
        return 'active';
      case 'active':
        return 'completed';
      case 'completed':
        return 'pending';
      default:
        return 'pending';
    }
  }
}

// ─── SubTask List Extension ───────────────────────────────────────

extension SubTaskListExtension on List<SubTask> {
  bool get allCompleted => isEmpty || every((s) => s.isCompleted);
  int get completedCount => where((s) => s.isCompleted).length;
  int get remainingCount => where((s) => !s.isCompleted).length;
  double get completionRatio => isEmpty ? 1.0 : completedCount / length;
}
