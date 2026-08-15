import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astra/core/database/database.dart';
import 'package:astra/providers/assistant_provider.dart';
import 'package:astra/providers/ritual_provider.dart';
import 'package:astra/providers/task_provider.dart';
import 'package:astra/providers/reminder_provider.dart';
import 'package:astra/services/reminder_service.dart';
import 'package:astra/services/ml/intent_classifier_client.dart';
import 'package:astra/services/ml/b1_event_classifier_client.dart';
import 'package:astra/providers/intent_classifier_provider.dart';
import 'package:astra/providers/b1_classifier_provider.dart';
import 'package:astra/core/time/astra_time_service.dart';
import 'helpers/test_database_helper.dart';
import 'helpers/test_fakes.dart';

// Mock ML clients reflecting actual FastAPI Set A & Set B endpoint behaviors for the 7 smoke scenarios
class MockIntentClassifierClient extends Fake implements IntentClassifierClient {
  @override
  Future<IntentClassificationResult?> classify(String text) async {
    final t = text.toLowerCase();
    if (t.contains('remind me to drink water')) {
      return const IntentClassificationResult(
        intent: 'CREATE_REMINDER',
        confidence: 0.997,
        topPredictions: [IntentPrediction(intent: 'CREATE_REMINDER', confidence: 0.997)],
      );
    }
    if (t.contains('exam today at 6pm')) {
      return const IntentClassificationResult(
        intent: 'CREATE_TASK',
        confidence: 0.884,
        topPredictions: [IntentPrediction(intent: 'CREATE_TASK', confidence: 0.884)],
      );
    }
    if (t.contains('microsoft interview')) {
      return const IntentClassificationResult(
        intent: 'CREATE_CALENDAR_EVENT',
        confidence: 0.912,
        topPredictions: [IntentPrediction(intent: 'CREATE_CALENDAR_EVENT', confidence: 0.912)],
      );
    }
    if (t.contains('submit assignment')) {
      return const IntentClassificationResult(
        intent: 'CREATE_TASK',
        confidence: 0.920,
        topPredictions: [IntentPrediction(intent: 'CREATE_TASK', confidence: 0.920)],
      );
    }
    if (t.contains('fill the nptel form')) {
      return const IntentClassificationResult(
        intent: 'CREATE_TASK',
        confidence: 0.890,
        topPredictions: [IntentPrediction(intent: 'CREATE_TASK', confidence: 0.890)],
      );
    }
    if (t.contains('sync my emails')) {
      return const IntentClassificationResult(
        intent: 'SYNC_EMAIL',
        confidence: 0.972,
        topPredictions: [IntentPrediction(intent: 'SYNC_EMAIL', confidence: 0.972)],
      );
    }
    if (t.contains('show me my tasks')) {
      return const IntentClassificationResult(
        intent: 'LIST_TASKS',
        confidence: 0.987,
        topPredictions: [IntentPrediction(intent: 'LIST_TASKS', confidence: 0.987)],
      );
    }
    return const IntentClassificationResult(
      intent: 'GENERAL_CHAT',
      confidence: 0.50,
      topPredictions: [],
    );
  }
}

class MockB1EventClassifierClient extends Fake implements B1EventClassifierClient {
  @override
  Future<B1ClassificationResult?> classify(String text) async {
    final t = text.toLowerCase();
    if (t.contains('exam')) {
      return const B1ClassificationResult(
        eventType: 'EXAM',
        confidence: 0.166,
        topPredictions: [B1Prediction(eventType: 'EXAM', confidence: 0.166)],
      );
    }
    if (t.contains('interview')) {
      return const B1ClassificationResult(
        eventType: 'INTERVIEW',
        confidence: 0.336,
        topPredictions: [B1Prediction(eventType: 'INTERVIEW', confidence: 0.336)],
      );
    }
    if (t.contains('assignment')) {
      return const B1ClassificationResult(
        eventType: 'ASSIGNMENT',
        confidence: 0.650,
        topPredictions: [B1Prediction(eventType: 'ASSIGNMENT', confidence: 0.650)],
      );
    }
    if (t.contains('form')) {
      return const B1ClassificationResult(
        eventType: 'FORM',
        confidence: 0.743,
        topPredictions: [B1Prediction(eventType: 'FORM', confidence: 0.743)],
      );
    }
    return const B1ClassificationResult(
      eventType: 'OTHER',
      confidence: 0.50,
      topPredictions: [],
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late AppDatabase testDb;
  late SettableTestClock testClock;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    testDb = TestDatabaseHelper.createMemoryDatabase();
    // Reference morning time: 9:00 AM on Aug 15, 2026
    testClock = SettableTestClock(DateTime(2026, 8, 15, 9, 0));
    final timeService = AstraTimeService(clock: testClock);

    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(testDb),
        reminderServiceProvider.overrideWithValue(ReminderService(testDb, timeService: timeService)),
        taskNotifierProvider.overrideWith((ref) => TaskNotifier(testDb, ReminderService(testDb, timeService: timeService))..loadTasks()),
        intentClassifierProvider.overrideWithValue(MockIntentClassifierClient()),
        b1EventClassifierProvider.overrideWithValue(MockB1EventClassifierClient()),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await testDb.close();
  });

