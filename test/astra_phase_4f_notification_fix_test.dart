import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' as drift;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astra/core/database/database.dart';
import 'package:astra/core/reminders/reminder.dart';
import 'package:astra/core/time/astra_time_service.dart';
import 'package:astra/services/assistant/astra_temporal_engine.dart';
import 'package:astra/services/notification_service.dart';
import 'package:astra/services/reminder_service.dart';
import 'helpers/test_database_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late ReminderService reminderService;
  late AstraTemporalEngine temporalEngine;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = TestDatabaseHelper.createMemoryDatabase();
    reminderService = ReminderService(db);
    temporalEngine = const AstraTemporalEngine();
  });

  tearDown(() async {
    await db.close();
  });

  group('ASTRA Phase 4F — Physical Notification Failure Diagnostic & Regression Tests (A–I)', () {
    // ─── A. Singular Minute Parsing ──────────────────────────────────────────
    test('A. singular minute expressions parse to exactly now + 1 minute', () {
      final now = DateTime(2026, 8, 18, 15, 30, 0);
      final expected = now.add(const Duration(minutes: 1));

      final variations = [
        'remind me to drink water in 1 minute',
        'remind me to drink water in 1 min',
        'remind me to drink water in next minute',
        'remind me to drink water in the next minute',
        'remind me to drink water next min',
        'remind me to drink water in next min',
        'remind me to drink water in a minute',
        'remind me to drink water after a minute',
        'drink water 1 minute from now',
        'drink water one minute from now',
      ];

      for (final text in variations) {
        final result = temporalEngine.parse(text, now: now);
        expect(result.eventStart, isNotNull, reason: 'Failed for input: "$text"');
        expect(result.eventStart, equals(expected), reason: 'Wrong time for input: "$text"');
      }
    });

    // ─── B. Plural Minute Parsing ────────────────────────────────────────────
    test('B. plural minute expressions parse to exact offsets', () {
      final now = DateTime(2026, 8, 18, 15, 30, 0);

      final tests = {
        'remind me in 2 minutes': now.add(const Duration(minutes: 2)),
        'remind me in 2 mins': now.add(const Duration(minutes: 2)),
        'remind me in next 2 minutes': now.add(const Duration(minutes: 2)),
        'remind me in the next 2 mins': now.add(const Duration(minutes: 2)),
        'remind me in next 5 mins': now.add(const Duration(minutes: 5)),
        'remind me in 10 minutes': now.add(const Duration(minutes: 10)),
        'remind me in fifteen minutes': now.add(const Duration(minutes: 15)),
        'remind me in twenty minutes': now.add(const Duration(minutes: 20)),
        'remind me in thirty mins': now.add(const Duration(minutes: 30)),
      };

      for (final entry in tests.entries) {
        final result = temporalEngine.parse(entry.key, now: now);
        expect(result.eventStart, isNotNull, reason: 'Failed for input: "${entry.key}"');
        expect(result.eventStart, equals(entry.value), reason: 'Wrong time for input: "${entry.key}"');
      }
    });

    // ─── C. Exact Timestamp Conversion ───────────────────────────────────────
    test('C. AstraTimeService converts UTC and local timestamps reliably', () {
      final timeService = AstraTimeService();
      final dt = DateTime(2026, 8, 18, 15, 30, 0);
      final tzDt = timeService.toTZ(dt);

      expect(tzDt.year, equals(2026));
      expect(tzDt.month, equals(8));
      expect(tzDt.day, equals(18));
      expect(tzDt.hour, equals(15));
      expect(tzDt.minute, equals(30));
    });

    // ─── D. DONE Action Payload Handling ─────────────────────────────────────
    test('D. DONE action completes the task and reminder in database', () async {
      final now = DateTime.now();
      const taskId = 'task_done_test_1';
      const reminderId = 'rem_done_test_1';

      await db.into(db.tasks).insert(
            TasksCompanion.insert(
              id: taskId,
              title: 'Drink Water',
              dueAt: drift.Value(now.add(const Duration(minutes: 2))),
              status: const drift.Value('active'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      await db.into(db.reminders).insert(
            RemindersCompanion.insert(
              id: reminderId,
              taskId: taskId,
              scheduledAt: now.add(const Duration(minutes: 2)),
              notificationId: taskId.hashCode,
              status: drift.Value(ReminderStatus.scheduled.name),
              createdAt: now,
              updatedAt: now,
            ),
          );

      final payload = jsonEncode({
        'taskId': taskId,
        'reminderId': reminderId,
      });

      await reminderService.handleNotificationAction(NotificationService.actionDone, payload);

      final task = await (db.select(db.tasks)..where((t) => t.id.equals(taskId))).getSingle();
      final reminder = await (db.select(db.reminders)..where((r) => r.id.equals(reminderId))).getSingle();

      expect(task.status, equals('completed'));
      expect(task.completedAt, isNotNull);
      expect(reminder.status, equals(ReminderStatus.completed.name));
    });

    // ─── E. SNOOZE Action Payload Handling ───────────────────────────────────
    test('E. SNOOZE action shifts reminder +10 minutes and reschedules', () async {
      final now = DateTime.now();
      const taskId = 'task_snooze_test_1';
      const reminderId = 'rem_snooze_test_1';

      await db.into(db.tasks).insert(
            TasksCompanion.insert(
              id: taskId,
              title: 'Team Standup',
              dueAt: drift.Value(now.add(const Duration(minutes: 2))),
              status: const drift.Value('active'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      await db.into(db.reminders).insert(
            RemindersCompanion.insert(
              id: reminderId,
              taskId: taskId,
              scheduledAt: now.add(const Duration(minutes: 2)),
              notificationId: taskId.hashCode,
              status: drift.Value(ReminderStatus.scheduled.name),
              createdAt: now,
              updatedAt: now,
            ),
          );

      final payload = jsonEncode({
        'taskId': taskId,
        'reminderId': reminderId,
      });

      await reminderService.handleNotificationAction(NotificationService.actionSnooze10m, payload);

      final task = await (db.select(db.tasks)..where((t) => t.id.equals(taskId))).getSingle();
      final reminder = await (db.select(db.reminders)..where((r) => r.id.equals(reminderId))).getSingle();

      expect(reminder.status, equals(ReminderStatus.snoozed.name));
      expect(task.dueAt, isNotNull);
      expect(task.dueAt!.isAfter(now.add(const Duration(minutes: 8))), isTrue);
      expect(reminder.scheduledAt.isAfter(now.add(const Duration(minutes: 8))), isTrue);
    });

    // ─── F. Snooze Task / Reminder Synchronization ───────────────────────────
    test('F. snoozing matches Task.dueAt and Reminder.scheduledAt exactly', () async {
      final now = DateTime.now();
      const taskId = 'task_sync_test_1';
      const reminderId = 'rem_sync_test_1';

      await db.into(db.tasks).insert(
            TasksCompanion.insert(
              id: taskId,
              title: 'Review PRs',
              dueAt: drift.Value(now),
              status: const drift.Value('active'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      await db.into(db.reminders).insert(
            RemindersCompanion.insert(
              id: reminderId,
              taskId: taskId,
              scheduledAt: now,
              notificationId: taskId.hashCode,
              status: drift.Value(ReminderStatus.scheduled.name),
              createdAt: now,
              updatedAt: now,
            ),
          );

      await reminderService.snoozeReminder(reminderId, duration: const Duration(minutes: 10));

      final task = await (db.select(db.tasks)..where((t) => t.id.equals(taskId))).getSingle();
      final reminder = await (db.select(db.reminders)..where((r) => r.id.equals(reminderId))).getSingle();

      expect(task.dueAt?.millisecondsSinceEpoch, equals(reminder.scheduledAt.millisecondsSinceEpoch));
    });

    // ─── G. Duplicate Reminder Protection ────────────────────────────────────
    test('G. rescheduling cancels existing reminder and maintains exactly one active reminder', () async {
      const taskId = 'task_dup_prot_1';
      final now = DateTime.now();

      await db.into(db.tasks).insert(
            TasksCompanion.insert(
              id: taskId,
              title: 'Water Plants',
              dueAt: drift.Value(now.add(const Duration(minutes: 5))),
              status: const drift.Value('active'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      // First schedule
      await reminderService.scheduleReminder(
        taskId: taskId,
        taskTitle: 'Water Plants',
        scheduledAt: now.add(const Duration(minutes: 5)),
      );

      // Reschedule for 10 minutes later
      await reminderService.scheduleReminder(
        taskId: taskId,
        taskTitle: 'Water Plants',
        scheduledAt: now.add(const Duration(minutes: 10)),
      );

      final activeReminders = await (db.select(db.reminders)
            ..where((r) => r.taskId.equals(taskId))
            ..where((r) => r.status.equals(ReminderStatus.scheduled.name)))
          .get();

      expect(activeReminders.length, equals(1));
    });

    // ─── H. Recurrence Unaffected by Snooze ───────────────────────────────────
    test('H. snooze does not overwrite recurrence rule on task', () async {
      final now = DateTime.now();
      const taskId = 'task_rec_snooze_1';
      const reminderId = 'rem_rec_snooze_1';
      const rruleJson = '{"frequency":"daily","interval":1,"hour":9,"minute":0}';

      await db.into(db.tasks).insert(
            TasksCompanion.insert(
              id: taskId,
              title: 'Daily Meditation',
              dueAt: drift.Value(now),
              recurrenceRuleJson: const drift.Value(rruleJson),
              status: const drift.Value('active'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      await db.into(db.reminders).insert(
            RemindersCompanion.insert(
              id: reminderId,
              taskId: taskId,
              scheduledAt: now,
              notificationId: taskId.hashCode,
              status: drift.Value(ReminderStatus.scheduled.name),
              createdAt: now,
              updatedAt: now,
            ),
          );

      await reminderService.snoozeReminder(reminderId, duration: const Duration(minutes: 10));

      final task = await (db.select(db.tasks)..where((t) => t.id.equals(taskId))).getSingle();
      expect(task.recurrenceRuleJson, equals(rruleJson));
    });

    // ─── I. Notification Cancellation After DONE ─────────────────────────────
    test('I. completing a reminder marks status completed and suppresses active state', () async {
      final now = DateTime.now();
      const taskId = 'task_cancel_done_1';
      const reminderId = 'rem_cancel_done_1';

      await db.into(db.tasks).insert(
            TasksCompanion.insert(
              id: taskId,
              title: 'Check Mail',
              dueAt: drift.Value(now),
              status: const drift.Value('active'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      await db.into(db.reminders).insert(
            RemindersCompanion.insert(
              id: reminderId,
              taskId: taskId,
              scheduledAt: now,
              notificationId: taskId.hashCode,
              status: drift.Value(ReminderStatus.scheduled.name),
              createdAt: now,
              updatedAt: now,
            ),
          );

      await reminderService.completeReminder(reminderId);

      final active = await db.getActiveReminders();
      expect(active.where((r) => r.id == reminderId), isEmpty);
    });
  });
}
