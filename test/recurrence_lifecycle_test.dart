import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astra/core/database/database.dart';
import 'package:astra/core/time/astra_time_service.dart';
import 'package:astra/services/assistant/astra_recurrence_engine.dart';
import 'package:astra/services/notification_service.dart';
import 'package:astra/services/reminder_service.dart';
import 'helpers/test_database_helper.dart';
import 'helpers/test_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late ReminderService reminderService;
  late SettableTestClock testClock;
  late AstraTimeService timeService;
  const recurrenceEngine = AstraRecurrenceEngine();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = TestDatabaseHelper.createMemoryDatabase();
    testClock = SettableTestClock(DateTime(2026, 5, 20, 8, 0));
    timeService = AstraTimeService(clock: testClock);
    reminderService = ReminderService(
      db,
      timeService: timeService,
      recurrenceEngine: recurrenceEngine,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('ASTRA Phase 2V-4: Recurring Reminder Lifecycle Tests', () {
    // A. DAILY: current occurrence completed → next day scheduled
    test('A. DAILY: completing current occurrence schedules next day and updates task.dueAt', () async {
      testClock.set(DateTime(2026, 5, 25, 8, 0));
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
        startDate: DateTime(2026, 5, 25),
        hour: 9,
        minute: 0,
      );

      const taskId = 'daily-task-1';
      final startOcc = DateTime(2026, 5, 25, 9, 0);

      await TestDatabaseHelper.insertTaskRow(
        db,
        id: taskId,
        title: 'Daily Standup',
        dueAt: startOcc,
        recurrenceRuleJson: rule.toJson(),
      );

      const reminderId = 'rem-daily-1';
      await TestDatabaseHelper.insertReminderRow(
        db,
        id: reminderId,
        taskId: taskId,
        scheduledAt: startOcc,
        notificationId: 101,
      );

      await reminderService.completeReminder(reminderId);

      final updatedTask = await (db.select(db.tasks)..where((t) => t.id.equals(taskId))).getSingle();
      expect(updatedTask.dueAt, DateTime(2026, 5, 26, 9, 0));

      final activeReminders = await db.getActiveReminders();
      expect(activeReminders.length, 1);
      expect(activeReminders.first.scheduledAt, DateTime(2026, 5, 26, 9, 0));
    });

    // B. WEEKDAYS: Friday completed → Monday next occurrence
    test('B. WEEKDAYS: completing Friday occurrence schedules Monday next occurrence', () async {
      testClock.set(DateTime(2026, 5, 22, 8, 0)); // Friday
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.weekdays,
        startDate: DateTime(2026, 5, 22),
        hour: 9,
        minute: 0,
      );

      const taskId = 'weekday-task-1';
      final friOcc = DateTime(2026, 5, 22, 9, 0);

      await TestDatabaseHelper.insertTaskRow(
        db,
        id: taskId,
        title: 'Weekday Standup',
        dueAt: friOcc,
        recurrenceRuleJson: rule.toJson(),
      );

      const reminderId = 'rem-weekday-1';
      await TestDatabaseHelper.insertReminderRow(
        db,
        id: reminderId,
        taskId: taskId,
        scheduledAt: friOcc,
        notificationId: 102,
      );

      await reminderService.completeReminder(reminderId);

      final updatedTask = await (db.select(db.tasks)..where((t) => t.id.equals(taskId))).getSingle();
      expect(updatedTask.dueAt, DateTime(2026, 5, 25, 9, 0)); // Monday May 25

      final activeReminders = await db.getActiveReminders();
      expect(activeReminders.length, 1);
      expect(activeReminders.first.scheduledAt, DateTime(2026, 5, 25, 9, 0));
    });

    // C. WEEKLY: Monday completed → next Monday scheduled
    test('C. WEEKLY: completing Monday occurrence schedules next Monday', () async {
      testClock.set(DateTime(2026, 5, 18, 10, 0)); // Monday
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.weekly,
        startDate: DateTime(2026, 5, 18),
        hour: 11,
        minute: 0,
      );

      const taskId = 'weekly-task-1';
      final monOcc = DateTime(2026, 5, 18, 11, 0);

      await TestDatabaseHelper.insertTaskRow(
        db,
        id: taskId,
        title: 'Weekly 1:1',
        dueAt: monOcc,
        recurrenceRuleJson: rule.toJson(),
      );

      const reminderId = 'rem-weekly-1';
      await TestDatabaseHelper.insertReminderRow(
        db,
        id: reminderId,
        taskId: taskId,
        scheduledAt: monOcc,
        notificationId: 103,
      );

      await reminderService.completeReminder(reminderId);

      final updatedTask = await (db.select(db.tasks)..where((t) => t.id.equals(taskId))).getSingle();
      expect(updatedTask.dueAt, DateTime(2026, 5, 25, 11, 0));

      final activeReminders = await db.getActiveReminders();
      expect(activeReminders.length, 1);
      expect(activeReminders.first.scheduledAt, DateTime(2026, 5, 25, 11, 0));
    });

    // D. MONTHLY: Jan 31 completed → Feb valid date scheduled
    test('D. MONTHLY: Jan 31 occurrence completes and advances to Feb 28', () async {
      testClock.set(DateTime(2026, 1, 31, 8, 0));
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.monthly,
        startDate: DateTime(2026, 1, 31),
        hour: 10,
        minute: 0,
      );

      const taskId = 'monthly-task-1';
      final janOcc = DateTime(2026, 1, 31, 10, 0);

      await TestDatabaseHelper.insertTaskRow(
        db,
        id: taskId,
        title: 'Monthly Report',
        dueAt: janOcc,
        recurrenceRuleJson: rule.toJson(),
      );

      const reminderId = 'rem-monthly-1';
      await TestDatabaseHelper.insertReminderRow(
        db,
        id: reminderId,
        taskId: taskId,
        scheduledAt: janOcc,
        notificationId: 104,
      );

      await reminderService.completeReminder(reminderId);

      final updatedTask = await (db.select(db.tasks)..where((t) => t.id.equals(taskId))).getSingle();
      expect(updatedTask.dueAt, DateTime(2026, 2, 28, 10, 0));

      final activeReminders = await db.getActiveReminders();
      expect(activeReminders.length, 1);
      expect(activeReminders.first.scheduledAt, DateTime(2026, 2, 28, 10, 0));
    });

    // E. END DATE: final occurrence completed → no next reminder, task completed
    test('E. END DATE: completing final occurrence completes task and schedules no new reminders', () async {
      testClock.set(DateTime(2026, 5, 22, 8, 0));
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
        startDate: DateTime(2026, 5, 20),
        endDate: DateTime(2026, 5, 22, 23, 59),
        hour: 9,
        minute: 0,
      );

      const taskId = 'finite-task-1';
      final finalOcc = DateTime(2026, 5, 22, 9, 0);

      await TestDatabaseHelper.insertTaskRow(
        db,
        id: taskId,
        title: 'Finite Daily Task',
        dueAt: finalOcc,
        recurrenceRuleJson: rule.toJson(),
      );

      const reminderId = 'rem-finite-1';
      await TestDatabaseHelper.insertReminderRow(
        db,
        id: reminderId,
        taskId: taskId,
        scheduledAt: finalOcc,
        notificationId: 105,
      );

      await reminderService.completeReminder(reminderId);

      final updatedTask = await (db.select(db.tasks)..where((t) => t.id.equals(taskId))).getSingle();
      expect(updatedTask.status, 'completed');

      final activeReminders = await db.getActiveReminders();
      expect(activeReminders.isEmpty, isTrue);
    });

    // F. ONE-SHOT REGRESSION: non-recurring task completed → marks completed, no recurrence
    test('F. ONE-SHOT REGRESSION: non-recurring task completes normally without recurrence advancement', () async {
      testClock.set(DateTime(2026, 5, 20, 14, 0));
      const taskId = 'oneshot-task-1';
      final occ = DateTime(2026, 5, 20, 15, 0);

      await TestDatabaseHelper.insertTaskRow(
        db,
        id: taskId,
        title: 'Single Meeting',
        dueAt: occ,
      );

      const reminderId = 'rem-oneshot-1';
      await TestDatabaseHelper.insertReminderRow(
        db,
        id: reminderId,
        taskId: taskId,
        scheduledAt: occ,
        notificationId: 106,
      );

      await reminderService.handleNotificationAction(
        NotificationService.actionDone,
        '{"taskId": "$taskId", "reminderId": "$reminderId"}',
      );

      final updatedTask = await (db.select(db.tasks)..where((t) => t.id.equals(taskId))).getSingle();
      expect(updatedTask.status, 'completed');

      final activeReminders = await db.getActiveReminders();
      expect(activeReminders.isEmpty, isTrue);
    });

    // G. SNOOZE: snooze recurring occurrence reschedules +10m, does NOT advance recurrence
    test('G. SNOOZE: snooze extends current occurrence and does not advance recurrence', () async {
      testClock.set(DateTime(2026, 5, 25, 8, 0));
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
        startDate: DateTime(2026, 5, 25),
        hour: 9,
        minute: 0,
      );

      const taskId = 'snooze-task-1';
      final occ = DateTime(2026, 5, 25, 9, 0);

      await TestDatabaseHelper.insertTaskRow(
        db,
        id: taskId,
        title: 'Snoozable Habit',
        dueAt: occ,
        recurrenceRuleJson: rule.toJson(),
      );

      const reminderId = 'rem-snooze-1';
      await TestDatabaseHelper.insertReminderRow(
        db,
        id: reminderId,
        taskId: taskId,
        scheduledAt: occ,
        notificationId: 107,
      );

      await reminderService.handleNotificationAction(
        NotificationService.actionSnooze10m,
        '{"taskId": "$taskId", "reminderId": "$reminderId"}',
      );

      final rem = await db.getReminderById(reminderId);
      expect(rem!.status, 'snoozed');
      expect(rem.scheduledAt, DateTime(2026, 5, 25, 8, 10)); // clock was 8:00 + 10m

      // Task due date synchronized to new snooze time; recurrence NOT advanced
      final task = await (db.select(db.tasks)..where((t) => t.id.equals(taskId))).getSingle();
      expect(task.dueAt, DateTime(2026, 5, 25, 8, 10));
      expect(task.recurrenceRuleJson, isNotNull);
      expect(task.recurrenceRuleJson, contains('DAILY'));
    });

    // G2. ONE-SHOT SNOOZE: moves Task.dueAt and Reminder.scheduledAt +10m with exactly 1 active reminder
    test('G2. ONE-SHOT SNOOZE: moves Task.dueAt and Reminder.scheduledAt +10m with exactly 1 active reminder', () async {
      testClock.set(DateTime(2026, 5, 20, 14, 0));
      const taskId = 'oneshot-snooze-1';
      final occ = DateTime(2026, 5, 20, 14, 0);

      await TestDatabaseHelper.insertTaskRow(
        db,
        id: taskId,
        title: 'One-shot Drink Water',
        dueAt: occ,
      );

      const reminderId = 'rem-oneshot-snooze-1';
      await TestDatabaseHelper.insertReminderRow(
        db,
        id: reminderId,
        taskId: taskId,
        scheduledAt: occ,
        notificationId: 108,
      );

      await reminderService.snoozeReminder(reminderId, duration: const Duration(minutes: 10));

      final rem = await db.getReminderById(reminderId);
      expect(rem!.status, 'snoozed');
      expect(rem.scheduledAt, DateTime(2026, 5, 20, 14, 10));

      final task = await (db.select(db.tasks)..where((t) => t.id.equals(taskId))).getSingle();
      expect(task.dueAt, DateTime(2026, 5, 20, 14, 10));
      expect(task.dueAt, rem.scheduledAt);

      final activeReminders = await db.getActiveReminders();
      expect(activeReminders.length, 1);
    });

    // H. MULTIPLE MISSED DAYS: app resumes several days later → jumps to first valid future occurrence
    test('H. MULTIPLE MISSED DAYS: reconcilePendingReminders jumps directly to next valid future occurrence', () async {
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
        startDate: DateTime(2026, 5, 10),
        hour: 9,
        minute: 0,
      );

      const taskId = 'missed-task-1';
      final missedOcc = DateTime(2026, 5, 15, 10, 0);

      await TestDatabaseHelper.insertTaskRow(
        db,
        id: taskId,
        title: 'Missed Habit',
        dueAt: missedOcc,
        recurrenceRuleJson: rule.toJson(),
      );

      const reminderId = 'rem-missed-1';
      await TestDatabaseHelper.insertReminderRow(
        db,
        id: reminderId,
        taskId: taskId,
        scheduledAt: missedOcc,
        notificationId: 109,
      );

      // Fast forward system clock to May 20
      testClock.set(DateTime(2026, 5, 20, 8, 0));

      await reminderService.reconcilePendingReminders();

      final oldRem = await db.getReminderById(reminderId);
      expect(oldRem!.status, 'delivered');

      final activeReminders = await db.getActiveReminders();
      expect(activeReminders.length, 1);
      expect(activeReminders.first.scheduledAt, DateTime(2026, 5, 20, 9, 0));

      final updatedTask = await (db.select(db.tasks)..where((t) => t.id.equals(taskId))).getSingle();
      expect(updatedTask.dueAt, DateTime(2026, 5, 20, 9, 0));
    });

    // I. DUPLICATE PROTECTION: calling scheduleReminder multiple times leaves exactly one active reminder
    test('I. DUPLICATE PROTECTION: calling scheduleReminder multiple times leaves exactly one active reminder', () async {
      testClock.set(DateTime(2026, 5, 20, 8, 0));
      const taskId = 'dup-task-1';

      await TestDatabaseHelper.insertTaskRow(
        db,
        id: taskId,
        title: 'Duplicate Target',
        dueAt: DateTime(2026, 5, 20, 10, 0),
      );

      await reminderService.scheduleReminder(
        taskId: taskId,
        taskTitle: 'Duplicate Target',
        scheduledAt: DateTime(2026, 5, 20, 10, 0),
      );

      await reminderService.scheduleReminder(
        taskId: taskId,
        taskTitle: 'Duplicate Target',
        scheduledAt: DateTime(2026, 5, 20, 11, 0),
      );

      final activeReminders = await db.getActiveReminders();
      expect(activeReminders.length, 1);
      expect(activeReminders.first.scheduledAt, DateTime(2026, 5, 20, 11, 0));
    });

    // K. SNOOZE VIA NOTIFICATION ACTION: notification action triggers snooze and updates task + reminder
    test('K. SNOOZE VIA NOTIFICATION ACTION: moves Task.dueAt and Reminder.scheduledAt +10m without advancing recurrence', () async {
      final baseTime = DateTime(2026, 5, 20, 9, 0);
      testClock.set(baseTime);

      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
        startDate: DateTime(2026, 5, 20),
        hour: 9,
        minute: 0,
      );

      const taskId = 'snooze-action-task-1';
      const reminderId = 'snooze-action-rem-1';

      await TestDatabaseHelper.insertTaskRow(
        db,
        id: taskId,
        title: 'Daily Review',
        dueAt: baseTime,
        recurrenceRuleJson: rule.toJson(),
      );

      await TestDatabaseHelper.insertReminderRow(
        db,
        id: reminderId,
        taskId: taskId,
        scheduledAt: baseTime,
        notificationId: 555,
      );

      // Invoke notification action callback directly
      final payload = '{"taskId": "$taskId", "reminderId": "$reminderId"}';
      await reminderService.handleNotificationAction(NotificationService.actionSnooze10m, payload);

      final expectedSnoozeTime = DateTime(2026, 5, 20, 9, 10);

      // 1. Task dueAt changes to +10m
      final task = await (db.select(db.tasks)..where((t) => t.id.equals(taskId))).getSingle();
      expect(task.dueAt, expectedSnoozeTime);
      expect(task.recurrenceRuleJson, isNotNull);
      expect(task.status, 'active');

      // 2. Reminder scheduledAt changes to +10m
      final reminder = await (db.select(db.reminders)..where((r) => r.id.equals(reminderId))).getSingle();
      expect(reminder.scheduledAt, expectedSnoozeTime);
      expect(reminder.status, 'snoozed');

      // 3. Exactly one active reminder
      final activeReminders = await db.getActiveReminders();
      expect(activeReminders.length, 1);
    });
  });
}
