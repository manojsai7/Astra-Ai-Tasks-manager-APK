import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';

import '../../core/database/database.dart';
import 'astra_backup_service.dart';
import 'astra_crypto_service.dart';

/// Strategy applied during backup restoration when local data already exists.
enum RestoreStrategy {
  merge('Merge with Local Data', 'Adds incoming records and updates older local entries without deleting existing local data'),
  replaceSelected('Replace Selected Categories', 'Clears local records for selected categories and replaces them with backup data');

  final String title;
  final String description;

  const RestoreStrategy(this.title, this.description);
}

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
  final RestoreStrategy strategy;
  final List<String> categoriesRestored;
  final int tasksRestored;
  final int messagesRestored;
  final int sessionsRestored;
  final int memoriesRestored;
  final int remindersRestored;
  final int ritualRulesRestored;

  const AstraRestoreResult({
    required this.success,
    required this.metadata,
    this.strategy = RestoreStrategy.merge,
    this.categoriesRestored = const [],
    required this.tasksRestored,
    required this.messagesRestored,
    required this.sessionsRestored,
    required this.memoriesRestored,
    required this.remindersRestored,
    this.ritualRulesRestored = 0,
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

  /// Decrypts and extracts raw data payload from a backup archive.
  Future<Map<String, dynamic>> extractBackupData(
    Uint8List bytes, {
    String? password,
  }) async {
    final metadata = validateBackup(bytes);
    final jsonStr = utf8.decode(bytes);
    final json = jsonDecode(jsonStr) as Map<String, dynamic>;

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
        return jsonDecode(decryptedJsonString) as Map<String, dynamic>;
      } catch (_) {
        throw const AstraRestoreException('Decrypted payload contains invalid data structure.', 'corrupt_decrypted_data');
      }
    } else {
      // Legacy V1 unencrypted archive
      return json['data'] as Map<String, dynamic>? ?? {};
    }
  }

  /// Restores data from an encrypted (V2) or legacy (V1) backup archive into the active [AppDatabase].
  ///
  /// Invariants:
  /// - Full decryption, envelope inspection, and schema parsing execute before any database write.
  /// - If password is wrong or archive is corrupt, live database remains 100% untouched.
  /// - Selective category restoration allows restoring only chosen categories.
  /// - Restoration executes in a single atomic transaction.
  Future<AstraRestoreResult> restoreBackup(
    Uint8List bytes, {
    String? password,
    RestoreStrategy strategy = RestoreStrategy.merge,
    Set<AstraBackupCategory>? selectedCategories,
    bool? clearExisting, // Legacy backward compatibility flag
  }) async {
    final effectiveStrategy = clearExisting == true ? RestoreStrategy.replaceSelected : strategy;
    final metadata = validateBackup(bytes);
    final data = await extractBackupData(bytes, password: password);

    // Determine active categories to restore
    final categoriesToRestore = selectedCategories ??
        metadata.selectedCategories
            .map((id) => AstraBackupCategory.fromId(id))
            .whereType<AstraBackupCategory>()
            .toSet();

    final activeCategories = categoriesToRestore.isEmpty
        ? AstraBackupCategory.defaultCategories
        : categoriesToRestore;

    final rawTasks = data['tasks'] as List<dynamic>? ?? [];
    final rawSessions = data['chatSessions'] as List<dynamic>? ?? [];
    final rawMessages = data['chatMessages'] as List<dynamic>? ?? [];
    final rawMemories = data['taskContexts'] as List<dynamic>? ?? [];
    final rawReminders = data['reminders'] as List<dynamic>? ?? [];
    final rawRitualRules = data['ritualRules'] as List<dynamic>? ?? [];
    final rawInboxItems = data['inboxItems'] as List<dynamic>? ?? [];
    final rawPanchang = data['panchangEvents'] as List<dynamic>? ?? [];

    int tasksRestored = 0;
    int sessionsRestored = 0;
    int messagesRestored = 0;
    int memoriesRestored = 0;
    int remindersRestored = 0;
    int ritualRulesRestored = 0;

    // Execute everything in an atomic database transaction
    await _db.transaction(() async {
      // 1. If strategy is replaceSelected, delete existing records for selected categories
      if (effectiveStrategy == RestoreStrategy.replaceSelected) {
        if (activeCategories.contains(AstraBackupCategory.chat)) {
          await _db.delete(_db.chatMessages).go();
          await _db.delete(_db.chatSessions).go();
        }
        if (activeCategories.contains(AstraBackupCategory.reminders)) {
          await _db.delete(_db.reminders).go();
        }
        if (activeCategories.contains(AstraBackupCategory.memory)) {
          await _db.delete(_db.taskContexts).go();
        }
        if (activeCategories.contains(AstraBackupCategory.tasks)) {
          await _db.delete(_db.tasks).go();
          await _db.delete(_db.inboxItems).go();
        }
        if (activeCategories.contains(AstraBackupCategory.streaks)) {
          await _db.delete(_db.ritualRules).go();
        }
        if (activeCategories.contains(AstraBackupCategory.panchang)) {
          await _db.delete(_db.panchangEvents).go();
        }
      }

      // 2. Restore Inbox Items & Tasks
      if (activeCategories.contains(AstraBackupCategory.tasks)) {
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

        for (final raw in rawTasks) {
          final item = raw as Map<String, dynamic>;
          final incomingId = item['id'] as String;
          final incomingUpdatedAt = DateTime.parse(item['updatedAt'] as String);

          if (effectiveStrategy == RestoreStrategy.merge) {
            final localTask = await (_db.select(_db.tasks)..where((t) => t.id.equals(incomingId))).getSingleOrNull();
            if (localTask != null) {
              // Deterministic Merge: If local task is newer, preserve local state
              if (localTask.updatedAt.isAfter(incomingUpdatedAt)) {
                continue;
              }
              // If local task is completed and backup is pending, preserve completed status if local completed more recently
              if (localTask.status == 'completed' && item['status'] != 'completed' && localTask.completedAt != null) {
                if (localTask.completedAt!.isAfter(incomingUpdatedAt)) {
                  continue;
                }
              }
            }
          }

          await _db.into(_db.tasks).insertOnConflictUpdate(
                TasksCompanion(
                  id: Value(incomingId),
                  inboxItemId: Value(item['inboxItemId'] as String?),
                  title: Value(item['title'] as String),
                  description: Value(item['description'] as String?),
                  taskType: Value(item['taskType'] as String? ?? 'reminder'),
                  priority: Value(item['priority'] as String? ?? 'medium'),
                  status: Value(item['status'] as String? ?? 'pending'),
                  order: Value(item['order'] as int? ?? 0),
                  subtasksJson: Value(item['subtasksJson'] as String? ?? '[]'),
                  dueAt: Value(item['dueAt'] != null ? DateTime.parse(item['dueAt'] as String) : null),
                  dueTime: Value(item['dueTime'] as String?),
                  startAt: Value(item['startAt'] != null ? DateTime.parse(item['startAt'] as String) : null),
                  endAt: Value(item['endAt'] != null ? DateTime.parse(item['endAt'] as String) : null),
                  completedAt: Value(item['completedAt'] != null ? DateTime.parse(item['completedAt'] as String) : null),
                  createdAt: Value(DateTime.parse(item['createdAt'] as String)),
                  updatedAt: Value(incomingUpdatedAt),
                  source: Value(item['source'] as String?),
                  sourceId: Value(item['sourceId'] as String?),
                  category: Value(item['category'] as String?),
                  organization: Value(item['organization'] as String?),
                  recurrenceRuleJson: Value(item['recurrenceRuleJson'] as String?),
                ),
              );
          tasksRestored++;
        }
      }

      // 3. Restore Chat Sessions & Messages
      if (activeCategories.contains(AstraBackupCategory.chat)) {
        for (final raw in rawSessions) {
          final item = raw as Map<String, dynamic>;
          final sessionId = item['id'] as int;

          await _db.into(_db.chatSessions).insertOnConflictUpdate(
                ChatSessionsCompanion(
                  id: Value(sessionId),
                  title: Value(item['title'] as String? ?? 'New Chat'),
                  createdAt: Value(DateTime.parse(item['createdAt'] as String)),
                  updatedAt: Value(DateTime.parse(item['updatedAt'] as String)),
                ),
              );
          sessionsRestored++;
        }

        for (final raw in rawMessages) {
          final item = raw as Map<String, dynamic>;
          final sessionId = item['sessionId'] as int;
          final timestamp = DateTime.parse(item['timestamp'] as String);
          final content = item['content'] as String;

          if (effectiveStrategy == RestoreStrategy.merge) {
            // Deduplicate messages with same timestamp and content in session
            final existing = await (_db.select(_db.chatMessages)
                  ..where((m) => m.sessionId.equals(sessionId) & m.timestamp.equals(timestamp) & m.content.equals(content)))
                .getSingleOrNull();
            if (existing != null) continue;
          }

          await _db.into(_db.chatMessages).insertOnConflictUpdate(
                ChatMessagesCompanion(
                  id: Value(item['id'] as int),
                  sessionId: Value(sessionId),
                  role: Value(item['role'] as String),
                  content: Value(content),
                  messageType: Value(item['messageType'] as String? ?? 'text'),
                  timestamp: Value(timestamp),
                ),
              );
          messagesRestored++;
        }
      }

      // 4. Restore Memory (Task Contexts)
      if (activeCategories.contains(AstraBackupCategory.memory)) {
        for (final raw in rawMemories) {
          final item = raw as Map<String, dynamic>;
          final taskId = item['taskId'] as String? ?? '';

          if (effectiveStrategy == RestoreStrategy.merge && taskId.isNotEmpty) {
            final existing = await (_db.select(_db.taskContexts)..where((c) => c.taskId.equals(taskId))).getSingleOrNull();
            if (existing != null) {
              // Update with richer context if incoming is populated
              if (existing.hasApplied && item['hasApplied'] != true) {
                continue;
              }
            }
          }

          await _db.into(_db.taskContexts).insertOnConflictUpdate(
                TaskContextsCompanion(
                  id: Value(item['id'] as int),
                  taskId: Value(taskId),
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
          memoriesRestored++;
        }
      }

      // 5. Restore Reminders
      if (activeCategories.contains(AstraBackupCategory.reminders)) {
        for (final raw in rawReminders) {
          final item = raw as Map<String, dynamic>;
          final reminderId = item['id'] as String;
          final taskId = item['taskId'] as String;
          final incomingUpdatedAt = DateTime.parse(item['updatedAt'] as String);

          if (effectiveStrategy == RestoreStrategy.merge) {
            final localReminder = await (_db.select(_db.reminders)..where((r) => r.id.equals(reminderId))).getSingleOrNull();
            if (localReminder != null && localReminder.updatedAt.isAfter(incomingUpdatedAt)) {
              continue;
            }
          }

          await _db.into(_db.reminders).insertOnConflictUpdate(
                RemindersCompanion(
                  id: Value(reminderId),
                  taskId: Value(taskId),
                  scheduledAt: Value(DateTime.parse(item['scheduledAt'] as String)),
                  timezone: Value(item['timezone'] as String? ?? 'Asia/Kolkata'),
                  notificationId: Value(item['notificationId'] as int),
                  status: Value(item['status'] as String? ?? 'scheduled'),
                  createdAt: Value(DateTime.parse(item['createdAt'] as String)),
                  updatedAt: Value(incomingUpdatedAt),
                ),
              );
          remindersRestored++;
        }
      }

      // 6. Restore Ritual Rules (Streaks)
      if (activeCategories.contains(AstraBackupCategory.streaks)) {
        for (final raw in rawRitualRules) {
          final item = raw as Map<String, dynamic>;
          final id = item['id'] is int ? item['id'] as int : int.tryParse(item['id'].toString()) ?? 1;

          await _db.into(_db.ritualRules).insertOnConflictUpdate(
                RitualRulesCompanion(
                  id: Value(id),
                  eventType: Value(item['eventType'] as String),
                  title: Value(item['title'] as String),
                  instructions: Value(item['instructions'] as String?),
                  remindDaysBefore: Value(item['remindDaysBefore'] as int? ?? 1),
                  remindAtTime: Value(item['remindAtTime'] as String? ?? '06:00'),
                  isActive: Value(item['isActive'] as bool? ?? true),
                ),
              );
          ritualRulesRestored++;
        }
      }

      // 7. Restore Panchang Events (Optional)
      if (activeCategories.contains(AstraBackupCategory.panchang)) {
        for (final raw in rawPanchang) {
          final item = raw as Map<String, dynamic>;
          final id = item['id'] is int ? item['id'] as int : int.tryParse(item['id'].toString()) ?? 1;

          await _db.into(_db.panchangEvents).insertOnConflictUpdate(
                PanchangEventsCompanion(
                  id: Value(id),
                  eventName: Value(item['eventName'] as String),
                  displayName: Value(item['displayName'] as String),
                  eventDate: Value(DateTime.parse(item['eventDate'] as String)),
                  paksha: Value(item['paksha'] as String),
                  lunarMonth: Value(item['lunarMonth'] as String),
                  description: Value(item['description'] as String?),
                  calendarYear: Value(item['calendarYear'] as int? ?? DateTime.now().year),
                  notificationScheduled: Value(item['notificationScheduled'] as bool? ?? false),
                ),
              );
        }
      }
    });

    return AstraRestoreResult(
      success: true,
      metadata: metadata,
      strategy: effectiveStrategy,
      categoriesRestored: activeCategories.map((c) => c.id).toList(),
      tasksRestored: tasksRestored,
      messagesRestored: messagesRestored,
      sessionsRestored: sessionsRestored,
      memoriesRestored: memoriesRestored,
      remindersRestored: remindersRestored,
      ritualRulesRestored: ritualRulesRestored,
    );
  }
}
