import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/ml/b1_event_classifier_client.dart';
import '../services/ml/i_b1_event_classifier.dart';
import '../services/ml/local_event_classifier.dart';

/// Provider holding the loaded [LocalEventClassifier] on-device asset.
final localEventClassifierProvider = FutureProvider<LocalEventClassifier>((ref) async {
  final jsonString = await rootBundle.loadString('assets/models/event_type_model_v3.json');
  final map = jsonDecode(jsonString) as Map<String, dynamic>;
  return LocalEventClassifier.fromJson(map);
});

/// Event classifier provider adhering to [IB1EventClassifier].
/// Defaults to native on-device [LocalEventClassifier] with asset loading.
final b1EventClassifierProvider = Provider<IB1EventClassifier>((ref) {
  final localAsync = ref.watch(localEventClassifierProvider);
  return localAsync.maybeWhen(
    data: (local) => local,
    orElse: () => _FallbackLocalEventClassifier(ref),
  );
});

class _FallbackLocalEventClassifier implements IB1EventClassifier {
  final Ref _ref;
  _FallbackLocalEventClassifier(this._ref);

  @override
  Future<B1ClassificationResult?> classify(String text) async {
    try {
      final classifier = await _ref.read(localEventClassifierProvider.future);
      return await classifier.classify(text);
    } catch (_) {
      // Local fallback on asset loading failure: safe default
      return const B1ClassificationResult(
        eventType: 'OTHER',
        confidence: 0.0,
        topPredictions: [],
      );
    }
  }
}
