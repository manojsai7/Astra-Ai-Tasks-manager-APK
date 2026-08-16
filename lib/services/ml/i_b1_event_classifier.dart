import 'b1_event_classifier_client.dart';

/// Clean interface for Event classification.
abstract class IB1EventClassifier {
  Future<B1ClassificationResult?> classify(String text);
}
