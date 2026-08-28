import 'package:flutter_test/flutter_test.dart';

import 'package:astra/services/assistant/astra_temporal_engine.dart';

void main() {
  const engine = AstraTemporalEngine();

  final now = DateTime(
    2026,
    8,
    15,
    12,
    1,
  );

  group('ASTRA temporal engine', () {
    test(
      'today at 6pm',
      () {
        final result = engine.parse(
          'bruh i have exam today at 6pm',
          now: now,
        );

        expect(
          result.eventStart,
          DateTime(2026, 8, 15, 18, 0),
        );
      },
    );

    test(
      'tomorrow',
      () {
        final result = engine.parse(
          'submit assignment tomorrow',
          now: now,
        );

        expect(
          result.eventStart,
          DateTime(2026, 8, 16),
        );
      },
    );

    test(
      'weekday with time',
      () {
        final result = engine.parse(
          'Microsoft interview Monday at 11am',
          now: now,
        );

        expect(
          result.eventStart,
          DateTime(2026, 8, 17, 11, 0),
        );
      },
    );

    test(
      'explicit date range and time range',
      () {
        final result = engine.parse(
          'training from 25th May 2026 to 18th June 2026 '
          'from 09:00 AM to 01:00 PM every day',
          now: now,
        );

        expect(
          result.eventStart,
          DateTime(2026, 5, 25, 9, 0),
        );

        expect(
          result.eventEnd,
          DateTime(2026, 6, 18, 13, 0),
        );

        expect(
          result.recurrence,
          'DAILY',
        );
      },
    );

    test(
      'deadline with explicit time',
      () {
        final result = engine.parse(
          'last date to pay fee is Friday at 10pm',
          now: now,
          isDeadline: true,
        );

        expect(
          result.deadline,
          DateTime(2026, 8, 21, 22, 0),
        );

        expect(
          result.ambiguous,
          false,
        );
      },
    );

    test(
      'bare deadline hour remains ambiguous',
      () {
        final result = engine.parse(
          'submit assignment tomorrow by 5',
          now: now,
          isDeadline: true,
        );

        expect(
          result.ambiguous,
          true,
        );

        expect(
          result.deadline,
          DateTime(2026, 8, 16),
        );

        expect(
          result.warnings.isNotEmpty,
          true,
        );
      },
    );

    test(
      'weekday recurrence',
      () {
        final result = engine.parse(
          'training every weekday from 9 AM to 1 PM',
          now: now,
        );

        expect(
          result.recurrence,
          'WEEKDAYS',
        );

        expect(
          result.eventStart,
          isNull,
        );

        expect(
          result.ambiguous,
          false,
        );
      },
    );

    test('today at 6pm when now is 9pm -> ambiguous = true, past warning', () {
      final nightTime = DateTime(2026, 8, 15, 21, 0); // 9:00 PM
      final result = engine.parse('exam today at 6pm', now: nightTime);

      expect(result.eventStart, DateTime(2026, 8, 15, 18, 0));
      expect(result.ambiguous, isTrue);
      expect(result.warnings.isNotEmpty, isTrue);
      expect(result.warnings.first, contains('already passed'));
    });

    test('today at 10pm when now is 9pm -> ambiguous = false, future valid', () {
      final nightTime = DateTime(2026, 8, 15, 21, 0); // 9:00 PM
      final result = engine.parse('exam today at 10pm', now: nightTime);

      expect(result.eventStart, DateTime(2026, 8, 15, 22, 0));
      expect(result.ambiguous, isFalse);
    });

    test('tomorrow at 6pm when now is 9pm -> ambiguous = false, future valid', () {
      final nightTime = DateTime(2026, 8, 15, 21, 0); // 9:00 PM
      final result = engine.parse('exam tomorrow at 6pm', now: nightTime);

      expect(result.eventStart, DateTime(2026, 8, 16, 18, 0));
      expect(result.ambiguous, isFalse);
    });

    test('explicit historical date -> ambiguous = true, past warning', () {
      final result = engine.parse('interview on 10 August 2025 at 10am', now: now);

      expect(result.eventStart, DateTime(2025, 8, 10, 10, 0));
      expect(result.ambiguous, isTrue);
      expect(result.warnings.isNotEmpty, isTrue);
    });
  });

  // ─── Named-weekday roll-forward ────────────────────────────────────────────
  //
  // A named weekday is an explicit anchor. When the named day IS today and the
  // requested time has already elapsed, the phrase means next week's occurrence
  // — never an instant in the past, and never a bare-time "did you mean
  // tomorrow?" prompt.
  group('ASTRA temporal engine — named weekday roll-forward', () {
    // 2026-08-15 is a Saturday; 2026-08-20 is a Thursday.

    test('named weekday is today and the time has passed -> next week', () {
      final saturdayNight = DateTime(2026, 8, 15, 21, 0);
      final result = engine.parse(
        'remind me about the report Saturday at 8pm',
        now: saturdayNight,
      );

      expect(result.eventStart, DateTime(2026, 8, 22, 20, 0));
      expect(result.ambiguous, isFalse);
      expect(result.warnings, isEmpty);
    });

    test('named weekday is today and the time is still ahead -> today', () {
      final saturdayNoon = DateTime(2026, 8, 15, 12, 1);
      final result = engine.parse(
        'remind me about the report Saturday at 8pm',
        now: saturdayNoon,
      );

      expect(result.eventStart, DateTime(2026, 8, 15, 20, 0));
      expect(result.ambiguous, isFalse);
    });

    test('named weekday is today with no time -> today, unchanged', () {
      final saturdayNoon = DateTime(2026, 8, 15, 12, 1);
      final result = engine.parse(
        'submit the report Saturday',
        now: saturdayNoon,
      );

      expect(result.eventStart, DateTime(2026, 8, 15));
    });

    test('named weekday exactly at the requested minute -> next week', () {
      final saturdayAtEight = DateTime(2026, 8, 15, 20, 0);
      final result = engine.parse(
        'call the team Saturday at 8pm',
        now: saturdayAtEight,
      );

      expect(result.eventStart, DateTime(2026, 8, 22, 20, 0));
    });

    test('"Thursday at 8pm" on a Thursday evening -> next Thursday', () {
      final thursdayNight = DateTime(2026, 8, 20, 21, 15);
      final result = engine.parse(
        'remind me about it Thursday at 8pm',
        now: thursdayNight,
      );

      expect(result.eventStart, DateTime(2026, 8, 27, 20, 0));
      expect(result.ambiguous, isFalse);
    });

    test('a future named weekday is unaffected by the time of day', () {
      final saturdayNight = DateTime(2026, 8, 15, 23, 30);
      final result = engine.parse(
        'Microsoft interview Monday at 11am',
        now: saturdayNight,
      );

      expect(result.eventStart, DateTime(2026, 8, 17, 11, 0));
      expect(result.ambiguous, isFalse);
    });
  });

  group('ASTRA temporal engine — date-only deadline for today', () {
    // A deadline with no clock time normalises to 00:00. That must not be read
    // as an elapsed instant when the date is today, or every "due Friday" said
    // on a Friday would route to CONFIRMATION_REQUIRED instead of executing.

    test('"due Friday" on a Friday afternoon is today and not ambiguous', () {
      // 2026-08-28 is a Friday.
      final fridayAfternoon = DateTime(2026, 8, 28, 15, 30);
      final result = engine.parse(
        'I have an assignment due Friday',
        now: fridayAfternoon,
        isDeadline: true,
      );

      expect(result.deadline, DateTime(2026, 8, 28));
      expect(result.ambiguous, isFalse);
      expect(result.warnings, isEmpty);
    });

    test('"due today" late at night is still not flagged as past', () {
      final lateNight = DateTime(2026, 8, 28, 23, 45);
      final result = engine.parse(
        'submit the report due today',
        now: lateNight,
        isDeadline: true,
      );

      expect(result.deadline, DateTime(2026, 8, 28));
      expect(result.ambiguous, isFalse);
    });

    test('a date-only deadline in the past is still flagged as ambiguous', () {
      final now = DateTime(2026, 8, 28, 10, 0);
      final result = engine.parse(
        'assignment due 10 August 2026',
        now: now,
        isDeadline: true,
      );

      expect(result.ambiguous, isTrue);
      expect(result.warnings, isNotEmpty);
    });

    test('a named time on today that has elapsed remains ambiguous', () {
      final fridayEvening = DateTime(2026, 8, 28, 21, 0);
      final result = engine.parse(
        'assignment due today at 8pm',
        now: fridayEvening,
        isDeadline: true,
      );

      expect(result.ambiguous, isTrue);
      expect(result.warnings, isNotEmpty);
    });
  });
}
