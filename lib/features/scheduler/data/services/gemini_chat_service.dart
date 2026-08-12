import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/astra_ai_gateway.dart';
import '../../../../models/task.dart';

/// Hybrid AI Service for ASTRA Conversational Assistant.
///
/// Features:
/// 1. Real-time Live Context Grounding (Current IST Time, User Tasks, Panchang).
/// 2. Multi-turn Conversation Memory (remembers prior messages in the session).
/// 3. Validated Gemini 2.5 / 2.0 / 1.5 Flash & Pro Models.
/// 4. Resilient Fallback (Gateway -> Direct Gemini -> Local Intelligent Synthesis).
class GeminiChatService {
  static final GeminiChatService _instance = GeminiChatService._internal();
  factory GeminiChatService() => _instance;
  GeminiChatService._internal();

  final AstraAiGateway _gateway = AstraAiGateway();
  String? _apiKey;

  static const List<String> _modelsToTry = [
    'gemini-2.5-flash',
    'gemini-2.0-flash',
    'gemini-1.5-flash',
    'gemini-1.5-pro',
  ];

  Future<void> _loadApiKey() async {
    if (_apiKey != null && _apiKey!.isNotEmpty) return;
    try {
      final envString = await rootBundle.loadString('assets/.env');
      for (final line in envString.split('\n')) {
        final trimmed = line.trim();
        if (trimmed.startsWith('GEMINI_API_KEY=')) {
          final val = trimmed.substring('GEMINI_API_KEY='.length).split('#').first.trim();
          if (val.isNotEmpty && !val.contains('YOUR_GEMINI_API_KEY_HERE')) {
            _apiKey = val;
            break;
          }
        }
      }
    } catch (e) {
      debugPrint('GeminiChatService .env read error: $e');
    }
  }

  Future<String> chat({
    required String userMessage,
    List<Map<String, String>> history = const [],
    List<Task> pendingTasks = const [],
    String? userEmail,
    String? panchangSummary,
  }) async {
    final now = DateTime.now().toLocal();
    final timeStr = DateFormat('EEEE, MMMM d, yyyy · h:mm:ss a').format(now);
    final lower = userMessage.toLowerCase().trim();

    // ── 1. Fast Deterministic Answers for Common Live Queries ────────────────
    if (lower == "what's the time" ||
        lower == "what is the time" ||
        lower == "what's the time now" ||
        lower == "what is the time now" ||
        lower == "what time is it" ||
        lower == "current time" ||
        lower == "time now") {
      return '⏰ Current time is **${DateFormat('h:mm a').format(now)}** (${DateFormat('EEEE, MMMM d, yyyy').format(now)} · IST).';
    }

    if (lower == "what's today's date" ||
        lower == "what is today's date" ||
        lower == "today's date" ||
        lower == "what day is today" ||
        lower == "what is today") {
      return '📅 Today is **${DateFormat('EEEE, MMMM d, yyyy').format(now)}**.';
    }

    // ── 2. Build Grounded System Context ─────────────────────────────────────
    final taskListSummary = pendingTasks.isEmpty
        ? 'No pending tasks recorded.'
        : pendingTasks.take(8).map((t) {
            final due = t.dueDate != null ? ' (Due: ${DateFormat('MMM d, h:mm a').format(t.dueDate!)})' : '';
            return '• ${t.title} [${t.priority.toUpperCase()}$due]';
          }).join('\n');

    final systemPrompt = '''
You are ASTRA, an intelligent, calm, and highly capable AI personal life scheduler and assistant.
You are running natively inside the ASTRA mobile app.

LIVE SYSTEM CONTEXT:
• Current Date & Time: $timeStr (IST)
• User Account: ${userEmail ?? 'Local User (Offline)'}
${panchangSummary != null ? '• Panchang Info: $panchangSummary' : ''}
• Current Pending Tasks:
$taskListSummary

INSTRUCTIONS:
- You know the current time, date, and user tasks from the LIVE SYSTEM CONTEXT above.
- Use conversation history to maintain context and remember what the user previously discussed.
- Answer clearly, helpfully, and conversationally in 2-4 sentences unless detailed analysis is requested.
- Do NOT say "as an AI language model". Speak naturally as ASTRA.
''';

    // ── 3. Try Direct Gemini with Multi-turn History ─────────────────────────
    await _loadApiKey();
    if (_apiKey != null && _apiKey!.isNotEmpty) {
      for (final modelName in _modelsToTry) {
        try {
          final model = GenerativeModel(
            model: modelName,
            apiKey: _apiKey!,
            systemInstruction: Content.system(systemPrompt),
          );

          // Build multi-turn contents from recent history
          final contents = <Content>[];
          for (final turn in history) {
            final role = turn['role'];
            final text = turn['text'] ?? '';
            if (text.trim().isEmpty) continue;

            if (role == 'user') {
              contents.add(Content.text(text));
            } else {
              contents.add(Content.model([TextPart(text)]));
            }
          }

          // Add the current user query
          contents.add(Content.text(userMessage));

          final response = await model.generateContent(contents);
          final reply = response.text?.trim();
          if (reply != null && reply.isNotEmpty) {
            return reply;
          }
        } catch (e) {
          debugPrint('Direct Gemini [$modelName] error: $e');
        }
      }
    }

    // ── 4. Try Server Gateway Fallback ───────────────────────────────────────
    try {
      final reply = await _gateway.chat(userMessage);
      if (reply.isNotEmpty) return reply;
    } catch (gatewayError) {
      debugPrint('Gateway fallback failed: $gatewayError');
    }

    // ── 5. Graceful Local Synthesis if completely offline / no key ───────────
    if (lower.contains('task') || lower.contains('schedule') || lower.contains('todo')) {
      return '📋 You have **${pendingTasks.length} pending task(s)**:\n\n$taskListSummary';
    }

    return '⚡ ASTRA is active. Current time: ${DateFormat('h:mm a').format(now)}. How can I assist with your tasks or schedule?';
  }
}
