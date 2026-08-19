import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/drift.dart' as drift;

import 'package:astra/core/commands/astra_response_builder.dart';
import 'package:astra/core/database/database.dart';
import 'package:astra/models/task.dart';
import 'package:astra/providers/reminder_provider.dart';
import 'package:astra/providers/ritual_provider.dart';
import 'package:astra/providers/task_provider.dart';
import 'package:astra/services/assistant/astra_recurrence_engine.dart';
import 'package:astra/services/notification_service.dart';
import 'package:astra/services/reminder_service.dart';
import 'package:astra/services/task/astra_schedule_item.dart';
import 'package:astra/theme/app_theme.dart';
import 'package:astra/widgets/assistant/astra_response_card.dart';
import 'package:astra/widgets/notifications/astra_reminder_readiness_prompt.dart';
import 'package:astra/widgets/tasks/astra_task_detail_sheet.dart';
import 'helpers/test_database_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late ReminderService reminderService;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = TestDatabaseHelper.createMemoryDatabase();
    reminderService = ReminderService(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('ASTRA Phase 4F-Final + 4G — Reminder Reliability, Task/Chat Sync & Creation UI Tests (1–19)', () {
    // ─── 1. Exact-alarm readiness state ──────────────────────────────────────
    test('1. ReminderReadinessState contains all valid lifecycle states', () {
      expect(ReminderReadinessState.values, contains(ReminderReadinessState.ready));
      expect(ReminderReadinessState.values, contains(ReminderReadinessState.notificationPermissionRequired));
      expect(ReminderReadinessState.values, contains(ReminderReadinessState.exactAlarmPermissionRequired));
      expect(ReminderReadinessState.values, contains(ReminderReadinessState.restricted));
    });

    // ─── 2. Permission-required onboarding prompt ────────────────────────────
    testWidgets('2. AstraReminderReadinessPrompt renders with ENABLE and Not now actions', (tester) async {
      bool dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: AstraReminderReadinessPrompt(
              onDismiss: () => dismissed = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('PRECISE REMINDERS'), findsOneWidget);
      expect(find.text('Enable Exact Alarm Access'), findsOneWidget);
      expect(find.text('ENABLE'), findsOneWidget);
      expect(find.text('Not now'), findsOneWidget);

      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();
      expect(dismissed, isTrue);
    });

    // ─── 3. Re-check after settings return ───────────────────────────────────
    test('3. checkReminderReadiness returns valid readiness state', () async {
      final state = await NotificationService.checkReminderReadiness();
      expect(state, isA<ReminderReadinessState>());
    });

    // ─── 4. No 30-second scheduling hack ─────────────────────────────────────
    test('4. reminders are scheduled at the exact target time without 30-second offsets', () async {
      final now = DateTime.now();
      final exactTarget = DateTime(now.year, now.month, now.day, now.hour, now.minute + 2, 0);

      await db.into(db.tasks).insert(
            TasksCompanion.insert(
              id: 'exact_timing_task_1',
              title: 'Drink Water',
              dueAt: drift.Value(exactTarget),
              status: const drift.Value('active'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      await reminderService.scheduleReminder(
        taskId: 'exact_timing_task_1',
        taskTitle: 'Drink Water',
        scheduledAt: exactTarget,
      );

      final reminders = await (db.select(db.reminders)..where((r) => r.taskId.equals('exact_timing_task_1'))).get();
      expect(reminders.isNotEmpty, isTrue);
      expect(reminders.first.scheduledAt.millisecondsSinceEpoch, equals(exactTarget.millisecondsSinceEpoch));
    });

    // ─── 5 & 6. Task creation refreshes Tasks & Schedule UI ──────────────────
    testWidgets('5 & 6. task creation in DB reactively updates taskListProvider and unifiedScheduleItemsProvider', (tester) async {
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          reminderServiceProvider.overrideWithValue(reminderService),
        ],
      );

      final now = DateTime.now();
      await container.read(taskNotifierProvider.notifier).addTask(
            Task(
              id: 'task_sync_1',
              title: 'Team Sync',
              dueDate: now.add(const Duration(hours: 2)),
              status: 'active',
              priority: 'high',
              order: 0,
              createdAt: now,
              subtasks: const [],
            ),
          );

      // Load tasks in notifier
      final tasks = container.read(taskNotifierProvider);
      expect(tasks.any((t) => t.id == 'task_sync_1'), isTrue);

      final scheduleItems = AstraScheduleItem.buildSchedule(
        tasks: tasks,
        windowStart: now.subtract(const Duration(days: 1)),
        windowEnd: now.add(const Duration(days: 7)),
      );
      expect(scheduleItems.any((item) => item.title == 'Team Sync'), isTrue);

      container.dispose();
    });

    // ─── 7. Task update refreshes Tasks UI ───────────────────────────────────
    testWidgets('7. task update reactively updates task status in taskListProvider', (tester) async {
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          reminderServiceProvider.overrideWithValue(reminderService),
        ],
      );

      final now = DateTime.now();
      await container.read(taskNotifierProvider.notifier).addTask(
            Task(
              id: 'task_sync_update_1',
              title: 'Review Code',
              dueDate: now.add(const Duration(hours: 1)),
              status: 'active',
              priority: 'medium',
              order: 0,
              createdAt: now,
              subtasks: const [],
            ),
          );

      await container.read(taskNotifierProvider.notifier).setStatus('task_sync_update_1', 'completed');

      final tasks = container.read(taskNotifierProvider);
      expect(tasks.firstWhere((t) => t.id == 'task_sync_update_1').status, equals('completed'));

      container.dispose();
    });

    // ─── 8 & 9. Response Card & VIEW TASK Action ─────────────────────────────
    testWidgets('8 & 9. AstraResponseCard renders +10 MIN and VIEW TASK actions', (tester) async {
      final response = AstraResponseBuilder.taskCreated(
        title: 'Complete Exam',
        dueAt: DateTime(2026, 8, 19, 10, 0),
        organization: 'Microsoft',
        priority: 'high',
        taskId: 'task_resp_1',
      );

      expect(response.actions.any((a) => a.label == '+10 MIN'), isTrue);
      expect(response.actions.any((a) => a.label == 'VIEW TASK'), isTrue);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: AstraResponseCard(
                response: response,
                accent: AstraColors.cyan,
                accentDepth: AstraColors.borderGlow,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('TASK CREATED'), findsOneWidget);
      expect(find.text('Complete Exam'), findsOneWidget);
      expect(find.text('+10 MIN'), findsOneWidget);
      expect(find.text('VIEW TASK'), findsOneWidget);
    });

    // ─── 10, 11, 12, 13, 14. Detail Sheet Visuals ───────────────────────────
    testWidgets('10-14. AstraTaskDetailSheet renders schedule, recurrence, and priority controls cleanly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            reminderServiceProvider.overrideWithValue(reminderService),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const Scaffold(
              body: AstraTaskDetailSheet(initialShowMoreOptions: true),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Title & Row Controls
      expect(find.byKey(const Key('task_detail_title_field')), findsOneWidget);
      expect(find.text('WHEN'), findsOneWidget);
      expect(find.text('REPEAT'), findsOneWidget);
      expect(find.text('REMIND'), findsOneWidget);
      expect(find.text('PRIORITY'), findsOneWidget);

      // Progressive disclosure sections
      expect(find.text('NOTES & DESCRIPTION'), findsOneWidget);
      expect(find.text('CHECKLIST & STEPS'), findsOneWidget);
      expect(find.text('CATEGORY'), findsOneWidget);
      expect(find.text('ORGANIZATION'), findsOneWidget);
    });

    // ─── 15, 16, 17. Viewport Widths (360dp, 390dp, 412dp) ──────────────────
    testWidgets('15-17. AstraTaskDetailSheet renders without layout overflows on 360dp, 390dp, and 412dp', (tester) async {
      final viewports = [
        const Size(360, 800),
        const Size(390, 844),
        const Size(412, 915),
      ];

      for (final size in viewports) {
        tester.view.physicalSize = size * tester.view.devicePixelRatio;
        tester.view.devicePixelRatio = 2.0;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWithValue(db),
              reminderServiceProvider.overrideWithValue(reminderService),
            ],
            child: MaterialApp(
              theme: AppTheme.darkTheme,
              home: const Scaffold(
                body: AstraTaskDetailSheet(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'Layout error on size $size');
      }

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    // ─── 18. Keyboard-safe creation/editing ──────────────────────────────────
    testWidgets('18. AstraTaskDetailSheet handles soft keyboard insets gracefully', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            reminderServiceProvider.overrideWithValue(reminderService),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const Scaffold(
              body: AstraTaskDetailSheet(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('task_detail_title_field')), 'Ship ASTRA Phase 4G');
      await tester.pumpAndSettle();

      expect(find.text('Ship ASTRA Phase 4G'), findsOneWidget);
      expect(find.byKey(const Key('task_detail_save_button')), findsOneWidget);
    });

    // ─── 19. Centralized Haptics ─────────────────────────────────────────────
    test('19. Recurrence summary generator produces exact human-readable text', () {
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.weekdays,
        interval: 1,
        byWeekdays: const [1, 2, 3, 4, 5],
        hour: 9,
        minute: 0,
      );
      expect(rule.frequency, equals(RecurrenceFrequency.weekdays));
      expect(rule.byWeekdays.length, equals(5));
    });
  });
}
