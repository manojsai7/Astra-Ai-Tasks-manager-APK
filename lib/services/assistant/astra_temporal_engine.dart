class AstraTemporalResult {
  final DateTime? eventStart;
  final DateTime? eventEnd;

  final DateTime? deadline;

  final String? rawDate;
  final String? rawTime;
  final String? rawDeadline;

  final String recurrence;

  final bool ambiguous;

  final List<String> warnings;

  const AstraTemporalResult({
    this.eventStart,
    this.eventEnd,
    this.deadline,
    this.rawDate,
    this.rawTime,
    this.rawDeadline,
    this.recurrence = 'NONE',
    this.ambiguous = false,
    this.warnings = const [],
  });
}

class AstraTemporalEngine {
  const AstraTemporalEngine();

  static const _months = <String, int>{
    'january': 1,
    'february': 2,
    'march': 3,
    'april': 4,
    'may': 5,
    'june': 6,
    'july': 7,
    'august': 8,
    'september': 9,
    'october': 10,
    'november': 11,
    'december': 12,
  };

  static const _weekdays = <String, int>{
    'monday': DateTime.monday,
    'tuesday': DateTime.tuesday,
    'wednesday': DateTime.wednesday,
    'thursday': DateTime.thursday,
    'friday': DateTime.friday,
    'saturday': DateTime.saturday,
    'sunday': DateTime.sunday,
  };

  AstraTemporalResult parse(
    String input, {
    DateTime? now,
    bool isDeadline = false,
  }) {
    final reference = now ?? DateTime.now();
    final text = input.trim();
    final lower = text.toLowerCase();

    final recurrence = _detectRecurrence(lower);

    final relativeOffset = _resolveRelativeOffset(
      lower,
      reference,
    );

    final explicitRange = _extractExplicitDateRange(
      text,
      reference,
    );

    final relativeDate = _resolveRelativeDate(
      lower,
      reference,
    );

    final weekdayDate = _resolveWeekday(
      lower,
      reference,
    );

    final explicitDate = _extractExplicitDate(
      text,
      reference,
    );

    final date = explicitRange?.start ??
        explicitDate ??
        relativeDate ??
        weekdayDate;

    final endDate = explicitRange?.end;

    final times = _extractTimes(text);

    final warnings = <String>[];
    var ambiguous = false;

    DateTime? start;
    DateTime? end;

    if (relativeOffset != null) {
      start = relativeOffset;
    } else if (date != null && times.isNotEmpty) {
      start = _mergeDateAndTime(
        date,
        times.first,
      );

      if (times.length > 1) {
        final endBase = endDate ?? date;

        end = _mergeDateAndTime(
          endBase,
          times[1],
        );
      }
    } else if (date != null) {
      start = date;

      if (endDate != null) {
        end = endDate;

        if (times.length > 1) {
          end = _mergeDateAndTime(
            endDate,
            times[1],
          );
        }
      }
    }

    DateTime? deadline;

    if (isDeadline) {
      final deadlineDate = date;

      final bareTime = _extractAmbiguousBareTime(
        lower,
      );

      if (bareTime != null &&
          !lower.contains('am') &&
          !lower.contains('pm')) {
        deadline = deadlineDate;
        ambiguous = true;
        warnings.add(
          'Bare deadline time "$bareTime" is ambiguous.',
        );
      } else if (deadlineDate != null && times.isNotEmpty) {
        deadline = _mergeDateAndTime(
          deadlineDate,
          times.first,
        );
      } else if (deadlineDate != null) {
        deadline = deadlineDate;
      }
    }

    if (isDeadline) {
      start = null;
      end = null;
    }

    if (isDeadline && deadline == null && times.isNotEmpty) {
      warnings.add(
        'Deadline time exists but date is unknown.',
      );
      ambiguous = true;
    }

    // Past-time detection: If a non-recurring command resolves to a concrete datetime
    // in the past relative to reference time, flag as ambiguous and add warning.
    if (recurrence == 'NONE') {
      final targetTime = isDeadline ? deadline : start;
      if (targetTime != null && targetTime.isBefore(reference)) {
        ambiguous = true;
        final formattedTime = '${targetTime.hour == 0 ? 12 : (targetTime.hour > 12 ? targetTime.hour - 12 : targetTime.hour)}:${targetTime.minute.toString().padLeft(2, '0')} ${targetTime.hour >= 12 ? 'PM' : 'AM'}';
        warnings.add(
          '$formattedTime today has already passed. Did you mean tomorrow at $formattedTime?',
        );
      }
    }

    return AstraTemporalResult(
      eventStart: start,
      eventEnd: end,
      deadline: deadline,
      rawDate: _extractRawDate(text),
      rawTime: _extractRawTime(text),
      rawDeadline: isDeadline ? text : null,
      recurrence: recurrence,
      ambiguous: ambiguous,
      warnings: List.unmodifiable(warnings),
    );
  }

