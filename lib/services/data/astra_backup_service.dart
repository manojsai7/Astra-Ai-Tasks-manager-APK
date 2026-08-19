import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';

import '../../core/database/database.dart';
import 'astra_crypto_service.dart';

/// Categories of user data supported for selective export and restore in ASTRA.
enum AstraBackupCategory {
  tasks('tasks', 'Tasks & Subtasks', 'Task items, subtasks, priorities, and recurrence rules', true),
  reminders('reminders', 'Reminders & Recurrence', 'Active reminder notifications and schedules', true),
  chat('chat', 'Chat History', 'ASTRA conversation sessions and message logs', true),
  memory('memory', 'ASTRA Memory', 'Extracted task contexts, entities, and long-term memory', true),
  streaks('streaks', 'Streaks & Focus', 'Habit streak rules, active rituals, and focus tracking', true),
  calendarLinks('calendarLinks', 'Calendar Links', 'Google Calendar external IDs and sync linkages', true),
  panchang('panchang', 'Panchang Cache', 'Pre-calculated Panchang dates and external cache', false),
  preferences('preferences', 'App Preferences', 'Theme, notification, and interface settings', false);

  final String id;
  final String title;
  final String description;
  final bool isDefaultSelected;

  const AstraBackupCategory(this.id, this.title, this.description, this.isDefaultSelected);

  /// The standard, recommended default categories defining ASTRA core identity.
  static Set<AstraBackupCategory> get defaultCategories =>
      AstraBackupCategory.values.where((c) => c.isDefaultSelected).toSet();

  static AstraBackupCategory? fromId(String id) {
    for (final c in AstraBackupCategory.values) {
      if (c.id == id || c.name == id) return c;
    }
    return null;
  }
}

/// Structured metadata for an ASTRA database backup archive.
class AstraBackupMetadata {
  static const String legacyV1Signature = 'ASTRA_BACKUP_V1';
  static const String encryptedV2Signature = 'ASTRA_ENCRYPTED_V2';
  static const int currentBackupVersion = 2;
  static const int currentSchemaVersion = 10;

  final String signature;
  final int backupVersion;
  final int schemaVersion;
  final DateTime createdAt;
  final String appVersion;
  final List<String> selectedCategories;
  final int taskCount;
  final int sessionCount;
  final int messageCount;
  final int memoryCount;
  final int reminderCount;
  final int ritualRuleCount;
  final int panchangCount;
  final String checksum;

  const AstraBackupMetadata({
    this.signature = encryptedV2Signature,
    this.backupVersion = currentBackupVersion,
    this.schemaVersion = currentSchemaVersion,
    required this.createdAt,
    required this.appVersion,
    this.selectedCategories = const [
      'tasks',
      'reminders',
      'chat',
      'memory',
      'streaks',
      'calendarLinks',
    ],
    required this.taskCount,
    required this.sessionCount,
    required this.messageCount,
    required this.memoryCount,
    required this.reminderCount,
    required this.ritualRuleCount,
    this.panchangCount = 0,
    required this.checksum,
  });

  Map<String, dynamic> toJson() => {
        'signature': signature,
        'backupVersion': backupVersion,
        'formatVersion': backupVersion,
        'schemaVersion': schemaVersion,
        'createdAt': createdAt.toIso8601String(),
        'appVersion': appVersion,
        'selectedCategories': selectedCategories,
        'categories': selectedCategories,
        'counts': {
          'taskCount': taskCount,
          'sessionCount': sessionCount,
          'messageCount': messageCount,
          'memoryCount': memoryCount,
          'reminderCount': reminderCount,
          'ritualRuleCount': ritualRuleCount,
          'panchangCount': panchangCount,
        },
        'checksum': checksum,
      };

