import 'dart:convert';

/// Frequency enum for task/reminder recurrence.
enum RecurrenceFrequency {
  none,
  daily,
  weekdays,
  weekly,
  monthly,
  yearly,
  custom;

  String toJson() => name.toUpperCase();

  static RecurrenceFrequency fromJson(String value) {
    switch (value.toUpperCase()) {
      case 'DAILY':
        return RecurrenceFrequency.daily;
      case 'WEEKDAYS':
        return RecurrenceFrequency.weekdays;
      case 'WEEKLY':
        return RecurrenceFrequency.weekly;
      case 'MONTHLY':
        return RecurrenceFrequency.monthly;
      case 'YEARLY':
        return RecurrenceFrequency.yearly;
      case 'CUSTOM':
        return RecurrenceFrequency.custom;
      case 'NONE':
      default:
        return RecurrenceFrequency.none;
    }
  }
}

/// Structured recurrence rule defining recurrence pattern, constraints, and time window.
class RecurrenceRule {
  final RecurrenceFrequency frequency;
  final int interval;
  final List<int> byWeekdays;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? occurrenceLimit;
  final int occurrencesCount;
  final int hour;
  final int minute;
  final int? endHour;
  final int? endMinute;

  const RecurrenceRule({
    required this.frequency,
    this.interval = 1,
    this.byWeekdays = const [],
    this.startDate,
    this.endDate,
    this.occurrenceLimit,
    this.occurrencesCount = 0,
    required this.hour,
    required this.minute,
    this.endHour,
    this.endMinute,
  });

  bool get isEnded {
    if (frequency == RecurrenceFrequency.none) return true;
    if (endDate != null && DateTime.now().isAfter(endDate!)) return true;
    if (occurrenceLimit != null && occurrencesCount >= occurrenceLimit!) return true;
    return false;
  }

  Map<String, dynamic> toMap() {
    return {
      'frequency': frequency.toJson(),
      'interval': interval,
      'byWeekdays': byWeekdays,
      if (startDate != null) 'startDate': startDate!.toIso8601String(),
      if (endDate != null) 'endDate': endDate!.toIso8601String(),
      if (occurrenceLimit != null) 'occurrenceLimit': occurrenceLimit,
      'occurrencesCount': occurrencesCount,
      'hour': hour,
      'minute': minute,
      if (endHour != null) 'endHour': endHour,
      if (endMinute != null) 'endMinute': endMinute,
    };
  }

  String toJson() => jsonEncode(toMap());

  factory RecurrenceRule.fromMap(Map<String, dynamic> map) {
    return RecurrenceRule(
      frequency: RecurrenceFrequency.fromJson(map['frequency'] as String? ?? 'NONE'),
      interval: (map['interval'] as num?)?.toInt() ?? 1,
      byWeekdays: (map['byWeekdays'] as List<dynamic>?)?.map((e) => (e as num).toInt()).toList() ?? const [],
      startDate: map['startDate'] != null ? DateTime.parse(map['startDate'] as String) : null,
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate'] as String) : null,
      occurrenceLimit: (map['occurrenceLimit'] as num?)?.toInt(),
      occurrencesCount: (map['occurrencesCount'] as num?)?.toInt() ?? 0,
      hour: (map['hour'] as num?)?.toInt() ?? 9,
      minute: (map['minute'] as num?)?.toInt() ?? 0,
      endHour: (map['endHour'] as num?)?.toInt(),
      endMinute: (map['endMinute'] as num?)?.toInt(),
    );
  }

  factory RecurrenceRule.fromJson(String source) => RecurrenceRule.fromMap(jsonDecode(source) as Map<String, dynamic>);

