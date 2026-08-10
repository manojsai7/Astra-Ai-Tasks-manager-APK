import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../providers/assistant_provider.dart';
import '../features/scheduler/data/services/gmail_sync_service.dart';
import '../features/scheduler/data/services/calendar_sync_service.dart';
import '../core/motion.dart';

class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key});

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _dotCtrl;

  @override
  void initState() {
    super.initState();
    _dotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _dotCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendInput() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    ref.read(assistantStateProvider.notifier).sendCommand(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assistantStateProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, state),
            Expanded(
              child: state.messages.isEmpty
                  ? _buildEmptyState(context, state)
                  : _buildMessageList(context, state),
            ),
            if (state.isLoading) _buildThinkingIndicator(),
            _buildInputBar(context),
          ],
        ),
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, AssistantState state) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderFaint)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.secondary.withAlpha(30),
                  AppTheme.accentPurple.withAlpha(20),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.secondary.withAlpha(50)),
            ),
            child: const Icon(Icons.auto_awesome, size: 18, color: AppTheme.secondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ASTRA',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        letterSpacing: 2,
                        color: AppTheme.textPrimary,
                      ),
                ),
                Text(
                  state.isLoading
                      ? 'thinking...'
                      : state.isAuthenticated
                          ? '● ${state.userEmail ?? "Connected"}'
                          : 'ready · Tap Sign In to connect Google',
                  style: TextStyle(
                    fontSize: 10,
                    color: state.isLoading
                        ? AppTheme.secondary
                        : state.isAuthenticated
                            ? AppTheme.accentGreen
                            : AppTheme.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Google Auth Action Button
          GestureDetector(
            onTap: () {
              final notifier = ref.read(assistantStateProvider.notifier);
              if (state.isAuthenticated) {
                notifier.handleSignOut();
              } else {
                notifier.handleSignIn();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: state.isAuthenticated
                    ? AppTheme.accentGreen.withAlpha(20)
                    : AppTheme.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: state.isAuthenticated
                      ? AppTheme.accentGreen.withAlpha(60)
                      : AppTheme.primary.withAlpha(60),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    state.isAuthenticated ? LucideIcons.check : LucideIcons.logIn,
                    size: 12,
                    color: state.isAuthenticated
                        ? AppTheme.accentGreen
                        : AppTheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    state.isAuthenticated ? 'Connected' : 'Sign In',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: state.isAuthenticated
                          ? AppTheme.accentGreen
                          : AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (state.messages.isNotEmpty) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => ref.read(assistantStateProvider.notifier).clearMessages(),
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(LucideIcons.trash2, size: 14, color: AppTheme.textMuted),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  // ─── Empty State ───────────────────────────────────────────────────────────

  Widget _buildEmptyState(BuildContext context, AssistantState state) {
    final suggestions = [
      if (!state.isAuthenticated) 'Sign in with Google',
      'Sync all',
      'Sync my emails',
      'Sync calendar',
      'List my tasks',
      'Remind me to apply for Google Internship',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.secondary.withAlpha(25),
                  AppTheme.accentPurple.withAlpha(20),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.secondary.withAlpha(50)),
            ),
            child: const Icon(Icons.auto_awesome, size: 30, color: AppTheme.secondary),
          ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
          const SizedBox(height: 14),
          Text(
            'AI Life Scheduler',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            state.isAuthenticated
                ? 'Connected as ${state.userEmail}\nI can scan your emails, fetch calendar events, and schedule tasks automatically.'
                : 'Sign in with Google to automatically pull tasks from your emails and calendar.',
            style: const TextStyle(
                fontSize: 12, color: AppTheme.textMuted, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          const Text(
            'SUGGESTED COMMANDS',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: AppTheme.textMuted,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          ...suggestions.map((s) => GestureDetector(
                onTap: () {
                  _controller.text = s;
                  _sendInput();
                },
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        s.contains('Sign in')
                            ? LucideIcons.logIn
                            : s.contains('Sync all')
                                ? LucideIcons.refreshCw
                                : s.contains('email')
                                    ? LucideIcons.mail
                                    : s.contains('calendar')
                                        ? LucideIcons.calendar
                                        : LucideIcons.arrowRight,
                        size: 14,
                        color: s.contains('Sign in') || s.contains('Sync all')
                            ? AppTheme.accentGreen
                            : AppTheme.textMuted,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        s,
                        style: const TextStyle(
                            fontSize: 13, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    ).withPremiumEntry();
  }

  // ─── Message List ──────────────────────────────────────────────────────────

  Widget _buildMessageList(BuildContext context, AssistantState state) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      physics: const BouncingScrollPhysics(),
      itemCount: state.messages.length,
      itemBuilder: (ctx, index) {
        final msg = state.messages[index];
        return _buildMessageBubble(context, msg);
      },
    );
  }

  Widget _buildMessageBubble(BuildContext context, AssistantMessage msg) {
    final isUser = msg.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.82),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: isUser
                    ? AppTheme.primary
                    : msg.messageType == AssistantMessageType.error
                        ? AppTheme.error.withAlpha(30)
                        : msg.messageType == AssistantMessageType.success
                            ? AppTheme.accentGreen.withAlpha(20)
                            : AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomRight: isUser
                      ? const Radius.circular(4)
                      : const Radius.circular(16),
                  bottomLeft: isUser
                      ? const Radius.circular(16)
                      : const Radius.circular(4),
                ),
                border: isUser
                    ? null
                    : Border.all(
                        color: msg.messageType == AssistantMessageType.error
                            ? AppTheme.error.withAlpha(80)
                            : msg.messageType == AssistantMessageType.success
                                ? AppTheme.accentGreen.withAlpha(60)
                                : AppTheme.secondary.withAlpha(25),
                        width: 1,
                      ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isUser) ...[
                    Icon(
                      msg.messageType == AssistantMessageType.error
                          ? LucideIcons.alertTriangle
                          : msg.messageType == AssistantMessageType.success
                              ? LucideIcons.checkCircle
                              : Icons.auto_awesome,
                      size: 13,
                      color: msg.messageType == AssistantMessageType.error
                          ? AppTheme.error
                          : msg.messageType == AssistantMessageType.success
                              ? AppTheme.accentGreen
                              : AppTheme.secondary,
                    ),
                    const SizedBox(width: 7),
                  ],
                  Flexible(
                    child: Text(
                      msg.text,
                      style: TextStyle(
                        color: isUser ? Colors.white : AppTheme.textPrimary,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (msg.emails != null && msg.emails!.isNotEmpty)
              _buildEmailSummaryCard(msg.emails!),
            if (msg.calendarEvents != null && msg.calendarEvents!.isNotEmpty)
              _buildCalendarSummaryCard(msg.calendarEvents!),
            const SizedBox(height: 2),
            Text(
              DateFormat('h:mm a').format(msg.timestamp),
              style: const TextStyle(fontSize: 9, color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    ).withPremiumEntry(delayMs: 0);
  }

  // ─── Rich Cards ────────────────────────────────────────────────────────────

  Widget _buildEmailSummaryCard(List<GmailMessageData> emails) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.secondary.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.mail, size: 13, color: AppTheme.secondary),
              const SizedBox(width: 6),
              const Text(
                'GMAIL SCAN RESULTS',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.secondary,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...emails.take(5).map((email) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 5, right: 8),
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppTheme.secondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            email.subject,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            email.sender,
                            style: const TextStyle(
                                fontSize: 10, color: AppTheme.textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
          if (emails.length > 5)
            Text(
              '+ ${emails.length - 5} more emails',
              style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
            ),
        ],
      ),
    );
  }

  Widget _buildCalendarSummaryCard(List<CalendarEventData> events) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.accentPurple.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.calendar, size: 13, color: AppTheme.accentPurple),
              const SizedBox(width: 6),
              const Text(
                'GOOGLE CALENDAR EVENTS',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.accentPurple,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...events.take(5).map((event) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.accentPurple.withAlpha(20),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        DateFormat('MMM d').format(event.startTime),
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.accentPurple,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            DateFormat('h:mm a').format(event.startTime),
                            style: const TextStyle(
                                fontSize: 10, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
          if (events.length > 5)
            Text(
              '+ ${events.length - 5} more events',
              style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
            ),
        ],
      ),
    );
  }

  // ─── Thinking Indicator ────────────────────────────────────────────────────

  Widget _buildThinkingIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: AppTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(14).copyWith(
              bottomLeft: const Radius.circular(4),
            ),
            border: Border.all(color: AppTheme.secondary.withAlpha(25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome, size: 12, color: AppTheme.secondary),
              const SizedBox(width: 7),
              _ThinkingDots(controller: _dotCtrl),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.1, end: 0);
  }

  // ─── Input Bar ─────────────────────────────────────────────────────────────

  Widget _buildInputBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.borderFaint)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Type a command (e.g., "Sync all", "List tasks")...',
                  hintStyle: TextStyle(color: AppTheme.textMuted),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                ),
                onSubmitted: (_) => _sendInput(),
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
          ),
          const SizedBox(width: 10),
          AstraPressScale(
            onTap: _sendInput,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.accentPurple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withAlpha(50),
                    blurRadius: 12,
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: const Icon(LucideIcons.send, size: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Thinking Dots ────────────────────────────────────────────────────────────

class _ThinkingDots extends StatelessWidget {
  final AnimationController controller;
  const _ThinkingDots({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (ctx, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i / 3;
            final value = ((controller.value + delay) % 1.0);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: AppTheme.secondary.withAlpha((value * 200 + 55).toInt()),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
