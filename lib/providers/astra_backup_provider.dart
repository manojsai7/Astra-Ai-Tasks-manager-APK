import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/data/astra_backup_service.dart';
import '../services/data/astra_restore_service.dart';
import 'chat_session_provider.dart';
import 'reminder_provider.dart';
import 'ritual_provider.dart';
import 'task_provider.dart';

/// Provider for [AstraBackupService].
final astraBackupServiceProvider = Provider<AstraBackupService>((ref) {
  final db = ref.watch(databaseProvider);
  return AstraBackupService(db);
});

/// Provider for [AstraRestoreService].
final astraRestoreServiceProvider = Provider<AstraRestoreService>((ref) {
  final db = ref.watch(databaseProvider);
  return AstraRestoreService(db);
});

/// Provider for querying local database statistics.
final databaseStatsProvider = FutureProvider<AstraDatabaseStats>((ref) async {
  final service = ref.watch(astraBackupServiceProvider);
  return service.getStats();
});

/// Executes full restore and refreshes all active Riverpod states cleanly.
Future<AstraRestoreResult> executeAstraRestore(
  WidgetRef ref,
  Uint8List backupBytes,
) async {
  final restoreService = ref.read(astraRestoreServiceProvider);
  final result = await restoreService.restoreBackup(backupBytes);

  // 1. Invalidate reactive stream & state providers
  ref.invalidate(taskListProvider);
  ref.invalidate(chatSessionProvider);
  ref.invalidate(currentSessionIdProvider);
  ref.invalidate(ritualRulesProvider);
  ref.invalidate(databaseStatsProvider);

  // 2. Reload tasks & reconcile pending OS alarms
  await ref.read(taskNotifierProvider.notifier).loadTasks();
  try {
    await ref.read(reminderServiceProvider).reconcilePendingReminders();
  } catch (_) {}

  return result;
}
