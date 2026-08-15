import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:astra/core/database/database.dart';

/// Test database setup & utility helpers.
class TestDatabaseHelper {
  /// Creates a clean in-memory database.
  static AppDatabase createMemoryDatabase() {
    return AppDatabase(NativeDatabase.memory());
  }

  /// Inserts a task row directly into Drift SQLite database.
  static Future<void> insertTaskRow(
    AppDatabase db, {
    required String id,
    required String title,
    DateTime? dueAt,
    String status = 'active',
    String priority = 'medium',
    String? organization,
    String? recurrenceRuleJson,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) async {
    final now = DateTime.now();
    await db.into(db.tasks).insert(
      TasksCompanion(
        id: Value(id),
        title: Value(title),
        dueAt: Value(dueAt),
        status: Value(status),
        priority: Value(priority),
        organization: Value(organization),
        recurrenceRuleJson: Value(recurrenceRuleJson),
        createdAt: Value(createdAt ?? now),
        updatedAt: Value(updatedAt ?? now),
      ),
    );
  }

  /// Inserts a reminder row directly into Drift SQLite database.
  static Future<void> insertReminderRow(
    AppDatabase db, {
    required String id,
    required String taskId,
    required DateTime scheduledAt,
    int notificationId = 100,
    String status = 'scheduled',
    String timezone = 'Asia/Kolkata',
    DateTime? createdAt,
    DateTime? updatedAt,
  }) async {
    final now = DateTime.now();
    await db.into(db.reminders).insert(
      RemindersCompanion(
        id: Value(id),
        taskId: Value(taskId),
        scheduledAt: Value(scheduledAt),
        notificationId: Value(notificationId),
        status: Value(status),
        timezone: Value(timezone),
        createdAt: Value(createdAt ?? now),
        updatedAt: Value(updatedAt ?? now),
      ),
    );
  }
}
