import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/database/database.dart';
import '../core/reminders/reminder.dart';
import '../core/reminders/reminder_strategy.dart';
import '../core/time/astra_time_service.dart';
import 'assistant/astra_recurrence_engine.dart';
import 'notification_service.dart';

/// Handles the full reminder lifecycle: persist → schedule OS notification → reconcile.
class ReminderService {
  ReminderService(
    this._db, {
    AstraTimeService? timeService,
    this.recurrenceEngine = const AstraRecurrenceEngine(),
  }) : _timeService = timeService ?? AstraTimeService();

  final AppDatabase _db;
  final AstraTimeService _timeService;
  final AstraRecurrenceEngine recurrenceEngine;

  AstraTimeService get timeService => _timeService;

  static const _uuid = Uuid();

  /// Cancels all possible notification offset IDs for a task.
  Future<void> _cancelAllNotificationOffsets(String taskId) async {
    final baseId = taskId.hashCode;
    const offsets = [0, 4, 10, 30];
    for (final off in offsets) {
      await NotificationService.cancelNotification(baseId + off);
    }
  }

  /// Creates or reschedules a reminder for [taskId] at [scheduledAt].
  /// Returns honest status — never claims success unless scheduling succeeded.
  Future<ReminderScheduleResult> scheduleReminder({
    required String taskId,
    required String taskTitle,
    required DateTime scheduledAt,
    ReminderStrategy strategy = ReminderStrategy.normal,
    String? timezone,
  }) async {
    final tz = timezone ?? _timeService.timezone;
    final scheduledTz = _timeService.toTZ(scheduledAt);
    final now = _timeService.nowTZ();

    if (scheduledTz.isBefore(now)) {
      return const ReminderScheduleResult(
        outcome: ScheduleOutcome.pastTime,
        message: 'Reminder time is in the past.',
      );
    }

    // Cancel any existing active reminder / OS notifications for this task (idempotent reschedule / duplicate protection).
    await _cancelAllNotificationOffsets(taskId);
    final existing = await _db.getReminderByTaskId(taskId);
    if (existing != null) {
      await _db.updateReminderStatus(existing.id, ReminderStatus.cancelled.name);
    }

    final reminderId = existing?.id ?? _uuid.v4();
    final baseNotificationId = taskId.hashCode;

    NotificationScheduleResult mainScheduleResult = NotificationScheduleResult.failed;
    final offsets = strategy.offsets;

    for (final offset in offsets) {
      final offsetTime = scheduledAt.subtract(offset);
      final offsetTz = _timeService.toTZ(offsetTime);

      if (offsetTz.isBefore(now)) {
        if (offset == Duration.zero) {
          mainScheduleResult = NotificationScheduleResult.pastTime;
        }
        continue;
      }

      final offsetNotificationId = baseNotificationId + offset.inMinutes;
      final isMain = offset == Duration.zero;

      final typeLabel = taskTitle.toLowerCase().contains('exam')
          ? 'Exam Reminder'
          : (taskTitle.toLowerCase().contains('interview')
              ? 'Interview Reminder'
              : (taskTitle.toLowerCase().contains('meeting') ? 'Meeting Reminder' : 'Reminder'));
      final title = isMain ? 'ASTRA · $typeLabel' : 'ASTRA · $typeLabel (${offset.inMinutes}m before)';
      final body = isMain ? taskTitle : '$taskTitle in ${offset.inMinutes} minutes';

      final payload = jsonEncode({
        'taskId': taskId,
        'reminderId': reminderId,
        'occurrence': scheduledAt.toIso8601String(),
        'offset': '${offset.inMinutes}m',
        'strategy': strategy.name,
        'scheduledAt': offsetTime.toIso8601String(),
      });

      final result = await NotificationService.scheduleReminderNotification(
        id: offsetNotificationId,
        title: title,
        body: body,
        scheduledTime: offsetTime,
        payload: payload,
        taskId: taskId,
        occurrence: scheduledAt,
        offsetStr: '${offset.inMinutes}m',
        strategyStr: strategy.name,
      );

      if (isMain || mainScheduleResult == NotificationScheduleResult.failed) {
        mainScheduleResult = result;
      }
    }

    final nowDt = DateTime.now();
    ReminderStatus status;
    ScheduleOutcome outcome;

    switch (mainScheduleResult) {
      case NotificationScheduleResult.exact:
        status = ReminderStatus.scheduled;
        outcome = ScheduleOutcome.scheduled;
      case NotificationScheduleResult.inexact:
        status = ReminderStatus.scheduled;
        outcome = ScheduleOutcome.inexactScheduled;
      case NotificationScheduleResult.permissionRequired:
        status = ReminderStatus.permissionRequired;
        outcome = ScheduleOutcome.permissionRequired;
      case NotificationScheduleResult.pastTime:
        status = ReminderStatus.scheduled;
        outcome = ScheduleOutcome.pastTime;
      case NotificationScheduleResult.failed:
        status = ReminderStatus.scheduled;
        outcome = ScheduleOutcome.failed;
    }

    final reminder = Reminder(
      id: reminderId,
      taskId: taskId,
      scheduledAt: scheduledAt,
      timezone: tz,
      notificationId: baseNotificationId,
      status: status,
      createdAt: existing != null ? existing.createdAt : nowDt,
      updatedAt: nowDt,
    );

    await _db.upsertReminder(
      RemindersCompanion(
        id: Value(reminder.id),
        taskId: Value(reminder.taskId),
        scheduledAt: Value(reminder.scheduledAt),
        timezone: Value(reminder.timezone),
        notificationId: Value(reminder.notificationId),
        status: Value(reminder.status.name),
        createdAt: Value(reminder.createdAt),
        updatedAt: Value(reminder.updatedAt),
      ),
    );

    return ReminderScheduleResult(
      reminder: reminder,
      outcome: outcome,
      message: _outcomeMessage(outcome, scheduledAt),
    );
  }

