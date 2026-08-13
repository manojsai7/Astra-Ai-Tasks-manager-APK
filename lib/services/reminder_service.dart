import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/database/database.dart';
import '../core/reminders/reminder.dart';
import '../core/time/astra_time_service.dart';
import 'notification_service.dart';

/// Handles the full reminder lifecycle: persist → schedule OS notification → reconcile.
class ReminderService {
  ReminderService(this._db, {AstraTimeService? timeService})
      : _timeService = timeService ?? AstraTimeService();

  final AppDatabase _db;
  final AstraTimeService _timeService;

  static const _uuid = Uuid();

  /// Creates or reschedules a reminder for [taskId] at [scheduledAt].
  /// Returns honest status — never claims success unless scheduling succeeded.
  Future<ReminderScheduleResult> scheduleReminder({
    required String taskId,
    required String taskTitle,
    required DateTime scheduledAt,
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

    // Cancel any existing active reminder for this task (idempotent reschedule).
    final existing = await _db.getReminderByTaskId(taskId);
    if (existing != null) {
      await NotificationService.cancelNotification(existing.notificationId);
      await _db.updateReminderStatus(existing.id, ReminderStatus.cancelled.name);
    }

    final reminderId = existing?.id ?? _uuid.v4();
    final notificationId = taskId.hashCode;

    final scheduleResult = await NotificationService.scheduleReminderNotification(
      id: notificationId,
      title: taskTitle,
      body: 'Time for: $taskTitle',
      scheduledTime: scheduledAt,
      payload: jsonEncode({'taskId': taskId, 'reminderId': reminderId}),
    );

    final nowDt = DateTime.now();
    ReminderStatus status;
    ScheduleOutcome outcome;

    switch (scheduleResult) {
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
        return const ReminderScheduleResult(
          outcome: ScheduleOutcome.pastTime,
          message: 'Reminder time is in the past.',
        );
      case NotificationScheduleResult.failed:
        status = ReminderStatus.failed;
        outcome = ScheduleOutcome.failed;
    }

    final reminder = Reminder(
      id: reminderId,
      taskId: taskId,
      scheduledAt: scheduledAt,
      timezone: tz,
      notificationId: notificationId,
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
    final existing = await _db.getReminderByTaskId(taskId);
    if (existing == null) return;
    await NotificationService.cancelNotification(existing.notificationId);
    await _db.cancelRemindersForTask(taskId);
  }

  Future<void> completeReminder(String reminderId) async {
    final entry = await _db.getReminderById(reminderId);
    if (entry == null) return;
    await NotificationService.cancelNotification(entry.notificationId);
    await _db.updateReminderStatus(reminderId, ReminderStatus.completed.name);
  }

  Future<void> snoozeReminder(String reminderId, {Duration duration = const Duration(minutes: 10)}) async {
    final entry = await _db.getReminderById(reminderId);
    if (entry == null) return;

    await NotificationService.cancelNotification(entry.notificationId);

    final newTime = _timeService.nowTZ().add(duration);
    final task = await (_db.select(_db.tasks)..where((t) => t.id.equals(entry.taskId))).getSingleOrNull();
    final title = task?.title ?? 'Reminder';

    final scheduleResult = await NotificationService.scheduleReminderNotification(
      id: entry.notificationId,
      title: title,
      body: 'Snoozed reminder: $title',
      scheduledTime: newTime,
      payload: jsonEncode({'taskId': entry.taskId, 'reminderId': reminderId}),
    );

    final status = scheduleResult == NotificationScheduleResult.permissionRequired
        ? ReminderStatus.permissionRequired.name
        : ReminderStatus.snoozed.name;

    await (_db.update(_db.reminders)..where((r) => r.id.equals(reminderId))).write(
      RemindersCompanion(
        scheduledAt: Value(newTime),
        status: Value(status),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// On app startup: re-schedule any active reminders whose OS notification may be missing.
  Future<void> reconcilePendingReminders() async {
    final active = await _db.getActiveReminders();
    final now = _timeService.nowTZ();

    for (final entry in active) {
      if (_timeService.toTZ(entry.scheduledAt).isBefore(now)) {
        await _db.updateReminderStatus(entry.id, ReminderStatus.delivered.name);
        continue;
      }

      final task = await (_db.select(_db.tasks)..where((t) => t.id.equals(entry.taskId))).getSingleOrNull();
      if (task == null) {
        await _db.updateReminderStatus(entry.id, ReminderStatus.cancelled.name);
        continue;
      }

      final result = await NotificationService.scheduleReminderNotification(
        id: entry.notificationId,
        title: task.title,
        body: 'Time for: ${task.title}',
        scheduledTime: entry.scheduledAt,
        payload: jsonEncode({'taskId': entry.taskId, 'reminderId': entry.id}),
      );

      if (result == NotificationScheduleResult.failed) {
        await _db.updateReminderStatus(entry.id, ReminderStatus.failed.name);
      }
    }

    debugPrint('[ReminderService] Reconciled ${active.length} pending reminders.');
  }

  /// Handles notification action taps (DONE / SNOOZE).
  Future<void> handleNotificationAction(String actionId, String? payload) async {
    if (payload == null || payload.isEmpty) return;

    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final taskId = data['taskId'] as String?;
      final reminderId = data['reminderId'] as String?;
      if (taskId == null) return;

      switch (actionId) {
        case NotificationService.actionDone:
          if (reminderId != null) await completeReminder(reminderId);
          await (_db.update(_db.tasks)..where((t) => t.id.equals(taskId))).write(
            TasksCompanion(
              status: const Value('completed'),
              completedAt: Value(DateTime.now()),
              updatedAt: Value(DateTime.now()),
            ),
          );
        case NotificationService.actionSnooze10m:
          if (reminderId != null) {
            await snoozeReminder(reminderId);
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
