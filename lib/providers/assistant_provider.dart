import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'dart:math' as math;
import '../features/scheduler/data/services/calendar_sync_service.dart';
import '../features/scheduler/data/services/gmail_sync_service.dart';
import '../features/scheduler/data/services/google_auth_service.dart';
import '../features/scheduler/domain/services/ai_life_scheduler_service.dart';
import '../models/task.dart';
import 'ritual_provider.dart';
import 'task_provider.dart';
import '../services/panchang_service.dart';
import '../features/scheduler/data/services/gemini_chat_service.dart';
import '../core/parser/task_parser.dart';
import '../services/notification_service.dart';
import 'auth_provider.dart';

// ─── Service Providers ───────────────────────────────────────────────────────

final googleAuthServiceProvider = Provider<GoogleAuthService>((ref) {
  return GoogleAuthService.instance;
});

final gmailSyncServiceProvider = Provider<GmailSyncService>((ref) {
  return GmailSyncService();
});

final calendarSyncServiceProvider = Provider<CalendarSyncService>((ref) {
  return CalendarSyncService();
});

final geminiChatServiceProvider = Provider<GeminiChatService>((ref) {
  return GeminiChatService();
});

final aiLifeSchedulerServiceProvider = Provider<AiLifeSchedulerService>((ref) {
  return AiLifeSchedulerService(
    database: ref.read(databaseProvider),
    authService: ref.read(googleAuthServiceProvider),
    gmailService: ref.read(gmailSyncServiceProvider),
    calendarService: ref.read(calendarSyncServiceProvider),
  );
});

// ─── State ───────────────────────────────────────────────────────────────────

enum AssistantMessageType { text, emailSummary, calendarSummary, syncResult, info, success, error, auth }

class AssistantMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final AssistantMessageType messageType;
  final List<GmailMessageData>? emails;
  final List<CalendarEventData>? calendarEvents;
  final SchedulerSyncResult? syncResult;

  AssistantMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.messageType = AssistantMessageType.text,
    this.emails,
    this.calendarEvents,
    this.syncResult,
  });
}

class AssistantState {
  final List<AssistantMessage> messages;
  final bool isLoading;
  final bool isAuthenticated;
  final String? userEmail;
  final String? error;

  const AssistantState({
    this.messages = const [],
    this.isLoading = false,
    this.isAuthenticated = false,
    this.userEmail,
    this.error,
  });

  AssistantState copyWith({
    List<AssistantMessage>? messages,
    bool? isLoading,
    bool? isAuthenticated,
    String? userEmail,
    bool clearUserEmail = false,
    String? error,
  }) {
    return AssistantState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userEmail: clearUserEmail ? null : (userEmail ?? this.userEmail),
      error: error ?? this.error,
    );
  }
}

// ─── Intent Detection Regexes ────────────────────────────────────────────────

