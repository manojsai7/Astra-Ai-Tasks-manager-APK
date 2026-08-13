import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:astra/core/commands/astra_command.dart';
import 'package:astra/core/commands/astra_command_bus.dart';
import 'package:astra/core/commands/astra_response.dart';
import 'package:astra/core/commands/astra_response_builder.dart';
import 'package:astra/core/parser/task_parser.dart';
import 'package:astra/core/reminders/reminder.dart';
import 'package:astra/core/time/astra_clock.dart';

void main() {
  final bus = AstraCommandBus();

  setUpAll(() {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
  });

  setUp(() {
    // Fixed base clock: 2026-08-13 (Thursday) 14:00 (2:00 PM) IST
    TaskParser.setClock(FixedAstraClock(DateTime(2026, 8, 13, 14, 0)));
    TaskParser.setTimezone('Asia/Kolkata');
  });

  tearDown(() => TaskParser.resetClock());

  group('AstraCommandBus Intent & Prefix Classification', () {
    test('remind me to drink water in 2 mins -> CREATE_REMINDER', () {
      final cmd = bus.parse('remind me to drink water in 2 mins');
      expect(cmd.intent, AstraIntent.createReminder);
      expect(cmd.intentConfidence, greaterThan(0.9));
    });

    test('remind me to drink water in the next two minutes -> CREATE_REMINDER', () {
      final cmd = bus.parse('remind me to drink water in the next two minutes');
      expect(cmd.intent, AstraIntent.createReminder);
    });

    test('notify me to drink water in 2 minutes -> CREATE_REMINDER', () {
      final cmd = bus.parse('notify me to drink water in 2 minutes');
      expect(cmd.intent, AstraIntent.createReminder);
    });

    test('notify with timezone noise still routes to CREATE_REMINDER', () {
      final cmd = bus.parse('Notify me to Drink water in next minute indian standard time');
      expect(cmd.intent, AstraIntent.createReminder);
      expect(cmd.intent, isNot(AstraIntent.currentTime));
    });

    test('alert me about my exam tomorrow at 10am -> CREATE_REMINDER', () {
      final cmd = bus.parse('alert me about my exam tomorrow at 10am');
      expect(cmd.intent, AstraIntent.createReminder);
    });

    test("don't let me forget my exam tomorrow at 10 -> CREATE_REMINDER", () {
      final cmd = bus.parse("don't let me forget my exam tomorrow at 10");
      expect(cmd.intent, AstraIntent.createReminder);
    });

    test('make sure I remember to drink water -> CREATE_REMINDER', () {
      final cmd = bus.parse('make sure I remember to drink water in 10 minutes');
      expect(cmd.intent, AstraIntent.createReminder);
    });

    test('remember to call dad tomorrow at 5pm -> CREATE_REMINDER', () {
      final cmd = bus.parse('remember to call dad tomorrow at 5pm');
      expect(cmd.intent, AstraIntent.createReminder);
    });

    test('schedule a reminder for meeting tomorrow at 4pm -> CREATE_REMINDER', () {
      final cmd = bus.parse('schedule a reminder for meeting tomorrow at 4pm');
      expect(cmd.intent, AstraIntent.createReminder);
    });

    test('/task drink water in 2 minutes -> explicit task mode override', () {
      final cmd = bus.parse('/task drink water in 2 minutes');
      expect(cmd.intent, AstraIntent.createReminder);
      expect(cmd.mode, AstraCommandMode.task);
      expect(cmd.intentConfidence, greaterThanOrEqualTo(0.99));
    });

    test('@task exam tomorrow at 10am by Microsoft -> explicit task mode override', () {
      final cmd = bus.parse('@task exam tomorrow at 10am by Microsoft');
      expect(cmd.intent, AstraIntent.createReminder);
      expect(cmd.mode, AstraCommandMode.task);
    });

    test('/calendar tomorrow 4pm meeting -> explicit calendar mode', () {
      final cmd = bus.parse('/calendar tomorrow 4pm meeting');
      expect(cmd.mode, AstraCommandMode.calendar);
    });

    test('/mail latest important -> explicit mail mode', () {
      final cmd = bus.parse('/mail latest important');
      expect(cmd.mode, AstraCommandMode.mail);
      expect(cmd.intent, AstraIntent.latestEmail);
    });

    test('/panchang tomorrow -> explicit panchang mode', () {
      final cmd = bus.parse('/panchang tomorrow');
      expect(cmd.mode, AstraCommandMode.panchang);
      expect(cmd.intent, AstraIntent.panchang);
    });

    test('create a task without reminder language routes to createTask', () {
      final cmd = bus.parse('create a task to submit assignment');
      expect(cmd.intent, AstraIntent.createTask);
    });

    test('mark drink water complete routes to completeTask', () {
      final cmd = bus.parse('mark drink water complete');
      expect(cmd.intent, AstraIntent.completeTask);
    });

    test('cancel reminder routes to cancelReminder', () {
      final cmd = bus.parse('cancel my water reminder');
      expect(cmd.intent, AstraIntent.cancelReminder);
    });

    test('snooze reminder routes to snoozeReminder', () {
      final cmd = bus.parse('snooze my water reminder 10 minutes');
      expect(cmd.intent, AstraIntent.snoozeReminder);
    });

    test('current time queries route to currentTime', () {
      expect(bus.parse("what's the time").intent, AstraIntent.currentTime);
      expect(bus.parse("what time is it").intent, AstraIntent.currentTime);
      expect(bus.parse("current time").intent, AstraIntent.currentTime);
      expect(bus.parse("tell me the time").intent, AstraIntent.currentTime);
    });

    test('current date queries route to currentDate', () {
      expect(bus.parse("what's today's date").intent, AstraIntent.currentDate);
      expect(bus.parse("today's date").intent, AstraIntent.currentDate);
    });
  });

  group('Sentiment and Urgency Signals (Metadata Only)', () {
    test('frustrated sentiment + high urgency extracted without altering intent', () {
      final cmd = bus.parse("I'm freaking out, remind me to submit this stupid application tomorrow at 9.");
      expect(cmd.intent, AstraIntent.createReminder);
      expect(cmd.sentiment, Sentiment.frustrated);
      expect(cmd.urgency, Urgency.high);
    });

    test('asap creates critical urgency', () {
      final cmd = bus.parse('asap remind me to send email in 5 minutes');
      expect(cmd.intent, AstraIntent.createReminder);
      expect(cmd.urgency, Urgency.critical);
    });

    test('positive sentiment detected', () {
      final cmd = bus.parse('awesome thanks remind me tomorrow at 10');
      expect(cmd.sentiment, Sentiment.positive);
    });
  });

  group('Deterministic TaskParser Temporal Intelligence', () {
    test('remind me to drink water in 2 mins -> +2 minutes', () {
      final parsed = TaskParser.parse('remind me to drink water in 2 mins');
      expect(parsed.remindAt, isNotNull);
      expect(parsed.remindAt!.difference(DateTime(2026, 8, 13, 14, 0)).inMinutes, 2);
      expect(parsed.title, 'Drink Water');
    });

    test('notify me in next minute -> +1 minute', () {
      final parsed = TaskParser.parse('notify me to drink water in next minute');
      expect(parsed.remindAt, isNotNull);
      expect(parsed.remindAt!.difference(DateTime(2026, 8, 13, 14, 0)).inMinutes, 1);
      expect(parsed.title, 'Drink Water');
    });

    test('notify me in the next two minutes -> +2 minutes', () {
      final parsed = TaskParser.parse('notify me to drink water in the next two minutes');
      expect(parsed.remindAt, isNotNull);
      expect(parsed.remindAt!.difference(DateTime(2026, 8, 13, 14, 0)).inMinutes, 2);
    });

    test('yo don\'t let me forget water in like 20 mins -> +20 minutes', () {
      final parsed = TaskParser.parse("yo don't let me forget water in like 20 mins");
      expect(parsed.remindAt, isNotNull);
      expect(parsed.remindAt!.difference(DateTime(2026, 8, 13, 14, 0)).inMinutes, 20);
      expect(parsed.title, 'Water');
    });

    test('alert me about my exam tomorrow at 10am -> tomorrow 10:00 AM', () {
      final parsed = TaskParser.parse('alert me about my exam tomorrow at 10am');
      expect(parsed.remindAt, isNotNull);
      expect(parsed.remindAt!.year, 2026);
      expect(parsed.remindAt!.month, 8);
      expect(parsed.remindAt!.day, 14);
      expect(parsed.remindAt!.hour, 10);
      expect(parsed.remindAt!.minute, 0);
    });

    test('don\'t let me forget my exam tomorrow at 10 -> tomorrow 10:00 AM', () {
      final parsed = TaskParser.parse("don't let me forget my exam tomorrow at 10");
      expect(parsed.remindAt, isNotNull);
      expect(parsed.remindAt!.day, 14);
      expect(parsed.remindAt!.hour, 10);
    });

    test('@task exam tomorrow at 10am by Microsoft -> title, date, org', () {
      final parsed = TaskParser.parse('@task exam tomorrow at 10am by Microsoft');
      expect(parsed.title, contains('Exam'));
      expect(parsed.remindAt, isNotNull);
      expect(parsed.remindAt!.hour, 10);
      expect(parsed.organization, 'Microsoft');
    });

    test('remind me Friday at 5pm -> Friday 17:00', () {
      // 2026-08-13 is Thursday, so Friday is 2026-08-14
      final parsed = TaskParser.parse('remind me to attend demo Friday at 5pm');
      expect(parsed.remindAt, isNotNull);
      expect(parsed.remindAt!.day, 14);
      expect(parsed.remindAt!.hour, 17);
      expect(parsed.remindAt!.minute, 0);
    });

    test('August 20 at 7pm -> month date parsing', () {
      final parsed = TaskParser.parse('remind me team dinner August 20 at 7pm');
      expect(parsed.remindAt, isNotNull);
      expect(parsed.remindAt!.month, 8);
      expect(parsed.remindAt!.day, 20);
      expect(parsed.remindAt!.hour, 19);
      expect(parsed.remindAt!.minute, 0);
    });

    test('Multi-line teacher notification with subtasks', () {
      const input = '''Dear students, you have your Microsoft exam tomorrow at 10am by Microsoft.
- Prepare chapters 4
- Prepare chapters 5
- Bring ID''';
      final parsed = TaskParser.parse(input);
      expect(parsed.remindAt, isNotNull);
      expect(parsed.remindAt!.hour, 10);
      expect(parsed.organization, 'Microsoft');
      expect(parsed.subtasks.length, 3);
      expect(parsed.subtasks[0].name, 'Prepare Chapters 4');
      expect(parsed.subtasks[1].name, 'Prepare Chapters 5');
      expect(parsed.subtasks[2].name, 'Bring ID');
    });
  });

  group('Structured AstraResponse Rendering', () {
    test('taskCreated builds structured response with actions', () {
      final resp = AstraResponseBuilder.taskCreated(
        title: 'Drink Water',
        dueAt: DateTime(2026, 8, 13, 14, 2),
        timezone: 'Asia/Kolkata',
        priority: 'medium',
        notificationOutcome: ScheduleOutcome.scheduled,
        taskId: 'test_123',
      );

      expect(resp.type, AstraResponseType.taskCreated);
      expect(resp.headline, 'Task created');
      expect(resp.lines.any((l) => l.value == 'Drink Water' && l.highlight), isTrue);
      expect(resp.lines.any((l) => l.label == 'Timezone' && l.value == 'Asia/Kolkata'), isTrue);
      expect(resp.lines.any((l) => l.label == 'Notification' && l.value == 'Scheduled'), isTrue);
      expect(resp.actions.length, 2);
      expect(resp.actions[0].label, 'DONE');
      expect(resp.actions[1].label, 'SNOOZE 10m');
      expect(resp.toPlainText(), isNot(contains('***')));
    });

    test('taskCompleted builds clean structured response', () {
      final resp = AstraResponseBuilder.taskCompleted('Drink Water');
      expect(resp.type, AstraResponseType.taskCompleted);
      expect(resp.headline, 'Task completed');
      expect(resp.toPlainText(), contains('Drink Water'));
      expect(resp.toPlainText(), isNot(contains('***')));
    });

    test('reminderCancelled and reminderSnoozed build structured responses', () {
      final cancel = AstraResponseBuilder.reminderCancelled('Drink Water');
      expect(cancel.type, AstraResponseType.reminderCancelled);

      final snooze = AstraResponseBuilder.reminderSnoozed('Drink Water', const Duration(minutes: 10));
      expect(snooze.type, AstraResponseType.reminderSnoozed);
      expect(snooze.lines.any((l) => l.value == '10 minutes'), isTrue);
    });
  });
}
