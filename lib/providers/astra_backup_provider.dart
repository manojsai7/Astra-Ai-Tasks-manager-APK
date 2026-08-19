import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/data/astra_backup_service.dart';
import '../services/data/astra_backup_storage_service.dart';
import '../services/data/astra_crypto_service.dart';
import '../services/data/astra_restore_service.dart';
import 'chat_session_provider.dart';
import 'reminder_provider.dart';
import 'ritual_provider.dart';
import 'task_provider.dart';

/// Provider for [AstraCryptoService].
final astraCryptoServiceProvider = Provider<AstraCryptoService>((ref) {
  return AstraCryptoService();
});

/// Provider for [IAstraBackupStorageService].
final astraBackupStorageServiceProvider = Provider<IAstraBackupStorageService>((ref) {
  return const AstraBackupStorageService();
});

/// Provider for [AstraBackupService].
final astraBackupServiceProvider = Provider<AstraBackupService>((ref) {
  final db = ref.watch(databaseProvider);
  final crypto = ref.watch(astraCryptoServiceProvider);
  return AstraBackupService(db, cryptoService: crypto);
});

/// Provider for [AstraRestoreService].
final astraRestoreServiceProvider = Provider<AstraRestoreService>((ref) {
  final db = ref.watch(databaseProvider);
  final crypto = ref.watch(astraCryptoServiceProvider);
  return AstraRestoreService(db, cryptoService: crypto);
});

/// Provider for querying local database statistics.
final databaseStatsProvider = FutureProvider<AstraDatabaseStats>((ref) async {
  final service = ref.watch(astraBackupServiceProvider);
  return service.getStats();
});

/// Executes restore and refreshes all active Riverpod states cleanly.
Future<AstraRestoreResult> executeAstraRestore(
  WidgetRef ref,
  Uint8List backupBytes, {
  String? password,
  RestoreStrategy strategy = RestoreStrategy.merge,
  Set<AstraBackupCategory>? selectedCategories,
}) async {
  final restoreService = ref.read(astraRestoreServiceProvider);
  final result = await restoreService.restoreBackup(
    backupBytes,
    password: password,
    strategy: strategy,
    selectedCategories: selectedCategories,
  );

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
