import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/task_extraction_proposal.dart';
import '../../domain/services/task_extraction_service.dart';

/// Production-ready client implementation of [TaskExtractionService] using Supabase Edge Functions.
///
/// Ensures production Gemini API secrets are kept securely on the backend,
/// communicating via an authenticated edge function endpoint.
class SupabaseTaskExtractionService implements TaskExtractionService {
  final String supabaseUrl;
  final String supabaseAnonKey;
  final http.Client _client;

  SupabaseTaskExtractionService({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    http.Client? client,
  }) : _client = client ?? http.Client();

  @override
  Future<TaskExtractionProposal> extractTask(
    String rawText,
    DateTime referenceTime,
  ) async {
    final endpoint = Uri.parse('$supabaseUrl/functions/v1/extract-task');

    try {
      final response = await _client.post(
        endpoint,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $supabaseAnonKey',
        },
        body: jsonEncode({
          'rawText': rawText,
          'referenceTime': referenceTime.toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return TaskExtractionProposal.fromJson(decoded);
      } else {
        throw HttpException(
          'Failed to extract task: Backend returned status ${response.statusCode}',
        );
      }
    } catch (e) {
      throw HttpException('Network error during task extraction: $e');
    }
  }
}

/// Custom HTTP exception class.
class HttpException implements Exception {
  final String message;
  const HttpException(this.message);

  @override
  String toString() => message;
}
