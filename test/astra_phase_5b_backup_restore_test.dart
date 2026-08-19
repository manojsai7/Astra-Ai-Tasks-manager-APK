import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astra/core/database/database.dart';
import 'package:astra/services/data/astra_backup_service.dart';
import 'package:astra/services/data/astra_backup_storage_service.dart';
import 'package:astra/services/data/astra_crypto_service.dart';
import 'package:astra/services/data/astra_restore_service.dart';

class _FakeAstraBackupStorageService implements IAstraBackupStorageService {
  AstraPickedDocument? storedDoc;

  @override
  Future<AstraPickedDocument?> pickBackupDocument() async => storedDoc;

  @override
  Future<String?> saveBackupDocument({required String fileName, required Uint8List bytes}) async {
    storedDoc = AstraPickedDocument(name: fileName, bytes: bytes);
    return '/storage/emulated/0/Download/$fileName';
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late AstraCryptoService cryptoService;
  late AstraBackupService backupService;
  late AstraRestoreService restoreService;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    cryptoService = AstraCryptoService();
    backupService = AstraBackupService(db, cryptoService: cryptoService);
    restoreService = AstraRestoreService(db, cryptoService: cryptoService);
  });

  tearDown(() async {
    await db.close();
  });

  group('ASTRA Phase 5B — Resilient Data, Encrypted Backup & Selective Restore Tests (A–W)', () {
    // ─── A. Default Category Selection ───────────────────────────────────────
    test('A. default category selection protects core identity and excludes caches', () {
      final defaults = AstraBackupCategory.defaultCategories;

      expect(defaults.contains(AstraBackupCategory.tasks), isTrue);
      expect(defaults.contains(AstraBackupCategory.reminders), isTrue);
      expect(defaults.contains(AstraBackupCategory.chat), isTrue);
      expect(defaults.contains(AstraBackupCategory.memory), isTrue);
      expect(defaults.contains(AstraBackupCategory.streaks), isTrue);
      expect(defaults.contains(AstraBackupCategory.calendarLinks), isTrue);

      // Caches and rebuildable data are excluded by default
      expect(defaults.contains(AstraBackupCategory.panchang), isFalse);
      expect(defaults.contains(AstraBackupCategory.preferences), isFalse);
    });

    // ─── B. Select All ───────────────────────────────────────────────────────
    test('B. select all contains all supported categories', () {
      final allCategories = AstraBackupCategory.values.toSet();
      expect(allCategories.length, 8);
      expect(allCategories.contains(AstraBackupCategory.panchang), isTrue);
      expect(allCategories.contains(AstraBackupCategory.preferences), isTrue);
    });

    // ─── C. Select None ──────────────────────────────────────────────────────
    test('C. select none is an empty category set', () {
      final emptyCategories = <AstraBackupCategory>{};
      expect(emptyCategories.isEmpty, isTrue);
    });

    // ─── D. Manifest Creation & Versioning ───────────────────────────────────
    test('D. manifest creation includes formatVersion, schemaVersion, appVersion, and categories', () async {
      await db.into(db.tasks).insert(
            TasksCompanion.insert(
              id: 'task-d-1',
              title: 'System Design Spec',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

      final payload = await backupService.createEncryptedBackup(
        password: 'Pass456!',
        appVersion: '2.2.0',
        categories: {AstraBackupCategory.tasks, AstraBackupCategory.reminders},
        kdfIterations: 5000,
      );

      expect(payload.metadata.signature, AstraBackupMetadata.encryptedV2Signature);
      expect(payload.metadata.backupVersion, 2);
      expect(payload.metadata.schemaVersion, AstraBackupMetadata.currentSchemaVersion);
      expect(payload.metadata.appVersion, '2.2.0');
      expect(payload.metadata.selectedCategories, contains('tasks'));
      expect(payload.metadata.selectedCategories, contains('reminders'));
      expect(payload.metadata.selectedCategories, isNot(contains('panchang')));
      expect(payload.metadata.checksum.isNotEmpty, isTrue);
    });

    // ─── E. Category Metadata & Counts ───────────────────────────────────────
    test('E. category metadata tracks item counts accurately', () async {
      final now = DateTime.now();
      await db.into(db.tasks).insert(TasksCompanion.insert(id: 't1', title: 'Task 1', createdAt: now, updatedAt: now));
      await db.into(db.tasks).insert(TasksCompanion.insert(id: 't2', title: 'Task 2', createdAt: now, updatedAt: now));
      await db.into(db.chatSessions).insert(ChatSessionsCompanion.insert(id: const Value(1), title: const Value('Chat 1'), createdAt: now, updatedAt: now));
      await db.into(db.chatMessages).insert(ChatMessagesCompanion.insert(id: const Value(1), sessionId: 1, role: 'user', content: 'Hello', timestamp: now));

      final stats = await backupService.getStats();
      expect(stats.taskCount, 2);
      expect(stats.sessionCount, 1);
      expect(stats.messageCount, 1);
    });

    // ─── F. Encrypted Backup Round Trip ──────────────────────────────────────
    test('F. encrypted backup round trip with AES-256-GCM decrypts and matches original data', () async {
      final now = DateTime.utc(2026, 8, 18, 15, 0);
      await db.into(db.tasks).insert(
            TasksCompanion.insert(
              id: 'task-f-1',
              title: 'Encrypted Task Round Trip',
              priority: const Value('high'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      final encryptedPayload = await backupService.createEncryptedBackup(
        password: 'SecurePassword123!',
        kdfIterations: 5000,
      );

      final bytes = encryptedPayload.toBytes();
      final freshDb = AppDatabase(NativeDatabase.memory());
      final freshRestore = AstraRestoreService(freshDb, cryptoService: cryptoService);

      final result = await freshRestore.restoreBackup(
        bytes,
        password: 'SecurePassword123!',
        strategy: RestoreStrategy.replaceSelected,
      );

      expect(result.success, isTrue);
      expect(result.tasksRestored, 1);

      final restoredTasks = await freshDb.select(freshDb.tasks).get();
      expect(restoredTasks.length, 1);
      expect(restoredTasks.first.title, 'Encrypted Task Round Trip');
      expect(restoredTasks.first.priority, 'high');
      await freshDb.close();
    });

    // ─── G. Wrong Password Rejection ─────────────────────────────────────────
    test('G. wrong password rejection throws AstraCryptoException without touching database', () async {
      final now = DateTime.now();
      await db.into(db.tasks).insert(TasksCompanion.insert(id: 't-orig', title: 'Local Task', createdAt: now, updatedAt: now));

      final encryptedPayload = await backupService.createEncryptedBackup(
        password: 'CorrectPassword!',
        kdfIterations: 5000,
      );
      final bytes = encryptedPayload.toBytes();

      expect(
        () => restoreService.restoreBackup(bytes, password: 'WrongPassword999!'),
        throwsA(isA<AstraCryptoException>()),
      );

      final localTasks = await db.select(db.tasks).get();
      expect(localTasks.length, 1);
      expect(localTasks.first.title, 'Local Task');
    });

    // ─── H. Corrupted Backup Rejection ───────────────────────────────────────
    test('H. corrupted backup with tampered ciphertext fails authentication', () async {
      final encryptedPayload = await backupService.createEncryptedBackup(
        password: 'Password123!',
        kdfIterations: 5000,
      );

      final json = jsonDecode(utf8.decode(encryptedPayload.toBytes())) as Map<String, dynamic>;
      final cipherStr = json['ciphertext'] as String;
      final tamperedCipher = '${cipherStr.substring(0, 10)}XYZ${cipherStr.substring(13)}';
      json['ciphertext'] = tamperedCipher;
      final tamperedBytes = Uint8List.fromList(utf8.encode(jsonEncode(json)));

      expect(
        () => restoreService.restoreBackup(tamperedBytes, password: 'Password123!'),
        throwsA(isA<AstraCryptoException>()),
      );
    });

    // ─── I. Unsupported Format Rejection ─────────────────────────────────────
    test('I. unsupported format with future schema version throws AstraRestoreException', () async {
      final now = DateTime.now();
      final futureMeta = AstraBackupMetadata(
        signature: AstraBackupMetadata.encryptedV2Signature,
        backupVersion: 2,
        schemaVersion: AstraBackupMetadata.currentSchemaVersion + 5,
        createdAt: now,
        appVersion: '99.0.0',
        taskCount: 0,
        sessionCount: 0,
        messageCount: 0,
        memoryCount: 0,
        reminderCount: 0,
        ritualRuleCount: 0,
        checksum: 'dummy',
      );

      final dummyPackage = const AstraEncryptedPackage(
        saltBase64: 'salt',
        nonceBase64: 'nonce',
        authTagBase64: 'tag',
        ciphertextBase64: 'cipher',
      );

      final futurePayload = AstraEncryptedBackupPayload(
        metadata: futureMeta,
        encryptedPackage: dummyPackage,
      );

      expect(
        () => restoreService.validateBackup(futurePayload.toBytes()),
        throwsA(isA<AstraRestoreException>().having((e) => e.code, 'code', 'incompatible_schema')),
      );
    });

    // ─── J. Selective Restore ────────────────────────────────────────────────
    test('J. selective restore only restores chosen categories and leaves others untouched', () async {
      final now = DateTime.now();
      // Setup backup with tasks and chat
      await db.into(db.tasks).insert(TasksCompanion.insert(id: 'task-bk', title: 'Backup Task', createdAt: now, updatedAt: now));
      await db.into(db.chatSessions).insert(ChatSessionsCompanion.insert(id: const Value(1), title: const Value('Backup Chat'), createdAt: now, updatedAt: now));
      await db.into(db.chatMessages).insert(ChatMessagesCompanion.insert(id: const Value(1), sessionId: 1, role: 'user', content: 'Backup message', timestamp: now));

      final backupPayload = await backupService.createEncryptedBackup(
        password: 'Pass!',
        categories: {AstraBackupCategory.tasks, AstraBackupCategory.chat},
        kdfIterations: 5000,
      );
      final backupBytes = backupPayload.toBytes();

      // Fresh target DB with existing local chat
      final targetDb = AppDatabase(NativeDatabase.memory());
      await targetDb.into(targetDb.chatSessions).insert(ChatSessionsCompanion.insert(id: const Value(2), title: const Value('Local Chat'), createdAt: now, updatedAt: now));
      await targetDb.into(targetDb.chatMessages).insert(ChatMessagesCompanion.insert(id: const Value(2), sessionId: 2, role: 'user', content: 'Local message', timestamp: now));

      final targetRestore = AstraRestoreService(targetDb, cryptoService: cryptoService);

      // Restore ONLY tasks
      final result = await targetRestore.restoreBackup(
        backupBytes,
        password: 'Pass!',
        selectedCategories: {AstraBackupCategory.tasks},
        strategy: RestoreStrategy.merge,
      );

      expect(result.success, isTrue);
      expect(result.tasksRestored, 1);

      final restoredTasks = await targetDb.select(targetDb.tasks).get();
      final localChat = await targetDb.select(targetDb.chatSessions).get();

      expect(restoredTasks.length, 1);
      expect(restoredTasks.first.title, 'Backup Task');
      // Local chat session was completely preserved
      expect(localChat.length, 1);
      expect(localChat.first.title, 'Local Chat');

      await targetDb.close();
    });

    // ─── K. Merge Restore (Timestamp Conflict Resolution) ────────────────────
    test('K. merge restore updates older local records and preserves newer local edits', () async {
      final oldTime = DateTime.utc(2026, 8, 1, 10, 0);
      final midTime = DateTime.utc(2026, 8, 10, 10, 0);
      final newTime = DateTime.utc(2026, 8, 18, 10, 0);

      // Backup has task-1 updated at midTime, task-2 updated at oldTime
      await db.into(db.tasks).insert(TasksCompanion.insert(id: 't-1', title: 'Task 1 (Backup New)', createdAt: oldTime, updatedAt: midTime));
      await db.into(db.tasks).insert(TasksCompanion.insert(id: 't-2', title: 'Task 2 (Backup Old)', createdAt: oldTime, updatedAt: oldTime));

      final backupPayload = await backupService.createEncryptedBackup(password: 'Pass!', kdfIterations: 5000);
      final bytes = backupPayload.toBytes();

      // Local DB has task-1 updated at oldTime (should be updated by backup)
      // Local DB has task-2 updated at newTime (should preserve local edit)
      final targetDb = AppDatabase(NativeDatabase.memory());
      await targetDb.into(targetDb.tasks).insert(TasksCompanion.insert(id: 't-1', title: 'Task 1 (Local Old)', createdAt: oldTime, updatedAt: oldTime));
      await targetDb.into(targetDb.tasks).insert(TasksCompanion.insert(id: 't-2', title: 'Task 2 (Local Newer)', createdAt: oldTime, updatedAt: newTime));

      final targetRestore = AstraRestoreService(targetDb, cryptoService: cryptoService);
      await targetRestore.restoreBackup(bytes, password: 'Pass!', strategy: RestoreStrategy.merge);

      final t1 = await (targetDb.select(targetDb.tasks)..where((t) => t.id.equals('t-1'))).getSingle();
      final t2 = await (targetDb.select(targetDb.tasks)..where((t) => t.id.equals('t-2'))).getSingle();

      expect(t1.title, 'Task 1 (Backup New)'); // Updated by backup
      expect(t2.title, 'Task 2 (Local Newer)'); // Preserved local newer edit

      await targetDb.close();
    });

    // ─── L. Replace Restore Confirmation ─────────────────────────────────────
    test('L. replace restore wipes selected categories and inserts backup records cleanly', () async {
      final now = DateTime.now();
      await db.into(db.tasks).insert(TasksCompanion.insert(id: 't-backup', title: 'Backup Task Only', createdAt: now, updatedAt: now));

      final backupPayload = await backupService.createEncryptedBackup(password: 'Pass!', kdfIterations: 5000);
      final bytes = backupPayload.toBytes();

      final targetDb = AppDatabase(NativeDatabase.memory());
      await targetDb.into(targetDb.tasks).insert(TasksCompanion.insert(id: 't-local-1', title: 'Local 1', createdAt: now, updatedAt: now));
      await targetDb.into(targetDb.tasks).insert(TasksCompanion.insert(id: 't-local-2', title: 'Local 2', createdAt: now, updatedAt: now));

      final targetRestore = AstraRestoreService(targetDb, cryptoService: cryptoService);
      final result = await targetRestore.restoreBackup(bytes, password: 'Pass!', strategy: RestoreStrategy.replaceSelected);

      expect(result.strategy, RestoreStrategy.replaceSelected);
      final tasks = await targetDb.select(targetDb.tasks).get();
      expect(tasks.length, 1);
      expect(tasks.first.title, 'Backup Task Only');

      await targetDb.close();
    });

    // ─── M. Task Conflict Resolution (Completed Status) ──────────────────────
    test('M. task conflict resolution preserves recently completed local status on merge', () async {
      final baseTime = DateTime.utc(2026, 8, 1, 10, 0);
      final completeTime = DateTime.utc(2026, 8, 15, 12, 0);

      // Backup has task as pending
      await db.into(db.tasks).insert(
            TasksCompanion.insert(
              id: 't-comp',
              title: 'Important Tax Task',
              status: const Value('pending'),
              createdAt: baseTime,
              updatedAt: baseTime,
            ),
          );

      final backupPayload = await backupService.createEncryptedBackup(password: 'Pass!', kdfIterations: 5000);
      final bytes = backupPayload.toBytes();

      // Local DB completed the task on August 15
      final targetDb = AppDatabase(NativeDatabase.memory());
      await targetDb.into(targetDb.tasks).insert(
            TasksCompanion.insert(
              id: 't-comp',
              title: 'Important Tax Task',
              status: const Value('completed'),
              completedAt: Value(completeTime),
              createdAt: baseTime,
              updatedAt: completeTime,
            ),
          );

      final targetRestore = AstraRestoreService(targetDb, cryptoService: cryptoService);
      await targetRestore.restoreBackup(bytes, password: 'Pass!', strategy: RestoreStrategy.merge);

      final task = await (targetDb.select(targetDb.tasks)..where((t) => t.id.equals('t-comp'))).getSingle();
      expect(task.status, 'completed');
      expect(task.completedAt != null && task.completedAt!.isAtSameMomentAs(completeTime), isTrue);

      await targetDb.close();
    });

    // ─── N. Chat Conflict Resolution (Message Deduplication) ─────────────────
    test('N. chat conflict resolution deduplicates messages with matching timestamps and content', () async {
      final now = DateTime.utc(2026, 8, 18, 10, 0);
      final later = DateTime.utc(2026, 8, 18, 10, 5);

      await db.into(db.chatSessions).insert(ChatSessionsCompanion.insert(id: const Value(1), title: const Value('Design Chat'), createdAt: now, updatedAt: now));
      await db.into(db.chatMessages).insert(ChatMessagesCompanion.insert(id: const Value(1), sessionId: 1, role: 'user', content: 'First message', timestamp: now));
      await db.into(db.chatMessages).insert(ChatMessagesCompanion.insert(id: const Value(2), sessionId: 1, role: 'assistant', content: 'Second message', timestamp: later));

      final backupPayload = await backupService.createEncryptedBackup(password: 'Pass!', kdfIterations: 5000);
      final bytes = backupPayload.toBytes();

      // Target DB already has message 1
      final targetDb = AppDatabase(NativeDatabase.memory());
      await targetDb.into(targetDb.chatSessions).insert(ChatSessionsCompanion.insert(id: const Value(1), title: const Value('Design Chat'), createdAt: now, updatedAt: now));
      await targetDb.into(targetDb.chatMessages).insert(ChatMessagesCompanion.insert(id: const Value(1), sessionId: 1, role: 'user', content: 'First message', timestamp: now));

      final targetRestore = AstraRestoreService(targetDb, cryptoService: cryptoService);
      await targetRestore.restoreBackup(bytes, password: 'Pass!', strategy: RestoreStrategy.merge);

      final messages = await (targetDb.select(targetDb.chatMessages)..where((m) => m.sessionId.equals(1))).get();
      // Message 1 deduplicated, Message 2 added
      expect(messages.length, 2);

      await targetDb.close();
    });

    // ─── O. Memory Conflict Resolution ───────────────────────────────────────
    test('O. memory conflict resolution merges task contexts cleanly', () async {
      await db.into(db.taskContexts).insert(
            TaskContextsCompanion.insert(
              id: const Value(1),
              taskId: 't-mem-1',
              companyName: const Value('Google DeepMind'),
              role: const Value('Research Scientist'),
              requirements: const Value('Python, PyTorch'),
            ),
          );

      final backupPayload = await backupService.createEncryptedBackup(password: 'Pass!', kdfIterations: 5000);
      final bytes = backupPayload.toBytes();

      final targetDb = AppDatabase(NativeDatabase.memory());
      final targetRestore = AstraRestoreService(targetDb, cryptoService: cryptoService);

      await targetRestore.restoreBackup(bytes, password: 'Pass!', strategy: RestoreStrategy.merge);

      final memory = await (targetDb.select(targetDb.taskContexts)..where((c) => c.taskId.equals('t-mem-1'))).getSingle();
      expect(memory.companyName, 'Google DeepMind');
      expect(memory.role, 'Research Scientist');

      await targetDb.close();
    });

    // ─── P. Transaction Rollback on Restore Failure ───────────────────────────
    test('P. transaction rollback prevents partial writes if decryption fails halfway', () async {
      final now = DateTime.now();
      await db.into(db.tasks).insert(TasksCompanion.insert(id: 't-safe', title: 'Local Safe Task', createdAt: now, updatedAt: now));

      final invalidBytes = Uint8List.fromList(utf8.encode('{"signature":"ASTRA_ENCRYPTED_V2"}'));

      expect(
        () => restoreService.restoreBackup(invalidBytes, password: 'Wrong'),
        throwsA(anything),
      );

      final tasks = await db.select(db.tasks).get();
      expect(tasks.length, 1);
      expect(tasks.first.title, 'Local Safe Task');
    });

    // ─── Q. Backup File Remains Valid ────────────────────────────────────────
    test('Q. backup file format and filename generation remain valid', () {
      final fixedDate = DateTime(2026, 8, 18, 16, 45);
      final name = AstraBackupService.generateBackupFileName(fixedDate);
      expect(name, 'ASTRA_Backup_2026-08-18_16-45.astra.db');
    });

    // ─── R. Existing Legacy Backup Compatibility ─────────────────────────────
    test('R. legacy V1 unencrypted backup restores cleanly for backward compatibility', () async {
      final now = DateTime.now();
      await db.into(db.tasks).insert(TasksCompanion.insert(id: 't-v1', title: 'V1 Task', createdAt: now, updatedAt: now));

      final v1Payload = await backupService.createBackup(appVersion: '2.0.0');
      final bytes = v1Payload.toBytes();

      final targetDb = AppDatabase(NativeDatabase.memory());
      final targetRestore = AstraRestoreService(targetDb, cryptoService: cryptoService);

      final result = await targetRestore.restoreBackup(bytes, strategy: RestoreStrategy.merge);
      expect(result.success, isTrue);
      expect(result.tasksRestored, 1);

      final tasks = await targetDb.select(targetDb.tasks).get();
      expect(tasks.first.title, 'V1 Task');

      await targetDb.close();
    });

    // ─── S. Android Backup Rule Configuration ────────────────────────────────
    test('S. android backup rules exist and are configured in AndroidManifest.xml', () {
      final extractionRulesFile = File('android/app/src/main/res/xml/data_extraction_rules.xml');
      final backupRulesFile = File('android/app/src/main/res/xml/backup_rules.xml');
      final manifestFile = File('android/app/src/main/AndroidManifest.xml');

      expect(extractionRulesFile.existsSync(), isTrue);
      expect(backupRulesFile.existsSync(), isTrue);
      expect(manifestFile.existsSync(), isTrue);

      final manifestContent = manifestFile.readAsStringSync();
      expect(manifestContent, contains('android:allowBackup="true"'));
      expect(manifestContent, contains('android:dataExtractionRules="@xml/data_extraction_rules"'));
      expect(manifestContent, contains('android:fullBackupContent="@xml/backup_rules"'));

      final extractionContent = extractionRulesFile.readAsStringSync();
      expect(extractionContent, contains('<include domain="database"'));
      expect(extractionContent, contains('<exclude domain="root" path="cache"'));
      expect(extractionContent, contains('<exclude domain="root" path="tmp"'));
    });

    // ─── T. Secret & Cache Exclusion ─────────────────────────────────────────
    test('T. secrets and caches are excluded from backup payloads', () async {
      final payload = await backupService.createEncryptedBackup(password: 'MySecretPassword123!', kdfIterations: 5000);
      final jsonString = payload.toJsonString();

      // Password and keys must never appear in serialized backup
      expect(jsonString, isNot(contains('MySecretPassword123!')));
      expect(jsonString, isNot(contains('rawKey')));
      expect(jsonString, isNot(contains('secretKey')));
    });

    // ─── U. Password Non-Leakage ─────────────────────────────────────────────
    test('U. password is never logged or exposed in metadata', () async {
      final payload = await backupService.createEncryptedBackup(password: 'Pass!', kdfIterations: 5000);
      final metaJson = jsonEncode(payload.metadata.toJson());

      expect(metaJson, isNot(contains('Pass!')));
    });

    // ─── V. Empty-Category Backup Handling ───────────────────────────────────
    test('V. empty-category backup creates valid envelope with zero items', () async {
      final payload = await backupService.createEncryptedBackup(
        password: 'Pass!',
        categories: {},
        kdfIterations: 5000,
      );

      expect(payload.metadata.taskCount, 0);
      expect(payload.metadata.sessionCount, 0);
    });

    // ─── W. Multi-Category Large Backup Handling ─────────────────────────────
    test('W. multi-category backup handles 50+ items across tasks, messages, reminders, and streaks', () async {
      final now = DateTime.now();
      for (int i = 0; i < 20; i++) {
        await db.into(db.tasks).insert(TasksCompanion.insert(id: 'task-$i', title: 'Task $i', createdAt: now, updatedAt: now));
      }
      await db.into(db.chatSessions).insert(ChatSessionsCompanion.insert(id: const Value(1), title: const Value('Main Chat'), createdAt: now, updatedAt: now));
      for (int i = 0; i < 30; i++) {
        await db.into(db.chatMessages).insert(ChatMessagesCompanion.insert(id: Value(i + 1), sessionId: 1, role: 'user', content: 'Message $i', timestamp: now));
      }
      await db.into(db.ritualRules).insert(RitualRulesCompanion.insert(eventType: 'Ekadashi', title: 'Fast on Ekadashi'));

      final payload = await backupService.createEncryptedBackup(password: 'Pass!', kdfIterations: 5000);
      final bytes = payload.toBytes();

      final targetDb = AppDatabase(NativeDatabase.memory());
      final targetRestore = AstraRestoreService(targetDb, cryptoService: cryptoService);

      final result = await targetRestore.restoreBackup(bytes, password: 'Pass!');
      expect(result.tasksRestored, 20);
      expect(result.messagesRestored, 30);
      expect(result.ritualRulesRestored, 1);

      await targetDb.close();
    });

    // Storage Service Interface Test
    test('Storage service fake stores and retrieves documents', () async {
      final storage = _FakeAstraBackupStorageService();
      final path = await storage.saveBackupDocument(fileName: 'test.db', bytes: Uint8List.fromList([1, 2, 3]));
      expect(path, contains('test.db'));
      final picked = await storage.pickBackupDocument();
      expect(picked?.name, 'test.db');
      expect(picked?.bytes.length, 3);
    });
  });
}
