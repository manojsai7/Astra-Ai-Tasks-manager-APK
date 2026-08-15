import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astra/core/time/astra_time_service.dart';
import 'package:astra/providers/b1_classifier_provider.dart';
import 'package:astra/providers/intent_classifier_provider.dart';
import 'package:astra/providers/assistant_provider.dart';
import 'package:astra/providers/astra_intent_resolver_provider.dart';
import 'package:astra/providers/astra_routing_policy_provider.dart';
import 'package:astra/providers/astra_semantic_engine_provider.dart';
import 'package:astra/providers/ritual_provider.dart';
import 'package:astra/providers/task_provider.dart';
import 'package:astra/providers/reminder_provider.dart';
import 'package:astra/services/ml/intent_classifier_client.dart';
import 'package:astra/services/ml/b1_event_classifier_client.dart';
import 'package:astra/services/reminder_service.dart';
import 'helpers/test_database_helper.dart';
import 'helpers/test_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Phase 2X-5 End-to-End Real Smoke Diagnostics: "Microsoft interview Monday at 11am"', () async {
    SharedPreferences.setMockInitialValues({});
    final db = TestDatabaseHelper.createMemoryDatabase();

    // Fix reference time to Saturday, Aug 15, 2026, 18:00
    final refTime = DateTime(2026, 8, 15, 18, 0);
    final clock = SettableTestClock(refTime);
    final timeService = AstraTimeService(clock: clock);

    final fakeIntentClient = FakeIntentClassifierClient()
      ..nextResult = const IntentClassificationResult(
        intent: 'CREATE_CALENDAR_EVENT',
        confidence: 0.98,
        topPredictions: [
          IntentPrediction(intent: 'CREATE_CALENDAR_EVENT', confidence: 0.98),
        ],
      );

    final fakeB1Client = FakeB1EventClassifierClient()
      ..nextResult = const B1ClassificationResult(
        eventType: 'INTERVIEW',
        confidence: 0.98,
        topPredictions: [
          B1Prediction(eventType: 'INTERVIEW', confidence: 0.98),
        ],
      );

    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        reminderServiceProvider.overrideWithValue(ReminderService(db, timeService: timeService)),
        taskNotifierProvider.overrideWith((ref) => TaskNotifier(db, ReminderService(db, timeService: timeService))..loadTasks()),
        intentClassifierProvider.overrideWithValue(fakeIntentClient),
        b1EventClassifierProvider.overrideWithValue(fakeB1Client),
      ],
    );

    const text = 'Microsoft interview Monday at 11am';

    // 1. Set A Intent Resolver Check
    final intentResolver = container.read(astraIntentResolverProvider);
    final resolvedIntent = intentResolver.resolve(
      text: text,
      ml: const IntentClassificationResult(
        intent: 'CREATE_CALENDAR_EVENT',
        confidence: 0.96,
        topPredictions: [
          IntentPrediction(intent: 'CREATE_CALENDAR_EVENT', confidence: 0.96),
        ],
      ),
    );

    expect(resolvedIntent.intent, 'CREATE_CALENDAR_EVENT');

    // 2. Routing Policy Check
    final routingPolicy = container.read(astraRoutingPolicyProvider);
    final routingDecision = routingPolicy.decide(
      resolvedIntent.intent,
      text: text,
    );

    expect(routingDecision.requiresEventClassification, isTrue);

    // 3. Set B & Semantic Engine Check
    final semanticEngine = container.read(astraSemanticEngineProvider);
    final semanticCommand = semanticEngine.resolve(
      text: text,
      intent: resolvedIntent.intent,
      b1: const B1ClassificationResult(
        eventType: 'INTERVIEW',
        confidence: 0.98,
        topPredictions: [
          B1Prediction(eventType: 'INTERVIEW', confidence: 0.98),
        ],
      ),
      now: refTime,
    );

    expect(semanticCommand.intent, 'CREATE_CALENDAR_EVENT');
    expect(semanticCommand.eventType, 'INTERVIEW');
    expect(semanticCommand.title, 'Microsoft Interview');
    expect(semanticCommand.organization, 'Microsoft');
    expect(semanticCommand.action, 'ATTEND');

    // 4. Temporal Check: Monday Aug 17, 2026 at 11:00 AM
    expect(semanticCommand.temporal.eventStart, DateTime(2026, 8, 17, 11, 0));
    expect(semanticCommand.temporal.timezone, 'Asia/Kolkata');
    expect(semanticCommand.route, 'EXECUTE');

    // 5. Assistant Provider Execution Check
    final assistantNotifier = container.read(assistantStateProvider.notifier);
    await assistantNotifier.sendCommand(text);

    final state = container.read(assistantStateProvider);
    expect(state.messages.isNotEmpty, isTrue);
    final assistantMsg = state.messages.last;
    expect(assistantMsg.text, contains('Microsoft Interview'));

    // 6. DB Verification
    final tasks = await db.select(db.tasks).get();
    expect(tasks.length, 1);
    expect(tasks.first.title, 'Microsoft Interview');
    expect(tasks.first.organization, 'Microsoft');
    expect(tasks.first.dueAt, DateTime(2026, 8, 17, 11, 0));

    final reminders = await db.select(db.reminders).get();
    expect(reminders.length, 1);
    expect(reminders.first.scheduledAt, DateTime(2026, 8, 17, 11, 0));

    await db.close();
    container.dispose();
  });
}
