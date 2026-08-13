import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/database.dart';
import '../services/notification_service.dart';
import '../services/reminder_service.dart';
import 'ritual_provider.dart';

final reminderServiceProvider = Provider<ReminderService>((ref) {
  final db = ref.watch(databaseProvider);
  return ReminderService(db);
});

/// Bootstraps notification action handling and reminder reconciliation.
Future<void> bootstrapReminderEngine(AppDatabase db) async {
  final service = ReminderService(db);
  NotificationService.setActionCallback(service.handleNotificationAction);
  await service.reconcilePendingReminders();
}

/// Runs once at app startup — wires notification actions and reconciles reminders.
final reminderBootstrapProvider = FutureProvider<void>((ref) async {
  final db = ref.watch(databaseProvider);
  await bootstrapReminderEngine(db);
});
