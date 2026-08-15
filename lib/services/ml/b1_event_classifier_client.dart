import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Result returned by ASTRA B1 event classifier.
class B1ClassificationResult {
  final String eventType;
  final double confidence;
  final List<B1Prediction> topPredictions;

  const B1ClassificationResult({
    required this.eventType,
    required this.confidence,
    required this.topPredictions,
  });

  factory B1ClassificationResult.fromJson(
    Map<String, dynamic> json,
  ) {
    final predictions =
        (json['top_predictions'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(B1Prediction.fromJson)
            .toList(growable: false);

    return B1ClassificationResult(
      eventType: json['event_type'] as String? ?? 'OTHER',
      confidence:
          (json['confidence'] as num?)?.toDouble() ?? 0.0,
      topPredictions: predictions,
    );
  }
}

class B1Prediction {
  final String eventType;
  final double confidence;

  const B1Prediction({
    required this.eventType,
    required this.confidence,
  });

  factory B1Prediction.fromJson(
    Map<String, dynamic> json,
  ) {
    return B1Prediction(
      eventType: json['event_type'] as String? ?? 'OTHER',
      confidence:
          (json['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Calls ASTRA's FastAPI B1 classifier.
///
/// IMPORTANT:
/// - This service NEVER creates tasks.
/// - This service NEVER calls Gemini.
/// - This service NEVER blocks the rest of ASTRA.
/// - Failure returns null so local deterministic logic continues.
class B1EventClassifierClient {
  B1EventClassifierClient({
    required String baseUrl,
    http.Client? client,
    this.timeout = const Duration(milliseconds: 1200),
  })  : _baseUrl = baseUrl.replaceFirst(RegExp(r'/$'), ''),
        _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;
  final Duration timeout;

  Future<B1ClassificationResult?> classify(
    String text,
  ) async {
    final trimmed = text.trim();

    if (trimmed.isEmpty) {
      return null;
    }

    final uri = Uri.parse(
      '$_baseUrl/ml/classify-event',
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

      final decoded =
          jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      return B1ClassificationResult.fromJson(
        decoded,
      );
    } on TimeoutException {
      return null;
    } on FormatException {
      return null;
    } on http.ClientException {
      return null;
    } catch (_) {
      // B1 is optional intelligence.
      // Local ASTRA logic must continue if it fails.
      return null;
    }
  }

  void dispose() {
    _client.close();
  }
}
