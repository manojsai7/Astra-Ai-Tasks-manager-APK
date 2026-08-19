import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/drift.dart' hide Column, isNull;

import 'package:astra/core/database/database.dart';
import 'package:astra/models/task.dart';
import 'package:astra/providers/ritual_provider.dart';
import 'package:astra/providers/task_provider.dart';
import 'package:astra/services/assistant/astra_recurrence_engine.dart';
import 'package:astra/services/haptics/astra_haptics.dart';
import 'package:astra/services/task/astra_schedule_item.dart';
import 'package:astra/screens/schedule_screen.dart';
import 'package:astra/widgets/schedule/astra_agenda_view.dart';
import 'package:astra/widgets/schedule/astra_day_view.dart';
import 'package:astra/widgets/schedule/astra_week_view.dart';
import 'package:astra/widgets/schedule/astra_month_view.dart';
import 'package:astra/widgets/tasks/astra_task_creation_sheet.dart';
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
            height: 800,
            child: child,
          ),
        ),
      ),
    );
  }

  group('ASTRA Phase 4B — Schedule / Agenda UX Tests (A–N)', () {
    // ─── A. Agenda Chronological Ordering ────────────────────────────────────
    test('A. Agenda sorts tasks chronologically across days and times', () {
      final now = DateTime(2026, 8, 18, 8, 0);

      final taskAfternoon = Task(
        id: 't-2',
        title: 'Architecture Review',
        dueDate: DateTime(2026, 8, 18, 14, 0),
        createdAt: now,
      );
      final taskMorning = Task(
        id: 't-1',
        title: 'Morning Standup',
        dueDate: DateTime(2026, 8, 18, 9, 0),
        createdAt: now,
      );
      final taskTomorrow = Task(
        id: 't-3',
        title: 'Cloud Deployment',
        dueDate: DateTime(2026, 8, 19, 10, 0),
        createdAt: now,
      );

      final schedule = AstraScheduleItem.buildSchedule(
        tasks: [taskAfternoon, taskTomorrow, taskMorning],
        windowStart: DateTime(2026, 8, 18),
        windowEnd: DateTime(2026, 8, 20),
        now: now,
      );

      expect(schedule.length, 3);
      expect(schedule[0].title, 'Morning Standup');
      expect(schedule[1].title, 'Architecture Review');
      expect(schedule[2].title, 'Cloud Deployment');
    });

    // ─── B. Day Timeline Positioning ─────────────────────────────────────────
    test('B. Duration events calculate duration and positioning accurately', () {
      final now = DateTime(2026, 8, 18, 10, 0);

      final durationTask = Task(
        id: 't-dur',
        title: 'Workshop',
        startAt: DateTime(2026, 8, 18, 13, 0),
        endAt: DateTime(2026, 8, 18, 15, 30),
        createdAt: now,
      );

      final item = AstraScheduleItem.fromTask(durationTask, now: now);
      expect(item.startAt.hour, 13);
      expect(item.endAt?.hour, 15);
      expect(item.endAt?.minute, 30);
      expect(item.itemType, 'event');
    });

    // ─── C. Week Rendering ───────────────────────────────────────────────────
    testWidgets('C. Week view renders 7-day strip and responds to date selection', (tester) async {
      final selectedDate = DateTime(2026, 8, 18);
      DateTime? tappedDate;

      final items = [
        AstraScheduleItem(
          id: 's-1',
          title: 'Design Sync',
          startAt: DateTime(2026, 8, 18, 11, 0),
          itemType: 'task',
        ),
      ];

      await tester.pumpWidget(
        buildTestableWidget(
          AstraWeekView(
            items: items,
            selectedDate: selectedDate,
            onDateSelected: (date) => tappedDate = date,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Design Sync'), findsOneWidget);
      expect(find.byType(AstraAgendaView), findsOneWidget);

      final day19 = find.text('19');
      expect(day19, findsWidgets);
      await tester.tap(day19.first);
      await tester.pump();
      expect(tappedDate?.day, 19);
    });

    // ─── D. Month Date Navigation ────────────────────────────────────────────
    testWidgets('D. Month view renders calendar grid and allows day tapping', (tester) async {
      final selectedDate = DateTime(2026, 8, 18);
      DateTime? selected;

      await tester.pumpWidget(
        buildTestableWidget(
          AstraMonthView(
            items: const [],
            selectedDate: selectedDate,
            onDateSelected: (d) => selected = d,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('M'), findsWidgets);
      final day25 = find.text('25');
      expect(day25, findsWidgets);

      await tester.tap(day25.first);
      await tester.pump();
      expect(selected?.day, 25);
    });

    // ─── E. Recurring Occurrence Expansion ───────────────────────────────────
    test('E. Recurring task expands into multiple occurrences over date window', () {
      final rule = const AstraRecurrenceEngine().parse('Drink water daily at 9am')!;

      final recurringTask = Task(
        id: 't-rec',
        title: 'Drink Water',
        recurrenceRule: rule,
        createdAt: DateTime(2026, 8, 1),
      );

      final schedule = AstraScheduleItem.buildSchedule(
        tasks: [recurringTask],
        windowStart: DateTime(2026, 8, 18, 0, 0),
        windowEnd: DateTime(2026, 8, 22, 23, 59),
      );

      // Should expand to 5 consecutive daily occurrences (18, 19, 20, 21, 22)
      expect(schedule.length, 5);
      expect(schedule.every((it) => it.title == 'Drink Water'), isTrue);
      expect(schedule.every((it) => it.isRecurring), isTrue);
      expect(schedule[0].startAt.day, 18);
      expect(schedule[4].startAt.day, 22);
    });

    // ─── F. No Duplicate Recurrence Tasks ────────────────────────────────────
    test('F. Recurrence expansion does not duplicate database rows', () async {
      final rule = const AstraRecurrenceEngine().parse('Drink water daily at 9am')!;

      final task = Task(
        id: 't-single-row',
        title: 'Hydration Routine',
        recurrenceRule: rule,
        createdAt: DateTime(2026, 8, 18),
      );

      await db.into(db.tasks).insert(
        TasksCompanion.insert(
          id: task.id,
          title: task.title,
          recurrenceRuleJson: Value(task.recurrenceRule?.toJson()),
          createdAt: task.createdAt,
          updatedAt: task.createdAt,
        ),
      );

      final allDbRows = await db.select(db.tasks).get();
      expect(allDbRows.length, 1);

      final schedule = AstraScheduleItem.buildSchedule(
        tasks: [task],
        windowStart: DateTime(2026, 8, 18),
        windowEnd: DateTime(2026, 8, 25),
      );

      // Multiple occurrences rendered without writing multiple DB rows
      expect(schedule.length, greaterThan(1));
      expect(allDbRows.length, 1);
    });

    // ─── G. Local Task + Google Event Coexistence ────────────────────────────
    test('G. Local tasks and external Google Calendar events coexist seamlessly', () {
      final localTask = Task(
        id: 't-loc',
        title: 'Local Assignment',
        dueDate: DateTime(2026, 8, 18, 10, 0),
        createdAt: DateTime(2026, 8, 18),
      );

      final googleEvent = AstraScheduleItem.fromGoogleCalendar(
        id: 'g-123',
        title: 'Google Meet Interview',
        startAt: DateTime(2026, 8, 18, 11, 30),
        endAt: DateTime(2026, 8, 18, 12, 30),
        location: 'Virtual',
      );

      final schedule = AstraScheduleItem.buildSchedule(
        tasks: [localTask],
        externalEvents: [googleEvent],
        windowStart: DateTime(2026, 8, 18),
        windowEnd: DateTime(2026, 8, 19),
      );

      expect(schedule.length, 2);
      expect(schedule[0].title, 'Local Assignment');
      expect(schedule[0].isGoogle, isFalse);
      expect(schedule[1].title, 'Google Meet Interview');
      expect(schedule[1].isGoogle, isTrue);
      expect(schedule[1].organization, 'Virtual');
    });

    // ─── H. Completed Task Rendering ─────────────────────────────────────────
    test('H. Completed tasks are properly flagged and preserved in schedule', () {
      final doneTask = Task(
        id: 't-done',
        title: 'Completed Task',
        status: 'completed',
        dueDate: DateTime(2026, 8, 18, 9, 0),
        createdAt: DateTime(2026, 8, 18),
      );

      final item = AstraScheduleItem.fromTask(doneTask);
      expect(item.isCompleted, isTrue);

      final schedule = AstraScheduleItem.buildSchedule(
        tasks: [doneTask],
        windowStart: DateTime(2026, 8, 18),
        windowEnd: DateTime(2026, 8, 19),
        includeCompleted: true,
      );
      expect(schedule.length, 1);
      expect(schedule.first.isCompleted, isTrue);
    });

    // ─── I. Overdue Task Rendering ───────────────────────────────────────────
    test('I. Past uncompleted tasks are flagged as Overdue', () {
      final pastDate = DateTime(2026, 8, 15, 10, 0);
      final currentDate = DateTime(2026, 8, 18, 12, 0);

      final pastTask = Task(
        id: 't-past',
        title: 'Past Due Assignment',
        dueDate: pastDate,
        createdAt: pastDate,
      );

      final item = AstraScheduleItem.fromTask(pastTask, now: currentDate);
      expect(item.isOverdue, isTrue);
    });

    // ─── J. Empty Schedule States ────────────────────────────────────────────
    testWidgets('J. Empty schedule displays user-friendly clear state', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          AstraAgendaView(
            items: const [],
            selectedDate: DateTime.now(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Your schedule is clear'), findsOneWidget);
      expect(find.text('No tasks or events found in this window.'), findsOneWidget);
    });

    // ─── K. Current-Day Navigation ───────────────────────────────────────────
    testWidgets('K. Schedule screen switches view modes and navigates to today', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(const ScheduleScreen()),
      );
      await tester.pump();

      expect(find.text('ASTRA SCHEDULE'), findsOneWidget);
      expect(find.byKey(const Key('view_mode_agenda')), findsOneWidget);
      expect(find.byKey(const Key('view_mode_day')), findsOneWidget);
      expect(find.byKey(const Key('view_mode_week')), findsOneWidget);
      expect(find.byKey(const Key('view_mode_month')), findsOneWidget);

      // Switch to DAY view
      await tester.tap(find.byKey(const Key('view_mode_day')));
      await tester.pump();
      expect(find.byType(AstraDayView), findsOneWidget);

      // Switch to WEEK view
      await tester.tap(find.byKey(const Key('view_mode_week')));
      await tester.pump();
      expect(find.byType(AstraWeekView), findsOneWidget);

      // Switch to MONTH view
      await tester.tap(find.byKey(const Key('view_mode_month')));
      await tester.pump();
      expect(find.byType(AstraMonthView), findsOneWidget);
    });

    // ─── L. Narrow-Screen Resilience (360dp, 390dp, 412dp) ───────────────────
    testWidgets('L. ScheduleScreen renders without overflow on 360dp, 390dp, 412dp', (tester) async {
      final widths = [360.0, 390.0, 412.0];

      for (final width in widths) {
        tester.view.physicalSize = Size(width * 2, 800 * 2);
        tester.view.devicePixelRatio = 2.0;

        await tester.pumpWidget(
          buildTestableWidget(const ScheduleScreen()),
        );
        await tester.pump();

        expect(find.text('ASTRA SCHEDULE'), findsOneWidget);
      }

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    // ─── M. Task Tap Opens Creation Sheet Callback ───────────────────────────
    testWidgets('M. Tapping add button opens task creation sheet', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(const ScheduleScreen()),
      );
      await tester.pump();

      // Tap + button
      await tester.tap(find.byKey(const Key('schedule_add_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Creation sheet is displayed
      expect(find.byType(AstraTaskCreationSheet), findsOneWidget);
    });

    // ─── N. Haptic Interaction Abstraction ───────────────────────────────────
    test('N. AstraHaptics executes safely during schedule interactions', () async {
      AstraHaptics.isEnabled = true;
      await AstraHaptics.selection();
      await AstraHaptics.light();
      await AstraHaptics.success();
      expect(AstraHaptics.isEnabled, isTrue);
    });
  });
}
