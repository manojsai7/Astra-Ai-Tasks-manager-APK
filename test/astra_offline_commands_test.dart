import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astra/core/database/database.dart';
import 'package:astra/providers/assistant_provider.dart';
import 'package:astra/providers/b1_classifier_provider.dart';
import 'package:astra/providers/intent_classifier_provider.dart';
import 'package:astra/providers/ritual_provider.dart';
import 'package:astra/services/assistant/astra_temporal_engine.dart';
import 'package:astra/services/ml/b1_event_classifier_client.dart';
import 'package:astra/services/ml/intent_classifier_client.dart';
import 'helpers/test_database_helper.dart';

/// Throwing mock that immediately throws an exception if invoked.
/// Proves that local commands never invoke the FastAPI network client.
class ThrowingIntentClassifierClient extends IntentClassifierClient {
  ThrowingIntentClassifierClient() : super(baseUrl: 'http://127.0.0.1:8000');

  @override
  Future<IntentClassificationResult?> classify(String text) async {
    throw Exception('CRITICAL: Network IntentClassifierClient was invoked when Uvicorn is OFF!');
  }
}

/// Throwing mock for B1 event classifier.
class ThrowingB1EventClassifierClient extends B1EventClassifierClient {
  ThrowingB1EventClassifierClient() : super(baseUrl: 'http://127.0.0.1:8000');

  @override
  Future<B1ClassificationResult?> classify(String text) async {
    throw Exception('CRITICAL: Network B1EventClassifierClient was invoked when Uvicorn is OFF!');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  final refNow = DateTime(2026, 8, 15, 10, 0); // Saturday 10:00 AM

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = TestDatabaseHelper.createMemoryDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  group('ASTRA Phase M2-A: Temporal Engine Hardening Tests', () {
    const temporal = AstraTemporalEngine();

    // B. Next-minute variants
    test('B. Next-minute variants resolve to referenceNow + 1 minute', () {
      final variants = [
        'remind me to drink water in 1 minute',
        'remind me to drink water in next minute',
        'remind me to drink water next minute',
        'remind me to drink water in a minute',
        'remind me to drink water in one minute',
        'remind me to drink water next 1 minute',
        'remind me to drink water after 1 minute',
        'remind me to drink water 1 minute from now',
      ];

      for (final text in variants) {
        final result = temporal.parse(text, now: refNow);
        expect(result.eventStart, equals(DateTime(2026, 8, 15, 10, 1)),
            reason: 'Failed on relative temporal phrase: "$text"');
        expect(result.ambiguous, isFalse);
      }
    });

    // C. Two-minute variants
    test('C. Two-minute variants resolve to referenceNow + 2 minutes', () {
      final variants = [
        'remind me to drink water in 2 mins',
        'remind me to drink water in 2 minutes',
        'remind me to drink water in two minutes',
        'remind me to drink water next 2 minutes',
        'remind me to drink water after 2 minutes',
        'remind me to drink water 2 mins from now',
      ];

      for (final text in variants) {
        final result = temporal.parse(text, now: refNow);
        expect(result.eventStart, equals(DateTime(2026, 8, 15, 10, 2)),
            reason: 'Failed on relative temporal phrase: "$text"');
        expect(result.ambiguous, isFalse);
      }
    });

    // D. Spaced time variants (e.g. 6 20pm, 6 20 pm, 6:20pm, 6:20 pm)
    test('D. Spaced time variants: "6 20pm" must NOT be interpreted as hour=20', () {
      final variants = [
        'gym today at 6:20pm',
        'gym today at 6:20 pm',
        'gym today at 6 20pm',
        'gym today at 6 20 pm',
      ];

      for (final text in variants) {
        final result = temporal.parse(text, now: refNow);
        expect(result.eventStart, equals(DateTime(2026, 8, 15, 18, 20)),
            reason: 'Failed to correctly parse 6:20 PM from: "$text"');
        expect(result.ambiguous, isFalse);
      }
    });

    // E. 24-hour variants
    test('E. 24-hour variants (e.g. 18:20, 18 20)', () {
      final variants = [
        'gym today at 18:20',
        'gym today at 18 20',
      ];

      for (final text in variants) {
        final result = temporal.parse(text, now: refNow);
        expect(result.eventStart, equals(DateTime(2026, 8, 15, 18, 20)),
            reason: 'Failed to correctly parse 24h 18:20 from: "$text"');
        expect(result.ambiguous, isFalse);
      }
    });
  });

  group('ASTRA Phase M2-A: Uvicorn-Independent Local Command Execution Tests', () {
    ProviderContainer createOfflineContainer() {
      return ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          intentClassifierProvider.overrideWithValue(ThrowingIntentClassifierClient()),
          b1EventClassifierProvider.overrideWithValue(ThrowingB1EventClassifierClient()),
        ],
      );
    }

    // A & F. Offline execution with Throwing API clients (no network calls)
    test('A & F. Local commands execute without FastAPI or network calls', () async {
      final container = createOfflineContainer();
      final assistantNotifier = container.read(assistantStateProvider.notifier);

      // 1. "show my tasks" / "list my tasks"
      await assistantNotifier.sendCommand('show my tasks');
      var state = container.read(assistantStateProvider);
      expect(state.messages.last.isUser, isFalse);
      expect(state.messages.last.text, contains('No pending tasks'));

      // 2. "remind me to drink water in 1 minute"
      await assistantNotifier.sendCommand('remind me to drink water in 1 minute');
      state = container.read(assistantStateProvider);
      expect(state.messages.last.isUser, isFalse);
      expect(state.messages.last.text, contains('Drink water'));

      // Verify task and reminder were persisted locally in Drift SQLite
      final tasks = await db.select(db.tasks).get();
      expect(tasks.any((t) => t.title.toLowerCase().contains('drink water')), isTrue);

      // 3. "remind me to drink water in next minute"
      await assistantNotifier.sendCommand('remind me to drink water in next minute');
      state = container.read(assistantStateProvider);
      expect(state.messages.last.isUser, isFalse);
      expect(state.messages.last.text, contains('Drink water'));

      // 4. "remind me to drink water in 2 mins"
      await assistantNotifier.sendCommand('remind me to drink water in 2 mins');
      state = container.read(assistantStateProvider);
      expect(state.messages.last.isUser, isFalse);
      expect(state.messages.last.text, contains('Drink water'));

      // 5. "standup every weekday at 10am"
      await assistantNotifier.sendCommand('standup every weekday at 10am');
      state = container.read(assistantStateProvider);
      expect(state.messages.last.isUser, isFalse);
      expect(state.messages.last.text, contains('Standup'));

      // 6. "Microsoft interview Monday at 11am"
      await assistantNotifier.sendCommand('Microsoft interview Monday at 11am');
      state = container.read(assistantStateProvider);
      expect(state.messages.last.isUser, isFalse);
      expect(state.messages.last.text, contains('Microsoft'));

      // 7. "move my Microsoft interview to tomorrow at 7pm"
      await assistantNotifier.sendCommand('move my Microsoft interview to tomorrow at 7pm');
      state = container.read(assistantStateProvider);
      expect(state.messages.last.isUser, isFalse);
      expect(state.messages.last.text, contains('Task updated'));

      container.dispose();
    });
  });
}
