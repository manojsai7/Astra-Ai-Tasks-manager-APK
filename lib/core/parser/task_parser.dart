import 'package:intl/intl.dart';

import '../../models/task.dart';
import '../../models/task_intent.dart';
import '../../services/assistant/astra_recurrence_engine.dart';
import '../time/astra_clock.dart';
import '../time/astra_time_service.dart';

/// ASTRA Task Parser v3 — deterministic local entity + temporal extraction.
///
/// Converts natural-language strings like
/// "remind me to drink water in the next 2 mins" or
/// "dear students you have exam tomorrow at 10am by Microsoft"
/// into a structured [ParsedTask] without any AI involvement.
class TaskParser {
  TaskParser._();

  static AstraTimeService _timeService = AstraTimeService();

  /// Override clock for unit tests.
  static void setClock(AstraClock clock) {
    _timeService = AstraTimeService(clock: clock);
  }

  static void resetClock() {
    _timeService = AstraTimeService();
  }

  static void setTimezone(String timezone) {
    _timeService.setTimezone(timezone);
  }

  // ─── Weekday lookup ───────────────────────────────────────────────────────

  static const Map<String, int> _weekdays = {
    'monday': 1,
    'tuesday': 2,
    'wednesday': 3,
    'thursday': 4,
    'friday': 5,
    'saturday': 6,
    'sunday': 7,
  };

  static const Map<String, int> _months = {
    'january': 1,
    'jan': 1,
    'february': 2,
    'feb': 2,
    'march': 3,
    'mar': 3,
    'april': 4,
    'apr': 4,
    'may': 5,
    'june': 6,
    'jun': 6,
    'july': 7,
    'jul': 7,
    'august': 8,
    'aug': 8,
    'september': 9,
    'sep': 9,
    'sept': 9,
    'october': 10,
    'oct': 10,
    'november': 11,
    'nov': 11,
    'december': 12,
    'dec': 12,
  };

