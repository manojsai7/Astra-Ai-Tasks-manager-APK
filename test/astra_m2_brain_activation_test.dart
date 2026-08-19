import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/drift.dart' as drift;

import 'package:astra/core/database/database.dart';
import 'package:astra/providers/assistant_provider.dart';
import 'package:astra/providers/b1_classifier_provider.dart';
import 'package:astra/providers/chat_session_provider.dart';
import 'package:astra/providers/intent_classifier_provider.dart';
import 'package:astra/providers/ritual_provider.dart';
import 'package:astra/providers/astra_memory_provider.dart';
import 'package:astra/services/assistant/astra_context_builder.dart';
import 'package:astra/services/assistant/astra_reference_resolver.dart';
import 'package:astra/services/assistant/astra_memory_engine.dart';
import 'package:astra/services/ml/b1_event_classifier_client.dart';
import 'package:astra/services/ml/intent_classifier_client.dart';
import 'helpers/test_database_helper.dart';

/// Throwing mock simulating server / FastAPI completely OFF.
class OfflineIntentClassifierClient extends IntentClassifierClient {
  OfflineIntentClassifierClient() : super(baseUrl: 'http://127.0.0.1:8000');

  @override
  Future<IntentClassificationResult?> classify(String text) async {
    throw Exception('CRITICAL: Network called while Uvicorn / ML API is OFF');
  }
}

/// Throwing mock simulating B1 server completely OFF.
class OfflineB1EventClassifierClient extends B1EventClassifierClient {
  OfflineB1EventClassifierClient() : super(baseUrl: 'http://127.0.0.1:8000');

