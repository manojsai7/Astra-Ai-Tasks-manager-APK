import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/ml/i_intent_classifier.dart';
import '../services/ml/intent_classifier_client.dart';
import '../services/ml/local_intent_classifier.dart';

/// Provider holding the loaded [LocalIntentClassifier] on-device asset.
final localIntentClassifierProvider = FutureProvider<LocalIntentClassifier>((ref) async {
  final jsonString = await rootBundle.loadString('assets/models/intent_model_v2.json');
  final map = jsonDecode(jsonString) as Map<String, dynamic>;
  return LocalIntentClassifier.fromJson(map);
});

/// Intent classifier provider adhering to [IIntentClassifier].
/// Defaults to native on-device [LocalIntentClassifier] with asset loading.
final intentClassifierProvider = Provider<IIntentClassifier>((ref) {
  final localAsync = ref.watch(localIntentClassifierProvider);
  return localAsync.maybeWhen(
    data: (local) => local,
    orElse: () => _FallbackLocalIntentClassifier(ref),
  );
});

class _FallbackLocalIntentClassifier implements IIntentClassifier {
  final Ref _ref;
  _FallbackLocalIntentClassifier(this._ref);

  @override
  Future<IntentClassificationResult?> classify(String text) async {
    try {
      final classifier = await _ref.read(localIntentClassifierProvider.future);
      return await classifier.classify(text);
    } catch (_) {
      // Local fallback on asset loading failure: safe default
      return const IntentClassificationResult(
        intent: 'GENERAL_CHAT',
        confidence: 0.0,
        topPredictions: [],
      );
    }
  }
}
