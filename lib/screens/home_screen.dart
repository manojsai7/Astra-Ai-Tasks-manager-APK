import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../providers/task_provider.dart';
import '../providers/focus_provider.dart';
import '../models/task.dart';
import '../widgets/premium/premium_card.dart';
import '../widgets/premium/premium_stat_pill.dart';
import '../widgets/premium/premium_progress_bar.dart';
import '../widgets/premium/premium_section_header.dart';
import '../widgets/premium/premium_quick_action.dart';
import '../widgets/premium/premium_timeline_item.dart';
import '../widgets/premium/premium_bottom_nav.dart';
import '../widgets/design_system/astra_insight_card.dart';
import '../providers/message_provider.dart';
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
                const SizedBox(height: AppTheme.s16),

                // ─── Streak Banner ───────────────────────────
                _buildStreakBanner(completed, total),
                const SizedBox(height: AppTheme.s16),

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
                const SizedBox(height: AppTheme.s16),

                // ─── Quick Actions ───────────────────────────
                _buildQuickActions(context),
                const SizedBox(height: AppTheme.s20),

                // ─── Schedule Timeline ───────────────────────
                _buildTimelineSection(context, todayTasks),
                const SizedBox(height: AppTheme.s16),

                // ─── AI Insight Card ─────────────────────────
                AstraInsightCard(
                  insight: _insights[_quoteIndex],
                  primaryAction: 'Got it',
                  secondaryAction: 'Next tip',
                  onSecondary: () => setState(
                      () => _quoteIndex = (_quoteIndex + 1) % _insights.length),
                ).animate().fadeIn(duration: 500.ms, delay: 250.ms),
                const SizedBox(height: AppTheme.s24),
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
                _getGreeting(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 2),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [AppTheme.textPrimary, AppTheme.primaryLight],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ).createShader(bounds),
                child: Text(
                  'MANOJ',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontSize: 28,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                ),
              ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.03, end: 0),
              const SizedBox(height: 2),
              Text(
                high > 0
                    ? '$high urgent task${high > 1 ? 's' : ''} need attention'
                    : pending == 0
                        ? '🎯 All tasks completed!'
                        : '$pending task${pending > 1 ? 's' : ''} remaining today',
                style: TextStyle(
                  fontSize: 12,
                  color: high > 0 ? AppTheme.error : AppTheme.textMuted,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Avatar Ring
        Container(
          padding: const EdgeInsets.all(2.5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppTheme.primary, AppTheme.secondary, AppTheme.accentGreen],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.4),
                blurRadius: 16,
                spreadRadius: -2,
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.background,
            ),
            child: const CircleAvatar(
              radius: 20,
              backgroundColor: AppTheme.surfaceElevated,
              child: Icon(Icons.person_outline, size: 22, color: AppTheme.primary),
            ),
          ),
        ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
      ],
    );
  }

  // ─── Streak Banner Component ───────────────────────────────
  Widget _buildStreakBanner(int completed, int total) {
    final pct = total > 0 ? ((completed / total) * 100).toInt() : 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.s16, vertical: AppTheme.s12),
      decoration: AppTheme.accentGreenCard,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.accentGreen.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppTheme.r12),
            ),
            child: const Icon(
              Icons.local_fire_department,
              size: 24,
              color: AppTheme.accentGreen,
            ),
          ),
          const SizedBox(width: AppTheme.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '$completed',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.accentGreen,
                      ),
                    ),
                    const SizedBox(width: AppTheme.s6),
                    Text(
                      'task${completed != 1 ? 's' : ''} done',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.accentGreen.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Text(
                  total > 0 ? '$pct% plan completed' : 'Add tasks to start your daily plan',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.accentGreen.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 42,
            height: 42,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: total > 0 ? completed / total : 0.0,
                  strokeWidth: 3.5,
                  backgroundColor: AppTheme.borderFaint,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentGreen),
                  strokeCap: StrokeCap.round,
                ),
                Text(
                  '$pct%',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.accentGreen,
                  ),
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
    final progressColor = progress >= 0.8
        ? AppTheme.success
        : progress >= 0.5
            ? AppTheme.warning
            : AppTheme.primary;

    return PremiumCard(
      padding: const EdgeInsets.all(AppTheme.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const PremiumSectionHeader(
                title: 'Today',
                showAccentBar: true,
                accentColor: AppTheme.primary,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceGlass,
                  borderRadius: BorderRadius.circular(AppTheme.r16),
                ),
                child: Text(
                  DateFormat('EEE, MMM d').format(DateTime.now()),
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.s16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$total',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: AppTheme.textPrimary,
                          fontSize: 36,
                          height: 1,
                        ),
                  ),
                  const Text(
                    'total tasks',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                ],
              ),
              const SizedBox(width: AppTheme.s16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: AppTheme.s6,
                      runSpacing: AppTheme.s6,
                      children: [
                        PremiumStatPill(
                          icon: Icons.check_circle_outline,
                          value: '$completed',
                          label: 'done',
                          iconColor: AppTheme.accentGreen,
                        ),
                        PremiumStatPill(
                          icon: Icons.radio_button_unchecked,
                          value: '$pending',
                          label: 'left',
                          iconColor: AppTheme.textMuted,
                        ),
                        if (high > 0)
                          PremiumStatPill(
                            icon: Icons.warning_amber_rounded,
                            value: '$high',
                            label: 'urgent',
                            iconColor: AppTheme.error,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.s12),
                    PremiumProgressBar(
                      value: progress,
                      height: 6,
                      fillColor: progressColor,
                    ),
                    const SizedBox(height: AppTheme.s4),
                    Text(
                      '${(progress * 100).toInt()}% complete',
                      style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.s16),
          const Divider(color: AppTheme.borderFaint, height: 1),
          const SizedBox(height: AppTheme.s12),

          // Mini Stats Row
          Row(
            children: [
              _miniStat(
                icon: Icons.timer_outlined,
                label: 'Focus',
                value: '${focusMins ~/ 60}h ${(focusMins % 60).toString().padLeft(2, '0')}m',
                color: AppTheme.secondary,
              ),
              _divider(),
              _miniStat(
                icon: Icons.priority_high,
                label: 'Urgent',
                value: '$high tasks',
                color: high > 0 ? AppTheme.error : AppTheme.textMuted,
              ),
              _divider(),
              _miniStat(
                icon: Icons.trending_up,
                label: 'Completion',
                value: '${(progress * 100).toInt()}%',
                color: progressColor,
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 100.ms).slideY(begin: 0.03, end: 0);
  }

  Widget _divider() => Container(
        width: 1,
        height: 26,
        margin: const EdgeInsets.symmetric(horizontal: AppTheme.s12),
        color: AppTheme.borderFaint,
      );

  Widget _miniStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Quick Actions Component ───────────────────────────────
  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PremiumSectionHeader(title: 'Quick Actions'),
        const SizedBox(height: AppTheme.s12),
        Row(
          children: [
            PremiumQuickAction(
              icon: Icons.add,
              label: 'Add Task',
              color: AppTheme.primary,
              onTap: () {
                setState(() => _currentIndex = 1); // Jump to Tasks tab
              },
            ),
            const SizedBox(width: AppTheme.s8),
            PremiumQuickAction(
              icon: Icons.auto_awesome,
              label: 'Ask ASTRA',
              color: AppTheme.accentPurple,
              onTap: () {
                setState(() => _currentIndex = 4); // Jump to Assistant tab
              },
            ),
            const SizedBox(width: AppTheme.s8),
            PremiumQuickAction(
              icon: Icons.play_arrow_rounded,
              label: 'Focus',
              color: AppTheme.accentGreen,
              onTap: () {
                setState(() => _currentIndex = 2); // Jump to Focus tab
              },
            ),
            const SizedBox(width: AppTheme.s8),
            PremiumQuickAction(
              icon: Icons.sync,
              label: 'Sync',
              color: AppTheme.secondary,
              onTap: () {
                setState(() => _currentIndex = 4); // Jump to Assistant tab for sync
              },
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
        PremiumSectionHeader(
          title: 'Schedule',
          showAccentBar: true,
          accentColor: AppTheme.secondary,
          trailing: todayTasks.length > 4
              ? TextButton(
                  onPressed: () => setState(() => _currentIndex = 1),
                  child: const Text(
                    'See all →',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : null,
        ),
        const SizedBox(height: AppTheme.s12),
        PremiumCard(
          padding: const EdgeInsets.all(AppTheme.s16),
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
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppTheme.s20),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.calendar_today_outlined, size: 32, color: AppTheme.textMuted),
            SizedBox(height: AppTheme.s8),
            Text(
              'No scheduled tasks',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Add tasks with due times to see your timeline here',
              style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
