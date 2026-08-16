import 'intent_classifier_client.dart';

/// Clean interface for Intent classification.
abstract class IIntentClassifier {
  Future<IntentClassificationResult?> classify(String text);
}
