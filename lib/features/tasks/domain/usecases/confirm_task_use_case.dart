import 'package:uuid/uuid.dart';
import '../entities/task.dart';
import '../repositories/task_repository.dart';

/// Use case to confirm and persist structured task proposals in Drift database.
///
/// Implements Phase 2:
/// - Rejects empty or whitespace-only task titles.
/// - Persists a typed task.
/// - Does not modify or delete the raw Inbox item (Inbox item remains unchanged).
class ConfirmTaskUseCase {
  final TaskRepository _repository;
  final _uuid = const Uuid();

  ConfirmTaskUseCase(this._repository);

  /// Validates and persists a task.
  ///
  /// Throws [ArgumentError] if the task title is empty or whitespace-only.
  Future<void> call({
    required String title,
    String? description,
    required TaskType taskType,
    required TaskPriority priority,
    DateTime? dueAt,
    String? inboxItemId,
  }) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      throw ArgumentError('Task title cannot be empty or whitespace only.');
    }

    final now = DateTime.now();
    final task = Task(
      id: _uuid.v4(),
      inboxItemId: inboxItemId,
      title: trimmedTitle,
      description: description?.trim(),
      taskType: taskType,
      priority: priority,
      status: TaskStatus.pending,
      dueAt: dueAt,
      completedAt: null,
      createdAt: now,
      updatedAt: now,
    );

    await _repository.saveTask(task);
  }
}
