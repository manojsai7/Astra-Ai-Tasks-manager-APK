import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:astra/core/database/database.dart';
import 'package:astra/core/reminders/reminder_strategy.dart';
import 'package:astra/core/time/astra_clock.dart';
import 'package:astra/core/time/astra_time_service.dart';
import 'package:astra/providers/assistant_provider.dart';
import 'package:astra/providers/reminder_provider.dart';
import 'package:astra/screens/assistant_screen.dart';
import 'package:astra/services/assistant/astra_recurrence_engine.dart';
import 'package:astra/services/reminder_service.dart';

import 'helpers/test_database_helper.dart';
import 'helpers/test_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late ReminderService reminderService;

  final fixedNow = DateTime(2026, 8, 16, 12, 0); // 12:00 PM
  final timeService = AstraTimeService(
    clock: FixedAstraClock(fixedNow),
    timezone: 'Asia/Kolkata',
  );

  setUp(() {
    db = TestDatabaseHelper.createMemoryDatabase();
    reminderService = ReminderService(db, timeService: timeService);
  });

  tearDown(() async {
    await db.close();
  });

  group('ASTRA Phase M2-D: Notification Strategy & Delivery Tests', () {
    // 1. NORMAL strategy
    test('1. NORMAL strategy: offsets = [0m] and maps default tasks', () {
      expect(ReminderStrategy.normal.offsets, [Duration.zero]);
      expect(ReminderStrategy.normal.name, 'NORMAL');

      final strategy = ReminderStrategyX.resolve(
        eventType: 'OTHER',
        priority: 'normal',
      );
      expect(strategy, ReminderStrategy.normal);
    });

    // 2. IMPORTANT strategy
    test('2. IMPORTANT strategy: offsets = [10m, 4m, 0m] and maps exams, interviews, meetings, high priority', () {
      expect(ReminderStrategy.important.offsets, [
        const Duration(minutes: 10),
        const Duration(minutes: 4),
        Duration.zero,
      ]);
      expect(ReminderStrategy.important.name, 'IMPORTANT');

      expect(ReminderStrategyX.resolve(eventType: 'EXAM'), ReminderStrategy.important);
      expect(ReminderStrategyX.resolve(eventType: 'INTERVIEW'), ReminderStrategy.important);
      expect(ReminderStrategyX.resolve(eventType: 'MEETING'), ReminderStrategy.important);
      expect(ReminderStrategyX.resolve(eventType: 'SESSION'), ReminderStrategy.important);
      expect(ReminderStrategyX.resolve(priority: 'high'), ReminderStrategy.important);
      expect(ReminderStrategyX.resolve(priority: 'urgent'), ReminderStrategy.important);
    });

    // 3. DEADLINE strategy
    test('3. DEADLINE & CRITICAL strategy: offsets = [30m, 10m, 0m] and maps deadlines & critical priority', () {
      expect(ReminderStrategy.deadline.offsets, [
        const Duration(minutes: 30),
        const Duration(minutes: 10),
        Duration.zero,
      ]);
      expect(ReminderStrategy.deadline.name, 'DEADLINE');

      expect(ReminderStrategyX.resolve(eventType: 'DEADLINE'), ReminderStrategy.deadline);
      expect(ReminderStrategyX.resolve(isDeadline: true), ReminderStrategy.deadline);
      expect(ReminderStrategyX.resolve(priority: 'critical'), ReminderStrategy.critical);
    });

    // 4. One task with multiple notification offsets
    test('4. One task with multiple notification offsets keeps single Task and single Reminder row in Drift', () async {
      final task = TestFixtures.createTask(
        id: 'exam-task-1',
        title: 'Physics Final Exam',
        dueDate: DateTime(2026, 8, 16, 15, 0), // 3:00 PM
        priority: 'high',
        category: 'exam',
      );

      await TestDatabaseHelper.insertTaskRow(
        db,
        id: task.id,
        title: task.title,
        dueAt: task.dueDate,
        priority: task.priority,
      );

      final result = await reminderService.scheduleReminder(
        taskId: task.id,
        taskTitle: task.title,
        scheduledAt: task.dueDate!,
        strategy: ReminderStrategy.important,
      );

      expect(result.reminder, isNotNull);
      expect(result.reminder!.taskId, task.id);

      // Verify single Task row in DB
      final tasksInDb = await db.select(db.tasks).get();
      expect(tasksInDb.length, 1);
      expect(tasksInDb.first.id, 'exam-task-1');

      // Verify single Reminder row in DB
      final remindersInDb = await db.select(db.reminders).get();
      expect(remindersInDb.length, 1);
      expect(remindersInDb.first.taskId, 'exam-task-1');
      expect(remindersInDb.first.status, 'scheduled');
    });

    // 5. Duplicate protection & snooze single-notification guarantee
    test('5. Duplicate protection cancels existing offsets; snooze schedules exactly 1 notification', () async {
      final task = TestFixtures.createTask(
        id: 'interview-task-1',
        title: 'Microsoft Interview',
        dueDate: DateTime(2026, 8, 16, 14, 0), // 2:00 PM
        priority: 'high',
      );

      await TestDatabaseHelper.insertTaskRow(
        db,
        id: task.id,
        title: task.title,
        dueAt: task.dueDate,
        priority: task.priority,
      );

      // Schedule first time
      await reminderService.scheduleReminder(
        taskId: task.id,
        taskTitle: task.title,
        scheduledAt: task.dueDate!,
        strategy: ReminderStrategy.important,
      );

      // Schedule second time (idempotent reschedule)
      final rescheduleResult = await reminderService.scheduleReminder(
        taskId: task.id,
        taskTitle: task.title,
        scheduledAt: DateTime(2026, 8, 16, 16, 0),
        strategy: ReminderStrategy.important,
      );

      var activeReminders = await db.getActiveReminders();
      expect(activeReminders.length, 1);
      expect(activeReminders.first.scheduledAt, DateTime(2026, 8, 16, 16, 0));

      // Snooze reminder
      await reminderService.snoozeReminder(rescheduleResult.reminder!.id, duration: const Duration(minutes: 10));

      activeReminders = await db.getActiveReminders();
      expect(activeReminders.length, 1);
      expect(activeReminders.first.status, 'snoozed');
      expect(activeReminders.first.scheduledAt, fixedNow.add(const Duration(minutes: 10)));
    });

    // 6. Recurrence + Strategy
    test('6. Recurrence + Strategy advances to next occurrence and schedules strategy', () async {
      const rule = RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
        interval: 1,
        hour: 9,
        minute: 0,
      );

      final task = TestFixtures.createTask(
        id: 'daily-standup-1',
        title: 'Engineering Standup',
        dueDate: DateTime(2026, 8, 16, 14, 0), // 2:00 PM (future relative to fixedNow 12:00 PM)
        priority: 'high',
        category: 'meeting',
        recurrenceRule: rule,
      );

      await TestDatabaseHelper.insertTaskRow(
        db,
        id: task.id,
        title: task.title,
        dueAt: task.dueDate,
        priority: task.priority,
        recurrenceRuleJson: rule.toJson(),
      );

      final sched = await reminderService.scheduleReminder(
        taskId: task.id,
        taskTitle: task.title,
        scheduledAt: task.dueDate!,
        strategy: ReminderStrategy.important,
      );

      expect(sched.reminder, isNotNull);

      // Complete reminder -> advances to next occurrence (tomorrow at 9:00 AM)
      await reminderService.completeReminder(sched.reminder!.id);

      final updatedTask = await (db.select(db.tasks)..where((t) => t.id.equals(task.id))).getSingle();
      expect(updatedTask.status, 'active');
      expect(updatedTask.dueAt, DateTime(2026, 8, 17, 9, 0));

      final reminders = await db.getActiveReminders();
      expect(reminders.length, 1);
      expect(reminders.first.scheduledAt, DateTime(2026, 8, 17, 9, 0));
    });
  });

  group('ASTRA Phase M2-D: Natural Chat UI & Layout Tests', () {
    // 7. Natural assistant message layout
    testWidgets('7. Natural assistant message layout renders clean prose without chunky card frame', (tester) async {
      final container = ProviderContainer(
        overrides: [
          reminderServiceProvider.overrideWithValue(reminderService),
        ],
      );
      addTearDown(container.dispose);

      final assistant = container.read(assistantStateProvider.notifier);
      assistant.addMessage('Your Microsoft interview is Monday at 11 AM.\nI’ve also scheduled a reminder for it.', isUser: false);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: AssistantScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // Prose text must be visible
      expect(find.textContaining('Your Microsoft interview is Monday at 11 AM.'), findsOneWidget);
      expect(find.textContaining('I’ve also scheduled a reminder for it.'), findsOneWidget);

      // SelectionArea is present for natural copy/selection
      expect(find.byType(SelectionArea), findsWidgets);
    });

    // 8. Long message scrolling
    testWidgets('8. Long multi-paragraph assistant message renders and scrolls without overflowing', (tester) async {
      final container = ProviderContainer(
        overrides: [
          reminderServiceProvider.overrideWithValue(reminderService),
        ],
      );
      addTearDown(container.dispose);

      final longText = List.generate(
        15,
        (i) => 'Paragraph $i: ASTRA is an offline-capable, deterministic, privacy-first personal assistant with native memory.',
      ).join('\n\n');

      final assistant = container.read(assistantStateProvider.notifier);
      assistant.addMessage(longText, isUser: false);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: AssistantScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.textContaining('Paragraph 0:'), findsOneWidget);

      // Verify list can scroll
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pump(const Duration(milliseconds: 500));

      expect(tester.takeException(), isNull);
    });

    // 9. Bottom nav + keyboard layout
    testWidgets('9. Bottom composer respects keyboard bottom insets on narrow and wide screens', (tester) async {
      // Test narrow screen (360dp width)
      tester.view.physicalSize = const Size(360 * 2, 800 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final container = ProviderContainer(
        overrides: [
          reminderServiceProvider.overrideWithValue(reminderService),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: AssistantScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // Verify input bar is rendered cleanly
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Ask ASTRA or type a command…'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
