import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:astra/models/task.dart';
import 'package:astra/models/task_intent.dart';
import 'package:astra/services/assistant/astra_recurrence_engine.dart';
import 'package:astra/widgets/tasks/astra_task_creation_sheet.dart';
import 'package:astra/screens/tasks_screen.dart';
import 'package:astra/providers/task_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ASTRA Pass 3B: TaskIntent Model & Creation Sheet Tests', () {
    // ─── 1. TaskIntent to Task Domain Conversion ──────────────────────────────
    test('1. TaskIntent converts to standard one-shot Task', () {
      final intent = TaskIntent(
        title: 'Study Data Structures',
        description: 'Binary trees & graphs',
        taskType: 'task',
        dueDate: DateTime(2026, 8, 19, 19, 0),
        priority: 'high',
        source: 'manual',
      );

      final task = intent.toTask();
      expect(task.title, 'Study Data Structures');
      expect(task.description, 'Binary trees & graphs');
      expect(task.dueDate, DateTime(2026, 8, 19, 19, 0));
      expect(task.priority, 'high');
      expect(task.status, 'active');
      expect(task.source, 'manual');
      expect(task.isDuration, isFalse);
    });

    test('2. TaskIntent converts to multi-day Event Task', () {
      final intent = TaskIntent(
        title: 'GB 2027 Aptitude Workshop',
        taskType: 'event',
        startAt: DateTime(2026, 8, 17, 9, 0),
        endAt: DateTime(2026, 8, 22, 17, 0),
        priority: 'high',
      );

      final task = intent.toTask();
      expect(task.title, 'GB 2027 Aptitude Workshop');
      expect(task.startAt, DateTime(2026, 8, 17, 9, 0));
      expect(task.endAt, DateTime(2026, 8, 22, 17, 0));
      expect(task.isDuration, isTrue);
      expect(task.status, 'active');
    });

    test('3. TaskIntent converts to Weekly Recurring Task with specific weekdays', () {
      const rule = RecurrenceRule(
        frequency: RecurrenceFrequency.weekly,
        byWeekdays: [DateTime.monday, DateTime.wednesday, DateTime.friday],
        hour: 19,
        minute: 0,
      );

      final intent = TaskIntent(
        title: 'DSA Class',
        taskType: 'reminder',
        recurrenceRule: rule,
        priority: 'medium',
      );

      final task = intent.toTask();
      expect(task.title, 'DSA Class');
      expect(task.recurrenceRule, isNotNull);
      expect(task.recurrenceRule!.frequency, RecurrenceFrequency.weekly);
      expect(task.recurrenceRule!.byWeekdays, [DateTime.monday, DateTime.wednesday, DateTime.friday]);
      expect(task.recurrenceRule!.hour, 19);
      expect(task.recurrenceRule!.minute, 0);
    });

    test('4. TaskIntent JSON round-trip preserves recurrence and properties', () {
      final intent = TaskIntent(
        id: 'intent_123',
        title: 'Water Plants',
        taskType: 'reminder',
        recurrenceRule: const RecurrenceRule(
          frequency: RecurrenceFrequency.daily,
          hour: 8,
          minute: 30,
        ),
        priority: 'low',
        source: 'assistant',
      );

      final json = intent.toJson();
      final deserialized = TaskIntent.fromJson(json);

      expect(deserialized.id, 'intent_123');
      expect(deserialized.title, 'Water Plants');
      expect(deserialized.taskType, 'reminder');
      expect(deserialized.priority, 'low');
      expect(deserialized.source, 'assistant');
      expect(deserialized.recurrenceRule?.frequency, RecurrenceFrequency.daily);
      expect(deserialized.recurrenceRule?.hour, 8);
      expect(deserialized.recurrenceRule?.minute, 30);
    });

    // ─── 2. Widget Tests for AstraTaskCreationSheet ───────────────────────────
    testWidgets('5. AstraTaskCreationSheet renders schedule modes, recurrence, and inputs', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AstraTaskCreationSheet(initialShowMoreOptions: true),
            ),
          ),
        ),
      );
      await tester.pump();

      // Verify Header
      expect(find.text('NEW TASK'), findsOneWidget);

      // Verify Core Row Controls
      expect(find.text('WHEN'), findsOneWidget);
      expect(find.text('REPEAT'), findsOneWidget);
      expect(find.text('REMIND'), findsOneWidget);
      expect(find.text('PRIORITY'), findsOneWidget);

      // Open REPEAT modal
      await tester.tap(find.text('REPEAT'));
      await tester.pumpAndSettle();

      // Verify Recurrence Presets exist in modal
      expect(find.text('Daily'), findsOneWidget);
      expect(find.text('Weekly'), findsOneWidget);
      expect(find.text('Monthly'), findsOneWidget);
      expect(find.text('Yearly'), findsOneWidget);

      // Tap Weekly and verify weekday chips render
      await tester.tap(find.text('Weekly'));
      await tester.pumpAndSettle();

      expect(find.text('M'), findsOneWidget);
      expect(find.text('W'), findsOneWidget);
      expect(find.text('F'), findsOneWidget);

      // Close modal
      await tester.tap(find.text('DONE'));
      await tester.pumpAndSettle();

      // Verify Save button
      expect(find.byKey(const Key('task_detail_save_button')), findsOneWidget);
    });

    // ─── 3. TasksScreen Clean-Up Tests ────────────────────────────────────────
    testWidgets('6. TasksScreen renders without floating inline composer and opens creation sheet on + tap', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;

      final now = DateTime.now();
      final tasks = [
        Task(id: '1', title: 'Focus Project', dueDate: now, status: 'pending', createdAt: now),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            taskListProvider.overrideWith((ref) => Stream.value(tasks)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: TasksScreen(),
            ),
          ),
        ),
      );
      await tester.pump();

      // Verify task list renders
      expect(find.text('Focus Project'), findsOneWidget);
      // Verify floating QuickAddBar / "Add a task for Today..." is removed
      expect(find.text('Add a task for Today...'), findsNothing);
      expect(find.text('Add a task...'), findsNothing);

      // Tap the + button in header and verify AstraTaskCreationSheet opens
      await tester.tap(find.byIcon(Icons.add).evaluate().isNotEmpty ? find.byIcon(Icons.add) : find.byWidgetPredicate((w) => w.toString().contains('plus') || w.toString().contains('Astra3DButton')).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify AstraTaskCreationSheet opened
      expect(find.byType(AstraTaskCreationSheet), findsOneWidget);
      expect(find.text('NEW TASK'), findsOneWidget);
    });
  });
}
