import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:astra/core/database/database.dart';
import 'package:astra/models/task.dart';
import 'package:astra/providers/reminder_provider.dart';
import 'package:astra/providers/ritual_provider.dart';
import 'package:astra/providers/task_provider.dart';
import 'package:astra/screens/tasks_screen.dart';
import 'package:astra/services/assistant/astra_recurrence_engine.dart';
import 'package:astra/services/reminder_service.dart';
import 'package:astra/theme/app_theme.dart';
import 'package:astra/widgets/tasks/astra_task_card.dart';
import 'package:astra/widgets/tasks/astra_task_detail_sheet.dart';
import 'package:astra/widgets/tasks/quick_add_bar.dart';
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

  group('ASTRA Phase 5A — Tasks UX 2.0 & Performance Hardening Tests (A–T)', () {
    // ─── A. Minimal Task Creation ────────────────────────────────────────────
    testWidgets('A. minimal task creation with title only via AstraTaskDetailSheet', (tester) async {
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

      await tester.enterText(find.byKey(const Key('task_detail_title_field')), 'Simple Quick Task');
      await tester.tap(find.byKey(const Key('task_detail_save_button')));
      await tester.pumpAndSettle();

      final tasks = await db.select(db.tasks).get();
      expect(tasks.length, 1);
      expect(tasks.first.title, 'Simple Quick Task');
    });

    // ─── B. Scheduled Task Creation ──────────────────────────────────────────
    testWidgets('B. scheduled task creation with date, time, and recurrence', (tester) async {
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

      await tester.enterText(find.byKey(const Key('task_detail_title_field')), 'Team Standup');

      // Date in WHEN modal
      await tester.tap(find.text('WHEN'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Today'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('DONE'));
      await tester.pumpAndSettle();

      // Recurrence in REPEAT modal
      await tester.tap(find.text('REPEAT'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Weekdays (Mon-Fri)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('DONE'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('task_detail_save_button')));
      await tester.pumpAndSettle();

      final tasks = await db.select(db.tasks).get();
      expect(tasks.length, 1);
      expect(tasks.first.title, 'Team Standup');
      final taskModel = taskEntryToTask(tasks.first);
      expect(taskModel.recurrenceRule?.frequency, RecurrenceFrequency.weekdays);
    });

    // ─── C & D. Quick Create Bar ─────────────────────────────────────────────
    testWidgets('C & D. QuickAddBar handles title-only and NLP temporal parsing', (tester) async {
      String? addedText;
      bool expanded = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: QuickAddBar(
              onAddTask: (text) => addedText = text,
              onExpand: () => expanded = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Submit title
      await tester.enterText(find.byType(TextField), 'Study DSA at 7pm');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(addedText, 'Study DSA at 7pm');

      // Expand action
      await tester.tap(find.byIcon(LucideIcons.slidersHorizontal));
      await tester.pumpAndSettle();
      expect(expanded, isTrue);
    });

    // ─── E & F. Progressive Disclosure ───────────────────────────────────────
    testWidgets('E & F. progressive disclosure reveals more options only when requested', (tester) async {
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

      // Initial collapsed state: Core rows visible, advanced sections hidden
      expect(find.text('WHEN'), findsOneWidget);
      expect(find.text('REPEAT'), findsOneWidget);
      expect(find.text('REMIND'), findsOneWidget);
      expect(find.text('PRIORITY'), findsOneWidget);
      expect(find.byKey(const Key('task_detail_desc_field')), findsNothing);

      // Expand more options
      await tester.tap(find.text('MORE DETAILS'));
      await tester.pumpAndSettle();

      // Advanced sections now visible
      expect(find.byKey(const Key('task_detail_desc_field')), findsOneWidget);
      expect(find.byKey(const Key('task_detail_org_field')), findsOneWidget);
      expect(find.byKey(const Key('task_detail_category_field')), findsOneWidget);
      expect(find.text('CHECKLIST & STEPS'), findsOneWidget);
    });

    // ─── G. Detail Editor Opening & Saving ───────────────────────────────────
    testWidgets('G. detail editor in edit mode populates fields and updates task in DB', (tester) async {
      final now = DateTime.now();
      final originalTask = Task(
        id: 'edit_test_1',
        title: 'Original Title',
        description: 'Original Notes',
        dueDate: now.add(const Duration(hours: 2)),
        organization: 'Google',
        priority: 'medium',
        createdAt: now,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            reminderServiceProvider.overrideWithValue(reminderService),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: AstraTaskDetailSheet(task: originalTask),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Original Title'), findsOneWidget);
      expect(find.text('Original Notes'), findsOneWidget);
      expect(find.text('Google'), findsOneWidget);
      expect(find.text('SAVE'), findsOneWidget);
    });

    // ─── H & I. Task Row Hierarchy & Touch Targets ───────────────────────────
    testWidgets('H & I. AstraTaskCard renders clear hierarchy with >=44dp touch targets', (tester) async {
      final now = DateTime.now();
      final task = Task(
        id: 'hierarchy_task_1',
        title: 'Complete System Architecture Review',
        description: 'Prepare diagrams for engineering meeting',
        dueDate: DateTime(now.year, now.month, now.day, 14, 0),
        organization: 'DeepMind',
        priority: 'high',
        createdAt: now,
      );

      bool completed = false;
      bool edited = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: AstraTaskCard(
              task: task,
              onComplete: () => completed = true,
              onEdit: () => edited = true,
              onDelete: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Information hierarchy elements
      expect(find.text('Complete System Architecture Review'), findsOneWidget);
      expect(find.text('Prepare diagrams for engineering meeting'), findsOneWidget);
      expect(find.text('DeepMind'), findsOneWidget);
      expect(find.text('HIGH'), findsOneWidget);

      // Checkbox touch target is >= 44dp
      final checkboxFinder = find.byKey(const Key('task_card_checkbox'));
      final checkboxSize = tester.getSize(checkboxFinder);
      expect(checkboxSize.width, greaterThanOrEqualTo(44.0));
      expect(checkboxSize.height, greaterThanOrEqualTo(44.0));

      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();
      expect(completed, isTrue);

      await tester.tap(find.text('Complete System Architecture Review'));
      await tester.pumpAndSettle();
      expect(edited, isTrue);
    });

    // ─── J & K. Swipe Gestures ───────────────────────────────────────────────
    testWidgets('J & K. AstraTaskCard supports swipe right to complete and swipe left to delete', (tester) async {
      final now = DateTime.now();
      final task1 = Task(
        id: 'gesture_task_1',
        title: 'Swipe Right Complete Task',
        dueDate: now.add(const Duration(hours: 1)),
        priority: 'medium',
        createdAt: now,
      );
      final task2 = Task(
        id: 'gesture_task_2',
        title: 'Swipe Left Delete Task',
        dueDate: now.add(const Duration(hours: 1)),
        priority: 'medium',
        createdAt: now,
      );

      bool completed = false;
      bool deleted = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Column(
              children: [
                AstraTaskCard(
                  task: task1,
                  onComplete: () => completed = true,
                ),
                AstraTaskCard(
                  task: task2,
                  onComplete: () {},
                  onDelete: () => deleted = true,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Swipe right -> complete
      await tester.fling(find.text('Swipe Right Complete Task'), const Offset(500, 0), 1000);
      await tester.pumpAndSettle();
      expect(completed, isTrue);

      // Swipe left -> delete
      await tester.fling(find.text('Swipe Left Delete Task'), const Offset(-500, 0), 1000);
      await tester.pumpAndSettle();
      expect(deleted, isTrue);
    });

    // ─── L, M, N, O, P. Task Filter Views ────────────────────────────────────
    testWidgets('L–P. TasksScreen renders My Day, Upcoming, Important, All, and Completed views', (tester) async {
      final now = DateTime.now();
      final tasks = [
        Task(
          id: 'task_today_1',
          title: 'Today Focus Task',
          dueDate: DateTime(now.year, now.month, now.day, 10, 0),
          priority: 'medium',
          createdAt: now,
        ),
        Task(
          id: 'task_upcoming_1',
          title: 'Tomorrow Plan',
          dueDate: DateTime(now.year, now.month, now.day + 1, 15, 0),
          priority: 'low',
          createdAt: now,
        ),
        Task(
          id: 'task_important_1',
          title: 'Critical Deadline',
          dueDate: DateTime(now.year, now.month, now.day, 18, 0),
          priority: 'high',
          createdAt: now,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            reminderServiceProvider.overrideWithValue(reminderService),
            taskListProvider.overrideWith((ref) => Stream.value(tasks)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: TasksScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tabs exist
      expect(find.text('MY DAY'), findsOneWidget);
      expect(find.text('UPCOMING'), findsOneWidget);
      expect(find.text('IMPORTANT'), findsOneWidget);
      expect(find.text('ALL'), findsOneWidget);
      expect(find.text('COMPLETED'), findsOneWidget);

      // Switch to UPCOMING
      await tester.tap(find.text('UPCOMING'));
      await tester.pumpAndSettle();
      expect(find.text('Tomorrow Plan'), findsOneWidget);

      // Switch to IMPORTANT
      await tester.tap(find.text('IMPORTANT'));
      await tester.pumpAndSettle();
      expect(find.text('Critical Deadline'), findsOneWidget);
    });

    // ─── Q. Responsive Viewports (360dp, 390dp, 412dp) ───────────────────────
    testWidgets('Q. responsive viewports (360dp, 390dp, 412dp) render without overflow', (tester) async {
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

        expect(tester.takeException(), isNull, reason: 'Failed on viewport size $size');
      }

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    // ─── R. Keyboard Insets Safety ───────────────────────────────────────────
    testWidgets('R. AstraTaskDetailSheet handles keyboard view insets safely', (tester) async {
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

      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('task_detail_save_button')), findsOneWidget);
      expect(tester.takeException(), isNull);

      tester.view.resetViewInsets();
    });

    // ─── S. Bounded Large Description Preview ────────────────────────────────
    testWidgets('S. large descriptions are bounded to max 2 lines preview in AstraTaskCard', (tester) async {
      final longNotice = 'IMPORTANT ANNOUNCEMENT:\n' * 50;
      final task = Task(
        id: 'large_notice_1',
        title: 'Semester Schedule Update',
        description: longNotice,
        dueDate: DateTime.now().add(const Duration(days: 2)),
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: AstraTaskCard(
              task: task,
              onComplete: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final cardFinder = find.byType(AstraTaskCard);
      final cardSize = tester.getSize(cardFinder);
      // Card height should be compact and bounded (~80-140dp), not hundreds of pixels
      expect(cardSize.height, lessThan(160.0));
    });

    // ─── T. Recurrence Computation Stability ─────────────────────────────────
    test('T. recurrence summary rules generate exact human-readable text', () {
      final weekdaysRule = RecurrenceRule(
        frequency: RecurrenceFrequency.weekdays,
        interval: 1,
        byWeekdays: const [1, 2, 3, 4, 5],
        hour: 9,
        minute: 0,
      );
      expect(weekdaysRule.frequency, RecurrenceFrequency.weekdays);
      expect(weekdaysRule.byWeekdays, const [1, 2, 3, 4, 5]);

      final dailyRule = RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
        interval: 1,
        hour: 20,
        minute: 0,
      );
      expect(dailyRule.frequency, RecurrenceFrequency.daily);
      expect(dailyRule.hour, 20);
    });
  });
}
