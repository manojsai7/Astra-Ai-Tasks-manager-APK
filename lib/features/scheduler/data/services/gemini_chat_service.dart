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
    } catch (_) {}

    if (_apiKey != null && _apiKey!.isNotEmpty) {
      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey!,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          maxOutputTokens: 500,
        ),
      );
    }
  }

  Future<String> chat(String userMessage) async {
    await initialize();
    if (_model == null) {
      return "I'm ASTRA, your AI Assistant! To enable full conversational AI, please add your Gemini API key to assets/.env.";
    }

    try {
      final prompt = '''
You are ASTRA, a calm, intelligent, and helpful AI life scheduler assistant.
The user said: "$userMessage"

Instructions:
- If the user asks about scheduling, productivity, tasks, or life planning, give clear, encouraging, practical advice.
- Keep your response friendly, clear, and under 3-4 sentences unless detailed assistance is required.
- Do NOT mention that you are a language model or AI software. Respond as ASTRA.
''';

      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      return response.text?.trim() ?? "I didn't quite catch that. Could you rephrase?";
    } catch (e) {
      return "I'm having trouble connecting right now. Please check your internet or try again shortly.";
    }
  }
}
