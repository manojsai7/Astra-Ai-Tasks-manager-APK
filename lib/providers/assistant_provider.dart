import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../features/scheduler/data/services/calendar_sync_service.dart';
import '../features/scheduler/data/services/gmail_sync_service.dart';
import '../features/scheduler/data/services/google_auth_service.dart';
import '../features/scheduler/domain/services/ai_life_scheduler_service.dart';
import '../models/task.dart';
import 'ritual_provider.dart';
import 'task_provider.dart';
import 'chat_session_provider.dart';
import '../services/panchang_service.dart';
import '../features/scheduler/data/services/gemini_chat_service.dart';
import '../core/parser/task_parser.dart';
import '../core/reminders/reminder.dart';
import '../core/commands/astra_command.dart';
import '../core/commands/astra_command_bus.dart';
import '../core/commands/astra_response.dart';
import '../core/commands/astra_response_builder.dart';
import 'reminder_provider.dart';
import 'auth_provider.dart';
import 'b1_classifier_provider.dart';
import '../services/ml/b1_event_classifier_client.dart';
import 'intent_classifier_provider.dart';
import 'astra_intent_resolver_provider.dart';
import '../services/assistant/astra_intent_resolver.dart';
import 'astra_routing_policy_provider.dart';
import 'astra_execution_gate_provider.dart';
import 'astra_command_executor_provider.dart';
import 'astra_semantic_engine_provider.dart';
import '../services/assistant/astra_command.dart' as semantic;
import '../services/assistant/astra_update_command.dart';

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
  final AstraResponse? structured;
  final List<GmailMessageData>? emails;
  final List<CalendarEventData>? calendarEvents;
  final SchedulerSyncResult? syncResult;

  AssistantMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.messageType = AssistantMessageType.text,
    this.structured,
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

// ─── Command Bus ─────────────────────────────────────────────────────────────

