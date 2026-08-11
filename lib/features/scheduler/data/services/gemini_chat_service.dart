import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../../core/network/astra_ai_gateway.dart';

/// Hybrid AI Service for ASTRA Chat.
///
/// Tries the secure server gateway first. If the gateway server is sleeping
/// (Render free tier cold start) or unreachable, it automatically falls back
/// to direct client-side Gemini AI generation using `assets/.env`.
class GeminiChatService {
  static final GeminiChatService _instance = GeminiChatService._internal();
  factory GeminiChatService() => _instance;
  GeminiChatService._internal();

  final AstraAiGateway _gateway = AstraAiGateway();
  GenerativeModel? _directModel;
  String? _apiKey;

  static const List<String> _modelsToTry = [
    'gemini-1.5-flash',
    'gemini-2.0-flash',
    'gemini-1.5-pro',
    'gemini-pro',
  ];

  Future<void> _initDirectGemini() async {
    if (_directModel != null) return;
    try {
      final envString = await rootBundle.loadString('assets/.env');
      for (final line in envString.split('\n')) {
        final trimmed = line.trim();
        if (trimmed.startsWith('GEMINI_API_KEY=')) {
          final val = trimmed.substring('GEMINI_API_KEY='.length).split('#').first.trim();
          if (val.isNotEmpty && !val.contains('YOUR_GEMINI_API_KEY_HERE')) {
            _apiKey = val;
          }
        }
      }
    } catch (e) {
      debugPrint('GeminiChatService .env read error: $e');
    }

    if (_apiKey != null && _apiKey!.isNotEmpty) {
      _directModel = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey!,
      );
    }
  }

  Future<String> chat(String userMessage) async {
    // 1. Try server gateway first
    try {
      final reply = await _gateway.chat(userMessage);
      if (reply.isNotEmpty) return reply;
    } catch (gatewayError) {
      debugPrint('Gateway failed or sleeping ($gatewayError). Trying direct fallback...');
    }

    // 2. Fallback to direct client-side Gemini if API key is present
    try {
      await _initDirectGemini();
      if (_apiKey != null && _apiKey!.isNotEmpty) {
        final prompt = '''
You are ASTRA, a calm, intelligent AI life scheduler assistant. 
The user just said: "$userMessage"

Respond conversationally, helpfully, and under 3 sentences unless more detail is needed.
Do NOT mention that you are an AI.
Return only the response text.
''';

        for (final mName in _modelsToTry) {
          try {
            final model = GenerativeModel(model: mName, apiKey: _apiKey!);
            final response = await model.generateContent([Content.text(prompt)]);
            final text = response.text?.trim();
            if (text != null && text.isNotEmpty) return text;
          } catch (mErr) {
            debugPrint('Direct model [$mName] error: $mErr');
          }
        }
      }
    } catch (directError) {
      debugPrint('Direct fallback error: $directError');
    }

    // 3. User-friendly explanation if all connections fail
    return '⚡ AI connection is warming up. Please tap send again in a few seconds!';
  }
}
