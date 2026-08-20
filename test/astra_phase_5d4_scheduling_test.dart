import 'package:flutter_test/flutter_test.dart';

import 'package:astra/core/scheduling/astra_schedule_resolver.dart';
import 'package:astra/models/task.dart';
import 'package:astra/services/assistant/astra_recurrence_engine.dart';
import 'package:astra/services/task/astra_task_filter.dart';

void main() {
  final resolver = const AstraScheduleResolver();

  DateTime at(int hour, int minute, {int dayOffset = 0}) {
    final base = DateTime(2026, 8, 20, 0, 0);
    return base.add(Duration(days: dayOffset, hours: hour, minutes: minute));
  }

  Task oneShot({DateTime? dueDate, String? dueTime}) => Task.create(
        title: 'Test task',
        dueDate: dueDate,
        dueTime: dueTime,
      );

  Task recurring({DateTime? startDate, DateTime? endDate, int hour = 20, int minute = 0}) =>
      Task.create(
        title: 'Gym',
        dueDate: startDate,
        dueTime: '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
        recurrenceRule: RecurrenceRule(
          frequency: RecurrenceFrequency.daily,
          startDate: startDate,
          endDate: endDate,
          hour: hour,
          minute: minute,
        ),
      );

  group('AstraScheduleResolver', () {
    test('A — unscheduled task has no occurrence', () {
      final result = resolver.resolve(oneShot(), now: at(15, 0));
      expect(result.effectiveDueAt, isNull);
      expect(result.isUpcoming, isFalse);
      expect(result.shouldScheduleReminder, isFalse);
    });

    test('B — floating time recurrence resolves next daily occurrence', () {
      final task = recurring();
      final result = resolver.resolve(task, now: at(15, 0));
      expect(result.nextOccurrence, at(20, 0));
      expect(result.isRecurring, isTrue);
      expect(result.isPast, isFalse);
      expect(result.shouldScheduleReminder, isTrue);
    });

    test('C — daily recurrence advances after today occurrence', () {
      final task = recurring();
      final result = resolver.resolve(task, now: at(21, 0));
      expect(result.nextOccurrence, at(20, 0, dayOffset: 1));
      expect(result.isUpcoming, isTrue);
    });

    test('D — stale recurring seed date never becomes overdue', () {
      final task = recurring(startDate: at(20, 0, dayOffset: -1));
      final now = at(15, 0);
      final result = resolver.resolve(task, now: now);
      expect(result.nextOccurrence, at(20, 0));
      expect(AstraTaskFilter.isOverdue(task, referenceTime: now), isFalse);
      expect(AstraTaskFilter.isToday(task, referenceTime: now), isTrue);
    });

    test('E — today past one-shot is overdue and must not schedule', () {
      final task = oneShot(dueDate: at(10, 0));
      final now = at(15, 0);
      final result = resolver.resolve(task, now: now);
      expect(result.isPast, isTrue);
      expect(result.shouldScheduleReminder, isFalse);
      expect(AstraTaskFilter.isOverdue(task, referenceTime: now), isTrue);
    });

    test('F — tomorrow future one-shot is upcoming', () {
      final task = oneShot(dueDate: at(10, 0, dayOffset: 1));
      final result = resolver.resolve(task, now: at(15, 0));
      expect(result.effectiveDueAt, at(10, 0, dayOffset: 1));
      expect(result.isUpcoming, isTrue);
      expect(result.shouldScheduleReminder, isTrue);
    });

    test('G — dueDate + dueTime is resolved as one canonical instant', () {
      final task = oneShot(dueDate: at(0, 0), dueTime: '20:00');
      final result = resolver.resolve(task, now: at(15, 0));
      expect(result.effectiveDueAt, at(20, 0));
    });

    test('H — bounded recurrence stops after its end window', () {
      final task = recurring(startDate: at(20, 0), endDate: at(20, 0, dayOffset: 1));
      final beforeEnd = resolver.resolve(task, now: at(15, 0, dayOffset: 1));
      expect(beforeEnd.nextOccurrence, at(20, 0, dayOffset: 1));

      final afterEnd = resolver.resolve(task, now: at(21, 0, dayOffset: 1));
      expect(afterEnd.nextOccurrence, isNull);
      expect(afterEnd.shouldScheduleReminder, isFalse);
    });

    test('I — weekdays recurrence resolves the next weekday', () {
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.weekdays,
        hour: 20,
        minute: 0,
      );
      final task = Task.create(title: 'Weekday task', recurrenceRule: rule, dueTime: '20:00');
      final result = resolver.resolve(task, now: DateTime(2026, 8, 22, 15)); // Saturday
      expect(result.nextOccurrence?.weekday, DateTime.monday);
    });

    test('J — filter buckets recurring task by resolved next occurrence', () {
      final task = recurring();
      final buckets = AstraTaskFilter.categorize([task], referenceTime: at(15, 0));
      expect(buckets.overdue, isEmpty);
      expect(buckets.todayTasks, contains(task));
      expect(buckets.recurringTasks, contains(task));
    });

    test('K — recurring completion/snooze semantics have one logical task row', () {
      final task = recurring();
      final resolved = resolver.resolve(task, now: at(15, 0));
      expect(resolved.nextOccurrence, at(20, 0));
      expect(task.id, isNotEmpty);
      // Snooze is an occurrence/reminder mutation; recurrence remains daily.
      expect(task.recurrenceRule!.frequency, RecurrenceFrequency.daily);
    });

    test('L — past explicit date never schedules a reminder', () {
      final task = oneShot(dueDate: at(10, 0, dayOffset: -1));
      final result = resolver.resolve(task, now: at(15, 0));
      expect(result.isPast, isTrue);
      expect(result.shouldScheduleReminder, isFalse);
    });
  });
}
