import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/task_provider.dart';
import '../providers/focus_provider.dart';
import '../models/task.dart';
import '../theme/app_theme.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _quoteController;
  int _quoteIndex = 0;

  final List<String> _quotes = [
    'Your future is created by today\'s actions.',
    'Progress over perfection. Every step counts.',
    'Small daily wins build big results over time.',
    'Start where you are. Use what you have.',
    'Focus on the step, not the staircase.',
    'Discipline is choosing between now and later.',
    'The best time to start was yesterday.',
    'Done is better than perfect. Keep moving.',
  ];

  @override
  void initState() {
    super.initState();
    _quoteController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    // Rotate quote every 12 seconds
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 12));
      if (mounted) {
        setState(() {
          _quoteIndex = (_quoteIndex + 1) % _quotes.length;
        });
        _quoteController.forward(from: 0);
      }
      return mounted;
    });
  }

  @override
  void dispose() {
    _quoteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tasksNotifier = ref.watch(taskNotifierProvider);
    final tasksFuture = ref.watch(taskListProvider).asData?.value ?? [];
    final tasks = tasksNotifier.isNotEmpty ? tasksNotifier : tasksFuture;
    final focusStats = ref.watch(focusStatsProvider);

    final pending = tasks.where((t) => !t.isCompleted).length;
    final high = tasks.where((t) => t.priority == 'high' && !t.isCompleted).length;
    final completed = tasks.where((t) => t.isCompleted).length;
    final total = tasks.length;
    final focusHours = (focusStats.totalMinutes) ~/ 60;
    final focusMinutes = (focusStats.totalMinutes) % 60;
    final progress = total > 0 ? completed / total : 0.0;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.background,
              AppTheme.surface,
            ],
            stops: const [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header – Premium Executive
                _buildPremiumHeader(context),
                const SizedBox(height: 16),

                // Stats with Progress
                _buildPremiumStats(
                  context,
                  total: total,
                  pending: pending,
                  high: high,
                  completed: completed,
                  progress: progress,
                  focusHours: focusHours,
                  focusMinutes: focusMinutes,
                ),
                const SizedBox(height: 16),

                // Quick Actions – Clean Labels
                _buildPremiumActions(context),
                const SizedBox(height: 20),

                // Today's Schedule – Timeline Style
                _buildTimelineSection(context, ref, tasks),
                const Spacer(),

                // Rotating Quote – Professional Footer
                _buildPremiumQuote(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Premium Header ────────────────────────────────────────

  Widget _buildPremiumHeader(BuildContext context) {
    final hour = DateTime.now().hour;
    String greeting = 'Good Morning';
    if (hour >= 12 && hour < 17) greeting = 'Good Afternoon';
    if (hour >= 17 && hour < 21) greeting = 'Good Evening';
    if (hour >= 21) greeting = 'Good Night';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$greeting,',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w400,
                fontSize: 15,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Manoj',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Plan smart. Focus deep. Achieve more.',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.textMuted.withAlpha(178),
                fontSize: 12,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        // Premium Avatar with gradient ring
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppTheme.primary, AppTheme.accent, AppTheme.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withAlpha(51),
                blurRadius: 20,
                spreadRadius: -5,
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
              radius: 24,
              backgroundColor: AppTheme.surfaceElevated,
              child: Icon(
                LucideIcons.user,
                size: 26,
                color: AppTheme.primary,
              ),
            ),
          ),
        ).animate().scale(
          duration: 1000.ms,
          curve: Curves.elasticOut,
        ),
      ],
    );
  }

  // ─── Premium Stats with Progress ──────────────────────────

  Widget _buildPremiumStats(
    BuildContext context, {
    required int total,
    required int pending,
    required int high,
    required int completed,
    required double progress,
    required int focusHours,
    required int focusMinutes,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main Task Card with Progress
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.surfaceElevated.withAlpha(230),
                  AppTheme.surface.withAlpha(178),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.primary.withAlpha(20),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withAlpha(10),
                  blurRadius: 30,
                  spreadRadius: -10,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tasks',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$total',
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontSize: 28,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$pending pending',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                // Progress Ring
                SizedBox(
                  width: 56,
                  height: 56,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 4,
                        backgroundColor: AppTheme.surfaceElevated,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progress >= 0.8
                              ? AppTheme.success
                              : progress >= 0.5
                              ? AppTheme.warning
                              : AppTheme.primary,
                        ),
                      ).animate().scale(
                        duration: 600.ms,
                        curve: Curves.elasticOut,
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Priority Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.surfaceElevated.withAlpha(230),
                  AppTheme.surface.withAlpha(178),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: high > 0 ? AppTheme.error.withAlpha(38) : AppTheme.textMuted.withAlpha(13),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      high > 0 ? LucideIcons.alertTriangle : LucideIcons.flag,
                      size: 14,
                      color: high > 0 ? AppTheme.error : AppTheme.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Priority',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  high > 0 ? '$high' : '0',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontSize: 22,
                    color: high > 0 ? AppTheme.error : AppTheme.textMuted,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  high > 0 ? '${high > 1 ? 'tasks' : 'task'} flagged' : 'No flags today',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.textMuted.withAlpha(153),
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Focus Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.surfaceElevated.withAlpha(230),
                  AppTheme.surface.withAlpha(178),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.accent.withAlpha(20),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      LucideIcons.timer,
                      size: 14,
                      color: AppTheme.accent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Focus',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${focusHours}h ${focusMinutes.toString().padLeft(2, '0')}m',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontSize: 20,
                    color: AppTheme.accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Today',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.textMuted.withAlpha(153),
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Premium Quick Actions ────────────────────────────────

  Widget _buildPremiumActions(BuildContext context) {
    return Row(
      children: [
        _PremiumActionButton(
          icon: LucideIcons.share2,
          label: 'Share',
          color: AppTheme.primary,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Share text from WhatsApp to ASTRA to add to Inbox!')),
            );
          },
        ),
        const SizedBox(width: 6),
        _PremiumActionButton(
          icon: LucideIcons.plus,
          label: 'Add Task',
          color: AppTheme.accent,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Switch to Tasks tab to add tasks')),
            );
          },
        ),
        const SizedBox(width: 6),
        _PremiumActionButton(
          icon: LucideIcons.play,
          label: 'Start Focus',
          color: AppTheme.success,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Switch to Focus tab to start timer')),
            );
          },
        ),
        const SizedBox(width: 6),
        _PremiumActionButton(
          icon: LucideIcons.messageSquare,
          label: 'Ask Astra',
          color: AppTheme.warning,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Switch to Assistant tab to chat')),
            );
          },
        ),
      ],
    );
  }

  // ─── Timeline Section ──────────────────────────────────────

  Widget _buildTimelineSection(BuildContext context, WidgetRef ref, List<Task> tasks) {
    final todayTasks = tasks
        .where((t) => !t.isCompleted && t.dueDate != null)
        .toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              LucideIcons.calendar,
              size: 14,
              color: AppTheme.textMuted,
            ),
            const SizedBox(width: 8),
            Text(
              'Today',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.textMuted.withAlpha(20),
                  width: 1,
                ),
              ),
              child: Text(
                DateFormat('MMM d, yyyy').format(DateTime.now()),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        todayTasks.isEmpty
            ? Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.surfaceElevated.withAlpha(102),
                      AppTheme.surface.withAlpha(51),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withAlpha(8),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        LucideIcons.checkCircle2,
                        size: 28,
                        color: AppTheme.textMuted.withAlpha(38),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '✨ All clear!',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textMuted,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'No tasks scheduled for today',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.textMuted.withAlpha(128),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : Column(
                children: [
                  ...todayTasks.take(4).map((task) {
                    return _TimelineTaskTile(task: task);
                  }),
                  if (todayTasks.length > 4)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'View Full Schedule →',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppTheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
      ],
    );
  }

  // ─── Premium Quote Footer ──────────────────────────────────

  Widget _buildPremiumQuote(BuildContext context) {
    final quote = _quotes[_quoteIndex];
    return AnimatedBuilder(
      animation: _quoteController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _quoteController,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            child: Row(
              children: [
                Icon(
                  LucideIcons.quote,
                  size: 14,
                  color: AppTheme.primary.withAlpha(30),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    quote,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.textMuted.withAlpha(128),
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.3,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Premium Action Button (with Scale Animation) ──────────

class _PremiumActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _PremiumActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_PremiumActionButton> createState() => _PremiumActionButtonState();
}

class _PremiumActionButtonState extends State<_PremiumActionButton> with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTapDown: (_) => _scaleController.forward(),
        onTapUp: (_) => _scaleController.reverse(),
        onTapCancel: () => _scaleController.reverse(),
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.surfaceElevated.withAlpha(204),
                      AppTheme.surface.withAlpha(153),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.color.withAlpha(20),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withAlpha(10),
                      blurRadius: 15,
                      spreadRadius: -5,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      widget.icon,
                      size: 18,
                      color: widget.color,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.label,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.textMuted.withAlpha(204),
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── Timeline Task Tile ─────────────────────────────────────

class _TimelineTaskTile extends StatelessWidget {
  final Task task;

  const _TimelineTaskTile({required this.task});

  @override
  Widget build(BuildContext context) {
    final color = task.priority == 'high'
        ? AppTheme.error
        : task.priority == 'medium'
        ? AppTheme.warning
        : AppTheme.accent;

    final category = task.priority == 'high'
        ? 'Deadline'
        : task.priority == 'medium'
        ? 'Important'
        : 'General';

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.surfaceElevated.withAlpha(178),
            AppTheme.surface.withAlpha(128),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withAlpha(15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Time column
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                task.dueDate != null
                    ? DateFormat('h:mm a').format(task.dueDate!)
                    : '--:--',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                width: 1.5,
                height: 8,
                color: AppTheme.textMuted.withAlpha(25),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Priority indicator dot
          Container(
            width: 4,
            height: 28,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          // Task details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Text(
                      category,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: color.withAlpha(204),
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (task.dueDate != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '• ${DateFormat('MMM d').format(task.dueDate!)}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.textMuted.withAlpha(128),
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Duration (placeholder)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '1h',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.textMuted.withAlpha(128),
                fontSize: 8,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(
      duration: 400.ms,
      delay: Duration(milliseconds: 50 * (task.id.hashCode % 5)),
    ).slideY(begin: 0.03, end: 0);
  }
}