  group('Phase 2U Smoke Tests', () {
    test('1. "remind me to drink water in 2 mins" -> exactly 1 task, 1 reminder, ~+2min', () async {
      final assistant = container.read(assistantStateProvider.notifier);
      await assistant.sendCommand('remind me to drink water in 2 mins');

      final tasks = await testDb.select(testDb.tasks).get();
      expect(tasks.length, 1);
      final task = tasks.first;
      expect(task.title, 'Drink water');
      expect(task.dueAt, isNotNull);
      expect(task.dueAt!.difference(testClock.now()).inSeconds, inInclusiveRange(60, 180));

      final reminders = await testDb.select(testDb.reminders).get();
      expect(reminders.length, 1);
      expect(reminders.first.taskId, task.id);
    });

    test('2. "bruh i have exam today at 6pm" -> exactly 1 task, title Exam, 18:00 today, 1 reminder', () async {
      final assistant = container.read(assistantStateProvider.notifier);
      await assistant.sendCommand('bruh i have exam today at 6pm');

      final tasks = await testDb.select(testDb.tasks).get();
      expect(tasks.length, 1);
      final task = tasks.first;
      expect(task.title, 'Exam');
      expect(task.dueAt, isNotNull);
      expect(task.dueAt!.hour, 18);
      expect(task.dueAt!.minute, 0);

      final reminders = await testDb.select(testDb.reminders).get();
      expect(reminders.length, 1);
      expect(reminders.first.taskId, task.id);
    });

    test('3. "Microsoft interview Monday at 11am" -> exactly 1 task, Microsoft Interview, Monday 11am', () async {
      final assistant = container.read(assistantStateProvider.notifier);
      await assistant.sendCommand('Microsoft interview Monday at 11am');

      final tasks = await testDb.select(testDb.tasks).get();
      expect(tasks.length, 1);
      final task = tasks.first;
      expect(task.title, 'Microsoft Interview');
      expect(task.organization, 'Microsoft');
      expect(task.dueAt, isNotNull);
      expect(task.dueAt!.hour, 11);
      expect(task.dueAt!.minute, 0);

      final reminders = await testDb.select(testDb.reminders).get();
      expect(reminders.length, 1);
      expect(reminders.first.taskId, task.id);
    });

    test('4. "submit assignment tomorrow by 5" -> MUST NOT insert a task, confirmation required', () async {
      final assistant = container.read(assistantStateProvider.notifier);
      await assistant.sendCommand('submit assignment tomorrow by 5');

      final tasks = await testDb.select(testDb.tasks).get();
      expect(tasks.isEmpty, true, reason: 'Ambiguous time should NOT write to DB');

      final reminders = await testDb.select(testDb.reminders).get();
      expect(reminders.isEmpty, true);

      final state = container.read(assistantStateProvider);
      expect(state.messages.last.structured?.headline, 'Please confirm details');
    });

    test('5. "fill the NPTEL form before 4pm" -> MUST NOT insert a task (missing date)', () async {
      final assistant = container.read(assistantStateProvider.notifier);
      await assistant.sendCommand('fill the NPTEL form before 4pm');

      final tasks = await testDb.select(testDb.tasks).get();
      expect(tasks.isEmpty, true, reason: 'Missing date deadline should NOT write to DB');

      final reminders = await testDb.select(testDb.reminders).get();
      expect(reminders.isEmpty, true);
    });

    test('6. "sync my emails" -> MUST NOT create a task, direct sync operation', () async {
      final assistant = container.read(assistantStateProvider.notifier);
      await assistant.sendCommand('sync my emails');

      final tasks = await testDb.select(testDb.tasks).get();
      expect(tasks.isEmpty, true);
    });

    test('7. "show me my tasks" -> MUST NOT create a task, reads tasks', () async {
      final assistant = container.read(assistantStateProvider.notifier);
      await assistant.sendCommand('show me my tasks');

      final tasks = await testDb.select(testDb.tasks).get();
      expect(tasks.isEmpty, true);
      final state = container.read(assistantStateProvider);
      expect(state.messages.last.structured?.headline, isNotNull);
    });

    test('8. "standup every weekday at 10am" -> creates 1 recurring task, title Standup, 1 reminder', () async {
      final assistant = container.read(assistantStateProvider.notifier);
      await assistant.sendCommand('standup every weekday at 10am');

      final tasks = await testDb.select(testDb.tasks).get();
      expect(tasks.length, 1);
      final task = tasks.first;
      expect(task.title, 'Standup');
      expect(task.recurrenceRuleJson, isNotNull);
      expect(task.recurrenceRuleJson, contains('WEEKDAYS'));

      final reminders = await testDb.select(testDb.reminders).get();
      expect(reminders.length, 1);
      expect(reminders.first.taskId, task.id);
    });
  });
}
