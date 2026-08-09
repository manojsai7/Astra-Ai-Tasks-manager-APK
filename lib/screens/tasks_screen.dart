import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:confetti/confetti.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';
import '../theme/app_theme.dart';

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
                              const Icon(Icons.calendar_today, color: AppTheme.textMuted, size: 20),
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
                                        width: 10,
                                        height: 10,
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
                                      Text(p.toUpperCase(), style: const TextStyle(fontSize: 12)),
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
                        onPressed: () {
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
                          Navigator.pop(ctx);
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
            icon: const Icon(Icons.add),
            onPressed: _showAddTaskDialog,
          ),
        ],
      ),
      body: Stack(
        children: [
          tasks.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.checklist, size: 64, color: AppTheme.textMuted),
                      SizedBox(height: 16),
                      Text('No tasks yet', style: TextStyle(color: AppTheme.textMuted)),
                      SizedBox(height: 8),
                      Text('Tap + to add your first task',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                    ],
                  ),
                )
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
                              backgroundColor: AppTheme.primary.withAlpha(51),
                              labelStyle: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      ...incomplete.map((task) => _TaskTile(
                            task: task,
                            onComplete: () {
                              ref.read(taskNotifierProvider.notifier).toggleComplete(task.id);
                              ref.invalidate(taskListProvider);
                              _confettiController?.play();
                            },
                            onDelete: () {
                              ref.read(taskNotifierProvider.notifier).deleteTask(task.id);
                              ref.invalidate(taskListProvider);
                            },
                          )),
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
                              backgroundColor: AppTheme.success.withAlpha(51),
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
                            onDelete: () {
                              ref.read(taskNotifierProvider.notifier).deleteTask(task.id);
                              ref.invalidate(taskListProvider);
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
        child: const Icon(Icons.add),
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: task.isCompleted ? Colors.transparent : color.withAlpha(38),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: GestureDetector(
          onTap: onComplete,
          child: AnimatedContainer(
            duration: 300.ms,
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: task.isCompleted ? AppTheme.success : color,
                width: 2,
              ),
              color: task.isCompleted ? AppTheme.success : Colors.transparent,
            ),
            child: task.isCompleted
                ? const Icon(Icons.check, size: 16, color: Colors.white)
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
                  const Icon(Icons.event, size: 14, color: AppTheme.textMuted),
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
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.textMuted),
              onPressed: onDelete,
            ),
          ],
        ),
        tileColor: task.isCompleted ? AppTheme.surface.withAlpha(128) : null,
      ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.1, end: 0),
    );
  }
}
