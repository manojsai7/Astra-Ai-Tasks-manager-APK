import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:astra/core/database/database.dart';
import 'package:astra/models/task.dart';
import 'package:astra/services/notification_service.dart';
import 'package:astra/services/reminder_service.dart';
import 'package:astra/services/email/astra_email_analyzer.dart';
import 'package:astra/features/scheduler/data/services/gmail_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ASTRA Production Reliability Tests', () {
    late AppDatabase db;
    late ReminderService reminderService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      db = AppDatabase(NativeDatabase.memory());
      reminderService = ReminderService(db);
      NotificationService.setActionCallback(reminderService.handleNotificationAction);
    });

    tearDown(() async {
      await db.close();
    });

    test('1. Background Notification Action: DONE completes task and cancels reminder', () async {
      final now = DateTime.now();
      const taskId = 'task_bg_done_1';
      const reminderId = 'rem_bg_done_1';

      await db.into(db.tasks).insert(
            TasksCompanion.insert(
              id: taskId,
              title: 'Complete Project Report',
              dueAt: Value(now.add(const Duration(hours: 2))),
              createdAt: now,
              updatedAt: now,
            ),
          );

      await db.into(db.reminders).insert(
            RemindersCompanion.insert(
              id: reminderId,
              taskId: taskId,
              scheduledAt: now.add(const Duration(hours: 2)),
              notificationId: 1001,
              status: const Value('scheduled'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      final payload = jsonEncode({
        'taskId': taskId,
        'reminderId': reminderId,
        'scheduledAt': now.add(const Duration(hours: 2)).toIso8601String(),
      });

      final response = NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotificationAction,
        actionId: NotificationService.actionDone,
        payload: payload,
      );

      await NotificationService.handleNotificationActionResponse(response);

      final updatedTask = await (db.select(db.tasks)..where((t) => t.id.equals(taskId))).getSingle();
      expect(updatedTask.status, 'completed');
      expect(updatedTask.completedAt, isNotNull);

      final updatedReminder = await (db.select(db.reminders)..where((r) => r.id.equals(reminderId))).getSingle();
      expect(updatedReminder.status, 'completed');
    });

    test('2. Background Notification Action: SNOOZE 10m reschedules task and reminder +10m', () async {
      final now = DateTime.now();
      const taskId = 'task_bg_snooze_1';
      const reminderId = 'rem_bg_snooze_1';
      final initialDue = now;

      await db.into(db.tasks).insert(
            TasksCompanion.insert(
              id: taskId,
              title: 'Math Homework',
              dueAt: Value(initialDue),
              createdAt: now,
              updatedAt: now,
            ),
          );

      await db.into(db.reminders).insert(
            RemindersCompanion.insert(
              id: reminderId,
              taskId: taskId,
              scheduledAt: initialDue,
              notificationId: 1002,
              status: const Value('scheduled'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      final payload = jsonEncode({
        'taskId': taskId,
        'reminderId': reminderId,
        'scheduledAt': initialDue.toIso8601String(),
      });

      final response = NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotificationAction,
        actionId: NotificationService.actionSnooze10m,
        payload: payload,
      );

      await NotificationService.handleNotificationActionResponse(response);

      final updatedTask = await (db.select(db.tasks)..where((t) => t.id.equals(taskId))).getSingle();
      expect(updatedTask.dueAt, isNotNull);
      expect(updatedTask.dueAt!.isAfter(initialDue), isTrue);

      final updatedReminder = await (db.select(db.reminders)..where((r) => r.id.equals(reminderId))).getSingle();
      expect(updatedReminder.status, 'snoozed');
    });

    test('3. Background Notification Action with null reminderId resolves active reminder by taskId', () async {
      final now = DateTime.now();
      const taskId = 'task_bg_null_rem_1';
      const reminderId = 'rem_bg_auto_1';

      await db.into(db.tasks).insert(
            TasksCompanion.insert(
              id: taskId,
              title: 'Study Physics',
              dueAt: Value(now.add(const Duration(hours: 1))),
              createdAt: now,
              updatedAt: now,
            ),
          );

      await db.into(db.reminders).insert(
            RemindersCompanion.insert(
              id: reminderId,
              taskId: taskId,
              scheduledAt: now.add(const Duration(hours: 1)),
              notificationId: 1003,
              status: const Value('scheduled'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      final payload = jsonEncode({
        'taskId': taskId,
      });

      final response = NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotificationAction,
        actionId: NotificationService.actionDone,
        payload: payload,
      );

      await NotificationService.handleNotificationActionResponse(response);

      final updatedTask = await (db.select(db.tasks)..where((t) => t.id.equals(taskId))).getSingle();
      expect(updatedTask.status, 'completed');
    });

    test('4. Email Intelligence: LeetCode weekly digest / contest is NOT falsely classified as Interview', () {
      final email = GmailMessageData(
        id: 'email_leetcode_digest_1',
        threadId: 't1',
        sender: 'LeetCode <no-reply@leetcode.com>',
        senderEmail: 'no-reply@leetcode.com',
        senderName: 'LeetCode',
        subject: 'Weekly Contest 410 & Top Interview Prep Problems',
        snippet: 'Check out the problem of the day and practice mock interview questions. Unsubscribe here.',
        bodyText: 'Here is your weekly digest of top interview preparation problems and weekly contest. Unsubscribe anytime.',
        date: DateTime(2026, 8, 16, 10, 0),
        attachments: [],
      );

      final analyzer = const AstraEmailAnalyzer();
      final analysis = analyzer.analyze(email, referenceTime: DateTime(2026, 8, 16, 10, 0));

      expect(analysis.category, EmailCategory.lowPriority);
      expect(analysis.isEvent, isFalse);
    });

    test('5. Email Intelligence: Explicit Technical Interview invitation is classified as Interview with evidence', () {
      final email = GmailMessageData(
        id: 'email_real_interview_1',
        threadId: 't2',
        sender: 'Recruiting Team <recruiting@amazon.com>',
        senderEmail: 'recruiting@amazon.com',
        senderName: 'Amazon Careers',
        subject: 'Amazon Technical Interview Invitation - Manoj Sai',
        snippet: 'Your technical round is scheduled for Monday, Aug 24 at 10:00 AM.',
        bodyText: 'Congratulations! Your technical round is scheduled for Monday, Aug 24, 2026 at 10:00 AM. Please confirm your availability.',
        date: DateTime(2026, 8, 16, 10, 0),
        attachments: [],
      );

      final analyzer = const AstraEmailAnalyzer();
      final analysis = analyzer.analyze(email, referenceTime: DateTime(2026, 8, 16, 10, 0));

      expect(analysis.category, EmailCategory.important);
      expect(analysis.isEvent, isTrue);
      expect(analysis.reasons.any((r) => r.contains('Evidence:') || r.contains('Interview')), isTrue);
    });

    test('6. Duration Task Model: isDuration returns true for multi-day date ranges', () {
      final start = DateTime(2026, 8, 17, 9, 0);
      final end = DateTime(2026, 8, 22, 17, 0);

      final task = Task(
        id: 'task_duration_1',
        title: 'SBT Aptitude Training',
        startAt: start,
        endAt: end,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(task.isDuration, isTrue);
      expect(task.durationFormatted, '17 Aug – 22 Aug · 6 Days');
    });
  });
}
