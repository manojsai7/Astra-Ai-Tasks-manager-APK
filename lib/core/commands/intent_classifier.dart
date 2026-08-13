import 'astra_command.dart';
import 'message_normalizer.dart';

/// Classifies normalized text into a deterministic [AstraIntent].
class IntentClassifier {
  static AstraCommand classify(NormalizedMessage msg) {
    final lower = msg.payload;
    final mode = msg.mode;

    final intent = _classifyIntent(lower, mode);
    final confidence = _confidence(intent, lower, mode);
    final sentiment = _detectSentiment(lower);
    final urgency = _detectUrgency(lower, sentiment);

    return AstraCommand(
      rawText: msg.raw,
      normalizedText: msg.normalized,
      payload: msg.payload,
      mode: mode,
      intent: intent,
      intentConfidence: confidence,
      sentiment: sentiment,
      urgency: urgency,
    );
  }

  static AstraIntent _classifyIntent(String lower, AstraCommandMode mode) {
    if (RegExp(
      r"^(?:what'?s?\s+the\s+time|what\s+time\s+is\s+it|current\s+time|time\s+now|tell\s+me\s+the\s+time)$",
      caseSensitive: false,
    ).hasMatch(lower)) {
      return AstraIntent.currentTime;
    }
    if (RegExp(
      r"^(?:what'?s?\s+today'?s?\s+date|what\s+day\s+is\s+it|today'?s?\s+date)$",
      caseSensitive: false,
    ).hasMatch(lower)) {
      return AstraIntent.currentDate;
    }

    if (mode == AstraCommandMode.task) {
      if (_matchesCancel(lower)) return AstraIntent.cancelReminder;
      if (_matchesSnooze(lower)) return AstraIntent.snoozeReminder;
      if (_matchesComplete(lower)) return AstraIntent.completeTask;
      return AstraIntent.createReminder;
    }
    if (mode == AstraCommandMode.calendar) {
      if (RegExp(r'\b(sync|fetch)\b').hasMatch(lower)) return AstraIntent.syncCalendar;
      return AstraIntent.todayCalendar;
    }
    if (mode == AstraCommandMode.mail) {
      if (RegExp(r'\b(latest|last|recent)\b').hasMatch(lower)) return AstraIntent.latestEmail;
      return AstraIntent.syncEmails;
    }
    if (mode == AstraCommandMode.panchang) return AstraIntent.panchang;

    if (_matchesCancel(lower)) return AstraIntent.cancelReminder;
    if (_matchesSnooze(lower)) return AstraIntent.snoozeReminder;
    if (_matchesComplete(lower)) return AstraIntent.completeTask;

    if (_matchesCreateReminder(lower)) return AstraIntent.createReminder;

    if (IntentPatterns.taskOnlyLanguage.hasMatch(lower) &&
        !IntentPatterns.reminderLanguage.hasMatch(lower)) {
      return AstraIntent.createTask;
    }

    if (RegExp(
      r'\b(create\s+task|add\s+task|new\s+task|todo|to-do)\b',
      caseSensitive: false,
    ).hasMatch(lower)) {
      return IntentPatterns.reminderLanguage.hasMatch(lower)
          ? AstraIntent.createReminder
          : AstraIntent.createTask;
    }

    if (RegExp(r'^remind\b', caseSensitive: false).hasMatch(lower)) {
      return AstraIntent.createReminder;
    }

    if (RegExp(r'\b(sign\s+out|logout|log\s+out)\b', caseSensitive: false).hasMatch(lower)) {
      return AstraIntent.signOut;
    }
    if (RegExp(r'\b(sign\s+in|login|connect\s+google|google\s+sign)\b', caseSensitive: false)
        .hasMatch(lower)) {
      return AstraIntent.signIn;
    }

    if (RegExp(
      r'\b(sync|fetch|check|get|read|show|scan)\s+(my\s+)?(email|emails|gmail|inbox|mail|mails)\b',
      caseSensitive: false,
    ).hasMatch(lower)) {
      return AstraIntent.syncEmails;
    }
    if (RegExp(r'\b(last|latest|newest|recent)\s+(mail|email|message)\b', caseSensitive: false)
        .hasMatch(lower)) {
      return AstraIntent.latestEmail;
    }

    if (RegExp(
      r'\b(sync|fetch|check|get)\s+(my\s+)?(calendar|events|meetings|schedule)\b',
      caseSensitive: false,
    ).hasMatch(lower)) {
      return AstraIntent.syncCalendar;
    }
    if (RegExp(
      r'\b(today.*meeting|today.*calendar|what.*calendar|next\s+meeting|upcoming\s+meeting)\b',
      caseSensitive: false,
    ).hasMatch(lower)) {
      return AstraIntent.todayCalendar;
    }

    if (RegExp(r'\b(sync|refresh|update)\s+(all|everything|life)\b', caseSensitive: false)
            .hasMatch(lower) ||
        RegExp(r'\b(life\s+sync|full\s+sync)\b', caseSensitive: false).hasMatch(lower)) {
      return AstraIntent.fullSync;
    }

    if (RegExp(
      r'\b(panchang|ekadashi|amavasya|purnima|chaturdashi|shivaratri|tithi)\b',
      caseSensitive: false,
    ).hasMatch(lower)) {
      return AstraIntent.panchang;
    }

    if (RegExp(
      r"\b(what\s+time\s+is\s+my|when\s+is\s+my|what'?s?\s+my)\s+.+\b(exam|task|reminder|meeting)\b",
      caseSensitive: false,
    ).hasMatch(lower)) {
      return AstraIntent.queryTask;
    }

    if (RegExp(
          r'\b(list|show|view|get|display|what\s+are)\s*(my\s*)?(task|tasks|todo|todos|reminder|reminders|schedule|agenda)\b',
          caseSensitive: false,
        ).hasMatch(lower) ||
        RegExp(
          r"\b(my\s+tasks|what'?s?\s+next|coming\s+up|pending\s+tasks)\b",
          caseSensitive: false,
        ).hasMatch(lower)) {
      return AstraIntent.listTasks;
    }

    return AstraIntent.generalChat;
  }

