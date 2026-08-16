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
import '../core/reminders/reminder_strategy.dart';
import '../core/commands/astra_command.dart';
import '../core/commands/astra_command_bus.dart';
import '../core/commands/astra_response.dart';
import '../core/commands/astra_response_builder.dart';
import 'reminder_provider.dart';
import 'auth_provider.dart';
import 'b1_classifier_provider.dart';
import '../services/ml/b1_event_classifier_client.dart';
import 'intent_classifier_provider.dart';
import '../services/ml/intent_classifier_client.dart';
import 'astra_intent_resolver_provider.dart';
import '../services/assistant/astra_intent_resolver.dart';
import 'astra_routing_policy_provider.dart';
import 'astra_execution_gate_provider.dart';
import 'astra_command_executor_provider.dart';
import 'astra_semantic_engine_provider.dart';
import '../services/assistant/astra_command.dart' as semantic;
import '../services/assistant/astra_update_command.dart';
import 'astra_memory_provider.dart';
import '../services/assistant/astra_memory_engine.dart';
import '../services/assistant/astra_temporal_engine.dart';
import '../services/assistant/astra_input_classifier.dart';
import '../services/assistant/astra_document_analyzer.dart';
import '../services/email/astra_email_analyzer.dart';
import '../features/scheduler/data/services/google_calendar_writer_service.dart';
import 'google_calendar_writer_provider.dart';
import 'package:uuid/uuid.dart';

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

enum AssistantMessageType { text, emailSummary, calendarSummary, syncResult, documentAnalysis, info, success, error, auth }

/// Represents an analyzed email insight candidate with actionable status.
class EmailInsightItem {
  final GmailMessageData email;
  final AstraEmailAnalysis analysis;
  final bool isProcessed;

  const EmailInsightItem({
    required this.email,
    required this.analysis,
    this.isProcessed = false,
  });

  EmailInsightItem copyWith({bool? isProcessed}) {
    return EmailInsightItem(
      email: email,
      analysis: analysis,
      isProcessed: isProcessed ?? this.isProcessed,
    );
  }
}

class AssistantMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final AssistantMessageType messageType;
  final AstraResponse? structured;
  final List<GmailMessageData>? emails;
  final List<EmailInsightItem>? emailInsights;
  final List<CalendarEventData>? calendarEvents;
  final SchedulerSyncResult? syncResult;
  final AstraDocumentAnalysis? documentAnalysis;

  AssistantMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.messageType = AssistantMessageType.text,
    this.structured,
    this.emails,
    this.emailInsights,
    this.calendarEvents,
    this.syncResult,
    this.documentAnalysis,
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
  final Set<String> _syncedCalendarCandidateIds = <String>{};
  final Set<String> _inFlightCalendarCandidateIds = <String>{};

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
    List<EmailInsightItem>? emailInsights,
    List<CalendarEventData>? calendarEvents,
    SchedulerSyncResult? syncResult,
    AstraDocumentAnalysis? documentAnalysis,
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
      emailInsights: emailInsights,
      calendarEvents: calendarEvents,
      syncResult: syncResult,
      documentAnalysis: documentAnalysis,
    );

    state = state.copyWith(
      messages: [...state.messages, newMsg],
      isLoading: false,
    );

    final currentSessionId = ref.read(currentSessionIdProvider);
    if (currentSessionId != null) {
      try {
        ref.read(chatSessionProvider.notifier).addMessage(
          currentSessionId,
          isUser ? 'user' : 'assistant',
          displayText,
          messageType: type.name,
        );
      } catch (_) {}
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
    IntentClassificationResult? mlResult;
    try {
      mlResult = await ref
          .read(intentClassifierProvider)
          .classify(text);
    } catch (_) {
      mlResult = null;
    }

    try {
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

  PendingConversationAction? _pendingAction;

  // ─── Command Router ────────────────────────────────────────────────────────

  Future<void> sendCommand(String input) async {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return;

    final requestGen = ++_activeRequestGeneration;

    // 0. Classify Input Kind (Command vs Conversation vs Document vs Multi-Item Document)
    const inputClassifier = AstraInputClassifier();
    final inputKind = inputClassifier.classify(trimmed);

    if (inputKind.kind == AstraInputKind.document || inputKind.kind == AstraInputKind.multiItemDocument) {
      debugPrint('[ASTRA ROUTER] inputKind=${inputKind.kind.name} mode=DOCUMENT_INTAKE reason=${inputKind.reason}');
      addMessage(trimmed, isUser: true);
      state = state.copyWith(isLoading: true, error: null);
      await handleDocumentIntake(trimmed, requestGen);
      return;
    }

    // 1. Resolve session ID & Build bounded local context via M1 Memory Engine
    final currentSessionId = ref.read(currentSessionIdProvider);
    final contextBuilder = ref.read(astraContextBuilderProvider);
    final memoryEngine = ref.read(astraMemoryEngineProvider);
    final referenceResolver = ref.read(astraReferenceResolverProvider);

    final localContext = await contextBuilder.buildContext(
      currentText: trimmed,
      sessionId: currentSessionId,
      now: DateTime.now(),
    );

    debugPrint(
      '[ASTRA MEMORY] session=$currentSessionId '
      'recent=${localContext.recentMessages.length} '
      'activeTasks=${localContext.activeTasks.length} '
      'memories=${localContext.structuredMemories.length}',
    );

    // 2. Resolve Contextual References (e.g. "it", "the exam", "make it 11", "remind me about it Thursday at 8pm")
    final refResult = referenceResolver.resolveReference(trimmed, localContext);
    if (refResult.isResolved) {
      debugPrint('[ASTRA REFERENCE] resolved="${refResult.resolvedTitle}" type=${refResult.resolvedType} confidence=${refResult.confidence.toStringAsFixed(2)}');
    }

    // 3. Resolve Intent via Set A on-device classifier & deterministic rules
    var resolvedIntent = await _resolveIntentWithSetA(trimmed);

    if (requestGen != _activeRequestGeneration) return;

    // If a pending conversation action exists and input provides the missing piece (e.g. "tomorrow at 7pm"), align intent to pending operation
    if (_pendingAction != null && _pendingAction!.operation == 'UPDATE_TASK') {
      const temporalEngine = AstraTemporalEngine();
      final temporalCheck = temporalEngine.parse(trimmed);
      if (temporalCheck.eventStart != null || temporalCheck.deadline != null || RegExp(r'\b(today|tomorrow|tmrw|monday|tuesday|wednesday|thursday|friday|saturday|sunday|\d{1,2}(?::\d{2})?\s*(?:am|pm))\b', caseSensitive: false).hasMatch(trimmed)) {
        resolvedIntent = const AstraResolvedIntent(
          intent: 'UPDATE_TASK',
          mlConfidence: 0.98,
          reason: 'pending_action_continuation_rule',
        );
      }
    }

    // If text contains pronoun/definite reference to update or remind, ensure intent aligns
    if (refResult.isResolved) {
      if (RegExp(r'^(?:make|set|change|shift|move)\s+(?:it|that|this)\b', caseSensitive: false).hasMatch(trimmed)) {
        resolvedIntent = const AstraResolvedIntent(
          intent: 'UPDATE_TASK',
          mlConfidence: 0.95,
          reason: 'contextual_reference_update_rule',
        );
      } else if (RegExp(r'\bremind\s+me\s+about\s+it\b', caseSensitive: false).hasMatch(trimmed)) {
        resolvedIntent = const AstraResolvedIntent(
          intent: 'CREATE_REMINDER',
          mlConfidence: 0.95,
          reason: 'contextual_reference_reminder_rule',
        );
      }
    }

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

            // If reference resolver found an entity (e.g. "remind me about it Thursday at 8pm" -> "Assignment"), augment text for semantic engine
            String semanticInput = trimmed;
            if (refResult.isResolved && refResult.resolvedTitle != null && (trimmed.contains(' it') || trimmed.contains(' this') || trimmed.contains(' that'))) {
              semanticInput = trimmed.replaceAll(RegExp(r'\b(about\s+)?(it|that|this)\b', caseSensitive: false), 'about ${refResult.resolvedTitle!}');
            }

            final semanticCommand = await _understandWithSemanticEngine(
              semanticInput,
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

                // Entity Capture: Store structured memory for newly created entity
                memoryEngine.storeMemory(
                  AstraMemoryItem(
                    id: execResult.taskId.isNotEmpty ? execResult.taskId : DateTime.now().millisecondsSinceEpoch.toString(),
                    type: 'TASK_ENTITY',
                    key: 'last_entity',
                    value: execResult.title,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                    metadata: {
                      'dueAt': execResult.scheduledAt?.toIso8601String(),
                      'organization': semanticCommand.organization,
                      'eventType': semanticCommand.eventType,
                    },
                  ),
                );

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

            // Handle pending action continuation across turns if applicable:
            // e.g. previous turn asked for time on "move my exam", next turn is "tomorrow at 7"
            String updateText = trimmed;
            if (_pendingAction != null && _pendingAction!.operation == 'UPDATE_TASK') {
              final pending = _pendingAction!;
              if (pending.targetEntity.isNotEmpty && !updateText.contains(pending.targetEntity)) {
                updateText = 'move ${pending.targetEntity} to $updateText';
              }
              _pendingAction = null; // consume pending action
            }

            var updateCmd = updateParser.parse(text: updateText, now: now);

            // Context-Aware Target Resolution:
            // If target is missing, stopword ("it", "that", "this", "to", "the exam"), or reference resolver found a specific entity, use AstraReferenceResolver result
            final isGenericTarget = updateCmd.targetQuery.isEmpty ||
                updateCmd.targetQuery == 'it' ||
                updateCmd.targetQuery == 'that' ||
                updateCmd.targetQuery == 'this' ||
                updateCmd.targetQuery == 'to' ||
                updateCmd.targetQuery == 'task' ||
                updateCmd.targetQuery == 'item';

            if ((isGenericTarget || (refResult.isResolved && refResult.resolvedTaskId != null)) && refResult.isResolved && refResult.resolvedTitle != null) {
              updateCmd = AstraUpdateCommand(
                originalText: updateCmd.originalText,
                targetQuery: refResult.resolvedTitle!,
                newTitle: updateCmd.newTitle,
                newDueAt: updateCmd.newDueAt,
                newPriority: updateCmd.newPriority,
                newOrganization: updateCmd.newOrganization,
                newRecurrenceRule: updateCmd.newRecurrenceRule,
                requiresConfirmation: updateCmd.newDueAt == null && updateCmd.newTitle == null && updateCmd.newPriority == null && updateCmd.newOrganization == null,
                warnings: updateCmd.warnings,
              );
            }

            final taskNotifier = ref.read(taskNotifierProvider.notifier);
            var activeTasks = ref.read(taskNotifierProvider);
            if (activeTasks.isEmpty) {
              await taskNotifier.loadTasks();
              activeTasks = ref.read(taskNotifierProvider);
            }
            final executor = ref.read(astraCommandExecutorProvider);
            final updateResult = await executor.update(
              ref: ref,
              command: updateCmd,
              activeTasks: activeTasks,
            );

            if (requestGen != _activeRequestGeneration) return;

            if (updateResult.success) {
              // Entity Capture: update structured memory
              memoryEngine.storeMemory(
                AstraMemoryItem(
                  id: updateResult.taskId.isNotEmpty ? updateResult.taskId : DateTime.now().millisecondsSinceEpoch.toString(),
                  type: 'TASK_ENTITY',
                  key: 'last_entity',
                  value: updateResult.title,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                  metadata: {
                    'dueAt': updateResult.scheduledAt?.toIso8601String(),
                  },
                ),
              );

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
              // If target was identified but missing new time, track as pending conversation action
              if (updateCmd.targetQuery.isNotEmpty && updateCmd.newDueAt == null) {
                _pendingAction = PendingConversationAction(
                  targetEntity: updateCmd.targetQuery,
                  operation: 'UPDATE_TASK',
                  missingFields: ['time'],
                  createdAt: DateTime.now(),
                  sessionId: currentSessionId,
                );
              }

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

    final analyzer = const AstraEmailAnalyzer();
    final insights = emails.map((e) {
      final analysis = analyzer.analyze(e);
      return EmailInsightItem(email: e, analysis: analysis);
    }).toList();

    final actionableCount = insights.where((i) => i.analysis.isActionable).length;

    addMessage(
      actionableCount > 0
          ? '📧 Found ${emails.length} email${emails.length > 1 ? "s" : ""} ($actionableCount actionable):'
          : '📧 Found ${emails.length} relevant email${emails.length > 1 ? "s" : ""}:',
      type: AssistantMessageType.emailSummary,
      emails: emails,
      emailInsights: insights,
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

    final analyzer = const AstraEmailAnalyzer();
    final analysis = analyzer.analyze(email);
    final insight = EmailInsightItem(email: email, analysis: analysis);

    addMessage(
      'Latest inbox email\n\nFrom: ${email.sender}\nSubject: ${email.subject}\nReceived: ${DateFormat('MMM d, h:mm a').format(email.date)}\n\n${email.snippet.isEmpty ? email.bodyText : email.snippet}',
      type: AssistantMessageType.emailSummary,
      emails: [email],
      emailInsights: [insight],
    );
  }

  Future<void> addEmailInsightToTasks({
    required GmailMessageData email,
    required AstraEmailAnalysis analysis,
  }) async {
    final now = DateTime.now();
    final scheduledAt = analysis.deadline ?? analysis.eventDateTime;
    final isHighImportance = analysis.importance == EmailImportance.high || analysis.importance == EmailImportance.critical;
    final strategy = isHighImportance
        ? (analysis.category == EmailCategory.deadline ? ReminderStrategy.deadline : ReminderStrategy.important)
        : ReminderStrategy.normal;

    final command = semantic.AstraCommand(
      intent: 'CREATE_TASK',
      eventType: analysis.isEvent ? 'MEETING' : (analysis.category == EmailCategory.deadline ? 'DEADLINE' : 'OTHER'),
      title: analysis.suggestedTaskTitle,
      action: analysis.actionRequired,
      organization: analysis.organization,
      temporal: semantic.AstraTemporal(
        deadline: analysis.deadline,
        eventStart: analysis.eventDateTime,
        timezone: 'Asia/Kolkata',
        recurrence: 'NONE',
      ),
      recurrence: 'NONE',
      priority: isHighImportance ? 'high' : 'medium',
      modelConfidence: analysis.confidence,
      semanticConfidence: analysis.confidence,
      requiresConfirmation: false,
      route: 'EXECUTE',
      originalText: 'Email: ${email.subject}',
    );

    final executor = ref.read(astraCommandExecutorProvider);
    final result = await executor.execute(
      ref: ref,
      command: command,
    );

    if (result.success) {
      final task = Task(
        id: result.taskId,
        title: result.title,
        dueDate: result.scheduledAt,
        priority: isHighImportance ? 'high' : 'medium',
        status: 'active',
        organization: analysis.organization,
        createdAt: now,
        updatedAt: now,
      );

      await ref.read(taskNotifierProvider.notifier).addTask(task);
      ref.invalidate(taskListProvider);
      await ref.read(taskNotifierProvider.notifier).loadTasks();

      if (scheduledAt != null) {
        await ref.read(reminderServiceProvider).scheduleReminder(
          taskId: task.id,
          taskTitle: task.title,
          scheduledAt: scheduledAt,
          strategy: strategy,
        );
      }

      // Record structured memory in AstraMemoryEngine
      final memoryEngine = ref.read(astraMemoryEngineProvider);
      memoryEngine.storeEmailTaskMemory(
        emailId: email.id,
        title: task.title,
        taskId: task.id,
        deadline: result.scheduledAt,
        organization: analysis.organization,
        subject: email.subject,
      );

      final dateStr = scheduledAt != null ? ' (due ${DateFormat('EEE, MMM d · h:mm a').format(scheduledAt)})' : '';
      addMessage(
        '✅ Added "${task.title}" to your tasks$dateStr.',
        type: AssistantMessageType.success,
      );
    } else {
      addMessage(
        'Could not create task: ${result.message}',
        type: AssistantMessageType.error,
      );
    }
  }

  Future<void> addEmailInsightToCalendar({
    required GmailMessageData email,
    required AstraEmailAnalysis analysis,
  }) async {
    final candidateId = 'email_${email.id}_${analysis.suggestedTaskTitle.hashCode}';
    if (_syncedCalendarCandidateIds.contains(candidateId)) {
      addMessage(
        'Already added "${analysis.suggestedTaskTitle}" to Google Calendar.',
        type: AssistantMessageType.info,
      );
      return;
    }
    if (_inFlightCalendarCandidateIds.contains(candidateId)) return;

    final startTime = analysis.startAt ?? analysis.eventDateTime ?? analysis.deadline ?? DateTime.now().add(const Duration(days: 1));
    final endTime = analysis.endAt ?? startTime.add(const Duration(hours: 1));

    final authService = ref.read(googleAuthServiceProvider);
    final client = await authService.getAuthenticatedClient();

    if (client == null) {
      debugPrint(
        '[ASTRA CALENDAR CARD]\n'
        'candidateId=$candidateId\n'
        'title=${analysis.suggestedTaskTitle}\n'
        'startAt=$startTime\n'
        'endAt=$endTime\n'
        'authenticated=false\n'
        'insertStarted=false',
      );
      debugPrint(
        '[ASTRA CALENDAR CARD]\n'
        'insertSuccess=false\n'
        'errorCode=auth_missing',
      );
      addMessage(
        'Google Calendar permission is required.',
        type: AssistantMessageType.auth,
      );
      return;
    }

    _inFlightCalendarCandidateIds.add(candidateId);
    debugPrint(
      '[ASTRA CALENDAR CARD]\n'
      'candidateId=$candidateId\n'
      'title=${analysis.suggestedTaskTitle}\n'
      'startAt=$startTime\n'
      'endAt=$endTime\n'
      'authenticated=true\n'
      'insertStarted=true',
    );

    try {
      final writer = ref.read(googleCalendarWriterServiceProvider);
      final senderInfo = email.senderName.isNotEmpty ? email.senderName : email.sender;
      final desc = 'From email: ${email.subject}\nSender: $senderInfo <${email.senderEmail}>\n\n${email.snippet}';

      final createdEvent = await writer.createEvent(
        client,
        title: analysis.suggestedTaskTitle,
        startTime: startTime,
        endTime: endTime,
        description: desc,
        location: analysis.organization,
      );

      _syncedCalendarCandidateIds.add(candidateId);
      _inFlightCalendarCandidateIds.remove(candidateId);

      // Also ensure local task exists
      await addEmailInsightToTasks(email: email, analysis: analysis);

      final googleEventId = createdEvent.id;
      debugPrint(
        '[ASTRA CALENDAR CARD]\n'
        'insertSuccess=true\n'
        'googleEventId=$googleEventId',
      );

      addMessage(
        'Added to Google Calendar: "${analysis.suggestedTaskTitle}".',
        type: AssistantMessageType.success,
      );
    } on GoogleCalendarWriteException catch (e) {
      _inFlightCalendarCandidateIds.remove(candidateId);
      debugPrint(
        '[ASTRA CALENDAR CARD]\n'
        'insertSuccess=false\n'
        'errorCode=${e.code.name}',
      );
      switch (e.code) {
        case GoogleCalendarWriteErrorCode.authRequired:
        case GoogleCalendarWriteErrorCode.permissionRequired:
          addMessage('Google Calendar permission is required.', type: AssistantMessageType.error);
          break;
        case GoogleCalendarWriteErrorCode.networkError:
          addMessage('Google Calendar is temporarily unavailable.', type: AssistantMessageType.error);
          break;
        case GoogleCalendarWriteErrorCode.apiError:
          addMessage('Could not add this event to Google Calendar.', type: AssistantMessageType.error);
          break;
      }
    } catch (e) {
      _inFlightCalendarCandidateIds.remove(candidateId);
      debugPrint(
        '[ASTRA CALENDAR CARD]\n'
        'insertSuccess=false\n'
        'errorCode=unexpected_error',
      );
      addMessage('Could not add this event to Google Calendar.', type: AssistantMessageType.error);
    }
  }

  // ─── Document Intake Handlers ─────────────────────────────────────────────

  Future<void> handleDocumentIntake(String text, int requestGen) async {
    final analyzer = const AstraDocumentAnalyzer();
    final analysis = analyzer.analyze(text);

    if (requestGen != _activeRequestGeneration) return;

    // Record extracted items in memory engine so user can refer to them later
    final memoryEngine = ref.read(astraMemoryEngineProvider);
    for (final item in analysis.extractedItems) {
      memoryEngine.storeEmailTaskMemory(
        emailId: item.id,
        title: item.title,
        taskId: item.id,
        deadline: item.dueAt ?? item.startAt,
        organization: item.organization,
        subject: item.description,
      );
    }

    final itemCount = analysis.extractedItems.length;
    final header = '📄 **${analysis.title}**\n${analysis.summary}\n\n'
        'Found **$itemCount actionable ${itemCount == 1 ? "item" : "items"}** from the document:';

    addMessage(
      header,
      type: AssistantMessageType.documentAnalysis,
      documentAnalysis: analysis,
    );
  }

  Future<void> addDocumentItemToTasks(AstraDocumentItem item) async {
    final now = DateTime.now();
    final taskId = const Uuid().v4();
    final scheduledAt = item.dueAt ?? item.startAt;

    final task = Task(
      id: taskId,
      title: item.title,
      description: item.description,
      startAt: item.startAt,
      endAt: item.endAt,
      dueDate: item.dueAt ?? item.startAt,
      priority: item.actionRequired ? 'high' : 'medium',
      status: 'active',
      organization: item.organization,
      createdAt: now,
      updatedAt: now,
    );

    await ref.read(taskNotifierProvider.notifier).addTask(task);
    ref.invalidate(taskListProvider);
    await ref.read(taskNotifierProvider.notifier).loadTasks();

    if (scheduledAt != null) {
      final isHigh = item.actionRequired || item.type == 'exam';
      final strategy = isHigh ? ReminderStrategy.important : ReminderStrategy.normal;
      try {
        await ref.read(reminderServiceProvider).scheduleReminder(
          taskId: task.id,
          taskTitle: task.title,
          scheduledAt: scheduledAt,
          strategy: strategy,
        );
      } catch (_) {}
    }

    final dateStr = item.isDuration
        ? ' (${DateFormat('d MMM').format(item.startAt!)} – ${DateFormat('d MMM yyyy').format(item.endAt!)})'
        : (scheduledAt != null ? ' (${DateFormat('EEE, MMM d · h:mm a').format(scheduledAt)})' : '');

    addMessage(
      '✅ Added "${item.title}"$dateStr to your tasks.',
      type: AssistantMessageType.success,
    );
  }

  Future<void> addDocumentItemToCalendar(AstraDocumentItem item) async {
    final candidateId = item.id;
    if (_syncedCalendarCandidateIds.contains(candidateId)) {
      addMessage(
        'Already added "${item.title}" to Google Calendar.',
        type: AssistantMessageType.info,
      );
      return;
    }
    if (_inFlightCalendarCandidateIds.contains(candidateId)) return;

    final startTime = item.startAt ?? item.dueAt ?? DateTime.now();
    final endTime = item.endAt ?? startTime.add(const Duration(hours: 1));

    final authService = ref.read(googleAuthServiceProvider);
    final client = await authService.getAuthenticatedClient();

    if (client == null) {
      debugPrint(
        '[ASTRA CALENDAR CARD]\n'
        'candidateId=$candidateId\n'
        'title=${item.title}\n'
        'startAt=$startTime\n'
        'endAt=$endTime\n'
        'authenticated=false\n'
        'insertStarted=false',
      );
      debugPrint(
        '[ASTRA CALENDAR CARD]\n'
        'insertSuccess=false\n'
        'errorCode=auth_missing',
      );
      addMessage(
        'Google Calendar permission is required.',
        type: AssistantMessageType.auth,
      );
      return;
    }

    _inFlightCalendarCandidateIds.add(candidateId);
    debugPrint(
      '[ASTRA CALENDAR CARD]\n'
      'candidateId=$candidateId\n'
      'title=${item.title}\n'
      'startAt=$startTime\n'
      'endAt=$endTime\n'
      'authenticated=true\n'
      'insertStarted=true',
    );

    try {
      final writer = ref.read(googleCalendarWriterServiceProvider);
      final createdEvent = await writer.createEvent(
        client,
        title: item.title,
        startTime: startTime,
        endTime: endTime,
        description: item.description,
        location: item.organization,
      );

      _syncedCalendarCandidateIds.add(candidateId);
      _inFlightCalendarCandidateIds.remove(candidateId);

      // Preserve local-task invariant
      await addDocumentItemToTasks(item);

      final googleEventId = createdEvent.id;
      debugPrint(
        '[ASTRA CALENDAR CARD]\n'
        'insertSuccess=true\n'
        'googleEventId=$googleEventId',
      );

      addMessage(
        'Added to Google Calendar: "${item.title}".',
        type: AssistantMessageType.success,
      );
    } on GoogleCalendarWriteException catch (e) {
      _inFlightCalendarCandidateIds.remove(candidateId);
      debugPrint(
        '[ASTRA CALENDAR CARD]\n'
        'insertSuccess=false\n'
        'errorCode=${e.code.name}',
      );
      switch (e.code) {
        case GoogleCalendarWriteErrorCode.authRequired:
        case GoogleCalendarWriteErrorCode.permissionRequired:
          addMessage('Google Calendar permission is required.', type: AssistantMessageType.error);
          break;
        case GoogleCalendarWriteErrorCode.networkError:
          addMessage('Google Calendar is temporarily unavailable.', type: AssistantMessageType.error);
          break;
        case GoogleCalendarWriteErrorCode.apiError:
          addMessage('Could not add this event to Google Calendar.', type: AssistantMessageType.error);
          break;
      }
    } catch (e) {
      _inFlightCalendarCandidateIds.remove(candidateId);
      debugPrint(
        '[ASTRA CALENDAR CARD]\n'
        'insertSuccess=false\n'
        'errorCode=unexpected_error',
      );
      addMessage('Could not add this event to Google Calendar.', type: AssistantMessageType.error);
    }
  }

  Future<void> addAllDocumentItemsToTasks(List<AstraDocumentItem> items) async {
    for (final item in items) {
      await addDocumentItemToTasks(item);
    }
    addMessage(
      '🎉 Added all ${items.length} items from the document to your tasks and schedule.',
      type: AssistantMessageType.success,
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
        final strategy = ReminderStrategyX.resolve(
          priority: task.priority,
          eventType: task.category,
        );
        final scheduleResult = await ref.read(reminderServiceProvider).scheduleReminder(
              taskId: task.id,
              taskTitle: task.title,
              scheduledAt: parsed.remindAt!,
              timezone: parsed.timezone,
              strategy: strategy,
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

    try {
      final response = await chatService
          .chat(
            userMessage: message,
            history: recentHistory,
            pendingTasks: tasks.where((t) => !t.isCompleted).toList(),
            userEmail: state.userEmail,
          )
          .timeout(const Duration(seconds: 5));
      addMessage(response, type: AssistantMessageType.text);
    } catch (_) {
      final pending = tasks.where((t) => !t.isCompleted).toList();
      final now = DateTime.now();
      if (message.toLowerCase().contains('task') || message.toLowerCase().contains('schedule')) {
        addMessage(
          '📋 You have ${pending.length} pending task(s). Current time is ${DateFormat('h:mm a').format(now)}.',
          type: AssistantMessageType.text,
        );
      } else {
        addMessage(
          '⚡ ASTRA is active. Current time: ${DateFormat('h:mm a').format(now)}. How can I assist with your tasks or schedule?',
          type: AssistantMessageType.text,
        );
      }
    }
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
