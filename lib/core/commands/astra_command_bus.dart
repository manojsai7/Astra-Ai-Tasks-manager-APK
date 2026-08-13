import 'astra_command.dart';
import 'intent_classifier.dart';
import 'message_normalizer.dart';

/// Central command pipeline: normalize → classify → command object.
///
/// Execution stays in [AssistantNotifier]; this bus owns understanding only.
class AstraCommandBus {
  AstraCommand parse(String rawText) {
    final normalized = MessageNormalizer.normalize(rawText);
    return IntentClassifier.classify(normalized);
  }
}