  RecurrenceRule copyWith({
    RecurrenceFrequency? frequency,
    int? interval,
    List<int>? byWeekdays,
    DateTime? startDate,
    DateTime? endDate,
    int? occurrenceLimit,
    int? occurrencesCount,
    int? hour,
    int? minute,
    int? endHour,
    int? endMinute,
    bool clearEndDate = false,
    bool clearOccurrenceLimit = false,
  }) {
    return RecurrenceRule(
      frequency: frequency ?? this.frequency,
      interval: interval ?? this.interval,
      byWeekdays: byWeekdays ?? this.byWeekdays,
      startDate: startDate ?? this.startDate,
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      occurrenceLimit: clearOccurrenceLimit ? null : (occurrenceLimit ?? this.occurrenceLimit),
      occurrencesCount: occurrencesCount ?? this.occurrencesCount,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      endHour: endHour ?? this.endHour,
      endMinute: endMinute ?? this.endMinute,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! RecurrenceRule) return false;
    return other.frequency == frequency &&
        other.interval == interval &&
        _listEquals(other.byWeekdays, byWeekdays) &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.occurrenceLimit == occurrenceLimit &&
        other.occurrencesCount == occurrencesCount &&
        other.hour == hour &&
        other.minute == minute &&
        other.endHour == endHour &&
        other.endMinute == endMinute;
  }

  @override
  int get hashCode {
    return Object.hash(
      frequency,
      interval,
      Object.hashAll(byWeekdays),
      startDate,
      endDate,
      occurrenceLimit,
      occurrencesCount,
      hour,
      minute,
      endHour,
      endMinute,
    );
  }

  static bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Pure deterministic recurrence engine.
/// Calculates the exact next occurrence strictly after `after`, respecting start/end boundaries, intervals, and weekday/monthly rules.
class AstraRecurrenceEngine {
  const AstraRecurrenceEngine();

  /// Calculates the next occurrence strictly after [after].
  DateTime? nextOccurrence(
    RecurrenceRule rule,
    DateTime after,
  ) {
    if (rule.frequency == RecurrenceFrequency.none) {
      return null;
    }

    if (rule.occurrenceLimit != null && rule.occurrencesCount >= rule.occurrenceLimit!) {
      return null;
    }

    final effectiveStart = rule.startDate ?? after;
    final baseDate = after.isBefore(effectiveStart) ? effectiveStart : after;

    switch (rule.frequency) {
      case RecurrenceFrequency.daily:
        return _nextDailyOccurrence(rule, after, baseDate);

      case RecurrenceFrequency.weekdays:
        return _nextWeekdaysOccurrence(rule, after, baseDate);

      case RecurrenceFrequency.weekly:
        return _nextWeeklyOccurrence(rule, after, baseDate);

      case RecurrenceFrequency.monthly:
        return _nextMonthlyOccurrence(rule, after, baseDate);

      case RecurrenceFrequency.yearly:
        return _nextYearlyOccurrence(rule, after, baseDate);

      case RecurrenceFrequency.custom:
        return _nextCustomOccurrence(rule, after, baseDate);

      case RecurrenceFrequency.none:
        return null;
    }
  }

  /// Checks whether an occurrence candidate is within the valid start/end window of [rule].
  bool isWithinWindow(
    RecurrenceRule rule,
    DateTime occurrence,
  ) {
    if (rule.startDate != null) {
      final startDay = DateTime(rule.startDate!.year, rule.startDate!.month, rule.startDate!.day);
      final occDay = DateTime(occurrence.year, occurrence.month, occurrence.day);
      if (occDay.isBefore(startDay)) {
        return false;
      }
    }

    if (rule.endDate != null) {
      if (occurrence.isAfter(rule.endDate!)) {
        return false;
      }
    }

    return true;
  }

  // ─── DAILY ───────────────────────────────────────────────────────────────────

  DateTime? _nextDailyOccurrence(
    RecurrenceRule rule,
    DateTime after,
    DateTime baseDate,
  ) {
    final candidateToday = DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day,
      rule.hour,
      rule.minute,
    );

    DateTime candidate;
    if (candidateToday.isAfter(after) && isWithinWindow(rule, candidateToday)) {
      candidate = candidateToday;
    } else {
      final nextDay = baseDate.add(Duration(days: rule.interval > 0 ? rule.interval : 1));
      candidate = DateTime(
        nextDay.year,
        nextDay.month,
        nextDay.day,
        rule.hour,
        rule.minute,
      );
    }