  Future<void> cancelReminderForTask(String taskId) async {
    await _cancelAllNotificationOffsets(taskId);
    await _db.cancelRemindersForTask(taskId);
  }

  Future<void> completeReminder(String reminderId) async {
    final entry = await _db.getReminderById(reminderId);
    if (entry == null) return;
    await _cancelAllNotificationOffsets(entry.taskId);
    await _db.updateReminderStatus(reminderId, ReminderStatus.completed.name);

    // Check if task is recurring and advance if possible
    final task = await (_db.select(_db.tasks)..where((t) => t.id.equals(entry.taskId))).getSingleOrNull();
    if (task != null && task.recurrenceRuleJson != null && task.recurrenceRuleJson!.trim().isNotEmpty) {
      await _advanceRecurrence(task, entry.scheduledAt);
    }
  }

  Future<void> snoozeReminder(String reminderId, {Duration duration = const Duration(minutes: 10)}) async {
    final entry = await _db.getReminderById(reminderId);
    if (entry == null) return;

    final task = await (_db.select(_db.tasks)..where((t) => t.id.equals(entry.taskId))).getSingleOrNull();
    final oldTaskDueAt = task?.dueAt;
    final oldReminderScheduledAt = entry.scheduledAt;

    await _cancelAllNotificationOffsets(entry.taskId);

    final newTime = _timeService.nowTZ().add(duration);
    final title = task?.title ?? 'Reminder';

    debugPrint('[ASTRA SNOOZE]\noldTaskDueAt=$oldTaskDueAt\noldReminderScheduledAt=$oldReminderScheduledAt');
    debugPrint('[ASTRA SNOOZE]\nnewTime=$newTime');

    final scheduleResult = await NotificationService.scheduleReminderNotification(
      id: entry.notificationId,
      title: title,
      body: 'Snoozed reminder: $title',
      scheduledTime: newTime,
      payload: jsonEncode({
        'taskId': entry.taskId,
        'reminderId': reminderId,
        'occurrence': newTime.toIso8601String(),
        'offset': '0m',
        'strategy': 'SNOOZE',
        'scheduledAt': newTime.toIso8601String(),
      }),
      taskId: entry.taskId,
      occurrence: newTime,
      offsetStr: '0m',
      strategyStr: 'SNOOZE',
    );

    final status = scheduleResult == NotificationScheduleResult.permissionRequired
        ? ReminderStatus.permissionRequired.name
        : ReminderStatus.snoozed.name;

    final now = DateTime.now();

    await (_db.update(_db.reminders)..where((r) => r.id.equals(reminderId))).write(
      RemindersCompanion(
        scheduledAt: Value(newTime),
        status: Value(status),
        updatedAt: Value(now),
      ),
    );

    // Update parent Task.dueAt to synchronize task state with snoozed reminder time
    await (_db.update(_db.tasks)..where((t) => t.id.equals(entry.taskId))).write(
      TasksCompanion(
        dueAt: Value(newTime),
        updatedAt: Value(now),
      ),
    );

    debugPrint('[ASTRA SNOOZE]\ntaskUpdated=true\nreminderUpdated=true\nnotificationRescheduled=true');
  }

