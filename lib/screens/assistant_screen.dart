import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../widgets/design_system/astra_card.dart';
import '../providers/assistant_provider.dart';
import '../providers/chat_session_provider.dart';
import '../features/scheduler/data/services/gmail_sync_service.dart';
import '../features/scheduler/data/services/calendar_sync_service.dart';
import '../core/motion.dart';
import '../widgets/design_system/astra_3d_button.dart';

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

  Future<void> _copyMessage(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Response copied'), duration: Duration(seconds: 2)),
    );
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
                  Astra3DButton(
                    expand: true,
                    icon: Icons.add,
                    label: 'New chat session',
                    onPressed: () async {
                        final id = await ref.read(chatSessionProvider.notifier).createSession();
                        ref.read(currentSessionIdProvider.notifier).state = id;
                        ref.read(assistantStateProvider.notifier).clearMessages();
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
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

  // ─── Header Component ──────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, AssistantState state) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: const BoxDecoration(
        color: AstraColors.background,
        border: Border(bottom: BorderSide(color: AstraColors.borderSoft)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AstraColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AstraColors.cyan, width: 1),
            ),
            child: const Icon(Icons.auto_awesome, color: AstraColors.cyan, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ASTRA', style: AstraText.displayM(size: 28)),
                const SizedBox(height: 2),
                Text(
                  state.isLoading
                      ? 'Thinking...'
                      : state.isAuthenticated
                          ? 'Ready · Connected (${state.userEmail})'
                          : 'Ready · Tap Sign In to connect Google',
                  style: AstraText.body(
                    size: 13,
                    color: state.isLoading
                        ? AstraColors.cyan
                        : state.isAuthenticated
                            ? AstraColors.lime
                            : AstraColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // ─── Actions: History Drawer, New Chat, Logout ─────────────
          PopupMenuButton<_ChatAction>(
            tooltip: 'Chat options',
            icon: const Icon(Icons.more_horiz, color: AstraColors.textPrimary),
            color: AstraColors.surface2,
            onSelected: (action) async {
              switch (action) {
                case _ChatAction.history:
                  _showSessionDrawer(context);
                  break;
                case _ChatAction.newChat:
                  final id = await ref.read(chatSessionProvider.notifier).createSession();
                  ref.read(currentSessionIdProvider.notifier).state = id;
                  ref.read(assistantStateProvider.notifier).clearMessages();
                  break;
                case _ChatAction.logout:
                  await ref.read(assistantStateProvider.notifier).handleSignOut();
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('hasSeenAuth');
                  if (context.mounted) Navigator.of(context).pushReplacementNamed('/auth');
                  break;
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: _ChatAction.history, child: _ChatMenuItem(icon: LucideIcons.history, label: 'Chat history')),
              PopupMenuItem(value: _ChatAction.newChat, child: _ChatMenuItem(icon: LucideIcons.plusCircle, label: 'New chat')),
              PopupMenuDivider(),
              PopupMenuItem(value: _ChatAction.logout, child: _ChatMenuItem(icon: LucideIcons.logOut, label: 'Sign out', color: AstraColors.red)),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  // ─── Empty State Component ─────────────────────────────────────────────────

  Widget _buildEmptyState(BuildContext context, AssistantState state) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      physics: const BouncingScrollPhysics(),
      children: [
        // Ready Card
        AstraCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.auto_awesome, color: AstraColors.cyan, size: 28),
              const SizedBox(height: 14),
              Text('Your assistant is ready.', style: AstraText.body(size: 20)),
              const SizedBox(height: 8),
              Text(
                state.isAuthenticated
                    ? 'Connected as ${state.userEmail}.\nAsk about tasks, calendar, mail, focus sessions or Panchang.'
                    : 'Ask about tasks, calendar, mail, focus sessions or Panchang.',
                style: AstraText.body(size: 15, color: AstraColors.textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Quick Commands Header & 3D Buttons
        Text('QUICK COMMANDS', style: AstraText.displayM(size: 28)),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            if (!state.isAuthenticated) 'SIGN IN WITH GOOGLE',
            'SYNC ALL',
            'LAST MAIL',
            'TODAY\'S TASKS',
            'TOMORROW PANCHANG',
          ].map((cmd) {
            return Astra3DButton(
              height: 46,
              depth: AstraDepth.small,
              color: AstraColors.surface2,
              textColor: AstraColors.textPrimary,
              onTap: () {
                _controller.text = cmd;
                _sendInput();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(cmd, style: AstraText.label(size: 11, color: AstraColors.textPrimary)),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 30),

        // System Status Card
        AstraCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SYSTEM STATUS', style: AstraText.displayM(size: 24)),
              const SizedBox(height: 14),
              _SystemRow('Intent engine', 'Ready', AstraColors.lime),
              _SystemRow('Tool routing', 'Ready', AstraColors.lime),
              _SystemRow('Panchang brain', 'Ready', AstraColors.lime),
              _SystemRow('Fallback model', 'Standby', AstraColors.amber),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 500.ms);
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
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
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
                    child: SelectionArea(
                      child: Text(
                        msg.text,
                        softWrap: true,
                        overflow: TextOverflow.visible,
                        style: TextStyle(
                          color: isUser ? Colors.black : AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (!isUser)
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => _copyMessage(msg.text),
                  tooltip: 'Copy response',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(LucideIcons.copy, size: 14, color: AppTheme.textMuted),
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
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
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
              child: const Icon(LucideIcons.send, size: 18, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Thinking Dots ────────────────────────────────────────────────────────────

enum _ChatAction { history, newChat, logout }

class _ChatMenuItem extends StatelessWidget {
  const _ChatMenuItem({required this.icon, required this.label, this.color = AppTheme.textPrimary});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      );
}

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

class _SystemRow extends StatelessWidget {
  const _SystemRow(this.title, this.status, this.color);
  final String title;
  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(title, style: AstraText.body(size: 15))),
          Text(status, style: AstraText.label(size: 11, color: color)),
        ],
      ),
    );
  }
}

