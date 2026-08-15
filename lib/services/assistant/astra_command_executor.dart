import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/database/database.dart';
import '../../models/task.dart';
import '../../features/scheduler/data/services/google_auth_service.dart';
import '../../features/scheduler/data/services/google_calendar_writer_service.dart';
import '../../providers/google_calendar_writer_provider.dart';
import '../../providers/ritual_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/reminder_provider.dart';
import 'astra_command.dart';
import 'astra_recurrence_engine.dart';
import 'astra_task_resolver.dart';
import 'astra_update_command.dart';

class AstraExecutionResult {
  final bool success;
  final String operation;
  final String taskId;
  final String title;
  final DateTime? scheduledAt;
  final String message;
  final bool calendarSynced;
  final String? calendarMessage;
  final String? googleEventId;
  final bool requiresConfirmation;
  final String? confirmationReason;
  final List<String> warnings;
  final List<String> candidateTitles;

  const AstraExecutionResult({
    required this.success,
    required this.operation,
    required this.taskId,
    required this.title,
    required this.scheduledAt,
    required this.message,
    this.calendarSynced = false,
    this.calendarMessage,
    this.googleEventId,
    this.requiresConfirmation = false,
    this.confirmationReason,
    this.warnings = const [],
    this.candidateTitles = const [],
  });
}

class AstraCommandExecutor {
  const AstraCommandExecutor({
    this.recurrenceEngine = const AstraRecurrenceEngine(),
    this.taskResolver = const AstraTaskResolver(),
    this.googleAuthService,
    this.googleCalendarWriterService,
  });

  final AstraRecurrenceEngine recurrenceEngine;
  final AstraTaskResolver taskResolver;
  final GoogleAuthService? googleAuthService;
  final GoogleCalendarWriterService? googleCalendarWriterService;

  Future<AstraExecutionResult> execute({
    required dynamic ref,
    required AstraCommand command,
  }) async {
    switch (command.intent) {
      case 'CREATE_TASK':
      case 'CREATE_REMINDER':
      case 'CREATE_CALENDAR_EVENT':
        return _createTaskLikeCommand(
          ref: ref,
          command: command,
        );

      default:
        throw UnsupportedError(
          'AstraCommandExecutor does not execute '
          'intent: ${command.intent}',
        );
    }
  }

  /// Safely executes an [AstraUpdateCommand] using [taskResolver].
  ///
  /// Invariants:
  /// - Exact match + valid changes -> updates task via [TaskNotifier.updateTask] and reschedules reminder if dueAt changed.
  /// - Ambiguous match -> returns confirmation result with candidate titles; ZERO DB writes.
  /// - Not found -> returns confirmation/info result; ZERO DB writes.
  /// - Missing changes or ambiguous time -> returns confirmation result; ZERO DB writes.
  Future<AstraExecutionResult> update({
    required dynamic ref,
    required AstraUpdateCommand command,
    required List<Task> activeTasks,
  }) async {
    // 1. Check if command parser already flagged validation or ambiguous time
    if (command.requiresConfirmation || !command.hasChanges) {
      return AstraExecutionResult(
        success: false,
        operation: 'UPDATE_TASK',
        taskId: '',
        title: '',
        scheduledAt: null,
        message: command.warnings.isNotEmpty
            ? command.warnings.first
            : 'Confirmation required before updating.',
        requiresConfirmation: true,
        confirmationReason: command.targetQuery.isEmpty
            ? 'missing_target'
            : (command.hasChanges ? 'ambiguous_time' : 'missing_changes'),
        warnings: command.warnings,
      );
    }

    // 2. Resolve target task using pure AstraTaskResolver
    final resolution = taskResolver.resolve(
      tasks: activeTasks,
      query: command.targetQuery,
    );

    switch (resolution.outcome) {
      case TaskResolutionOutcome.ambiguous:
        return AstraExecutionResult(
          success: false,
          operation: 'UPDATE_TASK',
          taskId: '',
          title: '',
          scheduledAt: null,
          message: 'Multiple matching tasks found.',
          requiresConfirmation: true,
          confirmationReason: 'ambiguous_task',
          candidateTitles: resolution.candidates.map((t) => t.title).toList(),
          warnings: ['Multiple tasks matched "${command.targetQuery}".'],
        );

      case TaskResolutionOutcome.notFound:
        return AstraExecutionResult(
          success: false,
          operation: 'UPDATE_TASK',
          taskId: '',
          title: '',
          scheduledAt: null,
          message: 'Task "${command.targetQuery}" not found.',
          requiresConfirmation: true,
          confirmationReason: 'task_not_found',
          warnings: ['No active task found matching "${command.targetQuery}".'],
        );

      case TaskResolutionOutcome.exact:
        final existing = resolution.task!;
        final newTitle = command.newTitle ?? existing.title;
        final newDueAt = command.newDueAt ?? existing.dueDate;
        final newPriority = command.newPriority != null
            ? _normalizePriority(command.newPriority!)
            : existing.priority;
        final newOrganization = command.newOrganization ?? existing.organization;
        final newRecurrence = command.newRecurrenceRule ?? existing.recurrenceRule;

        final updatedTask = existing.copyWith(
          title: newTitle,
          dueDate: newDueAt,
          priority: newPriority,
          organization: newOrganization,
          recurrenceRule: newRecurrence,
          updatedAt: DateTime.now(),
        );

        // Mutate through TaskNotifier (authoritative UI + Drift update)
        await ref.read(taskNotifierProvider.notifier).updateTask(updatedTask);
        ref.invalidate(taskListProvider);

        // If dueDate changed, reschedule reminder via ReminderService (idempotent: cancels old reminder)
        if (command.newDueAt != null) {
          await ref.read(reminderServiceProvider).scheduleReminder(
                taskId: updatedTask.id,
                taskTitle: updatedTask.title,
                scheduledAt: updatedTask.dueDate!,
              );
        } else if (command.newTitle != null && existing.dueDate != null) {
          // If only title changed and task had a reminder, update reminder title
          await ref.read(reminderServiceProvider).scheduleReminder(
                taskId: updatedTask.id,
                taskTitle: updatedTask.title,
                scheduledAt: existing.dueDate!,
              );
        }

        return AstraExecutionResult(
          success: true,
          operation: 'UPDATE_TASK',
          taskId: updatedTask.id,
          title: updatedTask.title,
          scheduledAt: updatedTask.dueDate,
          message: '${updatedTask.title} updated successfully.',
          requiresConfirmation: false,
        );
    }
  }

