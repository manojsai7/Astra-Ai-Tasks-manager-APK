import 'dart:convert';
import 'package:flutter/services.dart';

import 'i_intent_classifier.dart';
import 'intent_classifier_client.dart';
import 'local_logistic_classifier.dart';
import 'local_tfidf_vectorizer.dart';

/// Native on-device Set A Intent Classifier executing entirely locally in Dart.
class LocalIntentClassifier implements IIntentClassifier {
  final String modelName;
  final String version;
  final LocalTfidfVectorizer vectorizer;
  final LocalLogisticClassifier classifier;

  LocalIntentClassifier({
    required this.modelName,
    required this.version,
    required this.vectorizer,
    required this.classifier,
  });

  factory LocalIntentClassifier.fromJson(Map<String, dynamic> json) {
    final modelName = json['model_name'] as String? ?? 'astra_intent_classifier';
    final version = json['version'] as String? ?? 'v2';
    final vectorizer = LocalTfidfVectorizer.fromJson(json['vectorizer'] as Map<String, dynamic>);
    final classifier = LocalLogisticClassifier.fromJson(json['classifier'] as Map<String, dynamic>);

    return LocalIntentClassifier(
      modelName: modelName,
      version: version,
      vectorizer: vectorizer,
      classifier: classifier,
    );
  }

  /// Loads the pre-exported Set A model asset from Flutter rootBundle or specified string content.
  static Future<LocalIntentClassifier> loadFromAsset([String assetPath = 'assets/models/intent_model_v2.json']) async {
    final jsonString = await rootBundle.loadString(assetPath);
    final map = jsonDecode(jsonString) as Map<String, dynamic>;
    return LocalIntentClassifier.fromJson(map);
  }

  /// Synchronous classification returning structured [LocalClassificationResult].
  LocalClassificationResult classifySync(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return LocalClassificationResult(
        modelName: modelName,
        version: version,
        prediction: 'GENERAL_CHAT',
        confidence: 0.0,
        topPredictions: const [],
      );
    }

    final features = vectorizer.transform(trimmed);
    return classifier.classifyFeatures(
      features: features,
      modelName: modelName,
      version: version,
      topK: 3,
    );
  }

  /// Implements [IIntentClassifier.classify] returning [IntentClassificationResult].
  @override
  Future<IntentClassificationResult?> classify(String text) async {
    final res = classifySync(text);
    return IntentClassificationResult(
      intent: res.prediction,
      confidence: res.confidence,
      topPredictions: res.topPredictions
          .map((p) => IntentPrediction(intent: p.label, confidence: p.confidence))
          .toList(growable: false),
    );
  }
}
