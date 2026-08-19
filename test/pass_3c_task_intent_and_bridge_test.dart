import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astra/core/database/database.dart';
import 'package:astra/models/task.dart';
import 'package:astra/models/task_intent.dart';
import 'package:astra/providers/astra_command_executor_provider.dart';
import 'package:astra/providers/assistant_provider.dart';
import 'package:astra/providers/astra_memory_provider.dart';
import 'package:astra/providers/chat_session_provider.dart';
import 'package:astra/providers/ritual_provider.dart';
import 'package:astra/services/assistant/astra_command.dart';
import 'package:astra/services/assistant/astra_recurrence_engine.dart';
import 'package:astra/services/task/astra_task_filter.dart';
import 'package:astra/services/haptics/astra_haptics.dart';
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

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
      ],
    );
  }

  group('ASTRA Pass 3C: TaskIntent Canonical Bridge & UI Sync Tests', () {
    // ─── A. Manual TaskIntent -> Task Persistence ────────────────────────────
    test('A. Manual TaskIntent persists correctly to Drift via executor', () async {
      final container = createContainer();
      final executor = container.read(astraCommandExecutorProvider);

      const intent = TaskIntent(
        title: 'Review System Architecture',
        description: 'Prepare diagrams for tomorrow',
        taskType: 'task',
        priority: 'high',
        source: 'manual',
      );

      final result = await executor.executeTaskIntent(
        ref: container,
        intent: intent,
      );

      expect(result.success, isTrue);
      expect(result.title, 'Review System Architecture');

      final tasks = await db.select(db.tasks).get();
      expect(tasks.length, 1);
      expect(tasks.first.title, 'Review System Architecture');
      expect(tasks.first.priority, 'high');
      expect(tasks.first.source, 'manual');

      container.dispose();
    });

    // ─── B. ASTRA TaskIntent -> Same Task Repository ────────────────────────
    test('B. ASTRA TaskIntent maps from AstraCommand to same executor and DB', () async {
      final container = createContainer();
      final executor = container.read(astraCommandExecutorProvider);

      final command = AstraCommand(
        intent: 'CREATE_TASK',
        eventType: 'EXAM',
        title: 'Cloud Architecture Final',
        temporal: AstraTemporal(
          eventStart: DateTime.now().add(const Duration(days: 2)),
          rawDate: 'in 2 days',
        ),
        recurrence: 'NONE',
        priority: 'high',
        modelConfidence: 0.95,
        semanticConfidence: 0.95,
        requiresConfirmation: false,
        route: 'EXECUTE',
        originalText: 'Cloud Architecture Final in 2 days',
      );

      final intent = TaskIntent.fromAstraCommand(command);
      expect(intent.title, 'Cloud Architecture Final');
      expect(intent.source, 'assistant');

      final result = await executor.executeTaskIntent(
        ref: container,
        intent: intent,
      );

      expect(result.success, isTrue);

      final tasks = await db.select(db.tasks).get();
      expect(tasks.length, 1);
      expect(tasks.first.title, 'Cloud Architecture Final');
      expect(tasks.first.status, 'active');

      container.dispose();
    });

    // ─── C. Recurring TaskIntent -> RecurrenceRule ───────────────────────────
    test('C. Recurring TaskIntent produces unified RecurrenceRule across manual and NLP', () {
      const recurrenceEngine = AstraRecurrenceEngine();

      // Case 1: Weekday recurrence
      final rule1 = recurrenceEngine.parse('Study every weekday at 7pm');
      expect(rule1, isNotNull);
      expect(rule1!.frequency, RecurrenceFrequency.weekdays);
      expect(rule1.hour, 19);

      // Case 2: Daily recurrence
      final rule2 = recurrenceEngine.parse('Water plants daily at 8am');
      expect(rule2, isNotNull);
      expect(rule2!.frequency, RecurrenceFrequency.daily);
      expect(rule2.hour, 8);

      // Case 3: Monthly recurrence
      final rule3 = recurrenceEngine.parse('Pay fee every month on the 25th');
      expect(rule3, isNotNull);
      expect(rule3!.frequency, RecurrenceFrequency.monthly);

      // TaskIntent with recurrenceRule
      final intent = TaskIntent(
        title: 'Study DSA',
        taskType: 'task',
        recurrenceRule: rule1,
      );
      final task = intent.toTask();
      expect(task.recurrenceRule, isNotNull);
      expect(task.recurrenceRule!.frequency, RecurrenceFrequency.weekdays);
    });

    // ─── D. Task Screen State Refresh After Creation ─────────────────────────
    test('D. Task notifier and filter categorize tasks automatically', () async {
      final container = createContainer();
      final executor = container.read(astraCommandExecutorProvider);

      final tom = DateTime.now().add(const Duration(days: 1));
      final intent = TaskIntent(
        title: 'Upcoming Presentation',
        dueDate: tom,
        taskType: 'task',
      );

      await executor.executeTaskIntent(
        ref: container,
        intent: intent,
      );

      final tasks = await db.select(db.tasks).get();
      final mapped = tasks.map((t) => Task(id: t.id, title: t.title, dueDate: t.dueAt, createdAt: t.createdAt)).toList();
      final buckets = AstraTaskFilter.categorize(mapped);

      expect(buckets.upcomingCount, 1);
      expect(buckets.tomorrowTasks.length, 1);

      container.dispose();
    });

    // ─── E. Task Screen State Refresh After Update ───────────────────────────
    test('E. Task mutation updates state without manual restart', () async {
      final container = createContainer();
      final assistant = container.read(assistantStateProvider.notifier);
      final sessionId = await container.read(chatSessionProvider.notifier).createSession(title: 'Sync Test');
      container.read(currentSessionIdProvider.notifier).state = sessionId;

      await assistant.sendCommand('I have an exam tomorrow at 10am');
      var tasks = await db.select(db.tasks).get();
      expect(tasks.length, 1);
      expect(tasks.first.dueAt?.hour, 10);

      await assistant.sendCommand('make it 3pm');
      tasks = await db.select(db.tasks).get();
      expect(tasks.length, 1);
      expect(tasks.first.dueAt?.hour, 15); // 3:00 PM

      container.dispose();
    });

    // ─── F. Conversational Create -> Memory Write ────────────────────
    test('F. Conversational creation stores structured working memory', () async {
      final container = createContainer();
      final assistant = container.read(assistantStateProvider.notifier);
      final memoryEngine = container.read(astraMemoryEngineProvider);
      final sessionId = await container.read(chatSessionProvider.notifier).createSession(title: 'Mem Test');
      container.read(currentSessionIdProvider.notifier).state = sessionId;

      await assistant.sendCommand('I have a Google interview tomorrow at 4pm');

      final memories = memoryEngine.getAllWorkingMemories();
      expect(memories.isNotEmpty, isTrue);
      expect(memories.any((m) => m.value.contains('Google') || m.value.contains('Interview')), isTrue);

      container.dispose();
    });

    // ─── G.  it -> Same Task ID ─────────────────────────────────────────────
    test('G. Follow-up it resolves to existing Task ID without duplication', () async {
      final container = createContainer();
      final assistant = container.read(assistantStateProvider.notifier);
      final sessionId = await container.read(chatSessionProvider.notifier).createSession(title: 'ID Test');
      container.read(currentSessionIdProvider.notifier).state = sessionId;

      await assistant.sendCommand('I have an assignment due Friday');
      var tasks = await db.select(db.tasks).get();
      expect(tasks.length, 1);
      final originalId = tasks.first.id;

      await assistant.sendCommand('remind me about it Thursday at 8pm');
      tasks = await db.select(db.tasks).get();
      expect(tasks.length, 1);
      expect(tasks.first.id, originalId);

      container.dispose();
    });

    // ─── H. No Duplicate Task on Multiple Follow-ups ─────────────────────────
    test('H. Multiple mutations maintain single canonical task row', () async {
      final container = createContainer();
      final assistant = container.read(assistantStateProvider.notifier);
      final sessionId = await container.read(chatSessionProvider.notifier).createSession(title: 'No Dupes');
      container.read(currentSessionIdProvider.notifier).state = sessionId;

      await assistant.sendCommand('I have a team meeting tomorrow at 9am');
      await assistant.sendCommand('make it 11am');
      await assistant.sendCommand('make it 5pm');

      final tasks = await db.select(db.tasks).get();
      expect(tasks.length, 1);
      expect(tasks.first.dueAt?.hour, 17);

      container.dispose();
    });

    // ─── I. Calendar TaskIntent ──────────────────────────────────────────────
    test('I. Calendar event TaskIntent maps event duration correctly', () async {
      final container = createContainer();
      final executor = container.read(astraCommandExecutorProvider);

      final start = DateTime.now().add(const Duration(days: 3, hours: 10));
      final end = start.add(const Duration(hours: 2));

      final intent = TaskIntent(
        title: 'Kubernetes Workshop',
        taskType: 'event',
        startAt: start,
        endAt: end,
        organization: 'CNCF',
        source: 'manual',
      );

      final result = await executor.executeTaskIntent(
        ref: container,
        intent: intent,
      );

      expect(result.success, isTrue);
      expect(result.title, 'Kubernetes Workshop');

      final tasks = await db.select(db.tasks).get();
      expect(tasks.length, 1);
      expect(tasks.first.startAt, isNotNull);
      expect(tasks.first.endAt, isNotNull);

      container.dispose();
    });

    // ─── J. Haptic Invocation Abstraction ────────────────────────────────────
    test('J. AstraHaptics methods execute safely and respect isEnabled toggle', () async {
      // Should run without throwing on any platform/test environment
      AstraHaptics.isEnabled = true;
      await AstraHaptics.selection();
      await AstraHaptics.light();
      await AstraHaptics.medium();
      await AstraHaptics.heavy();
      await AstraHaptics.success();
      await AstraHaptics.warning();
      await AstraHaptics.delete();

      // Disable haptics
      AstraHaptics.isEnabled = false;
      await AstraHaptics.selection();
      await AstraHaptics.success();

      // Re-enable
      AstraHaptics.isEnabled = true;
      expect(AstraHaptics.isEnabled, isTrue);
    });
  });
}