  @override
  Future<B1ClassificationResult?> classify(String text) async {
    throw Exception('CRITICAL: Network called while Uvicorn / ML API is OFF');
  }
}

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

  ProviderContainer createOfflineContainer() {
    return ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        intentClassifierProvider.overrideWithValue(OfflineIntentClassifierClient()),
        b1EventClassifierProvider.overrideWithValue(OfflineB1EventClassifierClient()),
      ],
    );
  }

  group('ASTRA M2 — Local Brain Activation & Conversation Pipeline Tests (A–M)', () {
    // ─── A. Local Context Retrieval ──────────────────────────────────────────
    test('A. Local Context Retrieval builds bounded context with active tasks and messages', () async {
      final memoryEngine = AstraMemoryEngine(db);
      final builder = AstraContextBuilder(db: db, memoryEngine: memoryEngine);

      // Seed a session with 2 messages
      final now = DateTime.now();
      final sessionId = await db.into(db.chatSessions).insert(
        ChatSessionsCompanion(
          title: const drift.Value('Test Session'),
          createdAt: drift.Value(now),
          updatedAt: drift.Value(now),
        ),
      );

      await db.into(db.chatMessages).insert(
        ChatMessagesCompanion(
          sessionId: drift.Value(sessionId),
          role: const drift.Value('user'),
          content: const drift.Value('I have a Google meeting tomorrow at 3pm'),
          timestamp: drift.Value(now),
        ),
      );
      await db.into(db.chatMessages).insert(
        ChatMessagesCompanion(
          sessionId: drift.Value(sessionId),
          role: const drift.Value('assistant'),
          content: const drift.Value('Created Google Meeting for tomorrow at 3:00 PM.'),
          timestamp: drift.Value(now),
        ),
      );

      // Seed an active task
      await TestDatabaseHelper.insertTaskRow(
        db,
        id: 't-google-1',
        title: 'Google Meeting',
        dueAt: DateTime.now().add(const Duration(days: 1)),
        status: 'active',
      );

      final context = await builder.buildContext(
        currentText: 'make it 4pm',
        sessionId: sessionId,
      );

      expect(context.recentMessages.length, 2);
      expect(context.activeTasks.length, 1);
      expect(context.activeTasks.first.title, 'Google Meeting');
      expect(context.sessionId, sessionId);
    });

    // ─── B. Local Reference "it" ─────────────────────────────────────────────
    test('B. Local Reference "it" resolves to most recent conversation entity', () async {
      final memoryEngine = AstraMemoryEngine(db);
      final builder = AstraContextBuilder(db: db, memoryEngine: memoryEngine);
      const resolver = AstraReferenceResolver();

      final now = DateTime.now();
      final sessionId = await db.into(db.chatSessions).insert(
        ChatSessionsCompanion(
          title: const drift.Value('Exam Session'),
          createdAt: drift.Value(now),
          updatedAt: drift.Value(now),
        ),
      );

      await db.into(db.chatMessages).insert(
        ChatMessagesCompanion(
          sessionId: drift.Value(sessionId),
          role: const drift.Value('user'),
          content: const drift.Value('I have a Microsoft exam tomorrow at 10'),
          timestamp: drift.Value(now),
        ),
      );

      await TestDatabaseHelper.insertTaskRow(
        db,
        id: 't-msft-exam',
        title: 'Microsoft Exam',
        dueAt: DateTime.now().add(const Duration(days: 1)),
        status: 'active',
      );

      final context = await builder.buildContext(
        currentText: 'make it 11',
        sessionId: sessionId,
      );

      final result = resolver.resolveReference('make it 11', context);
      expect(result.isResolved, isTrue);
      expect(result.resolvedTitle, 'Microsoft Exam');
      expect(result.resolvedTaskId, 't-msft-exam');
      expect(result.confidence, greaterThanOrEqualTo(0.90));
    });

    // ─── C. Local Reference "the exam" ───────────────────────────────────────
    test('C. Local Reference "the exam" resolves to active task matching title', () async {
      final memoryEngine = AstraMemoryEngine(db);
      final builder = AstraContextBuilder(db: db, memoryEngine: memoryEngine);
      const resolver = AstraReferenceResolver();

      await TestDatabaseHelper.insertTaskRow(
        db,
        id: 't-math-exam',
        title: 'Math Exam',
        dueAt: DateTime.now().add(const Duration(days: 1)),
        status: 'active',
      );

      final context = await builder.buildContext(currentText: 'move the exam to 5pm');
      final result = resolver.resolveReference('move the exam to 5pm', context);

      expect(result.isResolved, isTrue);
      expect(result.resolvedTitle, 'Math Exam');
      expect(result.resolvedTaskId, 't-math-exam');
    });

    // ─── D. Organization Reference ("the Microsoft one") ─────────────────────
    test('D. Organization reference "the Microsoft one" resolves correctly', () async {
      final memoryEngine = AstraMemoryEngine(db);
      final builder = AstraContextBuilder(db: db, memoryEngine: memoryEngine);
      const resolver = AstraReferenceResolver();

      await TestDatabaseHelper.insertTaskRow(
        db,
        id: 't-ms-interview',
        title: 'Technical Interview',
        organization: 'Microsoft',
        dueAt: DateTime.now().add(const Duration(days: 2)),
        status: 'active',
      );
      await TestDatabaseHelper.insertTaskRow(
        db,
        id: 't-amz-interview',
        title: 'Behavioral Interview',
        organization: 'Amazon',
        dueAt: DateTime.now().add(const Duration(days: 3)),
        status: 'active',
      );

      final context = await builder.buildContext(currentText: 'reschedule the Microsoft one to 3pm');
      final result = resolver.resolveReference('reschedule the Microsoft one to 3pm', context);

      expect(result.isResolved, isTrue);
      expect(result.resolvedTitle, 'Technical Interview');
      expect(result.resolvedTaskId, 't-ms-interview');
    });

    // ─── E. Ambiguous Reference ──────────────────────────────────────────────
    test('E. Ambiguous reference returns unresolved without guessing', () async {
      final memoryEngine = AstraMemoryEngine(db);
      final builder = AstraContextBuilder(db: db, memoryEngine: memoryEngine);
      const resolver = AstraReferenceResolver();

      await TestDatabaseHelper.insertTaskRow(
        db,
        id: 't-exam-1',
        title: 'Physics Exam',
        status: 'active',
      );
      await TestDatabaseHelper.insertTaskRow(
        db,
        id: 't-exam-2',
        title: 'Chemistry Exam',
        status: 'active',
      );

      final context = await builder.buildContext(currentText: 'move the exam to 7pm');
      final result = resolver.resolveReference('move the exam to 7pm', context);

      expect(result.isResolved, isFalse);
      expect(result.reason, contains('Ambiguous'));
    });

    // ─── F. Unresolved Reference ─────────────────────────────────────────────
    test('F. Unresolved reference for unknown item returns clean unresolved status', () async {
      final memoryEngine = AstraMemoryEngine(db);
      final builder = AstraContextBuilder(db: db, memoryEngine: memoryEngine);
      const resolver = AstraReferenceResolver();

      final context = await builder.buildContext(currentText: 'reschedule the dentist appointment to 4pm');
      final result = resolver.resolveReference('reschedule the dentist appointment to 4pm', context);

      expect(result.isResolved, isFalse);
    });

    // ─── G. Conversation → UPDATE_TASK ───────────────────────────────────────
    test('G. Multi-turn conversation updates task without duplicate row', () async {
      final container = createOfflineContainer();
      final sessionId = await container.read(chatSessionProvider.notifier).createSession(title: 'Update Flow');
      container.read(currentSessionIdProvider.notifier).state = sessionId;

      final assistant = container.read(assistantStateProvider.notifier);

      // Turn 1: Create Microsoft interview
      await assistant.sendCommand('I have a Microsoft interview tomorrow at 10');
      var state = container.read(assistantStateProvider);
      expect(state.messages.last.isUser, isFalse);
      expect(state.messages.last.text, contains('Microsoft'));

      var tasks = await db.select(db.tasks).get();
      expect(tasks.length, 1);
      expect(tasks.first.dueAt?.hour, 10);

      // Turn 2: "Actually make it 2pm"
      await assistant.sendCommand('Actually make it 2pm');
      state = container.read(assistantStateProvider);
      expect(state.messages.last.isUser, isFalse);
      expect(state.messages.last.text, contains('Task updated'));

      tasks = await db.select(db.tasks).get();
      expect(tasks.length, 1);
      expect(tasks.first.dueAt?.hour, 14); // 2:00 PM

      container.dispose();
    });

    // ─── H. Conversation → CREATE_REMINDER ───────────────────────────────────
    test('H. Multi-turn conversation links reminder to existing task entity', () async {
      final container = createOfflineContainer();
      final sessionId = await container.read(chatSessionProvider.notifier).createSession(title: 'Reminder Flow');
      container.read(currentSessionIdProvider.notifier).state = sessionId;

      final assistant = container.read(assistantStateProvider.notifier);

      // Turn 1: Create Assignment
      await assistant.sendCommand('I have an assignment due Friday');
      var state = container.read(assistantStateProvider);
      expect(state.messages.last.isUser, isFalse);

      var tasks = await db.select(db.tasks).get();
      expect(tasks.length, 1);
      final initialTaskId = tasks.first.id;

      // Turn 2: "remind me about it Thursday at 8pm"
      await assistant.sendCommand('remind me about it Thursday at 8pm');
      state = container.read(assistantStateProvider);
      expect(state.messages.last.isUser, isFalse);

      // Verify no duplicate task was inserted
      tasks = await db.select(db.tasks).get();
      expect(tasks.length, 1);
      expect(tasks.first.id, initialTaskId);

      // Verify reminder exists linked to the same task
      final reminders = await db.select(db.reminders).get();
      expect(reminders.isNotEmpty, isTrue);
      expect(reminders.last.taskId, initialTaskId);
      expect(reminders.last.scheduledAt.hour, 20);

      container.dispose();
    });

    // ─── I. No Duplicate Task on Follow-up ────────────────────────────────────
    test('I. Follow-up commands do not spawn duplicate tasks', () async {
      final container = createOfflineContainer();
      final sessionId = await container.read(chatSessionProvider.notifier).createSession(title: 'No Dupes');
      container.read(currentSessionIdProvider.notifier).state = sessionId;

      final assistant = container.read(assistantStateProvider.notifier);

      await assistant.sendCommand('I have a project meeting tomorrow at 9am');
      await assistant.sendCommand('make it 11am');
      await assistant.sendCommand('make it 4pm');

      final tasks = await db.select(db.tasks).get();
      expect(tasks.length, 1);
      expect(tasks.first.dueAt?.hour, 16); // 4:00 PM

      container.dispose();
    });

    // ─── J. Existing Reminder Gets Rescheduled ────────────────────────────────
    test('J. Existing reminder gets updated on time mutation', () async {
      final container = createOfflineContainer();
      final sessionId = await container.read(chatSessionProvider.notifier).createSession(title: 'Reschedule');
      container.read(currentSessionIdProvider.notifier).state = sessionId;

      final assistant = container.read(assistantStateProvider.notifier);

      await assistant.sendCommand('I have a lab exam tomorrow at 8am');
      await assistant.sendCommand('make it 10am');

      final reminders = await db.select(db.reminders).get();
      expect(reminders.length, 1);
      expect(reminders.first.scheduledAt.hour, 10);

      container.dispose();
    });

    // ─── K. API Unavailable but Deterministic Command Succeeds ───────────────
    test('K. 100% offline execution without LLM or FastAPI', () async {
      final container = createOfflineContainer();
      final assistant = container.read(assistantStateProvider.notifier);

      // All of these MUST succeed locally with Offline classifier mocks throwing
      await assistant.sendCommand('I have a doctor appointment tomorrow at 11am');
      await assistant.sendCommand('list my tasks');
      await assistant.sendCommand('complete doctor appointment');

      final tasks = await db.select(db.tasks).get();
      expect(tasks.length, 1);
      expect(tasks.first.status, 'completed');

      container.dispose();
    });

    // ─── L. Memory Write-Back ────────────────────────────────────────────────
    test('L. Structured working memory writes back understood entities', () async {
      final container = createOfflineContainer();
      final memoryEngine = container.read(astraMemoryEngineProvider);
      final sessionId = await container.read(chatSessionProvider.notifier).createSession(title: 'Memory Writeback');
      container.read(currentSessionIdProvider.notifier).state = sessionId;

      final assistant = container.read(assistantStateProvider.notifier);

      await assistant.sendCommand('I have a Microsoft exam tomorrow at 10');

      final memories = memoryEngine.getAllWorkingMemories();
      expect(memories.isNotEmpty, isTrue);
      expect(memories.any((m) => m.value.contains('Microsoft Exam')), isTrue);

      container.dispose();
    });

    // ─── M. Session Isolation ────────────────────────────────────────────────
    test('M. Session messages remain isolated per session', () async {
      final container = createOfflineContainer();
      final sessionNotifier = container.read(chatSessionProvider.notifier);

      final s1 = await sessionNotifier.createSession(title: 'Session 1');
      final s2 = await sessionNotifier.createSession(title: 'Session 2');

      await sessionNotifier.addMessage(s1, 'user', 'Message in S1');
      await sessionNotifier.addMessage(s2, 'user', 'Message in S2');

      final s1Msgs = await sessionNotifier.getMessages(s1);
      final s2Msgs = await sessionNotifier.getMessages(s2);

      expect(s1Msgs.length, 1);
      expect(s1Msgs.first.content, 'Message in S1');
      expect(s2Msgs.length, 1);
      expect(s2Msgs.first.content, 'Message in S2');

      container.dispose();
    });

    // ─── END-TO-END ACCEPTANCE TESTS ─────────────────────────────────────────
    test('E2E-1: "I have a Microsoft exam tomorrow at 10" -> "make it 11" -> same task updated to 11 with 1 reminder', () async {
      final container = createOfflineContainer();
      final sessionId = await container.read(chatSessionProvider.notifier).createSession(title: 'E2E 1');
      container.read(currentSessionIdProvider.notifier).state = sessionId;

      final assistant = container.read(assistantStateProvider.notifier);

      // Turn 1
      await assistant.sendCommand('I have a Microsoft exam tomorrow at 10');
      var state = container.read(assistantStateProvider);
      expect(state.messages.last.isUser, isFalse);
      expect(state.messages.last.text, contains('Microsoft Exam'));

      // Turn 2
      await assistant.sendCommand('make it 11');
      state = container.read(assistantStateProvider);
      expect(state.messages.last.isUser, isFalse);
      expect(state.messages.last.text, contains('Task updated'));

      // Exact verification
      final tasks = await db.select(db.tasks).get();
      expect(tasks.length, 1);
      expect(tasks.first.title, 'Microsoft Exam');
      expect(tasks.first.dueAt?.hour, 11);

      final reminders = await db.select(db.reminders).get();
      expect(reminders.length, 1);
      expect(reminders.first.scheduledAt.hour, 11);

      container.dispose();
    });

    test('E2E-2: "I have an assignment due Friday" -> "remind me about it Thursday at 8pm" -> 1 task, linked reminder', () async {
      final container = createOfflineContainer();
      final sessionId = await container.read(chatSessionProvider.notifier).createSession(title: 'E2E 2');
      container.read(currentSessionIdProvider.notifier).state = sessionId;

      final assistant = container.read(assistantStateProvider.notifier);

      // Turn 1
      await assistant.sendCommand('I have an assignment due Friday');
      var state = container.read(assistantStateProvider);
      expect(state.messages.last.isUser, isFalse);
      expect(state.messages.last.text, contains('Assignment'));

      // Turn 2
      await assistant.sendCommand('remind me about it Thursday at 8pm');
      state = container.read(assistantStateProvider);
      expect(state.messages.last.isUser, isFalse);

      // Exact verification
      final tasks = await db.select(db.tasks).get();
      expect(tasks.length, 1);
      expect(tasks.first.title, 'Assignment');

      final reminders = await db.select(db.reminders).get();
      expect(reminders.isNotEmpty, isTrue);
      expect(reminders.last.taskId, tasks.first.id);
      expect(reminders.last.scheduledAt.hour, 20); // 8:00 PM

      container.dispose();
    });
  });
}
