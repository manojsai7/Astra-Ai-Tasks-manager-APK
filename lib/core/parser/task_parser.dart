import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../../models/task.dart';

/// ASTRA Task Parser v2.0
///
/// Converts natural-language task strings like
/// "dear students you have exam tomorrow at 10am by Microsoft" into a
/// structured [ParsedTask] with a clean title, IST-aware [remindAt], priority,
/// and optional organization name.
///
/// Runs entirely locally — no API calls, no packages beyond `intl` + `timezone`.
class TaskParser {
  // ─── Weekday lookup ───────────────────────────────────────────────────────
  static const Map<String, int> _weekdays = {
    'monday': 1, 'tuesday': 2, 'wednesday': 3,
    'thursday': 4, 'friday': 5, 'saturday': 6, 'sunday': 7,
  };

  // ─── Intent prefixes to strip ─────────────────────────────────────────────
  static const List<String> _intentPrefixes = [
    'please remind me to',
    'please remind me',
    'remind me to',
    'remind me',
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
    // common academic/broadcast phrases that pollute the title
    'dear students you have',
    'dear students',
    'hi students',
    'hey students',
    'you have',
    'please note that',
    'please note',
    'attention:',
    'fyi:',
  ];

  // ─── Filler words regex (used for leading-word cleanup in body) ──────────
  // Patterns for combined time detection ────────────────────────────────────

  /// Matches patterns like:
  ///   "in 2 mins"  /  "in a few hours"  /  "tomorrow at 10am"
  ///   "at 5pm"     /  "next monday"      /  "on friday"
  ///   "today"  /  "next week"
  static final RegExp _relativeRe = RegExp(
    r'in\s+(?:a\s+few|an?\s+|(?:one|two|three|four|five|six|seven|eight|nine|ten|\d+))\s*(?:minute|minutes|min|mins|hour|hours|hr|hrs|day|days|week|weeks)',
    caseSensitive: false,
  );

  static final RegExp _atTimeRe = RegExp(
    r'(?:^|\s)(?:at\s+)?(\d{1,2})(?::(\d{2}))?\s*(am|pm)',
    caseSensitive: false,
  );

  static final RegExp _atHourRe = RegExp(
    r'at\s+(\d{1,2})(?::(\d{2}))?(?!\s*(?:am|pm))',
    caseSensitive: false,
  );

  static final RegExp _orgRe = RegExp(
    r'\bby\s+([A-Za-z][A-Za-z0-9\s]{0,30}?)(?:\s*$|\s+(?:at|on|in|by|for|from|to))',
    caseSensitive: false,
  );

  static final RegExp _orgTrailingRe = RegExp(
    r'\bby\s+([A-Za-z][A-Za-z0-9]+)\s*$',
    caseSensitive: false,
  );

  // ─── Entry Point ──────────────────────────────────────────────────────────

  /// Parses [message] into a [ParsedTask].
  static ParsedTask parse(String message) {
    _ensureTimezones();
    final lower = message.toLowerCase().trim();

    // 1. Strip intent prefixes
    String body = _stripIntent(lower);

    // 2. Extract organization (before removing time so "by Google at 5pm" works)
    String? organization;
    String? orgRaw;
    final orgMatch = _orgRe.firstMatch(body) ?? _orgTrailingRe.firstMatch(body);
    if (orgMatch != null) {
      organization = _capitalize(orgMatch.group(1)!.trim());
      orgRaw = orgMatch.group(0)!;
    }

    // 3. Extract subtasks (bullet points, numbered lists, or "subtasks: x, y, z")
    final subtasks = _extractSubtasks(message);

    // 4. Extract time expression
    final timeResult = _extractTime(body);
    if (timeResult != null) {
      body = body.replaceFirst(timeResult.raw, '').trim();
    }

    // 4. Remove organization phrase from body
    if (orgRaw != null) {
      body = body.replaceFirst(orgRaw, '').trim();
    }

    // 5. Clean filler words and punctuation
    body = _cleanBody(body);

    // 6. Determine priority
    final priority = _extractPriority(lower);

    final title = _capitalize(body.isEmpty ? message : body);

    return ParsedTask(
      title: title,
      remindAt: timeResult?.dt,
      priority: priority,
      organization: organization,
      subtasks: subtasks,
      originalMessage: message,
      detectedExpression: timeResult?.raw,
    );
  }

  // ─── Subtask Extraction ──────────────────────────────────────────────────