  DateTime? _resolveRelativeOffset(
    String lower,
    DateTime now,
  ) {
    // 1. "next minute", "in next minute", "in the next minute", "in a minute", "after a minute"
    if (RegExp(r'\b(?:in\s+|after\s+)?(?:the\s+)?next\s+minute\b', caseSensitive: false).hasMatch(lower) ||
        RegExp(r'\b(?:in\s+|after\s+)a\s+minute\b', caseSensitive: false).hasMatch(lower) ||
        RegExp(r'\b1\s+minute\s+from\s+now\b', caseSensitive: false).hasMatch(lower) ||
        RegExp(r'\bone\s+minute\s+from\s+now\b', caseSensitive: false).hasMatch(lower)) {
      return now.add(const Duration(minutes: 1));
    }

    // 2. Numeric word variants: "in one minute", "next one minute", "after one minute", "in two minutes", "next two minutes"
    final wordMatch = RegExp(
      r'\b(?:in\s+|after\s+|next\s+)?(?:the\s+)?(one|two|three|four|five|ten|fifteen|twenty|thirty)\s*(mins?|minutes?|hours?|hrs?|days?|secs?|seconds?)(?:\s+from\s+now)?\b',
      caseSensitive: false,
    ).firstMatch(lower);

    if (wordMatch != null) {
      final wordMap = {
        'one': 1,
        'two': 2,
        'three': 3,
        'four': 4,
        'five': 5,
        'ten': 10,
        'fifteen': 15,
        'twenty': 20,
        'thirty': 30,
      };
      final amount = wordMap[wordMatch.group(1)!.toLowerCase()];
      if (amount != null) {
        final unit = wordMatch.group(2)!.toLowerCase();
        if (unit.startsWith('min')) {
          return now.add(Duration(minutes: amount));
        } else if (unit.startsWith('hour') || unit.startsWith('hr')) {
          return now.add(Duration(hours: amount));
        } else if (unit.startsWith('day')) {
          return now.add(Duration(days: amount));
        } else if (unit.startsWith('sec')) {
          return now.add(Duration(seconds: amount));
        }
      }
    }

    // 3. Digit variants: "in 1 minute", "next 1 minute", "after 1 minute", "1 minute from now", "in 2 mins", "2 mins from now"
    final match = RegExp(
      r'\b(?:in\s+|after\s+|next\s+)?(?:the\s+)?(\d+)\s*(mins?|minutes?|hours?|hrs?|days?|secs?|seconds?)(?:\s+from\s+now)?\b',
      caseSensitive: false,
    ).firstMatch(lower);

    if (match == null) return null;

    final amount = int.tryParse(match.group(1) ?? '');
    if (amount == null) return null;

    final unit = match.group(2)!.toLowerCase();
    if (unit.startsWith('min')) {
      return now.add(Duration(minutes: amount));
    } else if (unit.startsWith('hour') || unit.startsWith('hr')) {
      return now.add(Duration(hours: amount));
    } else if (unit.startsWith('day')) {
      return now.add(Duration(days: amount));
    } else if (unit.startsWith('sec')) {
      return now.add(Duration(seconds: amount));
    }

    return null;
  }

  // ----------------------------------------------------------
  // Relative dates
  // ----------------------------------------------------------

  DateTime? _resolveRelativeDate(
    String lower,
    DateTime now,
  ) {
    if (RegExp(r'\bday after tomorrow\b').hasMatch(lower)) {
      return DateTime(
        now.year,
        now.month,
        now.day + 2,
      );
    }

    if (RegExp(r'\btomorrow\b|\btmrw\b').hasMatch(lower)) {
      return DateTime(
        now.year,
        now.month,
        now.day + 1,
      );
    }

    if (RegExp(r'\btoday\b').hasMatch(lower)) {
      return DateTime(
        now.year,
        now.month,
        now.day,
      );
    }

    return null;
  }

  // ----------------------------------------------------------
  // Weekdays
  // ----------------------------------------------------------

  DateTime? _resolveWeekday(
    String lower,
    DateTime now,
  ) {
    for (final entry in _weekdays.entries) {
      if (!RegExp(
        '\\b${RegExp.escape(entry.key)}\\b',
      ).hasMatch(lower)) {
        continue;
      }

      final current = now.weekday;
      final target = entry.value;

      var delta = target - current;

      if (delta < 0) {
        delta += 7;
      }

      return DateTime(
        now.year,
        now.month,
        now.day + delta,
      );
    }

    return null;
  }

