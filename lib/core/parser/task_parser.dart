import 'package:intl/intl.dart';

/// ASTRA Task Parser
///
/// Converts natural-language task strings like
/// "Remind me to take water in 2 mins" into a structured [ParsedTask]
/// with a clean title, an absolute [remindAt] DateTime, and a priority.
///
/// Runs entirely locally — no API calls, no packages beyond `intl`.
class TaskParser {
  // ─── Intent prefixes to strip ─────────────────────────────────────────────
  static const List<String> _intentPrefixes = [
    'remind me to',
    'remind me',
    'please remind me to',
    'please remind me',
    'create task:',
    'create task',
    'add task:',
    'add task',
    'new task:',
    'new task',
    'set reminder for',
    'set reminder',
    'schedule',
    'remind',
  ];

  // ─── Entry Point ──────────────────────────────────────────────────────────

  /// Parses [message] into a [ParsedTask].
  static ParsedTask parse(String message) {
    final lower = message.toLowerCase().trim();

    // 1. Strip intent prefix to isolate the task body.
    String body = _stripIntent(lower);

    // 2. Extract time expression from the body.
    final timeResult = _extractTime(body);
    if (timeResult != null) {
      body = body.replaceFirst(timeResult.raw, '').trim();
    }

    // 3. Clean leftover noise words from the beginning.
    body = _cleanBody(body);

    // 4. Determine priority.
    final priority = _extractPriority(lower);

    return ParsedTask(
      title: _capitalize(body.isEmpty ? message : body),
      remindAt: timeResult?.dt,
      priority: priority,
      originalMessage: message,
      detectedExpression: timeResult?.raw,
    );
  }

  // ─── Intent Stripping ─────────────────────────────────────────────────────

  static String _stripIntent(String text) {
    for (final prefix in _intentPrefixes) {
      if (text.startsWith(prefix)) {
        return text.substring(prefix.length).trim();
      }
    }
    return text;
  }

  // ─── Time Expression Extraction ───────────────────────────────────────────

  static _TimeResult? _extractTime(String text) {
    final now = DateTime.now();

    // "in X minutes / hours / days"
    final inRel = RegExp(
      r'in\s+(a\s+few|an?\s+|(?:one|two|three|four|five|six|seven|eight|nine|ten|\d+))\s*(minute|minutes|min|mins|hour|hours|hr|hrs|day|days|week|weeks)',
      caseSensitive: false,
    );
    final mIn = inRel.firstMatch(text);
    if (mIn != null) {
      final amount = _wordToNumber(mIn.group(1)!.trim());
      final unit = mIn.group(2)!.toLowerCase();
      DateTime dt = now;
      if (unit.startsWith('min')) {
        dt = now.add(Duration(minutes: amount));
      } else if (unit.startsWith('hour') || unit == 'hr' || unit == 'hrs') {
        dt = now.add(Duration(hours: amount));
      } else if (unit.startsWith('day')) {
        dt = now.add(Duration(days: amount));
      } else if (unit.startsWith('week')) {
        dt = now.add(Duration(days: amount * 7));
      }
      return _TimeResult(raw: mIn.group(0)!, dt: dt);
    }

    // "at HH[:MM][am/pm]"
    final atTime = RegExp(
      r'at\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)?',
      caseSensitive: false,
    );
    final mAt = atTime.firstMatch(text);
    if (mAt != null) {
      int hour = int.parse(mAt.group(1)!);
      int minute = int.parse(mAt.group(2) ?? '0');
      final ampm = (mAt.group(3) ?? '').toLowerCase();
      if (ampm == 'pm' && hour < 12) hour += 12;
      if (ampm == 'am' && hour == 12) hour = 0;
      var dt = DateTime(now.year, now.month, now.day, hour, minute);
      if (!dt.isAfter(now)) {
        dt = dt.add(const Duration(days: 1));
      } // push to tomorrow if past
      return _TimeResult(raw: mAt.group(0)!, dt: dt);
    }

    // "at noon" / "at midnight"
    if (text.contains('at noon')) {
      return _TimeResult(raw: 'at noon', dt: DateTime(now.year, now.month, now.day, 12));
    }
    if (text.contains('at midnight')) {
      return _TimeResult(raw: 'at midnight', dt: DateTime(now.year, now.month, now.day, 0));
    }

    // "tomorrow [at X]"
    if (text.contains('tomorrow')) {
      final tomorrowBase = now.add(const Duration(days: 1));
      final atInTomorrow = atTime.firstMatch(text);
      if (atInTomorrow != null) {
        int h = int.parse(atInTomorrow.group(1)!);
        int m = int.parse(atInTomorrow.group(2) ?? '0');
        final ampm = (atInTomorrow.group(3) ?? '').toLowerCase();
        if (ampm == 'pm' && h < 12) h += 12;
        if (ampm == 'am' && h == 12) h = 0;
        return _TimeResult(
          raw: 'tomorrow${atInTomorrow.group(0)}',
          dt: DateTime(tomorrowBase.year, tomorrowBase.month, tomorrowBase.day, h, m),
        );
      }
      return _TimeResult(
        raw: 'tomorrow',
        dt: DateTime(tomorrowBase.year, tomorrowBase.month, tomorrowBase.day, 9, 0),
      );
    }

    // "today"
    if (text.contains('today')) {
      return _TimeResult(
        raw: 'today',
        dt: DateTime(now.year, now.month, now.day, 9, 0),
      );
    }

    // "next week"
    if (text.contains('next week')) {
      final d = now.add(const Duration(days: 7));
      return _TimeResult(raw: 'next week', dt: DateTime(d.year, d.month, d.day, 9, 0));
    }

    // Day-of-week: "on Monday", "on Friday", etc.
    const weekdays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    for (int i = 0; i < weekdays.length; i++) {
      if (text.contains(weekdays[i])) {
        final targetWeekday = i + 1;
        int diff = targetWeekday - now.weekday;
        if (diff <= 0) diff += 7;
        final d = now.add(Duration(days: diff));
        return _TimeResult(
          raw: weekdays[i],
          dt: DateTime(d.year, d.month, d.day, 9, 0),
        );
      }
    }

    return null;
  }