/// Returns the first matching [_Intent] for [input], or null for general chat.
_Intent? _detectIntent(String lower) {
  // ── Task creation / reminders (highest priority) ──────────────────────────
  if (RegExp(
    r'\b(remind\s+me|create\s+task|add\s+task|new\s+task|set\s+reminder|reminder|todo|to-do|schedule.*task)\b',
    caseSensitive: false,
  ).hasMatch(lower)) {
    return _Intent.createTask;
  }

  // ── Standalone "remind" at the start ─────────────────────────────────────
  if (RegExp(r'^remind\b', caseSensitive: false).hasMatch(lower)) {
    return _Intent.createTask;
  }

  // ── Sign out (check before sign in to avoid false positive) ──────────────
  if (RegExp(r'\b(sign\s+out|logout|log\s+out)\b', caseSensitive: false).hasMatch(lower)) {
    return _Intent.signOut;
  }

  // ── Sign in ───────────────────────────────────────────────────────────────
  if (RegExp(r'\b(sign\s+in|login|connect\s+google|google\s+sign)\b', caseSensitive: false)
      .hasMatch(lower)) {
    return _Intent.signIn;
  }

  // ── Email sync ────────────────────────────────────────────────────────────
  if (RegExp(
    r'\b(sync|fetch|check|get|read|show|scan)\s+(my\s+)?(email|emails|gmail|inbox|mail|mails)\b',
    caseSensitive: false,
  ).hasMatch(lower)) {
    return _Intent.syncEmails;
  }

  if (RegExp(r'\b(last|latest|newest|recent)\s+(mail|email|message)\b', caseSensitive: false)
      .hasMatch(lower)) {
    return _Intent.latestEmail;
  }

  // ── Calendar ──────────────────────────────────────────────────────────────
  if (RegExp(
    r'\b(sync|fetch|check|get)\s+(my\s+)?(calendar|events|meetings|schedule)\b',
    caseSensitive: false,
  ).hasMatch(lower)) {
    return _Intent.syncCalendar;
  }

  if (RegExp(
    r'\b(today.*meeting|today.*calendar|what.*calendar|next\s+meeting|upcoming\s+meeting)\b',
    caseSensitive: false,
  ).hasMatch(lower)) {
    return _Intent.todayCalendar;
  }

  // ── Full sync ─────────────────────────────────────────────────────────────
  if (RegExp(r'\b(sync|refresh|update)\s+(all|everything|life)\b', caseSensitive: false)
          .hasMatch(lower) ||
      RegExp(r'\b(life\s+sync|full\s+sync)\b', caseSensitive: false).hasMatch(lower)) {
    return _Intent.fullSync;
  }

  // ── Panchang ─────────────────────────────────────────────────────────────
  if (RegExp(
    r'\b(panchang|ekadashi|amavasya|purnima|chaturdashi|shivaratri|tithi)\b',
    caseSensitive: false,
  ).hasMatch(lower)) {
    return _Intent.panchang;
  }

  // ── Task completion ───────────────────────────────────────────────────────
  if (RegExp(
    r'\b(complete|done|finish|mark\s+as\s+done|tick\s+off)\s*(task|todo|reminder)?\b',
    caseSensitive: false,
  ).hasMatch(lower)) {
    return _Intent.completeTask;
  }

  // ── List tasks ────────────────────────────────────────────────────────────
  if (RegExp(
        r'\b(list|show|view|get|display|what\s+are)\s*(my\s*)?(task|tasks|todo|todos|reminder|reminders|schedule|agenda)\b',
        caseSensitive: false,
      ).hasMatch(lower) ||
      RegExp(
        r"\b(my\s+tasks|what'?s?\s+next|coming\s+up|pending\s+tasks)\b",
        caseSensitive: false,
      ).hasMatch(lower)) {
    return _Intent.listTasks;
  }

  // ── Time query ────────────────────────────────────────────────────────────
  if (RegExp(
    r"\b(what'?s?\s+the\s+time|what\s+time\s+is\s+it|current\s+time|time\s+now|tell\s+me\s+the\s+time)\b",
    caseSensitive: false,
  ).hasMatch(lower)) {
    return _Intent.currentTime;
  }

  // ── Date query ────────────────────────────────────────────────────────────
  if (RegExp(
    r"\b(what'?s?\s+today'?s?\s+date|what\s+day\s+is|today'?s?\s+date)\b",
    caseSensitive: false,
  ).hasMatch(lower)) {
    return _Intent.currentDate;
  }

  return null; // → falls through to general Gemini chat
}

enum _Intent {
  createTask,
  signIn,
  signOut,
  syncEmails,
  latestEmail,
  syncCalendar,
  todayCalendar,
  fullSync,
  panchang,
  completeTask,
  listTasks,
  currentTime,
  currentDate,
}

// ─── Notifier ────────────────────────────────────────────────────────────────

class AssistantNotifier extends StateNotifier<AssistantState> {
  final Ref ref;

  AssistantNotifier(this.ref) : super(const AssistantState()) {
    checkInitialAuth();
  }

  Future<void> checkInitialAuth() async {
    final auth = ref.read(googleAuthServiceProvider);
    final user = await auth.signInSilently();
    if (user != null) {
      state = state.copyWith(
        isAuthenticated: true,
        userEmail: user.email,
      );
    }
  }

