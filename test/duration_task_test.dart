import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:astra/core/database/database.dart';
import 'package:astra/models/task.dart';
import 'package:astra/core/reminders/reminder.dart';
import 'package:astra/core/reminders/reminder_strategy.dart';
import 'package:astra/services/reminder_service.dart';
import 'package:astra/core/time/astra_time_service.dart';
import 'package:astra/core/time/astra_clock.dart';

void main() {
  group('ASTRA Part C & J: Duration Tasks, Drift SQLite Migration & Notification Strategy Tests', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('7. Duration Task persistence with startAt and endAt in Drift SQLite', () async {
      final task = Task(
        id: 'task_duration_1',
        title: 'SBT Fullstack Training',
        description: 'Fullstack training 8 days',
        startAt: DateTime(2026, 8, 17, 9, 0),
        endAt: DateTime(2026, 8, 25, 17, 0),
        dueDate: null,
        status: 'active',
        priority: 'high',
        createdAt: DateTime(2026, 8, 16, 10, 0),
      );

      // Verify domain model getters
      expect(task.isDuration, isTrue);
      expect(task.isDeadline, isFalse);

      // Insert into DB
      await db.into(db.tasks).insert(
            TasksCompanion.insert(
              id: task.id,
              title: task.title,
              description: Value(task.description),
              startAt: Value(task.startAt),
              endAt: Value(task.endAt),
              dueAt: Value(task.dueDate),
              createdAt: task.createdAt,
              updatedAt: task.createdAt,
            ),
          );

      final row = await (db.select(db.tasks)..where((t) => t.id.equals(task.id))).getSingle();
      expect(row.startAt, DateTime(2026, 8, 17, 9, 0));
      expect(row.endAt, DateTime(2026, 8, 25, 17, 0));
      expect(row.dueAt, isNull);
    });

    test('8. JSON serialization of Duration Task supports startAt and endAt', () {
      final task = Task(
        id: 'json_task_1',
        title: 'Aptitude Training',
        startAt: DateTime(2026, 8, 17, 9, 0),
        endAt: DateTime(2026, 8, 22, 17, 0),
        dueDate: null,
        createdAt: DateTime(2026, 8, 16, 10, 0),
      );

      final json = task.toJson();
      expect(json['startAt'], '2026-08-17T09:00:00.000');
      expect(json['endAt'], '2026-08-22T17:00:00.000');
      expect(json['dueDate'], isNull);

      final deserialized = Task.fromJson(json);
      expect(deserialized.startAt, task.startAt);
      expect(deserialized.endAt, task.endAt);
      expect(deserialized.isDuration, isTrue);
    });

    test('9. dueAt-only deadline regression test (startAt and endAt remain null)', () {
      final deadlineTask = Task(
        id: 'deadline_task_1',
        title: 'Submit Assignment',
        dueDate: DateTime(2026, 8, 21, 17, 0),
        startAt: null,
        endAt: null,
        createdAt: DateTime(2026, 8, 16, 10, 0),
      );

      expect(deadlineTask.isDeadline, isTrue);
      expect(deadlineTask.isDuration, isFalse);

      final json = deadlineTask.toJson();
      expect(json['dueDate'], '2026-08-21T17:00:00.000');
      expect(json['startAt'], isNull);
      expect(json['endAt'], isNull);
    });

    test('10. Notification strategy offsets for NORMAL, IMPORTANT, and DEADLINE', () {
      expect(ReminderStrategy.normal.offsets, [Duration.zero]);
      expect(ReminderStrategy.important.offsets, [
        const Duration(minutes: 10),
        const Duration(minutes: 4),
        Duration.zero,
      ]);
      expect(ReminderStrategy.deadline.offsets, [
        const Duration(minutes: 30),
        const Duration(minutes: 10),
        Duration.zero,
      ]);
      expect(ReminderStrategy.critical.offsets, [
        const Duration(minutes: 30),
        const Duration(minutes: 10),
        Duration.zero,
      ]);
    });

    test('11. Multi-offset reminder scheduling belongs to ONE task without creating duplicate tasks', () async {
      final now = DateTime.now();
      final timeService = AstraTimeService(
        clock: FixedAstraClock(now),
      );
      final reminderService = ReminderService(db, timeService: timeService);

      final targetTime = now.add(const Duration(days: 1)); // 1 day in future
      final result = await reminderService.scheduleReminder(
        taskId: 'unique_exam_task_1',
        taskTitle: 'Microsoft Exam',
        scheduledAt: targetTime,
        strategy: ReminderStrategy.important,
      );

      // Verify schedule was handled
      expect(result.outcome, isNot(ScheduleOutcome.pastTime));

      // Task count in database must remain exactly 0 duplicate tasks created by ReminderService
      final taskRows = await db.select(db.tasks).get();
      expect(taskRows.length, 0); // ReminderService manages Reminders table, never creates duplicate Task rows
    });
  });
}