final astraCommandBusProvider = Provider<AstraCommandBus>((ref) => AstraCommandBus());

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
    AstraResponse? structured,
    List<GmailMessageData>? emails,
    List<CalendarEventData>? calendarEvents,
    SchedulerSyncResult? syncResult,
  }) {
    final displayText = structured?.toPlainText() ?? text;
    final newMsg = AssistantMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: displayText,
      isUser: isUser,
      timestamp: DateTime.now(),
      messageType: type,
      structured: structured,
      emails: emails,
      calendarEvents: calendarEvents,
      syncResult: syncResult,
    );

    state = state.copyWith(
      messages: [...state.messages, newMsg],
      isLoading: false,
    );

    final currentSessionId = ref.read(currentSessionIdProvider);
    if (currentSessionId != null) {
      ref.read(chatSessionProvider.notifier).addMessage(
        currentSessionId,
        isUser ? 'user' : 'assistant',
        displayText,
        messageType: type.name,
      );
    }
  }

  void addStructuredResponse(AstraResponse response, {AssistantMessageType? type}) {
    final msgType = type ?? _typeForResponse(response);
    addMessage(response.toPlainText(), type: msgType, structured: response);
  }

  AssistantMessageType _typeForResponse(AstraResponse response) => switch (response.type) {
        AstraResponseType.error => AssistantMessageType.error,
        AstraResponseType.auth => AssistantMessageType.auth,
        AstraResponseType.syncResult => AssistantMessageType.syncResult,
        AstraResponseType.emailSummary => AssistantMessageType.emailSummary,
        AstraResponseType.calendarSummary => AssistantMessageType.calendarSummary,
        AstraResponseType.taskCreated ||
        AstraResponseType.taskCompleted ||
        AstraResponseType.reminderCancelled ||
        AstraResponseType.reminderSnoozed ||
        AstraResponseType.success =>
          AssistantMessageType.success,
        AstraResponseType.info || AstraResponseType.taskList || AstraResponseType.taskQuery =>
          AssistantMessageType.info,
        _ => AssistantMessageType.text,
      };

  void clearMessages() {
    state = state.copyWith(messages: []);
  }

  void setMessages(List<AssistantMessage> messages) {
    state = state.copyWith(messages: messages, isLoading: false);
  }

  Future<void> loadSessionMessages(int sessionId) async {
    final dbMessages = await ref.read(chatSessionProvider.notifier).getMessages(sessionId);
    final mapped = dbMessages.map((m) {
      return AssistantMessage(
        id: m.id.toString(),
        text: m.content,
        isUser: m.role == 'user',
        timestamp: m.timestamp,
        messageType: m.messageType == 'error'
            ? AssistantMessageType.error
            : (m.messageType == 'success' ? AssistantMessageType.success : AssistantMessageType.text),
      );
    }).toList();
    state = state.copyWith(messages: mapped, isLoading: false);
  }

  Future<B1ClassificationResult?> _classifyWithB1(
    String text,
  ) async {
    try {
      return await ref
          .read(b1EventClassifierProvider)
          .classify(text);
    } catch (_) {
      return null;
    }
  }

  Future<semantic.AstraCommand?> _understandWithSemanticEngine(
    String text, {
    String intent = 'CREATE_TASK',
    bool requiresEventClassification = true,
  }) async {
    try {
      B1ClassificationResult? b1Result;
      if (requiresEventClassification) {
        b1Result = await _classifyWithB1(text);
      }

      final engine = ref.read(
        astraSemanticEngineProvider,
      );

      final now = ref.read(reminderServiceProvider).timeService.nowTZ();

      return engine.resolve(
        text: text,
        intent: intent,
        b1: b1Result,
        now: now,
      );
    } catch (_) {
      return null;
    }
  }

  Future<AstraResolvedIntent?> _resolveIntentWithSetA(
    String text,
  ) async {
    try {
      final mlResult = await ref
          .read(intentClassifierProvider)
          .classify(text);

      final resolver = ref.read(
        astraIntentResolverProvider,
      );

      return resolver.resolve(
        text: text,
        ml: mlResult,
      );
    } catch (_) {
      return null;
    }
  }

  int _activeRequestGeneration = 0;

  void stopCommand() {
    _activeRequestGeneration++;
    state = state.copyWith(isLoading: false);
    addMessage('Request cancelled.', type: AssistantMessageType.info);
  }

  // ─── Command Router ────────────────────────────────────────────────────────

  Future<void> sendCommand(String input) async {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return;

    final requestGen = ++_activeRequestGeneration;

    final resolvedIntent =
        await _resolveIntentWithSetA(trimmed);

    if (requestGen != _activeRequestGeneration) return;

    if (resolvedIntent != null) {
      debugPrint(
        '[ASTRA INTENT] '
        '${resolvedIntent.intent} '
        'confidence='
        '${resolvedIntent.mlConfidence.toStringAsFixed(3)} '
        'reason=${resolvedIntent.reason}',
      );
    }

    addMessage(trimmed, isUser: true);
    state = state.copyWith(isLoading: true, error: null);

    try {
      if (resolvedIntent != null) {
        switch (resolvedIntent.intent) {
          case 'LIST_TASKS':
            debugPrint('[ASTRA ROUTER] intent=LIST_TASKS source=set_a_resolver mode=AUTHORITATIVE');
            await handleListTasks();
            if (requestGen != _activeRequestGeneration) return;
            return;

          case 'SYNC_EMAIL':
            debugPrint('[ASTRA ROUTER] intent=SYNC_EMAIL source=set_a_resolver mode=AUTHORITATIVE');
            await handleSyncEmails();
            if (requestGen != _activeRequestGeneration) return;
            return;

          case 'SEARCH_EMAIL':
          case 'SUMMARIZE_EMAIL':
            debugPrint('[ASTRA ROUTER] intent=${resolvedIntent.intent} source=set_a_resolver mode=AUTHORITATIVE');
            await handleLatestInboxEmail();
            if (requestGen != _activeRequestGeneration) return;
            return;

          case 'GET_CALENDAR':
            debugPrint('[ASTRA ROUTER] intent=GET_CALENDAR source=set_a_resolver mode=AUTHORITATIVE');
            await handleTodayCalendar();
            if (requestGen != _activeRequestGeneration) return;
            return;

          case 'GET_PANCHANG':
            debugPrint('[ASTRA ROUTER] intent=GET_PANCHANG source=set_a_resolver mode=AUTHORITATIVE');
            handlePanchangQuery();
            if (requestGen != _activeRequestGeneration) return;
            return;

          case 'COMPLETE_TASK':
            debugPrint('[ASTRA ROUTER] intent=COMPLETE_TASK source=set_a_resolver mode=AUTHORITATIVE');
            await handleCompleteTask(trimmed);
            if (requestGen != _activeRequestGeneration) return;
            return;

          case 'CANCEL_TASK':
            debugPrint('[ASTRA ROUTER] intent=CANCEL_TASK source=set_a_resolver mode=AUTHORITATIVE');
            await handleCancelReminder(trimmed);
            if (requestGen != _activeRequestGeneration) return;
            return;

          case 'GENERAL_CHAT':
            debugPrint('[ASTRA ROUTER] intent=GENERAL_CHAT source=set_a_resolver mode=AUTHORITATIVE');
            await _handleGeneralChat(trimmed);
            if (requestGen != _activeRequestGeneration) return;
            return;

          case 'CREATE_TASK':
          case 'CREATE_REMINDER':
          case 'CREATE_CALENDAR_EVENT':
            final policy = ref.read(astraRoutingPolicyProvider);
            final routingDecision = policy.decide(
              resolvedIntent.intent,
              text: trimmed,
            );

            final semanticCommand = await _understandWithSemanticEngine(
              trimmed,
              intent: resolvedIntent.intent,
              requiresEventClassification: routingDecision.requiresEventClassification,
            );

            if (requestGen != _activeRequestGeneration) return;

            if (semanticCommand != null) {
              debugPrint(
                '[ASTRA SEMANTIC] '
                'type=${semanticCommand.eventType} '
                'action=${semanticCommand.action} '
                'title=${semanticCommand.title} '
                'route=${semanticCommand.route} '
                'confidence=${semanticCommand.semanticConfidence.toStringAsFixed(3)}',
              );

              final gate = ref.read(astraExecutionGateProvider);
              final gateDecision = gate.check(semanticCommand);

              if (gateDecision.canExecute) {
                debugPrint('[ASTRA ROUTER] intent=${resolvedIntent.intent} mode=EXECUTING_VIA_ASTRA_COMMAND');
                final executor = ref.read(astraCommandExecutorProvider);
                final execResult = await executor.execute(
                  ref: ref,
                  command: semanticCommand,
                );

                if (requestGen != _activeRequestGeneration) return;

                String? calStatus;
                if (semanticCommand.intent == 'CREATE_CALENDAR_EVENT') {
                  calStatus = execResult.calendarSynced
                      ? 'Synced with Google Calendar'
                      : (execResult.calendarMessage ?? 'Saved locally');
                }

                addStructuredResponse(AstraResponseBuilder.taskCreated(
                  title: execResult.title,
                  dueAt: execResult.scheduledAt,
                  timezone: semanticCommand.temporal.timezone,
                  organization: semanticCommand.organization,
                  priority: semanticCommand.priority,
                  taskId: execResult.taskId,
                  calendarStatus: calStatus,
                ));
                return;
              } else if (semanticCommand.route == 'CONFIRM' || gateDecision.reason == 'confirmation_required' || gateDecision.reason == 'temporal_ambiguous' || gateDecision.reason == 'temporal_missing') {
                debugPrint('[ASTRA ROUTER] intent=${resolvedIntent.intent} mode=CONFIRMATION_REQUIRED reason=${gateDecision.reason}');
                if (requestGen != _activeRequestGeneration) return;
                addStructuredResponse(AstraResponseBuilder.info(
                  'Please confirm details',
                  lines: [
                    AstraResponseLine(label: 'Title', value: semanticCommand.title, highlight: true),
                    if (semanticCommand.temporal.rawTime != null || semanticCommand.temporal.rawDate != null)
                      AstraResponseLine(
                        label: 'When',
                        value: '${semanticCommand.temporal.rawDate ?? ""} ${semanticCommand.temporal.rawTime ?? ""}'.trim(),
                      ),
                    if (semanticCommand.organization != null)
                      AstraResponseLine(label: 'Organization', value: semanticCommand.organization!),
                    if (semanticCommand.temporal.warnings.isNotEmpty)
                      AstraResponseLine(label: 'Note', value: semanticCommand.temporal.warnings.join(' ')),
                  ],
                ));
                return;
              }
            }
            break;

          case 'UPDATE_TASK':
            debugPrint('[ASTRA ROUTER] intent=${resolvedIntent.intent} source=set_a_resolver mode=AUTHORITATIVE');
            const updateParser = AstraUpdateParser();
            final now = DateTime.now();
            final updateCmd = updateParser.parse(text: trimmed, now: now);

            final activeTasks = ref.read(taskNotifierProvider);
            final executor = ref.read(astraCommandExecutorProvider);
            final updateResult = await executor.update(
              ref: ref,
              command: updateCmd,
              activeTasks: activeTasks,
            );

            if (requestGen != _activeRequestGeneration) return;

            if (updateResult.success) {
              addStructuredResponse(AstraResponseBuilder.info(
                'Task updated',
                lines: [
                  AstraResponseLine(label: 'Task', value: updateResult.title, highlight: true),
                  if (updateResult.scheduledAt != null)
                    AstraResponseLine(
                      label: 'Reminder',
                      value: DateFormat('EEE, MMM d · h:mm a').format(updateResult.scheduledAt!),
                    ),
                  AstraResponseLine(label: 'Status', value: updateResult.message),
                ],
              ));
            } else if (updateResult.requiresConfirmation) {
              final lines = <AstraResponseLine>[];
              if (updateCmd.targetQuery.isNotEmpty) {
                lines.add(AstraResponseLine(label: 'Target', value: updateCmd.targetQuery, highlight: true));
              }
              if (updateResult.candidateTitles.isNotEmpty) {
                lines.add(AstraResponseLine(
                  label: 'Matches',
                  value: updateResult.candidateTitles.join(', '),
                ));
              }
              if (updateResult.warnings.isNotEmpty) {
                lines.add(AstraResponseLine(label: 'Note', value: updateResult.warnings.join(' ')));
              }

              addStructuredResponse(AstraResponseBuilder.info(
                updateResult.message.isNotEmpty ? updateResult.message : 'Please clarify update details',
                lines: lines,
              ));
            }
            return;
        }
      }

      if (requestGen != _activeRequestGeneration) return;

      final command = ref.read(astraCommandBusProvider).parse(trimmed);

      switch (command.intent) {
        case AstraIntent.createReminder:
        case AstraIntent.createTask:
          await handleCreateTask(trimmed, command: command);

        case AstraIntent.signIn:
          await handleSignIn();

        case AstraIntent.signOut:
          await handleSignOut();

        case AstraIntent.syncEmails:
          await handleSyncEmails();

        case AstraIntent.latestEmail:
          await handleLatestInboxEmail();

        case AstraIntent.syncCalendar:
          await handleSyncCalendar();

        case AstraIntent.todayCalendar:
          await handleTodayCalendar();

        case AstraIntent.fullSync:
          await handleFullSync();

        case AstraIntent.panchang:
          handlePanchangQuery();

        case AstraIntent.completeTask:
          await handleCompleteTask(trimmed);

        case AstraIntent.cancelReminder:
          await handleCancelReminder(trimmed);

        case AstraIntent.snoozeReminder:
          await handleSnoozeReminder(trimmed);

        case AstraIntent.queryTask:
          await handleQueryTask(trimmed);

        case AstraIntent.listTasks:
          await handleListTasks();

        case AstraIntent.currentTime:
          _handleCurrentTime();

        case AstraIntent.currentDate:
          _handleCurrentDate();

        case AstraIntent.generalChat:
          await _handleGeneralChat(trimmed);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      addStructuredResponse(AstraResponseBuilder.error(_friendlyError(e)));
    }
  }

  // ─── Instant Handlers (no async needed) ──────────────────────────────────

  void _handleCurrentTime() {
    final now = DateTime.now().toLocal();
    addStructuredResponse(AstraResponseBuilder.info(
      'Current time',
      lines: [
        AstraResponseLine(label: 'Time', value: DateFormat('h:mm a').format(now)),
        AstraResponseLine(label: 'Date', value: DateFormat('EEEE, MMMM d, yyyy').format(now)),
        const AstraResponseLine(label: 'Timezone', value: 'Asia/Kolkata'),
      ],
    ));
  }

  void _handleCurrentDate() {
    final now = DateTime.now().toLocal();
    addStructuredResponse(AstraResponseBuilder.info(
      'Today\'s date',
      lines: [
        AstraResponseLine(label: 'Date', value: DateFormat('EEEE, MMMM d, yyyy').format(now)),
      ],
    ));
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

  Future<void> handleCreateTask(String input, {AstraCommand? command}) async {
    try {
      final parsed = TaskParser.parse(input);

      if (parsed.title.isEmpty || parsed.title.length < 2) {
        addStructuredResponse(AstraResponseBuilder.info(
          'Need more detail',
          lines: const [
            AstraResponseLine(
              label: '',
              value: 'Try: "Remind me to drink water in 2 minutes"',
            ),
          ],
        ));
        return;
      }

      final wantsReminder = command?.wantsReminder ?? parsed.hasReminder;

      if (wantsReminder && parsed.remindAt == null) {
        addStructuredResponse(AstraResponseBuilder.info(
          'When should I remind you?',
          lines: [
            AstraResponseLine(label: 'Task', value: parsed.title, highlight: true),
            const AstraResponseLine(
              label: '',
              value: 'Add a time like "tomorrow at 10am" or "in 5 minutes".',
            ),
          ],
        ));
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

      ScheduleOutcome? notificationOutcome;
      if (wantsReminder && parsed.remindAt != null) {
        final scheduleResult = await ref.read(reminderServiceProvider).scheduleReminder(
              taskId: task.id,
              taskTitle: task.title,
              scheduledAt: parsed.remindAt!,
              timezone: parsed.timezone,
            );
        notificationOutcome = scheduleResult.outcome;
      }

      addStructuredResponse(AstraResponseBuilder.taskCreated(
        title: task.title,
        dueAt: parsed.remindAt,
        timezone: parsed.timezone,
        organization: parsed.organization,
        priority: task.priority,
        notificationOutcome: notificationOutcome,
        taskId: task.id,
        subtasks: parsed.subtasks.map((s) => s.name).toList(),
      ));
    } catch (e) {
      addStructuredResponse(AstraResponseBuilder.error(_friendlyError(e)));
    }
  }

  Future<void> handleResponseAction(String actionId) async {
    if (actionId.startsWith('complete_')) {
      final taskId = actionId.replaceFirst('complete_', '');
      final tasks = ref.read(taskNotifierProvider);
      final target = tasks.cast<Task?>().firstWhere((t) => t?.id == taskId, orElse: () => null);
      if (target != null) {
        await ref.read(taskNotifierProvider.notifier).toggleComplete(taskId);
        ref.invalidate(taskListProvider);
        await ref.read(reminderServiceProvider).cancelReminderForTask(taskId);
        addStructuredResponse(AstraResponseBuilder.taskCompleted(target.title));
      }
    } else if (actionId.startsWith('snooze_')) {
      final taskId = actionId.replaceFirst('snooze_', '');
      final tasks = ref.read(taskNotifierProvider);
      final target = tasks.cast<Task?>().firstWhere((t) => t?.id == taskId, orElse: () => null);
      if (target != null) {
        final db = ref.read(databaseProvider);
        final reminder = await db.getReminderByTaskId(taskId);
        if (reminder != null) {
          await ref.read(reminderServiceProvider).snoozeReminder(reminder.id, duration: const Duration(minutes: 10));
        }
        addStructuredResponse(AstraResponseBuilder.reminderSnoozed(target.title, const Duration(minutes: 10)));
      }
    }
  }

  Future<void> handleCompleteTask(String input) async {
    final tasks = ref.read(taskNotifierProvider);
    final pending = tasks.where((t) => !t.isCompleted).toList();

    if (pending.isEmpty) {
      addStructuredResponse(AstraResponseBuilder.info('No pending tasks to complete.'));
      return;
    }

    String? query;
    final match =
        RegExp(r'(?:complete|done|finish|mark\s+as\s+done|tick\s+off|mark)\s+(.+)$', caseSensitive: false).firstMatch(input);
    if (match != null) {
      query = match.group(1)?.trim().toLowerCase();
      // Strip trailing "complete", "done", "as done" if present
      query = query?.replaceAll(RegExp(r'\s+(?:as\s+)?(?:done|complete|completed)$', caseSensitive: false), '').trim();
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
    await ref.read(reminderServiceProvider).cancelReminderForTask(target.id);

    addStructuredResponse(AstraResponseBuilder.taskCompleted(target.title));
  }

  Future<void> handleCancelReminder(String input) async {
    final target = _findTaskFromQuery(input, r'(?:cancel|delete|remove|stop)\s+(?:my\s+)?(?:the\s+)?(?:\w+\s+){0,3}?(?:reminder|alarm|notification)\s*(?:for\s+)?(.+)?$');
    if (target == null) {
      addStructuredResponse(AstraResponseBuilder.info('No matching reminder found.'));
      return;
    }
    await ref.read(reminderServiceProvider).cancelReminderForTask(target.id);
    addStructuredResponse(AstraResponseBuilder.reminderCancelled(target.title));
  }

  Future<void> handleSnoozeReminder(String input) async {
    final target = _findTaskFromQuery(input, r'(?:snooze|postpone|delay)\s+(?:my\s+)?(?:the\s+)?(?:\w+\s+){0,3}?(?:reminder\s+)?(?:for\s+)?(.+?)(?:\s+(\d+)\s*(?:min|mins|minutes))?$');
    if (target == null) {
      addStructuredResponse(AstraResponseBuilder.info('No matching reminder to snooze.'));
      return;
    }

    final minutesMatch = RegExp(r'(\d+)\s*(?:min|mins|minutes)', caseSensitive: false).firstMatch(input);
    final duration = Duration(minutes: int.tryParse(minutesMatch?.group(1) ?? '') ?? 10);

    final db = ref.read(databaseProvider);
    final reminder = await db.getReminderByTaskId(target.id);
    if (reminder != null) {
      await ref.read(reminderServiceProvider).snoozeReminder(reminder.id, duration: duration);
    }
    addStructuredResponse(AstraResponseBuilder.reminderSnoozed(target.title, duration));
  }

  Task? _findTaskFromQuery(String input, String pattern) {
    final tasks = ref.read(taskNotifierProvider).where((t) => !t.isCompleted).toList();
    if (tasks.isEmpty) return null;

    final match = RegExp(pattern, caseSensitive: false).firstMatch(input);
    final query = match?.group(1)?.trim().toLowerCase();
    if (query == null || query.isEmpty) return tasks.first;

    return tasks.cast<Task?>().firstWhere(
          (t) => t!.title.toLowerCase().contains(query),
          orElse: () => tasks.first,
        );
  }

  Future<void> handleQueryTask(String input) async {
    final tasks = ref.read(taskNotifierProvider);
    final pending = tasks.where((t) => !t.isCompleted).toList();

    if (pending.isEmpty) {
      addStructuredResponse(AstraResponseBuilder.info('No matching tasks found.'));
      return;
    }

    // Extract subject after "my" — e.g. "what time is my exam"
    String? subject;
    final match = RegExp(
      r"(?:what\s+time\s+is\s+my|when\s+is\s+my|what'?s?\s+my)\s+(.+?)(?:\?|$)",
      caseSensitive: false,
    ).firstMatch(input);
    if (match != null) {
      subject = match.group(1)?.trim().toLowerCase();
    }

    Task? target;
    if (subject != null && subject.isNotEmpty) {
      final matches = pending
          .where((t) =>
              t.title.toLowerCase().contains(subject!) ||
              (t.organization?.toLowerCase().contains(subject) ?? false))
          .toList();
      if (matches.isNotEmpty) target = matches.first;
    }
    target ??= pending.first;

    addStructuredResponse(AstraResponse(
      type: AstraResponseType.taskQuery,
      headline: target.title,
      lines: [
        if (target.dueDate != null)
          AstraResponseLine(
            label: 'Scheduled',
            value: DateFormat('EEEE, MMM d, yyyy · h:mm a').format(target.dueDate!),
            highlight: true,
          )
        else
          const AstraResponseLine(label: 'Scheduled', value: 'No reminder time set'),
        const AstraResponseLine(label: 'Timezone', value: 'Asia/Kolkata'),
        if (target.organization != null)
          AstraResponseLine(label: 'Organization', value: target.organization!),
        AstraResponseLine(label: 'Priority', value: target.priority.toUpperCase()),
      ],
      actions: [
        AstraAction(id: 'complete_${target.id}', label: 'DONE'),
        AstraAction(id: 'snooze_${target.id}', label: 'SNOOZE 10m'),
      ],
    ));
  }

  Future<void> handleListTasks() async {
    final tasks = ref.read(taskNotifierProvider);
    final pending = tasks.where((t) => !t.isCompleted).toList();

    if (pending.isEmpty) {
      addStructuredResponse(AstraResponseBuilder.info('No pending tasks. Your schedule is clear!'));
      return;
    }

    final lines = <AstraResponseLine>[];
    for (var i = 0; i < pending.length && i < 8; i++) {
      final t = pending[i];
      var val = t.title;
      if (t.priority == 'high') val += ' [HIGH]';
      if (t.dueDate != null) {
        val += ' · Due ${DateFormat("MMM d, h:mm a").format(t.dueDate!)}';
      }
      lines.add(AstraResponseLine(label: '${i + 1}', value: val));
    }
    if (pending.length > 8) {
      lines.add(AstraResponseLine(label: '', value: '... and ${pending.length - 8} more'));
    }

    addStructuredResponse(AstraResponse(
      type: AstraResponseType.taskList,
      headline: 'Pending Tasks (${pending.length})',
      lines: lines,
    ));
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