  static List<SubTask> _extractSubtasks(String message) {
    final List<SubTask> result = [];
    final lines = message.split('\n');

    for (final rawLine in lines) {
      final line = rawLine.trim();
      final bulletMatch = RegExp(r'^(?:[-*•]|\d+\.)\s+(.+)').firstMatch(line);
      if (bulletMatch != null) {
        final subtaskName = bulletMatch.group(1)!.trim();
        if (subtaskName.isNotEmpty) {
          result.add(SubTask.create(_capitalize(subtaskName)));
        }
      }
    }

    if (result.isEmpty) {
      final subtasksKeywordMatch = RegExp(r'(?:with\s+subtasks|subtasks|steps):\s*(.+)', caseSensitive: false).firstMatch(message);
      if (subtasksKeywordMatch != null) {
        final itemsStr = subtasksKeywordMatch.group(1)!;
        final items = itemsStr.split(RegExp(r'[,;]'));
        for (final item in items) {
          final clean = item.trim();
          if (clean.isNotEmpty) {
            result.add(SubTask.create(_capitalize(clean)));
          }
        }
      }
    }

    return result;
  }

  // ─── Timezone initialisation ─────────────────────────────────────────────

  static bool _tzInitialized = false;
  static void _ensureTimezones() {
    if (_tzInitialized) return;
    try {
      tz_data.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    } catch (_) {
      // Fallback — already initialised elsewhere
    }
    _tzInitialized = true;
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
    final ist = tz.getLocation('Asia/Kolkata');
    final now = tz.TZDateTime.now(ist);

    // ── "in X minutes/hours/days" ──────────────────────────────────────────
    final mIn = _relativeRe.firstMatch(text);
    if (mIn != null) {
      final raw = mIn.group(0)!;
      // Extract the numeric part
      final numRe = RegExp(
        r'(?:a\s+few|an?\s+|(?:one|two|three|four|five|six|seven|eight|nine|ten|\d+))',
        caseSensitive: false,
      );
      final unitRe = RegExp(
        r'(?:minute|minutes|min|mins|hour|hours|hr|hrs|day|days|week|weeks)',
        caseSensitive: false,
      );
      final numM = numRe.firstMatch(raw.replaceFirst(RegExp(r'^in\s*', caseSensitive: false), ''));
      final unitM = unitRe.firstMatch(raw);
      if (numM != null && unitM != null) {
        final amount = _wordToNumber(numM.group(0)!.trim());
        final unit = unitM.group(0)!.toLowerCase();
        Duration add;
        if (unit.startsWith('min')) {
          add = Duration(minutes: amount);
        } else if (unit.startsWith('hour') || unit == 'hr' || unit == 'hrs') {
          add = Duration(hours: amount);
        } else if (unit.startsWith('day')) {
          add = Duration(days: amount);
        } else {
          add = Duration(days: amount * 7);
        }
        return _TimeResult(raw: raw, dt: now.add(add));
      }
    }

    // ── "tomorrow [at X]" ────────────────────────────────────────────────
    if (text.contains('tomorrow')) {
      final tBase = now.add(const Duration(days: 1));
      final atM = _atTimeRe.firstMatch(text) ?? _atHourRe.firstMatch(text);
      if (atM != null) {
        final dt = _buildTZDate(ist, tBase, atM);
        if (dt != null) {
          return _TimeResult(raw: 'tomorrow${atM.group(0)}', dt: dt);
        }
      }
      return _TimeResult(
        raw: 'tomorrow',
        dt: _tzDate(ist, tBase.year, tBase.month, tBase.day, 9, 0),
      );
    }

    // ── "today [at X]" ───────────────────────────────────────────────────
    if (text.contains('today')) {
      final atM = _atTimeRe.firstMatch(text) ?? _atHourRe.firstMatch(text);
      if (atM != null) {
        final dt = _buildTZDate(ist, now, atM);
        if (dt != null) {
          return _TimeResult(raw: 'today${atM.group(0)}', dt: dt);
        }
      }
      return _TimeResult(
        raw: 'today',
        dt: _tzDate(ist, now.year, now.month, now.day, 9, 0),
      );
    }

    // ── "next week" ────────────────────────────────────────────────────────
    if (text.contains('next week')) {
      final d = now.add(const Duration(days: 7));
      return _TimeResult(
        raw: 'next week',
        dt: _tzDate(ist, d.year, d.month, d.day, 9, 0),
      );
    }

    // ── Day-of-week: "on Monday" / "next Friday" ──────────────────────────
    for (final entry in _weekdays.entries) {
      if (text.contains(entry.key)) {
        int diff = entry.value - now.weekday;
        if (diff <= 0) diff += 7;
        final d = now.add(Duration(days: diff));
        // Check for time after the weekday name
        final after = text.substring(text.indexOf(entry.key) + entry.key.length);
        final atM = _atTimeRe.firstMatch(after) ?? _atHourRe.firstMatch(after);
        if (atM != null) {
          final dt = _buildTZDate(ist, d, atM);
          if (dt != null) {
            return _TimeResult(raw: '${entry.key}${atM.group(0)}', dt: dt);
          }
        }
        return _TimeResult(
          raw: entry.key,
          dt: _tzDate(ist, d.year, d.month, d.day, 9, 0),
        );
      }
    }

    // ── Bare "at Xam/pm" ─────────────────────────────────────────────────
    final atM = _atTimeRe.firstMatch(text);
    if (atM != null) {
      final dt = _buildTZDate(ist, now, atM);
      if (dt != null) {
        return _TimeResult(raw: atM.group(0)!.trim(), dt: dt);
      }
    }

    // ── "at noon" / "at midnight" ────────────────────────────────────────
    if (text.contains('at noon')) {
      return _TimeResult(
        raw: 'at noon',
        dt: _tzDate(ist, now.year, now.month, now.day, 12, 0),
      );
    }
    if (text.contains('at midnight')) {
      return _TimeResult(
        raw: 'at midnight',
        dt: _tzDate(ist, now.year, now.month, now.day, 0, 0),
      );
    }

    return null;
  }

