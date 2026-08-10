import 'dart:async';
import 'package:drift/drift.dart';
import '../../../../core/database/database.dart';
import '../../../../services/notification_service.dart';
import '../../../tasks/domain/entities/task.dart';
import '../../data/services/calendar_sync_service.dart';
import '../../data/services/gemini_context_extractor.dart';
import '../../data/services/gmail_sync_service.dart';
import '../../data/services/google_auth_service.dart';

/// Summary result after running sync operation.
class SchedulerSyncResult {
  final int totalSynced;
  final int applicationsFound;
  final int examsFound;
  final int calendarEventsFound;
  final String? errorMessage;

  SchedulerSyncResult({
    this.totalSynced = 0,
    this.applicationsFound = 0,
    this.examsFound = 0,
    this.calendarEventsFound = 0,
    this.errorMessage,
  });

  bool get isSuccess => errorMessage == null;
}

/// Orchestrates Gmail and Calendar sync, AI context extraction via Gemini,
/// saving into SQLite database and scheduling context-rich notifications.
class AiLifeSchedulerService {
  final AppDatabase database;
  final GoogleAuthService authService;
  final GmailSyncService gmailService;
  final CalendarSyncService calendarService;
  final GeminiContextExtractor contextExtractor;

  AiLifeSchedulerService({
    required this.database,
    GoogleAuthService? authService,
    GmailSyncService? gmailService,
    CalendarSyncService? calendarService,
    GeminiContextExtractor? contextExtractor,
  })  : authService = authService ?? GoogleAuthService.instance,
        gmailService = gmailService ?? GmailSyncService(),
        calendarService = calendarService ?? CalendarSyncService(),
        contextExtractor = contextExtractor ?? GeminiContextExtractor();

  /// Executes full sync from Gmail and Google Calendar.
  Future<SchedulerSyncResult> syncAll() async {
    final client = await authService.getAuthenticatedClient();
    if (client == null) {
      return SchedulerSyncResult(
        errorMessage: 'User is not signed in to Google',
      );
    }

    int totalSynced = 0;
    int applicationsFound = 0;
    int examsFound = 0;
    int calendarEventsFound = 0;

    try {
      // 1. Sync Emails
      final emails = await gmailService.fetchRelevantEmails(client);
      for (final email in emails) {
        final extracted = await contextExtractor.extractFromEmail(
          emailSubject: email.subject,
          emailSender: email.sender,
          emailBody: email.bodyText,
          messageId: 'gmail_${email.id}',
        );

        if (extracted.isTask) {
          await _saveExtractedTask(extracted);
          totalSynced++;
          if (extracted.taskType == TaskType.application) {
            applicationsFound++;
          } else {
            examsFound++;
          }
        }
      }

      // 2. Sync Calendar Events
      final calendarEvents = await calendarService.fetchUpcomingEvents(client);
      for (final event in calendarEvents) {
        final extracted = await contextExtractor.extractFromCalendar(
          eventTitle: event.title,
          description: event.description,
          location: event.location,
          startTime: event.startTime,
          eventId: 'cal_${event.id}',
          htmlLink: event.htmlLink,
        );

        await _saveExtractedTask(extracted);
        totalSynced++;
        calendarEventsFound++;
      }

      return SchedulerSyncResult(
        totalSynced: totalSynced,
        applicationsFound: applicationsFound,
        examsFound: examsFound,
        calendarEventsFound: calendarEventsFound,
      );
    } catch (e) {
      return SchedulerSyncResult(
        errorMessage: 'Sync error: $e',
      );
    }
  }

  /// Persists task entity & context in SQLite and schedules reminder notification.
  Future<void> _saveExtractedTask(ExtractedTaskWithContext extracted) async {
    final now = DateTime.now();
    final taskId = extracted.context.taskId;

    // 1. Save Task row
    await database.into(database.tasks).insertOnConflictUpdate(
      TasksCompanion.insert(
        id: taskId,
        title: extracted.title,
        description: Value(extracted.description),
        taskType: extracted.taskType.value,
        priority: extracted.priority.value,
        status: TaskStatus.pending.value,
        dueAt: Value(extracted.dueAt),
        createdAt: now,
        updatedAt: now,
      ),
    );

    // 2. Save TaskContext row
    final ctx = extracted.context;
    await database.saveTaskContext(
      TaskContextsCompanion.insert(
        taskId: taskId,
        companyName: Value(ctx.companyName),
        role: Value(ctx.role),
        requirements: Value(ctx.requirements),
        applicationLink: Value(ctx.applicationLink),
        emailSnippet: Value(ctx.emailSnippet),
        fullEmail: Value(ctx.fullEmail),
        hasApplied: Value(ctx.hasApplied),
        appliedAt: Value(ctx.appliedAt),
        eventType: Value(ctx.eventType),
        location: Value(ctx.location),
        stipend: Value(ctx.stipend),
        actionItems: Value(ctx.actionItems),
        source: Value(ctx.source),
      ),
    );

    // 3. Schedule context-rich notification if dueAt is set
    if (extracted.dueAt != null && extracted.dueAt!.isAfter(now)) {
      final daysLeft = extracted.dueAt!.difference(now).inDays;
      String notificationBody = extracted.context.companyName != null
          ? '${extracted.context.companyName} (${extracted.context.role ?? "Application"}) due in $daysLeft days'
          : '${extracted.title} due in $daysLeft days';

      await NotificationService.scheduleNotification(
        id: taskId.hashCode.abs(),
        title: '⚠️ ${extracted.title}',
        body: notificationBody,
        scheduledTime: extracted.dueAt!.subtract(const Duration(hours: 24)),
      );
    }
  }
}
