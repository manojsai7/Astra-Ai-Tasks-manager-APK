import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' as drift;
import 'package:astra/core/database/database.dart';
import 'package:astra/features/scheduler/data/services/gemini_context_extractor.dart';
import 'package:astra/features/tasks/domain/entities/task.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = constructInMemoryDb();
  });

  tearDown(() async {
    await db.close();
  });

  group('GeminiContextExtractor Tests', () {
    final extractor = GeminiContextExtractor();

    test('extracts application details from email heuristic fallback', () async {
      const emailSubject = 'Amazon SDE Internship Application Received';
      const emailSender = 'recruiting@amazon.com';
      const emailBody = '''
      Thank you for applying for the Software Development Engineer Intern position at Amazon AWS!
      Please complete your Online Assessment before July 20, 2026.
      Apply link: https://amazon.jobs/en/jobs/12345
      Requirements: Currently pursuing B.Tech in Computer Science, good DSA knowledge.
      ''';

      final result = await extractor.extractFromEmail(
        emailSubject: emailSubject,
        emailSender: emailSender,
        emailBody: emailBody,
        messageId: 'msg_1001',
      );

      expect(result.isTask, isTrue);
      expect(result.title, contains('Amazon'));
      expect(result.context.companyName, equals('Amazon'));
      expect(result.context.applicationLink, equals('https://amazon.jobs/en/jobs/12345'));
      expect(result.context.source, equals('gmail'));
    });

    test('extracts exam reminder details from calendar', () async {
      final startTime = DateTime(2026, 7, 15, 10, 0);
      final result = await extractor.extractFromCalendar(
        eventTitle: 'Data Structures Final Exam',
        description: 'Exam covers Trees, Graphs, and Dynamic Programming in Hall 4',
        location: 'Hall 4',
        startTime: startTime,
        eventId: 'cal_event_50',
        htmlLink: 'https://calendar.google.com/event?id=50',
      );

      expect(result.isTask, isTrue);
      expect(result.taskType, equals(TaskType.reminder));
      expect(result.dueAt, equals(startTime));
      expect(result.context.location, equals('Hall 4'));
      expect(result.context.source, equals('calendar'));
    });
  });

  group('AppDatabase TaskContext Storage Tests', () {
    test('saves and watches TaskContext entry in Drift SQLite database', () async {
      const taskId = 'test_task_99';
      final now = DateTime.now();

      // 1. Insert Task
      await db.into(db.tasks).insert(
            TasksCompanion.insert(
              id: taskId,
              title: 'Amazon SDE Internship Application',
              taskType: drift.Value(TaskType.application.value),
              priority: drift.Value(TaskPriority.high.value),
              status: drift.Value(TaskStatus.pending.value),
              createdAt: now,
              updatedAt: now,
            ),
          );

      // 2. Save TaskContext
      await db.saveTaskContext(
        TaskContextsCompanion.insert(
          taskId: taskId,
          companyName: const drift.Value('Amazon'),
          role: const drift.Value('Software Development Engineer Intern'),
          requirements: const drift.Value('B.Tech 3rd year, DSA'),
          applicationLink: const drift.Value('https://amazon.jobs/123'),
          hasApplied: const drift.Value(false),
          source: const drift.Value('gmail'),
        ),
      );

      // 3. Fetch TaskContext
      final ctx = await db.getTaskContextByTaskId(taskId);
      expect(ctx, isNotNull);
      expect(ctx!.companyName, equals('Amazon'));
      expect(ctx.role, equals('Software Development Engineer Intern'));
      expect(ctx.hasApplied, isFalse);

      // 4. Update Applied status
      await db.updateAppliedStatus(taskId, true);
      final updatedCtx = await db.getTaskContextByTaskId(taskId);
      expect(updatedCtx!.hasApplied, isTrue);
      expect(updatedCtx.appliedAt, isNotNull);
    });
  });
}
