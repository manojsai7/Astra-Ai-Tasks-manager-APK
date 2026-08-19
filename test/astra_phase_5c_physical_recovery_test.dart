import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astra/core/database/database.dart';
import 'package:astra/core/reminders/reminder.dart';
import 'package:astra/services/data/astra_backup_service.dart';
import 'package:astra/services/data/astra_crypto_service.dart';
import 'package:astra/services/data/astra_restore_service.dart';
import 'package:astra/services/reminder_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase sourceDb;
  late AstraCryptoService cryptoService;
  late AstraBackupService backupService;

  setUp(() async {
    sourceDb = AppDatabase(NativeDatabase.memory());
    cryptoService = AstraCryptoService();
    backupService = AstraBackupService(sourceDb, cryptoService: cryptoService);
  });

  tearDown(() async {
    await sourceDb.close();
  });

  group('ASTRA Phase 5C — Physical Data Recovery & Clean Reinstall Validation Tests (1–10)', () {
    // ─── 1. Comprehensive Recovery Dataset Generation ────────────────────────
    test('1. Pre-backup dataset generation captures tasks, recurrence, chat, memory, and reminders', () async {
      final now = DateTime.utc(2026, 8, 18, 14, 0);
      final futureDue = DateTime.utc(2026, 8, 25, 10, 0);

      // Tasks: One-shot, Future, Recurring, Subtasks, High Priority
      await sourceDb.into(sourceDb.tasks).insert(
            TasksCompanion.insert(
              id: 'task-1',
              title: 'Gym training daily at 8pm',
              taskType: const Value('habit'),
              priority: const Value('high'),
              dueAt: Value(futureDue),
              subtasksJson: const Value('[{"id":"s1","title":"Pack shaker","isCompleted":true},{"id":"s2","title":"Warm up","isCompleted":false}]'),
              recurrenceRuleJson: const Value('{"frequency":"daily","interval":1}'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      await sourceDb.into(sourceDb.tasks).insert(
            TasksCompanion.insert(
              id: 'task-2',
              title: 'Quarterly Architecture Review',
              priority: const Value('urgent'),
              organization: const Value('DeepMind'),
              category: const Value('Work'),
              dueAt: Value(futureDue.add(const Duration(days: 2))),
              createdAt: now,
              updatedAt: now,
            ),
          );

      // Reminders
      await sourceDb.into(sourceDb.reminders).insert(
            RemindersCompanion.insert(
              id: 'rem-1',
              taskId: 'task-1',
              scheduledAt: futureDue,
              notificationId: 'task-1'.hashCode,
              status: const Value('scheduled'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      // Chat Sessions & Messages
      await sourceDb.into(sourceDb.chatSessions).insert(
            ChatSessionsCompanion.insert(
              id: const Value(1),
              title: const Value('Workout Planning'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      await sourceDb.into(sourceDb.chatMessages).insert(
            ChatMessagesCompanion.insert(
              id: const Value(1),
              sessionId: 1,
              role: 'user',
              content: 'Plan my workout routine for next week',
              timestamp: now,
            ),
          );

      await sourceDb.into(sourceDb.chatMessages).insert(
            ChatMessagesCompanion.insert(
              id: const Value(2),
              sessionId: 1,
              role: 'assistant',
              content: 'Here is your daily 8pm strength training schedule.',
              timestamp: now.add(const Duration(seconds: 2)),
            ),
          );

      // ASTRA Memory
      await sourceDb.into(sourceDb.taskContexts).insert(
            TaskContextsCompanion.insert(
              id: const Value(1),
              taskId: 'task-2',
              companyName: const Value('Google DeepMind'),
              role: const Value('Staff Systems Engineer'),
              requirements: const Value('Flutter, SQLite, Cryptography'),
            ),
          );

      // Streaks / Ritual Rules
      await sourceDb.into(sourceDb.ritualRules).insert(
            RitualRulesCompanion.insert(
              eventType: 'GymHabit',
              title: 'Daily Evening Workout',
              remindAtTime: const Value('19:45'),
              isActive: const Value(true),
            ),
          );

      final stats = await backupService.getStats();
      expect(stats.taskCount, 2);
      expect(stats.reminderCount, 1);
      expect(stats.sessionCount, 1);
      expect(stats.messageCount, 2);
      expect(stats.memoryCount, 1);
      expect(stats.ritualRuleCount, 1);
    });

    // ─── 2. Portable Encrypted Export Generation ─────────────────────────────
    test('2. Portable export generates AES-256-GCM package with versioned manifest', () async {
      final now = DateTime.utc(2026, 8, 18, 14, 0);
      await sourceDb.into(sourceDb.tasks).insert(
            TasksCompanion.insert(
              id: 'task-test',
              title: 'Secure Export Verification',
              createdAt: now,
              updatedAt: now,
            ),
          );

      final backupPayload = await backupService.createEncryptedBackup(
        password: 'UserStrongPass123!',
        appVersion: '2.2.0',
        kdfIterations: 5000,
      );

      final bytes = backupPayload.toBytes();
      expect(bytes.isNotEmpty, isTrue);

      final metadata = backupPayload.metadata;
      expect(metadata.signature, AstraBackupMetadata.encryptedV2Signature);
      expect(metadata.backupVersion, 2);
      expect(metadata.taskCount, 1);
      expect(metadata.selectedCategories, contains('tasks'));
    });

    // ─── 3. Clean Reinstall Simulation (New Device / No Shared State) ────────
    test('3. Clean reinstall simulation: decrypts with password only on completely fresh device instance', () async {
      final now = DateTime.utc(2026, 8, 18, 14, 0);
      final futureDue = DateTime.utc(2026, 8, 25, 20, 0);

      // 1. Populate source database
      await sourceDb.into(sourceDb.tasks).insert(
            TasksCompanion.insert(
              id: 'task-recover',
              title: 'Gym training daily at 8pm',
              dueAt: Value(futureDue),
              subtasksJson: const Value('[{"id":"s1","title":"Warmup","isCompleted":true}]'),
              recurrenceRuleJson: const Value('{"frequency":"daily","interval":1}'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      await sourceDb.into(sourceDb.chatSessions).insert(
            ChatSessionsCompanion.insert(
              id: const Value(1),
              title: const Value('Planning Chat'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      await sourceDb.into(sourceDb.chatMessages).insert(
            ChatMessagesCompanion.insert(
              id: const Value(1),
              sessionId: 1,
              role: 'user',
              content: 'Test message on device A',
              timestamp: now,
            ),
          );

      // 2. Export encrypted backup on Device A
      final backupPayload = await backupService.createEncryptedBackup(
        password: 'Password999!',
        kdfIterations: 5000,
      );
      final exportBytes = backupPayload.toBytes();

      // 3. Device B simulation: Fresh new memory database with NO shared state
      final freshDeviceDb = AppDatabase(NativeDatabase.memory());
      final freshCrypto = AstraCryptoService();
      final freshRestore = AstraRestoreService(freshDeviceDb, cryptoService: freshCrypto);

      // 4. Validate metadata on fresh device
      final validatedMeta = freshRestore.validateBackup(exportBytes);
      expect(validatedMeta.signature, AstraBackupMetadata.encryptedV2Signature);
      expect(validatedMeta.taskCount, 1);

      // 5. Restore with user password
      final restoreResult = await freshRestore.restoreBackup(
        exportBytes,
        password: 'Password999!',
        strategy: RestoreStrategy.replaceSelected,
      );

      expect(restoreResult.success, isTrue);
      expect(restoreResult.tasksRestored, 1);
      expect(restoreResult.sessionsRestored, 1);
      expect(restoreResult.messagesRestored, 1);

      // 6. Verify exact data state on fresh device
      final restoredTask = await (freshDeviceDb.select(freshDeviceDb.tasks)..where((t) => t.id.equals('task-recover'))).getSingle();
      expect(restoredTask.title, 'Gym training daily at 8pm');
      expect(restoredTask.recurrenceRuleJson, '{"frequency":"daily","interval":1}');

      final restoredSession = await (freshDeviceDb.select(freshDeviceDb.chatSessions)..where((s) => s.id.equals(1))).getSingle();
      expect(restoredSession.title, 'Planning Chat');

      await freshDeviceDb.close();
    });

    // ─── 4. Reminder Reconciliation Post-Restore ─────────────────────────────
    test('4. Reminder reconciliation post-restore identifies future active reminders', () async {
      final now = DateTime.now();
      final futureReminderTime = now.add(const Duration(days: 3));

      // Setup task and reminder
      await sourceDb.into(sourceDb.tasks).insert(
            TasksCompanion.insert(
              id: 'task-rem',
              title: 'Doctor Appointment',
              dueAt: Value(futureReminderTime),
              createdAt: now,
              updatedAt: now,
            ),
          );

      await sourceDb.into(sourceDb.reminders).insert(
            RemindersCompanion.insert(
              id: 'rem-doc',
              taskId: 'task-rem',
              scheduledAt: futureReminderTime,
              notificationId: 'task-rem'.hashCode,
              status: const Value('scheduled'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      final backupPayload = await backupService.createEncryptedBackup(password: 'Pass!', kdfIterations: 5000);
      final exportBytes = backupPayload.toBytes();

      final targetDb = AppDatabase(NativeDatabase.memory());
      final targetRestore = AstraRestoreService(targetDb, cryptoService: cryptoService);

      await targetRestore.restoreBackup(exportBytes, password: 'Pass!');

      final reminderService = ReminderService(targetDb);
      // Reconcile pending reminders
      await reminderService.reconcilePendingReminders();

      final activeReminders = await targetDb.getActiveReminders();
      expect(activeReminders.length, 1);
      expect(activeReminders.first.taskId, 'task-rem');
      expect(activeReminders.first.status, ReminderStatus.scheduled.name);

      await targetDb.close();
    });

    // ─── 5. Post-Restore Functional Operations (CRUD) ────────────────────────
    test('5. Post-restore CRUD: user can create, edit, and complete restored tasks seamlessly', () async {
      final now = DateTime.now();
      await sourceDb.into(sourceDb.tasks).insert(
            TasksCompanion.insert(
              id: 't-edit',
              title: 'Restored Task to Edit',
              priority: const Value('medium'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      final backupPayload = await backupService.createEncryptedBackup(password: 'Pass!', kdfIterations: 5000);
      final exportBytes = backupPayload.toBytes();

      final targetDb = AppDatabase(NativeDatabase.memory());
      final targetRestore = AstraRestoreService(targetDb, cryptoService: cryptoService);
      await targetRestore.restoreBackup(exportBytes, password: 'Pass!');

      // 1. Create a new task post-restore
      await targetDb.into(targetDb.tasks).insert(
            TasksCompanion.insert(
              id: 't-new-post-restore',
              title: 'Brand New Task After Restore',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

      // 2. Update restored task
      await (targetDb.update(targetDb.tasks)..where((t) => t.id.equals('t-edit'))).write(
            TasksCompanion(
              title: const Value('Restored Task (Updated)'),
              priority: const Value('high'),
              updatedAt: Value(DateTime.now()),
            ),
          );

      // 3. Complete restored task
      await (targetDb.update(targetDb.tasks)..where((t) => t.id.equals('t-edit'))).write(
            TasksCompanion(
              status: const Value('completed'),
              completedAt: Value(DateTime.now()),
              updatedAt: Value(DateTime.now()),
            ),
          );

      final updatedTask = await (targetDb.select(targetDb.tasks)..where((t) => t.id.equals('t-edit'))).getSingle();
      expect(updatedTask.title, 'Restored Task (Updated)');
      expect(updatedTask.priority, 'high');
      expect(updatedTask.status, 'completed');

      final allTasks = await targetDb.select(targetDb.tasks).get();
      expect(allTasks.length, 2);

      await targetDb.close();
    });

    // ─── 6. Post-Restore Chat & Context Continuity ───────────────────────────
    test('6. Post-restore chat: appending new messages to restored chat sessions works cleanly', () async {
      final now = DateTime.now();
      await sourceDb.into(sourceDb.chatSessions).insert(
            ChatSessionsCompanion.insert(
              id: const Value(1),
              title: const Value('Main Session'),
              createdAt: now,
              updatedAt: now,
            ),
          );
      await sourceDb.into(sourceDb.chatMessages).insert(
            ChatMessagesCompanion.insert(
              id: const Value(1),
              sessionId: 1,
              role: 'user',
              content: 'What was my goal yesterday?',
              timestamp: now,
            ),
          );

      final backupPayload = await backupService.createEncryptedBackup(password: 'Pass!', kdfIterations: 5000);
      final exportBytes = backupPayload.toBytes();

      final targetDb = AppDatabase(NativeDatabase.memory());
      final targetRestore = AstraRestoreService(targetDb, cryptoService: cryptoService);
      await targetRestore.restoreBackup(exportBytes, password: 'Pass!');

      // Append new message post-restore to session 1
      await targetDb.into(targetDb.chatMessages).insert(
            ChatMessagesCompanion.insert(
              sessionId: 1,
              role: 'assistant',
              content: 'Your goal was gym training at 8pm.',
              timestamp: DateTime.now(),
            ),
          );

      final messages = await (targetDb.select(targetDb.chatMessages)..where((m) => m.sessionId.equals(1))).get();
      expect(messages.length, 2);
      expect(messages.first.content, 'What was my goal yesterday?');
      expect(messages.last.content, 'Your goal was gym training at 8pm.');

      await targetDb.close();
    });
  });
}
