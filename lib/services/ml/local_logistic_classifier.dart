import 'dart:math' as math;

/// Prediction result representing a single labeled class and its softmax probability.
class LocalClassPrediction {
  final String label;
  final double confidence;

  const LocalClassPrediction({
    required this.label,
    required this.confidence,
  });

  Map<String, dynamic> toJson() => {
        'label': label,
        'confidence': confidence,
      };
}

/// Complete classification output with best prediction, confidence score, and top-3 classes.
class LocalClassificationResult {
  final String modelName;
  final String version;
  final String prediction;
  final double confidence;
  final List<LocalClassPrediction> topPredictions;

  const LocalClassificationResult({
    required this.modelName,
    required this.version,
    required this.prediction,
    required this.confidence,
    required this.topPredictions,
  });

  Map<String, dynamic> toJson() => {
        'model': modelName,
        'version': version,
        'prediction': prediction,
        'confidence': confidence,
        'top_predictions': topPredictions.map((p) => p.toJson()).toList(),
      };
}

/// Portable Logistic Regression classifier in pure Dart matching scikit-learn's LogisticRegression.
class LocalLogisticClassifier {
  final List<String> classes;
  final List<List<double>> coef; // shape: (numClasses, numFeatures)
  final List<double> intercept; // shape: (numClasses)

  LocalLogisticClassifier({
    required this.classes,
    required this.coef,
    required this.intercept,
  });

  factory LocalLogisticClassifier.fromJson(Map<String, dynamic> json) {
    final classesList = (json['classes'] as List<dynamic>)
        .map((x) => x.toString())
        .toList(growable: false);

    final rawCoef = json['coef'] as List<dynamic>;
    final coefList = <List<double>>[];
    for (final row in rawCoef) {
      coefList.add((row as List<dynamic>).map((v) => (v as num).toDouble()).toList(growable: false));
    }

    final interceptList = (json['intercept'] as List<dynamic>)
        .map((x) => (x as num).toDouble())
        .toList(growable: false);

    return LocalLogisticClassifier(
      classes: classesList,
      coef: coefList,
      intercept: interceptList,
    );
  }

  /// Calculates softmax probabilities for the input dense feature vector [features].
  List<double> predictProba(List<double> features) {
    final numClasses = classes.length;
    final numFeatures = features.length;
    final scores = List<double>.filled(numClasses, 0.0);

    double maxScore = -double.infinity;
    for (int i = 0; i < numClasses; i++) {
      double score = intercept[i];
      final classCoef = coef[i];
      for (int j = 0; j < numFeatures; j++) {
        final featVal = features[j];
        if (featVal != 0.0) {
          score += classCoef[j] * featVal;
        }
      }
      scores[i] = score;
      if (score > maxScore) {
        maxScore = score;
      }
    }

    // Softmax with numerical stability (subtract maxScore)
    final expScores = List<double>.filled(numClasses, 0.0);
    double sumExp = 0.0;
    for (int i = 0; i < numClasses; i++) {
      final expVal = math.exp(scores[i] - maxScore);
      expScores[i] = expVal;
      sumExp += expVal;
    }

    final probabilities = List<double>.filled(numClasses, 0.0);
    if (sumExp > 0.0) {
      for (int i = 0; i < numClasses; i++) {
        probabilities[i] = expScores[i] / sumExp;
      }
    }

    return probabilities;
  }

  /// Classifies [features] and returns structured top predictions.
  LocalClassificationResult classifyFeatures({
    required List<double> features,
    required String modelName,
    required String version,
    int topK = 3,
  }) {
    final probabilities = predictProba(features);
    final numClasses = classes.length;

    final indices = List<int>.generate(numClasses, (i) => i);
    indices.sort((a, b) => probabilities[b].compareTo(probabilities[a]));

    final bestIndex = indices.first;
    final bestLabel = classes[bestIndex];
    final bestConfidence = probabilities[bestIndex];

    final topCount = math.min(topK, numClasses);
    final topPredictions = <LocalClassPrediction>[];
    for (int i = 0; i < topCount; i++) {
      final idx = indices[i];
      topPredictions.add(
        LocalClassPrediction(
          label: classes[idx],
          confidence: probabilities[idx],
        ),
      );
    }

    return LocalClassificationResult(
      modelName: modelName,
      version: version,
      prediction: bestLabel,
      confidence: bestConfidence,
      topPredictions: topPredictions,
    );
  }
}
