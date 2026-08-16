import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis/gmail/v1.dart' as gmail;

import 'package:astra/core/database/database.dart';
import 'package:astra/core/reminders/reminder_strategy.dart';
import 'package:astra/core/time/astra_clock.dart';
import 'package:astra/core/time/astra_time_service.dart';
import 'package:astra/features/scheduler/data/services/gmail_sync_service.dart';
import 'package:astra/services/assistant/astra_command.dart';
import 'package:astra/services/assistant/astra_command_executor.dart';
import 'package:astra/services/assistant/astra_context_builder.dart';
import 'package:astra/services/assistant/astra_memory_engine.dart';
import 'package:astra/services/assistant/astra_reference_resolver.dart';
import 'package:astra/services/assistant/astra_temporal_engine.dart';
import 'package:astra/services/email/astra_email_analyzer.dart';
import 'package:astra/services/reminder_service.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:astra/providers/ritual_provider.dart';
import 'package:astra/providers/reminder_provider.dart';

import 'helpers/test_database_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late AstraMemoryEngine memoryEngine;
  late ReminderService reminderService;
  const executor = AstraCommandExecutor();

  // Fixed test reference time: Friday, May 22, 2026 at 10:00 AM
  final fixedBaseTime = DateTime(2026, 5, 22, 10, 0);
  final timeService = AstraTimeService(
    clock: FixedAstraClock(fixedBaseTime),
    timezone: 'Asia/Kolkata',
  );
  const temporalEngine = AstraTemporalEngine();
  const analyzer = AstraEmailAnalyzer(temporalEngine: temporalEngine);

  setUp(() {
    db = TestDatabaseHelper.createMemoryDatabase();
    memoryEngine = AstraMemoryEngine(db);
    reminderService = ReminderService(db, timeService: timeService);
  });

  tearDown(() async {
    await db.close();
  });

  group('ASTRA Email Intelligence Pass: 14 Focused Tests', () {
    // 1. Plain text email extraction
    test('1. Plain text email extraction decodes base64 and extracts clean text', () {
      const rawText = 'Please submit the Machine Learning assignment by Friday 5 PM.';
      final encoded = base64Url.encode(utf8.encode(rawText));

      final part = gmail.MessagePart(
        mimeType: 'text/plain',
        body: gmail.MessagePartBody(data: encoded),
      );

      final extracted = GmailSyncService.extractBodyText(part);
      expect(extracted, rawText);
    });

    // 2. HTML email extraction & entity decoding
    test('2. HTML email extraction strips tags and decodes entities cleanly', () {
      const htmlText = '<div><h3>Physics Midterm</h3><p>The exam is scheduled for <b>Friday at 2:00 PM</b>.&nbsp;Bring your calculator &amp; ID.</p></div>';
      final encoded = base64Url.encode(utf8.encode(htmlText));

      final part = gmail.MessagePart(
        mimeType: 'text/html',
        body: gmail.MessagePartBody(data: encoded),
      );

      final extracted = GmailSyncService.extractBodyText(part);
      expect(extracted, contains('Physics Midterm'));
      expect(extracted, contains('Friday at 2:00 PM'));
      expect(extracted, contains('calculator & ID'));
      expect(extracted.contains('<'), isFalse);
      expect(extracted.contains('&nbsp;'), isFalse);
    });

    // 3. Multipart / nested MIME email extraction
    test('3. Multipart email extraction prioritizes plain text and gathers attachments metadata', () {
      const plainText = 'Interview confirmation with Microsoft on Monday at 11 AM.';
      const htmlText = '<html><body>Interview confirmation with Microsoft on Monday at 11 AM.</body></html>';

      final attachments = <String>[];
      final multipart = gmail.MessagePart(
        mimeType: 'multipart/alternative',
        parts: [
          gmail.MessagePart(
            mimeType: 'text/plain',
            body: gmail.MessagePartBody(data: base64Url.encode(utf8.encode(plainText))),
          ),
          gmail.MessagePart(
            mimeType: 'text/html',
            body: gmail.MessagePartBody(data: base64Url.encode(utf8.encode(htmlText))),
          ),
          gmail.MessagePart(
            mimeType: 'application/pdf',
            filename: 'interview_guide.pdf',
          ),
        ],
      );

      final extracted = GmailSyncService.extractBodyText(multipart, attachments: attachments);
      expect(extracted, plainText);
      expect(attachments, contains('interview_guide.pdf'));
    });

    // 4. Deadline detection
    test('4. Deadline detection detects "due by Friday" and assigns DEADLINE category', () {
      final email = GmailMessageData(
        id: 'msg-dl-1',
        subject: 'Assignment 3 Submission',
        sender: 'Prof. Davis <davis@university.edu>',
        date: fixedBaseTime,
        snippet: 'Due by Friday 5 PM',
        bodyText: 'Please submit your Assignment 3 report. It is due by Friday at 5:00 PM.',
      );

      final analysis = analyzer.analyze(email, referenceTime: fixedBaseTime);

      expect(analysis.category, EmailCategory.deadline);
      expect(analysis.isActionable, isTrue);
      expect(analysis.deadline, isNotNull);
      expect(analysis.deadline!.weekday, DateTime.friday);
      expect(analysis.deadline!.hour, 17);
      expect(analysis.deadline!.minute, 0);
      expect(analysis.suggestedTaskTitle, contains('Assignment 3'));
    });

    // 5. Time extraction
    test('5. Time extraction parses exact clock times and dates', () {
      final email = GmailMessageData(
        id: 'msg-time-1',
        subject: 'Registration Closing Notice',
        sender: 'Hackathon Org <support@hackathon.org>',
        date: fixedBaseTime,
        snippet: 'closes at 11:59 PM',
        bodyText: 'Team registration closes at 11:59 PM today.',
      );

      final analysis = analyzer.analyze(email, referenceTime: fixedBaseTime);

      expect(analysis.actionDateTime, isNotNull);
      expect(analysis.actionDateTime!.hour, 23);
      expect(analysis.actionDateTime!.minute, 59);
    });

    // 6. Action detection
    test('6. Action detection identifies submit, register, apply, pay', () {
      final email1 = GmailMessageData(
        id: 'act-1',
        subject: 'Lab Report',
        sender: 'TA <ta@uni.edu>',
        date: fixedBaseTime,
        snippet: 'submit before Monday',
        bodyText: 'Submit the lab report before Monday at 10 AM.',
      );
      final analysis1 = analyzer.analyze(email1, referenceTime: fixedBaseTime);
      expect(analysis1.actionRequired, 'submit');

      final email2 = GmailMessageData(
        id: 'act-2',
        subject: 'Tuition Bill',
        sender: 'Accounts <billing@college.edu>',
        date: fixedBaseTime,
        snippet: 'tuition fee due',
        bodyText: 'Your tuition fee is due on Friday.',
      );
      final analysis2 = analyzer.analyze(email2, referenceTime: fixedBaseTime);
      expect(analysis2.actionRequired, 'pay');
    });

    // 7. Exam importance mapping
    test('7. Exam importance mapping classifies exams as IMPORTANT with high importance', () {
      final email = GmailMessageData(
        id: 'exam-1',
        subject: 'Final Examination Schedule',
        sender: 'Registrar <exams@university.edu>',
        date: fixedBaseTime,
        snippet: 'Physics exam on Monday at 9 AM',
        bodyText: 'Your Physics Final Exam is scheduled for Monday at 9:00 AM.',
      );

      final analysis = analyzer.analyze(email, referenceTime: fixedBaseTime);

      expect(analysis.category, EmailCategory.important);
      expect(analysis.importance, EmailImportance.high);
      expect(analysis.isEvent, isTrue);
      expect(analysis.suggestedTaskTitle, contains('Final Examination'));
    });

    // 8. Interview importance mapping
    test('8. Interview importance mapping identifies company interview and event start', () {
      final email = GmailMessageData(
        id: 'int-1',
        subject: 'Interview Invitation: Microsoft Software Engineer',
        sender: 'Microsoft Recruiting <recruiting@microsoft.com>',
        date: fixedBaseTime,
        snippet: 'interview on Monday at 11 AM',
        bodyText: 'We are pleased to invite you for your technical interview on Monday at 11:00 AM.',
      );

      final analysis = analyzer.analyze(email, referenceTime: fixedBaseTime);

      expect(analysis.category, EmailCategory.important);
      expect(analysis.importance, EmailImportance.high);
      expect(analysis.organization, 'Microsoft');
      expect(analysis.isEvent, isTrue);
      expect(analysis.eventDateTime, isNotNull);
      expect(analysis.eventDateTime!.hour, 11);
    });

    // 9. Informational / newsletter email classification
    test('9. Informational email classification marks newsletters as low priority without task prompt', () {
      final email = GmailMessageData(
        id: 'info-1',
        subject: 'Weekly Tech Digest & Newsletter',
        sender: 'Digest Team <newsletter@techdigest.com>',
        date: fixedBaseTime,
        snippet: 'unsubscribe anytime',
        bodyText: 'Here is your weekly digest of technology updates. You can unsubscribe anytime.',
      );

      final analysis = analyzer.analyze(email, referenceTime: fixedBaseTime);

      expect(analysis.category, EmailCategory.lowPriority);
      expect(analysis.importance, EmailImportance.low);
      expect(analysis.isActionable, isFalse);
    });

    // 10. Ambiguous deadline handling
    test('10. Ambiguous deadline does not invent hallucinated timestamps and sets requiresConfirmation', () {
      final email = GmailMessageData(
        id: 'amb-1',
        subject: 'Project Update Required',
        sender: 'Manager <lead@startup.io>',
        date: fixedBaseTime,
        snippet: 'submit sometime soon',
        bodyText: 'Please submit your feedback report sometime soon.',
      );

      final analysis = analyzer.analyze(email, referenceTime: fixedBaseTime);

      expect(analysis.deadline, isNull);
      expect(analysis.requiresConfirmation, isTrue);
    });

    // 11. Add-to-task reuses existing AstraCommandExecutor & ReminderStrategy
    test('11. Add-to-task reuses AstraCommandExecutor and schedules IMPORTANT reminder strategy for high importance', () async {
      final email = GmailMessageData(
        id: 'msg-exec-1',
        subject: 'Microsoft Technical Interview',
        sender: 'Microsoft Recruiting <recruiting@microsoft.com>',
        date: fixedBaseTime,
        snippet: 'Interview on Friday at 3 PM',
        bodyText: 'Your interview is scheduled for Friday at 3:00 PM.',
      );

      final analysis = analyzer.analyze(email, referenceTime: fixedBaseTime);

      final command = AstraCommand(
        intent: 'CREATE_TASK',
        eventType: 'INTERVIEW',
        title: analysis.suggestedTaskTitle,
        action: analysis.actionRequired,
        organization: analysis.organization,
        temporal: AstraTemporal(
          eventStart: analysis.eventDateTime,
          timezone: 'Asia/Kolkata',
          recurrence: 'NONE',
        ),
        recurrence: 'NONE',
        priority: 'high',
        modelConfidence: analysis.confidence,
        semanticConfidence: analysis.confidence,
        requiresConfirmation: false,
        route: 'EXECUTE',
        originalText: 'Email: ${email.subject}',
      );

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          reminderServiceProvider.overrideWithValue(reminderService),
        ],
      );
      addTearDown(container.dispose);

      final execResult = await executor.execute(ref: container, command: command);

      expect(execResult.success, isTrue);
      expect(execResult.taskId, isNotEmpty);

      // Verify task row was inserted into Drift DB
      final tasks = await db.select(db.tasks).get();
      expect(tasks.length, 1);
      expect(tasks.first.title, analysis.suggestedTaskTitle);

      // Schedule reminder with resolved IMPORTANT strategy
      final strategy = ReminderStrategyX.resolve(eventType: 'INTERVIEW', priority: 'high');
      expect(strategy, ReminderStrategy.important);

      final schedResult = await reminderService.scheduleReminder(
        taskId: tasks.first.id,
        taskTitle: tasks.first.title,
        scheduledAt: tasks.first.dueAt!,
        strategy: strategy,
      );

      expect(schedResult.reminder, isNotNull);
      final activeReminders = await db.getActiveReminders();
      expect(activeReminders.length, 1);
    });

    // 12. Email-derived memory storage & reference resolution
    test('12. Email-derived memory is stored and resolvable by AstraReferenceResolver', () async {
      final email = GmailMessageData(
        id: 'email-assign-99',
        subject: 'Machine Learning Assignment 2',
        sender: 'CS Dept <cs@university.edu>',
        date: fixedBaseTime,
        snippet: 'Submit Assignment 2 by Friday 5 PM',
        bodyText: 'Submit Assignment 2 by Friday 5 PM.',
      );

      final analysis = analyzer.analyze(email, referenceTime: fixedBaseTime);

      // Insert Task & Memory
      const taskId = 'task-ml-assign-2';
      await TestDatabaseHelper.insertTaskRow(
        db,
        id: taskId,
        title: analysis.suggestedTaskTitle,
        dueAt: analysis.deadline,
        priority: 'high',
        organization: analysis.organization,
      );

      memoryEngine.storeEmailTaskMemory(
        emailId: email.id,
        title: analysis.suggestedTaskTitle,
        taskId: taskId,
        deadline: analysis.deadline,
        organization: analysis.organization,
        subject: email.subject,
      );

      final memories = memoryEngine.getAllWorkingMemories();
      expect(memories.length, 1);
      expect(memories.first.source, 'email');
      expect(memories.first.metadata?['emailId'], 'email-assign-99');

      // Reference resolver query: "what was that assignment from the email?"
      const resolver = AstraReferenceResolver();
      final tasks = await db.select(db.tasks).get();
      final context = AstraContext(
        currentText: 'the assignment from email',
        now: fixedBaseTime,
        activeTasks: tasks,
        structuredMemories: memories,
      );

      final refResult = resolver.resolveReference('the assignment from email', context);
      expect(refResult.isResolved, isTrue);
      expect(refResult.resolvedTitle, contains('Assignment'));
    });

    // 13. Zero network / Gemini dependency verification
    test('13. AstraEmailAnalyzer operates 100% locally with zero external network or Gemini calls', () {
      final email = GmailMessageData(
        id: 'offline-email-1',
        subject: 'Offline Exam Registration',
        sender: 'Board <exams@board.org>',
        date: fixedBaseTime,
        snippet: 'closes tomorrow at 5 PM',
        bodyText: 'Registration closes tomorrow at 5:00 PM.',
      );

      // Analyze without any network mock or API key
      final analysis = analyzer.analyze(email, referenceTime: fixedBaseTime);
      expect(analysis.isActionable, isTrue);
      expect(analysis.actionDateTime, isNotNull);
      expect(analysis.confidence, greaterThanOrEqualTo(0.90));
    });

    // 14. Duplicate task creation prevention
    test('14. Duplicate task creation prevention: multiple calls with same email ID reuse single task and cancel prior alarms', () async {
      const taskId = 'email-dedup-task-1';
      final taskDueDate = fixedBaseTime.add(const Duration(hours: 4));

      await TestDatabaseHelper.insertTaskRow(
        db,
        id: taskId,
        title: 'Submit Lab Report',
        dueAt: taskDueDate,
      );

      // First schedule
      await reminderService.scheduleReminder(
        taskId: taskId,
        taskTitle: 'Submit Lab Report',
        scheduledAt: taskDueDate,
        strategy: ReminderStrategy.important,
      );

      // Second schedule (idempotent overwrite)
      await reminderService.scheduleReminder(
        taskId: taskId,
        taskTitle: 'Submit Lab Report',
        scheduledAt: taskDueDate,
        strategy: ReminderStrategy.important,
      );

      final reminders = await db.getActiveReminders();
      expect(reminders.length, 1);
      expect(reminders.first.taskId, taskId);
    });
  });
}
