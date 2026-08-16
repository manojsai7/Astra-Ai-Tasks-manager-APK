import 'dart:convert';
import 'package:flutter/services.dart';

import 'b1_event_classifier_client.dart';
import 'i_b1_event_classifier.dart';
import 'local_logistic_classifier.dart';
import 'local_tfidf_vectorizer.dart';

/// Native on-device Set B Event Classifier executing entirely locally in Dart.
class LocalEventClassifier implements IB1EventClassifier {
  final String modelName;
  final String version;
  final LocalTfidfVectorizer vectorizer;
  final LocalLogisticClassifier classifier;

  LocalEventClassifier({
    required this.modelName,
    required this.version,
    required this.vectorizer,
    required this.classifier,
  });

  factory LocalEventClassifier.fromJson(Map<String, dynamic> json) {
    final modelName = json['model_name'] as String? ?? 'astra_event_classifier';
    final version = json['version'] as String? ?? 'v3';
    final vectorizer = LocalTfidfVectorizer.fromJson(json['vectorizer'] as Map<String, dynamic>);
    final classifier = LocalLogisticClassifier.fromJson(json['classifier'] as Map<String, dynamic>);

    return LocalEventClassifier(
      modelName: modelName,
      version: version,
      vectorizer: vectorizer,
      classifier: classifier,
    );
  }

  /// Loads the pre-exported Set B model asset from Flutter rootBundle or specified string content.
  static Future<LocalEventClassifier> loadFromAsset([String assetPath = 'assets/models/event_type_model_v3.json']) async {
    final jsonString = await rootBundle.loadString(assetPath);
    final map = jsonDecode(jsonString) as Map<String, dynamic>;
    return LocalEventClassifier.fromJson(map);
  }

  /// Synchronous classification returning structured [LocalClassificationResult].
  LocalClassificationResult classifySync(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return LocalClassificationResult(
        modelName: modelName,
        version: version,
        prediction: 'OTHER',
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

  /// Implements [IB1EventClassifier.classify] returning [B1ClassificationResult].
  @override
  Future<B1ClassificationResult?> classify(String text) async {
    final res = classifySync(text);
    return B1ClassificationResult(
      eventType: res.prediction,
      confidence: res.confidence,
      topPredictions: res.topPredictions
          .map((p) => B1Prediction(eventType: p.label, confidence: p.confidence))
          .toList(growable: false),
    );
  }
}
