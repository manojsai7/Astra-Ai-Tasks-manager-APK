import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiChatService {
  static final GeminiChatService _instance = GeminiChatService._internal();
  factory GeminiChatService() => _instance;
  GeminiChatService._internal();

  static const List<String> freeTierModels = [
    'gemini-1.5-flash',
    'gemini-1.5-flash-latest',
    'gemini-2.0-flash-exp',
    'gemini-2.0-flash',
    'gemini-1.5-pro',
    'gemini-1.5-pro-latest',
    'gemini-1.0-pro',
    'gemini-pro',
  ];

  String? _apiKey;
  String? _workingModelName;

  Future<void> initialize() async {
    if (_apiKey != null && _apiKey!.isNotEmpty) return;

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

    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception('GEMINI_API_KEY is missing or invalid in assets/.env file');
    }
  }

  Future<String> chat(String userMessage) async {
    try {
      await initialize();
    } catch (e) {
      return '⚠️ Gemini setup error: $e\n\nPlease add your Gemini API Key from https://aistudio.google.com/app/apikey to assets/.env!';
    }

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

    // Order models starting with known working model if available
    final modelsToTry = <String>[];
    if (_workingModelName != null) {
      modelsToTry.add(_workingModelName!);
    }
    for (final m in freeTierModels) {
      if (m != _workingModelName) {
        modelsToTry.add(m);
      }
    }

    Object? lastError;

    for (final modelName in modelsToTry) {
      try {
        final model = GenerativeModel(
          model: modelName,
          apiKey: _apiKey!,
          generationConfig: GenerationConfig(
            temperature: 0.7,
            maxOutputTokens: 500,
          ),
        );

        final response = await model.generateContent([Content.text(prompt)]);
        final text = response.text?.trim();

        if (text != null && text.isNotEmpty) {
          _workingModelName = modelName;
          debugPrint('GeminiChatService using working model: $modelName');
          return text;
        }
      } catch (e) {
        debugPrint('GeminiChatService model [$modelName] failed: $e');
        lastError = e;
      }
    }

    return '⚠️ Gemini API error: $lastError\n\nPlease verify your API key at https://aistudio.google.com/app/apikey.';
  }
}