  // ─── Priority Detection ───────────────────────────────────────────────────

  static String _extractPriority(String lower) {
    if (lower.contains('urgent') || lower.contains('critical') || lower.contains('asap')) return 'high';
    if (lower.contains('high priority') || lower.contains('important')) return 'high';
    if (lower.contains('low priority') || lower.contains('later') || lower.contains('someday')) return 'low';
    return 'medium';
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  static String _cleanBody(String text) {
    // Strip leading noise: "to", "the", "a", "an"
    return text
        .replaceAll(RegExp(r'^(to|the|an?\s+)\s+'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  /// Converts English number words (and digit strings) to integers.
  static int _wordToNumber(String word) {
    const map = {
      'a': 1, 'an': 1, 'one': 1, 'two': 2, 'three': 3, 'four': 4,
      'five': 5, 'six': 6, 'seven': 7, 'eight': 8, 'nine': 9, 'ten': 10,
      'a few': 3,
    };
    final clean = word.toLowerCase().trim();
    return map[clean] ?? int.tryParse(clean) ?? 1;
  }
}

// ─── Private helpers ──────────────────────────────────────────────────────────

class _TimeResult {
  final String raw;   // raw matched string to remove from title
  final DateTime dt;
  _TimeResult({required this.raw, required this.dt});
}

// ─── Public Result Model ──────────────────────────────────────────────────────

class ParsedTask {
  final String title;
  final DateTime? remindAt;
  final String priority;           // 'low' | 'medium' | 'high'
  final String originalMessage;
  final String? detectedExpression; // e.g. "in 2 mins", "tomorrow"

  const ParsedTask({
    required this.title,
    this.remindAt,
    required this.priority,
    required this.originalMessage,
    this.detectedExpression,
  });

  bool get hasReminder => remindAt != null;

  String get formattedReminder =>
      remindAt == null ? 'No reminder set' : DateFormat('MMM d, yyyy h:mm a').format(remindAt!);

  /// Description string added to the created task for traceability.
  String get taskDescription {
    final buf = StringBuffer('Created via ASTRA Assistant.');
    if (remindAt != null) buf.write('\n⏰ Reminder: $formattedReminder');
    if (detectedExpression != null) buf.write('\n📝 Detected: "$detectedExpression"');
    return buf.toString();
  }

  @override
  String toString() =>
      'ParsedTask(title: "$title", remindAt: $remindAt, priority: $priority)';
}