  factory AstraBackupMetadata.fromJson(Map<String, dynamic> json) {
    final counts = json['counts'] as Map<String, dynamic>? ?? {};
    final rawCategories = json['selectedCategories'] as List<dynamic>? ??
        json['categories'] as List<dynamic>?;
    final categories = rawCategories?.map((e) => e.toString()).toList() ??
        AstraBackupCategory.defaultCategories.map((c) => c.id).toList();

    return AstraBackupMetadata(
      signature: json['signature'] as String? ?? '',
      backupVersion: json['backupVersion'] as int? ?? (json['formatVersion'] as int? ?? 1),
      schemaVersion: json['schemaVersion'] as int? ?? 1,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      appVersion: json['appVersion'] as String? ?? 'unknown',
      selectedCategories: categories,
      taskCount: counts['taskCount'] as int? ?? (json['taskCount'] as int? ?? 0),
      sessionCount: counts['sessionCount'] as int? ?? (json['sessionCount'] as int? ?? 0),
      messageCount: counts['messageCount'] as int? ?? (json['messageCount'] as int? ?? 0),
      memoryCount: counts['memoryCount'] as int? ?? (json['memoryCount'] as int? ?? 0),
      reminderCount: counts['reminderCount'] as int? ?? (json['reminderCount'] as int? ?? 0),
      ritualRuleCount: counts['ritualRuleCount'] as int? ?? (json['ritualRuleCount'] as int? ?? 0),
      panchangCount: counts['panchangCount'] as int? ?? (json['panchangCount'] as int? ?? 0),
      checksum: json['checksum'] as String? ?? '',
    );
  }

  bool get isEncryptedV2 => signature == encryptedV2Signature;
  bool get isLegacyV1 => signature == legacyV1Signature;
  bool get isValidSignature => isEncryptedV2 || isLegacyV1;

  bool containsCategory(AstraBackupCategory category) =>
      selectedCategories.contains(category.id) || selectedCategories.contains(category.name);
}

/// Complete backup container holding metadata and data tables (Legacy V1 plaintext container).
class AstraBackupPayload {
  final AstraBackupMetadata metadata;
  final Map<String, dynamic> data;

  const AstraBackupPayload({
    required this.metadata,
    required this.data,
  });

  Map<String, dynamic> toJson() => {
        'metadata': metadata.toJson(),
        'data': data,
      };

  String toJsonString() => jsonEncode(toJson());

  Uint8List toBytes() => Uint8List.fromList(utf8.encode(toJsonString()));

  factory AstraBackupPayload.fromJson(Map<String, dynamic> json) {
    final metadataJson = json['metadata'] as Map<String, dynamic>? ?? {};
    final dataJson = json['data'] as Map<String, dynamic>? ?? {};
    final metadata = AstraBackupMetadata.fromJson(metadataJson);

    return AstraBackupPayload(
      metadata: metadata,
      data: dataJson,
    );
  }

  factory AstraBackupPayload.fromBytes(Uint8List bytes) {
    final str = utf8.decode(bytes);
    final json = jsonDecode(str) as Map<String, dynamic>;
    return AstraBackupPayload.fromJson(json);
  }
}

/// Encrypted backup container (V2 format) holding envelope metadata and AES-256-GCM encrypted payload.
class AstraEncryptedBackupPayload {
  final AstraBackupMetadata metadata;
  final AstraEncryptedPackage encryptedPackage;

  const AstraEncryptedBackupPayload({
    required this.metadata,
    required this.encryptedPackage,
  });

  Map<String, dynamic> toJson() => {
        'signature': metadata.signature,
        'formatVersion': 2,
        'cipher': encryptedPackage.cipher,
        'kdf': encryptedPackage.kdf,
        'kdfParameters': {
          'iterations': encryptedPackage.kdfIterations,
          'keyLength': 32,
          'saltLength': 16,
          'nonceLength': 12,
        },
        'salt': encryptedPackage.saltBase64,
        'nonce': encryptedPackage.nonceBase64,
        'authTag': encryptedPackage.authTagBase64,
        'ciphertext': encryptedPackage.ciphertextBase64,
        'metadata': metadata.toJson(),
      };

  String toJsonString() => jsonEncode(toJson());

  Uint8List toBytes() => Uint8List.fromList(utf8.encode(toJsonString()));

  factory AstraEncryptedBackupPayload.fromJson(Map<String, dynamic> json) {
    final metadataJson = json['metadata'] as Map<String, dynamic>? ?? {};
    final metadata = AstraBackupMetadata.fromJson(metadataJson);
    final encryptedPackage = AstraEncryptedPackage.fromJson(json);

    return AstraEncryptedBackupPayload(
      metadata: metadata,
      encryptedPackage: encryptedPackage,
    );
  }

