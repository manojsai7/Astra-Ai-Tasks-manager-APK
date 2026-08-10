import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:confetti/confetti.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';
import '../theme/app_theme.dart';
import '../core/motion.dart';
import '../services/notification_service.dart';

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
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
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
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.textMuted,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('New Task', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 16),
                TextField(
                  controller: _titleController,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Task title',
                    hintStyle: const TextStyle(color: AppTheme.textMuted),
                    filled: true,
                    fillColor: AppTheme.surfaceElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descController,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Description (optional)',
                    hintStyle: const TextStyle(color: AppTheme.textMuted),
                    filled: true,
                    fillColor: AppTheme.surfaceElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2030),
                          );
                          if (date != null) {
                            setSheetState(() => _dueDate = date);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceElevated,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(LucideIcons.calendar, color: AppTheme.textMuted, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _dueDate == null
                                      ? 'Set due date'
                                      : DateFormat('MMM dd, yyyy').format(_dueDate!),
                                  style: TextStyle(
                                    color: _dueDate == null ? AppTheme.textMuted : AppTheme.textPrimary,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _priority,
                        items: ['low', 'medium', 'high']
                            .map((p) => DropdownMenuItem(
                                  value: p,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: p == 'high'
                                              ? AppTheme.error
                                              : p == 'medium'
                                                  ? AppTheme.warning
                                                  : AppTheme.accent,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(p.toUpperCase(), style: const TextStyle(fontSize: 11)),
                                    ],
                                  ),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setSheetState(() => _priority = val);
                          }
                        },
                        dropdownColor: AppTheme.surfaceElevated,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppTheme.surfaceElevated,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
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

                          // Schedule local notification if due date set
                          if (task.dueDate != null) {
                            // 1. Schedule reminder 24 hours before
                            final reminderTime = task.dueDate!.subtract(const Duration(days: 1));
                            await NotificationService.scheduleTaskReminder(
                              id: task.id.hashCode,
                              title: 'Task Due Tomorrow: ${task.title}',
                              body: 'Your task is due tomorrow. Stay ahead!',
                              scheduledTime: reminderTime,
                            );
                            
                            // 2. Schedule a second reminder 2 hours before
                            final finalReminder = task.dueDate!.subtract(const Duration(hours: 2));
                            await NotificationService.scheduleTaskReminder(
                              id: task.id.hashCode + 9999,
                              title: 'Urgent: ${task.title}',
                              body: 'This task is due in 2 hours!',
                              scheduledTime: finalReminder,
                            );

                            // 3. Direct due date / short-term reminder if due in future
                            final directReminder = task.dueDate!.isAfter(DateTime.now())
                                ? task.dueDate!
                                : DateTime.now().add(const Duration(minutes: 1));
                            await NotificationService.scheduleTaskReminder(
                              id: task.id.hashCode + 8888,
                              title: 'ASTRA Task Reminder: ${task.title}',
                              body: 'Priority: ${task.priority.toUpperCase()} - Due now!',
                              scheduledTime: directReminder,
                            );
                          }

                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Add Task'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
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

    final incomplete = tasks.where((t) => !t.isCompleted).toList();
    final completed = tasks.where((t) => t.isCompleted).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Tasks Arena'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus),
            onPressed: _showAddTaskDialog,
          ),
        ],
      ),
      body: Stack(
        children: [
          tasks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.checkSquare, size: 56, color: AppTheme.textMuted),
                      const SizedBox(height: 16),
                      const Text('No tasks yet', style: TextStyle(color: AppTheme.textMuted)),
                      const SizedBox(height: 8),
                      const Text('Tap + to add your first task',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                    ],
                  ),
                ).withPremiumEntry()
              : ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  children: [
                    if (incomplete.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: Row(
                          children: [
                            Text('Pending', style: Theme.of(context).textTheme.titleMedium),
                            const Spacer(),
                            Chip(
                              label: Text('${incomplete.length}'),
                              backgroundColor: AppTheme.primary.withAlpha(38),
                              labelStyle: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      ...incomplete.asMap().entries.map((entry) {
                        final index = entry.key;
                        final task = entry.value;
                        return _TaskTile(
                          task: task,
                          onComplete: () {
                            ref.read(taskNotifierProvider.notifier).toggleComplete(task.id);
                            ref.invalidate(taskListProvider);
                            _confettiController?.play();
                          },
                          onDelete: () async {
                            ref.read(taskNotifierProvider.notifier).deleteTask(task.id);
                            ref.invalidate(taskListProvider);
                            await NotificationService.cancelNotification(task.id.hashCode);
                          },
                        ).withPremiumEntry(delayMs: index * 40);
                      }),
                    ],
                    if (completed.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: Row(
                          children: [
                            Text('Completed', style: Theme.of(context).textTheme.titleMedium),
                            const Spacer(),
                            Chip(
                              label: Text('${completed.length}'),
                              backgroundColor: AppTheme.success.withAlpha(38),
                              labelStyle: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      ...completed.map((task) => _TaskTile(
                            task: task,
                            onComplete: () {
                              ref.read(taskNotifierProvider.notifier).toggleComplete(task.id);
                              ref.invalidate(taskListProvider);
                            },
                            onDelete: () async {
                              ref.read(taskNotifierProvider.notifier).deleteTask(task.id);
                              ref.invalidate(taskListProvider);
                              await NotificationService.cancelNotification(task.id.hashCode);
                            },
                          )),
                    ],
                  ],
                ),

          // Confetti overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController!,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 30,
              gravity: 0.1,
              shouldLoop: false,
              colors: const [
                AppTheme.primary,
                AppTheme.accent,
                AppTheme.success,
                AppTheme.warning,
                AppTheme.error,
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        backgroundColor: AppTheme.primary,
        child: const Icon(LucideIcons.plus),
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final Task task;
  final VoidCallback onComplete;
  final VoidCallback onDelete;

  const _TaskTile({
    required this.task,
    required this.onComplete,
    required this.onDelete,
  });

  Color _getPriorityColor() {
    switch (task.priority) {
      case 'high':
        return AppTheme.error;
      case 'medium':
        return AppTheme.warning;
      default:
        return AppTheme.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getPriorityColor();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: task.isCompleted ? Colors.transparent : color.withAlpha(30),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: GestureDetector(
          onTap: onComplete,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: task.isCompleted ? AppTheme.success : color,
                width: 2,
              ),
              color: task.isCompleted ? AppTheme.success : Colors.transparent,
            ),
            child: task.isCompleted
                ? const Icon(LucideIcons.check, size: 14, color: Colors.white)
                : null,
          ),
        ),
        title: Text(
          task.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                color: task.isCompleted ? AppTheme.textMuted : AppTheme.textPrimary,
              ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description != null && task.description!.isNotEmpty)
              Text(
                task.description!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            if (task.dueDate != null)
              Row(
                children: [
                  const Icon(LucideIcons.calendar, size: 13, color: AppTheme.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM dd, yyyy').format(task.dueDate!),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.textMuted,
                        ),
                  ),
                ],
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                task.priority.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 9,
                    ),
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              icon: const Icon(LucideIcons.trash2, size: 18, color: AppTheme.textMuted),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
