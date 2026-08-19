import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astra/core/database/database.dart';
import 'package:astra/providers/assistant_provider.dart';
import 'package:astra/providers/b1_classifier_provider.dart';
import 'package:astra/providers/chat_session_provider.dart';
import 'package:astra/providers/intent_classifier_provider.dart';
import 'package:astra/providers/ritual_provider.dart';
import 'package:astra/services/ml/b1_event_classifier_client.dart';
import 'package:astra/services/ml/intent_classifier_client.dart';
import 'helpers/test_database_helper.dart';

/// Throwing mock simulating server / FastAPI completely OFF.
class OfflineIntentClassifierClient extends IntentClassifierClient {
  OfflineIntentClassifierClient() : super(baseUrl: 'http://127.0.0.1:8000');

  @override
  Future<IntentClassificationResult?> classify(String text) async {
    throw Exception('CRITICAL: Network called while Uvicorn is OFF');
  }
}

/// Throwing mock simulating B1 server completely OFF.
class OfflineB1EventClassifierClient extends B1EventClassifierClient {
  OfflineB1EventClassifierClient() : super(baseUrl: 'http://127.0.0.1:8000');

  @override
  Future<B1ClassificationResult?> classify(String text) async {
    throw Exception('CRITICAL: Network called while Uvicorn is OFF');
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

  group('ASTRA Phase M2-C: Live Red-Chip Memory & Multi-Turn Reference Resolution Tests', () {
    // 11. Acceptance Test 1:
    // Message 1: "I have a Microsoft exam tomorrow at 10."
    // Message 2: "make it 11"
    test('11. Acceptance Test 1: "Microsoft exam tomorrow at 10" then "make it 11" updates task to 11:00 AM', () async {
      final container = createOfflineContainer();
      final sessionId = await container.read(chatSessionProvider.notifier).createSession(title: 'Exam Session');
      container.read(currentSessionIdProvider.notifier).state = sessionId;

      final assistant = container.read(assistantStateProvider.notifier);

      // Message 1
      await assistant.sendCommand('I have a Microsoft exam tomorrow at 10');
      var state = container.read(assistantStateProvider);
      expect(state.messages.last.isUser, isFalse);
      expect(state.messages.last.text, contains('Microsoft Exam'));

      // Verify task was created in Drift DB
      var tasks = await db.select(db.tasks).get();
      expect(tasks.length, 1);
      expect(tasks.first.title, 'Microsoft Exam');
      expect(tasks.first.dueAt?.hour, 10);

      // Message 2: "make it 11"
      await assistant.sendCommand('make it 11');
      state = container.read(assistantStateProvider);
      expect(state.messages.last.isUser, isFalse);
      expect(state.messages.last.text, contains('Task updated'));

      // Verify task and reminder were updated to 11:00 AM
      tasks = await db.select(db.tasks).get();
      expect(tasks.length, 1);
      expect(tasks.first.title, 'Microsoft Exam');
      expect(tasks.first.dueAt?.hour, 11);

      final reminders = await db.select(db.reminders).get();
      expect(reminders.length, 1);
      expect(reminders.first.scheduledAt.hour, 11);

      container.dispose();
    });

    // 12. Acceptance Test 2:
    // Message 1: "I have an assignment due Friday."
    // Message 2: "remind me about it Thursday at 8pm"
    test('12. Acceptance Test 2: "assignment due Friday" then "remind me about it Thursday at 8pm"', () async {
      final container = createOfflineContainer();
      final sessionId = await container.read(chatSessionProvider.notifier).createSession(title: 'Assignment Session');
      container.read(currentSessionIdProvider.notifier).state = sessionId;

      final assistant = container.read(assistantStateProvider.notifier);

      // Message 1: Create assignment
      await assistant.sendCommand('I have an assignment due Friday');
      var state = container.read(assistantStateProvider);
      expect(state.messages.last.isUser, isFalse);
      expect(state.messages.last.text, contains('Assignment'));

      // Message 2: "remind me about it Thursday at 8pm"
      await assistant.sendCommand('remind me about it Thursday at 8pm');
      state = container.read(assistantStateProvider);
      expect(state.messages.last.isUser, isFalse);
      expect(state.messages.last.text, contains('Assignment'));

      final reminders = await db.select(db.reminders).get();
      expect(reminders.isNotEmpty, isTrue);
      final lastReminder = reminders.last;
      expect(lastReminder.scheduledAt.hour, 20); // 8:00 PM
      expect(lastReminder.scheduledAt.weekday, DateTime.thursday);

      container.dispose();
    });

    // C. "schedule Microsoft interview tomorrow at 11am" then "make it 2pm"
    test('C. Multi-turn interview: "schedule Microsoft interview tomorrow at 11am" then "make it 2pm"', () async {
      final container = createOfflineContainer();
      final sessionId = await container.read(chatSessionProvider.notifier).createSession(title: 'Interview Session');
      container.read(currentSessionIdProvider.notifier).state = sessionId;

      final assistant = container.read(assistantStateProvider.notifier);

      await assistant.sendCommand('schedule Microsoft interview tomorrow at 11am');
      var state = container.read(assistantStateProvider);
      expect(state.messages.last.isUser, isFalse);
      expect(state.messages.last.text, contains('Microsoft'));

      await assistant.sendCommand('make it 2pm');
      state = container.read(assistantStateProvider);
      expect(state.messages.last.text, contains('Task updated'));

      final tasks = await db.select(db.tasks).get();
      expect(tasks.length, 1);
      expect(tasks.first.dueAt?.hour, 14); // 2:00 PM
      expect(tasks.first.dueAt?.weekday, DateTime.now().add(const Duration(days: 1)).weekday);

      container.dispose();
    });

    // D. Multi-turn Ambiguity: "I have two exams: physics and maths." -> "move the exam to 7pm" -> AMBIGUOUS -> ZERO DB WRITES
    test('D. Ambiguity Protection: "two exams: physics and maths" then "move the exam to 7pm" asks confirmation with zero writes', () async {
      final container = createOfflineContainer();
      final sessionId = await container.read(chatSessionProvider.notifier).createSession(title: 'Ambiguity Session');
      container.read(currentSessionIdProvider.notifier).state = sessionId;

      // Seed two active exam tasks
      await TestDatabaseHelper.insertTaskRow(
        db,
        id: 'task-phys-1',
        title: 'Physics Exam',
        dueAt: DateTime(2026, 8, 17, 9, 0),
        status: 'pending',
      );
      await TestDatabaseHelper.insertTaskRow(
        db,
        id: 'task-math-1',
        title: 'Maths Exam',
        dueAt: DateTime(2026, 8, 18, 9, 0),
        status: 'pending',
      );

      final assistant = container.read(assistantStateProvider.notifier);
      await assistant.sendCommand('move the exam to tomorrow at 7pm');

      final state = container.read(assistantStateProvider);
      expect(state.messages.last.isUser, isFalse);
      expect(state.messages.last.text, contains('Multiple matching tasks'));

      // Invariant: ZERO DB updates occurred
      final tasks = await db.select(db.tasks).get();
      final phys = tasks.firstWhere((t) => t.id == 'task-phys-1');
      final math = tasks.firstWhere((t) => t.id == 'task-math-1');
      expect(phys.dueAt?.hour, 9);
      expect(math.dueAt?.hour, 9);

      container.dispose();
    });

    // 8. Pending Action Completion: "move my exam" -> "tomorrow at 7pm"
    test('8. Pending action completion across turns: "move my exam" then "tomorrow at 7pm"', () async {
      final container = createOfflineContainer();
      final sessionId = await container.read(chatSessionProvider.notifier).createSession(title: 'Pending Session');
      container.read(currentSessionIdProvider.notifier).state = sessionId;

      await TestDatabaseHelper.insertTaskRow(
        db,
        id: 'task-exam-unique',
        title: 'Physics Exam',
        dueAt: DateTime(2026, 8, 17, 9, 0),
        status: 'pending',
      );

      final assistant = container.read(assistantStateProvider.notifier);

      // Turn 1: Incomplete update
      await assistant.sendCommand('move my exam');
      var state = container.read(assistantStateProvider);
      expect(state.messages.last.isUser, isFalse);

      // Turn 2: Provide missing time
      await assistant.sendCommand('tomorrow at 7pm');
      state = container.read(assistantStateProvider);
      expect(state.messages.last.isUser, isFalse);
      expect(state.messages.last.text, contains('Task updated'));

      final tasks = await db.select(db.tasks).get();
      final exam = tasks.firstWhere((t) => t.id == 'task-exam-unique');
      expect(exam.dueAt?.hour, 19); // 7:00 PM

      container.dispose();
    });
  });
}
