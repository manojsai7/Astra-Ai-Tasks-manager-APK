import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../providers/assistant_provider.dart';
import '../providers/chat_session_provider.dart';
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

  Future<void> _sendInput() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();

    final sessionNotifier = ref.read(chatSessionProvider.notifier);
    var sessionId = ref.read(currentSessionIdProvider);

    if (sessionId == null) {
      final title = text.length > 25 ? '${text.substring(0, 25)}...' : text;
      sessionId = await sessionNotifier.createSession(title: title);
      ref.read(currentSessionIdProvider.notifier).state = sessionId;
    }

    ref.read(assistantStateProvider.notifier).sendCommand(text);
    _scrollToBottom();
  }

  void _showSessionDrawer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (ctx, ref, _) {
            final sessions = ref.watch(chatSessionProvider);
            final currentId = ref.watch(currentSessionIdProvider);

            return Container(
              height: MediaQuery.of(context).size.height * 0.55,
              padding: const EdgeInsets.all(AppTheme.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.messageSquare, size: 18, color: AppTheme.secondary),
                      const SizedBox(width: AppTheme.s8),
                      Text(
                        'Chat Sessions',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppTheme.textMuted),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.s12),
                  if (sessions.isEmpty)
                    const Expanded(
                      child: Center(
                        child: Text(
                          'No chat sessions yet. Tap "New Chat" to start!',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: sessions.length,
                        itemBuilder: (ctx, index) {
                          final session = sessions[index];
                          final isActive = session.id == currentId;

                          return Container(
                            margin: const EdgeInsets.only(bottom: AppTheme.s8),
                            decoration: BoxDecoration(
                              color: isActive ? AppTheme.surfaceElevated : AppTheme.surfaceGlass,
                              borderRadius: BorderRadius.circular(AppTheme.r12),
                              border: Border.all(
                                color: isActive ? AppTheme.primary : AppTheme.borderSubtle,
                                width: isActive ? 1.5 : 1,
                              ),
                            ),
                            child: ListTile(
                              leading: Icon(
                                LucideIcons.bot,
                                color: isActive ? AppTheme.primary : AppTheme.textMuted,
                                size: 20,
                              ),
                              title: Text(
                                session.title,
                                style: TextStyle(
                                  color: isActive ? AppTheme.textPrimary : AppTheme.textSecondary,
                                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                DateFormat('MMM d, h:mm a').format(session.updatedAt),
                                style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                              ),
                              trailing: IconButton(
                                icon: const Icon(LucideIcons.trash2, size: 16, color: AppTheme.error),
                                onPressed: () {
                                  ref.read(chatSessionProvider.notifier).deleteSession(session.id);
                                  if (currentId == session.id) {
                                    ref.read(currentSessionIdProvider.notifier).state = null;
                                    ref.read(assistantStateProvider.notifier).clearMessages();
                                  }
                                },
                              ),
                              onTap: () {
                                ref.read(currentSessionIdProvider.notifier).state = session.id;
                                Navigator.pop(ctx);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: AppTheme.s12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final id = await ref.read(chatSessionProvider.notifier).createSession();
                        ref.read(currentSessionIdProvider.notifier).state = id;
                        ref.read(assistantStateProvider.notifier).clearMessages();
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text(
                        'New Chat Session',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.r12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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

  // ─── Header Component ──────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, AssistantState state) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: const BoxDecoration(
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
                  AppTheme.secondary.withValues(alpha: 0.3),
                  AppTheme.accentPurple.withValues(alpha: 0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.5)),
            ),
            child: const Icon(Icons.auto_awesome, size: 18, color: AppTheme.secondary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ASTRA',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        letterSpacing: 1.5,
                        color: AppTheme.textPrimary,
                        fontSize: 20,
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

          // ─── Actions: History Drawer, New Chat, Logout ─────────────
          IconButton(
            icon: const Icon(LucideIcons.history, size: 18, color: AppTheme.secondary),
            tooltip: 'Chat History',
            onPressed: () => _showSessionDrawer(context),
          ),
          IconButton(
            icon: const Icon(LucideIcons.plusCircle, size: 18, color: AppTheme.primary),
            tooltip: 'New Chat',
            onPressed: () async {
              final id = await ref.read(chatSessionProvider.notifier).createSession();
              ref.read(currentSessionIdProvider.notifier).state = id;
              ref.read(assistantStateProvider.notifier).clearMessages();
            },
          ),
          IconButton(
            icon: const Icon(LucideIcons.logOut, size: 18, color: AppTheme.textMuted),
            tooltip: 'Logout',
            onPressed: () async {
              await ref.read(assistantStateProvider.notifier).handleSignOut();
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('hasSeenAuth');
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/auth');
              }
            },
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  // ─── Empty State Component ─────────────────────────────────────────────────

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
                  AppTheme.secondary.withValues(alpha: 0.25),
                  AppTheme.accentPurple.withValues(alpha: 0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.5)),
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
                ? 'Connected as ${state.userEmail}\nAsk me anything or let me organize your day.'
                : 'Sign in with Google to automatically pull tasks from your emails and calendar.',
            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, height: 1.5),
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
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    ).withPremiumEntry();
  }

  // ─── Message List Component ────────────────────────────────────────────────

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
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: isUser
                    ? AppTheme.primary
                    : msg.messageType == AssistantMessageType.error
                        ? AppTheme.error.withValues(alpha: 0.2)
                        : msg.messageType == AssistantMessageType.success
                            ? AppTheme.accentGreen.withValues(alpha: 0.15)
                            : AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
                  bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
                ),
                border: isUser
                    ? null
                    : Border.all(
                        color: msg.messageType == AssistantMessageType.error
                            ? AppTheme.error.withValues(alpha: 0.4)
                            : msg.messageType == AssistantMessageType.success
                                ? AppTheme.accentGreen.withValues(alpha: 0.3)
                                : AppTheme.secondary.withValues(alpha: 0.2),
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
        border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.mail, size: 13, color: AppTheme.secondary),
              SizedBox(width: 6),
              Text(
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
                            style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
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
        border: Border.all(color: AppTheme.accentPurple.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.calendar, size: 13, color: AppTheme.accentPurple),
              SizedBox(width: 6),
              Text(
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
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.accentPurple.withValues(alpha: 0.2),
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
                            style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
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
            border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.25)),
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

  // ─── Input Bar Component (Fixed UI Padding for Keyboard & Bottom Nav) ──────

  Widget _buildInputBar(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(12, 10, 12, bottomInset > 0 ? bottomInset + 8 : 12),
      decoration: const BoxDecoration(
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
                  hintText: 'Ask ASTRA or type command...',
                  hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 11),
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
                    color: AppTheme.primary.withValues(alpha: 0.3),
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
                color: AppTheme.secondary.withValues(alpha: value * 0.8 + 0.2),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
