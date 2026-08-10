import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/router/router.dart';
import '../../../../core/database/database.dart';
import '../../../scheduler/domain/services/ai_life_scheduler_service.dart';
import '../../../scheduler/presentation/widgets/google_sync_card.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';

/// Interactive tasks screen showing Google sync card, task list, and AI context badges.
class TasksScreen extends StatefulWidget {
  final TaskRepository repository;
  final AppDatabase database;

  const TasksScreen({
    super.key,
    required this.repository,
    required this.database,
  });

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  late final AiLifeSchedulerService _schedulerService;

  @override
  void initState() {
    super.initState();
    _schedulerService = AiLifeSchedulerService(database: widget.database);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('ASTRA Tasks & AI Scheduler'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<List<Task>>(
          stream: widget.repository.watchTasks(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading tasks: ${snapshot.error}',
                  style: TextStyle(color: colorScheme.error),
                ),
              );
            }

            final tasks = snapshot.data ?? [];

            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // --- Top Google OAuth & Sync Card ---
                GoogleSyncCard(
                  schedulerService: _schedulerService,
                  onSyncCompleted: () => setState(() {}),
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Text(
                      'Your Tasks (${tasks.length})',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Tap for full context',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                if (tasks.isEmpty)
                  Card(
                    elevation: 0,
                    color: colorScheme.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.sparkles,
                            size: 48,
                            color: colorScheme.primary.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No tasks detected yet',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tap "Sync Gmail & Calendar Now" above to extract application deadlines and exam reminders automatically.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...tasks.map((task) => _buildTaskItem(context, theme, colorScheme, task)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTaskItem(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    Task task,
  ) {
    final dueText = task.dueAt != null
        ? 'Due: ${task.dueAt!.day}/${task.dueAt!.month}/${task.dueAt!.year}'
        : 'No due date';

    final isApp = task.taskType == TaskType.application;

    return StreamBuilder<TaskContextEntry?>(
      stream: widget.database.watchTaskContextByTaskId(task.id),
      builder: (context, ctxSnapshot) {
        final ctx = ctxSnapshot.data;
        final hasApplied = ctx?.hasApplied ?? false;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: hasApplied
                  ? Colors.green.shade300
                  : isApp
                      ? Colors.amber.shade400.withValues(alpha: 0.5)
                      : colorScheme.outlineVariant,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.pushNamed(
                context,
                AstraRoutes.taskDetail,
                arguments: {'task': task},
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isApp
                              ? Colors.amber.shade900.withValues(alpha: 0.15)
                              : colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isApp ? '📋 APPLICATION' : task.taskType.value,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isApp ? Colors.amber.shade900 : colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (ctx?.companyName != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            ctx!.companyName!,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                      const Spacer(),
                      if (hasApplied)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            '✅ APPLIED',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        )
                      else if (task.priority == TaskPriority.high || task.priority == TaskPriority.urgent)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '🔥 ${task.priority.value}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    task.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (task.description != null && task.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      task.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(LucideIcons.calendar, size: 14, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        dueText,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Tap for full context →',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
