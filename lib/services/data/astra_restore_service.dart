import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';

import '../../core/database/database.dart';
import 'astra_backup_service.dart';

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

/// Service that safely validates and restores ASTRA backup archives into SQLite.
class AstraRestoreService {
  final AppDatabase _db;

  const AstraRestoreService(this._db);

  /// Validates a backup archive's signature, structure, checksum, and schema compatibility.
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

    final metadataJson = json['metadata'] as Map<String, dynamic>?;
    final dataJson = json['data'] as Map<String, dynamic>?;

    if (metadataJson == null || dataJson == null) {
      throw const AstraRestoreException('Missing metadata or data section in backup.', 'invalid_structure');
    }

    final metadata = AstraBackupMetadata.fromJson(metadataJson);

    // 1. Signature Check
    if (!metadata.isValidSignature) {
      throw AstraRestoreException(
        'Invalid backup signature "${metadata.signature}". This file is not an ASTRA backup archive.',
        'invalid_signature',
      );
    }

    // 2. Checksum Verification
    final dataString = jsonEncode(dataJson);
    final calculatedChecksum = sha256.convert(utf8.encode(dataString)).toString();
    if (calculatedChecksum != metadata.checksum) {
      throw const AstraRestoreException(
        'Backup integrity check failed: checksum mismatch. The file may be corrupted.',
        'checksum_mismatch',
      );
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

  /// Restores data from the backup archive into the active [AppDatabase].
  ///
  /// Invariants:
  /// - Staging & validation execute before database mutation.
  /// - If validation or parsing fails, the live database remains 100% untouched.
  Future<AstraRestoreResult> restoreBackup(
    Uint8List bytes, {
    bool clearExisting = true,
  }) async {
    // 1. Validate header, signature, and checksum
    final metadata = validateBackup(bytes);

    final jsonStr = utf8.decode(bytes);
    final json = jsonDecode(jsonStr) as Map<String, dynamic>;
    final data = json['data'] as Map<String, dynamic>;

    final rawTasks = data['tasks'] as List<dynamic>? ?? [];
    final rawSessions = data['chatSessions'] as List<dynamic>? ?? [];
    final rawMessages = data['chatMessages'] as List<dynamic>? ?? [];
    final rawMemories = data['taskContexts'] as List<dynamic>? ?? [];
    final rawReminders = data['reminders'] as List<dynamic>? ?? [];
    final rawRitualRules = data['ritualRules'] as List<dynamic>? ?? [];
    final rawInboxItems = data['inboxItems'] as List<dynamic>? ?? [];

    // 2. Perform restoration in a batch transaction
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

      // Restore Tasks (with schema compatibility for v6-v9)
      for (final raw in rawTasks) {
        final t = raw as Map<String, dynamic>;
        await _db.into(_db.tasks).insertOnConflictUpdate(
              TasksCompanion(
                id: Value(t['id'] as String),
                inboxItemId: Value(t['inboxItemId'] as String?),
                title: Value(t['title'] as String),
                description: Value(t['description'] as String?),
                taskType: Value(t['taskType'] as String? ?? 'reminder'),
                priority: Value(t['priority'] as String? ?? 'medium'),
                status: Value(t['status'] as String? ?? 'pending'),
                order: Value(t['order'] as int? ?? 0),
                subtasksJson: Value(t['subtasksJson'] as String? ?? '[]'),
                dueAt: Value(t['dueAt'] != null ? DateTime.parse(t['dueAt'] as String) : null),
                startAt: Value(t['startAt'] != null ? DateTime.parse(t['startAt'] as String) : null),
                endAt: Value(t['endAt'] != null ? DateTime.parse(t['endAt'] as String) : null),
                completedAt: Value(t['completedAt'] != null ? DateTime.parse(t['completedAt'] as String) : null),
                createdAt: Value(DateTime.parse(t['createdAt'] as String)),
                updatedAt: Value(DateTime.parse(t['updatedAt'] as String)),
                source: Value(t['source'] as String?),
                sourceId: Value(t['sourceId'] as String?),
                category: Value(t['category'] as String?),
                organization: Value(t['organization'] as String?),
                recurrenceRuleJson: Value(t['recurrenceRuleJson'] as String?),
              ),
            );
      }

      // Restore Chat Sessions
      for (final raw in rawSessions) {
        final s = raw as Map<String, dynamic>;
        await _db.into(_db.chatSessions).insertOnConflictUpdate(
              ChatSessionsCompanion(
                id: Value(s['id'] as int),
                title: Value(s['title'] as String),
                createdAt: Value(DateTime.parse(s['createdAt'] as String)),
                updatedAt: Value(DateTime.parse(s['updatedAt'] as String)),
              ),
            );
      }

      // Restore Chat Messages
      for (final raw in rawMessages) {
        final m = raw as Map<String, dynamic>;
        await _db.into(_db.chatMessages).insertOnConflictUpdate(
              ChatMessagesCompanion(
                id: Value(m['id'] as int),
                sessionId: Value(m['sessionId'] as int),
                role: Value(m['role'] as String),
                content: Value(m['content'] as String),
                messageType: Value(m['messageType'] as String? ?? 'text'),
                timestamp: Value(DateTime.parse((m['timestamp'] ?? m['createdAt']) as String)),
              ),
            );
      }

      // Restore Task Contexts (Memories)
      for (final raw in rawMemories) {
        final c = raw as Map<String, dynamic>;
        await _db.into(_db.taskContexts).insertOnConflictUpdate(
              TaskContextsCompanion(
                id: Value(c['id'] as int),
                taskId: Value(c['taskId'] as String),
                companyName: Value(c['companyName'] as String?),
                role: Value(c['role'] as String?),
                requirements: Value(c['requirements'] as String?),
                applicationLink: Value(c['applicationLink'] as String?),
                emailSnippet: Value(c['emailSnippet'] as String?),
                fullEmail: Value(c['fullEmail'] as String?),
                hasApplied: Value(c['hasApplied'] as bool? ?? false),
                appliedAt: Value(c['appliedAt'] != null ? DateTime.parse(c['appliedAt'] as String) : null),
                eventType: Value(c['eventType'] as String?),
                location: Value(c['location'] as String?),
                stipend: Value(c['stipend'] as String?),
                actionItems: Value(c['actionItems'] as String?),
                source: Value(c['source'] as String? ?? 'gmail'),
              ),
            );
      }

      // Restore Reminders
      for (final raw in rawReminders) {
        final r = raw as Map<String, dynamic>;
        await _db.into(_db.reminders).insertOnConflictUpdate(
              RemindersCompanion(
                id: Value(r['id'] as String),
                taskId: Value(r['taskId'] as String),
                scheduledAt: Value(DateTime.parse(r['scheduledAt'] as String)),
                timezone: Value(r['timezone'] as String? ?? 'Asia/Kolkata'),
                notificationId: Value(r['notificationId'] as int),
                status: Value(r['status'] as String? ?? 'scheduled'),
                createdAt: Value(DateTime.parse(r['createdAt'] as String)),
                updatedAt: Value(DateTime.parse(r['updatedAt'] as String)),
              ),
            );
      }

      // Restore Ritual Rules
      for (final raw in rawRitualRules) {
        final rr = raw as Map<String, dynamic>;
        await _db.into(_db.ritualRules).insertOnConflictUpdate(
              RitualRulesCompanion(
                id: Value(rr['id'] as int),
                eventType: Value(rr['eventType'] as String),
                title: Value(rr['title'] as String),
                instructions: Value(rr['instructions'] as String?),
                remindDaysBefore: Value(rr['remindDaysBefore'] as int? ?? 1),
                remindAtTime: Value(rr['remindAtTime'] as String? ?? '06:00'),
                isActive: Value(rr['isActive'] as bool? ?? true),
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
