import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/task.dart';

final taskListProvider = FutureProvider<List<Task>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final tasksJson = prefs.getStringList('tasks') ?? [];
  return tasksJson.map((json) => Task.fromJson(jsonDecode(json))).toList();
});

final taskNotifierProvider = StateNotifierProvider<TaskNotifier, List<Task>>((ref) {
  return TaskNotifier();
});

class TaskNotifier extends StateNotifier<List<Task>> {
  TaskNotifier() : super([]) {
    loadTasks();
  }

  Future<void> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getStringList('tasks') ?? [];
    state = tasksJson.map((json) => Task.fromJson(jsonDecode(json))).toList();
  }

  Future<void> addTask(Task task) async {
    state = [task, ...state];
    await _saveTasks();
  }

  Future<void> toggleComplete(String id) async {
    state = state.map((task) {
      if (task.id == id) {
        return Task(
          id: task.id,
          title: task.title,
          description: task.description,
          dueDate: task.dueDate,
          priority: task.priority,
          isCompleted: !task.isCompleted,
          createdAt: task.createdAt,
        );
      }
      return task;
    }).toList();
    await _saveTasks();
  }

  Future<void> deleteTask(String id) async {
    state = state.where((task) => task.id != id).toList();
    await _saveTasks();
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = state.map((task) => jsonEncode(task.toJson())).toList();
    await prefs.setStringList('tasks', tasksJson);
  }
}