  // ----------------------------------------------------------
  // Explicit date
  // ----------------------------------------------------------

  DateTime? _extractExplicitDate(
    String text,
    DateTime reference,
  ) {
    final monthPattern = RegExp(
      r'\b(\d{1,2})(?:st|nd|rd|th)?\s+'
      r'(January|February|March|April|May|June|July|August|'
      r'September|October|November|December)'
      r'(?:\s+(\d{4}))?\b',
      caseSensitive: false,
    );

    final monthMatch = monthPattern.firstMatch(text);

    if (monthMatch != null) {
      final day = int.parse(monthMatch.group(1)!);
      final month =
          _months[monthMatch.group(2)!.toLowerCase()]!;
      final year =
          int.tryParse(monthMatch.group(3) ?? '') ??
              _inferYear(
                month,
                day,
                reference,
              );

      return _safeDate(
        year,
        month,
        day,
      );
    }

    final slashPattern = RegExp(
      r'\b(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})\b',
    );

    final slashMatch = slashPattern.firstMatch(text);

    if (slashMatch != null) {
      final day = int.parse(
        slashMatch.group(1)!,
      );

      final month = int.parse(
        slashMatch.group(2)!,
      );

      var year = int.parse(
        slashMatch.group(3)!,
      );

      if (year < 100) {
        year += 2000;
      }

      return _safeDate(
        year,
        month,
        day,
      );
    }

    return null;
  }

  // ----------------------------------------------------------
  // Date ranges
  // ----------------------------------------------------------

  _DateRange? _extractExplicitDateRange(
    String text,
    DateTime reference,
  ) {
    final pattern = RegExp(
      r'\b(\d{1,2})(?:st|nd|rd|th)?\s+'
      r'(January|February|March|April|May|June|July|August|'
      r'September|October|November|December)'
      r'(?:\s+(\d{4}))?'
      r'\s+(?:to|until|till)\s+'
      r'(\d{1,2})(?:st|nd|rd|th)?\s+'
      r'(January|February|March|April|May|June|July|August|'
      r'September|October|November|December)'
      r'(?:\s+(\d{4}))?',
      caseSensitive: false,
    );

    final match = pattern.firstMatch(text);

    if (match == null) {
      return null;
    }

    final startDay = int.parse(
      match.group(1)!,
    );

    final startMonth =
        _months[match.group(2)!.toLowerCase()]!;

    final explicitStartYear =
        int.tryParse(match.group(3) ?? '');

    final endDay = int.parse(
      match.group(4)!,
    );

    final endMonth =
        _months[match.group(5)!.toLowerCase()]!;

    final explicitEndYear =
        int.tryParse(match.group(6) ?? '');

    final startYear = explicitStartYear ??
        _inferYear(
          startMonth,
          startDay,
          reference,
        );

    final endYear = explicitEndYear ??
        _inferEndYear(
          startYear,
          startMonth,
          endMonth,
        );

    final start = _safeDate(
      startYear,
      startMonth,
      startDay,
    );

    final end = _safeDate(
      endYear,
      endMonth,
      endDay,
    );

    if (start == null || end == null) {
      return null;
    }

    return _DateRange(
      start: start,
      end: end,
    );
  }

  // ----------------------------------------------------------
  // Time extraction
  // ----------------------------------------------------------

