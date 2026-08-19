import 'package:flutter_test/flutter_test.dart';
import 'package:astra/core/time/astra_clock.dart';
import 'package:astra/core/time/astra_time_service.dart';
import 'package:astra/models/task.dart';
import 'package:astra/services/assistant/astra_recurrence_engine.dart';
import 'package:astra/services/task/astra_task_filter.dart';

void main() {
  group('ASTRA Pass 3A: Upcoming Tasks Correctness & Canonical Predicate Tests', () {
    late FixedAstraClock fixedClock;
    late AstraTimeService timeService;
    // Anchor reference time: Tuesday 18 August 2026, 11:00 AM
    final anchor = DateTime(2026, 8, 18, 11, 0);

    setUp(() {
      fixedClock = FixedAstraClock(anchor);
      timeService = AstraTimeService(clock: fixedClock);
    });

    test('A. Future one-shot task -> Upcoming', () {
      final taskTomorrow = Task(
        id: 'future_1',
        title: 'Submit quarterly report',
        dueDate: DateTime(2026, 8, 19, 15, 0), // Tomorrow 3:00 PM
        status: 'pending',
        createdAt: anchor,
      );

      final taskNextWeek = Task(
        id: 'future_2',
        title: 'Doctor Appointment',
        dueDate: DateTime(2026, 8, 25, 10, 0), // Next week
        status: 'active',
        createdAt: anchor,
      );

      expect(AstraTaskFilter.isUpcoming(taskTomorrow, timeService: timeService), isTrue);
      expect(AstraTaskFilter.isUpcoming(taskNextWeek, timeService: timeService), isTrue);
    });

    test('B. Overdue task -> Not Upcoming', () {
      final overdueTask = Task(
        id: 'overdue_1',
        title: 'Pay electricity bill',
        dueDate: DateTime(2026, 8, 17, 20, 0), // Yesterday
        status: 'pending',
        createdAt: anchor.subtract(const Duration(days: 2)),
      );

      final earlierTodayPastTask = Task(
        id: 'earlier_today',
        title: 'Morning stretch',
        dueDate: DateTime(2026, 8, 18, 8, 0), // Today 8:00 AM (< 11:00 AM)
        status: 'pending',
        createdAt: anchor.subtract(const Duration(days: 1)),
      );

      expect(AstraTaskFilter.isUpcoming(overdueTask, timeService: timeService), isFalse);
      expect(AstraTaskFilter.isOverdue(overdueTask, timeService: timeService), isTrue);
      expect(AstraTaskFilter.isUpcoming(earlierTodayPastTask, timeService: timeService), isFalse);
    });

    test('C. Task with null dueAt and no dates -> Not Upcoming', () {
      final noDateTask = Task(
        id: 'nodate_1',
        title: 'Someday read book',
        dueDate: null,
        startAt: null,
        endAt: null,
        recurrenceRule: null,
        status: 'pending',
        createdAt: anchor,
      );

      expect(AstraTaskFilter.isUpcoming(noDateTask, timeService: timeService), isFalse);
      expect(AstraTaskFilter.isOverdue(noDateTask, timeService: timeService), isFalse);
    });

    test('D. Recurring task -> Upcoming using next occurrence (Daily, Weekdays, Weekly, Monthly)', () {
      // 1. Daily task (Next occurrence: today 6pm or tomorrow 9am)
      const dailyRule = RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
        hour: 18,
        minute: 0,
      );
      final dailyTask = Task(
        id: 'recurring_daily',
        title: 'Evening workout',
        recurrenceRule: dailyRule,
        dueDate: null, // Even with null initial dueDate, recurrence rule provides next occurrence!
        status: 'active',
        createdAt: anchor.subtract(const Duration(days: 10)),
      );

      expect(AstraTaskFilter.isUpcoming(dailyTask, timeService: timeService), isTrue);

      // 2. Weekdays task (Mon-Fri at 10 AM, anchor is Tue 11 AM -> next is Wed 10 AM)
      const weekdayRule = RecurrenceRule(
        frequency: RecurrenceFrequency.weekdays,
        hour: 10,
        minute: 0,
      );
      final weekdayTask = Task(
        id: 'recurring_weekday',
        title: 'Team Standup',
        recurrenceRule: weekdayRule,
        status: 'pending',
        createdAt: anchor.subtract(const Duration(days: 5)),
      );

      expect(AstraTaskFilter.isUpcoming(weekdayTask, timeService: timeService), isTrue);

      // 3. Weekly task (Every Friday at 4 PM)
      const weeklyRule = RecurrenceRule(
        frequency: RecurrenceFrequency.weekly,
        byWeekdays: [DateTime.friday],
        hour: 16,
        minute: 0,
      );
      final weeklyTask = Task(
        id: 'recurring_weekly',
        title: 'Weekly Retrospective',
        recurrenceRule: weeklyRule,
        status: 'active',
        createdAt: anchor.subtract(const Duration(days: 14)),
      );

      expect(AstraTaskFilter.isUpcoming(weeklyTask, timeService: timeService), isTrue);

      // 4. Monthly task (25th of every month at 11 AM)
      const monthlyRule = RecurrenceRule(
        frequency: RecurrenceFrequency.monthly,
        startDate: null,
        hour: 11,
        minute: 0,
      );
      final monthlyTask = Task(
        id: 'recurring_monthly',
        title: 'Pay rent',
        recurrenceRule: monthlyRule,
        status: 'active',
        createdAt: DateTime(2026, 7, 25),
      );

      expect(AstraTaskFilter.isUpcoming(monthlyTask, timeService: timeService), isTrue);

      // 5. Expired recurring task with endDate in the past -> Not Upcoming
      final expiredRecurring = Task(
        id: 'recurring_expired',
        title: 'Old sprint',
        recurrenceRule: RecurrenceRule(
          frequency: RecurrenceFrequency.daily,
          endDate: DateTime(2026, 8, 10), // Ended in past
          hour: 9,
          minute: 0,
        ),
        status: 'active',
        createdAt: DateTime(2026, 8, 1),
      );

      expect(AstraTaskFilter.isUpcoming(expiredRecurring, timeService: timeService), isFalse);
    });

    test('E. Multi-day date-range task -> Upcoming when intersecting upcoming horizon', () {
      // 1. Ongoing multi-day event: 17 Aug -> 22 Aug (Anchor is 18 Aug)
      // This is the exact bug reported from the screenshot: "GB 2027 Batch Aptitude Training — 17 Aug → 22 Aug"
      final ongoingTraining = Task(
        id: 'range_training',
        title: 'GB 2027 Batch Aptitude Training',
        startAt: DateTime(2026, 8, 17, 9, 0),
        endAt: DateTime(2026, 8, 22, 17, 0),
        dueDate: null,
        status: 'active',
        createdAt: DateTime(2026, 8, 16),
      );

      expect(AstraTaskFilter.isUpcoming(ongoingTraining, timeService: timeService), isTrue);

      // 2. Future multi-day event: 24 Aug -> 28 Aug
      final futureConference = Task(
        id: 'range_conf',
        title: 'Flutter Forward Conference',
        startAt: DateTime(2026, 8, 24, 9, 0),
        endAt: DateTime(2026, 8, 28, 18, 0),
        dueDate: null,
        status: 'pending',
        createdAt: anchor,
      );

      expect(AstraTaskFilter.isUpcoming(futureConference, timeService: timeService), isTrue);

      // 3. Past multi-day event: 10 Aug -> 14 Aug (Completely in the past)
      final pastWorkshop = Task(
        id: 'range_past',
        title: 'Completed Workshop',
        startAt: DateTime(2026, 8, 10, 9, 0),
        endAt: DateTime(2026, 8, 14, 18, 0),
        dueDate: null,
        status: 'pending',
        createdAt: DateTime(2026, 8, 9),
      );

      expect(AstraTaskFilter.isUpcoming(pastWorkshop, timeService: timeService), isFalse);
      expect(AstraTaskFilter.isOverdue(pastWorkshop, timeService: timeService), isTrue);
    });

    test('F. Task exactly at horizon boundary', () {
      const horizon = Duration(days: 30);
      final horizonEndDate = anchor.add(horizon);

      final exactBoundaryTask = Task(
        id: 'boundary_exact',
        title: '30-day checkpoint',
        dueDate: horizonEndDate,
        status: 'pending',
        createdAt: anchor,
      );

      final beyondBoundaryTask = Task(
        id: 'boundary_beyond',
        title: 'Future far checkpoint',
        dueDate: horizonEndDate.add(const Duration(seconds: 1)),
        status: 'pending',
        createdAt: anchor,
      );

      expect(
        AstraTaskFilter.isUpcoming(exactBoundaryTask, timeService: timeService, horizon: horizon),
        isTrue,
        reason: 'Task right on horizon boundary should be included in Upcoming',
      );
      expect(
        AstraTaskFilter.isUpcoming(beyondBoundaryTask, timeService: timeService, horizon: horizon),
        isFalse,
        reason: 'Task beyond configured horizon should be excluded',
      );
    });

    test('G. Completed and cancelled tasks -> Not Upcoming', () {
      final completedTask = Task(
        id: 'completed_1',
        title: 'Finished homework',
        dueDate: DateTime(2026, 8, 20, 10, 0), // Future date, but status is completed
        status: 'completed',
        createdAt: anchor,
      );

      final cancelledTask = Task(
        id: 'cancelled_1',
        title: 'Cancelled meeting',
        dueDate: DateTime(2026, 8, 20, 14, 0),
        status: 'cancelled',
        createdAt: anchor,
      );

      expect(AstraTaskFilter.isUpcoming(completedTask, timeService: timeService), isFalse);
      expect(AstraTaskFilter.isUpcoming(cancelledTask, timeService: timeService), isFalse);
    });

    test('H. Current device time / clock changes are respected', () {
      final taskFriday = Task(
        id: 'clock_test_task',
        title: 'Friday Deployment',
        dueDate: DateTime(2026, 8, 21, 16, 0), // Friday
        status: 'active',
        createdAt: anchor,
      );

      // On Tuesday (anchor): it is upcoming
      expect(AstraTaskFilter.isUpcoming(taskFriday, timeService: timeService), isTrue);

      // Advance clock past Friday: Saturday 22 Aug
      fixedClock.set(DateTime(2026, 8, 22, 10, 0));
      expect(AstraTaskFilter.isUpcoming(taskFriday, timeService: timeService), isFalse);
      expect(AstraTaskFilter.isOverdue(taskFriday, timeService: timeService), isTrue);
    });

    test('I. My Day and Upcoming do not accidentally use the same predicate', () {
      // 1. Task due earlier today (e.g. 8 AM, current time 11 AM)
      final taskTodayMorning = Task(
        id: 'today_morning',
        title: 'Daily Journal',
        dueDate: DateTime(2026, 8, 18, 8, 0),
        status: 'active',
        createdAt: anchor.subtract(const Duration(days: 1)),
      );

      // In My Day? YES (due today)
      expect(AstraTaskFilter.isMyDay(taskTodayMorning, timeService: timeService), isTrue);
      // In Upcoming? NO (due in past relative to current time 11am)
      expect(AstraTaskFilter.isUpcoming(taskTodayMorning, timeService: timeService), isFalse);

      // 2. Overdue task from 3 days ago
      final oldOverdue = Task(
        id: 'old_overdue',
        title: 'Old task',
        dueDate: DateTime(2026, 8, 15, 10, 0),
        status: 'pending',
        createdAt: anchor.subtract(const Duration(days: 5)),
      );

      // In My Day? YES (surfaced to user)
      expect(AstraTaskFilter.isMyDay(oldOverdue, timeService: timeService), isTrue);
      // In Upcoming? NO
      expect(AstraTaskFilter.isUpcoming(oldOverdue, timeService: timeService), isFalse);

      // 3. Task due Tomorrow at 3 PM
      final taskTomorrow = Task(
        id: 'tomorrow_item',
        title: 'Tomorrow task',
        dueDate: DateTime(2026, 8, 19, 15, 0),
        status: 'pending',
        createdAt: anchor,
      );

      // In My Day? NO
      expect(AstraTaskFilter.isMyDay(taskTomorrow, timeService: timeService), isFalse);
      // In Upcoming? YES
      expect(AstraTaskFilter.isUpcoming(taskTomorrow, timeService: timeService), isTrue);
    });

    test('J. TaskBuckets accurately classifies tasks and matches active counts', () {
      final tasks = [
        // 1. Overdue task
        Task(id: '1', title: 'Overdue Task', dueDate: DateTime(2026, 8, 15), status: 'pending', createdAt: anchor),
        // 2. Today task
        Task(id: '2', title: 'Today Task', dueDate: DateTime(2026, 8, 18, 18, 0), status: 'pending', createdAt: anchor),
        // 3. Multi-day ongoing task (17-22 Aug) -> appears in today & upcoming
        Task(id: '3', title: 'Ongoing Training', startAt: DateTime(2026, 8, 17), endAt: DateTime(2026, 8, 22), status: 'active', createdAt: anchor),
        // 4. Tomorrow task
        Task(id: '4', title: 'Tomorrow Task', dueDate: DateTime(2026, 8, 19, 10, 0), status: 'pending', createdAt: anchor),
        // 5. This week task
        Task(id: '5', title: 'This Week Task', dueDate: DateTime(2026, 8, 21, 14, 0), status: 'pending', createdAt: anchor),
        // 6. Later task
        Task(id: '6', title: 'Later Task', dueDate: DateTime(2026, 9, 5), status: 'pending', createdAt: anchor),
        // 7. Recurring task (Weekly on Friday)
        Task(
          id: '7',
          title: 'Recurring Review',
          recurrenceRule: const RecurrenceRule(frequency: RecurrenceFrequency.weekly, byWeekdays: [DateTime.friday], hour: 15, minute: 0),
          status: 'active',
          createdAt: anchor,
        ),
        // 8. No date task
        Task(id: '8', title: 'No Date Task', dueDate: null, status: 'pending', createdAt: anchor),
        // 9. Completed task
        Task(id: '9', title: 'Completed Task', dueDate: DateTime(2026, 8, 19), status: 'completed', createdAt: anchor),
      ];

      final buckets = AstraTaskFilter.categorize(tasks, timeService: timeService);

      expect(buckets.overdue.length, 1);
      expect(buckets.todayTasks.length, 2); // Task 2 + ongoing Task 3
      expect(buckets.tomorrowTasks.length, 1); // Task 4
      expect(buckets.thisWeekTasks.length, 3); // Task 3 (ongoing through 22 Aug) + Task 5 (21 Aug) + Task 7 (Friday recurrence)
      expect(buckets.laterTasks.length, 1); // Task 6
      expect(buckets.noDateTasks.length, 1); // Task 8
      expect(buckets.recurringTasks.length, 1); // Task 7
      expect(buckets.completedTasks.length, 1); // Task 9

      // Active count should be exactly 8 (Tasks 1-8, excluding completed Task 9)
      expect(buckets.allActiveCount, 8);
      // Upcoming count should be 6 (Tasks 2 [today 6pm > 11am], 3, 4, 5, 6, 7)
      expect(buckets.upcomingCount, 6);
    });
  });
}