  static const List<String> _intentPrefixes = [
    'please remind me to',
    'please remind me about',
    'please remind me',
    'pls remind me to',
    'pls remind me about',
    'pls remind me',
    'remind me to',
    'remind me about',
    'remind me',
    "don't let me forget to",
    "don't let me forget about",
    "don't let me forget",
    'make sure i remember to',
    'make sure i remember',
    'make sure to remember',
    'let me know to',
    'let me know about',
    'let me know',
    'notify me to',
    'notify me about',
    'notify me',
    'alert me to',
    'alert me about',
    'alert me',
    'tell me to',
    'tell me about',
    'remember to',
    'ping me to',
    'ping me about',
    'ping me',
    'create task:',
    'create task',
    'add task:',
    'add task',
    'new task:',
    'new task',
    'set reminder for',
    'set reminder',
    'schedule a reminder for',
    'schedule a reminder',
    'schedule reminder for',
    'schedule reminder',
    'schedule',
    'remind',
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

  /// Relative duration including "next minute", "in a minute", "in next minute", word numbers.
  static final RegExp _relativeRe = RegExp(
    r'(?:\b(?:in|after|for)\s+(?:like\s+|about\s+|around\s+)?(?:the\s+)?(?:next\s+)?(?:a\s+)?|\b(?:the\s+)?next\s+)'
    r'(?:a\s+few|a\b|an\b|one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|fifteen|twenty|thirty|forty|fifty|sixty|ninety|\d+)?\s*'
    r'(?:second|seconds|sec|secs|minute|minutes|min|mins|hour|hours|hr|hrs|day|days|week|weeks)\b',
    caseSensitive: false,
  );

  static final RegExp _atTimeRe = RegExp(
    r'(?:^|\s)(?:at\s+)?(\d{1,2})(?::(\d{2}))?\s*(am|pm)\b',
    caseSensitive: false,
  );

  /// Time without am/pm suffix: "tomorrow 10:30", "Friday 4"
  static final RegExp _bareTimeRe = RegExp(
    r'(?:^|\s)(\d{1,2})(?::(\d{2}))?\s*(am|pm)?\b',
    caseSensitive: false,
  );

  static final RegExp _atHourRe = RegExp(
    r'\bat\s+(\d{1,2})(?::(\d{2}))?(?!\s*(?:am|pm)\b)',
    caseSensitive: false,
  );

  static final RegExp _monthDayRe = RegExp(
    r'\b(january|jan|february|feb|march|mar|april|apr|may|june|jun|july|jul|august|aug|september|sep|sept|october|oct|november|nov|december|dec)\s+(\d{1,2})(?:st|nd|rd|th)?(?:\s*,\s*(\d{4}))?\b',
    caseSensitive: false,
  );

  static final RegExp _dayMonthRe = RegExp(
    r'\b(\d{1,2})(?:st|nd|rd|th)?\s+(?:of\s+)?(january|jan|february|feb|march|mar|april|apr|may|june|jun|july|jul|august|aug|september|sep|sept|october|oct|november|nov|december|dec)(?:\s*,\s*(\d{4}))?\b',
    caseSensitive: false,
  );

  static final RegExp _orgRe = RegExp(
    r'\bby\s+([A-Za-z][A-Za-z0-9\s]{0,40}?)(?:\s*[.,!?]*)?(?:\r?\n|$)',
    caseSensitive: false,
  );

  static final RegExp _orgInlineRe = RegExp(
    r'\bby\s+([A-Za-z][A-Za-z0-9\s]{0,40}?)(?=\s+(?:at|on|in|for|from|to)\b|\s*[.,!?]*(?:\r?\n|$))',
    caseSensitive: false,
  );

  // ─── Entry Point ──────────────────────────────────────────────────────────

  static ParsedTask parse(String message) {
    final lower = message.toLowerCase().trim();

    // For multi-line messages, isolate the main instruction line from bullet subtasks
    final lines = lower.split(RegExp(r'\r?\n'));
    final mainLine = lines.firstWhere(
      (l) => l.trim().isNotEmpty && !RegExp(r'^(?:[-*•]|\d+\.)').hasMatch(l.trim()),
      orElse: () => lower,
    );

    String body = _stripIntent(mainLine);

    String? organization;
    String? orgRaw;
    final orgMatch = _orgRe.firstMatch(body) ?? _orgInlineRe.firstMatch(body);
    if (orgMatch != null) {
      organization = _titleCase(orgMatch.group(1)!.trim());
      orgRaw = orgMatch.group(0)!;
    }

    final subtasks = _extractSubtasks(message);

    // 1. Extract Recurrence & Window (e.g., "daily", "weekdays", "from tomorrow till next Wednesday")
    final recurrenceResult = _extractRecurrence(body) ?? _extractRecurrence(lower);
    if (recurrenceResult != null) {
      if (recurrenceResult.frequencyRaw != null) {
        body = body.replaceFirst(RegExp(RegExp.escape(recurrenceResult.frequencyRaw!), caseSensitive: false), ' ').trim();
      }
      if (recurrenceResult.windowRaw != null) {
        body = body.replaceFirst(RegExp(RegExp.escape(recurrenceResult.windowRaw!), caseSensitive: false), ' ').trim();
      }
      body = body.replaceFirst(recurrenceResult.raw, ' ').trim();
    }

    // 2. Extract Time / Date
    final timeResult = _extractTime(body) ?? _extractTime(lower);
    if (timeResult != null) {
      body = body.replaceFirst(RegExp(RegExp.escape(timeResult.raw), caseSensitive: false), ' ').trim();
    }

    if (orgRaw != null) {
      body = body.replaceFirst(orgRaw, ' ').trim();
    }

    body = _cleanBody(body);

    final priority = _extractPriority(lower);
    final title = _titleCase(body.isEmpty ? message : body, original: message);

    RecurrenceRule? recurrenceRule;
    String? dueTime;
    DateTime? remindAt = timeResult?.dt;

    if (timeResult?.hour != null) {
      final h = timeResult!.hour!;
      final m = timeResult.minute ?? 0;
      dueTime = '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
    }

    if (recurrenceResult != null) {
      final hour = timeResult?.hour ?? 20; // Default 8:00 PM
      final minute = timeResult?.minute ?? 0;
      dueTime ??= '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

      recurrenceRule = RecurrenceRule(
        frequency: recurrenceResult.frequency,
        byWeekdays: recurrenceResult.byWeekdays,
        startDate: recurrenceResult.startDate,
        endDate: recurrenceResult.endDate,
        hour: hour,
        minute: minute,
      );

      // Determine initial anchor
      if (recurrenceResult.startDate != null) {
        remindAt = DateTime(
          recurrenceResult.startDate!.year,
          recurrenceResult.startDate!.month,
          recurrenceResult.startDate!.day,
          hour,
          minute,
        );
      } else if (remindAt == null) {
        final now = _timeService.nowTZ();
        final nextOcc = const AstraRecurrenceEngine().nextOccurrence(recurrenceRule, now);
        remindAt = nextOcc;
      }
    }

    return ParsedTask(
      title: title,
      remindAt: remindAt,
      dueTime: dueTime,
      recurrenceRule: recurrenceRule,
      recurrenceStartDate: recurrenceResult?.startDate,
      recurrenceEndDate: recurrenceResult?.endDate,
      priority: priority,
      organization: organization,
      subtasks: subtasks,
      originalMessage: message,
      detectedExpression: timeResult?.raw ?? recurrenceResult?.raw,
      timezone: _timeService.timezone,
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
          result.add(SubTask.create(_titleCase(subtaskName)));
        }
      }
    }