    if (!isWithinWindow(rule, candidate) || !candidate.isAfter(after)) {
      return null;
    }

    return candidate;
  }

  // ─── WEEKDAYS (Mon-Fri) ─────────────────────────────────────────────────────

  DateTime? _nextWeekdaysOccurrence(
    RecurrenceRule rule,
    DateTime after,
    DateTime baseDate,
  ) {
    var cursor = DateTime(baseDate.year, baseDate.month, baseDate.day);
    // Search up to 365 days forward
    for (var i = 0; i < 365; i++) {
      if (cursor.weekday >= DateTime.monday && cursor.weekday <= DateTime.friday) {
        final candidate = DateTime(
          cursor.year,
          cursor.month,
          cursor.day,
          rule.hour,
          rule.minute,
        );

        if (candidate.isAfter(after) && isWithinWindow(rule, candidate)) {
          return candidate;
        }
      }
      cursor = cursor.add(const Duration(days: 1));
      if (rule.endDate != null && cursor.isAfter(rule.endDate!)) {
        break;
      }
    }
    return null;
  }

  // ─── WEEKLY (byWeekdays) ────────────────────────────────────────────────────

  DateTime? _nextWeeklyOccurrence(
    RecurrenceRule rule,
    DateTime after,
    DateTime baseDate,
  ) {
    final targetDays = rule.byWeekdays.isNotEmpty
        ? rule.byWeekdays
        : [rule.startDate?.weekday ?? baseDate.weekday];

    var cursor = DateTime(baseDate.year, baseDate.month, baseDate.day);
    for (var i = 0; i < 365; i++) {
      if (targetDays.contains(cursor.weekday)) {
        final candidate = DateTime(
          cursor.year,
          cursor.month,
          cursor.day,
          rule.hour,
          rule.minute,
        );

        if (candidate.isAfter(after) && isWithinWindow(rule, candidate)) {
          return candidate;
        }
      }
      cursor = cursor.add(const Duration(days: 1));
      if (rule.endDate != null && cursor.isAfter(rule.endDate!)) {
        break;
      }
    }
    return null;
  }

  // ─── MONTHLY ─────────────────────────────────────────────────────────────────

  DateTime? _nextMonthlyOccurrence(
    RecurrenceRule rule,
    DateTime after,
    DateTime baseDate,
  ) {
    final targetDayOfMonth = rule.startDate?.day ?? baseDate.day;

    var targetYear = baseDate.year;
    var targetMonth = baseDate.month;

    // Try current month first
    final candidateDayCurrentMonth = _clampDayToMonth(targetYear, targetMonth, targetDayOfMonth);
    final candidateCurrent = DateTime(
      targetYear,
      targetMonth,
      candidateDayCurrentMonth,
      rule.hour,
      rule.minute,
    );

    if (candidateCurrent.isAfter(after) && isWithinWindow(rule, candidateCurrent)) {
      return candidateCurrent;
    }

    // Step forward by interval months
    for (var i = 1; i <= 120; i++) {
      targetMonth += rule.interval > 0 ? rule.interval : 1;
      while (targetMonth > 12) {
        targetMonth -= 12;
        targetYear += 1;
      }

      final validDay = _clampDayToMonth(targetYear, targetMonth, targetDayOfMonth);
      final candidate = DateTime(
        targetYear,
        targetMonth,
        validDay,
        rule.hour,
        rule.minute,
      );

      if (candidate.isAfter(after) && isWithinWindow(rule, candidate)) {
        return candidate;
      }

      if (rule.endDate != null && candidate.isAfter(rule.endDate!)) {
        break;
      }
    }

    return null;
  }

  // ─── YEARLY ──────────────────────────────────────────────────────────────────

