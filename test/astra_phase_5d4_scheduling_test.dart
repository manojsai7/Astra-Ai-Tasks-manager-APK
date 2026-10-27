// test/astra_phase_5d4_scheduling_test.dart
// Phase 5D.4 Canonical Schedule Resolver Permutation Matrix Tests
// Verifies ASTRA Blueprint Section 7 invariants across recurring, one-shot, snooze, and restore flows.

import 'package:flutter_test/flutter_test.dart';
import 'package:astra/services/task/astra_schedule_resolver.dart';

void main() {
  final DateTime refNow = DateTime(2026, 8, 20, 15, 0); // Thursday 3:00 PM

  group('Phase 5D.4 Canonical AstraScheduleResolver Matrix', () {
    test(
      'A: Unscheduled task (no date, no time, no recurrence) -> unscheduled bucket, no reminder',
      () {
        final res = AstraScheduleResolver.resolve(
          isCompleted: false,
          dueDate: null,
          dueTime: null,
          isRecurring: false,
          now: refNow,
        );

        expect(res.bucket, AstraScheduleBucket.unscheduled);
        expect(res.effectiveDueAt, isNull);
        expect(res.shouldScheduleReminder, isFalse);
        expect(
          res.rejectionReason,
          AstraReminderRejectionReason.noTargetTimestamp,
        );
      },
    );

    test(
      'C & K: "Gym daily at 8 PM" (no date + 20:00 + daily) before 8 PM -> today 20:00, never overdue',
      () {
        final res = AstraScheduleResolver.resolve(
          isCompleted: false,
          dueDate: null,
          dueTime: '20:00',
          isRecurring: true,
          now: refNow,
        );

        expect(res.effectiveDueAt, DateTime(2026, 8, 20, 20, 0));
        expect(res.isOverdue, isFalse);
        expect(res.isToday, isTrue);
        expect(res.bucket, AstraScheduleBucket.today);
        expect(res.shouldScheduleReminder, isTrue);
        expect(res.effectiveReminderAt, DateTime(2026, 8, 20, 20, 0));
      },
    );

    test(
      'D & E: "Gym daily at 8 PM" with stale seed date after 8 PM (now = 9 PM) -> tomorrow 20:00',
      () {
        final DateTime ninePm = DateTime(2026, 8, 20, 21, 0);
        final DateTime staleSeed = DateTime(2026, 8, 10, 20, 0);

        final res = AstraScheduleResolver.resolve(
          isCompleted: false,
          dueDate: staleSeed,
          dueTime: '20:00',
          isRecurring: true,
          now: ninePm,
        );

        expect(res.effectiveDueAt, DateTime(2026, 8, 21, 20, 0));
        expect(res.isOverdue, isFalse);
        expect(res.isTomorrow, isTrue);
        expect(res.bucket, AstraScheduleBucket.tomorrow);
        expect(res.shouldScheduleReminder, isTrue);
      },
    );

    test(
      'F & O: Today past one-shot ("Exam today at 10 AM" when now is 3 PM) -> overdue, past alarm rejected',
      () {
        final res = AstraScheduleResolver.resolve(
          isCompleted: false,
          dueDate: DateTime(2026, 8, 20),
          dueTime: '10:00',
          isRecurring: false,
          now: refNow,
        );

        expect(res.isOverdue, isTrue);
        expect(res.bucket, AstraScheduleBucket.overdue);
        expect(res.shouldScheduleReminder, isFalse);
        expect(res.effectiveReminderAt, isNull);
        expect(res.rejectionReason, AstraReminderRejectionReason.pastDueTime);
      },
    );

    test(
      'I: Bounded recurrence ("Gym daily at 8 PM from tomorrow till next Wednesday") respects start & end window',
      () {
        final DateTime startTomorrow = DateTime(2026, 8, 21);
        final DateTime endNextWed = DateTime(2026, 8, 26);

        final res = AstraScheduleResolver.resolve(
          isCompleted: false,
          dueDate: null,
          dueTime: '20:00',
          isRecurring: true,
          recurrenceStart: startTomorrow,
          recurrenceEnd: endNextWed,
          now: refNow,
        );

        expect(res.effectiveDueAt, DateTime(2026, 8, 21, 20, 0));
        expect(res.bucket, AstraScheduleBucket.tomorrow);
        expect(res.shouldScheduleReminder, isTrue);

        final expiredRes = AstraScheduleResolver.resolve(
          isCompleted: false,
          dueDate: null,
          dueTime: '20:00',
          isRecurring: true,
          recurrenceStart: startTomorrow,
          recurrenceEnd: endNextWed,
          now: DateTime(2026, 8, 27, 9, 0),
        );

        expect(expiredRes.effectiveDueAt, isNull);
        expect(expiredRes.shouldScheduleReminder, isFalse);
        expect(
          expiredRes.rejectionReason,
          AstraReminderRejectionReason.outsideRecurrenceWindow,
        );
      },
    );

    test(
      'Q: Recurring SNOOZE (+10m) shifts current reminder without mutating recurrence dueTime',
      () {
        final DateTime eightPm = DateTime(2026, 8, 20, 20, 0);
        final DateTime snoozedTarget = DateTime(2026, 8, 20, 20, 10);

        final res = AstraScheduleResolver.resolve(
          isCompleted: false,
          dueDate: DateTime(2026, 8, 20),
          dueTime: '20:00',
          isRecurring: true,
          computeNextOccurrence: (_) => DateTime(2026, 8, 21, 20, 0),
          snoozedUntil: snoozedTarget,
          now: eightPm,
        );

        expect(res.dueTime, '20:00');
        expect(res.shouldScheduleReminder, isTrue);
        expect(res.effectiveReminderAt, snoozedTarget);
      },
    );
  });
}
