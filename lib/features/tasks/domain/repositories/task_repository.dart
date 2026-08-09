import '../entities/task.dart';

/// Repository contract defining persistence operations for tasks.
abstract interface class TaskRepository {
  /// Persists a new or updated [Task] in local storage.
  Future<void> saveTask(Task task);

  /// Exposes a stream of all tasks sorted chronologically by creation time.
  Stream<List<Task>> watchTasks();

  /// Retrieves a task by its unique identifier, or null if not found.
  Future<Task?> getTaskById(String id);
}
