import 'package:flutter_test/flutter_test.dart';

import '../lib/core/scheduling/astra_schedule_resolver.dart';
import '../lib/models/task.dart';
import '../lib/services/assistant/astra_recurrence_engine.dart';

Task _task({
  String title = 'Task',
  DateTime? dueDate,
  String? dueTime,
  RecurrenceRule? recurrenceRule,
  DateTime? startAt,
  DateTime? endAt,
  String status = 'active',
}) {
  return Task(
    id: title,
    title: title,
    dueDate: dueDate,
    dueTime: dueTime,
    recurrenceRule: recurrenceRule,
    startAt: startAt,
    endAt: endAt,
    status: status,
    createdAt: DateTime(2026, 8, 20, 15),
  );
}

void main() {
  group('AstraScheduleResolver', () {
    const resolver = AstraScheduleResolver();
    final now = DateTime(2026, 8, 20, 15, 0); // Thursday 3 PM

    test('daily no-date + time resolves to the next occurrence', () {
      final task = _task(
        title: 'Gym',
        dueTime: '20:00',
        recurrenceRule: const RecurrenceRule(
          frequency: RecurrenceFrequency.daily,
          hour: 20,
          minute: 0,
        ),
      );

      final resolved = resolver.resolve(task: task, now: now);

      expect(resolved.isRecurring, isTrue);
      expect(resolved.isUpcoming, isTrue);
      expect(resolved.isOverdue, isFalse);
      expect(resolved.nextOccurrence, DateTime(2026, 8, 20, 20));
      expect(resolved.shouldScheduleReminder, isTrue);
    });

    test('daily recurring task after occurrence rolls to tomorrow', () {
      final afterOccurrence = DateTime(2026, 8, 20, 21);
      final task = _task(
        title: 'Gym',
        dueDate: DateTime(2026, 8, 19, 20), // stale seed date
        dueTime: '20:00',
        recurrenceRule: const RecurrenceRule(
          frequency: RecurrenceFrequency.daily,
          hour: 20,
          minute: 0,
        ),
      );

      final resolved = resolver.resolve(task: task, now: afterOccurrence);

      expect(resolved.nextOccurrence, DateTime(2026, 8, 21, 20));
      expect(resolved.isOverdue, isFalse);
      expect(resolved.isTomorrow, isTrue);
    });

    test('today past one-shot is overdue and cannot schedule a reminder', () {
      final task = _task(
        title: 'Exam',
        dueDate: DateTime(2026, 8, 20),
        dueTime: '10:00',
      );

      final resolved = resolver.resolve(task: task, now: now);

      expect(resolved.isPast, isTrue);
      expect(resolved.isUpcoming, isFalse);
      expect(resolved.isOverdue, isTrue);
      expect(resolved.shouldScheduleReminder, isFalse);
      expect(resolved.reminderRejectionReason, 'past');
    });

    test('today future one-shot is upcoming and schedules reminder', () {
      final task = _task(
        title: 'Exam',
        dueDate: DateTime(2026, 8, 20),
        dueTime: '18:00',
      );

      final resolved = resolver.resolve(task: task, now: now);

      expect(resolved.isUpcoming, isTrue);
      expect(resolved.isToday, isTrue);
      expect(resolved.isOverdue, isFalse);
      expect(resolved.effectiveDueAt, DateTime(2026, 8, 20, 18));
      expect(resolved.shouldScheduleReminder, isTrue);
    });

    test('all-day today is not overdue until the day ends', () {
      final task = _task(
        title: 'Read notice',
        dueDate: DateTime(2026, 8, 20),
      );

      final resolved = resolver.resolve(task: task, now: now);

      expect(resolved.isUpcoming, isTrue);
      expect(resolved.isToday, isTrue);
      expect(resolved.isOverdue, isFalse);
      expect(resolved.shouldScheduleReminder, isTrue);
    });

    test('past date one-shot is overdue and never schedules a past alarm', () {
      final task = _task(
        title: 'Old deadline',
        dueDate: DateTime(2026, 8, 19),
        dueTime: '10:00',
      );

      final resolved = resolver.resolve(task: task, now: now);

      expect(resolved.isOverdue, isTrue);
      expect(resolved.shouldScheduleReminder, isFalse);
    });

    test('bounded recurrence respects start and end dates', () {
      final task = _task(
        title: 'Training',
        dueTime: '20:00',
        recurrenceRule: RecurrenceRule(
          frequency: RecurrenceFrequency.daily,
          startDate: DateTime(2026, 8, 21),
          endDate: DateTime(2026, 8, 26, 23, 59),
          hour: 20,
          minute: 0,
        ),
      );

      final resolved = resolver.resolve(task: task, now: now);

      expect(resolved.nextOccurrence, DateTime(2026, 8, 21, 20));
      expect(resolved.isUpcoming, isTrue);
      expect(resolved.isOverdue, isFalse);
      expect(resolved.recurrenceStart, DateTime(2026, 8, 21));
      expect(resolved.recurrenceEnd, DateTime(2026, 8, 26, 23, 59));
    });

    test('weekdays schedule skips the weekend', () {
      final friday = DateTime(2026, 8, 21, 18); // Friday 6 PM
      final task = _task(
        title: 'Study',
        dueTime: '09:00',
        recurrenceRule: const RecurrenceRule(
          frequency: RecurrenceFrequency.weekdays,
          byWeekdays: [1, 2, 3, 4, 5],
          hour: 9,
          minute: 0,
        ),
      );

      final resolved = resolver.resolve(task: task, now: friday);

      expect(resolved.nextOccurrence, DateTime(2026, 8, 24, 9));
      expect(resolved.isOverdue, isFalse);
    });

    test('recurring reminder with large offset never schedules in the past', () {
      final task = _task(
        title: 'Tomorrow task',
        dueTime: '08:00',
        recurrenceRule: const RecurrenceRule(
          frequency: RecurrenceFrequency.daily,
          hour: 8,
          minute: 0,
        ),
      );

      final resolved = AstraScheduleResolver.resolve(
        task: task,
        now: DateTime(2026, 8, 20, 7, 30),
        reminderOffsetMinutes: 120,
      );

      expect(resolved.nextOccurrence, DateTime(2026, 8, 20, 8));
      expect(resolved.shouldScheduleReminder, isTrue);
      expect(resolved.reminderScheduleInstant, DateTime(2026, 8, 20, 8));
    });

    test('completed recurring task never produces a reminder', () {
      final task = _task(
        title: 'Gym',
        dueTime: '20:00',
        status: 'completed',
        recurrenceRule: const RecurrenceRule(
          frequency: RecurrenceFrequency.daily,
          hour: 20,
          minute: 0,
        ),
      );

      final resolved = resolver.resolve(task: task, now: now);

      expect(resolved.shouldScheduleReminder, isFalse);
      expect(resolved.isUpcoming, isFalse);
    });
  });
}