  DateTime? _nextYearlyOccurrence(
    RecurrenceRule rule,
    DateTime after,
    DateTime baseDate,
  ) {
    final start = rule.startDate ?? baseDate;
    final targetMonth = start.month;
    final targetDay = start.day;

    for (var i = 0; i <= 20; i++) {
      final targetYear = baseDate.year + (i * (rule.interval > 0 ? rule.interval : 1));
      final validDay = _clampDayToMonth(targetYear, targetMonth, targetDay);
      final candidate = DateTime(
        targetYear,
        targetMonth,
        validDay,
        rule.hour,
        rule.minute,
      );

      if (candidate.isAfter(after) && isWithinWindow(rule, candidate)) {
        return candidate;
      }

      if (rule.endDate != null && candidate.isAfter(rule.endDate!)) {
        break;
      }
    }

    return null;
  }

  // ─── CUSTOM ──────────────────────────────────────────────────────────────────

  DateTime? _nextCustomOccurrence(
    RecurrenceRule rule,
    DateTime after,
    DateTime baseDate,
  ) {
    if (rule.byWeekdays.isNotEmpty) {
      return _nextWeeklyOccurrence(rule, after, baseDate);
    }
    return _nextDailyOccurrence(rule, after, baseDate);
  }

  // ─── Month Clamping Helper ───────────────────────────────────────────────────

  int _clampDayToMonth(int year, int month, int targetDay) {
    final daysInMonth = _daysInMonth(year, month);
    return targetDay > daysInMonth ? daysInMonth : targetDay;
  }

  int _daysInMonth(int year, int month) {
    if (month == 2) {
      final isLeapYear = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
      return isLeapYear ? 29 : 28;
    }
    const days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    return days[month - 1];
  }

  /// Pure deterministic natural language recurrence parser.
  RecurrenceRule? parse(String text) {
    final lower = text.toLowerCase().trim();
    if (lower.isEmpty) return null;

    int hour = 9;
    int minute = 0;

    // Extract time if present
    final timeMatch = RegExp(r'\b(?:at\s+)?(\d{1,2})(?::(\d{2}))?\s*(am|pm)?\b', caseSensitive: false).firstMatch(lower);
    if (timeMatch != null && (lower.contains('at ') || timeMatch.group(3) != null || timeMatch.group(2) != null)) {
      var h = int.tryParse(timeMatch.group(1) ?? '9') ?? 9;
      final m = int.tryParse(timeMatch.group(2) ?? '0') ?? 0;
      final ampm = timeMatch.group(3)?.toLowerCase();
      if (ampm == 'pm' && h < 12) h += 12;
      if (ampm == 'am' && h == 12) h = 0;
      hour = h;
      minute = m;
    }

    if (lower.contains('every weekday') || lower.contains('on weekdays') || lower.contains('mon-fri') || lower.contains('monday to friday')) {
      return RecurrenceRule(
        frequency: RecurrenceFrequency.weekdays,
        byWeekdays: [1, 2, 3, 4, 5],
        hour: hour,
        minute: minute,
      );
    }

    if (lower.contains('every day') || lower.contains('daily') || lower.contains('every morning') || lower.contains('every night')) {
      return RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
        hour: hour,
        minute: minute,
      );
    }

    if (lower.contains('every month') || lower.contains('monthly')) {
      return RecurrenceRule(
        frequency: RecurrenceFrequency.monthly,
        hour: hour,
        minute: minute,
      );
    }

    if (lower.contains('every week') || lower.contains('weekly')) {
      return RecurrenceRule(
        frequency: RecurrenceFrequency.weekly,
        hour: hour,
        minute: minute,
      );
    }

    // "every 2 hours", "every 3 days"
    final intervalMatch = RegExp(r'every\s+(\d+)\s*(days?|hours?|weeks?|months?)', caseSensitive: false).firstMatch(lower);
    if (intervalMatch != null) {
      final num = int.tryParse(intervalMatch.group(1) ?? '1') ?? 1;
      final unit = intervalMatch.group(2) ?? 'days';
      if (unit.startsWith('hour')) {
        return RecurrenceRule(
          frequency: RecurrenceFrequency.daily,
          interval: num,
          hour: hour,
          minute: minute,
        );
      }
      return RecurrenceRule(
        frequency: RecurrenceFrequency.custom,
        interval: num,
        hour: hour,
        minute: minute,
      );
    }

    return null;
  }
}
