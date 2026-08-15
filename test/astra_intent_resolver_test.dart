import 'package:flutter_test/flutter_test.dart';

import 'package:astra/services/assistant/astra_intent_resolver.dart';
import 'package:astra/services/ml/intent_classifier_client.dart';

void main() {
  const resolver = AstraIntentResolver();

  test('email refresh resolves to SYNC_EMAIL', () {
    final result = resolver.resolve(
      text: 'update inbox',
      ml: const IntentClassificationResult(
        intent: 'UPDATE_TASK',
        confidence: 0.70,
        topPredictions: [],
      ),
    );

    expect(result.intent, 'SYNC_EMAIL');
  });

  test('reminder phrase resolves to CREATE_REMINDER', () {
    final result = resolver.resolve(
      text: 'remind me to drink water in 2 mins',
      ml: const IntentClassificationResult(
        intent: 'CREATE_REMINDER',
        confidence: 0.99,
        topPredictions: [],
      ),
    );

    expect(result.intent, 'CREATE_REMINDER');
  });

  test('task listing resolves to LIST_TASKS', () {
    final result = resolver.resolve(
      text: 'show me my tasks',
      ml: const IntentClassificationResult(
        intent: 'LIST_TASKS',
        confidence: 0.98,
        topPredictions: [],
      ),
    );

    expect(result.intent, 'LIST_TASKS');
  });

  test('calendar creation beats calendar query', () {
    final result = resolver.resolve(
      text: 'schedule a meeting tomorrow',
      ml: const IntentClassificationResult(
        intent: 'CREATE_CALENDAR_EVENT',
        confidence: 0.90,
        topPredictions: [],
      ),
    );

    expect(
      result.intent,
      'CREATE_CALENDAR_EVENT',
    );
  });

  test('low-confidence ML fallback survives', () {
    final result = resolver.resolve(
      text: 'some unusual phrase',
      ml: const IntentClassificationResult(
        intent: 'GENERAL_CHAT',
        confidence: 0.30,
        topPredictions: [],
      ),
    );

    expect(result.intent, 'GENERAL_CHAT');
  });

  test('refresh inbox resolves to SYNC_EMAIL', () {
    final result = resolver.resolve(
      text: 'refresh inbox',
      ml: const IntentClassificationResult(
        intent: 'UPDATE_TASK',
        confidence: 0.70,
        topPredictions: [],
      ),
    );

    expect(result.intent, 'SYNC_EMAIL');
  });

  test('get my latest emails does not force SYNC_EMAIL', () {
    final result = resolver.resolve(
      text: 'get my latest emails',
      ml: const IntentClassificationResult(
        intent: 'SEARCH_EMAIL',
        confidence: 0.70,
        topPredictions: [],
      ),
    );

    expect(result.intent, 'SEARCH_EMAIL');
  });

  test('summarize my emails does not force SYNC_EMAIL', () {
    final result = resolver.resolve(
      text: 'summarize my emails',
      ml: const IntentClassificationResult(
        intent: 'SUMMARIZE_EMAIL',
        confidence: 0.90,
        topPredictions: [],
      ),
    );

    expect(result.intent, 'SUMMARIZE_EMAIL');
  });

  test('panchang queries resolve to GET_PANCHANG', () {
    final result = resolver.resolve(
      text: 'when is ekadashi',
      ml: const IntentClassificationResult(
        intent: 'GET_PANCHANG',
        confidence: 0.95,
        topPredictions: [],
      ),
    );

    expect(result.intent, 'GET_PANCHANG');
  });

  test('meeting query resolves to GET_CALENDAR', () {
    final result = resolver.resolve(
      text: 'what is my next meeting',
      ml: const IntentClassificationResult(
        intent: 'GET_CALENDAR',
        confidence: 0.95,
        topPredictions: [],
      ),
    );

    expect(result.intent, 'GET_CALENDAR');
  });

  test('greeting resolves to GENERAL_CHAT', () {
    final result = resolver.resolve(
      text: 'hi',
      ml: const IntentClassificationResult(
        intent: 'GENERAL_CHAT',
        confidence: 0.99,
        topPredictions: [],
      ),
    );

    expect(result.intent, 'GENERAL_CHAT');
  });

  test('completion phrase resolves to COMPLETE_TASK', () {
    final result = resolver.resolve(
      text: 'mark my amazon interview as completed',
      ml: const IntentClassificationResult(
        intent: 'COMPLETE_TASK',
        confidence: 0.95,
        topPredictions: [],
      ),
    );

    expect(result.intent, 'COMPLETE_TASK');
  });

  test('cancellation phrase resolves to CANCEL_TASK', () {
    final result = resolver.resolve(
      text: 'cancel my reminder',
      ml: const IntentClassificationResult(
        intent: 'CANCEL_TASK',
        confidence: 0.95,
        topPredictions: [],
      ),
    );

    expect(result.intent, 'CANCEL_TASK');
  });
}