  Future<AstraExecutionResult> _createTaskLikeCommand({
    required dynamic ref,
    required AstraCommand command,
  }) async {
    final taskId =
        DateTime.now().millisecondsSinceEpoch.toString();

    final now = DateTime.now();

    // 1. Build RecurrenceRule if command has recurrence
    final recurrenceRule = _buildRecurrenceRule(command);

    // 2. Determine initial scheduledAt / dueDate
    DateTime? scheduledAt;
    if (recurrenceRule != null) {
      scheduledAt = _calculateFirstOccurrence(recurrenceRule, command, now);
    } else {
      scheduledAt = command.temporal.eventStart ?? command.temporal.deadline;
    }

    final taskDescription = _buildDescription(command);

    final task = Task(
      id: taskId,
      title: command.title,
      description: taskDescription,
      dueDate: scheduledAt,
      priority: _normalizePriority(
        command.priority,
      ),
      status: scheduledAt != null
          ? 'active'
          : 'pending',
      createdAt: now,
      source: 'assistant',
      organization: command.organization,
      recurrenceRule: recurrenceRule,
    );

    final db = ref.read(databaseProvider);
    final subtasksJson = jsonEncode(task.subtasks.map((s) => s.toJson()).toList());

    await db.into(db.tasks).insertOnConflictUpdate(
          TasksCompanion(
            id: Value(task.id),
            title: Value(task.title),
            description: Value(task.description),
            taskType: const Value('reminder'),
            priority: Value(task.priority),
            status: Value(task.status),
            order: Value(task.order),
            subtasksJson: Value(subtasksJson),
            dueAt: Value(task.dueDate),
            completedAt: Value(task.completedAt),
            createdAt: Value(task.createdAt),
            updatedAt: Value(task.updatedAt ?? now),
            source: Value(task.source),
            sourceId: Value(task.sourceId),
            category: Value(task.category),
            organization: Value(task.organization),
            recurrenceRuleJson: Value(task.recurrenceRule?.toJson()),
          ),
        );

    await ref.read(taskNotifierProvider.notifier).loadTasks();
    ref.invalidate(taskListProvider);

    if (scheduledAt != null) {
      final reminderId = DateTime.now().millisecondsSinceEpoch.toString();
      await db.upsertReminder(
        RemindersCompanion(
          id: Value(reminderId),
          taskId: Value(task.id),
          scheduledAt: Value(scheduledAt),
          timezone: Value(command.temporal.timezone),
          notificationId: Value(task.id.hashCode),
          status: const Value('scheduled'),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      try {
        await ref
            .read(reminderServiceProvider)
            .scheduleReminder(
              taskId: task.id,
              taskTitle: task.title,
              scheduledAt: scheduledAt,
            );
      } catch (_) {
        // Safe fallback in headless/test environments where platform channel is not active
      }
    }

    bool calendarSynced = false;
    String? calendarMessage;
    String? googleEventId;

    if (command.intent == 'CREATE_CALENDAR_EVENT' && scheduledAt != null) {
      try {
        final authService = googleAuthService ?? GoogleAuthService.instance;
        final client = await authService.getAuthenticatedClient();

        if (client != null) {
          final writerService = googleCalendarWriterService ??
              (ref != null
                  ? (ref.read(googleCalendarWriterServiceProvider) as GoogleCalendarWriterService)
                  : const GoogleCalendarWriterService());

          final calDescription = _buildCalendarDescription(command);

          final event = await writerService.createEvent(
            client,
            title: command.title,
            startTime: scheduledAt,
            endTime: command.temporal.eventEnd,
            description: calDescription,
            location: command.organization,
            timezone: command.temporal.timezone,
            recurrenceRule: recurrenceRule,
          );

          calendarSynced = true;
          googleEventId = event.id;
        } else {
          calendarSynced = false;
          calendarMessage = 'Saved locally. Google Calendar permission is required.';
        }
      } on GoogleCalendarWriteException catch (e) {
        calendarSynced = false;
        switch (e.code) {
          case GoogleCalendarWriteErrorCode.authRequired:
          case GoogleCalendarWriteErrorCode.permissionRequired:
            calendarMessage = 'Saved locally. Google Calendar permission is required.';
            break;
          case GoogleCalendarWriteErrorCode.networkError:
            calendarMessage = 'Saved locally. Google Calendar sync is unavailable.';
            break;
          case GoogleCalendarWriteErrorCode.apiError:
            calendarMessage = 'Saved locally. Google Calendar sync failed.';
            break;
        }
      } catch (e) {
        calendarSynced = false;
        calendarMessage = 'Saved locally. Google Calendar sync failed.';
      }
    }

    return AstraExecutionResult(
      success: true,
      operation: command.intent,
      taskId: task.id,
      title: task.title,
      scheduledAt: scheduledAt,
      message: _successMessage(
        command,
        scheduledAt,
      ),
      calendarSynced: calendarSynced,
      calendarMessage: calendarMessage,
      googleEventId: googleEventId,
    );
  }

  String _buildCalendarDescription(AstraCommand command) {
    final buffer = StringBuffer('Created via ASTRA Assistant.\n');
    if (command.action != null && command.action!.isNotEmpty) {
      buffer.writeln('Action: ${command.action}');
    }
    if (command.eventType.isNotEmpty && command.eventType != 'OTHER') {
      buffer.writeln('Type: ${command.eventType}');
    }
    if (command.organization != null && command.organization!.isNotEmpty) {
      buffer.writeln('Organization: ${command.organization}');
    }
    if (command.originalText.isNotEmpty) {
      buffer.writeln('Original: ${command.originalText}');
    }
    return buffer.toString().trim();
  }

  RecurrenceRule? _buildRecurrenceRule(AstraCommand command) {
    final freqStr = command.recurrence.toUpperCase().trim();
    if (freqStr == 'NONE' || freqStr.isEmpty) {
      return null;
    }

    final freq = RecurrenceFrequency.fromJson(freqStr);
    if (freq == RecurrenceFrequency.none) {
      return null;
    }

    final baseTime = command.temporal.eventStart ?? command.temporal.deadline;
    var hour = baseTime?.hour ?? 9;
    var minute = baseTime?.minute ?? 0;

    // If raw time was given, parse hour/min as fallback if baseTime was null
    if (baseTime == null && command.temporal.rawTime != null) {
      final parsed = _parseRawHourMinute(command.temporal.rawTime!);
      if (parsed != null) {
        hour = parsed.hour;
        minute = parsed.minute;
      }
    }

    int? endHour;
    int? endMinute;
    if (command.temporal.eventEnd != null) {
      endHour = command.temporal.eventEnd!.hour;
      endMinute = command.temporal.eventEnd!.minute;
    }

    final startDate = command.temporal.eventStart ??
        (command.temporal.rawDate != null ? baseTime : null);

    final endDate = command.temporal.eventEnd != null
        ? (command.temporal.eventEnd!.isAfter(startDate ?? DateTime.now()) ? command.temporal.eventEnd : null)
        : null;

    final byWeekdays = <int>[];
    if (freq == RecurrenceFrequency.weekdays) {
      byWeekdays.addAll([
        DateTime.monday,
        DateTime.tuesday,
        DateTime.wednesday,
        DateTime.thursday,
        DateTime.friday,
      ]);
    } else if (freq == RecurrenceFrequency.weekly) {
      final targetDay = startDate?.weekday ?? baseTime?.weekday ?? DateTime.monday;
      byWeekdays.add(targetDay);
    }

    return RecurrenceRule(
      frequency: freq,
      interval: 1,
      byWeekdays: byWeekdays,
      startDate: startDate,
      endDate: endDate,
      hour: hour,
      minute: minute,
      endHour: endHour,
      endMinute: endMinute,
    );
  }

  DateTime? _calculateFirstOccurrence(
    RecurrenceRule rule,
    AstraCommand command,
    DateTime now,
  ) {
    // 1. Direct candidate from startDate or eventStart
    if (rule.startDate != null) {
      final candidate = DateTime(
        rule.startDate!.year,
        rule.startDate!.month,
        rule.startDate!.day,
        rule.hour,
        rule.minute,
      );

      // If candidate is within window (e.g. valid weekday for weekdays freq)
      if (recurrenceEngine.isWithinWindow(rule, candidate)) {
        if (rule.frequency == RecurrenceFrequency.weekdays) {
          if (candidate.weekday >= DateTime.monday && candidate.weekday <= DateTime.friday) {
            return candidate;
          }
        } else {
          return candidate;
        }
      }
    }

    // 2. Use recurrence engine to find next valid future occurrence after now (or startDate - 1 second)
    final after = (rule.startDate != null && rule.startDate!.isAfter(now))
        ? rule.startDate!.subtract(const Duration(seconds: 1))
        : now;

    return recurrenceEngine.nextOccurrence(rule, after);
  }

  _TimeHourMinute? _parseRawHourMinute(String raw) {
    final match = RegExp(
      r'(\d{1,2})(?::(\d{2}))?\s*(am|pm)?',
      caseSensitive: false,
    ).firstMatch(raw);
    if (match == null) return null;

    var h = int.tryParse(match.group(1) ?? '') ?? 9;
    final m = int.tryParse(match.group(2) ?? '') ?? 0;
    final ampm = match.group(3)?.toLowerCase();

    if (ampm == 'pm' && h != 12) h += 12;
    if (ampm == 'am' && h == 12) h = 0;

    return _TimeHourMinute(hour: h, minute: m);
  }

  String _buildDescription(
    AstraCommand command,
  ) {
    final parts = <String>[
      'Created via ASTRA Assistant.',
    ];

    if (command.action != null &&
        command.action!.trim().isNotEmpty) {
      parts.add(
        'Action: ${command.action}',
      );
    }

    if (command.eventType.trim().isNotEmpty &&
        command.eventType != 'OTHER') {
      parts.add(
        'Type: ${command.eventType}',
      );
    }

    if (command.recurrence != 'NONE') {
      parts.add(
        'Recurrence: ${command.recurrence}',
      );
    }

    if (command.temporal.rawDate != null &&
        command.temporal.rawDate!.trim().isNotEmpty) {
      parts.add(
        'Date: ${command.temporal.rawDate}',
      );
    }

    if (command.temporal.rawTime != null &&
        command.temporal.rawTime!.trim().isNotEmpty) {
      parts.add(
        'Time: ${command.temporal.rawTime}',
      );
    }

    if (command.temporal.rawDeadline != null &&
        command.temporal.rawDeadline!.trim().isNotEmpty) {
      parts.add(
        'Deadline: ${command.temporal.rawDeadline}',
      );
    }

    return parts.join('\n');
  }

  String _normalizePriority(
    String value,
  ) {
    switch (value.toLowerCase()) {
      case 'low':
      case 'medium':
      case 'high':
      case 'critical':
        return value.toLowerCase();
      default:
        return 'medium';
    }
  }

  String _successMessage(
    AstraCommand command,
    DateTime? scheduledAt,
  ) {
    if (scheduledAt == null) {
      return '${command.title} created.';
    }

    return '${command.title} scheduled for '
        '${scheduledAt.toLocal()}.';
  }
}

class _TimeHourMinute {
  final int hour;
  final int minute;

  const _TimeHourMinute({
    required this.hour,
    required this.minute,
  });
}
