import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../features/scheduler/data/services/calendar_sync_service.dart';
import '../features/scheduler/data/services/gmail_sync_service.dart';
import '../features/scheduler/data/services/google_auth_service.dart';
import '../features/scheduler/domain/services/ai_life_scheduler_service.dart';
import '../models/task.dart';
import 'ritual_provider.dart';
import 'task_provider.dart';

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
    String? error,
  }) {
    return AssistantState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userEmail: userEmail ?? this.userEmail,
      error: error ?? this.error,
    );
  }
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

    // Add user message
    addMessage(trimmed, isUser: true);

    state = state.copyWith(isLoading: true, error: null);
    final lower = trimmed.toLowerCase();

    try {
      if (lower.contains('sign in') || lower.contains('login') || lower.contains('connect google')) {
        await handleSignIn();
        return;
      }

      if (lower.contains('sign out') || lower.contains('logout')) {
        await handleSignOut();
        return;
      }

      if (lower.contains('sync email') || lower.contains('check email') || lower.contains('scan email') || lower.contains('sync gmail')) {
        await handleSyncEmails();
        return;
      }

      if (lower.contains('sync calendar') || lower.contains('check calendar') || lower.contains('fetch calendar')) {
        await handleSyncCalendar();
        return;
      }

      if (lower.contains('sync all') || lower.contains('life sync') || lower.contains('full sync') || lower.contains('sync everything')) {
        await handleFullSync();
        return;
      }

      if (lower.contains('remind me') || lower.contains('create task') || lower.contains('add task')) {
        await handleCreateTask(trimmed);
        return;
      }

      if (lower.contains('complete') || lower.contains('done') || lower.contains('finish')) {
        await handleCompleteTask(trimmed);
        return;
      }

      if (lower.contains('list') || lower.contains('show') || lower.contains('my tasks') || lower.contains('what\'s next') || lower.contains('coming up')) {
        await handleListTasks();
        return;
      }

      // Default Help
      addMessage(
        '🤖 Here is what I can do:\n\n'
        '🔐 "Sign in" — Connect Google Account (Gmail & Calendar)\n'
        '📧 "Sync emails" — Scan inbox for task-relevant emails\n'
        '📅 "Sync calendar" — Fetch Google Calendar schedule\n'
        '🔄 "Sync all" — Perform full AI Life Sync\n'
        '✅ "Remind me to [task]" — Create new task\n'
        '📋 "List my tasks" — View pending tasks\n'
        '☑️ "Complete [task]" — Mark task as done',
        type: AssistantMessageType.info,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      addMessage(
        '⚠️ Something went wrong: ${_friendlyError(e)}',
        type: AssistantMessageType.error,
      );
    }
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
    state = state.copyWith(isAuthenticated: false, userEmail: null);
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

    // Mirror synced DB tasks to TaskNotifier so UI updates immediately
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
    final db = ref.read(databaseProvider);
    final dbTasks = await db.select(db.tasks).get();
    final taskNotifier = ref.read(taskNotifierProvider.notifier);

    for (final t in dbTasks) {
      final taskModel = Task(
        id: t.id,
        title: t.title,
        description: t.description,
        dueDate: t.dueAt,
        priority: t.priority,
        isCompleted: t.status == 'completed',
        createdAt: t.createdAt,
      );
      await taskNotifier.addTask(taskModel);
    }
    ref.invalidate(taskListProvider);
  }

  Future<void> handleCreateTask(String input) async {
    String title = input
        .replaceAll(RegExp(r'remind me to|create task|add task|please', caseSensitive: false), '')
        .trim();

    if (title.isEmpty) {
      addMessage('What would you like to be reminded about?', type: AssistantMessageType.info);
      return;
    }

    String priority = 'medium';
    if (input.contains('urgent') || input.contains('high') || input.contains('important')) {
      priority = 'high';
    } else if (input.contains('low')) {
      priority = 'low';
    }

    final task = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title[0].toUpperCase() + title.substring(1),
      description: 'Added via ASTRA Assistant',
      priority: priority,
      createdAt: DateTime.now(),
    );

    await ref.read(taskNotifierProvider.notifier).addTask(task);
    ref.invalidate(taskListProvider);

    addMessage(
      '✅ Task created: "${task.title}"\nPriority: ${priority.toUpperCase()}',
      type: AssistantMessageType.success,
    );
  }

  Future<void> handleCompleteTask(String input) async {
    final tasks = ref.read(taskNotifierProvider);
    final pending = tasks.where((t) => !t.isCompleted).toList();

    if (pending.isEmpty) {
      addMessage('🎉 No pending tasks to complete!', type: AssistantMessageType.info);
      return;
    }

    String? query;
    final match = RegExp(r'(?:complete|done|finish)\s*(.+)$', caseSensitive: false).firstMatch(input);
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

    addMessage(
      '✅ Marked "${target.title}" as complete!',
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

    String list = '📋 Your pending tasks (${pending.length}):\n\n';
    for (var i = 0; i < pending.length && i < 8; i++) {
      final t = pending[i];
      list += '${i + 1}. ${t.title}';
      if (t.priority == 'high') list += ' 🔴 HIGH';
      if (t.dueDate != null) {
        list += '\n   📅 Due: ${DateFormat("MMM d, h:mm a").format(t.dueDate!)}';
      }
      list += '\n\n';
    }
    if (pending.length > 8) {
      list += '... and ${pending.length - 8} more.';
    }
    addMessage(list, type: AssistantMessageType.info);
  }

  String _friendlyError(Object e) {
    final str = e.toString().toLowerCase();
    if (str.contains('network') || str.contains('socket')) return 'Check internet connection.';
    if (str.contains('403') || str.contains('permission')) return 'Google permissions denied.';
    return e.toString();
  }
}

// ─── Provider Declaration ────────────────────────────────────────────────────

final assistantStateProvider = StateNotifierProvider<AssistantNotifier, AssistantState>((ref) {
  return AssistantNotifier(ref);
});
