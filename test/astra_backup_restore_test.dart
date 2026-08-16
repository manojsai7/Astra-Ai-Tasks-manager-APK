import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:astra/core/database/database.dart';
import 'package:astra/providers/astra_backup_provider.dart';
import 'package:astra/providers/ritual_provider.dart';
import 'package:astra/providers/task_provider.dart';
import 'package:astra/providers/reminder_provider.dart';
import 'package:astra/services/data/astra_backup_service.dart';
import 'package:astra/services/data/astra_restore_service.dart';
import 'package:astra/services/reminder_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ASTRA M3 — Local Database Backup & Restore Tests', () {
    late AppDatabase db;
    late AstraBackupService backupService;
    late AstraRestoreService restoreService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      db = AppDatabase(NativeDatabase.memory());
      backupService = AstraBackupService(db);
      restoreService = AstraRestoreService(db);

      // Seed initial test data
      final now = DateTime(2026, 8, 16, 12, 0);

      await db.into(db.tasks).insert(
            TasksCompanion.insert(
              id: 'task_exam_1',
              title: 'Physics Midterm Exam',
              description: const Value('Hall A Room 102'),
              dueAt: Value(DateTime(2026, 8, 20, 10, 0)),
              startAt: Value(DateTime(2026, 8, 20, 10, 0)),
              endAt: Value(DateTime(2026, 8, 20, 12, 0)),
              priority: const Value('high'),
              status: const Value('active'),
              subtasksJson: const Value('[{"id":"s1","name":"Bring Calculator","isCompleted":true}]'),
              organization: const Value('University'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      await db.into(db.chatSessions).insert(
            ChatSessionsCompanion.insert(
              id: const Value(1),
              title: const Value('Study Plan Chat'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      await db.into(db.chatMessages).insert(
            ChatMessagesCompanion.insert(
              id: const Value(101),
              sessionId: 1,
              role: 'user',
              content: 'What exams do I have next week?',
              timestamp: now,
            ),
          );

      await db.into(db.taskContexts).insert(
            TaskContextsCompanion.insert(
              id: const Value(1),
              taskId: 'task_exam_1',
              role: const Value('Student preparing for Physics Midterm'),
              companyName: const Value('University'),
            ),
          );

      await db.into(db.reminders).insert(
            RemindersCompanion.insert(
              id: 'rem_1',
              taskId: 'task_exam_1',
              scheduledAt: DateTime(2026, 8, 20, 9, 50),
              notificationId: 9001,
              status: const Value('scheduled'),
              createdAt: now,
              updatedAt: now,
            ),
          );
    });

    tearDown(() async {
      await db.close();
    });

    test('A. Backup Metadata: contains format version, schema version, signature and appVersion', () async {
      final payload = await backupService.createBackup(appVersion: '2.1.3');

      expect(payload.metadata.signature, 'ASTRA_BACKUP_V1');
      expect(payload.metadata.backupVersion, 1);
      expect(payload.metadata.schemaVersion, 9);
      expect(payload.metadata.appVersion, '2.1.3');
      expect(payload.metadata.taskCount, 1);
      expect(payload.metadata.sessionCount, 1);
      expect(payload.metadata.messageCount, 1);
      expect(payload.metadata.memoryCount, 1);
      expect(payload.metadata.reminderCount, 1);
      expect(payload.metadata.checksum.isNotEmpty, isTrue);
    });

    test('B. Backup Integrity: SHA-256 checksum is valid over payload data', () async {
      final payload = await backupService.createBackup();
      final bytes = payload.toBytes();

      final validatedMetadata = restoreService.validateBackup(bytes);
      expect(validatedMetadata.checksum, payload.metadata.checksum);
    });

    test('C. Backup Contents: contains tasks, chat sessions, messages, and memories', () async {
      final payload = await backupService.createBackup();
      final data = payload.data;

      final tasks = data['tasks'] as List;
      expect(tasks.length, 1);
      expect(tasks.first['title'], 'Physics Midterm Exam');
      expect(tasks.first['startAt'], '2026-08-20T10:00:00.000');
      expect(tasks.first['endAt'], '2026-08-20T12:00:00.000');

      final messages = data['chatMessages'] as List;
      expect(messages.length, 1);
      expect(messages.first['content'], 'What exams do I have next week?');

      final memories = data['taskContexts'] as List;
      expect(memories.length, 1);
      expect(memories.first['role'], 'Student preparing for Physics Midterm');
    });

    test('D. Secrets Excluded: no OAuth tokens or client credentials exist in backup JSON', () async {
      final payload = await backupService.createBackup();
      final jsonString = payload.toJsonString();

      expect(jsonString.contains('accessToken'), isFalse);
      expect(jsonString.contains('refreshToken'), isFalse);
      expect(jsonString.contains('clientSecret'), isFalse);
      expect(jsonString.contains('password'), isFalse);
    });

    test('E. Invalid Backup Rejected: throws on bad signature', () {
      final invalidJson = jsonEncode({
        'metadata': {
          'signature': 'CORRUPTED_SIGNATURE',
          'schemaVersion': 9,
          'checksum': 'abc',
        },
        'data': {},
      });

      expect(
        () => restoreService.validateBackup(Uint8List.fromList(utf8.encode(invalidJson))),
        throwsA(isA<AstraRestoreException>().having((e) => e.code, 'code', 'invalid_signature')),
      );
    });

    test('F. Corrupt Backup Rejected: throws on checksum mismatch', () async {
      final payload = await backupService.createBackup();
      final payloadMap = payload.toJson();

      // Tamper with data payload
      (payloadMap['data'] as Map<String, dynamic>)['tasks'] = [];

      final tamperedBytes = Uint8List.fromList(utf8.encode(jsonEncode(payloadMap)));

      expect(
        () => restoreService.validateBackup(tamperedBytes),
        throwsA(isA<AstraRestoreException>().having((e) => e.code, 'code', 'checksum_mismatch')),
      );
    });

    test('G. Schema Migration Compatibility: accepts v8 schema backup without startAt/endAt gracefully', () async {
      final legacyData = {
        'tasks': [
          {
            'id': 'old_task_1',
            'title': 'Legacy Task',
            'taskType': 'reminder',
            'priority': 'medium',
            'status': 'pending',
            'order': 0,
            'subtasksJson': '[]',
            'dueAt': '2026-08-25T14:00:00.000',
            'createdAt': '2026-08-16T12:00:00.000',
            'updatedAt': '2026-08-16T12:00:00.000',
          }
        ],
        'chatSessions': [],
        'chatMessages': [],
        'taskContexts': [],
        'reminders': [],
        'ritualRules': [],
        'inboxItems': [],
      };

      final dataString = jsonEncode(legacyData);
      final checksum = sha256.convert(utf8.encode(dataString)).toString();

      final legacyPayload = AstraBackupPayload(
        metadata: AstraBackupMetadata(
          schemaVersion: 8,
          createdAt: DateTime(2026, 8, 16),
          appVersion: '2.0.0',
          taskCount: 1,
          sessionCount: 0,
          messageCount: 0,
          memoryCount: 0,
          reminderCount: 0,
          ritualRuleCount: 0,
          checksum: checksum,
        ),
        data: legacyData,
      );

      final freshDb = AppDatabase(NativeDatabase.memory());
      final freshRestore = AstraRestoreService(freshDb);
      final result = await freshRestore.restoreBackup(legacyPayload.toBytes());

      expect(result.success, isTrue);
      expect(result.tasksRestored, 1);

      final restoredTasks = await freshDb.select(freshDb.tasks).get();
      expect(restoredTasks.length, 1);
      expect(restoredTasks.first.title, 'Legacy Task');
      expect(restoredTasks.first.startAt, isNull);
      expect(restoredTasks.first.endAt, isNull);

      await freshDb.close();
    });

    test('H. Restore Preserves Tasks: full field fidelity including startAt and endAt', () async {
      final payload = await backupService.createBackup();
      final bytes = payload.toBytes();

      final freshDb = AppDatabase(NativeDatabase.memory());
      final freshRestore = AstraRestoreService(freshDb);

      await freshRestore.restoreBackup(bytes);

      final tasks = await freshDb.select(freshDb.tasks).get();
      expect(tasks.length, 1);
      final task = tasks.first;
      expect(task.title, 'Physics Midterm Exam');
      expect(task.startAt, DateTime(2026, 8, 20, 10, 0));
      expect(task.endAt, DateTime(2026, 8, 20, 12, 0));
      expect(task.organization, 'University');

      await freshDb.close();
    });

    test('I. Restore Preserves Chat History: sessions and messages are fully restored', () async {
      final payload = await backupService.createBackup();
      final bytes = payload.toBytes();

      final freshDb = AppDatabase(NativeDatabase.memory());
      final freshRestore = AstraRestoreService(freshDb);

      await freshRestore.restoreBackup(bytes);

      final sessions = await freshDb.select(freshDb.chatSessions).get();
      expect(sessions.length, 1);
      expect(sessions.first.title, 'Study Plan Chat');

      final messages = await freshDb.select(freshDb.chatMessages).get();
      expect(messages.length, 1);
      expect(messages.first.content, 'What exams do I have next week?');

      await freshDb.close();
    });

    test('J. Restore Preserves Memories: task contexts and memories intact', () async {
      final payload = await backupService.createBackup();
      final bytes = payload.toBytes();

      final freshDb = AppDatabase(NativeDatabase.memory());
      final freshRestore = AstraRestoreService(freshDb);

      await freshRestore.restoreBackup(bytes);

      final memories = await freshDb.select(freshDb.taskContexts).get();
      expect(memories.length, 1);
      expect(memories.first.role, 'Student preparing for Physics Midterm');

      await freshDb.close();
    });

    test('K. Restore Refreshes State: riverpod container reloads taskNotifier and invalidates cache', () async {
      final payload = await backupService.createBackup();
      final bytes = payload.toBytes();

      final targetDb = AppDatabase(NativeDatabase.memory());
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(targetDb),
          reminderServiceProvider.overrideWithValue(ReminderService(targetDb)),
          taskNotifierProvider.overrideWith((ref) => TaskNotifier(targetDb, ReminderService(targetDb))..loadTasks()),
        ],
      );

      final restoreService = container.read(astraRestoreServiceProvider);
      final result = await restoreService.restoreBackup(bytes);
      expect(result.success, isTrue);

      container.invalidate(taskListProvider);
      await container.read(taskNotifierProvider.notifier).loadTasks();

      final tasks = container.read(taskNotifierProvider);
      expect(tasks.length, 1);
      expect(tasks.first.title, 'Physics Midterm Exam');

      container.dispose();
      await targetDb.close();
    });

    test('L. Failed Restore Leaves Current DB Untouched: live database remains pristine on error', () async {
      // Current DB has 1 task
      final initialTasks = await db.select(db.tasks).get();
      expect(initialTasks.length, 1);

      // Attempt restore with corrupted bytes
      final corruptBytes = Uint8List.fromList(utf8.encode('{"corrupt": true}'));

      expect(
        () => restoreService.restoreBackup(corruptBytes),
        throwsA(isA<AstraRestoreException>()),
      );

      // Live database must remain 100% untouched
      final afterTasks = await db.select(db.tasks).get();
      expect(afterTasks.length, 1);
      expect(afterTasks.first.title, 'Physics Midterm Exam');
    });
  });
}