  List<_TimeValue> _extractTimes(
    String text,
  ) {
    final values = <_TimeValue>[];

    // Pattern 1: Explicit 12-hour with colon or space separator: "6:20pm", "6:20 pm", "6 20pm", "6 20 pm", "7pm", "7 pm"
    final explicit12Pattern = RegExp(
      r'(?<!\d)'
      r'(\d{1,2})'
      r'(?:(?:\s*:\s*|\s+)(\d{2}))?'
      r'\s*(am|pm)'
      r'\b',
      caseSensitive: false,
    );

    for (final match in explicit12Pattern.allMatches(text)) {
      var hour = int.parse(match.group(1)!);
      final minute = int.tryParse(match.group(2) ?? '') ?? 0;
      final ampm = match.group(3)!.toLowerCase();

      if (hour < 1 || hour > 12 || minute < 0 || minute > 59) {
        continue;
      }

      if (ampm == 'pm' && hour != 12) {
        hour += 12;
      }

      if (ampm == 'am' && hour == 12) {
        hour = 0;
      }

      values.add(_TimeValue(hour: hour, minute: minute));
    }

    if (values.isNotEmpty) {
      return values;
    }

    // Pattern 2: 24-hour time with colon or space: "18:20", "18 20", "09:30" (when preceded by at/from/by or standalone)
    final explicit24Pattern = RegExp(
      r'(?:\b(?:at|by|from|until|to)\s+|\b)'
      r'([01]?\d|2[0-3])(?:\s*:\s*|\s+)([0-5]\d)\b',
      caseSensitive: false,
    );

    for (final match in explicit24Pattern.allMatches(text)) {
      final hour = int.parse(match.group(1)!);
      final minute = int.parse(match.group(2)!);
      values.add(_TimeValue(hour: hour, minute: minute));
    }

    if (values.isNotEmpty) {
      return values;
    }

    // Pattern 3: Preceded bare hour: "at 10", "at 11", "at 9", "at 2"
    final precededBarePattern = RegExp(
      r'\b(?:at|by|from|until|to)\s+([1-9]|1[0-2])\b',
      caseSensitive: false,
    );

    for (final match in precededBarePattern.allMatches(text)) {
      var hour = int.parse(match.group(1)!);
      // If hour is 1..7 without am/pm, default to PM for daytime tasks unless 8..11 which defaults to AM
      if (hour >= 1 && hour <= 7) {
        hour += 12;
      }
      values.add(_TimeValue(hour: hour, minute: 0));
    }

    return values;
  }

  // ----------------------------------------------------------
  // Recurrence
  // ----------------------------------------------------------

  String _detectRecurrence(
    String lower,
  ) {
    if (lower.contains('every weekday') ||
        lower.contains('weekdays') ||
        lower.contains('monday to friday')) {
      return 'WEEKDAYS';
    }

    if (lower.contains('every day') ||
        lower.contains('daily')) {
      return 'DAILY';
    }

    if (lower.contains('every week') ||
        lower.contains('weekly')) {
      return 'WEEKLY';
    }

    if (lower.contains('every month') ||
        lower.contains('monthly')) {
      return 'MONTHLY';
    }

    return 'NONE';
  }

  // ----------------------------------------------------------
  // Raw temporal phrases
  // ----------------------------------------------------------

  String? _extractRawDate(
    String text,
  ) {
    final match = RegExp(
      r'\b(today|tomorrow|tmrw|Monday|Tuesday|Wednesday|'
      r'Thursday|Friday|Saturday|Sunday|'
      r'\d{1,2}(?:st|nd|rd|th)?\s+[A-Za-z]+'
      r'(?:\s+\d{4})?)\b',
      caseSensitive: false,
    ).firstMatch(text);

    return match?.group(1);
  }

  String? _extractRawTime(
    String text,
  ) {
    final match = RegExp(
      r'\b\d{1,2}(?:\s*:\s*\d{2})?\s*(?:am|pm)\b',
      caseSensitive: false,
    ).firstMatch(text);

    return match?.group(0);
  }

  String? _extractAmbiguousBareTime(
    String lower,
  ) {
    final match = RegExp(
      r'\b(?:by|before|at)\s+(\d{1,2})\b',
      caseSensitive: false,
    ).firstMatch(lower);

    return match?.group(1);
  }

  // ----------------------------------------------------------
  // Date helpers
  // ----------------------------------------------------------

  int _inferYear(
    int month,
    int day,
    DateTime reference,
  ) {
    final candidate = DateTime(
      reference.year,
      month,
      day,
    );

    if (candidate.isBefore(
      DateTime(
        reference.year,
        reference.month,
        reference.day,
      ),
    )) {
      return reference.year + 1;
    }

    return reference.year;
  }

  int _inferEndYear(
    int startYear,
    int startMonth,
    int endMonth,
  ) {
    if (endMonth < startMonth) {
      return startYear + 1;
    }

    return startYear;
  }

  DateTime? _safeDate(
    int year,
    int month,
    int day,
  ) {
    try {
      final value = DateTime(
        year,
        month,
        day,
      );

      if (value.year != year ||
          value.month != month ||
          value.day != day) {
        return null;
      }

      return value;
    } catch (_) {
      return null;
    }
  }

  DateTime _mergeDateAndTime(
    DateTime date,
    _TimeValue time,
  ) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }
}

class _TimeValue {
  final int hour;
  final int minute;

  const _TimeValue({
    required this.hour,
    required this.minute,
  });
}

class _DateRange {
  final DateTime start;
  final DateTime end;

  const _DateRange({
    required this.start,
    required this.end,
  });
}
