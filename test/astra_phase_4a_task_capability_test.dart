import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astra/core/database/database.dart';
import 'package:astra/models/task.dart';
import 'package:astra/models/task_intent.dart';
import 'package:astra/providers/astra_command_executor_provider.dart';
import 'package:astra/providers/ritual_provider.dart';
import 'package:astra/services/assistant/astra_recurrence_engine.dart';
import 'package:astra/services/task/astra_task_filter.dart';
import 'package:astra/services/task/astra_schedule_item.dart';
import 'package:astra/services/haptics/astra_haptics.dart';
import 'helpers/test_database_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = TestDatabaseHelper.createMemoryDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
      ],
    );
  }

  group('ASTRA Phase 4A — Task System Capability & Product Upgrade Tests (A–M)', () {
    // ─── A. Task Detail Model ────────────────────────────────────────────────
    test('A. Task detail model properties and helper getters', () {
      final task = Task(
        id: 't-1',
        title: 'System Design Interview Prep',
        description: 'Read designing data-intensive applications chapter 5',
        category: 'Work',
        organization: 'Meta',
        priority: 'high',
        status: 'pending',
        subtasks: [
          SubTask(id: 's-1', name: 'Replication models', isCompleted: true),
          SubTask(id: 's-2', name: 'Leaderless consensus', isCompleted: false),
        ],
        createdAt: DateTime.now(),
      );

      expect(task.title, 'System Design Interview Prep');
      expect(task.description, contains('chapter 5'));
      expect(task.category, 'Work');
      expect(task.organization, 'Meta');
      expect(task.isImportant, isTrue);
      expect(task.isNoDate, isTrue);
      expect(task.subtasks.length, 2);
      expect(task.subtasks.first.isCompleted, isTrue);
    });

    // ─── B. Important Task ───────────────────────────────────────────────────
    test('B. Important task identification and bucketing', () {
      final highTask = Task(
        id: 't-high',
        title: 'Final Exam Submission',
        priority: 'high',
        createdAt: DateTime.now(),
      );
      final criticalTask = Task(
        id: 't-crit',
        title: 'Server Crash Emergency',
        priority: 'critical',
        createdAt: DateTime.now(),
      );
      final normalTask = Task(
        id: 't-med',
        title: 'Water plants',
        priority: 'medium',
        createdAt: DateTime.now(),
      );

      expect(AstraTaskFilter.isImportant(highTask), isTrue);
      expect(AstraTaskFilter.isImportant(criticalTask), isTrue);
      expect(AstraTaskFilter.isImportant(normalTask), isFalse);

      final buckets = AstraTaskFilter.categorize([highTask, criticalTask, normalTask]);
      expect(buckets.importantCount, 2);
    });

    // ─── C. Smart Lists ──────────────────────────────────────────────────────
    test('C. Centralized Smart Lists filtering', () {
      final now = DateTime(2026, 8, 18, 10, 0);

      final todayTask = Task(
        id: 't-today',
        title: 'Team Standup',
        dueDate: DateTime(2026, 8, 18, 11, 0),
        createdAt: now,
      );
      final upcomingTask = Task(
        id: 't-up',
        title: 'Project Demo',
        dueDate: DateTime(2026, 8, 25, 14, 0),
        createdAt: now,
      );
      final noDateTask = Task(
        id: 't-nodate',
        title: 'Backlog Item',
        createdAt: now,
      );
      final completedTask = Task(
        id: 't-done',
        title: 'Finished Homework',
        status: 'completed',
        createdAt: now,
      );

      final allTasks = [todayTask, upcomingTask, noDateTask, completedTask];
      final buckets = AstraTaskFilter.categorize(allTasks, referenceTime: now);

      expect(buckets.todayTasks.length, 1);
      expect(buckets.todayTasks.first.id, 't-today');
      expect(buckets.upcomingCount, 2); // todayTask + upcomingTask
      expect(buckets.noDateTasks.length, 1);
      expect(buckets.noDateTasks.first.id, 't-nodate');
      expect(buckets.completedTasks.length, 1);
      expect(buckets.allActiveCount, 3);
    });

    // ─── D. My Day Semantics ─────────────────────────────────────────────────
    test('D. My Day surfaces Overdue + Today items without destructive reset', () {
      final now = DateTime(2026, 8, 18, 12, 0);

      final overdueTask = Task(
        id: 't-overdue',
        title: 'Unpaid Utility Bill',
        dueDate: DateTime(2026, 8, 15, 18, 0),
        createdAt: now.subtract(const Duration(days: 4)),
      );
      final todayTask = Task(
        id: 't-today',
        title: 'Gym Workout',
        dueDate: DateTime(2026, 8, 18, 18, 0),
        createdAt: now,
      );
      final futureTask = Task(
        id: 't-future',
        title: 'Weekend Trip',
        dueDate: DateTime(2026, 8, 22, 10, 0),
        createdAt: now,
      );

      expect(AstraTaskFilter.isMyDay(overdueTask, referenceTime: now), isTrue);
      expect(AstraTaskFilter.isMyDay(todayTask, referenceTime: now), isTrue);
      expect(AstraTaskFilter.isMyDay(futureTask, referenceTime: now), isFalse);

      // Verify task status is unchanged (non-destructive)
      expect(overdueTask.status, 'pending');
      expect(todayTask.status, 'pending');
    });

    // ─── E. Recurrence End Date ──────────────────────────────────────────────
    test('E. Recurrence respects End Date boundary', () {
      const engine = AstraRecurrenceEngine();
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
        startDate: DateTime(2026, 8, 1),
        endDate: DateTime(2026, 8, 10, 23, 59),
        hour: 9,
        minute: 0,
      );

      // Occurrence within window
      final occ1 = engine.nextOccurrence(rule, DateTime(2026, 8, 5, 10, 0));
      expect(occ1, isNotNull);
      expect(occ1!.day, 6);

      // Occurrence after end date
      final occAfter = engine.nextOccurrence(rule, DateTime(2026, 8, 11, 0, 0));
      expect(occAfter, isNull);
    });

    // ─── F. Recurrence Occurrence Limit ──────────────────────────────────────
    test('F. Recurrence stops after occurrenceLimit is reached', () {
      const engine = AstraRecurrenceEngine();

      // Rule limited to 3 occurrences, with 2 completed
      final ruleActive = RecurrenceRule(
        frequency: RecurrenceFrequency.weekly,
        occurrenceLimit: 3,
        occurrencesCount: 2,
        hour: 10,
        minute: 0,
      );
      expect(ruleActive.isEnded, isFalse);
      expect(engine.nextOccurrence(ruleActive, DateTime(2026, 8, 18)), isNotNull);

      // Rule with 3/3 completed
      final ruleEnded = RecurrenceRule(
        frequency: RecurrenceFrequency.weekly,
        occurrenceLimit: 3,
        occurrencesCount: 3,
        hour: 10,
        minute: 0,
      );
      expect(ruleEnded.isEnded, isTrue);
      expect(engine.nextOccurrence(ruleEnded, DateTime(2026, 8, 18)), isNull);
    });

    // ─── G. Start vs Deadline Distinction ────────────────────────────────────
    test('G. Clear distinction between Start Date, Deadline, and Multi-Day Duration', () {
      final now = DateTime.now();

      // Deadline only (e.g. assignment submission)
      final deadlineTask = Task(
        id: 't-dl',
        title: 'Submit Paper',
        dueDate: now.add(const Duration(days: 2)),
        createdAt: now,
      );
      expect(deadlineTask.isDeadline, isTrue);
      expect(deadlineTask.isDuration, isFalse);

      // Duration event (e.g. 3-day hackathon)
      final durationTask = Task(
        id: 't-dur',
        title: 'AI Hackathon',
        startAt: DateTime(2026, 9, 1, 9, 0),
        endAt: DateTime(2026, 9, 3, 18, 0),
        createdAt: now,
      );
      expect(durationTask.isDuration, isTrue);
      expect(durationTask.isDeadline, isFalse);
      expect(durationTask.durationFormatted, contains('Days'));
    });

    // ─── H. Reminder Linkage ─────────────────────────────────────────────────
    test('H. Task creation correctly links single active reminder in Drift', () async {
      final container = createContainer();
      final executor = container.read(astraCommandExecutorProvider);

      final intent = TaskIntent(
        title: 'Doctor Appointment',
        dueDate: DateTime.now().add(const Duration(days: 1)),
        taskType: 'reminder',
        priority: 'high',
      );

      final result = await executor.executeTaskIntent(
        ref: container,
        intent: intent,
      );

      expect(result.success, isTrue);

      final tasks = await db.select(db.tasks).get();
      final reminders = await db.select(db.reminders).get();

      expect(tasks.length, 1);
      expect(reminders.length, 1);
      expect(reminders.first.taskId, tasks.first.id);

      container.dispose();
    });

    // ─── I. Task + Calendar Schedule Representation ──────────────────────────
    test('I. AstraScheduleItem unifies tasks and occurrences chronologically', () {
      final windowStart = DateTime(2026, 8, 18, 0, 0);
      final windowEnd = DateTime(2026, 8, 18, 23, 59);

      final task1 = Task(
        id: 't-1',
        title: 'Morning Yoga',
        dueDate: DateTime(2026, 8, 18, 7, 0),
        createdAt: windowStart,
      );
      final task2 = Task(
        id: 't-2',
        title: 'System Design Workshop',
        startAt: DateTime(2026, 8, 18, 14, 0),
        endAt: DateTime(2026, 8, 18, 16, 0),
        organization: 'Tech Club',
        createdAt: windowStart,
      );
      final task3 = Task(
        id: 't-3',
        title: 'Evening Standup',
        dueDate: DateTime(2026, 8, 18, 18, 0),
        createdAt: windowStart,
      );

      final schedule = AstraScheduleItem.buildSchedule(
        tasks: [task2, task3, task1],
        windowStart: windowStart,
        windowEnd: windowEnd,
      );

      expect(schedule.length, 3);
      expect(schedule[0].title, 'Morning Yoga');
      expect(schedule[1].title, 'System Design Workshop');
      expect(schedule[1].organization, 'Tech Club');
      expect(schedule[2].title, 'Evening Standup');
    });

    // ─── J. TaskIntent Compatibility ─────────────────────────────────────────
    test('J. TaskIntent produces valid domain Task and json roundtrips', () {
      const rule = RecurrenceRule(
        frequency: RecurrenceFrequency.weekdays,
        hour: 9,
        minute: 0,
      );

      const intent = TaskIntent(
        title: 'Code Review Session',
        description: 'Review PR #42',
        taskType: 'event',
        priority: 'high',
        category: 'Engineering',
        organization: 'OpenSource',
        recurrenceRule: rule,
      );

      final task = intent.toTask();
      expect(task.title, 'Code Review Session');
      expect(task.priority, 'high');
      expect(task.recurrenceRule?.frequency, RecurrenceFrequency.weekdays);

      final json = intent.toJson();
      final roundtrip = TaskIntent.fromJson(json);
      expect(roundtrip.title, intent.title);
      expect(roundtrip.priority, intent.priority);
      expect(roundtrip.recurrenceRule?.frequency, RecurrenceFrequency.weekdays);
    });

    // ─── K. Narrow-Screen Task Data Safety ────────────────────────────────────
    test('K. Long titles and multi-line descriptions format safely', () {
      final task = Task(
        id: 't-long',
        title: 'A'.padRight(200, ' Very long complex multi-token engineering task title'),
        description: 'B'.padRight(1000, ' Detailed architecture description notes'),
        createdAt: DateTime.now(),
      );

      expect(task.title.length, greaterThan(150));
      expect(task.description?.length, greaterThan(500));
      expect(task.isActive, isTrue);
    });

    // ─── L. Restrained Palette & Active State Invariant ───────────────────────
    test('L. Active and Important states are determined deterministically', () {
      final activeTask = Task(
        id: 't-act',
        title: 'Active Task',
        status: 'active',
        priority: 'high',
        createdAt: DateTime.now(),
      );
      final completedTask = Task(
        id: 't-comp',
        title: 'Done Task',
        status: 'completed',
        createdAt: DateTime.now(),
      );

      expect(activeTask.isActive, isTrue);
      expect(activeTask.isImportant, isTrue);
      expect(completedTask.isActive, isFalse);
    });

    // ─── M. Haptics Invariant ────────────────────────────────────────────────
    test('M. AstraHaptics remains safe and non-blocking in all environments', () async {
      AstraHaptics.isEnabled = true;
      await AstraHaptics.selection();
      await AstraHaptics.light();
      await AstraHaptics.medium();
      await AstraHaptics.success();
      await AstraHaptics.warning();
      await AstraHaptics.delete();
      expect(AstraHaptics.isEnabled, isTrue);
    });
  });
}
