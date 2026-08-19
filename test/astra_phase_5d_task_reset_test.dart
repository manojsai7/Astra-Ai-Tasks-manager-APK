import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:astra/core/database/database.dart';
import 'package:astra/core/parser/task_parser.dart';
import 'package:astra/models/task.dart';
import 'package:astra/models/task_intent.dart';
import 'package:astra/providers/task_provider.dart';
import 'package:astra/services/assistant/astra_recurrence_engine.dart';
import 'package:astra/services/data/astra_backup_service.dart';
import 'package:astra/services/data/astra_restore_service.dart';
import 'package:astra/widgets/tasks/astra_task_card.dart';
import 'package:drift/drift.dart' as drift;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late AstraRecurrenceEngine recurrenceEngine;

  setUp(() {
    db = constructInMemoryDb();
    recurrenceEngine = const AstraRecurrenceEngine();
    TaskParser.resetClock();
  });

  tearDown(() async {
    await db.close();
  });

  group('ASTRA Phase 5D: Task Experience Reset — Scheduling Matrix (Scenarios A–G)', () {
    test('Scenario A: NO DATE + NO TIME + NO REPEAT -> Unscheduled Task', () {
      final task = Task.create(
        title: 'Buy groceries',
        dueDate: null,
        dueTime: null,
        recurrenceRule: null,
      );

      expect(task.title, equals('Buy groceries'));
      expect(task.dueDate, isNull);
      expect(task.dueTime, isNull);
      expect(task.recurrenceRule, isNull);
      expect(task.isNoDate, isTrue);
    });

    test('Scenario B: NO DATE + 8:00 PM + NO REPEAT -> Floating Timed Task', () {
      final task = Task.create(
        title: 'Drink water',
        dueDate: null,
        dueTime: '20:00',
        recurrenceRule: null,
      );

      expect(task.title, equals('Drink water'));
      expect(task.dueDate, isNull);
      expect(task.dueTime, equals('20:00'));
      expect(task.recurrenceRule, isNull);
    });

    test('Scenario C: NO DATE + 8:00 PM + DAILY -> Daily Recurring Task', () {
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
        hour: 20,
        minute: 0,
      );
      final task = Task.create(
        title: 'Gym',
        dueDate: null,
        dueTime: '20:00',
        recurrenceRule: rule,
      );

      expect(task.title, equals('Gym'));
      expect(task.dueDate, isNull);
      expect(task.dueTime, equals('20:00'));
      expect(task.recurrenceRule?.frequency, equals(RecurrenceFrequency.daily));

      final now = DateTime(2026, 8, 19, 18, 0); // 6:00 PM
      final nextOcc = recurrenceEngine.nextOccurrence(rule, now);
      expect(nextOcc, equals(DateTime(2026, 8, 19, 20, 0))); // Today at 8:00 PM

      final lateNow = DateTime(2026, 8, 19, 21, 0); // 9:00 PM
      final nextDayOcc = recurrenceEngine.nextOccurrence(rule, lateNow);
      expect(nextDayOcc, equals(DateTime(2026, 8, 20, 20, 0))); // Tomorrow at 8:00 PM
    });

    test('Scenario D: TOMORROW + NO TIME + NO REPEAT -> Date Anchor Task', () {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final task = Task.create(
        title: 'Call landlord',
        dueDate: tomorrow,
        dueTime: null,
        recurrenceRule: null,
      );

      expect(task.title, equals('Call landlord'));
      expect(task.dueDate, isNotNull);
      expect(task.dueTime, isNull);
      expect(task.recurrenceRule, isNull);
    });

    test('Scenario E: TOMORROW + 8:00 PM + NO REPEAT -> Scheduled Single Occurrence', () {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final task = Task.create(
        title: 'Doctor appointment',
        dueDate: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 20, 0),
        dueTime: '20:00',
        recurrenceRule: null,
      );

      expect(task.title, equals('Doctor appointment'));
      expect(task.dueDate?.hour, equals(20));
      expect(task.dueTime, equals('20:00'));
      expect(task.recurrenceRule, isNull);
    });

    test('Scenario F: TOMORROW + 8:00 PM + DAILY -> Daily Recurring Anchored Tomorrow', () {
      final tomorrow = DateTime(2026, 8, 20);
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
        startDate: tomorrow,
        hour: 20,
        minute: 0,
      );
      final task = Task.create(
        title: 'Gym',
        dueDate: DateTime(2026, 8, 20, 20, 0),
        dueTime: '20:00',
        recurrenceRule: rule,
      );
      expect(task.title, equals('Gym'));

      final now = DateTime(2026, 8, 19, 10, 0);
      final nextOcc = recurrenceEngine.nextOccurrence(rule, now);
      expect(nextOcc, equals(DateTime(2026, 8, 20, 20, 0)));
    });

    test('Scenario G: START + END + 8:00 PM + DAILY -> Bounded Recurring Schedule', () {
      final startDate = DateTime(2026, 8, 20);
      final endDate = DateTime(2026, 8, 26, 23, 59, 59);
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
        startDate: startDate,
        endDate: endDate,
        hour: 20,
        minute: 0,
      );
      final task = Task.create(
        title: 'Gym daily from tomorrow till next Wednesday',
        dueDate: DateTime(2026, 8, 20, 20, 0),
        dueTime: '20:00',
        recurrenceRule: rule,
      );
      expect(task.title, equals('Gym daily from tomorrow till next Wednesday'));

      // Occurrence within window
      final occ1 = recurrenceEngine.nextOccurrence(rule, DateTime(2026, 8, 19, 10, 0));
      expect(occ1, equals(DateTime(2026, 8, 20, 20, 0)));

      // Occurrence on final day
      final occFinal = recurrenceEngine.nextOccurrence(rule, DateTime(2026, 8, 25, 21, 0));
      expect(occFinal, equals(DateTime(2026, 8, 26, 20, 0)));

      // Occurrence after end date should be null
      final occPast = recurrenceEngine.nextOccurrence(rule, DateTime(2026, 8, 26, 21, 0));
      expect(occPast, isNull);
    });
  });

  group('ASTRA Phase 5D: Natural Language Recurrence & Window Parsing (Scenarios H–L)', () {
    test('Scenario H: "Gym daily at 8pm" -> recurrence daily, time 20:00, clean title "Gym"', () {
      final parsed = TaskParser.parse('Gym daily at 8pm');
      expect(parsed.title, equals('Gym'));
      expect(parsed.dueTime, equals('20:00'));
      expect(parsed.recurrenceRule?.frequency, equals(RecurrenceFrequency.daily));
      expect(parsed.recurrenceRule?.hour, equals(20));
      expect(parsed.recurrenceRule?.minute, equals(0));
    });

    test('Scenario I: "Study DSA weekdays at 7" -> recurrence weekdays, time 19:00', () {
      final parsed = TaskParser.parse('Study DSA weekdays at 7');
      expect(parsed.title, equals('Study DSA'));
      expect(parsed.dueTime, equals('19:00'));
      expect(parsed.recurrenceRule?.frequency, equals(RecurrenceFrequency.weekdays));
      expect(parsed.recurrenceRule?.hour, equals(19));
      expect(parsed.recurrenceRule?.minute, equals(0));
    });

    test('Scenario J: "Interview tomorrow at 11" -> non-recurring, remindAt tomorrow 11:00', () {
      final parsed = TaskParser.parse('Interview tomorrow at 11');
      expect(parsed.title, equals('Interview'));
      expect(parsed.dueTime, equals('11:00'));
      expect(parsed.recurrenceRule, isNull);
      expect(parsed.remindAt?.hour, equals(11));
    });

    test('Scenario K: "Gym daily at 8pm from tomorrow till next Wednesday" -> bounded recurrence window', () {
      final parsed = TaskParser.parse('Gym daily at 8pm from tomorrow till next Wednesday');
      expect(parsed.title, equals('Gym'));
      expect(parsed.dueTime, equals('20:00'));
      expect(parsed.recurrenceRule?.frequency, equals(RecurrenceFrequency.daily));
      expect(parsed.recurrenceRule?.startDate, isNotNull);
      expect(parsed.recurrenceRule?.endDate, isNotNull);
    });

    test('Scenario L: ParsedTask.toTaskIntent() canonical bridge preserves all fields', () {
      final parsed = TaskParser.parse('Gym daily at 8pm from tomorrow till next Wednesday');
      final intent = parsed.toTaskIntent(source: 'assistant');

      expect(intent.title, equals('Gym'));
      expect(intent.dueTime, equals('20:00'));
      expect(intent.recurrenceRule?.frequency, equals(RecurrenceFrequency.daily));
      expect(intent.source, equals('assistant'));

      final task = intent.toTask();
      expect(task.title, equals('Gym'));
      expect(task.dueTime, equals('20:00'));
      expect(task.recurrenceRule?.frequency, equals(RecurrenceFrequency.daily));
      expect(task.status, equals('active'));
    });
  });

  group('ASTRA Phase 5D: SQLite Persistence & Migration Compatibility (Scenarios M–Q)', () {
    test('Scenario M: Insert and query task with dueTime in Drift SQLite', () async {
      const taskId = 'test-task-due-time-1';
      final now = DateTime.now();

      await db.into(db.tasks).insert(
            TasksCompanion(
              id: const drift.Value(taskId),
              title: const drift.Value('Drink water'),
              dueTime: const drift.Value('20:00'),
              status: const drift.Value('pending'),
              priority: const drift.Value('medium'),
              createdAt: drift.Value(now),
              updatedAt: drift.Value(now),
            ),
          );

      final row = await (db.select(db.tasks)..where((t) => t.id.equals(taskId))).getSingle();
      expect(row.title, equals('Drink water'));
      expect(row.dueAt, isNull);
      expect(row.dueTime, equals('20:00'));
      expect(row.status, equals('pending'));

      final task = taskEntryToTask(row);
      expect(task.title, equals('Drink water'));
      expect(task.dueDate, isNull);
      expect(task.dueTime, equals('20:00'));
    });

    test('Scenario N: Task.toJson() and Task.fromJson() roundtrip with dueTime and recurrence', () {
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.weekdays,
        hour: 19,
        minute: 0,
      );
      final task = Task.create(
        title: 'Study DSA',
        dueTime: '19:00',
        recurrenceRule: rule,
      );

      final json = task.toJson();
      expect(json['dueTime'], equals('19:00'));
      expect(json['recurrenceRule'], isNotNull);

      final restored = Task.fromJson(json);
      expect(restored.title, equals('Study DSA'));
      expect(restored.dueTime, equals('19:00'));
      expect(restored.recurrenceRule?.frequency, equals(RecurrenceFrequency.weekdays));
    });

    test('Scenario O: Backup export includes dueTime and schemaVersion 10', () async {
      final now = DateTime.now();
      await db.into(db.tasks).insert(
            TasksCompanion(
              id: const drift.Value('task-backup-test-1'),
              title: const drift.Value('Night Workout'),
              dueTime: const drift.Value('21:00'),
              status: const drift.Value('active'),
              priority: const drift.Value('high'),
              createdAt: drift.Value(now),
              updatedAt: drift.Value(now),
            ),
          );

      final backupService = AstraBackupService(db);
      final encryptedPayload = await backupService.createEncryptedBackup(password: 'testpass123');

      expect(encryptedPayload.metadata.schemaVersion, equals(10));
      expect(encryptedPayload.metadata.taskCount, equals(1));
    });

    test('Scenario P: Backup restore preserves dueTime across devices', () async {
      final now = DateTime.now();
      await db.into(db.tasks).insert(
            TasksCompanion(
              id: const drift.Value('task-restore-test-1'),
              title: const drift.Value('Morning Meditation'),
              dueTime: const drift.Value('06:30'),
              status: const drift.Value('active'),
              priority: const drift.Value('medium'),
              createdAt: drift.Value(now),
              updatedAt: drift.Value(now),
            ),
          );

      final backupService = AstraBackupService(db);
      final payload = await backupService.createEncryptedBackup(password: 'restorepwd4');

      // Create new clean in-memory db
      final newDb = constructInMemoryDb();
      final restoreService = AstraRestoreService(newDb);

      final result = await restoreService.restoreBackup(
        payload.toBytes(),
        password: 'restorepwd4',
      );

      expect(result.success, isTrue);
      expect(result.tasksRestored, equals(1));

      final restoredRow = await (newDb.select(newDb.tasks)..where((t) => t.id.equals('task-restore-test-1'))).getSingle();
      expect(restoredRow.title, equals('Morning Meditation'));
      expect(restoredRow.dueTime, equals('06:30'));

      await newDb.close();
    });

    test('Scenario Q: Single SQLite row invariant for recurring task', () async {
      const taskId = 'single-row-recurring-task';
      final now = DateTime.now();
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
        hour: 20,
        minute: 0,
      );

      await db.into(db.tasks).insert(
            TasksCompanion(
              id: const drift.Value(taskId),
              title: const drift.Value('Gym'),
              dueTime: const drift.Value('20:00'),
              recurrenceRuleJson: drift.Value(rule.toJson()),
              status: const drift.Value('active'),
              priority: const drift.Value('medium'),
              createdAt: drift.Value(now),
              updatedAt: drift.Value(now),
            ),
          );

      // Verify only 1 row exists in the database
      final count = await (db.select(db.tasks)..where((t) => t.id.equals(taskId))).get();
      expect(count.length, equals(1));
    });
  });

  group('ASTRA Phase 5D: UI & Component Tests (Scenarios R–V)', () {
    testWidgets('Scenario R: AstraTaskCard displays formatted time for NO DATE + 8:00 PM task', (tester) async {
      final task = Task.create(
        title: 'Evening Workout',
        dueDate: null,
        dueTime: '20:00',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AstraTaskCard(
              task: task,
              onComplete: () {},
            ),
          ),
        ),
      );

      expect(find.text('Evening Workout'), findsOneWidget);
      expect(find.text('8:00 PM'), findsOneWidget);
    });

    testWidgets('Scenario S: AstraTaskCard displays bounded recurrence summary subtitle', (tester) async {
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
        hour: 20,
        minute: 0,
        endDate: DateTime(2026, 8, 26),
      );
      final task = Task.create(
        title: 'Gym',
        dueTime: '20:00',
        recurrenceRule: rule,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AstraTaskCard(
              task: task,
              onComplete: () {},
            ),
          ),
        ),
      );

      expect(find.text('Gym'), findsOneWidget);
      expect(find.text('Daily · 8:00 PM · until 26 Aug'), findsOneWidget);
    });

    testWidgets('Scenario T: AstraTaskCard displays Weekdays recurrence subtitle', (tester) async {
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.weekdays,
        hour: 19,
        minute: 0,
      );
      final task = Task.create(
        title: 'Study DSA',
        dueTime: '19:00',
        recurrenceRule: rule,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AstraTaskCard(
              task: task,
              onComplete: () {},
            ),
          ),
        ),
      );

      expect(find.text('Study DSA'), findsOneWidget);
      expect(find.text('Weekdays · 7:00 PM'), findsOneWidget);
    });

    test('Scenario U: TaskIntent toTask with dueTime preserves status active if scheduled', () {
      final intent = TaskIntent(
        title: 'Floating reminder',
        dueTime: '20:00',
      );

      final task = intent.toTask();
      expect(task.title, equals('Floating reminder'));
      expect(task.dueTime, equals('20:00'));
      expect(task.status, equals('active'));
    });

    test('Scenario V: Task.copyWith clearRecurrenceRule removes recurrence cleanly', () {
      final rule = RecurrenceRule(frequency: RecurrenceFrequency.daily, hour: 20, minute: 0);
      final task = Task.create(title: 'Gym', recurrenceRule: rule);
      expect(task.recurrenceRule, isNotNull);

      final updated = task.copyWith(clearRecurrenceRule: true);
      expect(updated.recurrenceRule, isNull);
    });
  });
}
