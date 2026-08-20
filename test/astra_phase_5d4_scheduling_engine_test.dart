import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astra/core/database/database.dart';
import 'package:astra/core/scheduling/astra_schedule_resolver.dart';
import 'package:astra/models/task.dart';
import 'package:astra/models/task_intent.dart';
import 'package:astra/services/assistant/astra_recurrence_engine.dart';
import 'package:astra/services/reminder_service.dart';
import 'package:astra/services/task/astra_task_filter.dart';
import 'package:astra/services/task/astra_schedule_item.dart';
import 'package:astra/providers/task_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  late AppDatabase db;
  late ReminderService reminderService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    reminderService = ReminderService(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('ASTRA Phase 5D.4 — Canonical Scheduling Engine Correctness (A–Z)', () {
    final referenceNow = DateTime(2026, 8, 20, 15, 0); // 3:00 PM on Thursday Aug 20, 2026

    // ── A. Unscheduled Task ──────────────────────────────────────────────────
    test('A: Unscheduled task (no date, no time, no recurrence)', () {
      final task = Task(
        id: 'task-a',
        title: 'Buy groceries',
        createdAt: referenceNow,
      );

      final resolved = AstraScheduleResolver.resolve(task: task, now: referenceNow);

      expect(resolved.effectiveDueAt, isNull);
      expect(resolved.nextOccurrence, isNull);
      expect(resolved.isRecurring, isFalse);
      expect(resolved.isPast, isFalse);
      expect(resolved.isUpcoming, isFalse);
      expect(resolved.isOverdue, isFalse);
      expect(resolved.isToday, isFalse);
      expect(resolved.isTomorrow, isFalse);
      expect(resolved.shouldScheduleReminder, isFalse);
      expect(resolved.reminderRejectionReason, 'unscheduled');
    });

    // ── B. Floating Time without Date ────────────────────────────────────────
    test('B: Floating time without date (e.g. 20:00)', () {
      final task = Task(
        id: 'task-b',
        title: 'Read paper',
        dueTime: '20:00',
        createdAt: referenceNow,
      );

      final resolved = AstraScheduleResolver.resolve(task: task, now: referenceNow);

      // At 3 PM, 8 PM today is upcoming
      expect(resolved.effectiveDueAt, DateTime(2026, 8, 20, 20, 0));
      expect(resolved.nextOccurrence, DateTime(2026, 8, 20, 20, 0));
      expect(resolved.isToday, isTrue);
      expect(resolved.isUpcoming, isTrue);
      expect(resolved.isOverdue, isFalse);
      expect(resolved.shouldScheduleReminder, isTrue);
      expect(resolved.reminderScheduleInstant, DateTime(2026, 8, 20, 20, 0));
    });

    // ── C. Daily Recurrence with No Seed Date ────────────────────────────────
    test('C: Daily recurrence with no seed date (e.g. 20:00 daily)', () {
      final task = Task(
        id: 'task-c',
        title: 'Gym daily',
        recurrenceRule: const RecurrenceRule(
          frequency: RecurrenceFrequency.daily,
          hour: 20,
          minute: 0,
        ),
        createdAt: referenceNow,
      );

      // At 3 PM: next occurrence is today 8 PM
      final resolvedAt3PM = AstraScheduleResolver.resolve(task: task, now: referenceNow);
      expect(resolvedAt3PM.effectiveDueAt, DateTime(2026, 8, 20, 20, 0));
      expect(resolvedAt3PM.nextOccurrence, DateTime(2026, 8, 20, 20, 0));
      expect(resolvedAt3PM.isRecurring, isTrue);
      expect(resolvedAt3PM.isToday, isTrue);
      expect(resolvedAt3PM.isUpcoming, isTrue);
      expect(resolvedAt3PM.isOverdue, isFalse);
      expect(resolvedAt3PM.shouldScheduleReminder, isTrue);

      // At 9 PM: next occurrence is tomorrow 8 PM
      final now9PM = DateTime(2026, 8, 20, 21, 0);
      final resolvedAt9PM = AstraScheduleResolver.resolve(task: task, now: now9PM);
      expect(resolvedAt9PM.nextOccurrence, DateTime(2026, 8, 21, 20, 0));
      expect(resolvedAt9PM.isTomorrow, isTrue);
      expect(resolvedAt9PM.isUpcoming, isTrue);
      expect(resolvedAt9PM.isOverdue, isFalse);
    });

    // ── D. Weekday Recurrence with No Seed Date ──────────────────────────────
    test('D: Weekday recurrence with no seed date', () {
      // Friday 9 PM -> next weekday is Monday
      final fridayNight = DateTime(2026, 8, 21, 21, 0);
      final task = Task(
        id: 'task-d',
        title: 'Standup',
        recurrenceRule: const RecurrenceRule(
          frequency: RecurrenceFrequency.weekdays,
          hour: 10,
          minute: 0,
        ),
        createdAt: fridayNight,
      );

      final resolved = AstraScheduleResolver.resolve(task: task, now: fridayNight);
      expect(resolved.nextOccurrence, DateTime(2026, 8, 24, 10, 0)); // Monday Aug 24
      expect(resolved.isRecurring, isTrue);
      expect(resolved.isUpcoming, isTrue);
      expect(resolved.isOverdue, isFalse);
    });

    // ── E. Weekly Recurrence with No Seed Date ───────────────────────────────
    test('E: Weekly recurrence with no seed date', () {
      final task = Task(
        id: 'task-e',
        title: 'Weekly Review',
        recurrenceRule: const RecurrenceRule(
          frequency: RecurrenceFrequency.weekly,
          byWeekdays: [DateTime.sunday], // Sunday
          hour: 18,
          minute: 0,
        ),
        createdAt: referenceNow, // Thursday
      );

      final resolved = AstraScheduleResolver.resolve(task: task, now: referenceNow);
      expect(resolved.nextOccurrence, DateTime(2026, 8, 23, 18, 0)); // Sunday Aug 23
      expect(resolved.isUpcoming, isTrue);
      expect(resolved.isOverdue, isFalse);
    });

    // ── F. Today Future Time ─────────────────────────────────────────────────
    test('F: Today future time (e.g. today 8 PM at 3 PM)', () {
      final task = Task(
        id: 'task-f',
        title: 'Dinner',
        dueDate: DateTime(2026, 8, 20),
        dueTime: '20:00',
        createdAt: referenceNow,
      );

      final resolved = AstraScheduleResolver.resolve(task: task, now: referenceNow);
      expect(resolved.effectiveDueAt, DateTime(2026, 8, 20, 20, 0));
      expect(resolved.isPast, isFalse);
      expect(resolved.isUpcoming, isTrue);
      expect(resolved.isOverdue, isFalse);
      expect(resolved.isToday, isTrue);
      expect(resolved.shouldScheduleReminder, isTrue);
    });

    // ── G. Today Past Time ───────────────────────────────────────────────────
    test('G: Today past time (e.g. today 10 AM at 3 PM)', () {
      final task = Task(
        id: 'task-g',
        title: 'Breakfast meeting',
        dueDate: DateTime(2026, 8, 20),
        dueTime: '10:00',
        createdAt: referenceNow,
      );

      final resolved = AstraScheduleResolver.resolve(task: task, now: referenceNow);
      expect(resolved.effectiveDueAt, DateTime(2026, 8, 20, 10, 0));
      expect(resolved.isPast, isTrue);
      expect(resolved.isUpcoming, isFalse);
      expect(resolved.isToday, isTrue);
      expect(resolved.shouldScheduleReminder, isFalse);
      expect(resolved.reminderRejectionReason, 'past');
    });

    // ── H. Tomorrow Future Time ──────────────────────────────────────────────
    test('H: Tomorrow future time', () {
      final task = Task(
        id: 'task-h',
        title: 'Call team',
        dueDate: DateTime(2026, 8, 21),
        dueTime: '11:00',
        createdAt: referenceNow,
      );

      final resolved = AstraScheduleResolver.resolve(task: task, now: referenceNow);
      expect(resolved.isTomorrow, isTrue);
      expect(resolved.isUpcoming, isTrue);
      expect(resolved.isOverdue, isFalse);
      expect(resolved.shouldScheduleReminder, isTrue);
      expect(resolved.reminderScheduleInstant, DateTime(2026, 8, 21, 11, 0));
    });

    // ── I. Past Date without Recurrence ──────────────────────────────────────
    test('I: Past date without recurrence (e.g. yesterday 10 AM)', () {
      final task = Task(
        id: 'task-i',
        title: 'Exam yesterday',
        dueDate: DateTime(2026, 8, 19),
        dueTime: '10:00',
        createdAt: referenceNow,
      );

      final resolved = AstraScheduleResolver.resolve(task: task, now: referenceNow);
      expect(resolved.isPast, isTrue);
      expect(resolved.isUpcoming, isFalse);
      expect(resolved.isOverdue, isTrue);
      expect(resolved.shouldScheduleReminder, isFalse);
      expect(resolved.reminderRejectionReason, 'past');
    });

    // ── J. Past Date with Daily Recurrence ────────────────────────────────────
    test('J: Past date with daily recurrence (seed was yesterday, current is 3 PM)', () {
      final task = Task(
        id: 'task-j',
        title: 'Gym daily',
        dueDate: DateTime(2026, 8, 19, 20, 0), // yesterday
        recurrenceRule: const RecurrenceRule(
          frequency: RecurrenceFrequency.daily,
          hour: 20,
          minute: 0,
        ),
        createdAt: DateTime(2026, 8, 19),
      );

      final resolved = AstraScheduleResolver.resolve(task: task, now: referenceNow);

      // Invariant: Recurring task with future occurrences is NEVER overdue!
      expect(resolved.isOverdue, isFalse);
      expect(resolved.nextOccurrence, DateTime(2026, 8, 20, 20, 0)); // Today 8 PM
      expect(resolved.isToday, isTrue);
      expect(resolved.isUpcoming, isTrue);
      expect(resolved.shouldScheduleReminder, isTrue);
    });

    // ── K. Today with Daily Recurrence (after today occurrence) ───────────────
    test('K: Today with daily recurrence after today occurrence', () {
      final now9PM = DateTime(2026, 8, 20, 21, 0); // 9 PM
      final task = Task(
        id: 'task-k',
        title: 'Gym daily',
        dueDate: DateTime(2026, 8, 20, 20, 0),
        recurrenceRule: const RecurrenceRule(
          frequency: RecurrenceFrequency.daily,
          hour: 20,
          minute: 0,
        ),
        createdAt: referenceNow,
      );

      final resolved = AstraScheduleResolver.resolve(task: task, now: now9PM);
      expect(resolved.isOverdue, isFalse);
      expect(resolved.nextOccurrence, DateTime(2026, 8, 21, 20, 0)); // Tomorrow 8 PM
      expect(resolved.isTomorrow, isTrue);
      expect(resolved.isUpcoming, isTrue);
    });

    // ── L. Tomorrow with Recurrence ───────────────────────────────────────────
    test('L: Tomorrow with recurrence', () {
      final task = Task(
        id: 'task-l',
        title: 'Weekly clean',
        dueDate: DateTime(2026, 8, 21),
        recurrenceRule: const RecurrenceRule(
          frequency: RecurrenceFrequency.weekly,
          byWeekdays: [DateTime.friday],
          hour: 16,
          minute: 0,
        ),
        createdAt: referenceNow,
      );

      final resolved = AstraScheduleResolver.resolve(task: task, now: referenceNow);
      expect(resolved.nextOccurrence, DateTime(2026, 8, 21, 16, 0));
      expect(resolved.isTomorrow, isTrue);
      expect(resolved.isUpcoming, isTrue);
    });

    // ── M. Bounded Recurrence ─────────────────────────────────────────────────
    test('M: Bounded recurrence (startDate to endDate)', () {
      final task = Task(
        id: 'task-m',
        title: 'Sprint daily',
        recurrenceRule: RecurrenceRule(
          frequency: RecurrenceFrequency.daily,
          hour: 10,
          minute: 0,
          startDate: DateTime(2026, 8, 21),
          endDate: DateTime(2026, 8, 25, 23, 59),
        ),
        createdAt: referenceNow,
      );

      final resolved = AstraScheduleResolver.resolve(task: task, now: referenceNow);
      expect(resolved.nextOccurrence, DateTime(2026, 8, 21, 10, 0));
      expect(resolved.isUpcoming, isTrue);

      // Check after end date
      final afterEnd = DateTime(2026, 8, 26, 12, 0);
      final resolvedAfterEnd = AstraScheduleResolver.resolve(task: task, now: afterEnd);
      expect(resolvedAfterEnd.isRecurring, isFalse);
      expect(resolvedAfterEnd.isPast, isTrue);
      expect(resolvedAfterEnd.shouldScheduleReminder, isFalse);
    });

    // ── N. Reminder at Time ──────────────────────────────────────────────────
    test('N: Reminder at time', () {
      final task = Task(
        id: 'task-n',
        title: 'Meeting',
        dueDate: DateTime(2026, 8, 20),
        dueTime: '17:00',
        createdAt: referenceNow,
      );

      final resolved = AstraScheduleResolver.resolve(
        task: task,
        now: referenceNow,
        reminderOffsetMinutes: 0,
        reminderEnabled: true,
      );

      expect(resolved.shouldScheduleReminder, isTrue);
      expect(resolved.reminderScheduleInstant, DateTime(2026, 8, 20, 17, 0));
    });

    // ── O. Reminder with Offset ──────────────────────────────────────────────
    test('O: Reminder with offset (15m before)', () {
      final task = Task(
        id: 'task-o',
        title: 'Meeting',
        dueDate: DateTime(2026, 8, 20),
        dueTime: '17:00',
        createdAt: referenceNow,
      );

      final resolved = AstraScheduleResolver.resolve(
        task: task,
        now: referenceNow,
        reminderOffsetMinutes: 15,
        reminderEnabled: true,
      );

      expect(resolved.shouldScheduleReminder, isTrue);
      expect(resolved.reminderScheduleInstant, DateTime(2026, 8, 20, 16, 45));
    });

    // ── P. Past Reminder Rejection ───────────────────────────────────────────
    test('P: Past reminder rejection (never schedules alarm for past instant)', () {
      final task = Task(
        id: 'task-p',
        title: 'Past meeting',
        dueDate: DateTime(2026, 8, 20),
        dueTime: '14:00', // 1 hour ago
        createdAt: referenceNow,
      );

      final resolved = AstraScheduleResolver.resolve(
        task: task,
        now: referenceNow,
        reminderEnabled: true,
      );

      expect(resolved.shouldScheduleReminder, isFalse);
      expect(resolved.reminderRejectionReason, 'past');
    });

    // ── Q. DONE Recurring Task ───────────────────────────────────────────────
    test('Q: DONE recurring task advances to next occurrence on single DB row', () async {
      final initialTask = Task(
        id: 'task-q',
        title: 'Daily meditation',
        dueDate: DateTime(2026, 8, 20, 8, 0),
        recurrenceRule: const RecurrenceRule(
          frequency: RecurrenceFrequency.daily,
          hour: 8,
          minute: 0,
        ),
        createdAt: referenceNow,
      );

      final notifier = TaskNotifier(db, reminderService);
      await notifier.addTask(initialTask);

      // Complete the task
      await notifier.toggleComplete('task-q');

      final allTasks = await db.select(db.tasks).get();
      expect(allTasks.length, 1, reason: 'Must maintain single canonical DB row (no duplicate rows)');

      final updatedTask = allTasks.first;
      expect(updatedTask.status, 'active');
      expect(updatedTask.completedAt, isNull);
      expect(updatedTask.dueAt, isNotNull);
      expect(updatedTask.dueAt!.isAfter(referenceNow), isTrue);
    });

    // ── R. SNOOZE Recurring Task ─────────────────────────────────────────────
    test('R: SNOOZE recurring task shifts current occurrence only and keeps base rule', () async {
      final task = Task(
        id: 'task-r',
        title: 'Drink water',
        dueDate: DateTime(2026, 8, 20, 20, 0),
        recurrenceRule: const RecurrenceRule(
          frequency: RecurrenceFrequency.daily,
          hour: 20,
          minute: 0,
        ),
        createdAt: referenceNow,
      );

      final notifier = TaskNotifier(db, reminderService);
      await notifier.addTask(task);

      await reminderService.scheduleReminder(
        taskId: 'task-r',
        taskTitle: 'Drink water',
        scheduledAt: DateTime(2026, 8, 20, 20, 0),
      );

      final reminders = await db.getActiveReminders();
      expect(reminders.isNotEmpty, isTrue);

      // Snooze 10m
      await reminderService.snoozeReminder(reminders.first.id, duration: const Duration(minutes: 10));

      final updatedTask = await (db.select(db.tasks)..where((t) => t.id.equals('task-r'))).getSingle();
      expect(updatedTask.recurrenceRuleJson, isNotNull);

      // Base recurrence rule is preserved
      final rule = RecurrenceRule.fromJson(updatedTask.recurrenceRuleJson!);
      expect(rule.hour, 20);
      expect(rule.minute, 0);
      expect(rule.frequency, RecurrenceFrequency.daily);
    });

    // ── S. Task Date Changed from Yesterday to Today ─────────────────────────
    test('S: Task date changed from yesterday to today recomputes schedule', () {
      final pastIntent = const TaskIntent(
        title: 'Followup',
        dueDate: null,
        dueTime: '10:00',
      );

      // When date is changed to today (after 10 AM)
      final resolved = AstraScheduleResolver.resolve(
        intent: pastIntent,
        dueDate: DateTime(2026, 8, 20), // today
        now: referenceNow, // 3 PM
      );

      expect(resolved.isPast, isTrue);
      expect(resolved.isToday, isTrue);
      expect(resolved.shouldScheduleReminder, isFalse);
    });

    // ── T. Time Changed ──────────────────────────────────────────────────────
    test('T: Time changed recomputes schedule and reminder', () {
      final task = Task(
        id: 'task-t',
        title: 'Meeting',
        dueDate: DateTime(2026, 8, 20),
        dueTime: '10:00', // past
        createdAt: referenceNow,
      );

      // Change time to 18:00 (future)
      final resolved = AstraScheduleResolver.resolve(
        task: task,
        dueTime: '18:00',
        now: referenceNow,
      );

      expect(resolved.isPast, isFalse);
      expect(resolved.isUpcoming, isTrue);
      expect(resolved.shouldScheduleReminder, isTrue);
      expect(resolved.reminderScheduleInstant, DateTime(2026, 8, 20, 18, 0));
    });

    // ── U. Recurrence Changed ────────────────────────────────────────────────
    test('U: Recurrence changed updates next occurrence', () {
      final dailyRule = const RecurrenceRule(frequency: RecurrenceFrequency.daily, hour: 10, minute: 0);
      final weeklyRule = const RecurrenceRule(frequency: RecurrenceFrequency.weekly, byWeekdays: [DateTime.monday], hour: 10, minute: 0);

      final resolvedDaily = AstraScheduleResolver.resolve(
        dueDate: DateTime(2026, 8, 20),
        recurrenceRule: dailyRule,
        now: referenceNow, // Thursday 3 PM
      );
      expect(resolvedDaily.nextOccurrence, DateTime(2026, 8, 21, 10, 0)); // Tomorrow

      final resolvedWeekly = AstraScheduleResolver.resolve(
        dueDate: DateTime(2026, 8, 20),
        recurrenceRule: weeklyRule,
        now: referenceNow,
      );
      expect(resolvedWeekly.nextOccurrence, DateTime(2026, 8, 24, 10, 0)); // Next Monday
    });

    // ── V. Reminder Offset Changed ───────────────────────────────────────────
    test('V: Reminder offset changed updates reminderScheduleInstant', () {
      final task = Task(
        id: 'task-v',
        title: 'Doctor',
        dueDate: DateTime(2026, 8, 20),
        dueTime: '18:00',
        createdAt: referenceNow,
      );

      final r0 = AstraScheduleResolver.resolve(task: task, now: referenceNow, reminderOffsetMinutes: 0);
      expect(r0.reminderScheduleInstant, DateTime(2026, 8, 20, 18, 0));

      final r30 = AstraScheduleResolver.resolve(task: task, now: referenceNow, reminderOffsetMinutes: 30);
      expect(r30.reminderScheduleInstant, DateTime(2026, 8, 20, 17, 30));
    });

    // ── W. Restore Recurring Task ────────────────────────────────────────────
    test('W: Restored recurring task reconciles to future occurrence without spam', () {
      final oldRecurringTask = Task(
        id: 'task-w',
        title: 'Take vitamins',
        dueDate: DateTime(2025, 1, 1, 9, 0), // 1.5 years ago
        recurrenceRule: const RecurrenceRule(
          frequency: RecurrenceFrequency.daily,
          hour: 9,
          minute: 0,
        ),
        createdAt: DateTime(2025, 1, 1),
      );

      final resolved = AstraScheduleResolver.resolve(task: oldRecurringTask, now: referenceNow);
      expect(resolved.isOverdue, isFalse);
      expect(resolved.nextOccurrence, DateTime(2026, 8, 21, 9, 0)); // Tomorrow morning
      expect(resolved.isUpcoming, isTrue);
    });

    // ── X. Schedule View Dynamic Expansion ───────────────────────────────────
    test('X: Schedule view expands recurring items dynamically in window', () {
      final recurringTask = Task(
        id: 'task-x',
        title: 'Daily Standup',
        recurrenceRule: const RecurrenceRule(
          frequency: RecurrenceFrequency.daily,
          hour: 10,
          minute: 0,
        ),
        createdAt: referenceNow,
      );

      final windowStart = DateTime(2026, 8, 20, 0, 0);
      final windowEnd = DateTime(2026, 8, 25, 0, 0);

      final items = AstraScheduleItem.buildSchedule(
        tasks: [recurringTask],
        windowStart: windowStart,
        windowEnd: windowEnd,
        now: referenceNow,
      );

      expect(items.length, 5);
      for (final item in items) {
        expect(item.isOverdue, isFalse);
      }
    });

    // ── Y. Task Bucketing ────────────────────────────────────────────────────
    test('Y: Task bucketing correctly distributes tasks using resolver', () {
      final tasks = [
        Task(id: '1', title: 'Overdue', dueDate: DateTime(2026, 8, 10), createdAt: referenceNow),
        Task(id: '2', title: 'Today', dueDate: DateTime(2026, 8, 20, 18, 0), createdAt: referenceNow),
        Task(id: '3', title: 'Tomorrow', dueDate: DateTime(2026, 8, 21, 10, 0), createdAt: referenceNow),
        Task(id: '4', title: 'Recurring Daily', recurrenceRule: const RecurrenceRule(frequency: RecurrenceFrequency.daily, hour: 20, minute: 0), createdAt: referenceNow),
        Task(id: '5', title: 'No Date', createdAt: referenceNow),
      ];

      final buckets = AstraTaskFilter.categorize(tasks, referenceTime: referenceNow);

      expect(buckets.overdue.map((t) => t.id).toList(), ['1']);
      expect(buckets.todayTasks.map((t) => t.id).toSet(), containsAll(['2', '4']));
      expect(buckets.tomorrowTasks.map((t) => t.id).toSet(), containsAll(['3']));
      expect(buckets.noDateTasks.map((t) => t.id).toList(), ['5']);
    });

    // ── Z. No Duplicate Task Rows ────────────────────────────────────────────
    test('Z: No duplicate task rows created across multiple completion cycles', () async {
      final notifier = TaskNotifier(db, reminderService);
      final task = Task(
        id: 'task-z',
        title: 'Daily Streak',
        recurrenceRule: const RecurrenceRule(
          frequency: RecurrenceFrequency.daily,
          hour: 9,
          minute: 0,
        ),
        createdAt: referenceNow,
      );
      await notifier.addTask(task);

      // Cycle 1
      await notifier.toggleComplete('task-z');
      // Cycle 2
      await notifier.toggleComplete('task-z');
      // Cycle 3
      await notifier.toggleComplete('task-z');

      final rows = await db.select(db.tasks).get();
      expect(rows.length, 1, reason: 'Single canonical DB task row preserved across cycles');
      expect(rows.first.id, 'task-z');
    });
  });

  // ── Permutation Matrix Testing ──────────────────────────────────────────────
  group('ASTRA Phase 5D.4 — Permutation Matrix Verification', () {
    final now = DateTime(2026, 8, 20, 15, 0);

    final dateOptions = <String, DateTime?>{
      'none': null,
      'today': DateTime(2026, 8, 20),
      'tomorrow': DateTime(2026, 8, 21),
      'future': DateTime(2026, 8, 28),
      'past': DateTime(2026, 8, 10),
    };

    final timeOptions = <String, String?>{
      'none': null,
      'future_time': '20:00',
      'past_time': '09:00',
    };

    final recurrenceOptions = <String, RecurrenceRule?>{
      'none': null,
      'daily': const RecurrenceRule(frequency: RecurrenceFrequency.daily, hour: 20, minute: 0),
      'weekdays': const RecurrenceRule(frequency: RecurrenceFrequency.weekdays, hour: 20, minute: 0),
      'weekly': const RecurrenceRule(frequency: RecurrenceFrequency.weekly, byWeekdays: [DateTime.monday], hour: 20, minute: 0),
    };

    final reminderOptions = <String, int>{
      'none': -1, // disabled
      'at_time': 0,
      '15m_before': 15,
    };

    for (final dateEntry in dateOptions.entries) {
      for (final timeEntry in timeOptions.entries) {
        for (final recEntry in recurrenceOptions.entries) {
          for (final remEntry in reminderOptions.entries) {
            test('Matrix: date=${dateEntry.key}, time=${timeEntry.key}, rec=${recEntry.key}, rem=${remEntry.key}', () {
              final reminderEnabled = remEntry.value >= 0;
              final reminderOffset = reminderEnabled ? remEntry.value : 0;

              final resolved = AstraScheduleResolver.resolve(
                dueDate: dateEntry.value,
                dueTime: timeEntry.value,
                recurrenceRule: recEntry.value,
                now: now,
                reminderEnabled: reminderEnabled,
                reminderOffsetMinutes: reminderOffset,
              );

              // Invariant 1: If reminder is scheduled, it MUST be strictly in the future
              if (resolved.shouldScheduleReminder) {
                expect(resolved.reminderScheduleInstant, isNotNull);
                expect(resolved.reminderScheduleInstant!.isAfter(now), isTrue,
                    reason: 'Alarms must NEVER be scheduled in the past');
              }

              // Invariant 2: Active recurring tasks are NEVER overdue
              if (resolved.isRecurring && resolved.nextOccurrence != null) {
                expect(resolved.isOverdue, isFalse,
                    reason: 'Recurring tasks with future occurrences cannot be overdue');
              }

              // Invariant 3: Past one-shot tasks never schedule alarms
              if (resolved.isPast && !resolved.isRecurring) {
                expect(resolved.shouldScheduleReminder, isFalse,
                    reason: 'Past one-shot tasks must reject reminder scheduling');
              }
            });
          }
        }
      }
    }
  });
}
