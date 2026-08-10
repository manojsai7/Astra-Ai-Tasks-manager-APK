import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiChatService {
  static final GeminiChatService _instance = GeminiChatService._internal();
  factory GeminiChatService() => _instance;
  GeminiChatService._internal();

  GenerativeModel? _model;
  String? _apiKey;

  Future<void> initialize() async {
    if (_model != null) return;

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
      debugPrint('GeminiChatService .env load error: $e');
    }

    if (_apiKey != null && _apiKey!.isNotEmpty) {
      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey!,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          maxOutputTokens: 500,
        ),
      );
    } else {
      throw Exception('GEMINI_API_KEY is missing or invalid in assets/.env file');
    }
  }

  Future<String> chat(String userMessage) async {
    if (_model == null) {
      try {
        await initialize();
      } catch (e) {
        return '⚠️ Gemini setup error: $e\n\nPlease check assets/.env and add your Gemini API Key from https://aistudio.google.com/app/apikey!';
      }
    }

    try {
      final prompt = '''
You are ASTRA, a calm, intelligent AI life scheduler assistant. 
The user just said: "$userMessage"

Your job:
- If the user is asking about their schedule, respond conversationally.
- If they are asking to create a task or reminder, acknowledge it and ask for clarification if needed.
- If they are just chatting, respond naturally and helpfully.

Keep your response friendly, clear, and under 3 sentences unless more detail is needed.
Do NOT mention that you are an AI.
Return only the response text.
''';
      final response = await _model!.generateContent([Content.text(prompt)]);
      return response.text?.trim() ?? "I didn't quite catch that. Could you rephrase?";
    } catch (e) {
      debugPrint('GeminiChatService error: $e');

      // Attempt model fallback if gemini-1.5-flash encounters model-specific error
      if (_apiKey != null && _apiKey!.isNotEmpty) {
        try {
          final fallbackModel = GenerativeModel(
            model: 'gemini-2.0-flash',
            apiKey: _apiKey!,
          );
          final res = await fallbackModel.generateContent([Content.text(userMessage)]);
          if (res.text != null && res.text!.isNotEmpty) {
            return res.text!.trim();
          }
        } catch (fallbackError) {
          debugPrint('GeminiChatService fallback error: $fallbackError');
        }
      }

      return '⚠️ Gemini error: $e';
    }
  }
}
