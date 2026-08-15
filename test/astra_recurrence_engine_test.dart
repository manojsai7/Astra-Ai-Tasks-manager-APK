import 'package:flutter_test/flutter_test.dart';
import 'package:astra/services/assistant/astra_recurrence_engine.dart';

void main() {
  const engine = AstraRecurrenceEngine();

  group('AstraRecurrenceEngine Tests', () {
    // 1. DAILY: start Monday 2026-05-25 09:00, after Monday 08:00 -> Monday 09:00
    test('1. DAILY: after Monday 08:00 -> Monday 09:00', () {
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
        startDate: DateTime(2026, 5, 25),
        hour: 9,
        minute: 0,
      );
      final after = DateTime(2026, 5, 25, 8, 0);
      final next = engine.nextOccurrence(rule, after);

      expect(next, DateTime(2026, 5, 25, 9, 0));
    });

    // 2. DAILY: after Monday 10:00 -> Tuesday 09:00
    test('2. DAILY: after Monday 10:00 -> Tuesday 09:00', () {
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
        startDate: DateTime(2026, 5, 25),
        hour: 9,
        minute: 0,
      );
      final after = DateTime(2026, 5, 25, 10, 0);
      final next = engine.nextOccurrence(rule, after);

      expect(next, DateTime(2026, 5, 26, 9, 0));
    });

    // 3. WEEKDAYS: Monday 09:00, after Friday 10:00 -> following Monday 09:00
    test('3. WEEKDAYS: after Friday 10:00 -> following Monday 09:00', () {
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.weekdays,
        startDate: DateTime(2026, 5, 25), // Monday
        hour: 9,
        minute: 0,
      );
      // 2026-05-29 is Friday
      final after = DateTime(2026, 5, 29, 10, 0);
      final next = engine.nextOccurrence(rule, after);

      // Next weekday is Monday 2026-06-01
      expect(next, DateTime(2026, 6, 1, 9, 0));
      expect(next!.weekday, DateTime.monday);
    });

    // 4. WEEKLY: Monday + Wednesday, after Monday occurrence -> Wednesday
    test('4. WEEKLY: after Monday occurrence -> Wednesday', () {
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.weekly,
        byWeekdays: [DateTime.monday, DateTime.wednesday],
        startDate: DateTime(2026, 5, 25),
        hour: 9,
        minute: 0,
      );
      final after = DateTime(2026, 5, 25, 9, 0);
      final next = engine.nextOccurrence(rule, after);

      // Wednesday 2026-05-27
      expect(next, DateTime(2026, 5, 27, 9, 0));
    });

    // 5. WEEKLY: after Wednesday occurrence -> next Monday
    test('5. WEEKLY: after Wednesday occurrence -> next Monday', () {
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.weekly,
        byWeekdays: [DateTime.monday, DateTime.wednesday],
        startDate: DateTime(2026, 5, 25),
        hour: 9,
        minute: 0,
      );
      final after = DateTime(2026, 5, 27, 9, 0);
      final next = engine.nextOccurrence(rule, after);

      // Next Monday 2026-06-01
      expect(next, DateTime(2026, 6, 1, 9, 0));
    });

    // 6. MONTHLY: May 25 -> June 25
    test('6. MONTHLY: May 25 -> June 25', () {
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.monthly,
        startDate: DateTime(2026, 5, 25),
        hour: 9,
        minute: 0,
      );
      final after = DateTime(2026, 5, 25, 9, 0);
      final next = engine.nextOccurrence(rule, after);

      expect(next, DateTime(2026, 6, 25, 9, 0));
    });

    // 7. MONTHLY short-month handling: January 31 -> February last valid day (Feb 28 on 2026)
    test('7. MONTHLY short-month handling: January 31 -> February 28', () {
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.monthly,
        startDate: DateTime(2026, 1, 31),
        hour: 9,
        minute: 0,
      );
      final after = DateTime(2026, 1, 31, 9, 0);
      final next = engine.nextOccurrence(rule, after);

      expect(next, DateTime(2026, 2, 28, 9, 0));
    });

    // 8. End-date boundary: next occurrence beyond endDate -> null
    test('8. End-date boundary: next occurrence beyond endDate -> null', () {
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
        startDate: DateTime(2026, 5, 25),
        endDate: DateTime(2026, 5, 26, 23, 59),
        hour: 9,
        minute: 0,
      );
      final after = DateTime(2026, 5, 26, 9, 0);
      final next = engine.nextOccurrence(rule, after);

      expect(next, isNull);
    });

    // 9. Start-date boundary: after before startDate -> first valid occurrence on/after startDate
    test('9. Start-date boundary: after before startDate -> first valid occurrence on/after startDate', () {
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
        startDate: DateTime(2026, 5, 25),
        hour: 9,
        minute: 0,
      );
      final after = DateTime(2026, 5, 20, 12, 0);
      final next = engine.nextOccurrence(rule, after);

      expect(next, DateTime(2026, 5, 25, 9, 0));
    });

    // 10. WEEKDAYS with endDate: last valid weekday returned, next occurrence after endDate -> null
    test('10. WEEKDAYS with endDate: last valid weekday returned, next occurrence after endDate -> null', () {
      // 2026-06-18 is Thursday
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.weekdays,
        startDate: DateTime(2026, 5, 25),
        endDate: DateTime(2026, 6, 18, 13, 0),
        hour: 9,
        minute: 0,
        endHour: 13,
        endMinute: 0,
      );

      // Day before end date (Wednesday June 17 09:00)
      final afterWed = DateTime(2026, 6, 17, 9, 0);
      final nextThu = engine.nextOccurrence(rule, afterWed);
      expect(nextThu, DateTime(2026, 6, 18, 9, 0));

      // After last occurrence (Thursday June 18 09:00)
      final afterThu = DateTime(2026, 6, 18, 9, 0);
      final nextFri = engine.nextOccurrence(rule, afterThu);
      expect(nextFri, isNull);
    });

    // 11. NONE -> null
    test('11. NONE -> null', () {
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.none,
        hour: 9,
        minute: 0,
      );
      final after = DateTime(2026, 5, 25, 8, 0);
      final next = engine.nextOccurrence(rule, after);

      expect(next, isNull);
    });

    // 12. JSON round-trip: rule -> JSON -> rule
    test('12. JSON round-trip: rule -> JSON -> rule', () {
      final original = RecurrenceRule(
        frequency: RecurrenceFrequency.weekdays,
        interval: 2,
        byWeekdays: [DateTime.monday, DateTime.wednesday, DateTime.friday],
        startDate: DateTime(2026, 5, 25),
        endDate: DateTime(2026, 6, 18, 13, 0),
        hour: 9,
        minute: 0,
        endHour: 13,
        endMinute: 0,
      );

      final jsonStr = original.toJson();
      final restored = RecurrenceRule.fromJson(jsonStr);

      expect(restored, equals(original));
      expect(restored.frequency, RecurrenceFrequency.weekdays);
      expect(restored.interval, 2);
      expect(restored.byWeekdays, [DateTime.monday, DateTime.wednesday, DateTime.friday]);
      expect(restored.startDate, DateTime(2026, 5, 25));
      expect(restored.endDate, DateTime(2026, 6, 18, 13, 0));
      expect(restored.hour, 9);
      expect(restored.minute, 0);
      expect(restored.endHour, 13);
      expect(restored.endMinute, 0);
    });
  });
}
