import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'i_intent_classifier.dart';

class IntentClassificationResult {
  final String intent;
  final double confidence;
  final List<IntentPrediction> topPredictions;

  const IntentClassificationResult({
    required this.intent,
    required this.confidence,
    required this.topPredictions,
  });

  factory IntentClassificationResult.fromJson(
    Map<String, dynamic> json,
  ) {
    final predictions =
        (json['top_predictions'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(IntentPrediction.fromJson)
            .toList(growable: false);

    return IntentClassificationResult(
      intent: json['prediction'] as String? ?? 'GENERAL_CHAT',
      confidence:
          (json['confidence'] as num?)?.toDouble() ?? 0.0,
      topPredictions: predictions,
    );
  }
}

class IntentPrediction {
  final String intent;
  final double confidence;

  const IntentPrediction({
    required this.intent,
    required this.confidence,
  });

  factory IntentPrediction.fromJson(
    Map<String, dynamic> json,
  ) {
    return IntentPrediction(
      intent: json['label'] as String? ?? 'GENERAL_CHAT',
      confidence:
          (json['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class IntentClassifierClient implements IIntentClassifier {
  IntentClassifierClient({
    required String baseUrl,
    http.Client? client,
    this.timeout = const Duration(milliseconds: 1200),
  })  : _baseUrl = baseUrl.replaceFirst(RegExp(r'/$'), ''),
        _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;
  final Duration timeout;

  @override
  Future<IntentClassificationResult?> classify(
    String text,
  ) async {
    final trimmed = text.trim();

    if (trimmed.isEmpty) {
      return null;
    }

    final uri = Uri.parse(
      '$_baseUrl/ml/classify-intent',
    );

    try {
      final response = await _client
          .post(
            uri,
            headers: const {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'text': trimmed,
            }),
          )
          .timeout(timeout);

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        return null;
      }

      final decoded = jsonDecode(
        response.body,
      );

      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      return IntentClassificationResult.fromJson(
        decoded,
      );
    } on TimeoutException {
      return null;
    } on FormatException {
      return null;
    } on http.ClientException {
      return null;
    } catch (_) {
      return null;
    }
  }

  void dispose() {
    _client.close();
  }
}
