import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/task_provider.dart';
import '../providers/focus_provider.dart';
import '../models/task.dart';
import '../theme/app_theme.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksNotifier = ref.watch(taskNotifierProvider);
    final tasksFuture = ref.watch(taskListProvider).asData?.value ?? [];
    final tasks = tasksNotifier.isNotEmpty ? tasksNotifier : tasksFuture;
    final focusStats = ref.watch(focusStatsProvider);

    final pending = tasks.where((t) => !t.isCompleted).length;
    final high = tasks.where((t) => t.priority == 'high' && !t.isCompleted).length;
    final completed = tasks.where((t) => t.isCompleted).length;
    final focusHours = (focusStats.totalMinutes) ~/ 60;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(context, ref),
              const SizedBox(height: 24),
              // Stats Grid
              _buildStatsGrid(context, pending, high, completed, focusHours),
              const SizedBox(height: 20),
              // Quick Actions
              _buildQuickActions(context),
              const SizedBox(height: 24),
              // Today's Schedule
              _buildTodaySection(context, ref, tasks),
              const Spacer(),
              // Motivational Quote
              _buildMotivationalQuote(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
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
            Row(
              children: [
                Icon(
                  LucideIcons.sun,
                  size: 16,
                  color: AppTheme.textMuted,
                ),
                const SizedBox(width: 8),
                Text(
                  greeting,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Manoj',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [AppTheme.primary, AppTheme.accent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.background,
            ),
            child: const CircleAvatar(
              radius: 22,
              backgroundColor: AppTheme.surfaceElevated,
              child: Icon(
                LucideIcons.user,
                size: 24,
                color: AppTheme.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context, int pending, int high, int completed, int focusHours) {
    return Row(
      children: [
        _StatCard(
          icon: LucideIcons.checkSquare,
          value: '$pending',
          label: 'Tasks',
          subtitle: completed > 0 ? '$completed done' : 'No tasks',
          color: AppTheme.primary,
          glowColor: AppTheme.primary.withAlpha(38),
          flex: 2,
        ),
        const SizedBox(width: 12),
        _StatCard(
          icon: LucideIcons.flag,
          value: '$high',
          label: 'Priority',
          subtitle: high > 0 ? 'High priority' : 'All clear',
          color: AppTheme.error,
          glowColor: AppTheme.error.withAlpha(38),
          flex: 1,
        ),
        const SizedBox(width: 12),
        _StatCard(
          icon: LucideIcons.timer,
          value: '$focusHours',
          label: 'Focus',
          subtitle: '${focusHours}h logged',
          color: AppTheme.accent,
          glowColor: AppTheme.accent.withAlpha(38),
          flex: 1,
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        _ActionButton(
          icon: LucideIcons.share2,
          label: 'Share',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Share text from WhatsApp to ASTRA to add to Inbox!')),
            );
          },
        ),
        const SizedBox(width: 12),
        _ActionButton(
          icon: LucideIcons.plus,
          label: 'New Task',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Switch to Tasks tab to add tasks')),
            );
          },
        ),
        const SizedBox(width: 12),
        _ActionButton(
          icon: LucideIcons.play,
          label: 'Focus',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Switch to Focus tab to start timer')),
            );
          },
        ),
        const SizedBox(width: 12),
        _ActionButton(
          icon: LucideIcons.messageSquare,
          label: 'Assistant',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Switch to Assistant tab to chat')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTodaySection(BuildContext context, WidgetRef ref, List<Task> tasks) {
    final theme = Theme.of(context);

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
              size: 16,
              color: AppTheme.textMuted,
            ),
            const SizedBox(width: 8),
            Text(
              'Today\'s Schedule',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              DateFormat('EEE, MMM d').format(DateTime.now()),
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        todayTasks.isEmpty
            ? Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withAlpha(10),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        LucideIcons.checkCircle2,
                        size: 32,
                        color: AppTheme.textMuted,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'All clear!',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: AppTheme.textMuted,
                        ),
                      ),
                      Text(
                        'No tasks scheduled today',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 300.ms)
            : Column(
                children: todayTasks.take(4).map((task) {
                  return _UpcomingTaskTile(task: task);
                }).toList(),
              ),
      ],
    );
  }

  Widget _buildMotivationalQuote(BuildContext context) {
    final quotes = [
      'Focus on progress, not perfection.',
      'Small daily improvements lead to big results.',
      'The secret of getting ahead is getting started.',
      'Don\'t watch the clock; do what it does. Keep going.',
      'Your future is created by what you do today.',
    ];
    final quote = quotes[DateTime.now().day % quotes.length];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(
            LucideIcons.quote,
            size: 14,
            color: AppTheme.primary.withAlpha(102),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '"$quote"',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textMuted,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---- Reusable Widgets ----

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final String subtitle;
  final Color color;
  final Color glowColor;
  final int flex;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.glowColor,
    this.flex = 1,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.surfaceElevated,
              AppTheme.background,
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: glowColor,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: glowColor,
              blurRadius: 20,
              spreadRadius: -5,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
                Icon(icon, size: 16, color: color),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: color,
                fontSize: flex == 2 ? 28 : 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              subtitle,
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppTheme.textMuted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ).animate().fadeIn(
        duration: 400.ms,
        delay: Duration(milliseconds: flex == 2 ? 0 : 200),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withAlpha(10),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: AppTheme.textSecondary),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.textMuted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpcomingTaskTile extends StatelessWidget {
  final Task task;

  const _UpcomingTaskTile({required this.task});

  @override
  Widget build(BuildContext context) {
    final color = task.priority == 'high'
        ? AppTheme.error
        : task.priority == 'medium'
        ? AppTheme.warning
        : AppTheme.accent;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withAlpha(20),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (task.dueDate != null)
                  Text(
                    'Due: ${DateFormat('MMM d, h:mm a').format(task.dueDate!)}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.textMuted,
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ),
          if (task.priority == 'high')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.error.withAlpha(30),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'URGENT',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.error,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(
      duration: 300.ms,
      delay: Duration(milliseconds: 100 * (task.title.length % 3)),
    );
  }
}