    if (result.isEmpty) {
      final subtasksKeywordMatch = RegExp(
        r'(?:with\s+subtasks|subtasks|steps):\s*(.+)',
        caseSensitive: false,
      ).firstMatch(message);
      if (subtasksKeywordMatch != null) {
        final itemsStr = subtasksKeywordMatch.group(1)!;
        for (final item in itemsStr.split(RegExp(r'[,;]'))) {
          final clean = item.trim();
          if (clean.isNotEmpty) {
            result.add(SubTask.create(_titleCase(clean)));
          }
        }
      }
    }

    return result;
  }

  // ─── Intent Stripping ─────────────────────────────────────────────────────

  static String _stripIntent(String text) {
    var result = text;
    result = result.replaceFirst(
      RegExp(
        r'^(?:/(?:task|calendar|mail|panchang)|@(?:task|calendar|mail|panchang))\s+',
        caseSensitive: false,
      ),
      '',
    );
    result = result.replaceFirst(
      RegExp(
        r'^(?:hey(?:\s+can\s+you)?|hi|hello|yo|ok|okay|please|pls|can\s+you\s+(?:pls\s+|please\s+)?|could\s+you\s+(?:pls\s+|please\s+)?|i\s+have\s+(?:an?\s+)?)[,\s]+',
        caseSensitive: false,
      ),
      '',
    );
    for (final prefix in _intentPrefixes) {
      if (!result.startsWith(prefix)) continue;
      // Require word boundary after prefix — prevents "remind me to" matching "remind me tomorrow".
      if (result.length > prefix.length) {
        final next = result[prefix.length];
        if (next != ' ' && next != ',' && next != ':') continue;
      }
      return result.substring(prefix.length).trim();
    }
    return result;
  }

  // ─── Time Expression Extraction ───────────────────────────────────────────

  static _TimeResult? _extractTime(String text) {
    final now = _timeService.nowTZ();

    // ── Relative: "in the next 2 mins", "after 2 minutes", "in next minute", etc.
    final mIn = _relativeRe.firstMatch(text);
    if (mIn != null) {
      final raw = mIn.group(0)!;
      final numRe = RegExp(
        r'(?:a\s+few|a\b|an\b|one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|fifteen|twenty|thirty|forty|fifty|sixty|ninety|\d+)',
        caseSensitive: false,
      );
      final unitRe = RegExp(
        r'(?:second|seconds|sec|secs|minute|minutes|min|mins|hour|hours|hr|hrs|day|days|week|weeks)',
        caseSensitive: false,
      );
      final numM = numRe.firstMatch(raw);
      final unitM = unitRe.firstMatch(raw);
      if (unitM != null) {
        final amount = numM != null ? _wordToNumber(numM.group(0)!.trim()) : 1;
        final unit = unitM.group(0)!.toLowerCase();
        final Duration add;
        if (unit.startsWith('sec')) {
          add = Duration(seconds: amount);
        } else if (unit.startsWith('min')) {
          add = Duration(minutes: amount);
        } else if (unit.startsWith('hour') || unit == 'hr' || unit == 'hrs') {
          add = Duration(hours: amount);
        } else if (unit.startsWith('day')) {
          add = Duration(days: amount);
        } else {
          add = Duration(days: amount * 7);
        }
        return _TimeResult(raw: raw.trim(), dt: now.add(add));
      }
    }

    // ── Month date: "August 20 at 7pm", "Aug 14 at 10am" ──────────────────
    final mMonthDay = _monthDayRe.firstMatch(text) ?? _dayMonthRe.firstMatch(text);
    if (mMonthDay != null) {
      final isDayFirst = _dayMonthRe.hasMatch(text);
      final monthStr = isDayFirst ? mMonthDay.group(2)!.toLowerCase() : mMonthDay.group(1)!.toLowerCase();
      final dayStr = isDayFirst ? mMonthDay.group(1)! : mMonthDay.group(2)!;
      final yearStr = mMonthDay.group(3);

      final month = _months[monthStr] ?? 1;
      final day = int.tryParse(dayStr) ?? 1;
      var year = yearStr != null ? int.tryParse(yearStr) ?? now.year : now.year;

      if (yearStr == null) {
        // If date has passed this year, roll forward
        final candidate = DateTime(year, month, day, 23, 59);
        if (candidate.isBefore(now)) {
          year += 1;
        }
      }

      final dateBase = _timeService.buildDateTime(year, month, day, 9, 0);
      final after = text.substring(mMonthDay.end);
      final atM = _findTimeMatch(after) ?? _findTimeMatch(text);
      if (atM != null) {
        final res = _buildTZDate(dateBase, atM, rawPrefix: mMonthDay.group(0)!);
        if (res != null) return res;
      }
      return _TimeResult(raw: mMonthDay.group(0)!, dt: dateBase);
    }

    // ── "tomorrow [at X]" ──────────────────────────────────────────────────
    if (RegExp(r'\btomorrow\b', caseSensitive: false).hasMatch(text)) {
      final tBase = now.add(const Duration(days: 1));
      final atM = _findTimeMatch(text);
      if (atM != null) {
        final res = _buildTZDate(tBase, atM, rawPrefix: 'tomorrow');
        if (res != null) return res;
      }
      return _TimeResult(
        raw: 'tomorrow',
        dt: _timeService.buildDateTime(tBase.year, tBase.month, tBase.day, 9, 0),
      );
    }

    // ── "today [at X]" ─────────────────────────────────────────────────────
    if (RegExp(r'\btoday\b', caseSensitive: false).hasMatch(text)) {
      final atM = _findTimeMatch(text);
      if (atM != null) {
        final res = _buildTZDate(now, atM, rawPrefix: 'today');
        if (res != null) return res;
      }
      return _TimeResult(
        raw: 'today',
        dt: _timeService.buildDateTime(now.year, now.month, now.day, 9, 0),
      );
    }

    // ── "day after tomorrow" ───────────────────────────────────────────────
    if (RegExp(r'\bday after tomorrow\b', caseSensitive: false).hasMatch(text)) {
      final d = now.add(const Duration(days: 2));
      final atM = _findTimeMatch(text);
      if (atM != null) {
        final res = _buildTZDate(d, atM, rawPrefix: 'day after tomorrow');
        if (res != null) return res;
      }
      return _TimeResult(
        raw: 'day after tomorrow',
        dt: _timeService.buildDateTime(d.year, d.month, d.day, 9, 0),
      );
    }

    // ── "next week" ────────────────────────────────────────────────────────
    if (RegExp(r'\bnext week\b', caseSensitive: false).hasMatch(text)) {
      final d = now.add(const Duration(days: 7));
      return _TimeResult(
        raw: 'next week',
        dt: _timeService.buildDateTime(d.year, d.month, d.day, 9, 0),
      );
    }

    // ── Weekday: "next Monday at 9:30am" / "Friday at 4pm" ────────────────
    final weekdayMatch = _findWeekdayMatch(text);
    if (weekdayMatch != null) {
      final dayName = weekdayMatch.key;
      final forceNext = weekdayMatch.value;
      final weekday = _weekdays[dayName]!;
      final now = _timeService.nowTZ();
      var diff = weekday - now.weekday;
      if (diff <= 0 || forceNext) diff += 7;
      final d = now.add(Duration(days: diff));
      final dayIndex = text.indexOf(dayName);
      final after = dayIndex >= 0 ? text.substring(dayIndex + dayName.length) : '';
      final atM = _findTimeMatch(after) ?? _findTimeMatch(text);
      if (atM != null) {
        final prefix = forceNext ? 'next $dayName' : dayName;
        final res = _buildTZDate(d, atM, rawPrefix: prefix);
        if (res != null) return res;
      }
      return _TimeResult(
        raw: forceNext ? 'next $dayName' : dayName,
        dt: _timeService.buildDateTime(d.year, d.month, d.day, 9, 0),
      );
    }

    // ── Bare "at Xam/pm" or "at 7" ───────────────────────────────────────
    final atM = _findTimeMatch(text);
    if (atM != null) {
      final res = _buildTZDate(now, atM);
      if (res != null) return res;
    }

    // ── "at noon" / "at midnight" ──────────────────────────────────────────
    if (RegExp(r'\bat noon\b', caseSensitive: false).hasMatch(text)) {
      return _TimeResult(
        raw: 'at noon',
        dt: _timeService.buildDateTime(now.year, now.month, now.day, 12, 0),
      );
    }
    if (RegExp(r'\bat midnight\b', caseSensitive: false).hasMatch(text)) {
      return _TimeResult(
        raw: 'at midnight',
        dt: _timeService.buildDateTime(now.year, now.month, now.day, 0, 0),
      );
    }

    return null;
  }

  static RegExpMatch? _findTimeMatch(String text) {
    return _atTimeRe.firstMatch(text) ??
        _atHourRe.firstMatch(text) ??
        _bareTimeWithMeridiem(text) ??
        _bareHourAfterDate(text);
  }

  /// Matches " 10:30 pm" or " 4pm" or " 5 pm" even without the word "at".
  static RegExpMatch? _bareTimeWithMeridiem(String text) {
    final m = _bareTimeRe.firstMatch(text);
    if (m == null) return null;
    final ampm = m.group(3);
    if (ampm != null && ampm.isNotEmpty) return m;
    return null;
  }

  /// Matches hour following date words like "tomorrow 10" or "Friday 4"
  static RegExpMatch? _bareHourAfterDate(String text) {
    final m = RegExp(
      r'(?:tomorrow|today|day\s+after\s+tomorrow|monday|tuesday|wednesday|thursday|friday|saturday|sunday)\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)?\b',
      caseSensitive: false,
    ).firstMatch(text);
    if (m == null) return null;
    return m;
  }

  static MapEntry<String, bool>? _findWeekdayMatch(String text) {
    final nextRe = RegExp(r'\bnext\s+(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b', caseSensitive: false);
    final nextM = nextRe.firstMatch(text);
    if (nextM != null) {
      return MapEntry(nextM.group(1)!.toLowerCase(), true);
    }
    for (final entry in _weekdays.entries) {
      if (RegExp(r'\b' + entry.key + r'\b', caseSensitive: false).hasMatch(text)) {
        return MapEntry(entry.key, false);
      }
    }
    return null;
  }

  static _RecurrenceResult? _extractRecurrence(String text) {
    final lower = text.toLowerCase();

    RecurrenceFrequency? freq;
    List<int> byWeekdays = [];
    String? matchedFreqString;

    if (RegExp(r'\b(?:daily|every\s+day|everyday)\b', caseSensitive: false).hasMatch(lower)) {
      freq = RecurrenceFrequency.daily;
      matchedFreqString = RegExp(r'\b(?:daily|every\s+day|everyday)\b', caseSensitive: false).firstMatch(lower)!.group(0);
    } else if (RegExp(r'\b(?:weekdays|every\s+weekday|on\s+weekdays|monday\s+to\s+friday|mon-fri)\b', caseSensitive: false).hasMatch(lower)) {
      freq = RecurrenceFrequency.weekdays;
      matchedFreqString = RegExp(r'\b(?:weekdays|every\s+weekday|on\s+weekdays|monday\s+to\s+friday|mon-fri)\b', caseSensitive: false).firstMatch(lower)!.group(0);
    } else if (RegExp(r'\bevery\s+(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b', caseSensitive: false).hasMatch(lower)) {
      freq = RecurrenceFrequency.weekly;
      final m = RegExp(r'\bevery\s+(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b', caseSensitive: false).firstMatch(lower)!;
      matchedFreqString = m.group(0);
      final dayName = m.group(1)!.toLowerCase();
      if (_weekdays.containsKey(dayName)) {
        byWeekdays = [_weekdays[dayName]!];
      }
    } else if (RegExp(r'\b(?:weekly|every\s+week)\b', caseSensitive: false).hasMatch(lower)) {
      freq = RecurrenceFrequency.weekly;
      matchedFreqString = RegExp(r'\b(?:weekly|every\s+week)\b', caseSensitive: false).firstMatch(lower)!.group(0);
    } else if (RegExp(r'\b(?:monthly|every\s+month)\b', caseSensitive: false).hasMatch(lower)) {
      freq = RecurrenceFrequency.monthly;
      matchedFreqString = RegExp(r'\b(?:monthly|every\s+month)\b', caseSensitive: false).firstMatch(lower)!.group(0);
    } else if (RegExp(r'\b(?:yearly|every\s+year|annually)\b', caseSensitive: false).hasMatch(lower)) {
      freq = RecurrenceFrequency.yearly;
      matchedFreqString = RegExp(r'\b(?:yearly|every\s+year|annually)\b', caseSensitive: false).firstMatch(lower)!.group(0);
    }

    if (freq == null) return null;

    DateTime? startDate;
    DateTime? endDate;
    String raw = matchedFreqString ?? '';
    String? windowRaw;

    // Check for "from X (till|until|to) Y"
    final windowMatch = RegExp(
      r'\bfrom\s+(tomorrow|today|next\s+[a-z]+|[a-z]+)\s+(?:till|until|to)\s+(tomorrow|today|next\s+[a-z]+|[a-z]+|\d{1,2}(?:st|nd|rd|th)?(?:\s+[a-z]+)?)\b',
      caseSensitive: false,
    ).firstMatch(lower);

    if (windowMatch != null) {
      windowRaw = windowMatch.group(0)!;
      raw += ' $windowRaw';
      final startStr = windowMatch.group(1)!;
      final endStr = windowMatch.group(2)!;
      startDate = _parseDateToken(startStr);
      endDate = _parseDateToken(endStr);
      if (endDate != null) {
        endDate = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
      }
    } else {
      // Check for standalone "until X" / "till X"
      final untilMatch = RegExp(
        r'\b(?:until|till)\s+(tomorrow|today|next\s+[a-z]+|[a-z]+|\d{1,2}(?:st|nd|rd|th)?(?:\s+[a-z]+)?)\b',
        caseSensitive: false,
      ).firstMatch(lower);
      if (untilMatch != null) {
        windowRaw = untilMatch.group(0)!;
        raw += ' $windowRaw';
        endDate = _parseDateToken(untilMatch.group(1)!);
        if (endDate != null) {
          endDate = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
        }
      }
    }

    return _RecurrenceResult(
      frequency: freq,
      byWeekdays: byWeekdays,
      startDate: startDate,
      endDate: endDate,
      frequencyRaw: matchedFreqString,
      windowRaw: windowRaw,
      raw: raw.trim(),
    );
  }

  static DateTime? _parseDateToken(String token) {
    final clean = token.toLowerCase().trim();
    final now = _timeService.nowTZ();
    if (clean == 'today') return DateTime(now.year, now.month, now.day);
    if (clean == 'tomorrow') return DateTime(now.year, now.month, now.day + 1);
    if (clean == 'day after tomorrow') return DateTime(now.year, now.month, now.day + 2);

    final weekdayMatch = _findWeekdayMatch(clean);
    if (weekdayMatch != null) {
      final dayName = weekdayMatch.key;
      final forceNext = weekdayMatch.value;
      final weekday = _weekdays[dayName]!;
      var diff = weekday - now.weekday;
      if (diff <= 0 || forceNext) diff += 7;
      final d = now.add(Duration(days: diff));
      return DateTime(d.year, d.month, d.day);
    }
    return null;
  }

  static _TimeResult? _buildTZDate(DateTime base, RegExpMatch m, {String? rawPrefix}) {
    try {
      int hour = int.parse(m.group(1)!);
      final minute = int.tryParse(m.group(2) ?? '') ?? 0;
      final ampm = (m.groupCount >= 3 ? m.group(3) : null)?.toLowerCase() ?? '';
      if (ampm == 'pm' && hour < 12) hour += 12;
      if (ampm == 'am' && hour == 12) hour = 0;
      if (ampm.isEmpty && hour >= 1 && hour <= 7) {
        // "call mom at 7" → evening unless context says morning
        hour += 12;
      }
      var dt = _timeService.buildDateTime(
        base.year,
        base.month,
        base.day,
        hour,
        minute,
      );
      final rolled = _timeService.rollForwardIfPast(dt);
      final raw = rawPrefix != null ? '$rawPrefix ${m.group(0)!.trim()}'.trim() : m.group(0)!.trim();
      return _TimeResult(
        raw: raw,
        dt: rolled,
        hour: hour,
        minute: minute,
        hasExplicitTime: true,
      );
    } catch (_) {
      return null;
    }
  }

  // ─── Priority Detection ───────────────────────────────────────────────────

  static String _extractPriority(String lower) {
    if (RegExp(r'\b(urgent|critical|asap|emergency|immediately)\b').hasMatch(lower)) {
      return 'high';
    }
    if (RegExp(r'\b(high priority|important|must|deadline)\b').hasMatch(lower)) {
      return 'high';
    }
    if (RegExp(r'\b(low priority|later|someday|whenever|no rush)\b').hasMatch(lower)) {
      return 'low';
    }
    return 'medium';
  }

  // ─── Body Cleaning ────────────────────────────────────────────────────────

  static String _cleanBody(String text) {
    var cleaned = text
        .replaceAll(RegExp(r'\b(?:at|on|for|from|till|until|to)\s*$', caseSensitive: false), '')
        .replaceAll(RegExp(r'^(?:to|the|an?|your|my|our)\s+', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    cleaned = cleaned.replaceAll(RegExp(r'[.,!?]+$'), '').trim();
    return cleaned;
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  static String _titleCase(String text, {String? original}) {
    if (text.isEmpty) return text;
    final origWords = (original ?? '').split(RegExp(r'\s+'));
    final origUpperMap = <String, String>{};
    for (final ow in origWords) {
      final clean = ow.replaceAll(RegExp(r'[^\w]'), '');
      if (clean.length >= 2 && clean == clean.toUpperCase() && RegExp(r'^[A-Z0-9]+$').hasMatch(clean)) {
        origUpperMap[clean.toLowerCase()] = clean;
      }
    }

    return text.split(' ').map((w) {
      if (w.isEmpty) return '';
      final clean = w.replaceAll(RegExp(r'[^\w]'), '').toLowerCase();
      if (origUpperMap.containsKey(clean)) {
        return origUpperMap[clean]!;
      }
      return w[0].toUpperCase() + w.substring(1);
    }).join(' ');
  }

  static int _wordToNumber(String word) {
    const map = {
      'a': 1,
      'an': 1,
      'one': 1,
      'two': 2,
      'three': 3,
      'four': 4,
      'five': 5,
      'six': 6,
      'seven': 7,
      'eight': 8,
      'nine': 9,
      'ten': 10,
      'eleven': 11,
      'twelve': 12,
      'fifteen': 15,
      'twenty': 20,
      'thirty': 30,
      'forty': 40,
      'fifty': 50,
      'sixty': 60,
      'ninety': 90,
      'a few': 3,
    };
    final clean = word.toLowerCase().trim();
    return map[clean] ?? int.tryParse(clean) ?? 1;
  }
}

class _RecurrenceResult {
  final RecurrenceFrequency frequency;
  final List<int> byWeekdays;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? frequencyRaw;
  final String? windowRaw;
  final String raw;

  _RecurrenceResult({
    required this.frequency,
    this.byWeekdays = const [],
    this.startDate,
    this.endDate,
    this.frequencyRaw,
    this.windowRaw,
    required this.raw,
  });
}

class _TimeResult {
  final String raw;
  final DateTime dt;
  final int? hour;
  final int? minute;
  final bool hasExplicitTime;

  _TimeResult({
    required this.raw,
    required this.dt,
    this.hour,
    this.minute,
    this.hasExplicitTime = false,
  });
}

// ─── Public Result Model ──────────────────────────────────────────────────────

class ParsedTask {
  final String title;
  final DateTime? remindAt;
  final String? dueTime;
  final RecurrenceRule? recurrenceRule;
  final DateTime? recurrenceStartDate;
  final DateTime? recurrenceEndDate;
  final String priority;
  final String? organization;
  final List<SubTask> subtasks;
  final String originalMessage;
  final String? detectedExpression;
  final String timezone;

  const ParsedTask({
    required this.title,
    this.remindAt,
    this.dueTime,
    this.recurrenceRule,
    this.recurrenceStartDate,
    this.recurrenceEndDate,
    required this.priority,
    this.organization,
    this.subtasks = const [],
    required this.originalMessage,
    this.detectedExpression,
    this.timezone = AstraTimeService.defaultTimezone,
  });

  bool get hasReminder => remindAt != null;
  bool get hasRecurrence => recurrenceRule != null && recurrenceRule!.frequency != RecurrenceFrequency.none;

  String get formattedReminder => remindAt == null
      ? 'No reminder set'
      : DateFormat('MMM d, yyyy h:mm a').format(remindAt!);

  TaskIntent toTaskIntent({String? source}) {
    return TaskIntent(
      title: title,
      dueDate: remindAt,
      dueTime: dueTime,
      recurrenceRule: recurrenceRule,
      priority: priority,
      organization: organization,
      subtasks: subtasks,
      source: source ?? 'assistant',
    );
  }

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
      'ParsedTask(title: "$title", remindAt: $remindAt, dueTime: $dueTime, recurrence: ${recurrenceRule?.frequency.name}, priority: $priority, org: $organization, subtasks: ${subtasks.length})';
}