  factory AstraEncryptedBackupPayload.fromBytes(Uint8List bytes) {
    final str = utf8.decode(bytes);
    final json = jsonDecode(str) as Map<String, dynamic>;
    return AstraEncryptedBackupPayload.fromJson(json);
  }
}

/// Database statistics for display in UI and category size estimation.
class AstraDatabaseStats {
  final int taskCount;
  final int sessionCount;
  final int messageCount;
  final int memoryCount;
  final int reminderCount;
  final int ritualRuleCount;
  final int panchangCount;
  final int estimatedSizeBytes;

  const AstraDatabaseStats({
    required this.taskCount,
    required this.sessionCount,
    required this.messageCount,
    required this.memoryCount,
    required this.reminderCount,
    this.ritualRuleCount = 0,
    this.panchangCount = 0,
    required this.estimatedSizeBytes,
  });

  String get formattedSize {
    if (estimatedSizeBytes < 1024) return '$estimatedSizeBytes B';
    if (estimatedSizeBytes < 1024 * 1024) return '${(estimatedSizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(estimatedSizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  int estimateCategorySize(AstraBackupCategory category) {
    switch (category) {
      case AstraBackupCategory.tasks:
        return taskCount * 220;
      case AstraBackupCategory.reminders:
        return reminderCount * 120;
      case AstraBackupCategory.chat:
        return (sessionCount * 100) + (messageCount * 160);
      case AstraBackupCategory.memory:
        return memoryCount * 280;
      case AstraBackupCategory.streaks:
        return ritualRuleCount * 150;
      case AstraBackupCategory.calendarLinks:
        return (taskCount ~/ 3) * 80;
      case AstraBackupCategory.panchang:
        return panchangCount * 140;
      case AstraBackupCategory.preferences:
        return 512;
    }
  }

  int estimateSelectedSize(Set<AstraBackupCategory> selected) {
    int total = 256; // Base envelope metadata size
    for (final cat in selected) {
      total += estimateCategorySize(cat);
    }
    return total;
  }

  String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}

/// Service that creates consistent, secret-free, selective SQLite backup exports.
class AstraBackupService {
  final AppDatabase _db;
  final AstraCryptoService _cryptoService;

  AstraBackupService(this._db, {AstraCryptoService? cryptoService})
      : _cryptoService = cryptoService ?? AstraCryptoService();

  /// Generates the standard ASTRA backup filename: `ASTRA_Backup_YYYY-MM-DD_HH-mm.astra.db`.
  static String generateBackupFileName([DateTime? time]) {
    final t = time ?? DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd_HH-mm').format(t);
    return 'ASTRA_Backup_$dateStr.astra.db';
  }

  /// Queries database statistics.
  Future<AstraDatabaseStats> getStats() async {
    final tasks = await _db.select(_db.tasks).get();
    final sessions = await _db.select(_db.chatSessions).get();
    final messages = await _db.select(_db.chatMessages).get();
    final memories = await _db.select(_db.taskContexts).get();
    final reminders = await _db.select(_db.reminders).get();
    final ritualRules = await _db.select(_db.ritualRules).get();
    final panchang = await _db.select(_db.panchangEvents).get();

    final estimatedSize = 512 +
        (tasks.length * 220) +
        (sessions.length * 100) +
        (messages.length * 160) +
        (memories.length * 280) +
        (reminders.length * 120) +
        (ritualRules.length * 150);

    return AstraDatabaseStats(
      taskCount: tasks.length,
      sessionCount: sessions.length,
      messageCount: messages.length,
      memoryCount: memories.length,
      reminderCount: reminders.length,
      ritualRuleCount: ritualRules.length,
      panchangCount: panchang.length,
      estimatedSizeBytes: estimatedSize,
    );
  }

