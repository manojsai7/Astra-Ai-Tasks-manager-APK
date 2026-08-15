import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:http/http.dart' as http;

import 'package:astra/core/database/database.dart';
import 'package:astra/models/task.dart';
import 'package:astra/features/scheduler/data/services/google_calendar_writer_service.dart';
import 'package:astra/providers/ritual_provider.dart';
import 'package:astra/providers/task_provider.dart';
import 'package:astra/providers/reminder_provider.dart';
import 'package:astra/services/reminder_service.dart';
import 'package:astra/services/assistant/astra_command.dart';
import 'package:astra/services/assistant/astra_command_executor.dart';
import 'package:astra/services/assistant/astra_recurrence_engine.dart';
import 'package:astra/services/assistant/astra_update_command.dart';
import 'helpers/test_mock_auth.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late AppDatabase testDb;
  const executor = AstraCommandExecutor();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    testDb = AppDatabase(NativeDatabase.memory());

    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(testDb),
        reminderServiceProvider.overrideWithValue(ReminderService(testDb)),
        taskNotifierProvider.overrideWith((ref) => TaskNotifier(testDb, ReminderService(testDb))..loadTasks()),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await testDb.close();
  });

  group('AstraCommand executor contract', () {
    test(
      'CREATE_TASK command contains executable temporal data',
      () {
        final command = AstraCommand(
          intent: 'CREATE_TASK',
          eventType: 'EXAM',
          title: 'Exam',
          action: 'ATTEND',
          organization: null,
          temporal: AstraTemporal(
            eventStart: DateTime(
              2026,
              8,
              15,
              18,
              0,
            ),
            recurrence: 'NONE',
          ),
          recurrence: 'NONE',
          priority: 'normal',
          modelConfidence: 0.95,
          semanticConfidence: 0.95,
          requiresConfirmation: false,
          route: 'EXECUTE',
          originalText:
              'bruh i have exam today at 6pm',
        );

        expect(
          command.intent,
          'CREATE_TASK',
        );

        expect(
          command.eventType,
          'EXAM',
        );

        expect(
          command.temporal.eventStart,
          isNotNull,
        );
      },
    );

    test(
      'CREATE_REMINDER command represents reminder intent',
      () {
        final command = AstraCommand(
          intent: 'CREATE_REMINDER',
          eventType: 'OTHER',
          title: 'Drink water',
          action: null,
          organization: null,
          temporal: AstraTemporal(
            eventStart:
                DateTime.now().add(
              const Duration(minutes: 2),
            ),
            recurrence: 'NONE',
          ),
          recurrence: 'NONE',
          priority: 'normal',
          modelConfidence: 0.99,
          semanticConfidence: 0.99,
          requiresConfirmation: false,
          route: 'EXECUTE',
          originalText:
              'remind me to drink water in 2 mins',
        );

        expect(
          command.intent,
          'CREATE_REMINDER',
        );

        expect(
          command.title,
          'Drink water',
        );
      },
    );

    test('Microsoft interview Monday at 11am represents calendar event with org', () {
      final command = AstraCommand(
        intent: 'CREATE_CALENDAR_EVENT',
        eventType: 'INTERVIEW',
        title: 'Microsoft Interview',
        action: 'ATTEND',
        organization: 'Microsoft',
        temporal: AstraTemporal(
          eventStart: DateTime(2026, 8, 17, 11, 0),
          recurrence: 'NONE',
        ),
        recurrence: 'NONE',
        priority: 'normal',
        modelConfidence: 0.95,
        semanticConfidence: 0.95,
        requiresConfirmation: false,
        route: 'EXECUTE',
        originalText: 'Microsoft interview Monday at 11am',
      );

      expect(command.intent, 'CREATE_CALENDAR_EVENT');
      expect(command.organization, 'Microsoft');
      expect(command.title, 'Microsoft Interview');
      expect(command.temporal.eventStart, isNotNull);
    });

    test('submit assignment tomorrow by 5 requires confirmation and cannot auto-execute', () {
      final command = AstraCommand(
        intent: 'CREATE_TASK',
        eventType: 'ASSIGNMENT',
        title: 'Assignment',
        action: 'SUBMIT',
        organization: null,
        temporal: const AstraTemporal(
          ambiguous: true,
          warnings: ['Bare deadline time "5" is ambiguous.'],
        ),
        recurrence: 'NONE',
        priority: 'normal',
        modelConfidence: 0.90,
        semanticConfidence: 0.90,
        requiresConfirmation: true,
        route: 'CONFIRM',
        originalText: 'submit assignment tomorrow by 5',
      );

      expect(command.requiresConfirmation, true);
      expect(command.route, 'CONFIRM');
    });
  });

  group('AstraCommandExecutor Recurrence Tests (Phase 2V-3)', () {
    // A. Daily recurrence: "study every day at 9am"
    test('A. Daily recurrence: persists RecurrenceRule, sets first valid occurrence, schedules 1 reminder', () async {
      final futureDate = DateTime.now().add(const Duration(days: 1));
      final command = AstraCommand(
        intent: 'CREATE_TASK',
        eventType: 'STUDY',
        title: 'Study',
        action: 'STUDY',
        organization: null,
        temporal: AstraTemporal(
          eventStart: DateTime(futureDate.year, futureDate.month, futureDate.day, 9, 0),
          rawTime: '9am',
          recurrence: 'DAILY',
        ),
        recurrence: 'DAILY',
        priority: 'medium',
        modelConfidence: 0.95,
        semanticConfidence: 0.95,
        requiresConfirmation: false,
        route: 'EXECUTE',
        originalText: 'study every day at 9am',
      );

      final result = await executor.execute(ref: container, command: command);
      expect(result.success, isTrue);

      final tasks = await testDb.select(testDb.tasks).get();
      expect(tasks.length, 1);
      final task = tasks.first;
      expect(task.title, 'Study');
      expect(task.recurrenceRuleJson, isNotNull);

      final rule = RecurrenceRule.fromJson(task.recurrenceRuleJson!);
      expect(rule.frequency, RecurrenceFrequency.daily);
      expect(rule.hour, 9);
      expect(rule.minute, 0);

      // Verify task dueDate matches first valid occurrence
      expect(task.dueAt, isNotNull);
      expect(task.dueAt!.hour, 9);
      expect(task.dueAt!.minute, 0);

      // Verify exactly ONE reminder is scheduled
      final reminders = await testDb.select(testDb.reminders).get();
      expect(reminders.length, 1);
      expect(reminders.first.taskId, task.id);
      expect(reminders.first.scheduledAt, task.dueAt);
    });

    // B. Weekdays recurrence: "training every weekday from 25 May to 18 June at 9am"
    test('B. Weekdays recurrence: persists window, sets first weekday occurrence, schedules 1 reminder', () async {
      final command = AstraCommand(
        intent: 'CREATE_TASK',
        eventType: 'TRAINING',
        title: 'Training',
        action: 'ATTEND',
        organization: null,
        temporal: AstraTemporal(
          eventStart: DateTime(2026, 5, 25, 9, 0), // 2026-05-25 is Monday
          eventEnd: DateTime(2026, 6, 18, 13, 0),
          rawTime: '9am to 1pm',
          recurrence: 'WEEKDAYS',
        ),
        recurrence: 'WEEKDAYS',
        priority: 'high',
        modelConfidence: 0.95,
        semanticConfidence: 0.95,
        requiresConfirmation: false,
        route: 'EXECUTE',
        originalText: 'training every weekday from 25 May to 18 June at 9am',
      );

      final result = await executor.execute(ref: container, command: command);
      expect(result.success, isTrue);

      final tasks = await testDb.select(testDb.tasks).get();
      expect(tasks.length, 1);
      final task = tasks.first;
      expect(task.title, 'Training');

      final rule = RecurrenceRule.fromJson(task.recurrenceRuleJson!);
      expect(rule.frequency, RecurrenceFrequency.weekdays);
      expect(rule.startDate, DateTime(2026, 5, 25, 9, 0));
      expect(rule.endDate, DateTime(2026, 6, 18, 13, 0));
      expect(rule.hour, 9);
      expect(rule.endHour, 13);

      expect(task.dueAt, DateTime(2026, 5, 25, 9, 0));

      final reminders = await testDb.select(testDb.reminders).get();
      expect(reminders.length, 1);
      expect(reminders.first.taskId, task.id);
      expect(reminders.first.scheduledAt, DateTime(2026, 5, 25, 9, 0));
    });

    // C. Weekly recurrence: "meeting every Monday at 11am"
    test('C. Weekly recurrence: persists weekly rule with Monday weekday', () async {
      final command = AstraCommand(
        intent: 'CREATE_CALENDAR_EVENT',
        eventType: 'MEETING',
        title: 'Meeting',
        action: 'ATTEND',
        organization: null,
        temporal: AstraTemporal(
          eventStart: DateTime(2026, 8, 17, 11, 0), // Monday
          rawTime: '11am',
          recurrence: 'WEEKLY',
        ),
        recurrence: 'WEEKLY',
        priority: 'medium',
        modelConfidence: 0.95,
        semanticConfidence: 0.95,
        requiresConfirmation: false,
        route: 'EXECUTE',
        originalText: 'meeting every Monday at 11am',
      );

      final result = await executor.execute(ref: container, command: command);
      expect(result.success, isTrue);

      final tasks = await testDb.select(testDb.tasks).get();
      final task = tasks.first;
      final rule = RecurrenceRule.fromJson(task.recurrenceRuleJson!);
      expect(rule.frequency, RecurrenceFrequency.weekly);
      expect(rule.byWeekdays, contains(DateTime.monday));
      expect(rule.hour, 11);

      final reminders = await testDb.select(testDb.reminders).get();
      expect(reminders.length, 1);
    });

    // D. Monthly recurrence: "pay fee every month on the 25th"
    test('D. Monthly recurrence: persists monthly rule and calculates day 25', () async {
      final command = AstraCommand(
        intent: 'CREATE_TASK',
        eventType: 'PAYMENT',
        title: 'Pay Fee',
        action: 'PAY',
        organization: null,
        temporal: AstraTemporal(
          eventStart: DateTime(2026, 8, 25, 10, 0),
          rawTime: '10am',
          recurrence: 'MONTHLY',
        ),
        recurrence: 'MONTHLY',
        priority: 'high',
        modelConfidence: 0.95,
        semanticConfidence: 0.95,
        requiresConfirmation: false,
        route: 'EXECUTE',
        originalText: 'pay fee every month on the 25th',
      );

      final result = await executor.execute(ref: container, command: command);
      expect(result.success, isTrue);

      final tasks = await testDb.select(testDb.tasks).get();
      final task = tasks.first;
      final rule = RecurrenceRule.fromJson(task.recurrenceRuleJson!);
      expect(rule.frequency, RecurrenceFrequency.monthly);
      expect(rule.hour, 10);

      final reminders = await testDb.select(testDb.reminders).get();
      expect(reminders.length, 1);
    });

    // E. Non-recurring regression
    test('E. Non-recurring regression: simple reminder and exam have recurrenceRule == null', () async {
      final reminderCmd = AstraCommand(
        intent: 'CREATE_REMINDER',
        eventType: 'OTHER',
        title: 'Drink water',
        action: null,
        organization: null,
        temporal: AstraTemporal(
          eventStart: DateTime.now().add(const Duration(minutes: 2)),
          recurrence: 'NONE',
        ),
        recurrence: 'NONE',
        priority: 'medium',
        modelConfidence: 0.99,
        semanticConfidence: 0.99,
        requiresConfirmation: false,
        route: 'EXECUTE',
        originalText: 'remind me to drink water in 2 mins',
      );

      final result = await executor.execute(ref: container, command: reminderCmd);
      expect(result.success, isTrue);

      final tasks = await testDb.select(testDb.tasks).get();
      final task = tasks.first;
      expect(task.title, 'Drink water');
      expect(task.recurrenceRuleJson, isNull);

      final reminders = await testDb.select(testDb.reminders).get();
      expect(reminders.length, 1);
    });
  });

  group('AstraCommandExecutor Google Calendar Write Integration (Phase 2X-4)', () {
    // A. CREATE_CALENDAR_EVENT with valid Google client
    test('A. CREATE_CALENDAR_EVENT with valid Google client creates local task/reminder and writes to Google Calendar', () async {
      int writerCallCount = 0;
      final mockWriter = MockGoogleCalendarWriterService((client, {
        required title,
        required startTime,
        endTime,
        description,
        location,
        timezone = 'Asia/Kolkata',
        recurrenceRule,
      }) async {
        writerCallCount++;
        return FakeTestCalendarEvent(id: 'google_cal_123');
      });

      final mockAuth = MockGoogleAuthService(
        clientToReturn: MockAuthClient((req) async => http.StreamedResponse(Stream.value([]), 200)),
      );

      final testExecutor = AstraCommandExecutor(
        googleAuthService: mockAuth,
        googleCalendarWriterService: mockWriter,
      );

      final command = AstraCommand(
        intent: 'CREATE_CALENDAR_EVENT',
        eventType: 'INTERVIEW',
        title: 'Microsoft Interview',
        action: 'ATTEND',
        organization: 'Microsoft',
        temporal: AstraTemporal(
          eventStart: DateTime(2026, 8, 17, 11, 0),
          recurrence: 'NONE',
        ),
        recurrence: 'NONE',
        priority: 'high',
        modelConfidence: 0.98,
        semanticConfidence: 0.98,
        requiresConfirmation: false,
        route: 'EXECUTE',
        originalText: 'Microsoft interview Monday at 11am',
      );

      final result = await testExecutor.execute(ref: container, command: command);

      // Local invariants
      expect(result.success, isTrue);
      expect(result.calendarSynced, isTrue);
      expect(result.googleEventId, 'google_cal_123');
      expect(writerCallCount, 1);

      final tasks = await testDb.select(testDb.tasks).get();
      expect(tasks.length, 1);
      expect(tasks.first.title, 'Microsoft Interview');
      expect(tasks.first.organization, 'Microsoft');

      final reminders = await testDb.select(testDb.reminders).get();
      expect(reminders.length, 1);
    });

    // B. Google auth unavailable: local task still created, calendarSynced == false, clear message, no crash
    test('B. Google auth unavailable: local task + reminder created, calendarSynced == false, no crash', () async {
      int writerCallCount = 0;
      final mockWriter = MockGoogleCalendarWriterService((client, {
        required title,
        required startTime,
        endTime,
        description,
        location,
        timezone = 'Asia/Kolkata',
        recurrenceRule,
      }) async {
        writerCallCount++;
        return FakeTestCalendarEvent(id: 'dummy');
      });

      final mockAuth = MockGoogleAuthService(clientToReturn: null);

      final testExecutor = AstraCommandExecutor(
        googleAuthService: mockAuth,
        googleCalendarWriterService: mockWriter,
      );

      final command = AstraCommand(
        intent: 'CREATE_CALENDAR_EVENT',
        eventType: 'INTERVIEW',
        title: 'Google Interview',
        action: 'ATTEND',
        organization: 'Google',
        temporal: AstraTemporal(
          eventStart: DateTime(2026, 8, 18, 14, 0),
          recurrence: 'NONE',
        ),
        recurrence: 'NONE',
        priority: 'high',
        modelConfidence: 0.98,
        semanticConfidence: 0.98,
        requiresConfirmation: false,
        route: 'EXECUTE',
        originalText: 'Google interview Tuesday at 2pm',
      );

      final result = await testExecutor.execute(ref: container, command: command);

      expect(result.success, isTrue);
      expect(result.calendarSynced, isFalse);
      expect(result.calendarMessage, contains('Google Calendar permission is required'));
      expect(result.googleEventId, isNull);
      expect(writerCallCount, 0);

      final tasks = await testDb.select(testDb.tasks).get();
      expect(tasks.length, 1);
      expect(tasks.first.title, 'Google Interview');
    });

    // C. Google 403 permission error: local task still created, calendarSynced == false, permission message
    test('C. Google 403 permission error: local task created, calendarSynced == false with permission message', () async {
      final mockWriter = MockGoogleCalendarWriterService((client, {
        required title,
        required startTime,
        endTime,
        description,
        location,
        timezone = 'Asia/Kolkata',
        recurrenceRule,
      }) async {
        throw const GoogleCalendarWriteException(
          code: GoogleCalendarWriteErrorCode.permissionRequired,
          message: 'Insufficient Calendar permissions.',
        );
      });

      final mockAuth = MockGoogleAuthService(
        clientToReturn: MockAuthClient((req) async => http.StreamedResponse(Stream.value([]), 200)),
      );

      final testExecutor = AstraCommandExecutor(
        googleAuthService: mockAuth,
        googleCalendarWriterService: mockWriter,
      );

      final command = AstraCommand(
        intent: 'CREATE_CALENDAR_EVENT',
        eventType: 'INTERVIEW',
        title: 'Apple Interview',
        action: 'ATTEND',
        organization: 'Apple',
        temporal: AstraTemporal(
          eventStart: DateTime(2026, 8, 19, 10, 0),
          recurrence: 'NONE',
        ),
        recurrence: 'NONE',
        priority: 'high',
        modelConfidence: 0.98,
        semanticConfidence: 0.98,
        requiresConfirmation: false,
        route: 'EXECUTE',
        originalText: 'Apple interview Wednesday at 10am',
      );

      final result = await testExecutor.execute(ref: container, command: command);

      expect(result.success, isTrue);
      expect(result.calendarSynced, isFalse);
      expect(result.calendarMessage, contains('Google Calendar permission is required'));

      final tasks = await testDb.select(testDb.tasks).get();
      expect(tasks.length, 1);
    });

    // D. Network failure: local task still created, calendarSynced == false
    test('D. Network failure: local task created, calendarSynced == false with network message', () async {
      final mockWriter = MockGoogleCalendarWriterService((client, {
        required title,
        required startTime,
        endTime,
        description,
        location,
        timezone = 'Asia/Kolkata',
        recurrenceRule,
      }) async {
        throw const GoogleCalendarWriteException(
          code: GoogleCalendarWriteErrorCode.networkError,
          message: 'Network unreachable.',
        );
      });

      final mockAuth = MockGoogleAuthService(
        clientToReturn: MockAuthClient((req) async => http.StreamedResponse(Stream.value([]), 200)),
      );

      final testExecutor = AstraCommandExecutor(
        googleAuthService: mockAuth,
        googleCalendarWriterService: mockWriter,
      );

      final command = AstraCommand(
        intent: 'CREATE_CALENDAR_EVENT',
        eventType: 'MEETING',
        title: 'Meta Meeting',
        action: 'ATTEND',
        organization: 'Meta',
        temporal: AstraTemporal(
          eventStart: DateTime(2026, 8, 20, 15, 0),
          recurrence: 'NONE',
        ),
        recurrence: 'NONE',
        priority: 'medium',
        modelConfidence: 0.98,
        semanticConfidence: 0.98,
        requiresConfirmation: false,
        route: 'EXECUTE',
        originalText: 'Meta meeting Thursday at 3pm',
      );

      final result = await testExecutor.execute(ref: container, command: command);

      expect(result.success, isTrue);
      expect(result.calendarSynced, isFalse);
      expect(result.calendarMessage, contains('Google Calendar sync is unavailable'));

      final tasks = await testDb.select(testDb.tasks).get();
      expect(tasks.length, 1);
    });

    // E. Recurring calendar event: recurrenceRule passed to writer, 1 local reminder
    test('E. Recurring calendar event: recurrenceRule persisted locally and passed to Google writer', () async {
      RecurrenceRule? capturedRule;
      final mockWriter = MockGoogleCalendarWriterService((client, {
        required title,
        required startTime,
        endTime,
        description,
        location,
        timezone = 'Asia/Kolkata',
        recurrenceRule,
      }) async {
        capturedRule = recurrenceRule;
        return FakeTestCalendarEvent(id: 'recurring_cal_999');
      });

      final mockAuth = MockGoogleAuthService(
        clientToReturn: MockAuthClient((req) async => http.StreamedResponse(Stream.value([]), 200)),
      );

      final testExecutor = AstraCommandExecutor(
        googleAuthService: mockAuth,
        googleCalendarWriterService: mockWriter,
      );

      final command = AstraCommand(
        intent: 'CREATE_CALENDAR_EVENT',
        eventType: 'MEETING',
        title: 'Weekly Sync',
        action: 'ATTEND',
        organization: null,
        temporal: AstraTemporal(
          eventStart: DateTime(2026, 8, 17, 10, 0),
          rawTime: '10am',
          recurrence: 'WEEKLY',
        ),
        recurrence: 'WEEKLY',
        priority: 'medium',
        modelConfidence: 0.95,
        semanticConfidence: 0.95,
        requiresConfirmation: false,
        route: 'EXECUTE',
        originalText: 'weekly sync Monday at 10am',
      );

      final result = await testExecutor.execute(ref: container, command: command);

      expect(result.success, isTrue);
      expect(result.calendarSynced, isTrue);
      expect(capturedRule, isNotNull);
      expect(capturedRule!.frequency, RecurrenceFrequency.weekly);

      final tasks = await testDb.select(testDb.tasks).get();
      expect(tasks.length, 1);
      expect(tasks.first.recurrenceRuleJson, isNotNull);

      final reminders = await testDb.select(testDb.reminders).get();
      expect(reminders.length, 1);
    });

    // F. Non-calendar CREATE_TASK: Google writer is never called
    test('F. Non-calendar CREATE_TASK: Google writer is never invoked', () async {
      int writerCallCount = 0;
      final mockWriter = MockGoogleCalendarWriterService((client, {
        required title,
        required startTime,
        endTime,
        description,
        location,
        timezone = 'Asia/Kolkata',
        recurrenceRule,
      }) async {
        writerCallCount++;
        return FakeTestCalendarEvent(id: 'unexpected');
      });

      final mockAuth = MockGoogleAuthService(
        clientToReturn: MockAuthClient((req) async => http.StreamedResponse(Stream.value([]), 200)),
      );

      final testExecutor = AstraCommandExecutor(
        googleAuthService: mockAuth,
        googleCalendarWriterService: mockWriter,
      );

      final command = AstraCommand(
        intent: 'CREATE_TASK',
        eventType: 'EXAM',
        title: 'Exam',
        action: 'ATTEND',
        organization: null,
        temporal: AstraTemporal(
          eventStart: DateTime(2026, 8, 15, 18, 0),
          recurrence: 'NONE',
        ),
        recurrence: 'NONE',
        priority: 'high',
        modelConfidence: 0.99,
        semanticConfidence: 0.99,
        requiresConfirmation: false,
        route: 'EXECUTE',
        originalText: 'bruh i have exam today at 6pm',
      );

      final result = await testExecutor.execute(ref: container, command: command);

      expect(result.success, isTrue);
      expect(result.calendarSynced, isFalse);
      expect(result.googleEventId, isNull);
      expect(writerCallCount, 0);
    });
  });

  group('AstraCommandExecutor UPDATE_TASK Integration Tests (Phase 2Y-4)', () {
    const updateParser = AstraUpdateParser();
    final now = DateTime(2026, 8, 15, 10, 0); // Saturday 10:00 AM

    test('A. Reschedule exact task: dueDate updated, reminder rescheduled, no duplicate task', () async {
      final taskNotifier = container.read(taskNotifierProvider.notifier);
      final reminderService = container.read(reminderServiceProvider);

      final initialTask = Task(
        id: 'exam-1',
        title: 'Exam',
        dueDate: DateTime(2026, 8, 15, 18, 0),
        priority: 'high',
        status: 'active',
        createdAt: now,
      );
      await taskNotifier.addTask(initialTask);
      await reminderService.scheduleReminder(
        taskId: initialTask.id,
        taskTitle: initialTask.title,
        scheduledAt: initialTask.dueDate!,
      );

      final updateCmd = updateParser.parse(text: 'move my exam to tomorrow at 7pm', now: now);
      final activeTasks = container.read(taskNotifierProvider);

      final result = await executor.update(ref: container, command: updateCmd, activeTasks: activeTasks);

      expect(result.success, isTrue);
      expect(result.requiresConfirmation, isFalse);

      // Verify task updated in DB
      final tasksInDb = await testDb.select(testDb.tasks).get();
      expect(tasksInDb.length, 1);
      expect(tasksInDb.first.dueAt, DateTime(2026, 8, 16, 19, 0));

      // Verify exactly 1 active reminder in DB at new time
      final remindersInDb = await testDb.select(testDb.reminders).get();
      final activeReminders = remindersInDb.where((r) => r.status != 'cancelled').toList();
      expect(activeReminders.length, 1);
      expect(activeReminders.first.scheduledAt, DateTime(2026, 8, 16, 19, 0));
    });

    test('B. Reschedule by organization/title: "reschedule my Microsoft interview to 2pm"', () async {
      final taskNotifier = container.read(taskNotifierProvider.notifier);
      final initialTask = Task(
        id: 'interview-1',
        title: 'Microsoft Interview',
        organization: 'Microsoft',
        dueDate: DateTime(2026, 8, 17, 11, 0),
        priority: 'high',
        status: 'active',
        createdAt: now,
      );
      await taskNotifier.addTask(initialTask);

      final updateCmd = updateParser.parse(text: 'reschedule my Microsoft interview to 2pm', now: now);
      final activeTasks = container.read(taskNotifierProvider);

      final result = await executor.update(ref: container, command: updateCmd, activeTasks: activeTasks);

      expect(result.success, isTrue);
      final updated = (await testDb.select(testDb.tasks).get()).firstWhere((t) => t.id == 'interview-1');
      expect(updated.dueAt, DateTime(2026, 8, 15, 14, 0));
    });

    test('C. Change priority: "make the interview high priority" updates only priority', () async {
      final taskNotifier = container.read(taskNotifierProvider.notifier);
      final initialTask = Task(
        id: 'interview-2',
        title: 'Tech Interview',
        dueDate: DateTime(2026, 8, 17, 11, 0),
        priority: 'medium',
        status: 'active',
        createdAt: now,
      );
      await taskNotifier.addTask(initialTask);

      final updateCmd = updateParser.parse(text: 'make the interview high priority', now: now);
      final activeTasks = container.read(taskNotifierProvider);

      final result = await executor.update(ref: container, command: updateCmd, activeTasks: activeTasks);

      expect(result.success, isTrue);
      final updated = (await testDb.select(testDb.tasks).get()).firstWhere((t) => t.id == 'interview-2');
      expect(updated.priority, 'high');
      expect(updated.title, 'Tech Interview');
      expect(updated.dueAt, DateTime(2026, 8, 17, 11, 0));
    });

    test('D. Rename: "rename my exam to physics exam" updates title and reminder title', () async {
      final taskNotifier = container.read(taskNotifierProvider.notifier);
      final reminderService = container.read(reminderServiceProvider);

      final initialTask = Task(
        id: 'exam-2',
        title: 'Exam',
        dueDate: DateTime(2026, 8, 18, 10, 0),
        priority: 'medium',
        status: 'active',
        createdAt: now,
      );
      await taskNotifier.addTask(initialTask);
      await reminderService.scheduleReminder(
        taskId: initialTask.id,
        taskTitle: initialTask.title,
        scheduledAt: initialTask.dueDate!,
      );

      final updateCmd = updateParser.parse(text: 'rename my exam to physics exam', now: now);
      final activeTasks = container.read(taskNotifierProvider);

      final result = await executor.update(ref: container, command: updateCmd, activeTasks: activeTasks);

      expect(result.success, isTrue);
      final updated = (await testDb.select(testDb.tasks).get()).firstWhere((t) => t.id == 'exam-2');
      expect(updated.title, 'Physics Exam');
    });

    test('E. Ambiguous target: Physics Exam + Maths Exam -> confirmation, ZERO writes', () async {
      final taskNotifier = container.read(taskNotifierProvider.notifier);
      await taskNotifier.addTask(Task(
        id: 'exam-phy',
        title: 'Physics Exam',
        dueDate: DateTime(2026, 8, 18, 10, 0),
        status: 'active',
        createdAt: now,
      ));
      await taskNotifier.addTask(Task(
        id: 'exam-math',
        title: 'Maths Exam',
        dueDate: DateTime(2026, 8, 19, 10, 0),
        status: 'active',
        createdAt: now,
      ));

      final updateCmd = updateParser.parse(text: 'move my exam to tomorrow at 7pm', now: now);
      final activeTasks = container.read(taskNotifierProvider);

      final result = await executor.update(ref: container, command: updateCmd, activeTasks: activeTasks);

      expect(result.success, isFalse);
      expect(result.requiresConfirmation, isTrue);
      expect(result.confirmationReason, 'ambiguous_task');
      expect(result.candidateTitles, contains('Physics Exam'));
      expect(result.candidateTitles, contains('Maths Exam'));

      // Invariant: ZERO database mutations
      final tasksInDb = await testDb.select(testDb.tasks).get();
      final phy = tasksInDb.firstWhere((t) => t.id == 'exam-phy');
      expect(phy.dueAt, DateTime(2026, 8, 18, 10, 0));
    });

    test('F. Not found: "move my quantum homework to tomorrow" -> info/confirmation, ZERO writes', () async {
      final updateCmd = updateParser.parse(text: 'move my quantum homework to tomorrow at 7pm', now: now);
      final activeTasks = container.read(taskNotifierProvider);

      final result = await executor.update(ref: container, command: updateCmd, activeTasks: activeTasks);

      expect(result.success, isFalse);
      expect(result.requiresConfirmation, isTrue);
      expect(result.confirmationReason, 'task_not_found');
    });

    test('G. Missing destination: "move my exam" -> confirmation, ZERO writes', () async {
      final updateCmd = updateParser.parse(text: 'move my exam', now: now);
      final activeTasks = container.read(taskNotifierProvider);

      final result = await executor.update(ref: container, command: updateCmd, activeTasks: activeTasks);

      expect(result.success, isFalse);
      expect(result.requiresConfirmation, isTrue);
    });

    test('H. Ambiguous time: "move my exam to tomorrow by 5" -> confirmation, ZERO writes', () async {
      final updateCmd = updateParser.parse(text: 'move my exam to tomorrow by 5', now: now);
      final activeTasks = container.read(taskNotifierProvider);

      final result = await executor.update(ref: container, command: updateCmd, activeTasks: activeTasks);

      expect(result.success, isFalse);
      expect(result.requiresConfirmation, isTrue);
    });

    test('I. Recurring task update: moving recurring task preserves recurrenceRule', () async {
      final taskNotifier = container.read(taskNotifierProvider.notifier);
      final initialTask = Task(
        id: 'recurring-task-1',
        title: 'Morning Yoga',
        dueDate: DateTime(2026, 8, 16, 7, 0),
        status: 'active',
        recurrenceRule: const RecurrenceRule(frequency: RecurrenceFrequency.daily, hour: 7, minute: 0),
        createdAt: now,
      );
      await taskNotifier.addTask(initialTask);

      final updateCmd = updateParser.parse(text: 'move my Morning Yoga to tomorrow at 8am', now: now);
      final activeTasks = container.read(taskNotifierProvider);

      final result = await executor.update(ref: container, command: updateCmd, activeTasks: activeTasks);

      expect(result.success, isTrue);
      final updated = (await testDb.select(testDb.tasks).get()).firstWhere((t) => t.id == 'recurring-task-1');
      expect(updated.dueAt, DateTime(2026, 8, 16, 8, 0));
      expect(updated.recurrenceRuleJson, isNotNull);
      expect(updated.recurrenceRuleJson, contains('DAILY'));
    });

    test('J. Non-due update: priority change leaves existing reminder unchanged', () async {
      final taskNotifier = container.read(taskNotifierProvider.notifier);
      final reminderService = container.read(reminderServiceProvider);

      final initialTask = Task(
        id: 'task-pri-1',
        title: 'Project Submission',
        dueDate: DateTime(2026, 8, 25, 17, 0),
        priority: 'medium',
        status: 'active',
        createdAt: now,
      );
      await taskNotifier.addTask(initialTask);
      await reminderService.scheduleReminder(
        taskId: initialTask.id,
        taskTitle: initialTask.title,
        scheduledAt: initialTask.dueDate!,
      );

      final updateCmd = updateParser.parse(text: 'make Project Submission urgent priority', now: now);
      final activeTasks = container.read(taskNotifierProvider);

      final result = await executor.update(ref: container, command: updateCmd, activeTasks: activeTasks);

      expect(result.success, isTrue);
      final reminders = await testDb.select(testDb.reminders).get();
      final activeRem = reminders.where((r) => r.taskId == 'task-pri-1' && r.status != 'cancelled').first;
      expect(activeRem.scheduledAt, DateTime(2026, 8, 25, 17, 0));
    });

    test('K. Field preservation: all metadata fields are preserved intact', () async {
      final taskNotifier = container.read(taskNotifierProvider.notifier);

      final initialTask = Task(
        id: 'full-task-1',
        title: 'Original Title',
        description: 'Important description',
        status: 'active',
        order: 5,
        priority: 'low',
        source: 'assistant',
        sourceId: 'src-123',
        category: 'work',
        organization: 'Acme Corp',
        createdAt: DateTime(2026, 8, 1, 10, 0),
        dueDate: DateTime(2026, 8, 20, 10, 0),
        subtasks: [SubTask(id: 's1', name: 'Step 1', isCompleted: false)],
      );
      await taskNotifier.addTask(initialTask);

      final updateCmd = updateParser.parse(text: 'rename my Original Title to New Title', now: now);
      final activeTasks = container.read(taskNotifierProvider);

      final result = await executor.update(ref: container, command: updateCmd, activeTasks: activeTasks);

      expect(result.success, isTrue);
      final updated = (await testDb.select(testDb.tasks).get()).firstWhere((t) => t.id == 'full-task-1');

      expect(updated.id, 'full-task-1');
      expect(updated.title, 'New Title');
      expect(updated.description, 'Important description');
      expect(updated.status, 'active');
      expect(updated.order, 5);
      expect(updated.priority, 'low');
      expect(updated.source, 'assistant');
      expect(updated.sourceId, 'src-123');
      expect(updated.category, 'work');
      expect(updated.organization, 'Acme Corp');
      expect(updated.createdAt, DateTime(2026, 8, 1, 10, 0));
      expect(updated.subtasksJson, contains('Step 1'));
    });
  });
}

