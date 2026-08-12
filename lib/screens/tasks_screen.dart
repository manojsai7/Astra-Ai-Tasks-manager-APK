import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';
import '../theme/app_theme.dart';
import '../core/motion.dart';
import '../services/notification_service.dart';
import '../widgets/design_system/astra_section_header.dart';
import '../widgets/design_system/astra_3d_button.dart';
import '../widgets/design_system/astra_card.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  DateTime? _dueDate;
  String _priority = 'medium';
  ConfettiController? _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(taskNotifierProvider.notifier).loadTasks();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _confettiController?.dispose();
    super.dispose();
  }

  void _showAddTaskDialog() {
    _titleController.clear();
    _descController.clear();
    _dueDate = null;
    _priority = 'medium';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.borderSubtle,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('New Task',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 4),
                Text(
                  'Add it to your plan',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w400),
                ),
                const SizedBox(height: 20),

                // Title field
                TextField(
                  controller: _titleController,
                  autofocus: true,
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500),
                  decoration: const InputDecoration(
                    hintText: 'What needs to be done?',
                    prefixIcon:
                        Icon(LucideIcons.penLine, size: 18, color: AppTheme.textMuted),
                  ),
                ),
                const SizedBox(height: 10),

                // Description field
                TextField(
                  controller: _descController,
                  style: const TextStyle(
                      color: AppTheme.textPrimary, fontSize: 14),
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'Notes (optional)',
                    prefixIcon: Icon(LucideIcons.alignLeft,
                        size: 18, color: AppTheme.textMuted),
                  ),
                ),
                const SizedBox(height: 12),

                // Date picker
                GestureDetector(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      if (!context.mounted) return;
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (time != null) {
                        setSheetState(() => _dueDate = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            ));
                      } else {
                        setSheetState(() => _dueDate = date);
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.calendar,
                          color: _dueDate != null
                              ? AppTheme.primary
                              : AppTheme.textMuted,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _dueDate == null
                              ? 'Set due date & time'
                              : DateFormat('MMM dd, yyyy · h:mm a')
                                  .format(_dueDate!),
                          style: TextStyle(
                            color: _dueDate == null
                                ? AppTheme.textMuted
                                : AppTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Priority pills
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PRIORITY',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textMuted,
                          letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _PriorityPill(
                          label: 'Low',
                          color: AppTheme.accent,
                          isSelected: _priority == 'low',
                          onTap: () =>
                              setSheetState(() => _priority = 'low'),
                        ),
                        const SizedBox(width: 8),
                        _PriorityPill(
                          label: 'Medium',
                          color: AppTheme.warning,
                          isSelected: _priority == 'medium',
                          onTap: () =>
                              setSheetState(() => _priority = 'medium'),
                        ),
                        const SizedBox(width: 8),
                        _PriorityPill(
                          label: 'High',
                          color: AppTheme.error,
                          isSelected: _priority == 'high',
                          onTap: () =>
                              setSheetState(() => _priority = 'high'),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_titleController.text.trim().isEmpty) return;
                      final task = Task(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        title: _titleController.text.trim(),
                        description: _descController.text.trim().isEmpty
                            ? null
                            : _descController.text.trim(),
                        dueDate: _dueDate,
                        priority: _priority,
                        createdAt: DateTime.now(),
                      );
                      ref.read(taskNotifierProvider.notifier).addTask(task);
                      ref.invalidate(taskListProvider);

                      if (task.dueDate != null) {
                        final reminderTime = task.dueDate!
                            .subtract(const Duration(days: 1));
                        await NotificationService.scheduleTaskReminder(
                          id: task.id.hashCode,
                          title: 'Task Due Tomorrow: ${task.title}',
                          body: 'Your task is due tomorrow. Stay ahead!',
                          scheduledTime: reminderTime,
                        );
                        final finalReminder = task.dueDate!
                            .subtract(const Duration(hours: 2));
                        await NotificationService.scheduleTaskReminder(
                          id: task.id.hashCode + 9999,
                          title: 'Urgent: ${task.title}',
                          body: 'This task is due in 2 hours!',
                          scheduledTime: finalReminder,
                        );
                        final directReminder =
                            task.dueDate!.isAfter(DateTime.now())
                                ? task.dueDate!
                                : DateTime.now()
                                    .add(const Duration(minutes: 1));
                        await NotificationService.scheduleTaskReminder(
                          id: task.id.hashCode + 8888,
                          title: 'ASTRA: ${task.title}',
                          body:
                              'Priority: ${task.priority.toUpperCase()} · Due now!',
                          scheduledTime: directReminder,
                        );
                      }

                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Add to Plan',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stateTasks = ref.watch(taskNotifierProvider);
    final tasksFuture = ref.watch(taskListProvider).asData?.value ?? [];
    final tasks = stateTasks.isNotEmpty ? stateTasks : tasksFuture;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final overdue = tasks
        .where((t) =>
            !t.isCompleted &&
            t.dueDate != null &&
            t.dueDate!.isBefore(today))
        .toList();
    final todayTasks = tasks
        .where((t) =>
            !t.isCompleted &&
            t.dueDate != null &&
            t.dueDate!.isAfter(today.subtract(const Duration(seconds: 1))) &&
            t.dueDate!.isBefore(today.add(const Duration(days: 1))))
        .toList();
    final upcoming = tasks
        .where((t) =>
            !t.isCompleted &&
            (t.dueDate == null ||
                t.dueDate!.isAfter(today.add(const Duration(days: 1)))))
        .toList();
    final completed = tasks.where((t) => t.isCompleted).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Header ────────────────────────────────────────
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TASKS',
                                style: AstraText.displayL(size: 34),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${tasks.where((t) => !t.isCompleted).length} remaining · ${tasks.length} total',
                                style: AstraText.body(size: 15, color: AstraColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 58,
                          height: 58,
                          child: Astra3DButton(
                            height: 52,
                            depth: AstraDepth.medium,
                            color: AstraColors.lime,
                            onTap: _showAddTaskDialog,
                            child: const Icon(Icons.add_rounded, size: 30, color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(duration: 400.ms),
              ),

              SliverToBoxAdapter(child: const SizedBox(height: 24)),

              // Task sections
              if (tasks.isEmpty)
                SliverFillRemaining(
                  child: _buildEmptyState(context),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      if (overdue.isNotEmpty) ...[
                        const AstraSectionHeader(
                          title: 'Overdue',
                          showAccentBar: true,
                          accentColor: AppTheme.error,
                        ),
                        const SizedBox(height: 8),
                        ...overdue.asMap().entries.map((e) => _TaskCard(
                              task: e.value,
                              onComplete: () {
                                ref
                                    .read(taskNotifierProvider.notifier)
                                    .toggleComplete(e.value.id);
                                ref.invalidate(taskListProvider);
                                _confettiController?.play();
                              },
                              onDelete: () async {
                                ref
                                    .read(taskNotifierProvider.notifier)
                                    .deleteTask(e.value.id);
                                ref.invalidate(taskListProvider);
                                await NotificationService.cancelNotification(
                                    e.value.id.hashCode);
                              },
                            ).withPremiumEntry(delayMs: e.key * 40)),
                        const SizedBox(height: 20),
                      ],
                      if (todayTasks.isNotEmpty) ...[
                        const AstraSectionHeader(
                          title: 'Today',
                          showAccentBar: true,
                        ),
                        const SizedBox(height: 8),
                        ...todayTasks.asMap().entries.map((e) => _TaskCard(
                              task: e.value,
                              onComplete: () {
                                ref
                                    .read(taskNotifierProvider.notifier)
                                    .toggleComplete(e.value.id);
                                ref.invalidate(taskListProvider);
                                _confettiController?.play();
                              },
                              onDelete: () async {
                                ref
                                    .read(taskNotifierProvider.notifier)
                                    .deleteTask(e.value.id);
                                ref.invalidate(taskListProvider);
                                await NotificationService.cancelNotification(
                                    e.value.id.hashCode);
                              },
                            ).withPremiumEntry(delayMs: e.key * 40)),
                        const SizedBox(height: 20),
                      ],
                      if (upcoming.isNotEmpty) ...[
                        const AstraSectionHeader(
                          title: 'Upcoming',
                          showAccentBar: true,
                          accentColor: AppTheme.secondary,
                        ),
                        const SizedBox(height: 8),
                        ...upcoming.asMap().entries.map((e) => _TaskCard(
                              task: e.value,
                              onComplete: () {
                                ref
                                    .read(taskNotifierProvider.notifier)
                                    .toggleComplete(e.value.id);
                                ref.invalidate(taskListProvider);
                                _confettiController?.play();
                              },
                              onDelete: () async {
                                ref
                                    .read(taskNotifierProvider.notifier)
                                    .deleteTask(e.value.id);
                                ref.invalidate(taskListProvider);
                                await NotificationService.cancelNotification(
                                    e.value.id.hashCode);
                              },
                            ).withPremiumEntry(delayMs: e.key * 40)),
                        const SizedBox(height: 20),
                      ],
                      if (completed.isNotEmpty) ...[
                        AstraSectionHeader(
                          title: 'Completed',
                          showAccentBar: true,
                          accentColor: AppTheme.accentGreen,
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.accentGreen.withAlpha(20),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppTheme.accentGreen.withAlpha(50)),
                            ),
                            child: Text(
                              '${completed.length} done',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.accentGreen,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...completed.map((t) => _TaskCard(
                              task: t,
                              onComplete: () {
                                ref
                                    .read(taskNotifierProvider.notifier)
                                    .toggleComplete(t.id);
                                ref.invalidate(taskListProvider);
                              },
                              onDelete: () async {
                                ref
                                    .read(taskNotifierProvider.notifier)
                                    .deleteTask(t.id);
                                ref.invalidate(taskListProvider);
                                await NotificationService.cancelNotification(
                                    t.id.hashCode);
                              },
                            )),
                        const SizedBox(height: 24),
                      ],
                    ]),
                  ),
                ),
            ],
          ),

          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController!,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.03,
              numberOfParticles: 40,
              gravity: 0.1,
              shouldLoop: false,
              colors: const [
                AppTheme.primary,
                AppTheme.accentGreen,
                AppTheme.accentPurple,
                AppTheme.accent,
                AppTheme.secondary,
                AppTheme.warning,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AstraColors.surface,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: AstraColors.edgeSoft),
              boxShadow: const [
                BoxShadow(color: AstraColors.depth, offset: Offset(0, 6), blurRadius: 0),
              ],
            ),
            child: const Icon(Icons.task_alt_rounded, color: AstraColors.lime, size: 52),
          ),
          const SizedBox(height: 22),
          Text(
            'NO TASKS YET',
            style: AstraText.displayM(size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            'Your plan is empty.\nTap + to add your first task.',
            textAlign: TextAlign.center,
            style: AstraText.body(size: 15, color: AstraColors.textMuted),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 220,
            child: Astra3DButton(
              height: 54,
              depth: AstraDepth.medium,
              color: AstraColors.lime,
              textColor: Colors.black,
              onTap: _showAddTaskDialog,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_rounded, color: Colors.black, size: 22),
                  const SizedBox(width: 8),
                  Text('ADD FIRST TASK', style: AstraText.label(size: 12, color: Colors.black)),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }
}

