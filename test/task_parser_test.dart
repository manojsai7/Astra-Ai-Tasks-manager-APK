import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:astra/core/parser/task_parser.dart';
import 'package:astra/core/time/astra_clock.dart';

void main() {
  setUpAll(() {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
  });

  // Fixed reference: Thursday Aug 13, 2026 at 2:00 PM IST
  final refTime = DateTime(2026, 8, 13, 14, 0, 0);

  setUp(() {
    TaskParser.setClock(FixedAstraClock(refTime));
    TaskParser.setTimezone('Asia/Kolkata');
  });

  tearDown(() {
    TaskParser.resetClock();
  });

  group('TaskParser — relative reminders', () {
    test('in 2 mins', () {
      final parsed = TaskParser.parse('remind me to drink water in 2 mins');
      expect(parsed.title.toLowerCase(), contains('drink water'));
      expect(parsed.remindAt, isNotNull);
      expect(parsed.remindAt!.difference(refTime).inMinutes, 2);
    });

    test('in the next 2 mins', () {
      final parsed = TaskParser.parse('remind me to drink water in the next 2 mins');
      expect(parsed.title.toLowerCase(), contains('drink water'));
      expect(parsed.remindAt, isNotNull);
      expect(parsed.remindAt!.difference(refTime).inMinutes, 2);
    });

    test('in 2 minutes', () {
      final parsed = TaskParser.parse('remind me to drink water in 2 minutes');
      expect(parsed.remindAt!.difference(refTime).inMinutes, 2);
    });

    test('after 2 minutes', () {
      final parsed = TaskParser.parse('remind me to drink water after 2 minutes');
      expect(parsed.remindAt!.difference(refTime).inMinutes, 2);
    });
  });

  group('TaskParser — day + time', () {
    test('tomorrow at 10am', () {
      final parsed = TaskParser.parse('remind me to drink water tomorrow at 10am');
      expect(parsed.title.toLowerCase(), contains('drink water'));
      expect(parsed.remindAt, isNotNull);
      expect(parsed.remindAt!.year, 2026);
      expect(parsed.remindAt!.month, 8);
      expect(parsed.remindAt!.day, 14);
      expect(parsed.remindAt!.hour, 10);
      expect(parsed.remindAt!.minute, 0);
    });

    test('tomorrow 10:30 pm', () {
      final parsed = TaskParser.parse('remind me tomorrow 10:30 pm to sleep');
      expect(parsed.remindAt!.day, 14);
      expect(parsed.remindAt!.hour, 22);
      expect(parsed.remindAt!.minute, 30);
    });

    test('next Monday at 9am', () {
      // Aug 13 2026 is Thursday → next Monday is Aug 17
      final parsed = TaskParser.parse('schedule exam next Monday at 9am');
      expect(parsed.title.toLowerCase(), contains('exam'));
      expect(parsed.remindAt!.day, 17);
      expect(parsed.remindAt!.hour, 9);
    });

    test('Friday at 4pm', () {
      // Next Friday from Thu Aug 13 is Aug 14
      final parsed = TaskParser.parse('meeting Friday at 4pm');
      expect(parsed.remindAt!.day, 14);
      expect(parsed.remindAt!.hour, 16);
    });

    test('at 7pm (today, rolls forward if past)', () {
      final parsed = TaskParser.parse('call mom at 7pm');
      expect(parsed.remindAt!.hour, 19);
      expect(parsed.remindAt!.minute, 0);
    });
  });

  group('TaskParser — organization + academic broadcast', () {
    test('exam tomorrow at 10am by Microsoft', () {
      final parsed = TaskParser.parse(
        'Dear students, you have an exam tomorrow at 10am by Microsoft.',
      );
      expect(parsed.title.toLowerCase(), contains('exam'));
      expect(parsed.organization, 'Microsoft');
      expect(parsed.remindAt!.day, 14);
      expect(parsed.remindAt!.hour, 10);
      expect(parsed.timezone, 'Asia/Kolkata');
    });

    test('title is not corrupted by global at/with removal', () {
      final parsed = TaskParser.parse('remind me to meet with John at 5pm');
      expect(parsed.title.toLowerCase(), contains('with'));
      expect(parsed.remindAt!.hour, 17);
    });
  });

  group('TaskParser — priority', () {
    test('urgent keyword sets high priority', () {
      final parsed = TaskParser.parse('urgent: submit report tomorrow');
      expect(parsed.priority, 'high');
    });
  });
}