  /// On app startup: re-schedule any active reminders whose OS notification may be missing.
  /// For recurring tasks, if historical occurrences were missed while the app was closed,
  /// advances directly to the next valid future occurrence (no historical notification spam).
  Future<void> reconcilePendingReminders() async {
    final active = await _db.getActiveReminders();
    final now = _timeService.nowTZ();

    for (final entry in active) {
      final scheduledTz = _timeService.toTZ(entry.scheduledAt);
      if (scheduledTz.isBefore(now)) {
        await _db.updateReminderStatus(entry.id, ReminderStatus.delivered.name);

        final task = await (_db.select(_db.tasks)..where((t) => t.id.equals(entry.taskId))).getSingleOrNull();
        if (task != null && task.recurrenceRuleJson != null && task.recurrenceRuleJson!.trim().isNotEmpty) {
          await _advanceRecurrence(task, now);
        }
        continue;
      }

      final task = await (_db.select(_db.tasks)..where((t) => t.id.equals(entry.taskId))).getSingleOrNull();
      if (task == null) {
        await _db.updateReminderStatus(entry.id, ReminderStatus.cancelled.name);
        continue;
      }

      final strategy = ReminderStrategyX.resolve(
        priority: task.priority,
        eventType: task.category,
      );

      for (final offset in strategy.offsets) {
        final offsetTime = entry.scheduledAt.subtract(offset);
        final offsetTz = _timeService.toTZ(offsetTime);
        if (offsetTz.isBefore(now)) continue;

        final isMain = offset == Duration.zero;
        final title = isMain ? task.title : 'Prep: ${task.title}';
        final body = isMain ? 'Time for: ${task.title}' : '${task.title} in ${offset.inMinutes} minutes.';

        final result = await NotificationService.scheduleReminderNotification(
          id: entry.taskId.hashCode + offset.inMinutes,
          title: title,
          body: body,
          scheduledTime: offsetTime,
          payload: jsonEncode({
            'taskId': entry.taskId,
            'reminderId': entry.id,
            'occurrence': entry.scheduledAt.toIso8601String(),
            'offset': '${offset.inMinutes}m',
            'strategy': strategy.name,
            'scheduledAt': offsetTime.toIso8601String(),
          }),
          taskId: entry.taskId,
          occurrence: entry.scheduledAt,
          offsetStr: '${offset.inMinutes}m',
          strategyStr: strategy.name,
        );

        if (result == NotificationScheduleResult.permissionRequired) {
          await _db.updateReminderStatus(entry.id, ReminderStatus.permissionRequired.name);
        }
      }
    }

    debugPrint('[ReminderService] Reconciled ${active.length} pending reminders.');
  }

  /// Advances a recurring task to its next occurrence strictly after [afterTime].
  /// If no further occurrences exist, marks the task completed.
  Future<void> _advanceRecurrence(TaskEntry task, DateTime afterTime) async {
    RecurrenceRule? rule;
    try {
      if (task.recurrenceRuleJson != null && task.recurrenceRuleJson!.trim().isNotEmpty) {
        rule = RecurrenceRule.fromJson(task.recurrenceRuleJson!);
      }
    } catch (e) {
      debugPrint('[ReminderService] Error parsing recurrenceRuleJson for task ${task.id}: $e');
    }

    if (rule == null || rule.frequency == RecurrenceFrequency.none) {
      return;
    }

    final nextOcc = recurrenceEngine.nextOccurrence(rule, afterTime);

    if (nextOcc != null) {
      debugPrint('[ASTRA RECURRENCE]\ntask=${task.id}\ncurrent=$afterTime\nnext=$nextOcc\naction=ADVANCE');

      // Update task dueDate to next occurrence and ensure status is active/pending
      final now = DateTime.now();
      await (_db.update(_db.tasks)..where((t) => t.id.equals(task.id))).write(
        TasksCompanion(
          dueAt: Value(nextOcc),
          status: const Value('active'),
          completedAt: const Value(null),
          updatedAt: Value(now),
        ),
      );

      final strategy = ReminderStrategyX.resolve(
        priority: task.priority,
        eventType: task.category,
      );

      // Schedule reminder for the next occurrence with appropriate strategy
      await scheduleReminder(
        taskId: task.id,
        taskTitle: task.title,
        scheduledAt: nextOcc,
        strategy: strategy,
      );
    } else {
      debugPrint('[ASTRA RECURRENCE]\ntask=${task.id}\ncurrent=$afterTime\nnext=null\naction=COMPLETE');

      final now = DateTime.now();
      await (_db.update(_db.tasks)..where((t) => t.id.equals(task.id))).write(
        TasksCompanion(
          status: const Value('completed'),
          completedAt: Value(now),
          updatedAt: Value(now),
        ),
      );
    }
  }

