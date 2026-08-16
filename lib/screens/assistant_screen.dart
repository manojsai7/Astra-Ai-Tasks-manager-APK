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
import '../widgets/design_system/astra_3d_surface.dart';
import '../widgets/assistant/astra_response_card.dart';
import '../services/email/astra_email_analyzer.dart';

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
          0,
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
                              onTap: () async {
                                ref.read(currentSessionIdProvider.notifier).state = session.id;
                                await ref.read(assistantStateProvider.notifier).loadSessionMessages(session.id);
                                if (ctx.mounted) Navigator.pop(ctx);
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
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: AppTheme.background,
      resizeToAvoidBottomInset: false,
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
            Padding(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: _buildInputBar(context),
            ),
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
        border: Border(bottom: BorderSide(color: AstraColors.borderSoft, width: 1)),
      ),
      child: Row(
        children: [
          // Avatar: charcoal surface + neutral border — no cyan ring
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AstraColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AstraColors.edgeSoft, width: 1),
            ),
            child: Icon(
              Icons.auto_awesome,
              // Muted cyan — accent communicates system, not branding
              color: AstraColors.cyan.withValues(alpha: 0.7),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ASTRA', style: AstraText.displayM(size: 28)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    // State dot indicator
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: state.isLoading
                            ? AstraColors.amber
                            : state.isAuthenticated
                                ? AstraColors.lime
                                : AstraColors.textMuted,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        state.isLoading
                            ? 'Preparing response…'
                            : state.isAuthenticated
                                ? 'Connected · ${state.userEmail}'
                                : 'Tap Sign In to connect Google',
                        style: AstraText.body(size: 13, color: AstraColors.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

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
            // Neutral grey 3D — reference back-button style
            return Astra3DButton(
              height: 44,
              depth: AstraDepth.small,
              palette: AstraMaterials.neutral,
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
      reverse: true,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      physics: const BouncingScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: state.messages.length,
      itemBuilder: (ctx, index) {
        final msg = state.messages[state.messages.length - 1 - index];
        return _buildMessageBubble(context, msg);
      },
    );
  }

  // Returns the semantic accent color for ASTRA response types
  Color _accentFor(AssistantMessageType type) => switch (type) {
        AssistantMessageType.success     => AstraColors.lime,
        AssistantMessageType.error       => AstraColors.red,
        AssistantMessageType.syncResult  => AstraColors.lime,
        AssistantMessageType.emailSummary    => AstraColors.cyan,
        AssistantMessageType.calendarSummary => AstraColors.violet,
        _                               => AstraColors.cyan,
      };

  Widget _buildMessageBubble(BuildContext context, AssistantMessage msg) {
    final isUser = msg.isUser;
    final maxW = MediaQuery.sizeOf(context).width * 0.78;

    if (isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          constraints: BoxConstraints(maxWidth: maxW),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // ── Physical lime user bubble ──────────────────────────
              Astra3DSurface(
                faceColor: AstraDepthColors.limeFace,
                depthColor: AstraDepthColors.limeDepth,
                borderColor: AstraDepthColors.limeBorder,
                depthOffset: AstraDepth.small,
                borderRadius: 16,
                enabled: false, // display only — no interaction
                hapticOnPress: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: SelectionArea(
                    child: Text(
                      msg.text,
                      softWrap: true,
                      overflow: TextOverflow.visible,
                      style: const TextStyle(
                        color: AstraColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('h:mm a').format(msg.timestamp),
                style: const TextStyle(fontSize: 9, color: AstraColors.textMuted),
              ),
            ],
          ),
        ),
      ).withPremiumEntry(delayMs: 0);
    }

    // ── ASTRA response card — structured or plain text ──
    final accent = _accentFor(msg.messageType);
    final accentDepth = switch (msg.messageType) {
      AssistantMessageType.success  => AstraDepthColors.limeDepth,
      AssistantMessageType.syncResult => AstraDepthColors.limeDepth,
      AssistantMessageType.error    => AstraDepthColors.redDepth,
      AssistantMessageType.calendarSummary => AstraDepthColors.violetDepth,
      _                            => AstraDepthColors.cyanDepth,
    };

    if (msg.structured != null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          constraints: BoxConstraints(maxWidth: maxW),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AstraResponseCard(
                response: msg.structured!,
                accent: accent,
                accentDepth: accentDepth,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 4, top: 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => _copyMessage(msg.text),
                      tooltip: 'Copy response',
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(LucideIcons.copy, size: 13, color: AstraColors.textMuted),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat('h:mm a').format(msg.timestamp),
                      style: const TextStyle(fontSize: 9, color: AstraColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ).withPremiumEntry(delayMs: 0);
    }

    // ── Plain Assistant Prose (Natural Conversational Flow) ──
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.88),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Natural left-aligned assistant prose
            Padding(
              padding: const EdgeInsets.only(left: 2, right: 4, top: 2, bottom: 4),
              child: SelectionArea(
                child: msg.messageType == AssistantMessageType.error
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2, right: 8),
                            child: Icon(LucideIcons.alertTriangle, size: 15, color: AstraColors.red),
                          ),
                          Expanded(
                            child: Text(
                              msg.text,
                              softWrap: true,
                              style: const TextStyle(
                                color: AstraColors.red,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w400,
                                height: 1.55,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Text(
                        msg.text,
                        softWrap: true,
                        style: const TextStyle(
                          color: AstraColors.text,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w400,
                          height: 1.55,
                          letterSpacing: 0.1,
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 2, top: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => _copyMessage(msg.text),
                    tooltip: 'Copy response',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(LucideIcons.copy, size: 13, color: AstraColors.textMuted),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('h:mm a').format(msg.timestamp),
                    style: const TextStyle(fontSize: 10, color: AstraColors.textMuted),
                  ),
                ],
              ),
            ),
            if (msg.emailInsights != null && msg.emailInsights!.isNotEmpty)
              _buildEmailInsightsCard(msg.emailInsights!)
            else if (msg.emails != null && msg.emails!.isNotEmpty)
              _buildEmailSummaryCard(msg.emails!),
            if (msg.calendarEvents != null && msg.calendarEvents!.isNotEmpty)
              _buildCalendarSummaryCard(msg.calendarEvents!),
          ],
        ),
      ),
    ).withPremiumEntry(delayMs: 0);
  }

  // ─── Rich Cards ────────────────────────────────────────────────────────────

  Widget _buildEmailInsightsCard(List<EmailInsightItem> insights) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: insights.take(5).map((item) {
        final email = item.email;
        final analysis = item.analysis;
        final isDeadline = analysis.category == EmailCategory.deadline;
        final isEvent = analysis.isEvent;
        final dt = analysis.actionDateTime;

        final badgeColor = isDeadline
            ? const Color(0xFFF59E0B) // Amber
            : (isEvent ? AstraColors.cyan : (analysis.isActionable ? AstraColors.lime : AstraColors.textMuted));

        final badgeText = isDeadline
            ? 'DEADLINE'
            : (analysis.category == EmailCategory.important
                ? (analysis.actionRequired?.toUpperCase() ?? 'IMPORTANT')
                : (analysis.isEvent ? 'EVENT' : (analysis.actionRequired?.toUpperCase() ?? 'EMAIL INSIGHT')));

        return Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AstraColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AstraColors.edgeSoft, width: 1),
            boxShadow: const [
              BoxShadow(color: AstraColors.depth, offset: Offset(0, 3), blurRadius: 0),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Category Badge + Date/Time
              Row(
                children: [
                  Icon(
                    isDeadline
                        ? LucideIcons.alertTriangle
                        : (isEvent ? LucideIcons.calendar : LucideIcons.mail),
                    size: 13,
                    color: badgeColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: badgeColor,
                      letterSpacing: 1.1,
                    ),
                  ),
                  if (dt != null) ...[
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        DateFormat('EEE · h:mm a').format(dt),
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: badgeColor,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),

              // Candidate Title
              Text(
                analysis.suggestedTaskTitle,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AstraColors.text,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),

              // Sender / Subject snippet
              Text(
                'From: ${email.senderName.isNotEmpty ? email.senderName : email.sender}',
                style: const TextStyle(fontSize: 10.5, color: AstraColors.textMuted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              // Reason Tag
              if (analysis.reasons.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  analysis.reasons.first,
                  style: TextStyle(
                    fontSize: 10,
                    color: AstraColors.textMuted.withValues(alpha: 0.8),
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // Action Buttons Row (Add to Tasks / Calendar / Ignore)
              if (analysis.isActionable) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Astra3DSurface(
                      faceColor: AstraDepthColors.limeFace,
                      depthColor: AstraDepthColors.limeDepth,
                      borderColor: AstraDepthColors.limeBorder,
                      depthOffset: AstraDepth.small,
                      borderRadius: 8,
                      onTap: () {
                        ref.read(assistantStateProvider.notifier).addEmailInsightToTasks(
                              email: email,
                              analysis: analysis,
                            );
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.plus, size: 11, color: Colors.black),
                            SizedBox(width: 4),
                            Text(
                              'ADD TO TASKS',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (isEvent)
                      Astra3DSurface(
                        faceColor: AstraDepthColors.cyanFace,
                        depthColor: AstraDepthColors.cyanDepth,
                        borderColor: AstraDepthColors.cyanBorder,
                        depthOffset: AstraDepth.small,
                        borderRadius: 8,
                        onTap: () {
                          ref.read(assistantStateProvider.notifier).addEmailInsightToCalendar(
                                email: email,
                                analysis: analysis,
                              );
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.calendar, size: 11, color: Colors.black),
                              SizedBox(width: 4),
                              Text(
                                'ADD TO CALENDAR',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

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
    // Charcoal card + left cyan accent strip — consistent with ASTRA response card design
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          decoration: BoxDecoration(
            color: AstraColors.surface,
            borderRadius: BorderRadius.circular(14).copyWith(
              bottomLeft: const Radius.circular(4),
            ),
            border: Border.all(color: AstraColors.edgeSoft, width: 1),
            boxShadow: const [
              BoxShadow(color: AstraColors.depth, offset: Offset(0, 3), blurRadius: 0),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13).copyWith(
              bottomLeft: const Radius.circular(3),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Cyan accent strip
                Container(
                  width: 3,
                  height: 36,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AstraColors.cyan, AstraDepthColors.cyanDepth],
                      stops: [0.6, 1.0],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 12,
                        color: AstraColors.cyan.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 8),
                      _ThinkingDots(controller: _dotCtrl),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.1, end: 0);
  }

  // ─── Input Bar Component (Fixed UI Padding for Keyboard & Bottom Nav) ──────

  Widget _buildInputBar(BuildContext context) {
    final assistantState = ref.watch(assistantStateProvider);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      decoration: const BoxDecoration(
        color: AstraColors.surface,
        border: Border(top: BorderSide(color: AstraColors.edgeSoft, width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AstraColors.surface2,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AstraColors.edgeSoft, width: 1),
              ),
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: AstraColors.text, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Ask ASTRA or type a command…',
                  hintStyle: TextStyle(color: AstraColors.textMuted, fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onSubmitted: (_) => _sendInput(),
                textCapitalization: TextCapitalization.sentences,
                maxLines: null,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Send / Stop button: toggle based on assistant isLoading state
          if (assistantState.isLoading)
            Astra3DIconButton(
              icon: LucideIcons.square,
              iconSize: 16,
              size: 46,
              depth: AstraDepth.small,
              faceColor: const Color(0xFFEF4444),
              depthColor: const Color(0xFFB91C1C),
              borderColor: const Color(0xFFDC2626),
              iconColor: Colors.white,
              borderRadius: AstraRadii.md,
              onTap: () {
                ref.read(assistantStateProvider.notifier).stopCommand();
              },
            )
          else
            Astra3DIconButton(
              icon: LucideIcons.send,
              iconSize: 18,
              size: 46,
              depth: AstraDepth.small,
              faceColor: AstraDepthColors.limeFace,
              depthColor: AstraDepthColors.limeDepth,
              borderColor: AstraDepthColors.limeBorder,
              iconColor: Colors.black,
              borderRadius: AstraRadii.md,
              onTap: _sendInput,
            ),
        ],
      ),
    );
  }
}

// ─── Thinking Dots ────────────────────────────────────────────────────────────

enum _ChatAction { history, newChat, logout }

class _ChatMenuItem extends StatelessWidget {
  const _ChatMenuItem({required this.icon, required this.label, this.color = AstraColors.textPrimary});
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
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                // Muted cyan dots — no glow, just pulse via opacity
                color: AstraColors.cyan.withValues(alpha: value * 0.7 + 0.3),
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

