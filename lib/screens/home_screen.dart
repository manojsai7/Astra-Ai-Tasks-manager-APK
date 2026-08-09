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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.background,
              AppTheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header – Premium
                _buildHeader(context),
                const SizedBox(height: 28),
                
                // Stats Grid – Glassmorphism
                _buildStatsGrid(context, pending, high, completed, focusHours),
                const SizedBox(height: 20),
                
                // Quick Actions – Premium Buttons
                _buildQuickActions(context),
                const SizedBox(height: 24),
                
                // Today's Schedule – Executive View
                _buildTodaySection(context, ref, tasks),
                const Spacer(),
                
                // Motivational Quote – Premium
                _buildMotivationalQuote(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
              greeting,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w400,
                letterSpacing: 1,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Manoj',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        // Avatar with premium gradient ring
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
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: AppTheme.glassCard,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      LucideIcons.checkSquare,
                      size: 16,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Tasks',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '$pending',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontSize: 32,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  completed > 0 ? '$completed completed' : 'No tasks',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: AppTheme.glassCard,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  LucideIcons.flag,
                  size: 16,
                  color: high > 0 ? AppTheme.error : AppTheme.textMuted,
                ),
                const SizedBox(height: 6),
                Text(
                  '$high',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontSize: 24,
                    color: high > 0 ? AppTheme.error : AppTheme.textMuted,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  high > 0 ? 'Priority' : 'All clear',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: AppTheme.glassCard,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  LucideIcons.timer,
                  size: 16,
                  color: AppTheme.accent,
                ),
                const SizedBox(height: 6),
                Text(
                  '$focusHours',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontSize: 24,
                    color: AppTheme.accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Focus Hours',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
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
        const SizedBox(width: 8),
        _ActionButton(
          icon: LucideIcons.plus,
          label: 'Task',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Switch to Tasks tab to add tasks')),
            );
          },
        ),
        const SizedBox(width: 8),
        _ActionButton(
          icon: LucideIcons.play,
          label: 'Focus',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Switch to Focus tab to start timer')),
            );
          },
        ),
        const SizedBox(width: 8),
        _ActionButton(
          icon: LucideIcons.messageSquare,
          label: 'Ask',
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
              'Today',
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              DateFormat('EEE, MMM d').format(DateTime.now()),
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppTheme.textMuted,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        todayTasks.isEmpty
            ? Container(
                padding: const EdgeInsets.all(24),
                decoration: AppTheme.glassCard,
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        LucideIcons.checkCircle2,
                        size: 32,
                        color: AppTheme.textMuted.withAlpha(76),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No tasks scheduled',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              )
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
      'Progress over perfection.',
      'Small daily wins build big results.',
      'Start where you are. Use what you have.',
      'Your future is created by today\'s actions.',
      'Focus on the step, not the staircase.',
      'Discipline is choosing between now and later.',
      'The best time to start was yesterday.',
    ];
    final quote = quotes[DateTime.now().day % quotes.length];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            LucideIcons.quote,
            size: 14,
            color: AppTheme.primary.withAlpha(51),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '"$quote"',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.textMuted.withAlpha(153),
                fontSize: 12,
                fontStyle: FontStyle.italic,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---- Reusable Action Button ----
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
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.surfaceElevated,
                AppTheme.surfaceGlass,
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withAlpha(10),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---- Upcoming Task Tile ----
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: AppTheme.glassCard.copyWith(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withAlpha(20),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 28,
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
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (task.dueDate != null)
                  Text(
                    DateFormat('MMM d • h:mm a').format(task.dueDate!),
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                  letterSpacing: 0.5,
                ),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(
      duration: 400.ms,
      delay: Duration(milliseconds: 50 * (task.id.hashCode % 5)),
    );
  }
}
