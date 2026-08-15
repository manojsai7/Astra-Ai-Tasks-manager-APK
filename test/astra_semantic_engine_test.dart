import 'package:flutter_test/flutter_test.dart';

import 'package:astra/services/assistant/astra_semantic_engine.dart';

void main() {
  const engine = AstraSemanticEngine();

  final now = DateTime(
    2026,
    8,
    15,
    12,
    4,
  );

  group('ASTRA integrated semantic engine', () {
    test(
      'exam today at 6pm resolves fully',
      () {
        final result = engine.resolve(
          text:
              'bruh i have exam today at 6pm',
          intent: 'CREATE_TASK',
          now: now,
        );

        expect(result.eventType, 'EXAM');
        expect(result.action, 'ATTEND');

        expect(
          result.temporal.eventStart,
          DateTime(
            2026,
            8,
            15,
            18,
            0,
          ),
        );

        expect(
          result.route,
          'EXECUTE',
        );
      },
    );

    test(
      'Microsoft interview resolves weekday + time',
      () {
        final result = engine.resolve(
          text:
              'Microsoft interview Monday at 11am',
          intent: 'CREATE_CALENDAR_EVENT',
          now: now,
        );

        expect(
          result.eventType,
          'INTERVIEW',
        );

        expect(
          result.action,
          'ATTEND',
        );

        expect(
          result.temporal.eventStart,
          DateTime(
            2026,
            8,
            17,
            11,
            0,
          ),
        );
      },
    );

    test(
      'fee deadline resolves correctly',
      () {
        final result = engine.resolve(
          text:
              'last date to pay fee is Friday at 10pm',
          intent: 'CREATE_TASK',
          now: now,
        );

        expect(
          result.eventType,
          'FEE',
        );

        expect(
          result.action,
          'PAY',
        );

        expect(
          result.temporal.deadline,
          DateTime(
            2026,
            8,
            21,
            22,
            0,
          ),
        );

        expect(
          result.route,
          'EXECUTE',
        );
      },
    );

    test(
      'ambiguous assignment deadline requires confirmation',
      () {
        final result = engine.resolve(
          text:
              'submit assignment tomorrow by 5',
          intent: 'CREATE_TASK',
          now: now,
        );

        expect(
          result.eventType,
          'ASSIGNMENT',
        );

        expect(
          result.action,
          'SUBMIT',
        );

        expect(
          result.temporal.ambiguous,
          true,
        );

        expect(
          result.requiresConfirmation,
          true,
        );

        expect(
          result.route,
          'CONFIRM',
        );
      },
    );

    test(
      'NPTEL form keeps explicit time but unknown date',
      () {
        final result = engine.resolve(
          text:
              'fill the NPTEL form before 4pm',
          intent: 'CREATE_TASK',
          now: now,
        );

        expect(
          result.eventType,
          'FORM',
        );

        expect(
          result.action,
          'FILL',
        );

        expect(
          result.temporal.eventStart,
          isNull,
        );

        expect(
          result.temporal.deadline,
          isNull,
        );

        expect(
          result.requiresConfirmation,
          true,
        );
      },
    );

    test(
      'training range and recurrence survive',
      () {
        final result = engine.resolve(
          text:
              'Campus Recruitment Training from '
              '25th May 2026 to 18th June 2026 '
              'from 09:00 AM to 01:00 PM every day',
          intent: 'CREATE_TASK',
          now: now,
        );

        expect(
          result.eventType,
          'TRAINING',
        );

        expect(
          result.action,
          'ATTEND',
        );

        expect(
          result.recurrence,
          'DAILY',
        );

        expect(
          result.temporal.eventStart,
          DateTime(
            2026,
            5,
            25,
            9,
            0,
          ),
        );

        expect(
          result.temporal.eventEnd,
          DateTime(
            2026,
            6,
            18,
            13,
            0,
          ),
        );
      },
    );

    test(
      'hall ticket becomes document collection',
      () {
        final result = engine.resolve(
          text:
              'Please collect your hall ticket from the office before 5 PM.',
          intent: 'CREATE_TASK',
          now: now,
        );

        expect(
          result.eventType,
          'DOCUMENT',
        );

        expect(
          result.action,
          'COLLECT',
        );

        expect(
          result.title,
          'Hall Ticket',
        );

        expect(
          result.requiresConfirmation,
          true,
        );
      },
    );

    test(
      'scholarship application gets correct semantic type',
      () {
        final result = engine.resolve(
          text:
              'The scholarship application form must be submitted by 31st March 2026.',
          intent: 'CREATE_TASK',
          now: now,
        );

        expect(
          result.eventType,
          'APPLICATION',
        );

        expect(
          result.action,
          'SUBMIT',
        );

        expect(
          result.title,
          'Scholarship Application',
        );
      },
    );

    test(
      'remind me to drink water in 2 mins extracts clean title and creates reminder',
      () {
        final result = engine.resolve(
          text: 'remind me to drink water in 2 mins',
          intent: 'CREATE_REMINDER',
          now: now,
        );

        expect(result.title, 'Drink water');
        expect(result.intent, 'CREATE_REMINDER');
        expect(result.eventType, 'OTHER');
        expect(result.action, isNull);
        expect(result.route, 'EXECUTE');
      },
    );

    test(
      'remind me to submit the assignment tomorrow extracts clean title',
      () {
        final result = engine.resolve(
          text: 'remind me to submit the assignment tomorrow',
          intent: 'CREATE_REMINDER',
          now: now,
        );

        expect(result.title, 'Submit the assignment');
      },
    );

    test(
      'remind me to call mom at 7pm extracts clean title',
      () {
        final result = engine.resolve(
          text: 'remind me to call mom at 7pm',
          intent: 'CREATE_REMINDER',
          now: now,
        );

        expect(result.title, 'Call mom');
      },
    );

    test(
      'Microsoft interview Monday at 11am produces organization-aware title',
      () {
        final result = engine.resolve(
          text: 'Microsoft interview Monday at 11am',
          intent: 'CREATE_CALENDAR_EVENT',
          now: now,
        );

        expect(result.title, 'Microsoft Interview');
        expect(result.organization, 'Microsoft');
        expect(result.eventType, 'INTERVIEW');
        expect(result.action, 'ATTEND');
        expect(result.route, 'EXECUTE');
      },
    );

    test(
      'fill the NPTEL form before 4pm produces organization-aware title',
      () {
        final result = engine.resolve(
          text: 'fill the NPTEL form before 4pm',
          intent: 'CREATE_TASK',
          now: now,
        );

        expect(result.title, 'NPTEL Form');
        expect(result.organization, 'NPTEL');
        expect(result.eventType, 'FORM');
      },
    );
  });
}

