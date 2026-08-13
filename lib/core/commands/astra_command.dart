/// Command mode from explicit `/task` or `@task` prefixes.
enum AstraCommandMode {
  none,
  task,
  calendar,
  mail,
  panchang,
}

/// Deterministic intents — execution is decided here, not by Gemini.
enum AstraIntent {
  createReminder,
  createTask,
  completeTask,
  cancelReminder,
  snoozeReminder,
  listTasks,
  queryTask,
  currentTime,
  currentDate,
  syncEmails,
  latestEmail,
  syncCalendar,
  todayCalendar,
  fullSync,
  panchang,
  signIn,
  signOut,
  generalChat,
}

enum Sentiment {
  neutral,
  positive,
  negative,
  frustrated,
  excited,
}

enum Urgency {
  low,
  normal,
  high,
  critical,
}

/// Parsed command after normalization + classification.
class AstraCommand {
  final String rawText;
  final String normalizedText;
  final String payload;
  final AstraCommandMode mode;
  final AstraIntent intent;
  final double intentConfidence;
  final Sentiment sentiment;
  final Urgency urgency;

  const AstraCommand({
    required this.rawText,
    required this.normalizedText,
    required this.payload,
    required this.mode,
    required this.intent,
    required this.intentConfidence,
    this.sentiment = Sentiment.neutral,
    this.urgency = Urgency.normal,
  });

  bool get isDeterministic => intent != AstraIntent.generalChat;

  bool get wantsReminder =>
      intent == AstraIntent.createReminder ||
      (mode == AstraCommandMode.task && _hasReminderLanguage(payload));

  static bool _hasReminderLanguage(String text) {
    return IntentPatterns.reminderLanguage.hasMatch(text);
  }
}

/// Shared regex patterns for intent + parser alignment.
abstract final class IntentPatterns {
  static final reminderLanguage = RegExp(
    r'\b(?:'
    r'remind(?:er)?(?:\s+me)?|'
    r'notify(?:\s+me)?|'
    r'alert(?:\s+me)?|'
    r'tell\s+me\s+(?:to|when|about)|'
    r'let\s+me\s+know|'
    r'ping(?:\s+me)?|'
    r"don'?t\s+let\s+me\s+forget|"
    r'make\s+sure\s+(?:i|to)\s+remember|'
    r'remember\s+to|'
    r'schedule\s+(?:a\s+)?reminder|'
    r'set\s+(?:a\s+)?reminder'
    r')\b',
    caseSensitive: false,
  );

  static final taskOnlyLanguage = RegExp(
    r'\b(?:add\s+(?:a\s+)?task|create\s+(?:a\s+)?task|new\s+task)\b',
    caseSensitive: false,
  );

  static final temporalHint = RegExp(
    r'\b(?:today|tomorrow|day\s+after\s+tomorrow|monday|tuesday|wednesday|thursday|friday|saturday|sunday|'
    r'in\s+\d+|in\s+(?:the\s+)?next|in\s+next|after\s+\d+|at\s+\d|'
    r'\d{1,2}(?::\d{2})?\s*(?:am|pm)|next\s+(?:week|minute|min|hour|hr|day|monday|tuesday|wednesday|thursday|friday|saturday|sunday))\b',
    caseSensitive: false,
  );
}
