import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../providers/task_provider.dart';
import '../providers/focus_provider.dart';
import '../models/task.dart';
import '../widgets/design_system/astra_card.dart';
import '../widgets/premium/premium_timeline_item.dart';
import '../widgets/premium/premium_bottom_nav.dart';
import '../widgets/design_system/astra_3d_button.dart';
import '../widgets/design_system/astra_section_header.dart';
import '../widgets/design_system/astra_insight_card.dart';
import '../providers/message_provider.dart';
import '../providers/assistant_provider.dart';
import 'tasks_screen.dart';
import 'focus_screen.dart';
import 'panchang_screen.dart';
import 'assistant_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _scaleController;
  int _quoteIndex = 0;
  static const MethodChannel _shareChannel =
      MethodChannel('dev.codehunters.astra/share_bridge');

  final List<String> _insights = [
    'You tend to complete high-priority tasks faster in the morning.',
    'Adding due times improves your completion rate significantly.',
    'Short focus sessions work better for you on busy days.',
    'Your most productive window appears to be the evening.',
    'Batch similar tasks together to reduce context-switching.',
  ];

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();

    _initShareListener();

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 12));
      if (mounted) {
        setState(() => _quoteIndex = (_quoteIndex + 1) % _insights.length);
      }
      return mounted;
    });
  }

  void _initShareListener() {
    _shareChannel.invokeMethod<String>('getInitialShareText').then((text) {
      if (text != null && text.isNotEmpty) {
        _handleSharedText(text);
      }
    }).catchError((_) {});

    _shareChannel.setMethodCallHandler((call) async {
      if (call.method == 'onShareReceived') {
        final text = call.arguments as String?;
        if (text != null && text.isNotEmpty) {
          _handleSharedText(text);
        }
      }
    });
  }

  void _handleSharedText(String text) {
    ref.read(messageNotifierProvider.notifier).addMessage(text);
    if (mounted) {
      setState(() {
        _currentIndex = 4; // Navigate to Assistant tab
      });
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final h = DateTime.now().hour;
    if (h < 5) return 'Good Night';
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    if (h < 21) return 'Good Evening';
    return 'Good Night';
  }

  Color _priorityColor(String p) => switch (p) {
        'high' => AppTheme.error,
        'medium' => AppTheme.warning,
        _ => AppTheme.secondary,
      };

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildDashboardView(context),
      const TasksScreen(),
      const FocusScreen(),
      const PanchangScreen(),
      const AssistantScreen(),
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: PremiumBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) async {
          await HapticFeedback.selectionClick();
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildDashboardView(BuildContext context) {
    final tasksAsync = ref.watch(taskListProvider);
    final focusStats = ref.watch(focusStatsProvider);

    return SafeArea(
      child: tasksAsync.when(
        loading: () => _buildLoadingState(),
        error: (err, _) => _buildErrorState(err),
        data: (tasks) => _buildDashboardContent(context, tasks, focusStats.totalMinutes),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppTheme.primary,
            strokeWidth: 2,
          ),
          SizedBox(height: 16),
          Text(
            'Loading your plan...',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object err) {
    return Center(
      child: Text(
        'Error: $err',
        style: const TextStyle(color: AppTheme.error, fontSize: 13),
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context, List<Task> tasks, int focusMins) {
    final pending = tasks.where((t) => !t.isCompleted).length;
    final high = tasks.where((t) => t.priority == 'high' && !t.isCompleted).length;
    final completed = tasks.where((t) => t.isCompleted).length;
    final total = tasks.length;
    final progress = total > 0 ? completed / total : 0.0;
    final todayTasks = tasks
        .where((t) => !t.isCompleted && t.dueDate != null)
        .toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));

    return RefreshIndicator(
      color: AppTheme.primary,
      backgroundColor: AppTheme.surfaceElevated,
      onRefresh: () async {
        ref.read(taskNotifierProvider.notifier).loadTasks();
      },
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.s20, vertical: AppTheme.s12),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ─── Header ──────────────────────────────────
                _buildHeader(context, pending, high),
                const SizedBox(height: 24),

                // ─── Progress Card ───────────────────────────
                _buildStreakBanner(completed, total),
                const SizedBox(height: 24),

                // ─── Today Hero Card ─────────────────────────
                _buildTodayCard(
                  context,
                  total: total,
                  completed: completed,
                  pending: pending,
                  progress: progress,
                  focusMins: focusMins,
                  high: high,
                ),
                const SizedBox(height: 26),

                // ─── Quick Actions ───────────────────────────
                _buildQuickActions(context),
                const SizedBox(height: 30),

                // ─── Schedule Timeline ───────────────────────
                _buildTimelineSection(context, todayTasks),
                const SizedBox(height: 26),

                // ─── AI Insight Card ─────────────────────────
                AstraInsightCard(
                  insight: _insights[_quoteIndex],
                  primaryAction: 'Got it',
                  secondaryAction: 'Next tip',
                  onSecondary: () => setState(
                      () => _quoteIndex = (_quoteIndex + 1) % _insights.length),
                ).animate().fadeIn(duration: 500.ms, delay: 250.ms),
                const SizedBox(height: 30),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Header Component ──────────────────────────────────────
  Widget _buildHeader(BuildContext context, int pending, int high) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getGreeting().toUpperCase(),
                style: AstraText.label(size: 15, color: AstraColors.textMuted),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  'MANOJ',
                  style: AstraText.displayL(size: 46, color: AstraColors.textPrimary),
                ),
              ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.03, end: 0),
              const SizedBox(height: 6),
              Text(
                high > 0
                    ? '$high urgent task${high > 1 ? 's' : ''} need attention'
                    : pending == 0
                        ? '🎯 All tasks completed!'
                        : '$pending task${pending > 1 ? 's' : ''} remaining today',
                style: AstraText.body(
                  size: 15,
                  color: high > 0 ? AstraColors.red : AstraColors.textMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        // Tactile Profile Icon Button
        GestureDetector(
          onTap: () => _showProfileSheet(context),
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: AstraColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AstraColors.edge, width: 1),
              boxShadow: const [
                BoxShadow(color: AstraColors.depth, offset: Offset(0, 4), blurRadius: 0),
              ],
            ),
            child: const Icon(Icons.person_outline_rounded, color: AstraColors.lime, size: 34),
          ),
        ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
      ],
    );
  }

  void _showProfileSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AstraColors.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(radius: 28, backgroundColor: AstraColors.surface2, child: Icon(Icons.person_outline_rounded, color: AstraColors.lime, size: 30)),
              const SizedBox(height: 12),
              Text('MANOJ', style: AstraText.displayM(size: 28)),
              const SizedBox(height: 4),
              Text('Manage your ASTRA account', style: AstraText.body(size: 13, color: AstraColors.textMuted)),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.logout, color: AstraColors.red),
                title: Text('Sign out', style: AstraText.metric(color: AstraColors.red, size: 15)),
                onTap: () async {
                  final navigator = Navigator.of(context);
                  Navigator.pop(sheetContext);
                  await ref.read(assistantStateProvider.notifier).handleSignOut();
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('hasSeenAuth');
                  if (mounted) navigator.pushReplacementNamed('/auth');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Streak Progress Card Component ───────────────────────
  Widget _buildStreakBanner(int completed, int total) {
    final pct = total > 0 ? ((completed / total) * 100).toInt() : 0;

    return AstraCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFF35461B),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              size: 34,
              color: AstraColors.lime,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$completed',
                        style: AstraText.displayL(size: 42, color: AstraColors.lime),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'TASKS DONE',
                        style: AstraText.label(size: 13, color: AstraColors.textPrimary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$pct% PLAN COMPLETED',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AstraText.label(size: 12, color: AstraColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 58,
            height: 58,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: total > 0 ? completed / total : 0.0,
                  strokeWidth: 7,
                  backgroundColor: AstraColors.surface3,
                  valueColor: const AlwaysStoppedAnimation(AstraColors.lime),
                  strokeCap: StrokeCap.round,
                ),
                Text(
                  '$pct%',
                  style: AstraText.label(size: 11, color: AstraColors.lime),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 80.ms).slideY(begin: 0.04, end: 0);
  }

  // ─── Today Hero Card Component ─────────────────────────────
  Widget _buildTodayCard(
    BuildContext context, {
    required int total,
    required int completed,
    required int pending,
    required double progress,
    required int focusMins,
    required int high,
  }) {
    return AstraCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(width: 4, height: 31, color: AstraColors.lime),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'TODAY',
                  style: AstraText.displayM(size: 30),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AstraColors.surface2,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AstraColors.edgeSoft),
                ),
                child: Text(
                  DateFormat('EEE, MMM d').format(DateTime.now()).toUpperCase(),
                  style: AstraText.label(size: 11, color: AstraColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$total', style: AstraText.displayXL(size: 58)),
                  Text('TOTAL TASKS', style: AstraText.label(size: 12)),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Pills row — Wrap prevents right-edge overflow
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _miniPill(Icons.check_circle_outline, '$completed DONE', AstraColors.lime),
                        _miniPill(Icons.radio_button_unchecked, '$pending LEFT', AstraColors.textMuted),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Progress bar stretches full available width
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: AstraColors.surface3,
                        valueColor: const AlwaysStoppedAnimation(AstraColors.lime),
                      ),
                    ),
                    // Removed redundant "% COMPLETE" label — already in streak banner & metrics tile
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(color: AstraColors.edgeSoft),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _metricTile(
                  Icons.timer_outlined,
                  'FOCUS',
                  '${focusMins ~/ 60}h ${(focusMins % 60).toString().padLeft(2, '0')}m',
                  AstraColors.cyan,
                ),
              ),
              _divider(),
              Expanded(
                child: _metricTile(
                  Icons.priority_high_rounded,
                  'URGENT',
                  '$high TASKS',
                  high > 0 ? AstraColors.red : AstraColors.textMuted,
                ),
              ),
              _divider(),
              Expanded(
                child: _metricTile(
                  Icons.trending_up_rounded,
                  'COMPLETION',
                  '${(progress * 100).toInt()}%',
                  AstraColors.lime,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 100.ms).slideY(begin: 0.03, end: 0);
  }

  Widget _miniPill(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AstraColors.surface2,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AstraColors.edgeSoft),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(text, style: AstraText.label(size: 11, color: AstraColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 42,
        color: AstraColors.edgeSoft,
        margin: const EdgeInsets.symmetric(horizontal: 8),
      );

  Widget _metricTile(IconData icon, String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(label, style: AstraText.label(size: 11)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value, style: AstraText.body(size: 15, color: color)),
        ),
      ],
    );
  }

  // ─── Quick Actions Component ───────────────────────────────
  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AstraSectionHeader(title: 'QUICK ACTIONS'),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Astra3DButton(
                height: 62,
                expand: true,
                depth: AstraDepth.medium,
                color: AstraColors.surface2,
                textColor: AstraColors.textPrimary,
                onTap: () => setState(() => _currentIndex = 1),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_rounded, size: 24, color: AstraColors.lime),
                      const SizedBox(height: 4),
                      Text('ADD TASK', style: AstraText.label(size: 9, color: AstraColors.textPrimary)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Astra3DButton(
                height: 62,
                expand: true,
                depth: AstraDepth.medium,
                color: AstraColors.surface2,
                textColor: AstraColors.textPrimary,
                onTap: () => setState(() => _currentIndex = 4),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.auto_awesome, size: 24, color: AstraColors.violet),
                      const SizedBox(height: 4),
                      Text('ASK ASTRA', style: AstraText.label(size: 9, color: AstraColors.textPrimary)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Astra3DButton(
                height: 62,
                expand: true,
                depth: AstraDepth.medium,
                color: AstraColors.surface2,
                textColor: AstraColors.textPrimary,
                onTap: () => setState(() => _currentIndex = 2),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.play_arrow_rounded, size: 24, color: AstraColors.lime),
                      const SizedBox(height: 4),
                      Text('FOCUS', style: AstraText.label(size: 9, color: AstraColors.textPrimary)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Astra3DButton(
                height: 62,
                expand: true,
                depth: AstraDepth.medium,
                color: AstraColors.surface2,
                textColor: AstraColors.textPrimary,
                onTap: () => setState(() => _currentIndex = 4),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.sync_rounded, size: 24, color: AstraColors.cyan),
                      const SizedBox(height: 4),
                      Text('SYNC', style: AstraText.label(size: 9, color: AstraColors.textPrimary)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 500.ms, delay: 150.ms);
  }

  // ─── Timeline Section Component ────────────────────────────
  Widget _buildTimelineSection(BuildContext context, List<Task> todayTasks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AstraSectionHeader(
          title: 'SCHEDULE',
          action: todayTasks.length > 4 ? 'SEE ALL →' : null,
          onActionTap: () => setState(() => _currentIndex = 1),
        ),
        const SizedBox(height: 14),
        AstraCard(
          padding: const EdgeInsets.all(16),
          child: todayTasks.isEmpty
              ? _buildEmptyTimeline()
              : Column(
                  children: todayTasks.take(4).toList().asMap().entries.map((e) {
                    final task = e.value;
                    final isLast = e.key == (todayTasks.take(4).length - 1);
                    return PremiumTimelineItem(
                      time: task.dueDate != null
                          ? DateFormat('h:mm a').format(task.dueDate!)
                          : '—',
                      title: task.title,
                      subtitle: task.priority == 'high'
                          ? '⚠ High priority'
                          : task.description,
                      nodeColor: _priorityColor(task.priority),
                      isLast: isLast,
                      isCompleted: task.isCompleted,
                    );
                  }).toList(),
                ),
        ),
      ],
    ).animate().fadeIn(duration: 500.ms, delay: 200.ms);
  }

  Widget _buildEmptyTimeline() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 32, color: AstraColors.textMuted),
            const SizedBox(height: 8),
            Text('No scheduled tasks', style: AstraText.body(size: 14, color: AstraColors.textMuted)),
            const SizedBox(height: 4),
            Text('Add tasks with due times to see your schedule timeline here', style: AstraText.caption(size: 11), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

