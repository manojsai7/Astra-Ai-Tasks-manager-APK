import 'package:drift/drift.dart';
import '../../../../core/database/database.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';

/// Database-driven implementation of [TaskRepository] using Drift.
class TaskRepositoryImpl implements TaskRepository {
  final AppDatabase _db;

  TaskRepositoryImpl(this._db);

  @override
  Future<void> saveTask(Task task) async {
    await _db
        .into(_db.tasks)
        .insertOnConflictUpdate(
          TasksCompanion.insert(
            id: task.id,
            inboxItemId: Value(task.inboxItemId),
            title: task.title,
            description: Value(task.description),
            taskType: task.taskType.value,
            priority: task.priority.value,
            status: task.status.value,
            dueAt: Value(task.dueAt),
            completedAt: Value(task.completedAt),
            createdAt: task.createdAt,
            updatedAt: task.updatedAt,
          ),
        );
  }

  @override
  Stream<List<Task>> watchTasks() {
    final query = _db.select(_db.tasks)
      ..orderBy([
        (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
      ]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return Task(
          id: row.id,
          inboxItemId: row.inboxItemId,
          title: row.title,
          description: row.description,
          taskType: TaskType.fromValue(row.taskType),
          priority: TaskPriority.fromValue(row.priority),
          status: TaskStatus.fromValue(row.status),
          dueAt: row.dueAt,
          completedAt: row.completedAt,
          createdAt: row.createdAt,
          updatedAt: row.updatedAt,
        );
      }).toList();
    });
  }

  @override
  Future<Task?> getTaskById(String id) async {
    final query = _db.select(_db.tasks)..where((t) => t.id.equals(id));
    final row = await query.getSingleOrNull();
    if (row == null) return null;

    return Task(
      id: row.id,
      inboxItemId: row.inboxItemId,
      title: row.title,
      description: row.description,
      taskType: TaskType.fromValue(row.taskType),
      priority: TaskPriority.fromValue(row.priority),
      status: TaskStatus.fromValue(row.status),
      dueAt: row.dueAt,
      completedAt: row.completedAt,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
