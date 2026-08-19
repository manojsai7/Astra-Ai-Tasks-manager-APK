import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:astra/core/database/database.dart';
import 'package:astra/services/data/astra_backup_service.dart';
import 'package:astra/services/data/astra_backup_storage_service.dart';
import 'package:astra/services/data/astra_crypto_service.dart';
import 'package:astra/services/data/astra_restore_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ASTRA M3 & B3 — Local Database Backup, Portable SAF Storage & AES-256-GCM Encryption Tests', () {
    late AppDatabase db;
    late AstraCryptoService cryptoService;
    late AstraBackupService backupService;
    late AstraRestoreService restoreService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      db = AppDatabase(NativeDatabase.memory());
      cryptoService = AstraCryptoService();
      backupService = AstraBackupService(db, cryptoService: cryptoService);
      restoreService = AstraRestoreService(db, cryptoService: cryptoService);

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

    // =========================================================================
    // SECTION 1: LEGACY V1 ARCHIVE SUPPORT
    // =========================================================================

    test('1. Legacy V1 Backup Metadata: contains format version, schema version, signature and appVersion', () async {
      final payload = await backupService.createBackup(appVersion: '2.1.3');

      expect(payload.metadata.signature, 'ASTRA_BACKUP_V1');
      expect(payload.metadata.backupVersion, 1);
      expect(payload.metadata.schemaVersion, AstraBackupMetadata.currentSchemaVersion);
      expect(payload.metadata.appVersion, '2.1.3');
      expect(payload.metadata.taskCount, 1);
      expect(payload.metadata.sessionCount, 1);
      expect(payload.metadata.messageCount, 1);
      expect(payload.metadata.memoryCount, 1);
      expect(payload.metadata.reminderCount, 1);
      expect(payload.metadata.checksum.isNotEmpty, isTrue);
    });

    test('2. Legacy V1 Integrity: SHA-256 checksum is valid over payload data', () async {
      final payload = await backupService.createBackup();
      final bytes = payload.toBytes();

      final validatedMetadata = restoreService.validateBackup(bytes);
      expect(validatedMetadata.checksum, payload.metadata.checksum);
    });

    test('3. Legacy V1 Restore: restores tasks, sessions, messages, and memories seamlessly', () async {
      final payload = await backupService.createBackup();
      final bytes = payload.toBytes();

      final freshDb = AppDatabase(NativeDatabase.memory());
      final freshRestore = AstraRestoreService(freshDb, cryptoService: cryptoService);

      final result = await freshRestore.restoreBackup(bytes);
      expect(result.success, isTrue);
      expect(result.tasksRestored, 1);
      expect(result.messagesRestored, 1);
      expect(result.memoriesRestored, 1);

      final tasks = await freshDb.select(freshDb.tasks).get();
      expect(tasks.length, 1);
      expect(tasks.first.title, 'Physics Midterm Exam');
      expect(tasks.first.startAt, DateTime(2026, 8, 20, 10, 0));
      expect(tasks.first.endAt, DateTime(2026, 8, 20, 12, 0));

      await freshDb.close();
    });

    // =========================================================================
    // SECTION 2: B3 V2 ENCRYPTED BACKUPS (AES-256-GCM + PBKDF2)
    // =========================================================================

    test('4. V2 Encrypted Export: signature is ASTRA_ENCRYPTED_V2 with valid cipher parameters', () async {
      final encryptedPayload = await backupService.createEncryptedBackup(
        password: 'SuperSecretPassword123',
        kdfIterations: 2000,
      );

      expect(encryptedPayload.metadata.signature, 'ASTRA_ENCRYPTED_V2');
      expect(encryptedPayload.metadata.backupVersion, 2);
      expect(encryptedPayload.metadata.schemaVersion, AstraBackupMetadata.currentSchemaVersion);
      expect(encryptedPayload.encryptedPackage.cipher, 'AES-256-GCM');
      expect(encryptedPayload.encryptedPackage.kdf, 'PBKDF2_HMAC_SHA256');
      expect(encryptedPayload.encryptedPackage.saltBase64.isNotEmpty, isTrue);
      expect(encryptedPayload.encryptedPackage.nonceBase64.isNotEmpty, isTrue);
      expect(encryptedPayload.encryptedPackage.authTagBase64.isNotEmpty, isTrue);
      expect(encryptedPayload.encryptedPackage.ciphertextBase64.isNotEmpty, isTrue);
    });

    test('5. Nonce & Salt Freshness: successive backups generate unique salts and nonces', () async {
      final backup1 = await backupService.createEncryptedBackup(
        password: 'Password123',
        kdfIterations: 2000,
      );
      final backup2 = await backupService.createEncryptedBackup(
        password: 'Password123',
        kdfIterations: 2000,
      );

      expect(backup1.encryptedPackage.saltBase64, isNot(backup2.encryptedPackage.saltBase64));
      expect(backup1.encryptedPackage.nonceBase64, isNot(backup2.encryptedPackage.nonceBase64));
      expect(backup1.encryptedPackage.ciphertextBase64, isNot(backup2.encryptedPackage.ciphertextBase64));
    });

    test('6. Password & Key Non-Leakage: password and raw encryption key are NEVER serialized into backup', () async {
      const secretPassword = 'MySecretRecoveryPassword!';
      final encryptedPayload = await backupService.createEncryptedBackup(
        password: secretPassword,
        kdfIterations: 2000,
      );
      final jsonString = encryptedPayload.toJsonString();

      expect(jsonString, isNot(contains(secretPassword)));
      expect(jsonString, isNot(contains('secretKey')));
      expect(jsonString, isNot(contains('rawKey')));
      expect(jsonString, isNot(contains('privateKey')));
    });

    test('7. V2 Decryption with Correct Password: restores database completely', () async {
      final encryptedPayload = await backupService.createEncryptedBackup(
        password: 'CorrectPassword123!',
        kdfIterations: 2000,
      );
      final bytes = encryptedPayload.toBytes();

      final freshDb = AppDatabase(NativeDatabase.memory());
      final freshRestore = AstraRestoreService(freshDb, cryptoService: cryptoService);

      final result = await freshRestore.restoreBackup(
        bytes,
        password: 'CorrectPassword123!',
      );

      expect(result.success, isTrue);
      expect(result.tasksRestored, 1);
      expect(result.messagesRestored, 1);
      expect(result.memoriesRestored, 1);

      final tasks = await freshDb.select(freshDb.tasks).get();
      expect(tasks.length, 1);
      expect(tasks.first.title, 'Physics Midterm Exam');
      expect(tasks.first.startAt, DateTime(2026, 8, 20, 10, 0));

      await freshDb.close();
    });

    test('8. V2 Wrong Password Rejection: throws AstraCryptoException and leaves live DB untouched', () async {
      final encryptedPayload = await backupService.createEncryptedBackup(
        password: 'CorrectPassword123!',
        kdfIterations: 2000,
      );
      final bytes = encryptedPayload.toBytes();

      // Current DB has 1 task
      final initialTasks = await db.select(db.tasks).get();
      expect(initialTasks.length, 1);

      expect(
        () => restoreService.restoreBackup(bytes, password: 'WrongPassword999!'),
        throwsA(isA<AstraCryptoException>()),
      );

      // Verify live database remains completely untouched
      final afterTasks = await db.select(db.tasks).get();
      expect(afterTasks.length, 1);
      expect(afterTasks.first.title, 'Physics Midterm Exam');
    });

    test('9. Tampered Ciphertext Detection: modified ciphertext fails AES-GCM MAC validation', () async {
      final encryptedPayload = await backupService.createEncryptedBackup(
        password: 'Password123!',
        kdfIterations: 2000,
      );

      final jsonMap = encryptedPayload.toJson();
      final originalCiphertext = jsonMap['ciphertext'] as String;
      // Tamper with ciphertext by corrupting one character
      final tamperedCiphertext = originalCiphertext.replaceRange(0, 4, 'AAAA');
      jsonMap['ciphertext'] = tamperedCiphertext;

      final tamperedBytes = Uint8List.fromList(utf8.encode(jsonEncode(jsonMap)));

      expect(
        () => restoreService.restoreBackup(tamperedBytes, password: 'Password123!'),
        throwsA(isA<AstraCryptoException>()),
      );
    });

    test('10. Tampered AuthTag Detection: modified MAC tag fails authentication', () async {
      final encryptedPayload = await backupService.createEncryptedBackup(
        password: 'Password123!',
        kdfIterations: 2000,
      );

      final jsonMap = encryptedPayload.toJson();
      final originalTag = jsonMap['authTag'] as String;
      jsonMap['authTag'] = originalTag.replaceRange(0, 4, 'ZZZZ');

      final tamperedBytes = Uint8List.fromList(utf8.encode(jsonEncode(jsonMap)));

      expect(
        () => restoreService.restoreBackup(tamperedBytes, password: 'Password123!'),
        throwsA(isA<AstraCryptoException>()),
      );
    });

    test('11. Corrupted / Non-JSON Envelope: throws AstraRestoreException', () async {
      final corruptBytes = Uint8List.fromList(utf8.encode('NOT_A_VALID_JSON_STRING'));

      expect(
        () => restoreService.validateBackup(corruptBytes),
        throwsA(isA<AstraRestoreException>()),
      );
    });

    test('12. Unsupported Newer Schema Rejection: throws incompatible_schema exception', () async {
      final encryptedPayload = await backupService.createEncryptedBackup(
        password: 'Password123!',
        kdfIterations: 2000,
      );

      final jsonMap = encryptedPayload.toJson();
      final metadataMap = jsonMap['metadata'] as Map<String, dynamic>;
      metadataMap['schemaVersion'] = 999; // Future schema version
      jsonMap['metadata'] = metadataMap;

      final futureSchemaBytes = Uint8List.fromList(utf8.encode(jsonEncode(jsonMap)));

      expect(
        () => restoreService.validateBackup(futureSchemaBytes),
        throwsA(isA<AstraRestoreException>()),
      );
    });

    test('13. Cross-Device / Uninstall Simulation: Device A exports -> wipe -> Device B imports with password', () async {
      // 1. Device A creates encrypted backup with user password
      final deviceAPayload = await backupService.createEncryptedBackup(
        password: 'UserPersonalPassphrase2026',
        kdfIterations: 2000,
      );
      final exportBytes = deviceAPayload.toBytes();

      // 2. Simulate device wipe / new installation on Device B (fresh DB, fresh providers, no local cached keys)
      final deviceBDb = AppDatabase(NativeDatabase.memory());
      final deviceBCrypto = AstraCryptoService();
      final deviceBRestore = AstraRestoreService(deviceBDb, cryptoService: deviceBCrypto);

      // Verify Device B is initially completely empty
      final initialTasks = await deviceBDb.select(deviceBDb.tasks).get();
      expect(initialTasks.isEmpty, isTrue);

      // 3. User selects file on Device B and enters their passphrase
      final validatedMetadata = deviceBRestore.validateBackup(exportBytes);
      expect(validatedMetadata.taskCount, 1);

      final restoreResult = await deviceBRestore.restoreBackup(
        exportBytes,
        password: 'UserPersonalPassphrase2026',
      );

      expect(restoreResult.success, isTrue);

      // 4. Verify all records restored accurately on Device B
      final deviceBTasks = await deviceBDb.select(deviceBDb.tasks).get();
      expect(deviceBTasks.length, 1);
      expect(deviceBTasks.first.title, 'Physics Midterm Exam');
      expect(deviceBTasks.first.startAt, DateTime(2026, 8, 20, 10, 0));

      final deviceBMessages = await deviceBDb.select(deviceBDb.chatMessages).get();
      expect(deviceBMessages.length, 1);
      expect(deviceBMessages.first.content, 'What exams do I have next week?');

      await deviceBDb.close();
    });

    test('14. Portable Storage Abstraction: IAstraBackupStorageService saves and retrieves outside app-private sandbox', () async {
      final payload = await backupService.createEncryptedBackup(
        password: 'TestPassword',
        kdfIterations: 2000,
      );
      final bytes = payload.toBytes();
      final fileName = AstraBackupService.generateBackupFileName();

      final mockStorage = _FakeAstraBackupStorageService();

      final savedPath = await mockStorage.saveBackupDocument(fileName: fileName, bytes: bytes);
      expect(savedPath, contains('content://downloads/'));
      expect(mockStorage.storedBytes, isNotNull);
      expect(mockStorage.storedBytes!.length, bytes.length);

      final pickedDoc = await mockStorage.pickBackupDocument();
      expect(pickedDoc, isNotNull);
      expect(pickedDoc!.name, fileName);

      final metadata = restoreService.validateBackup(pickedDoc.bytes);
      expect(metadata.isValidSignature, isTrue);
      expect(metadata.isEncryptedV2, isTrue);
    });

    test('15. Filename Generation: produces standard ASTRA_Backup_YYYY-MM-DD_HH-mm.astra.db format', () {
      final fixedDate = DateTime(2026, 8, 17, 14, 30);
      final filename = AstraBackupService.generateBackupFileName(fixedDate);
      expect(filename, 'ASTRA_Backup_2026-08-17_14-30.astra.db');
    });
  });
}

class _FakeAstraBackupStorageService implements IAstraBackupStorageService {
  String? storedFileName;
  Uint8List? storedBytes;

  @override
  Future<String?> saveBackupDocument({
    required String fileName,
    required Uint8List bytes,
  }) async {
    storedFileName = fileName;
    storedBytes = bytes;
    return 'content://downloads/$fileName';
  }

  @override
  Future<AstraPickedDocument?> pickBackupDocument() async {
    if (storedBytes == null || storedFileName == null) return null;
    return AstraPickedDocument(
      name: storedFileName!,
      bytes: storedBytes!,
      path: 'content://downloads/$storedFileName',
    );
  }
}
