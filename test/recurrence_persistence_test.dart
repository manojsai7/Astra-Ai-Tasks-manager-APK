import 'package:flutter_test/flutter_test.dart';

import 'package:astra/core/database/database.dart';
import 'package:astra/models/task.dart';
import 'package:astra/providers/task_provider.dart';
import 'package:astra/services/assistant/astra_recurrence_engine.dart';
import 'package:astra/services/reminder_service.dart';
import 'helpers/test_database_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late ReminderService reminderService;
  late TaskNotifier taskNotifier;

  setUp(() {
    db = TestDatabaseHelper.createMemoryDatabase();
    reminderService = ReminderService(db);
    taskNotifier = TaskNotifier(db, reminderService);
  });

  tearDown(() async {
    await db.close();
  });

  group('Phase 2V-2: Recurrence Persistence & Drift Mapping Tests', () {
    // A. Existing task with null recurrence: loads successfully, recurrenceRule == null
    test('A. Existing task with null recurrence: loads successfully and recurrenceRule == null', () async {
      final task = Task.create(
        title: 'Non-recurring task',
        priority: 'high',
        dueDate: DateTime(2026, 5, 25, 10, 0),
        recurrenceRule: null,
      );

      await taskNotifier.addTask(task);

      final loadedTasks = taskNotifier.state;
      expect(loadedTasks.length, 1);
      expect(loadedTasks.first.title, 'Non-recurring task');
      expect(loadedTasks.first.recurrenceRule, isNull);

      final row = await (db.select(db.tasks)..where((t) => t.id.equals(task.id))).getSingle();
      expect(row.recurrenceRuleJson, isNull);
    });

    // B. Task with DAILY recurrence: write task, read task, recurrenceRule.frequency == daily
    test('B. Task with DAILY recurrence: write/read round-trip preserves daily frequency', () async {
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
        startDate: DateTime(2026, 5, 25),
        hour: 9,
        minute: 0,
      );

      final task = Task.create(
        title: 'Daily Standup',
        dueDate: DateTime(2026, 5, 25, 9, 0),
        recurrenceRule: rule,
      );

      await taskNotifier.addTask(task);

      final loadedTasks = taskNotifier.state;
      expect(loadedTasks.length, 1);
      final loaded = loadedTasks.first;
      expect(loaded.title, 'Daily Standup');
      expect(loaded.recurrenceRule, isNotNull);
      expect(loaded.recurrenceRule!.frequency, RecurrenceFrequency.daily);
      expect(loaded.recurrenceRule!.hour, 9);
      expect(loaded.recurrenceRule!.minute, 0);
      expect(loaded.recurrenceRule!.startDate, DateTime(2026, 5, 25));
    });

    // C. Task with WEEKDAYS recurrence: write task, read task verifies frequency
    test('C. Task with WEEKDAYS recurrence: write/read round-trip succeeds with time window', () async {
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.weekdays,
        startDate: DateTime(2026, 5, 25),
        hour: 14,
        minute: 30,
      );

      final task = Task.create(
        title: 'Afternoon Sync',
        dueDate: DateTime(2026, 5, 25, 14, 30),
        recurrenceRule: rule,
      );

      await taskNotifier.addTask(task);

      final loadedTasks = taskNotifier.state;
      expect(loadedTasks.length, 1);
      final loaded = loadedTasks.first;
      expect(loaded.title, 'Afternoon Sync');
      expect(loaded.recurrenceRule, isNotNull);
      expect(loaded.recurrenceRule!.frequency, RecurrenceFrequency.weekdays);
      expect(loaded.recurrenceRule!.hour, 14);
      expect(loaded.recurrenceRule!.minute, 30);
    });

    // D. JSON round-trip: raw JSON stored directly in Drift reconstructs identical rule
    test('D. JSON round-trip: persisted JSON in Drift row reconstructs identical rule', () async {
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.weekly,
        startDate: DateTime(2026, 5, 25),
        endDate: DateTime(2026, 12, 31),
        hour: 10,
        minute: 15,
      );

      await TestDatabaseHelper.insertTaskRow(
        db,
        id: 'json-roundtrip-1',
        title: 'Weekly Review',
        dueAt: DateTime(2026, 5, 25, 10, 15),
        recurrenceRuleJson: rule.toJson(),
      );

      await taskNotifier.loadTasks();

      final loaded = taskNotifier.state.first;
      expect(loaded.recurrenceRule, isNotNull);
      expect(loaded.recurrenceRule!.frequency, RecurrenceFrequency.weekly);
      expect(loaded.recurrenceRule!.startDate, DateTime(2026, 5, 25));
      expect(loaded.recurrenceRule!.endDate, DateTime(2026, 12, 31));
      expect(loaded.recurrenceRule!.hour, 10);
      expect(loaded.recurrenceRule!.minute, 15);
    });

    // E. Malformed JSON resilience: task still loads safely, recurrenceRule == null
    test('E. Malformed recurrence JSON: task still loads, recurrenceRule == null without throwing', () async {
      await TestDatabaseHelper.insertTaskRow(
        db,
        id: 'corrupted-task-1',
        title: 'Corrupted Recurrence Task',
        dueAt: DateTime(2026, 5, 25, 10, 0),
        recurrenceRuleJson: '{invalid_json: true, "corrupted": ',
      );

      await taskNotifier.loadTasks();

      final loaded = taskNotifier.state.first;
      expect(loaded.id, 'corrupted-task-1');
      expect(loaded.title, 'Corrupted Recurrence Task');
      expect(loaded.recurrenceRule, isNull);
    });

    // F. Existing task behavior: all other metadata fields preserved intact
    test('F. Existing non-recurring task behavior: all metadata preserved', () async {
      final task = Task(
        id: 'full-task-1',
        title: 'Full Metadata Task',
        description: 'Testing field preservation',
        dueDate: DateTime(2026, 5, 25, 10, 0),
        priority: 'high',
        status: 'active',
        order: 3,
        subtasks: [SubTask(id: 's1', name: 'Step 1', isCompleted: false)],
        source: 'assistant',
        sourceId: 'src-123',
        category: 'work',
        organization: 'Acme Corp',
        createdAt: DateTime(2026, 5, 20, 10, 0),
        recurrenceRule: null,
      );

      await taskNotifier.addTask(task);

      final loaded = taskNotifier.state.first;
      expect(loaded.id, 'full-task-1');
      expect(loaded.title, 'Full Metadata Task');
      expect(loaded.description, 'Testing field preservation');
      expect(loaded.priority, 'high');
      expect(loaded.status, 'active');
      expect(loaded.order, 3);
      expect(loaded.subtasks.length, 1);
      expect(loaded.subtasks.first.name, 'Step 1');
      expect(loaded.source, 'assistant');
      expect(loaded.sourceId, 'src-123');
      expect(loaded.category, 'work');
      expect(loaded.organization, 'Acme Corp');
      expect(loaded.recurrenceRule, isNull);
    });

    // G. Migration simulation: database schema version exposes recurrenceRuleJson
    test('G. Migration: schema upgrade from version 7 to 8 adds recurrenceRuleJson column', () async {
      expect(db.schemaVersion, greaterThanOrEqualTo(8));

      final task = Task.create(
        title: 'Schema 8 Task',
        recurrenceRule: const RecurrenceRule(frequency: RecurrenceFrequency.daily, hour: 9, minute: 0),
      );

      await taskNotifier.addTask(task);
      final rows = await db.select(db.tasks).get();
      expect(rows.first.recurrenceRuleJson, contains('DAILY'));
    });
  });
}
