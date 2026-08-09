import 'package:flutter/material.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';

/// Minimal tasks list screen showing all persisted tasks.
class TasksScreen extends StatelessWidget {
  final TaskRepository repository;

  const TasksScreen({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(title: const Text('Persisted Tasks')),
      body: SafeArea(
        child: StreamBuilder<List<Task>>(
          stream: repository.watchTasks(),
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
            if (tasks.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.task_alt_outlined,
                      size: 48,
                      color: colorScheme.outline,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No tasks created yet.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16.0),
              itemCount: tasks.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final task = tasks[index];
                final dueText = task.dueAt != null
                    ? 'Due: ${task.dueAt!.toLocal()}'
                    : 'No due date';

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        if (task.description != null &&
                            task.description!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            task.description!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Type: ${task.taskType.value}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.primary,
                              ),
                            ),
                            Text(
                              'Priority: ${task.priority.value}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.secondary,
                              ),
                            ),
                            Text(
                              dueText,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