  // ─── Time helpers ─────────────────────────────────────────────────────────

  static tz.TZDateTime _tzDate(
      tz.Location loc, int year, int month, int day, int hour, int minute) {
    return tz.TZDateTime(loc, year, month, day, hour, minute);
  }

  /// Builds a TZDateTime from a regex match group containing hour/minute/ampm.
  static tz.TZDateTime? _buildTZDate(
      tz.Location loc, tz.TZDateTime base, RegExpMatch m) {
    try {
      // group indices differ between _atTimeRe (1,2,3) and _atHourRe (1,2)
      int hour = int.parse(m.group(1)!);
      int minute = int.tryParse(m.group(2) ?? '') ?? 0;
      final String ampm = (m.groupCount >= 3 ? m.group(3) : null)?.toLowerCase() ?? '';
      if (ampm == 'pm' && hour < 12) hour += 12;
      if (ampm == 'am' && hour == 12) hour = 0;
      var dt = _tzDate(loc, base.year, base.month, base.day, hour, minute);
      final now = tz.TZDateTime.now(loc);
      if (dt.isBefore(now)) dt = dt.add(const Duration(days: 1));
      return dt;
    } catch (_) {
      return null;
    }
  }

  // ─── Priority Detection ───────────────────────────────────────────────────

  static String _extractPriority(String lower) {
    if (RegExp(r'\b(urgent|critical|asap|emergency|immediately)\b').hasMatch(lower)) return 'high';
    if (RegExp(r'\b(high priority|important|must|deadline)\b').hasMatch(lower)) return 'high';
    if (RegExp(r'\b(low priority|later|someday|whenever|no rush)\b').hasMatch(lower)) return 'low';
    return 'medium';
  }

  // ─── Body Cleaning ────────────────────────────────────────────────────────

  static String _cleanBody(String text) {
    String cleaned = text
        // Remove residual time connectors
        .replaceAll(RegExp(r'\bat\b\s*$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\bon\b\s*$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\bfor\b\s*$', caseSensitive: false), '')
        // Remove filler words at the beginning only
        .replaceAll(RegExp(r'^(to|the|an?\s+)\s+', caseSensitive: false), '')
        // Collapse spaces
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // Remove trailing punctuation
    cleaned = cleaned.replaceAll(RegExp(r'[.,!?]+$'), '').trim();
    return cleaned;
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  static String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  /// Converts English number words and digit strings to integers.
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
  final String raw;
  final DateTime dt;
  _TimeResult({required this.raw, required this.dt});
}

// ─── Public Result Model ──────────────────────────────────────────────────────

class ParsedTask {
  final String title;
  final DateTime? remindAt;
  final String priority;           // 'low' | 'medium' | 'high'
  final String? organization;      // e.g. 'Microsoft', 'Google'
  final List<SubTask> subtasks;
  final String originalMessage;
  final String? detectedExpression;

  const ParsedTask({
    required this.title,
    this.remindAt,
    required this.priority,
    this.organization,
    this.subtasks = const [],
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
    if (organization != null) buf.write('\n🏢 Organization: $organization');
    if (subtasks.isNotEmpty) {
      buf.write('\n📋 Subtasks:\n${subtasks.map((s) => ' • ${s.name}').join('\n')}');
    }
    return buf.toString();
  }

  @override
  String toString() =>
      'ParsedTask(title: "$title", remindAt: $remindAt, priority: $priority, org: $organization, subtasks: ${subtasks.length})';
}
