import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';

import '../../core/database/database.dart';
import 'astra_backup_service.dart';
import 'astra_crypto_service.dart';

/// Exceptions thrown during backup restoration or validation.
class AstraRestoreException implements Exception {
  final String message;
  final String? code;

  const AstraRestoreException(this.message, [this.code]);

  @override
  String toString() => 'AstraRestoreException: $message (code: $code)';
}

/// Result of a successful restore operation.
class AstraRestoreResult {
  final bool success;
  final AstraBackupMetadata metadata;
  final int tasksRestored;
  final int messagesRestored;
  final int sessionsRestored;
  final int memoriesRestored;
  final int remindersRestored;

  const AstraRestoreResult({
    required this.success,
    required this.metadata,
    required this.tasksRestored,
    required this.messagesRestored,
    required this.sessionsRestored,
    required this.memoriesRestored,
    required this.remindersRestored,
  });
}

/// Service that safely validates, decrypts, and restores ASTRA backup archives into SQLite.
class AstraRestoreService {
  final AppDatabase _db;
  final AstraCryptoService _cryptoService;

  AstraRestoreService(this._db, {AstraCryptoService? cryptoService})
      : _cryptoService = cryptoService ?? AstraCryptoService();

  /// Validates a backup archive's signature, structure, and schema compatibility.
  /// Returns the parsed [AstraBackupMetadata] on success, or throws [AstraRestoreException].
  AstraBackupMetadata validateBackup(Uint8List bytes) {
    if (bytes.isEmpty) {
      throw const AstraRestoreException('The selected backup file is empty.', 'empty_file');
    }

    final String jsonStr;
    try {
      jsonStr = utf8.decode(bytes);
    } catch (_) {
      throw const AstraRestoreException('The backup file is not valid UTF-8 text.', 'encoding_error');
    }

    final Map<String, dynamic> json;
    try {
      json = jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (_) {
      throw const AstraRestoreException('The backup file contains corrupted JSON.', 'corrupt_json');
    }

    final metadataJson = (json['metadata'] as Map<String, dynamic>?) ?? json;
    final signature = (json['signature'] as String?) ?? (metadataJson['signature'] as String? ?? '');

    if (signature != AstraBackupMetadata.encryptedV2Signature &&
        signature != AstraBackupMetadata.legacyV1Signature) {
      throw AstraRestoreException(
        'Invalid backup signature "$signature". This file is not a valid ASTRA backup archive.',
        'invalid_signature',
      );
    }

    final metadata = AstraBackupMetadata.fromJson(metadataJson);

    // 1. Signature Check
    if (!metadata.isValidSignature) {
      throw AstraRestoreException(
        'Invalid backup signature "${metadata.signature}". This file is not an ASTRA backup archive.',
        'invalid_signature',
      );
    }

    // 2. Legacy V1 Checksum Verification (if unencrypted)
    if (metadata.isLegacyV1) {
      final dataJson = json['data'] as Map<String, dynamic>?;
      if (dataJson == null) {
        throw const AstraRestoreException('Missing data section in legacy backup.', 'invalid_structure');
      }
      final dataString = jsonEncode(dataJson);
      final calculatedChecksum = sha256.convert(utf8.encode(dataString)).toString();
      if (calculatedChecksum != metadata.checksum) {
        throw const AstraRestoreException(
          'Backup integrity check failed: checksum mismatch. The file may be corrupted.',
          'checksum_mismatch',
        );
      }
    }

    // 3. Schema Compatibility Check
    if (metadata.schemaVersion > AstraBackupMetadata.currentSchemaVersion) {
      throw AstraRestoreException(
        'Backup schema v${metadata.schemaVersion} is newer than current app schema v${AstraBackupMetadata.currentSchemaVersion}. Please update ASTRA.',
        'incompatible_schema',
      );
    }

    return metadata;
  }

  /// Restores data from an encrypted (V2) or legacy (V1) backup archive into the active [AppDatabase].
  ///
  /// Invariants:
  /// - Full decryption, envelope inspection, and schema parsing execute before any database write.
  /// - If password is wrong or archive is corrupt, live database remains 100% untouched.
  /// - Restoration executes in a single atomic transaction.
  Future<AstraRestoreResult> restoreBackup(
    Uint8List bytes, {
    String? password,
    bool clearExisting = true,
  }) async {
    // 1. Validate envelope signature and schema version
    final metadata = validateBackup(bytes);

    final jsonStr = utf8.decode(bytes);
    final json = jsonDecode(jsonStr) as Map<String, dynamic>;

    final Map<String, dynamic> data;

    if (metadata.isEncryptedV2) {
      if (password == null || password.isEmpty) {
        throw const AstraRestoreException('This backup is encrypted. Please enter the backup password.', 'password_required');
      }

      final encryptedPackage = AstraEncryptedPackage.fromJson(json);

      // Decrypt and verify AES-256-GCM authentication tag
      final decryptedJsonString = await _cryptoService.decryptData(
        package: encryptedPackage,
        password: password,
      );

      try {
        data = jsonDecode(decryptedJsonString) as Map<String, dynamic>;
      } catch (_) {
        throw const AstraRestoreException('Decrypted payload contains invalid data structure.', 'corrupt_decrypted_data');
      }
    } else {
      // Legacy V1 unencrypted archive
      data = json['data'] as Map<String, dynamic>? ?? {};
    }

    final rawTasks = data['tasks'] as List<dynamic>? ?? [];
    final rawSessions = data['chatSessions'] as List<dynamic>? ?? [];
    final rawMessages = data['chatMessages'] as List<dynamic>? ?? [];
    final rawMemories = data['taskContexts'] as List<dynamic>? ?? [];
    final rawReminders = data['reminders'] as List<dynamic>? ?? [];
    final rawRitualRules = data['ritualRules'] as List<dynamic>? ?? [];
    final rawInboxItems = data['inboxItems'] as List<dynamic>? ?? [];

    // 2. Perform restoration in an atomic batch transaction
    await _db.transaction(() async {
      if (clearExisting) {
        // Clear child tables first to respect foreign keys
        await _db.delete(_db.chatMessages).go();
        await _db.delete(_db.chatSessions).go();
        await _db.delete(_db.reminders).go();
        await _db.delete(_db.taskContexts).go();
        await _db.delete(_db.tasks).go();
        await _db.delete(_db.inboxItems).go();
        await _db.delete(_db.ritualRules).go();
      }

      // Restore Inbox Items
      for (final raw in rawInboxItems) {
        final item = raw as Map<String, dynamic>;
        await _db.into(_db.inboxItems).insertOnConflictUpdate(
              InboxItemsCompanion(
                id: Value(item['id'] as String),
                rawText: Value(item['rawText'] as String),
                sourceType: Value(item['sourceType'] as String),
                processingStatus: Value(item['processingStatus'] as String),
                receivedAt: Value(DateTime.parse(item['receivedAt'] as String)),
                createdAt: Value(DateTime.parse(item['createdAt'] as String)),
                updatedAt: Value(DateTime.parse(item['updatedAt'] as String)),
              ),
            );
      }

      // Restore Tasks
      for (final raw in rawTasks) {
        final item = raw as Map<String, dynamic>;
        await _db.into(_db.tasks).insertOnConflictUpdate(
              TasksCompanion(
                id: Value(item['id'] as String),
                inboxItemId: Value(item['inboxItemId'] as String?),
                title: Value(item['title'] as String),
                description: Value(item['description'] as String?),
                taskType: Value(item['taskType'] as String? ?? 'todo'),
                priority: Value(item['priority'] as String? ?? 'medium'),
                status: Value(item['status'] as String? ?? 'active'),
                order: Value(item['order'] as int? ?? 0),
                subtasksJson: Value(item['subtasksJson'] as String? ?? '[]'),
                dueAt: Value(item['dueAt'] != null ? DateTime.parse(item['dueAt'] as String) : null),
                startAt: Value(item['startAt'] != null ? DateTime.parse(item['startAt'] as String) : null),
                endAt: Value(item['endAt'] != null ? DateTime.parse(item['endAt'] as String) : null),
                completedAt: Value(item['completedAt'] != null ? DateTime.parse(item['completedAt'] as String) : null),
                createdAt: Value(DateTime.parse(item['createdAt'] as String)),
                updatedAt: Value(DateTime.parse(item['updatedAt'] as String)),
                source: Value(item['source'] as String?),
                sourceId: Value(item['sourceId'] as String?),
                category: Value(item['category'] as String?),
                organization: Value(item['organization'] as String?),
                recurrenceRuleJson: Value(item['recurrenceRuleJson'] as String?),
              ),
            );
      }

      // Restore Chat Sessions
      for (final raw in rawSessions) {
        final item = raw as Map<String, dynamic>;
        await _db.into(_db.chatSessions).insertOnConflictUpdate(
              ChatSessionsCompanion(
                id: Value(item['id'] as int),
                title: Value(item['title'] as String? ?? 'New Chat'),
                createdAt: Value(DateTime.parse(item['createdAt'] as String)),
                updatedAt: Value(DateTime.parse(item['updatedAt'] as String)),
              ),
            );
      }

      // Restore Chat Messages
      for (final raw in rawMessages) {
        final item = raw as Map<String, dynamic>;
        await _db.into(_db.chatMessages).insertOnConflictUpdate(
              ChatMessagesCompanion(
                id: Value(item['id'] as int),
                sessionId: Value(item['sessionId'] as int),
                role: Value(item['role'] as String),
                content: Value(item['content'] as String),
                messageType: Value(item['messageType'] as String? ?? 'normal'),
                timestamp: Value(DateTime.parse(item['timestamp'] as String)),
              ),
            );
      }

      // Restore Task Contexts (Memories)
      for (final raw in rawMemories) {
        final item = raw as Map<String, dynamic>;
        await _db.into(_db.taskContexts).insertOnConflictUpdate(
              TaskContextsCompanion(
                id: Value(item['id'] as int),
                taskId: Value(item['taskId'] as String? ?? ''),
                companyName: Value(item['companyName'] as String?),
                role: Value(item['role'] as String?),
                requirements: Value(item['requirements'] as String?),
                applicationLink: Value(item['applicationLink'] as String?),
                emailSnippet: Value(item['emailSnippet'] as String?),
                fullEmail: Value(item['fullEmail'] as String?),
                hasApplied: Value(item['hasApplied'] as bool? ?? false),
                appliedAt: Value(item['appliedAt'] != null ? DateTime.parse(item['appliedAt'] as String) : null),
                eventType: Value(item['eventType'] as String?),
                location: Value(item['location'] as String?),
                stipend: Value(item['stipend'] as String?),
                actionItems: Value(item['actionItems'] as String?),
                source: Value(item['source'] as String? ?? 'chat'),
              ),
            );
      }

      // Restore Reminders
      for (final raw in rawReminders) {
        final item = raw as Map<String, dynamic>;
        await _db.into(_db.reminders).insertOnConflictUpdate(
              RemindersCompanion(
                id: Value(item['id'] as String),
                taskId: Value(item['taskId'] as String),
                scheduledAt: Value(DateTime.parse(item['scheduledAt'] as String)),
                timezone: Value(item['timezone'] as String? ?? 'Asia/Kolkata'),
                notificationId: Value(item['notificationId'] as int),
                status: Value(item['status'] as String? ?? 'scheduled'),
                createdAt: Value(DateTime.parse(item['createdAt'] as String)),
                updatedAt: Value(DateTime.parse(item['updatedAt'] as String)),
              ),
            );
      }

      // Restore Ritual Rules
      for (final raw in rawRitualRules) {
        final item = raw as Map<String, dynamic>;
        await _db.into(_db.ritualRules).insertOnConflictUpdate(
              RitualRulesCompanion(
                id: Value(item['id'] is int ? item['id'] as int : int.tryParse(item['id'].toString()) ?? 1),
                eventType: Value(item['eventType'] as String),
                title: Value(item['title'] as String),
                instructions: Value(item['instructions'] as String),
                remindDaysBefore: Value(item['remindDaysBefore'] as int),
                remindAtTime: Value(item['remindAtTime'] as String),
                isActive: Value(item['isActive'] as bool? ?? true),
              ),
            );
      }
    });

    return AstraRestoreResult(
      success: true,
      metadata: metadata,
      tasksRestored: rawTasks.length,
      messagesRestored: rawMessages.length,
      sessionsRestored: rawSessions.length,
      memoriesRestored: rawMemories.length,
      remindersRestored: rawReminders.length,
    );
  }
}
