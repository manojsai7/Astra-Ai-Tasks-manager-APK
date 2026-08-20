import '../../../../models/task_intent.dart';
import '../../../../models/task.dart';
import '../../../../providers/astra_command_executor_provider.dart';
import '../../../../providers/astra_memory_provider.dart';
import '../../../../providers/reminder_provider.dart';
import '../../../../services/assistant/astra_memory_engine.dart';

import '../models/astra_note.dart';

class AstraNoteActionService {
  /// Converts an [AstraNote] into a Task via existing [AstraCommandExecutor].
  static Future<String> convertNoteToTask(dynamic ref, AstraNote note, {DateTime? dueDate}) async {
    final intent = TaskIntent(
      title: note.title.isNotEmpty ? note.title : 'Task from Note',
      description: note.body,
      dueDate: dueDate,
      organization: note.organization,
      source: 'note',
      subtasks: note.checklist.map((c) => SubTask.create(c.text)).toList(),
    );

    final dynamic r = ref;
    final executor = r.read(astraCommandExecutorProvider);
    final result = await executor.executeTaskIntent(
      ref: ref,
      intent: intent,
    );
    return result.taskId;
  }

  /// Schedules a reminder for an [AstraNote] via [ReminderService].
  static Future<dynamic> scheduleNoteReminder(
    dynamic ref,
    AstraNote note,
    DateTime scheduledAt,
  ) async {
    final dynamic r = ref;
    final reminderService = r.read(reminderServiceProvider);
    return await reminderService.scheduleReminder(
      taskId: note.id,
      taskTitle: note.title.isNotEmpty ? note.title : 'Note Reminder',
      scheduledAt: scheduledAt,
    );
  }

  /// Stores an [AstraNote] summary as structured memory via [AstraMemoryEngine].
  static void storeNoteInMemory(dynamic ref, AstraNote note) {
    final dynamic r = ref;
    final memoryEngine = r.read(astraMemoryEngineProvider);
    memoryEngine.storeMemory(
      AstraMemoryItem(
        id: 'note_${note.id}',
        type: 'NOTE',
        key: note.title.isNotEmpty ? note.title : 'Untitled Note',
        value: note.body,
        createdAt: note.createdAt,
        updatedAt: note.updatedAt,
        metadata: {
          'noteId': note.id,
          'organization': note.organization,
          'tags': note.tags,
          'isPinned': note.isPinned,
        },
      ),
    );
  }
}