  /// Handles notification action taps (DONE / SNOOZE).
  Future<void> handleNotificationAction(String actionId, String? payload) async {
    if (payload == null || payload.isEmpty) return;

    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final taskId = data['taskId'] as String?;
      final reminderId = data['reminderId'] as String?;
      if (taskId == null) return;

      debugPrint('[ASTRA SNOOZE]\naction_received=true\nreminderId=$reminderId\nactionId=$actionId');

      var remId = reminderId;
      if (remId == null) {
        final activeReminders = await (_db.select(_db.reminders)
              ..where((r) => r.taskId.equals(taskId))
              ..where((r) => r.status.equals(ReminderStatus.scheduled.name)))
            .get();
        if (activeReminders.isNotEmpty) {
          remId = activeReminders.first.id;
        }
      }

      switch (actionId) {
        case NotificationService.actionDone:
          final task = await (_db.select(_db.tasks)..where((t) => t.id.equals(taskId))).getSingleOrNull();
          final isRecurring = task != null && task.recurrenceRuleJson != null && task.recurrenceRuleJson!.trim().isNotEmpty;

          if (remId != null) {
            await completeReminder(remId);
          }

          // For non-recurring tasks, mark completed immediately.
          // For recurring tasks, completeReminder() handles advancing or completing the task.
          if (!isRecurring) {
            await (_db.update(_db.tasks)..where((t) => t.id.equals(taskId))).write(
              TasksCompanion(
                status: const Value('completed'),
                completedAt: Value(DateTime.now()),
                updatedAt: Value(DateTime.now()),
              ),
            );
          }

        case NotificationService.actionSnooze10m:
          if (remId != null) {
            await snoozeReminder(remId);
          } else {
            // Fallback: snooze directly by taskId
            final now = DateTime.now();
            final newTime = now.add(const Duration(minutes: 10));
            final createdRemId = now.millisecondsSinceEpoch.toString();
            await _db.into(_db.reminders).insert(
                  RemindersCompanion.insert(
                    id: createdRemId,
                    taskId: taskId,
                    scheduledAt: newTime,
                    notificationId: taskId.hashCode,
                    status: Value(ReminderStatus.snoozed.name),
                    createdAt: now,
                    updatedAt: now,
                  ),
                );
            await (_db.update(_db.tasks)..where((t) => t.id.equals(taskId))).write(
              TasksCompanion(
                dueAt: Value(newTime),
                updatedAt: Value(now),
              ),
            );
            await NotificationService.scheduleReminderNotification(
              id: taskId.hashCode,
              title: 'Reminder',
              body: 'Snoozed reminder',
              scheduledTime: newTime,
              payload: jsonEncode({
                'taskId': taskId,
                'reminderId': createdRemId,
                'occurrence': newTime.toIso8601String(),
                'offset': '0m',
                'strategy': 'SNOOZE',
                'scheduledAt': newTime.toIso8601String(),
              }),
              taskId: taskId,
              occurrence: newTime,
              offsetStr: '0m',
              strategyStr: 'SNOOZE',
            );
          }
        default:
          break;
      }
    } catch (e) {
      debugPrint('[ReminderService] Action handler error: $e');
    }
  }

  String? _outcomeMessage(ScheduleOutcome outcome, DateTime scheduledAt) {
    final formatted = scheduledAt.toLocal().toString();
    return switch (outcome) {
      ScheduleOutcome.scheduled => 'Reminder scheduled for $formatted.',
      ScheduleOutcome.inexactScheduled =>
        'Reminder scheduled (approximate — exact alarm permission unavailable).',
      ScheduleOutcome.permissionRequired =>
        'Task saved but notification permission required for exact reminder.',
      ScheduleOutcome.pastTime => 'Reminder time is in the past.',
      ScheduleOutcome.failed => 'Task saved but notification scheduling failed.',
    };
  }
}