// ─── Priority Pill ──────────────────────────────────────────────────────────

class _PriorityPill extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _PriorityPill({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(30) : AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : AppTheme.borderSubtle,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                  color: isSelected ? color : AppTheme.textMuted,
                  shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? color : AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Task Card ──────────────────────────────────────────────────────────────

class _TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onComplete;
  final VoidCallback onDelete;

  const _TaskCard({
    required this.task,
    required this.onComplete,
    required this.onDelete,
  });

  Color _priorityColor() => switch (task.priority) {
        'high' => AppTheme.error,
        'medium' => AppTheme.warning,
        _ => AppTheme.accent,
      };

  @override
  Widget build(BuildContext context) {
    final color = _priorityColor();
    final isOverdue = !task.isCompleted &&
        task.dueDate != null &&
        task.dueDate!.isBefore(DateTime.now());

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AstraCard(
        padding: EdgeInsets.zero,
        borderColor: task.isCompleted
            ? AstraColors.borderSoft
            : isOverdue
                ? AstraColors.red.withValues(alpha: .5)
                : color.withValues(alpha: .3),
        child: Row(
        children: [
          // Priority strip
          Container(
            width: 4,
            height: 72,
            decoration: BoxDecoration(
              color: task.isCompleted
                  ? AppTheme.accentGreen.withAlpha(60)
                  : isOverdue
                      ? AppTheme.error
                      : color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Checkbox
          GestureDetector(
            onTap: onComplete,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: task.isCompleted ? AppTheme.accentGreen : color,
                  width: 2,
                ),
                color: task.isCompleted ? AppTheme.accentGreen : Colors.transparent,
                boxShadow: task.isCompleted
                    ? [
                        BoxShadow(
                          color: AppTheme.accentGreen.withAlpha(60),
                          blurRadius: 8,
                          spreadRadius: -2,
                        )
                      ]
                    : null,
              ),
              child: task.isCompleted
                  ? const Icon(LucideIcons.check, size: 13, color: Colors.black)
                  : null,
            ),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: task.isCompleted
                          ? AppTheme.textMuted
                          : AppTheme.textPrimary,
                      decoration: task.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (task.description != null &&
                      task.description!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      task.description!,
                      style: TextStyle(
                          fontSize: 11, color: AppTheme.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (task.dueDate != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          LucideIcons.clock,
                          size: 11,
                          color: isOverdue
                              ? AppTheme.error
                              : AppTheme.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MMM d · h:mm a').format(task.dueDate!),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: isOverdue
                                ? AppTheme.error
                                : AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Priority badge + delete
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  task.priority.toUpperCase(),
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: task.isCompleted ? AppTheme.textMuted : color),
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.trash2,
                    size: 16, color: AppTheme.textMuted),
                onPressed: onDelete,
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
    ),
  );
}
}
