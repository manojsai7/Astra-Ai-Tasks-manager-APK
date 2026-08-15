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
}