  /// Creates a consistent raw [AstraBackupPayload] internally for requested categories.
  Future<AstraBackupPayload> createBackup({
    Set<AstraBackupCategory>? categories,
    String appVersion = '2.1.3',
    DateTime? timestamp,
  }) async {
    final now = timestamp ?? DateTime.now().toUtc();
    final activeCategories = categories ?? AstraBackupCategory.defaultCategories;
    final selectedCategoryIds = activeCategories.map((c) => c.id).toList();

    final Map<String, dynamic> dataPayload = {};

    int taskCount = 0;
    int sessionCount = 0;
    int messageCount = 0;
    int memoryCount = 0;
    int reminderCount = 0;
    int ritualRuleCount = 0;
    int panchangCount = 0;

    // 1. TASKS & INBOX ITEMS
    if (activeCategories.contains(AstraBackupCategory.tasks)) {
      final tasks = await _db.select(_db.tasks).get();
      final inboxItems = await _db.select(_db.inboxItems).get();
      taskCount = tasks.length;

      dataPayload['tasks'] = tasks
          .map((t) => {
                'id': t.id,
                'inboxItemId': t.inboxItemId,
                'title': t.title,
                'description': t.description,
                'taskType': t.taskType,
                'priority': t.priority,
                'status': t.status,
                'order': t.order,
                'subtasksJson': t.subtasksJson,
                'dueAt': t.dueAt?.toIso8601String(),
                'dueTime': t.dueTime,
                'startAt': t.startAt?.toIso8601String(),
                'endAt': t.endAt?.toIso8601String(),
                'completedAt': t.completedAt?.toIso8601String(),
                'createdAt': t.createdAt.toIso8601String(),
                'updatedAt': t.updatedAt.toIso8601String(),
                'source': t.source,
                'sourceId': activeCategories.contains(AstraBackupCategory.calendarLinks) ? t.sourceId : null,
                'category': t.category,
                'organization': t.organization,
                'recurrenceRuleJson': t.recurrenceRuleJson,
              })
          .toList();

      dataPayload['inboxItems'] = inboxItems
          .map((i) => {
                'id': i.id,
                'rawText': i.rawText,
                'sourceType': i.sourceType,
                'processingStatus': i.processingStatus,
                'receivedAt': i.receivedAt.toIso8601String(),
                'createdAt': i.createdAt.toIso8601String(),
                'updatedAt': i.updatedAt.toIso8601String(),
              })
          .toList();
    }

    // 2. REMINDERS
    if (activeCategories.contains(AstraBackupCategory.reminders)) {
      final reminders = await _db.select(_db.reminders).get();
      reminderCount = reminders.length;

      dataPayload['reminders'] = reminders
          .map((r) => {
                'id': r.id,
                'taskId': r.taskId,
                'scheduledAt': r.scheduledAt.toIso8601String(),
                'timezone': r.timezone,
                'notificationId': r.notificationId,
                'status': r.status,
                'createdAt': r.createdAt.toIso8601String(),
                'updatedAt': r.updatedAt.toIso8601String(),
              })
          .toList();
    }

    // 3. CHAT SESSIONS & MESSAGES
    if (activeCategories.contains(AstraBackupCategory.chat)) {
      final sessions = await _db.select(_db.chatSessions).get();
      final messages = await _db.select(_db.chatMessages).get();
      sessionCount = sessions.length;
      messageCount = messages.length;

      dataPayload['chatSessions'] = sessions
          .map((s) => {
                'id': s.id,
                'title': s.title,
                'createdAt': s.createdAt.toIso8601String(),
                'updatedAt': s.updatedAt.toIso8601String(),
              })
          .toList();

      dataPayload['chatMessages'] = messages
          .map((m) => {
                'id': m.id,
                'sessionId': m.sessionId,
                'role': m.role,
                'content': m.content,
                'messageType': m.messageType,
                'timestamp': m.timestamp.toIso8601String(),
              })
          .toList();
    }

    // 4. MEMORY (TASK CONTEXTS)
    if (activeCategories.contains(AstraBackupCategory.memory)) {
      final memories = await _db.select(_db.taskContexts).get();
      memoryCount = memories.length;

      dataPayload['taskContexts'] = memories
          .map((c) => {
                'id': c.id,
                'taskId': c.taskId,
                'companyName': c.companyName,
                'role': c.role,
                'requirements': c.requirements,
                'applicationLink': c.applicationLink,
                'emailSnippet': c.emailSnippet,
                'fullEmail': c.fullEmail,
                'hasApplied': c.hasApplied,
                'appliedAt': c.appliedAt?.toIso8601String(),
                'eventType': c.eventType,
                'location': c.location,
                'stipend': c.stipend,
                'actionItems': c.actionItems,
                'source': c.source,
              })
          .toList();
    }

    // 5. STREAKS & FOCUS RITUALS
    if (activeCategories.contains(AstraBackupCategory.streaks)) {
      final ritualRules = await _db.select(_db.ritualRules).get();
      ritualRuleCount = ritualRules.length;

      dataPayload['ritualRules'] = ritualRules
          .map((rr) => {
                'id': rr.id,
                'eventType': rr.eventType,
                'title': rr.title,
                'instructions': rr.instructions,
                'remindDaysBefore': rr.remindDaysBefore,
                'remindAtTime': rr.remindAtTime,
                'isActive': rr.isActive,
              })
          .toList();
    }

    // 6. PANCHANG CACHE (Optional)
    if (activeCategories.contains(AstraBackupCategory.panchang)) {
      final events = await _db.select(_db.panchangEvents).get();
      panchangCount = events.length;

      dataPayload['panchangEvents'] = events
          .map((p) => {
                'id': p.id,
                'eventName': p.eventName,
                'displayName': p.displayName,
                'eventDate': p.eventDate.toIso8601String(),
                'paksha': p.paksha,
                'lunarMonth': p.lunarMonth,
                'description': p.description,
                'calendarYear': p.calendarYear,
                'notificationScheduled': p.notificationScheduled,
              })
          .toList();
    }

    // 7. PREFERENCES (Optional safe preferences map)
    if (activeCategories.contains(AstraBackupCategory.preferences)) {
      dataPayload['preferences'] = {
        'theme': 'dark',
        'hapticsEnabled': true,
        'exactAlarmEnabled': true,
      };
    }

    // Calculate cryptographic SHA-256 checksum over data payload
    final dataString = jsonEncode(dataPayload);
    final checksum = sha256.convert(utf8.encode(dataString)).toString();

    final metadata = AstraBackupMetadata(
      signature: AstraBackupMetadata.legacyV1Signature,
      backupVersion: 1,
      schemaVersion: AstraBackupMetadata.currentSchemaVersion,
      createdAt: now,
      appVersion: appVersion,
      selectedCategories: selectedCategoryIds,
      taskCount: taskCount,
      sessionCount: sessionCount,
      messageCount: messageCount,
      memoryCount: memoryCount,
      reminderCount: reminderCount,
      ritualRuleCount: ritualRuleCount,
      panchangCount: panchangCount,
      checksum: checksum,
    );

    return AstraBackupPayload(
      metadata: metadata,
      data: dataPayload,
    );
  }

