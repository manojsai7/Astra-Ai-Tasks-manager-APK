import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/task.dart';
import '../providers/task_provider.dart';
import '../services/task/astra_task_filter.dart';
import '../theme/app_theme.dart';
import '../services/notification_service.dart';
import '../widgets/design_system/astra_section_header.dart';
import '../widgets/design_system/astra_3d_button.dart';
import '../widgets/tasks/astra_task_card.dart';
import '../widgets/tasks/astra_task_creation_sheet.dart';
import '../widgets/tasks/tasks_view_tabs.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  TaskViewFilter _selectedView = TaskViewFilter.myDay;
  ConfettiController? _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(milliseconds: 800));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(taskNotifierProvider.notifier).loadTasks();
    });
  }

  @override
  void dispose() {
    _confettiController?.dispose();
    super.dispose();
  }

  void _showAddTaskDialog() {
    DateTime? initialDate;
    if (_selectedView == TaskViewFilter.myDay) {
      initialDate = DateTime.now();
    } else if (_selectedView == TaskViewFilter.upcoming) {
      initialDate = DateTime.now().add(const Duration(days: 1));
    }
    AstraTaskDetailSheet.create(
      context,
      initialDate: initialDate,
      initialPriority: _selectedView == TaskViewFilter.priority ? 'high' : 'medium',
    );
  }


  void _showEditTaskDialog(Task task) {
    AstraTaskDetailSheet.edit(
      context,
      task: task,
    );
  }

  @override
  Widget build(BuildContext context) {
    final stateTasks = ref.watch(taskNotifierProvider);
    final tasksFuture = ref.watch(taskListProvider).asData?.value ?? [];
    final tasks = stateTasks.isNotEmpty ? stateTasks : tasksFuture;
    final buckets = AstraTaskFilter.categorize(tasks);
    final overdue = buckets.overdue;
    final todayTasks = buckets.todayTasks;
    final tomorrowTasks = buckets.tomorrowTasks;
    final thisWeekTasks = buckets.thisWeekTasks;
    final laterTasks = buckets.laterTasks;
    final noDateTasks = buckets.noDateTasks;
    final recurringTasks = buckets.recurringTasks;
    final completedTasks = buckets.completedTasks;

    // Counts Map for top tabs
    final counts = <TaskViewFilter, int>{
      TaskViewFilter.myDay: overdue.length + todayTasks.length,
      TaskViewFilter.upcoming: buckets.upcomingCount,
      TaskViewFilter.all: buckets.allActiveCount,
      TaskViewFilter.important: tasks.where((t) => AstraTaskFilter.isActive(t) && (t.isImportant || t.priority == 'high' || t.priority == 'medium')).length,
      TaskViewFilter.recurring: recurringTasks.length,
      TaskViewFilter.completed: completedTasks.length,
    };

    return Scaffold(
      backgroundColor: AstraColors.background,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ASTRA', style: AstraText.label(size: 11, color: AstraColors.cyan)),
                          const SizedBox(height: 2),
                          Text('TASKS', style: AstraText.displayL(size: 36)),
                        ],
                      ),
                      const Spacer(),
                      // Count badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AstraColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AstraColors.edgeSoft),
                        ),
                        child: Text(
                          '${buckets.allActiveCount} active',
                          style: AstraText.label(size: 11, color: AstraColors.lime),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Add Button
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: Astra3DButton(
                          height: 42,
                          depth: AstraDepth.small,
                          color: AstraColors.lime,
                          depthColor: AstraDepthColors.limeDepth,
                          borderColor: AstraDepthColors.limeBorder,
                          onTap: _showAddTaskDialog,
                          child: const Icon(LucideIcons.plus, size: 20, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                ),

                // View Tabs (Horizontal Scrolling)
                TasksViewTabs(
                  selectedView: _selectedView,
                  onSelectView: (view) => setState(() => _selectedView = view),
                  counts: counts,
                ),

                const SizedBox(height: 6),

                // Task List View based on Filter
                Expanded(
                  child: _buildViewContent(
                    overdue: overdue,
                    todayTasks: todayTasks,
                    tomorrowTasks: tomorrowTasks,
                    thisWeekTasks: thisWeekTasks,
                    laterTasks: laterTasks,
                    noDateTasks: noDateTasks,
                    recurringTasks: recurringTasks,
                    completedTasks: completedTasks,
                    allTasks: tasks,
                  ),
                ),
              ],
            ),
          ),

          // Confetti Celebration (Subtle & Bounded)
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController!,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.08,
              emissionFrequency: 0.015,
              numberOfParticles: 16,
              gravity: 0.25,
              shouldLoop: false,
              colors: const [
                AstraColors.lime,
                AstraColors.softGreen,
                AstraColors.cyan,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewContent({
    required List<Task> overdue,
    required List<Task> todayTasks,
    required List<Task> tomorrowTasks,
    required List<Task> thisWeekTasks,
    required List<Task> laterTasks,
    required List<Task> noDateTasks,
    required List<Task> recurringTasks,
    required List<Task> completedTasks,
    required List<Task> allTasks,
  }) {
    switch (_selectedView) {
      case TaskViewFilter.myDay:
        final myDayList = [...overdue, ...todayTasks, ...noDateTasks];
        if (myDayList.isEmpty) {
          return _buildEmptyState(
            icon: LucideIcons.sunMedium,
            title: 'MY DAY IS CLEAR',
            subtitle: 'No tasks scheduled for today.\nTap + above to add your focus.',
          );
        }
        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            if (overdue.isNotEmpty) ...[
              const AstraSectionHeader(
                title: 'Overdue',
                showAccentBar: true,
                accentColor: AstraColors.red,
              ),
              const SizedBox(height: 8),
              ...overdue.map((t) => _buildTaskCard(t)),
              const SizedBox(height: 16),
            ],
            if (todayTasks.isNotEmpty) ...[
              const AstraSectionHeader(
                title: 'Today',
                showAccentBar: true,
                accentColor: AstraColors.lime,
              ),
              const SizedBox(height: 8),
              ...todayTasks.map((t) => _buildTaskCard(t)),
              const SizedBox(height: 16),
            ],
            if (noDateTasks.isNotEmpty) ...[
              const AstraSectionHeader(
                title: 'No Due Date',
                showAccentBar: true,
                accentColor: AstraColors.cyan,
              ),
              const SizedBox(height: 8),
              ...noDateTasks.map((t) => _buildTaskCard(t)),
            ],
          ],
        );

      case TaskViewFilter.upcoming:
        final hasUpcoming = tomorrowTasks.isNotEmpty || thisWeekTasks.isNotEmpty || laterTasks.isNotEmpty;
        if (!hasUpcoming) {
          return _buildEmptyState(
            icon: LucideIcons.calendarDays,
            title: 'NO UPCOMING TASKS',
            subtitle: 'You are all caught up for the days ahead.',
          );
        }
        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            if (tomorrowTasks.isNotEmpty) ...[
              const AstraSectionHeader(
                title: 'Tomorrow',
                showAccentBar: true,
                accentColor: AstraColors.amber,
              ),
              const SizedBox(height: 8),
              ...tomorrowTasks.map((t) => _buildTaskCard(t)),
              const SizedBox(height: 16),
            ],
            if (thisWeekTasks.isNotEmpty) ...[
              const AstraSectionHeader(
                title: 'This Week',
                showAccentBar: true,
                accentColor: AstraColors.cyan,
              ),
              const SizedBox(height: 8),
              ...thisWeekTasks.map((t) => _buildTaskCard(t)),
              const SizedBox(height: 16),
            ],
            if (laterTasks.isNotEmpty) ...[
              const AstraSectionHeader(
                title: 'Later',
                showAccentBar: true,
                accentColor: AstraColors.textMuted,
              ),
              const SizedBox(height: 8),
              ...laterTasks.map((t) => _buildTaskCard(t)),
            ],
          ],
        );

      case TaskViewFilter.important:
        final starred = allTasks.where((t) => !t.isCompleted && t.isImportant).toList();
        final high = allTasks.where((t) => !t.isCompleted && !t.isImportant && t.priority == 'high').toList();
        final medium = allTasks.where((t) => !t.isCompleted && !t.isImportant && t.priority == 'medium').toList();
        final low = allTasks.where((t) => !t.isCompleted && !t.isImportant && t.priority == 'low').toList();

        if (starred.isEmpty && high.isEmpty && medium.isEmpty && low.isEmpty) {
          return _buildEmptyState(
            icon: LucideIcons.star,
            title: 'NO IMPORTANT TASKS',
            subtitle: 'Mark tasks as important or high priority to see them here.',
          );
        }
        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            if (starred.isNotEmpty) ...[
              const AstraSectionHeader(
                title: 'Starred & Urgent',
                showAccentBar: true,
                accentColor: Color(0xFFFEF08A),
              ),
              const SizedBox(height: 8),
              ...starred.map((t) => _buildTaskCard(t)),
              const SizedBox(height: 16),
            ],
            if (high.isNotEmpty) ...[
              const AstraSectionHeader(
                title: 'High Priority',
                showAccentBar: true,
                accentColor: AstraColors.red,
              ),
              const SizedBox(height: 8),
              ...high.map((t) => _buildTaskCard(t)),
              const SizedBox(height: 16),
            ],
            if (medium.isNotEmpty) ...[
              const AstraSectionHeader(
                title: 'Medium Priority',
                showAccentBar: true,
                accentColor: AstraColors.amber,
              ),
              const SizedBox(height: 8),
              ...medium.map((t) => _buildTaskCard(t)),
              const SizedBox(height: 16),
            ],
            if (low.isNotEmpty) ...[
              const AstraSectionHeader(
                title: 'Low Priority',
                showAccentBar: true,
                accentColor: AstraColors.cyan,
              ),
              const SizedBox(height: 8),
              ...low.map((t) => _buildTaskCard(t)),
            ],
          ],
        );

      case TaskViewFilter.recurring:
        if (recurringTasks.isEmpty) {
          return _buildEmptyState(
            icon: LucideIcons.repeat,
            title: 'NO RECURRING TASKS',
            subtitle: 'Automated routines and repeating schedules appear here.',
          );
        }
        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            const AstraSectionHeader(
              title: 'Routines & Habits',
              showAccentBar: true,
              accentColor: AstraColors.cyan,
            ),
            const SizedBox(height: 8),
            ...recurringTasks.map((t) => _buildTaskCard(t)),
          ],
        );

      case TaskViewFilter.completed:
        if (completedTasks.isEmpty) {
          return _buildEmptyState(
            icon: LucideIcons.checkCircle2,
            title: 'NO COMPLETED TASKS',
            subtitle: 'Tasks you complete will be archived here.',
          );
        }
        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            AstraSectionHeader(
              title: 'Completed',
              showAccentBar: true,
              accentColor: AstraAccent.primaryMuted,
              trailing: Text(
                '${completedTasks.length} done',
                style: AstraText.label(size: 11, color: AstraAccent.primaryMuted),
              ),
            ),
            const SizedBox(height: 8),
            ...completedTasks.map((t) => _buildTaskCard(t)),
          ],
        );

      case TaskViewFilter.all:
        final activeTasks = allTasks.where((t) => !t.isCompleted).toList();
        if (activeTasks.isEmpty && completedTasks.isEmpty) {
          return _buildEmptyState(
            icon: LucideIcons.layoutList,
            title: 'NO TASKS YET',
            subtitle: 'Your workspace is empty.\nTap + above to add your first task.',
          );
        }
        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            if (overdue.isNotEmpty) ...[
              const AstraSectionHeader(
                title: 'Overdue',
                showAccentBar: true,
                accentColor: AstraColors.red,
              ),
              const SizedBox(height: 8),
              ...overdue.map((t) => _buildTaskCard(t)),
              const SizedBox(height: 16),
            ],
            if (todayTasks.isNotEmpty) ...[
              const AstraSectionHeader(
                title: 'Today',
                showAccentBar: true,
                accentColor: AstraColors.lime,
              ),
              const SizedBox(height: 8),
              ...todayTasks.map((t) => _buildTaskCard(t)),
              const SizedBox(height: 16),
            ],
            if (tomorrowTasks.isNotEmpty || thisWeekTasks.isNotEmpty || laterTasks.isNotEmpty) ...[
              const AstraSectionHeader(
                title: 'Upcoming',
                showAccentBar: true,
                accentColor: AstraColors.amber,
              ),
              const SizedBox(height: 8),
              ...tomorrowTasks.map((t) => _buildTaskCard(t)),
              ...thisWeekTasks.map((t) => _buildTaskCard(t)),
              ...laterTasks.map((t) => _buildTaskCard(t)),
              const SizedBox(height: 16),
            ],
            if (noDateTasks.isNotEmpty) ...[
              const AstraSectionHeader(
                title: 'No Due Date',
                showAccentBar: true,
                accentColor: AstraColors.cyan,
              ),
              const SizedBox(height: 8),
              ...noDateTasks.map((t) => _buildTaskCard(t)),
              const SizedBox(height: 16),
            ],
            if (completedTasks.isNotEmpty) ...[
              AstraSectionHeader(
                title: 'Completed',
                showAccentBar: true,
                accentColor: AstraAccent.primaryMuted,
                trailing: Text(
                  '${completedTasks.length} done',
                  style: AstraText.label(size: 11, color: AstraAccent.primaryMuted),
                ),
              ),
              const SizedBox(height: 8),
              ...completedTasks.map((t) => _buildTaskCard(t)),
            ],
          ],
        );
    }
  }

  Widget _buildTaskCard(Task task) {
    return AstraTaskCard(
      task: task,
      onComplete: () {
        HapticFeedback.selectionClick();
        ref.read(taskNotifierProvider.notifier).toggleComplete(task.id);
        ref.invalidate(taskListProvider);
        if (!task.isCompleted) {
          _confettiController?.play();
        }
      },
      onEdit: () => _showEditTaskDialog(task),
      onDelete: () async {
        HapticFeedback.lightImpact();
        ref.read(taskNotifierProvider.notifier).deleteTask(task.id);
        ref.invalidate(taskListProvider);
        await NotificationService.cancelNotification(task.id.hashCode);
      },
      onStatusCycle: () {
        final next = task.status.nextStatus();
        ref.read(taskNotifierProvider.notifier).setStatus(task.id, next);
        ref.invalidate(taskListProvider);
      },
      onToggleSubtask: (subId) {
        ref.read(taskNotifierProvider.notifier).toggleSubtask(task.id, subId);
        ref.invalidate(taskListProvider);
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AstraColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AstraColors.edgeSoft),
                boxShadow: const [
                  BoxShadow(color: AstraColors.depth, offset: Offset(0, 4), blurRadius: 0),
                ],
              ),
              child: Icon(icon, color: AstraColors.lime, size: 34),
            ),
            const SizedBox(height: 18),
            Text(title, style: AstraText.displayM(size: 24)),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AstraText.body(size: 13.5, color: AstraColors.textMuted),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 350.ms);
  }
}
