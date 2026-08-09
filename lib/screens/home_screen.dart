import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../providers/task_provider.dart';
import '../providers/message_provider.dart';
import '../providers/focus_provider.dart';
import '../models/task.dart';
import '../theme/app_theme.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksFromNotifier = ref.watch(taskNotifierProvider);
    final tasksFromFuture = ref.watch(taskListProvider).asData?.value ?? [];
    final tasks = tasksFromNotifier.isNotEmpty ? tasksFromNotifier : tasksFromFuture;

    final messagesFromNotifier = ref.watch(messageNotifierProvider);
    final messagesFromFuture = ref.watch(messageListProvider).asData?.value ?? [];
    final messages = messagesFromNotifier.isNotEmpty ? messagesFromNotifier : messagesFromFuture;

    final focusStats = ref.watch(focusStatsProvider);

    final pending = tasks.where((t) => !t.isCompleted).length;
    final high = tasks.where((t) => t.priority == 'high' && !t.isCompleted).length;
    final completed = tasks.where((t) => t.isCompleted).length;
    final inboxCount = messages.length;
    final focusHours = (focusStats.totalMinutes) ~/ 60;

    final upcoming = tasks.where((t) => !t.isCompleted && t.dueDate != null).toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header - "Arena" style
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good Morning 👋',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      Text(
                        'Manoj',
                        style: Theme.of(context).textTheme.displayMedium,
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.primary, width: 2),
                    ),
                    child: const CircleAvatar(
                      radius: 24,
                      backgroundColor: AppTheme.surfaceElevated,
                      child: Icon(Icons.person, color: AppTheme.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Stats Grid - Matiks style cards
              _buildStatsGrid(context, pending, high, inboxCount, completed, focusHours),
              const SizedBox(height: 24),

              // Quick Actions - Matiks style chips
              Row(
                children: [
                  _ActionChip(
                    icon: Icons.share_outlined,
                    label: 'Share',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Share text from WhatsApp to ASTRA to add to Inbox!')),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  _ActionChip(
                    icon: Icons.add_task_outlined,
                    label: 'New Task',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Switch to Tasks tab to add tasks')),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  _ActionChip(
                    icon: Icons.play_arrow_outlined,
                    label: 'Focus',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Switch to Focus tab to start timer')),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Upcoming Tasks - Matiks style leaderboard/card list
              Text(
                '⚡ Upcoming',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: upcoming.isEmpty
                    ? const Center(
                        child: Text(
                          'No upcoming tasks',
                          style: TextStyle(color: AppTheme.textMuted),
                        ),
                      )
                    : ListView.builder(
                        itemCount: upcoming.length > 5 ? 5 : upcoming.length,
                        itemBuilder: (ctx, index) {
                          final task = upcoming[index];
                          return _TaskCard(task: task);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, int pending, int high, int inbox, int completed, int focusHours) {
    return Row(
      children: [
        _StatCard(
          title: 'Tasks',
          value: '$pending',
          subtitle: 'Pending',
          color: AppTheme.primary,
          icon: Icons.checklist_outlined,
        ),
        const SizedBox(width: 12),
        _StatCard(
          title: 'High',
          value: '$high',
          subtitle: 'Priority',
          color: AppTheme.error,
          icon: Icons.priority_high_outlined,
        ),
        const SizedBox(width: 12),
        _StatCard(
          title: 'Focus',
          value: '$focusHours',
          subtitle: 'Hours',
          color: AppTheme.accent,
          icon: Icons.timer_outlined,
        ),
      ],
    );
  }
}

// --- Matiks Style Widgets ---

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.surfaceElevated,
              AppTheme.surface,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withAlpha(51), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppTheme.textMuted,
                      ),
                ),
                Icon(icon, size: 18, color: color),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: color,
                    fontSize: 28,
                  ),
            ),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primary.withAlpha(25)),
          ),
          child: Column(
            children: [
              Icon(icon, size: 28, color: AppTheme.primary),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ).animate().scale(duration: 300.ms, curve: Curves.easeOut).then().fadeIn(),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Task task;
  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final color = task.priority == 'high'
        ? AppTheme.error
        : task.priority == 'medium'
            ? AppTheme.warning
            : AppTheme.accent;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(38)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (task.dueDate != null)
                  Text(
                    'Due: ${DateFormat('MMM dd').format(task.dueDate!)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                        ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withAlpha(38),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              task.priority.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