  /// Creates a password-protected, authenticated encrypted [AstraEncryptedBackupPayload] (V2 format)
  /// for the selected categories.
  Future<AstraEncryptedBackupPayload> createEncryptedBackup({
    required String password,
    Set<AstraBackupCategory>? categories,
    String appVersion = '2.1.3',
    DateTime? timestamp,
    int kdfIterations = AstraCryptoService.defaultPbkdf2Iterations,
  }) async {
    // 1. Create the plaintext payload internally with selective category filtering
    final plainPayload = await createBackup(
      categories: categories,
      appVersion: appVersion,
      timestamp: timestamp,
    );

    // 2. Encrypt the data payload JSON string using AES-256-GCM + PBKDF2
    final dataJsonString = jsonEncode(plainPayload.data);
    final encryptedPackage = await _cryptoService.encryptData(
      plaintext: dataJsonString,
      password: password,
      iterations: kdfIterations,
    );

    final v2Metadata = AstraBackupMetadata(
      signature: AstraBackupMetadata.encryptedV2Signature,
      backupVersion: 2,
      schemaVersion: AstraBackupMetadata.currentSchemaVersion,
      createdAt: plainPayload.metadata.createdAt,
      appVersion: appVersion,
      selectedCategories: plainPayload.metadata.selectedCategories,
      taskCount: plainPayload.metadata.taskCount,
      sessionCount: plainPayload.metadata.sessionCount,
      messageCount: plainPayload.metadata.messageCount,
      memoryCount: plainPayload.metadata.memoryCount,
      reminderCount: plainPayload.metadata.reminderCount,
      ritualRuleCount: plainPayload.metadata.ritualRuleCount,
      panchangCount: plainPayload.metadata.panchangCount,
      checksum: plainPayload.metadata.checksum,
    );

    return AstraEncryptedBackupPayload(
      metadata: v2Metadata,
      encryptedPackage: encryptedPackage,
    );
  }
}
