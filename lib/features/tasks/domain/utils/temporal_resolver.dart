/// Helper utility to resolve relative or absolute date/time expressions deterministically.
abstract class TemporalResolver {
  static const Map<String, int> _months = {
    'jan': 1,
    'feb': 2,
    'mar': 3,
    'apr': 4,
    'may': 5,
    'jun': 6,
    'jul': 7,
    'aug': 8,
    'sep': 9,
    'oct': 10,
    'nov': 11,
    'dec': 12,
  };

  /// Parses date and time expressions relative to the reference timestamp.
  ///
  /// Returns a resolved [DateTime], or `null` if the date expression cannot be safely resolved.
  static DateTime? resolve({
    required String? dateExpression,
    required String? timeExpression,
    required DateTime referenceTime,
  }) {
    if (dateExpression == null) return null;

    final normalizedDate = dateExpression.trim().toLowerCase();
    if (normalizedDate.isEmpty) return null;

    int? year;
    int? month;
    int? day;

    // Case 1: "today"
    if (normalizedDate == 'today') {
      year = referenceTime.year;
      month = referenceTime.month;
      day = referenceTime.day;
    }
    // Case 2: "tomorrow"
    else if (normalizedDate == 'tomorrow') {
      final tomorrow = referenceTime.add(const Duration(days: 1));
      year = tomorrow.year;
      month = tomorrow.month;
      day = tomorrow.day;
    }
    // Case 3: "DD Month" (e.g., "20 July" or "20 July 2026")
    else {
      final match1 = RegExp(
        r'\b(\d{1,2})\s+(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\b(?:\s+(\d{4}))?',
      ).firstMatch(normalizedDate);

      if (match1 != null) {
        day = int.tryParse(match1.group(1) ?? '');
        final monthStr = match1.group(2) ?? '';
        month = _months[monthStr];
        final yearStr = match1.group(3);
        year = yearStr != null ? int.tryParse(yearStr) : referenceTime.year;
      } else {
        // Case 4: "Month DD" (e.g., "July 20" or "July 20 2026")
        final match2 = RegExp(
          r'\b(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\s+(\d{1,2})\b(?:\s+(\d{4}))?',
        ).firstMatch(normalizedDate);

        if (match2 != null) {
          final monthStr = match2.group(1) ?? '';
          month = _months[monthStr];
          day = int.tryParse(match2.group(2) ?? '');
          final yearStr = match2.group(3);
          year = yearStr != null ? int.tryParse(yearStr) : referenceTime.year;
        }
      }
    }

    // If we could not resolve a valid date, return null (ambiguous/requires review)
    if (year == null || month == null || day == null) {
      return null;
    }

    // Default time is 00:00 (no invented time, keeping it deterministic)
    int hour = 0;
    int minute = 0;

    if (timeExpression != null) {
      final normalizedTime = timeExpression.trim().toLowerCase();
      final timeMatch = RegExp(
        r'\b(\d{1,2}):(\d{2})(?:\s*(am|pm))?\b',
      ).firstMatch(normalizedTime);

      if (timeMatch != null) {
        final parsedHour = int.tryParse(timeMatch.group(1) ?? '');
        final parsedMinute = int.tryParse(timeMatch.group(2) ?? '');
        final period = timeMatch.group(3);

        if (parsedHour != null && parsedMinute != null) {
          hour = parsedHour;
          minute = parsedMinute;

          if (period == 'pm' && hour < 12) {
            hour += 12;
          } else if (period == 'am' && hour == 12) {
            hour = 0;
          }
        }
      }
    }

    // Construct local DateTime representing the resolved time
    return DateTime(year, month, day, hour, minute);
  }
}
