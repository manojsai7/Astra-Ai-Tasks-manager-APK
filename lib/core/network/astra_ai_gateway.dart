import 'dart:convert';

import 'package:http/http.dart' as http;

/// Client for ASTRA's server-side AI gateway.
///
/// Keep all provider credentials on the server. Configure the public gateway
/// URL at build time, for example:
/// `--dart-define=ASTRA_API_BASE_URL=https://api.example.com`.
class AstraAiGateway {
  AstraAiGateway({http.Client? client}) : _client = client ?? http.Client();

  /// The Android-emulator address makes routine local runs work without flags.
  /// Replace this default with the deployed HTTPS URL before publishing, or
  /// override it per build with --dart-define=ASTRA_API_BASE_URL=... .
  /// http://10.0.2.2:8000
  static const _baseUrl = String.fromEnvironment(
    'ASTRA_API_BASE_URL',
    defaultValue: 'https://astra-ai-gateway-s4q0.onrender.com',
  );
  final http.Client _client;

  bool get isConfigured => _baseUrl.isNotEmpty;

  Future<String> chat(String message) async {
    final data = await _post('/v1/assistant/chat', {'message': message});
    final reply = data['reply'];
    if (reply is String && reply.trim().isNotEmpty) return reply.trim();
    throw const AstraAiGatewayException('The AI gateway returned an empty response.');
  }

  Future<Map<String, dynamic>> extractTask({
    required String text,
    required String source,
  }) async {
    return _post('/v1/assistant/extract-task', {'text': text, 'source': source});
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> payload) async {
    if (!isConfigured) {
      throw const AstraAiGatewayException(
        'AI is not configured for this build. Set ASTRA_API_BASE_URL.',
      );
    }

    final response = await _client
        .post(
          Uri.parse('$_baseUrl$path'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 25));

    Map<String, dynamic> body = {};
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) body = decoded;
    } on FormatException {
      // Use a clear status error below when an intermediary returns HTML/plain text.
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final detail = body['detail'];
      throw AstraAiGatewayException(
        detail is String ? detail : 'AI gateway request failed (${response.statusCode}).',
      );
    }
    return body;
  }
}

class AstraAiGatewayException implements Exception {
  final String message;
  const AstraAiGatewayException(this.message);

  @override
  String toString() => message;
}