  void addMessage(
    String text, {
    bool isUser = false,
    AssistantMessageType type = AssistantMessageType.text,
    List<GmailMessageData>? emails,
    List<CalendarEventData>? calendarEvents,
    SchedulerSyncResult? syncResult,
  }) {
    final newMsg = AssistantMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: isUser,
      timestamp: DateTime.now(),
      messageType: type,
      emails: emails,
      calendarEvents: calendarEvents,
      syncResult: syncResult,
    );

    state = state.copyWith(
      messages: [...state.messages, newMsg],
      isLoading: false,
    );
  }

  void clearMessages() {
    state = state.copyWith(messages: []);
  }

  // ─── Command Router ────────────────────────────────────────────────────────

  Future<void> sendCommand(String input) async {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return;

    // Normalize: strip trailing punctuation for intent matching only
    final lower = trimmed.toLowerCase().replaceAll(RegExp(r'[?.!]+$'), '').trim();

    // Add user message
    addMessage(trimmed, isUser: true);
    state = state.copyWith(isLoading: true, error: null);

    try {
      final intent = _detectIntent(lower);

      switch (intent) {
        case _Intent.createTask:
          await handleCreateTask(trimmed);

        case _Intent.signIn:
          await handleSignIn();

        case _Intent.signOut:
          await handleSignOut();

        case _Intent.syncEmails:
          await handleSyncEmails();

        case _Intent.latestEmail:
          await handleLatestInboxEmail();

        case _Intent.syncCalendar:
          await handleSyncCalendar();

        case _Intent.todayCalendar:
          await handleTodayCalendar();

        case _Intent.fullSync:
          await handleFullSync();

        case _Intent.panchang:
          handlePanchangQuery();

        case _Intent.completeTask:
          await handleCompleteTask(trimmed);

        case _Intent.listTasks:
          await handleListTasks();

        case _Intent.currentTime:
          _handleCurrentTime();

        case _Intent.currentDate:
          _handleCurrentDate();

        case null:
          // Fallback: Gemini conversational chat
          await _handleGeneralChat(trimmed);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      addMessage(
        '⚠️ Something went wrong: ${_friendlyError(e)}',
        type: AssistantMessageType.error,
      );
    }
  }

  // ─── Instant Handlers (no async needed) ──────────────────────────────────

  void _handleCurrentTime() {
    final now = DateTime.now().toLocal();
    final timeStr = DateFormat('h:mm a').format(now);
    final dateStr = DateFormat('EEEE, MMMM d, yyyy').format(now);
    addMessage(
      '🕐 Current time: **$timeStr** IST\n📅 $dateStr',
      type: AssistantMessageType.info,
    );
  }

  void _handleCurrentDate() {
    final now = DateTime.now().toLocal();
    addMessage(
      '📅 Today is **${DateFormat('EEEE, MMMM d, yyyy').format(now)}**.',
      type: AssistantMessageType.info,
    );
  }

  // ─── Handlers ──────────────────────────────────────────────────────────────

  Future<void> handleSignIn() async {
    final auth = ref.read(googleAuthServiceProvider);
    if (auth.isSignedIn) {
      state = state.copyWith(isAuthenticated: true, userEmail: auth.currentUser?.email);
      addMessage(
        '✅ Already signed in as ${auth.currentUser?.email ?? "Google User"}.\n\nTry "Sync emails" or "Sync calendar"!',
        type: AssistantMessageType.success,
      );
      return;
    }

    try {
      final user = await auth.signIn();
      if (user != null) {
        state = state.copyWith(
          isAuthenticated: true,
          userEmail: user.email,
        );
        addMessage(
          '✅ Signed in as ${user.email}!\n\n'
          'Now you can:\n'
          '• "Sync emails" – Scan Gmail for application/exam tasks\n'
          '• "Sync calendar" – Fetch upcoming Google Calendar events\n'
          '• "Sync all" – Perform complete life sync',
          type: AssistantMessageType.success,
        );
      } else {
        addMessage(
          'Sign-in was cancelled. You can sign in anytime.',
          type: AssistantMessageType.info,
        );
      }
    } catch (e) {
      addMessage(
        '⚠️ Google Sign-In failed: ${_friendlyError(e)}',
        type: AssistantMessageType.error,
      );
    }
  }

  Future<void> handleSignOut() async {
    final auth = ref.read(googleAuthServiceProvider);
    await auth.signOut();
    await ref.read(authProvider.notifier).signOut();
    state = state.copyWith(isAuthenticated: false, clearUserEmail: true);
    addMessage(
      'Signed out of Google account. Local tasks remain saved.',
      type: AssistantMessageType.info,
    );
  }

  Future<void> handleSyncEmails() async {
    final auth = ref.read(googleAuthServiceProvider);
    final client = await auth.getAuthenticatedClient();

    if (client == null) {
      addMessage(
        '🔐 Google permissions needed. Tap "Sign In" below or type "Sign in" to connect.',
        type: AssistantMessageType.auth,
      );
      return;
    }

    final gmail = ref.read(gmailSyncServiceProvider);
    final emails = await gmail.fetchRelevantEmails(client, maxResults: 10);

    if (emails.isEmpty) {
      addMessage(
        '📭 No task-relevant emails found in your inbox.',
        type: AssistantMessageType.info,
      );
      return;
    }

    addMessage(
      '📧 Found ${emails.length} relevant email${emails.length > 1 ? "s" : ""}:',
      type: AssistantMessageType.emailSummary,
      emails: emails,
    );
  }

  Future<void> handleLatestInboxEmail() async {
    final auth = ref.read(googleAuthServiceProvider);
    final client = await auth.getAuthenticatedClient();
    if (client == null) {
      addMessage('Please sign in with Google first so I can read your inbox.',
          type: AssistantMessageType.auth);
      return;
    }

    final email = await ref.read(gmailSyncServiceProvider).fetchLatestInboxEmail(client);
    if (email == null) {
      addMessage('Your inbox does not have a readable recent message.',
          type: AssistantMessageType.info);
      return;
    }
    addMessage(
      'Latest inbox email\n\nFrom: ${email.sender}\nSubject: ${email.subject}\nReceived: ${DateFormat('MMM d, h:mm a').format(email.date)}\n\n${email.snippet.isEmpty ? email.bodyText : email.snippet}',
      type: AssistantMessageType.emailSummary,
      emails: [email],
    );
  }

  Future<void> handleSyncCalendar() async {
    final auth = ref.read(googleAuthServiceProvider);
    final client = await auth.getAuthenticatedClient();

    if (client == null) {
      addMessage(
        '🔐 Google permissions needed. Tap "Sign In" to connect Google Calendar.',
        type: AssistantMessageType.auth,
      );
      return;
    }

    final calendar = ref.read(calendarSyncServiceProvider);
    final events = await calendar.fetchUpcomingEvents(client, daysAhead: 14);

    if (events.isEmpty) {
      addMessage(
        '📅 No upcoming calendar events found in the next 14 days.',
        type: AssistantMessageType.info,
      );
      return;
    }

    addMessage(
      '📅 Found ${events.length} upcoming calendar event${events.length > 1 ? "s" : ""}:',
      type: AssistantMessageType.calendarSummary,
      calendarEvents: events,
    );
  }

  Future<void> handleTodayCalendar() async {
    final auth = ref.read(googleAuthServiceProvider);
    final client = await auth.getAuthenticatedClient();
    if (client == null) {
      addMessage('Please sign in with Google first so I can check your calendar.',
          type: AssistantMessageType.auth);
      return;
    }
    final events =
        await ref.read(calendarSyncServiceProvider).fetchUpcomingEvents(client, daysAhead: 1);
    if (events.isEmpty) {
      addMessage('Your calendar is clear for the next day.', type: AssistantMessageType.info);
      return;
    }
    addMessage('Here is what is coming up next:',
        type: AssistantMessageType.calendarSummary, calendarEvents: events);
  }

  void handlePanchangQuery() {
    final events = PanchangService.getUpcomingEvents(months: 3);
    if (events.isEmpty) {
      addMessage('Panchang events are unavailable right now.', type: AssistantMessageType.info);
      return;
    }
    final lines = events
        .take(6)
        .map((event) =>
            '${event.displayName} — ${DateFormat('EEE, d MMM').format(event.eventDate)}\n${event.description}')
        .join('\n\n');
    addMessage('Upcoming Panchang\n\n$lines', type: AssistantMessageType.info);
  }

  Future<void> handleFullSync() async {
    final auth = ref.read(googleAuthServiceProvider);
    if (!auth.isSignedIn) {
      final client = await auth.getAuthenticatedClient();
      if (client == null) {
        addMessage(
          '🔐 Please type "Sign in" or tap Sign In above to authorize Google access.',
          type: AssistantMessageType.auth,
        );
        return;
      }
    }

    final scheduler = ref.read(aiLifeSchedulerServiceProvider);
    final result = await scheduler.syncAll();

    if (!result.isSuccess) {
      addMessage(
        '⚠️ Sync error: ${result.errorMessage}',
        type: AssistantMessageType.error,
      );
      return;
    }

    await _syncDbTasksToNotifier();

    addMessage(
      '✅ Life Sync Complete!\n\n'
      '• ${result.totalSynced} items processed\n'
      '• ${result.applicationsFound} job/internship applications\n'
      '• ${result.examsFound} exams/deadlines\n'
      '• ${result.calendarEventsFound} calendar events',
      type: AssistantMessageType.syncResult,
      syncResult: result,
    );
  }

  Future<void> _syncDbTasksToNotifier() async {
    final taskNotifier = ref.read(taskNotifierProvider.notifier);
    await taskNotifier.loadTasks();
    ref.invalidate(taskListProvider);
  }

  Future<void> handleCreateTask(String input) async {
    try {
      final parsed = TaskParser.parse(input);

      if (parsed.title.isEmpty || parsed.title.length < 2) {
        addMessage(
          '🤔 I didn\'t catch the task name. Try:\n"Remind me to call John at 5pm"',
          type: AssistantMessageType.info,
        );
        return;
      }

      final task = Task(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: parsed.title,
        description: parsed.taskDescription,
        dueDate: parsed.remindAt,
        priority: parsed.priority,
        status: parsed.remindAt != null ? 'active' : 'pending',
        subtasks: parsed.subtasks,
        organization: parsed.organization,
        source: 'assistant',
        createdAt: DateTime.now(),
      );

      await ref.read(taskNotifierProvider.notifier).addTask(task);
      ref.invalidate(taskListProvider);

      // Schedule notification if a reminder time was detected and is in future
      bool notifScheduled = false;
      if (parsed.remindAt != null) {
        try {
          final ist = tz.getLocation('Asia/Kolkata');
          final istNow = tz.TZDateTime.now(ist);
          final scheduledIst = tz.TZDateTime.from(parsed.remindAt!, ist);

          if (scheduledIst.isBefore(istNow)) {
            // Time already passed
            notifScheduled = false;
          } else {
            notifScheduled = await NotificationService.scheduleNotification(
              id: task.id.hashCode,
              title: '⏰ Reminder: ${task.title}',
              body: 'Time for your task: ${task.title}',
              scheduledTime: parsed.remindAt!,
              payload: task.id,
            );
          }
        } catch (_) {
          notifScheduled = false;
        }
      }

      // Build rich FAANG-level response
      final buf = StringBuffer('✅ Task created: **"${task.title}"**\n');
      if (parsed.remindAt != null) {
        buf.write('⏰ Reminder: ${parsed.formattedReminder}\n');
      }
      if (parsed.organization != null) {
        buf.write('🏢 Organization: ${parsed.organization}\n');
      }
      if (parsed.subtasks.isNotEmpty) {
        buf.write('📋 Subtasks:\n');
        for (final sub in parsed.subtasks) {
          buf.write('  • ${sub.name}\n');
        }
      }
      buf.write('📊 Priority: ${task.priority.toUpperCase()}\n');
      buf.write('📌 Status: ${task.status.emoji} ${task.status.displayName}');

      if (parsed.remindAt != null && !notifScheduled) {
        buf.write('\n⚠️ Note: Reminder set in past or notification permission missing.');
      }

      addMessage(buf.toString(), type: AssistantMessageType.success);
    } catch (e) {
      addMessage(
        '⚠️ Error creating task: ${_friendlyError(e)}',
        type: AssistantMessageType.error,
      );
    }
  }

  Future<void> handleCompleteTask(String input) async {
    final tasks = ref.read(taskNotifierProvider);
    final pending = tasks.where((t) => !t.isCompleted).toList();

    if (pending.isEmpty) {
      addMessage('🎉 No pending tasks to complete!', type: AssistantMessageType.info);
      return;
    }

    String? query;
    final match =
        RegExp(r'(?:complete|done|finish|mark)\s+(.+)$', caseSensitive: false).firstMatch(input);
    if (match != null) {
      query = match.group(1)?.trim().toLowerCase();
    }

    Task target = pending.first;
    if (query != null && query.isNotEmpty) {
      target = pending.firstWhere(
        (t) => t.title.toLowerCase().contains(query!),
        orElse: () => pending.first,
      );
    }

    await ref.read(taskNotifierProvider.notifier).toggleComplete(target.id);
    ref.invalidate(taskListProvider);
    await NotificationService.cancelNotification(target.id.hashCode);

    addMessage(
      '✅ Marked **"${target.title}"** as complete!',
      type: AssistantMessageType.success,
    );
  }

  Future<void> handleListTasks() async {
    final tasks = ref.read(taskNotifierProvider);
    final pending = tasks.where((t) => !t.isCompleted).toList();

    if (pending.isEmpty) {
      addMessage('📭 No pending tasks. Your schedule is clear!', type: AssistantMessageType.info);
      return;
    }

    final buf = StringBuffer('📋 Your pending tasks (${pending.length}):\n\n');
    for (var i = 0; i < pending.length && i < 8; i++) {
      final t = pending[i];
      buf.write('${i + 1}. ${t.title}');
      if (t.priority == 'high') buf.write(' 🔴 HIGH');
      if (t.priority == 'low') buf.write(' 🟢 LOW');
      if (t.dueDate != null) {
        buf.write('\n   📅 Due: ${DateFormat("MMM d, h:mm a").format(t.dueDate!)}');
      }
      buf.write('\n\n');
    }
    if (pending.length > 8) {
      buf.write('... and ${pending.length - 8} more.');
    }
    addMessage(buf.toString(), type: AssistantMessageType.info);
  }

  // ─── General Chat Fallback (Gemini) ──────────────────────────────────────

  Future<void> _handleGeneralChat(String message) async {
    final chatService = ref.read(geminiChatServiceProvider);
    final tasks = ref.read(taskNotifierProvider);

    // Sliding window: last 10 messages EXCLUDING the one we just added
    final allMessages = state.messages;
    final historyMessages = allMessages.length > 1
        ? allMessages.sublist(0, allMessages.length - 1)
        : <AssistantMessage>[];
    final recentHistory = historyMessages
        .sublist(math.max(0, historyMessages.length - 10))
        .map((m) => {'role': m.isUser ? 'user' : 'model', 'text': m.text})
        .toList();

    final response = await chatService.chat(
      userMessage: message,
      history: recentHistory,
      pendingTasks: tasks.where((t) => !t.isCompleted).toList(),
      userEmail: state.userEmail,
    );
    addMessage(response, type: AssistantMessageType.text);
  }

  // ─── Error Formatting ─────────────────────────────────────────────────────

  String _friendlyError(Object e) {
    final str = e.toString().toLowerCase();
    if (str.contains('network') || str.contains('socket')) return 'Check internet connection.';
    if (str.contains('403') || str.contains('permission')) return 'Google permissions denied.';
    if (str.contains('401') || str.contains('unauthorized')) return 'Please sign in again.';
    return e.toString();
  }
}

// ─── Provider Declaration ────────────────────────────────────────────────────

final assistantStateProvider =
    StateNotifierProvider<AssistantNotifier, AssistantState>((ref) {
  return AssistantNotifier(ref);
});
