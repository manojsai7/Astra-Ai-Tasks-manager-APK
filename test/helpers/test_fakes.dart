import 'package:flutter_test/flutter_test.dart';
import 'package:astra/core/time/astra_clock.dart';
import 'package:astra/services/ml/intent_classifier_client.dart';
import 'package:astra/services/ml/b1_event_classifier_client.dart';

/// Test clock allowing explicit deterministic time manipulation.
class SettableTestClock implements AstraClock {
  DateTime _current;
  SettableTestClock(this._current);

  void set(DateTime time) => _current = time;
  void advance(Duration d) => _current = _current.add(d);

  @override
  DateTime now() => _current;
}

/// Fake classifier client for deterministic intent responses.
class FakeIntentClassifierClient extends Fake implements IntentClassifierClient {
  IntentClassificationResult? nextResult;

  @override
  Future<IntentClassificationResult?> classify(String text) async {
    return nextResult;
  }
}

/// Fake B1 event classifier client for deterministic entity responses.
class FakeB1EventClassifierClient extends Fake implements B1EventClassifierClient {
  B1ClassificationResult? nextResult;

  @override
  Future<B1ClassificationResult?> classify(String text) async {
    return nextResult;
  }
}
