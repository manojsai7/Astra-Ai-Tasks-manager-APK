import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/database.dart';
import '../models/task.dart';
import '../services/assistant/astra_recurrence_engine.dart';
import '../services/reminder_service.dart';
import 'reminder_provider.dart';
import 'ritual_provider.dart'; // exposes databaseProvider

enum SortMode {
  myOrder,
  byDate,
  byPriority,
}

// ─── Reactive Stream Provider (Drift-backed) ─────────────────────────────────

final taskListProvider = StreamProvider<List<Task>>((ref) {
  final db = ref.watch(databaseProvider);

  return (db.select(db.tasks)
        ..orderBy([
          (t) => OrderingTerm(expression: t.order, mode: OrderingMode.asc),
          (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
        ]))
      .watch()
      .map((rows) => rows.map(_rowToTask).toList());
});

// ─── Sort Mode Provider ───────────────────────────────────────────────────────

final sortModeProvider = StateProvider<SortMode>((ref) => SortMode.myOrder);

// ─── Task CRUD Notifier (Drift-backed) ────────────────────────────────────────

final taskNotifierProvider =
    StateNotifierProvider<TaskNotifier, List<Task>>((ref) {
  final db = ref.watch(databaseProvider);
  final reminders = ref.watch(reminderServiceProvider);
  return TaskNotifier(db, reminders)..loadTasks();
});

class TaskNotifier extends StateNotifier<List<Task>> {
  final AppDatabase _db;
  final ReminderService _reminders;

  TaskNotifier(this._db, this._reminders) : super([]);

  // ─── Read ───────────────────────────────────────────────────────────────────

  Future<void> loadTasks() async {
    final rows = await (_db.select(_db.tasks)
          ..orderBy([
            (t) => OrderingTerm(expression: t.order, mode: OrderingMode.asc),
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .get();
    if (!mounted) return;
    state = rows.map(_rowToTask).toList();
  }

  // ─── Create ─────────────────────────────────────────────────────────────────

  Future<void> addTask(Task task) async {
    final now = DateTime.now();
    final subtasksJson = jsonEncode(task.subtasks.map((s) => s.toJson()).toList());

    await _db.into(_db.tasks).insertOnConflictUpdate(
          TasksCompanion(
            id: Value(task.id),
            title: Value(task.title),
            description: Value(task.description),
            taskType: const Value('reminder'),
            priority: Value(task.priority),
            status: Value(task.status),
            order: Value(task.order),
            subtasksJson: Value(subtasksJson),
            dueAt: Value(task.dueDate),
            startAt: Value(task.startAt),
            endAt: Value(task.endAt),
            completedAt: Value(task.completedAt),
            createdAt: Value(task.createdAt),
            updatedAt: Value(task.updatedAt ?? now),
            source: Value(task.source),
            sourceId: Value(task.sourceId),
            category: Value(task.category),
            organization: Value(task.organization),
            recurrenceRuleJson: Value(task.recurrenceRule?.toJson()),
          ),
        );
    if (!mounted) return;
    await loadTasks();
  }

  // ─── State Machine Transition ─────────────────────────────────────────────

  Future<void> setStatus(String id, String newStatus) async {
    final task = state.firstWhere((t) => t.id == id, orElse: () => throw Exception('Task $id not found'));
    final isCompleted = newStatus == 'completed';
    final now = DateTime.now();

    // Cascade completion to subtasks if completing task
    List<SubTask> updatedSubtasks = task.subtasks;
    if (isCompleted) {
      updatedSubtasks = task.subtasks.map((s) => s.copyWith(isCompleted: true)).toList();
    }
    final subtasksJson = jsonEncode(updatedSubtasks.map((s) => s.toJson()).toList());

    await (_db.update(_db.tasks)..where((t) => t.id.equals(id))).write(
      TasksCompanion(
        status: Value(newStatus),
        completedAt: Value(isCompleted ? (task.completedAt ?? now) : null),
        subtasksJson: Value(subtasksJson),
        updatedAt: Value(now),
      ),
    );
    if (!mounted) return;
    await loadTasks();
  }

  // ─── Toggle completion (backward compatible helper) ─────────────────────────

  Future<void> toggleComplete(String id) async {
    final task = state.firstWhere((t) => t.id == id, orElse: () => throw Exception('Task $id not found'));
    final newStatus = task.status == 'completed' ? 'pending' : 'completed';
    await setStatus(id, newStatus);
    if (newStatus == 'completed') {
      await _reminders.cancelReminderForTask(id);
    }
  }

  // ─── Toggle Subtask ─────────────────────────────────────────────────────────

  Future<void> toggleSubtask(String taskId, String subtaskId) async {
    final task = state.firstWhere((t) => t.id == taskId, orElse: () => throw Exception('Task $taskId not found'));
    final updatedSubtasks = task.subtasks.map((s) {
      if (s.id == subtaskId) {
        return s.copyWith(isCompleted: !s.isCompleted);
      }
      return s;
    }).toList();

    // Check if all subtasks completed
    final allDone = updatedSubtasks.isNotEmpty && updatedSubtasks.every((s) => s.isCompleted);
    final newStatus = allDone ? 'completed' : task.status;
    final subtasksJson = jsonEncode(updatedSubtasks.map((s) => s.toJson()).toList());
    final now = DateTime.now();

    await (_db.update(_db.tasks)..where((t) => t.id.equals(taskId))).write(
      TasksCompanion(
        status: Value(newStatus),
        subtasksJson: Value(subtasksJson),
        completedAt: Value(allDone ? (task.completedAt ?? now) : null),
        updatedAt: Value(now),
      ),
    );
    if (!mounted) return;
    await loadTasks();
  }

  // ─── Drag & Drop Reorder ───────────────────────────────────────────────────

  Future<void> reorderTasks(int oldIndex, int newIndex) async {
    final currentTasks = List<Task>.from(state);
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = currentTasks.removeAt(oldIndex);
    currentTasks.insert(newIndex, item);

    // Update order indices in DB
    for (int i = 0; i < currentTasks.length; i++) {
      await (_db.update(_db.tasks)..where((t) => t.id.equals(currentTasks[i].id))).write(
        TasksCompanion(
          order: Value(i),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }

    await loadTasks();
  }

  // ─── Delete ─────────────────────────────────────────────────────────────────

  Future<void> deleteTask(String id) async {
    await _reminders.cancelReminderForTask(id);
    await (_db.delete(_db.tasks)..where((t) => t.id.equals(id))).go();
    if (!mounted) return;
    await loadTasks();
  }

  // ─── Update ─────────────────────────────────────────────────────────────────

  Future<void> updateTask(Task updated) async {
    final now = DateTime.now();
    final subtasksJson = jsonEncode(updated.subtasks.map((s) => s.toJson()).toList());

    await (_db.update(_db.tasks)..where((t) => t.id.equals(updated.id))).write(
      TasksCompanion(
        title: Value(updated.title),
        description: Value(updated.description),
        priority: Value(updated.priority),
        status: Value(updated.status),
        order: Value(updated.order),
        subtasksJson: Value(subtasksJson),
        dueAt: Value(updated.dueDate),
        startAt: Value(updated.startAt),
        endAt: Value(updated.endAt),
        completedAt: Value(updated.completedAt),
        updatedAt: Value(now),
        source: Value(updated.source),
        sourceId: Value(updated.sourceId),
        category: Value(updated.category),
        organization: Value(updated.organization),
        recurrenceRuleJson: Value(updated.recurrenceRule?.toJson()),
      ),
    );
    if (!mounted) return;
    await loadTasks();
  }
}

// ─── Sort Helper ─────────────────────────────────────────────────────────────

List<Task> sortTasks(List<Task> tasks, SortMode mode) {
  final list = List<Task>.from(tasks);
  switch (mode) {
    case SortMode.myOrder:
      list.sort((a, b) => a.order.compareTo(b.order));
      return list;
    case SortMode.byDate:
      final withDate = list.where((t) => t.dueDate != null || t.startAt != null).toList()
        ..sort((a, b) {
          final aDate = a.dueDate ?? a.startAt!;
          final bDate = b.dueDate ?? b.startAt!;
          return aDate.compareTo(bDate);
        });
      final noDate = list.where((t) => t.dueDate == null && t.startAt == null).toList()
        ..sort((a, b) => a.order.compareTo(b.order));
      return [...withDate, ...noDate];
    case SortMode.byPriority:
      const rank = {'high': 0, 'medium': 1, 'low': 2};
      list.sort((a, b) => (rank[a.priority] ?? 1).compareTo(rank[b.priority] ?? 1));
      return list;
  }
}

// ─── Conversion Helper ────────────────────────────────────────────────────────

Task _rowToTask(TaskEntry row) {
  List<SubTask> subtasks = [];
  if (row.subtasksJson.isNotEmpty && row.subtasksJson != '[]') {
    try {
      final List decoded = jsonDecode(row.subtasksJson);
      subtasks = decoded.map((s) => SubTask.fromJson(s as Map<String, dynamic>)).toList();
    } catch (_) {}
  }

  RecurrenceRule? recurrenceRule;
  if (row.recurrenceRuleJson != null && row.recurrenceRuleJson!.trim().isNotEmpty) {
    try {
      recurrenceRule = RecurrenceRule.fromJson(row.recurrenceRuleJson!);
    } catch (e) {
      debugPrint('[task_provider] Warning: Failed to parse recurrenceRuleJson for task ${row.id}: $e');
    }
  }

  return Task(
    id: row.id,
    title: row.title,
    description: row.description,
    dueDate: row.dueAt,
    startAt: row.startAt,
    endAt: row.endAt,
    status: row.status,
    priority: row.priority,
    order: row.order,
    subtasks: subtasks,
    createdAt: row.createdAt,
    completedAt: row.completedAt,
    updatedAt: row.updatedAt,
    source: row.source,
    sourceId: row.sourceId,
    category: row.category,
    organization: row.organization,
    recurrenceRule: recurrenceRule,
  );
}
