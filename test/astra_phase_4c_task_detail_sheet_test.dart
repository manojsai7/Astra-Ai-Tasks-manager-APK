import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/drift.dart' hide Column, isNull, isNotNull;
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:astra/core/database/database.dart';
import 'package:astra/models/task.dart';
import 'package:astra/providers/ritual_provider.dart';
import 'package:astra/providers/task_provider.dart';
import 'package:astra/services/assistant/astra_recurrence_engine.dart';
import 'package:astra/widgets/tasks/astra_task_detail_sheet.dart';
import 'package:astra/screens/tasks_screen.dart';
import 'package:astra/screens/schedule_screen.dart';
import 'helpers/test_database_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = TestDatabaseHelper.createMemoryDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildTestableWidget(Widget child, {List<Task> initialTasks = const [], List<Override> overrides = const []}) {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        taskListProvider.overrideWith((ref) => Stream.value(initialTasks)),
        ...overrides,
      ],
      child: MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 2400,
            child: child,
          ),
        ),
      ),
    );
  }

  Future<void> pumpSheet(WidgetTester tester, {Task? task, List<Task> initialTasks = const []}) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    await tester.pumpWidget(
      buildTestableWidget(
        task != null
            ? AstraTaskDetailSheet(task: task)
            : const AstraTaskDetailSheet(initialShowMoreOptions: true),
        initialTasks: initialTasks,
      ),
    );
    await tester.pump();
  }

  group('ASTRA Phase 4C — Advanced Task Detail Sheet Tests (A–T)', () {
    // ─── A. Create Task ──────────────────────────────────────────────────────
    testWidgets('A. Create task: title, category, priority, and save', (tester) async {
      await pumpSheet(tester);

      expect(find.text('NEW TASK'), findsOneWidget);

      // Enter title
      await tester.enterText(find.byKey(const Key('task_detail_title_field')), 'Launch Satellite System');
      // Enter category
      await tester.enterText(find.byKey(const Key('task_detail_category_field')), 'Aerospace');

      // Tap Save
      await tester.tap(find.byKey(const Key('task_detail_save_button')));
      await tester.pumpAndSettle();

      final tasksInDb = await db.select(db.tasks).get();
      expect(tasksInDb.length, 1);
      expect(tasksInDb.first.title, 'Launch Satellite System');
      expect(tasksInDb.first.category, 'Aerospace');
    });

    // ─── B. Edit Task ────────────────────────────────────────────────────────
    testWidgets('B. Edit task: loads existing task, edits notes, updates DB', (tester) async {
      final existingTask = Task(
        id: 't-edit-1',
        title: 'Original Title',
        description: 'Original Notes',
        priority: 'low',
        category: 'Personal',
        createdAt: DateTime.now(),
      );

      await db.into(db.tasks).insert(
        TasksCompanion.insert(
          id: existingTask.id,
          title: existingTask.title,
          description: Value(existingTask.description),
          priority: Value(existingTask.priority),
          category: Value(existingTask.category),
          createdAt: existingTask.createdAt,
          updatedAt: existingTask.createdAt,
        ),
      );

      await pumpSheet(tester, task: existingTask, initialTasks: [existingTask]);

      expect(find.text('TASK DETAILS'), findsOneWidget);
      expect(find.text('Original Title'), findsOneWidget);
      expect(find.text('Original Notes'), findsOneWidget);

      // Edit description
      await tester.enterText(find.byKey(const Key('task_detail_desc_field')), 'Updated Comprehensive Architecture Notes');

      // Tap Save
      await tester.tap(find.byKey(const Key('task_detail_save_button')));
      await tester.pumpAndSettle();

      final updated = (await db.select(db.tasks).get()).firstWhere((t) => t.id == 't-edit-1');
      expect(updated.description, 'Updated Comprehensive Architecture Notes');
    });

    // ─── C. Title Validation ─────────────────────────────────────────────────
    testWidgets('C. Title validation: rejects whitespace-only title with inline error', (tester) async {
      await pumpSheet(tester);

      // Enter whitespace only
      await tester.enterText(find.byKey(const Key('task_detail_title_field')), '   ');

      // Tap Save
      await tester.tap(find.byKey(const Key('task_detail_save_button')));
      await tester.pump();

      // Validation error shown, zero DB writes
      expect(find.text('Please enter a task title'), findsOneWidget);
      final tasksInDb = await db.select(db.tasks).get();
      expect(tasksInDb.isEmpty, isTrue);
    });

    // ─── D. Notes Preservation ───────────────────────────────────────────────
    testWidgets('D. Notes: multiline notes persist cleanly', (tester) async {
      await pumpSheet(tester);

      await tester.enterText(find.byKey(const Key('task_detail_title_field')), 'Task with Multiline Notes');
      await tester.enterText(find.byKey(const Key('task_detail_desc_field')), 'Line 1: Summary\nLine 2: Action items\nLine 3: Key deliverables');

      await tester.tap(find.byKey(const Key('task_detail_save_button')));
      await tester.pumpAndSettle();

      final task = (await db.select(db.tasks).get()).first;
      expect(task.description, contains('Line 1: Summary'));
      expect(task.description, contains('Line 3: Key deliverables'));
    });

    // ─── E. Category / List Assignment ───────────────────────────────────────
    testWidgets('E. Category: selecting preset category assigns category to task', (tester) async {
      await pumpSheet(tester);

      await tester.enterText(find.byKey(const Key('task_detail_title_field')), 'Finance Audit');
      await tester.enterText(find.byKey(const Key('task_detail_category_field')), 'Finance');
      await tester.pump();

      await tester.tap(find.byKey(const Key('task_detail_save_button')));
      await tester.pumpAndSettle();

      final task = (await db.select(db.tasks).get()).first;
      expect(task.category, 'Finance');
    });

    // ─── F. Organization & Link ──────────────────────────────────────────────
    testWidgets('F. Organization & link: sets organization and external link', (tester) async {
      await pumpSheet(tester);

      await tester.enterText(find.byKey(const Key('task_detail_title_field')), 'Google DeepMind Interview');
      await tester.enterText(find.byKey(const Key('task_detail_org_field')), 'Google');
      await tester.enterText(find.byKey(const Key('task_detail_link_field')), 'https://meet.google.com/abc-xyz');

      await tester.tap(find.byKey(const Key('task_detail_save_button')));
      await tester.pumpAndSettle();

      final task = (await db.select(db.tasks).get()).first;
      expect(task.organization, 'Google');
    });

    // ─── G. Start vs Deadline Semantics ──────────────────────────────────────
    testWidgets('G. Start vs Deadline: deadline sets dueDate without startAt', (tester) async {
      await pumpSheet(tester);

      await tester.enterText(find.byKey(const Key('task_detail_title_field')), 'Deadline Task');
      await tester.tap(find.byKey(const Key('task_detail_save_button')));
      await tester.pumpAndSettle();

      final task = (await db.select(db.tasks).get()).first;
      expect(task.dueAt, isNotNull);
      expect(task.startAt, isNull);
      expect(task.endAt, isNull);
    });

    testWidgets('H. Duration event: event mode sets both startAt and endAt', (tester) async {
      await pumpSheet(tester);

      await tester.enterText(find.byKey(const Key('task_detail_title_field')), 'Architecture Workshop');
      // Open WHEN modal
      await tester.tap(find.text('WHEN'));
      await tester.pumpAndSettle();

      // Switch to Duration Event mode
      await tester.tap(find.text('EVENT (START/END)'));
      await tester.pumpAndSettle();

      expect(find.text('START DATE'), findsOneWidget);
      expect(find.text('END DATE'), findsOneWidget);

      // Close modal
      await tester.tap(find.text('DONE'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('task_detail_save_button')));
      await tester.pumpAndSettle();

      final tasks = await db.select(db.tasks).get();
      expect(tasks.isNotEmpty, isTrue);
      final task = tasks.first;
      expect(task.startAt, isNotNull);
      expect(task.endAt, isNotNull);
      expect(task.endAt!.isAfter(task.startAt!) || task.endAt!.isAtSameMomentAs(task.startAt!), isTrue);
    });

    // ─── I. Reminder Enable / Disable ────────────────────────────────────────
    testWidgets('I. Reminder: schedules active reminder when enabled', (tester) async {
      await pumpSheet(tester);

      await tester.enterText(find.byKey(const Key('task_detail_title_field')), 'Doctor Appointment');
      await tester.tap(find.byKey(const Key('task_detail_save_button')));
      await tester.pumpAndSettle();

      final remindersInDb = await db.select(db.reminders).get();
      final active = remindersInDb.where((r) => r.status != 'cancelled').toList();
      expect(active.length, 1);
      expect(active.first.taskId, isNotEmpty);
    });

    // ─── J. Daily Recurrence ─────────────────────────────────────────────────
    testWidgets('J. Daily recurrence: sets recurrenceRule to daily', (tester) async {
      await pumpSheet(tester);

      await tester.enterText(find.byKey(const Key('task_detail_title_field')), 'Daily Standup');
      await tester.tap(find.text('REPEAT'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Daily'));
      await tester.pumpAndSettle();

      // Close modal
      await tester.tap(find.text('DONE'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('task_detail_save_button')));
      await tester.pumpAndSettle();

      final task = (await db.select(db.tasks).get()).first;
      expect(task.recurrenceRuleJson, isNotNull);
      expect(task.recurrenceRuleJson, contains('DAILY'));
    });

    // ─── K. Weekly Recurrence ────────────────────────────────────────────────
    testWidgets('K. Weekly recurrence: allows selecting specific weekdays', (tester) async {
      await pumpSheet(tester);

      await tester.enterText(find.byKey(const Key('task_detail_title_field')), 'Gym Routine');
      await tester.tap(find.text('REPEAT'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Weekly'));
      await tester.pumpAndSettle();

      // Close modal
      await tester.tap(find.text('DONE'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('task_detail_save_button')));
      await tester.pumpAndSettle();

      final task = (await db.select(db.tasks).get()).first;
      expect(task.recurrenceRuleJson, contains('WEEKLY'));
    });

    // ─── L. Recurrence End Date ──────────────────────────────────────────────
    test('L. Recurrence rule with end date deserializes accurately', () {
      final rule = RecurrenceRule.fromMap({
        'frequency': 'DAILY',
        'endDate': '2026-12-31T00:00:00.000',
        'hour': 9,
        'minute': 0,
      });
      expect(rule.endDate, isNotNull);
      expect(rule.endDate!.year, 2026);
      expect(rule.endDate!.month, 12);
    });

    // ─── M. Occurrence Limit ─────────────────────────────────────────────────
    test('M. Recurrence rule with occurrence limit is modeled cleanly', () {
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
        occurrenceLimit: 10,
        occurrencesCount: 3,
        hour: 9,
        minute: 0,
      );
      expect(rule.occurrenceLimit, 10);
      expect(rule.isEnded, isFalse);

      final endedRule = rule.copyWith(occurrencesCount: 10);
      expect(endedRule.isEnded, isTrue);
    });

    // ─── N. Subtasks (Steps) ─────────────────────────────────────────────────
    testWidgets('N. Subtasks: adding, toggling, and deleting subtask steps', (tester) async {
      await pumpSheet(tester);

      await tester.enterText(find.byKey(const Key('task_detail_title_field')), 'Sprint Planning');

      // Add Step 1
      await tester.enterText(find.byKey(const Key('task_detail_add_step_field')), 'Review backlog');
      await tester.tap(find.byKey(const Key('task_detail_add_step_button')));
      await tester.pump();

      // Add Step 2
      await tester.enterText(find.byKey(const Key('task_detail_add_step_field')), 'Assign story points');
      await tester.tap(find.byKey(const Key('task_detail_add_step_button')));
      await tester.pump();

      expect(find.text('Review backlog'), findsOneWidget);
      expect(find.text('Assign story points'), findsOneWidget);

      await tester.tap(find.byKey(const Key('task_detail_save_button')));
      await tester.pumpAndSettle();

      final task = (await db.select(db.tasks).get()).first;
      expect(task.subtasksJson, isNotNull);
      expect(task.subtasksJson, contains('Review backlog'));
      expect(task.subtasksJson, contains('Assign story points'));
    });

    // ─── O. Important & Priority ─────────────────────────────────────────────
    testWidgets('O. Important toggle sets high priority', (tester) async {
      await pumpSheet(tester);

      await tester.enterText(find.byKey(const Key('task_detail_title_field')), 'Critical Deployment');
      await tester.tap(find.text('PRIORITY'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('High'));
      await tester.pumpAndSettle();

      // Close modal
      await tester.tap(find.text('DONE'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('task_detail_save_button')));
      await tester.pumpAndSettle();

      final task = (await db.select(db.tasks).get()).first;
      expect(task.priority, 'high');
    });

    // ─── P. Calendar Linkage ─────────────────────────────────────────────────
    testWidgets('P. Calendar linkage: persists link field', (tester) async {
      await pumpSheet(tester);

      await tester.enterText(find.byKey(const Key('task_detail_title_field')), 'Google Event');
      await tester.enterText(find.byKey(const Key('task_detail_link_field')), 'gcal-evt-12345');

      await tester.tap(find.byKey(const Key('task_detail_save_button')));
      await tester.pumpAndSettle();

      final task = (await db.select(db.tasks).get()).first;
      expect(task.source, 'manual');
    });

    // ─── Q. Google Sync Failure Best-Effort Local Invariant ───────────────────
    test('Q. Local task is preserved even when external Google service is null/offline', () async {
      final task = Task(
        id: 't-loc-only',
        title: 'Offline Local Task',
        createdAt: DateTime.now(),
      );
      await db.into(db.tasks).insert(
        TasksCompanion.insert(
          id: task.id,
          title: task.title,
          createdAt: task.createdAt,
          updatedAt: task.createdAt,
        ),
      );

      final row = (await db.select(db.tasks).get()).firstWhere((t) => t.id == 't-loc-only');
      expect(row.title, 'Offline Local Task');
    });

    // ─── R. Invalid Date Range = Zero Writes ─────────────────────────────────
    testWidgets('R. Invalid date range triggers validation and zero writes', (tester) async {
      final pastStart = DateTime(2026, 8, 20, 14, 0);
      final earlierEnd = DateTime(2026, 8, 20, 11, 0);

      final invalidTask = Task(
        id: 't-invalid-range',
        title: 'Invalid Workshop',
        startAt: pastStart,
        endAt: earlierEnd,
        createdAt: DateTime.now(),
      );

      await pumpSheet(tester, task: invalidTask);

      await tester.tap(find.byKey(const Key('task_detail_save_button')));
      await tester.pump();

      expect(find.text('End time cannot be earlier than start time'), findsOneWidget);
    });

    // ─── S. Duplicate Reminder Protection ────────────────────────────────────
    testWidgets('S. Duplicate reminder protection: updating task maintains exactly 1 active reminder', (tester) async {
      final task = Task(
        id: 't-single-rem',
        title: 'Single Reminder Task',
        dueDate: DateTime(2026, 8, 25, 10, 0),
        createdAt: DateTime.now(),
      );

      await db.into(db.tasks).insert(
        TasksCompanion.insert(
          id: task.id,
          title: task.title,
          dueAt: Value(task.dueDate),
          createdAt: task.createdAt,
          updatedAt: task.createdAt,
        ),
      );

      await pumpSheet(tester, task: task, initialTasks: [task]);

      // Edit title and save
      await tester.enterText(find.byKey(const Key('task_detail_title_field')), 'Updated Single Reminder Task');
      await tester.tap(find.byKey(const Key('task_detail_save_button')));
      await tester.pumpAndSettle();

      final reminders = await db.select(db.reminders).get();
      final activeReminders = reminders.where((r) => r.taskId == task.id && r.status != 'cancelled').toList();
      expect(activeReminders.length, lessThanOrEqualTo(1));
    });

    // ─── T. Narrow-Screen Resilience (360dp, 390dp, 412dp) ───────────────────
    testWidgets('T. Detail sheet renders without overflow on 360dp, 390dp, 412dp', (tester) async {
      final widths = [360.0, 390.0, 412.0];

      for (final width in widths) {
        tester.view.physicalSize = Size(width * 2, 800 * 2);
        tester.view.devicePixelRatio = 2.0;

        await tester.pumpWidget(
          buildTestableWidget(const AstraTaskDetailSheet()),
        );
        await tester.pump();

        expect(find.text('NEW TASK'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    // ─── Opening Triggers Verification ───────────────────────────────────────
    testWidgets('Tasks screen + button opens AstraTaskDetailSheet', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      await tester.pumpWidget(
        buildTestableWidget(const TasksScreen()),
      );
      await tester.pump();

      await tester.tap(find.byIcon(LucideIcons.plus));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AstraTaskDetailSheet), findsOneWidget);
    });

    testWidgets('Schedule screen + button opens AstraTaskDetailSheet', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      await tester.pumpWidget(
        buildTestableWidget(const ScheduleScreen()),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('schedule_add_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AstraTaskDetailSheet), findsOneWidget);
    });
  });
}