  static bool _matchesCreateReminder(String lower) {
    if (IntentPatterns.reminderLanguage.hasMatch(lower)) return true;
    if (RegExp(r'\bschedule\b', caseSensitive: false).hasMatch(lower) &&
        IntentPatterns.temporalHint.hasMatch(lower)) {
      return true;
    }
    return false;
  }

  static bool _matchesComplete(String lower) => RegExp(
        r'\b(complete|done|finish|mark\s+as\s+done|tick\s+off)\b',
        caseSensitive: false,
      ).hasMatch(lower);

  static bool _matchesCancel(String lower) => RegExp(
        r'\b(cancel|delete|remove|stop)\s+(?:my\s+)?(?:the\s+)?(?:\w+\s+){0,3}?(?:reminder|alarm|notification)\b',
        caseSensitive: false,
      ).hasMatch(lower);

  static bool _matchesSnooze(String lower) => RegExp(
        r'\b(snooze|postpone|delay)\s+(?:my\s+)?',
        caseSensitive: false,
      ).hasMatch(lower);

  static double _confidence(AstraIntent intent, String lower, AstraCommandMode mode) {
    if (mode != AstraCommandMode.none) return 0.99;
    if (intent == AstraIntent.generalChat) return 0.3;
    if (intent == AstraIntent.createReminder && IntentPatterns.reminderLanguage.hasMatch(lower)) {
      return 0.97;
    }
    if (IntentPatterns.temporalHint.hasMatch(lower)) return 0.95;
    return 0.85;
  }

  static Sentiment _detectSentiment(String lower) {
    if (RegExp(r'\b(freaking\s+out|stupid|hate|ugh|damn|annoying)\b').hasMatch(lower)) {
      return Sentiment.frustrated;
    }
    if (RegExp(r'\b(thanks|awesome|great|love|perfect|yay)\b').hasMatch(lower)) {
      return Sentiment.positive;
    }
    if (RegExp(r"\b(excited|can't\s+wait|amazing)\b").hasMatch(lower)) {
      return Sentiment.excited;
    }
    if (RegExp(r'\b(worried|stressed|anxious|sad)\b').hasMatch(lower)) {
      return Sentiment.negative;
    }
    return Sentiment.neutral;
  }

  static Urgency _detectUrgency(String lower, Sentiment sentiment) {
    if (RegExp(r'\b(asap|urgent|critical|emergency|immediately|right\s+now)\b').hasMatch(lower)) {
      return Urgency.critical;
    }
    if (RegExp(r'\b(important|soon|hurry|quickly)\b').hasMatch(lower) ||
        sentiment == Sentiment.frustrated) {
      return Urgency.high;
    }
    if (RegExp(r'\b(later|someday|whenever|no\s+rush)\b').hasMatch(lower)) {
      return Urgency.low;
    }
    return Urgency.normal;
  }
}
