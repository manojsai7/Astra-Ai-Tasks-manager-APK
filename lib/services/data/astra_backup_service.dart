import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';

import '../../core/database/database.dart';

/// Structured metadata for an ASTRA database backup archive.
class AstraBackupMetadata {
  static const String currentSignature = 'ASTRA_BACKUP_V1';
  static const int currentBackupVersion = 1;
  static const int currentSchemaVersion = 9;

  final String signature;
  final int backupVersion;
  final int schemaVersion;
  final DateTime createdAt;
  final String appVersion;
  final int taskCount;
  final int sessionCount;
  final int messageCount;
  final int memoryCount;
  final int reminderCount;
  final int ritualRuleCount;
  final String checksum;

  const AstraBackupMetadata({
    this.signature = currentSignature,
    this.backupVersion = currentBackupVersion,
    this.schemaVersion = currentSchemaVersion,
    required this.createdAt,
    required this.appVersion,
    required this.taskCount,
    required this.sessionCount,
    required this.messageCount,
    required this.memoryCount,
    required this.reminderCount,
    required this.ritualRuleCount,
    required this.checksum,
  });

  Map<String, dynamic> toJson() => {
        'signature': signature,
        'backupVersion': backupVersion,
        'schemaVersion': schemaVersion,
        'createdAt': createdAt.toIso8601String(),
        'appVersion': appVersion,
        'counts': {
          'taskCount': taskCount,
          'sessionCount': sessionCount,
          'messageCount': messageCount,
          'memoryCount': memoryCount,
          'reminderCount': reminderCount,
          'ritualRuleCount': ritualRuleCount,
        },
        'checksum': checksum,
      };

  factory AstraBackupMetadata.fromJson(Map<String, dynamic> json) {
    final counts = json['counts'] as Map<String, dynamic>? ?? {};
    return AstraBackupMetadata(
      signature: json['signature'] as String? ?? '',
      backupVersion: json['backupVersion'] as int? ?? 1,
      schemaVersion: json['schemaVersion'] as int? ?? 1,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      appVersion: json['appVersion'] as String? ?? 'unknown',
      taskCount: counts['taskCount'] as int? ?? (json['taskCount'] as int? ?? 0),
      sessionCount: counts['sessionCount'] as int? ?? (json['sessionCount'] as int? ?? 0),
      messageCount: counts['messageCount'] as int? ?? (json['messageCount'] as int? ?? 0),
      memoryCount: counts['memoryCount'] as int? ?? (json['memoryCount'] as int? ?? 0),
      reminderCount: counts['reminderCount'] as int? ?? (json['reminderCount'] as int? ?? 0),
      ritualRuleCount: counts['ritualRuleCount'] as int? ?? (json['ritualRuleCount'] as int? ?? 0),
      checksum: json['checksum'] as String? ?? '',
    );
  }

  bool get isValidSignature => signature == currentSignature;
}

/// Complete backup container holding metadata and data tables.
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

/// Database statistics for display in UI.
class AstraDatabaseStats {
  final int taskCount;
  final int sessionCount;
  final int messageCount;
  final int memoryCount;
  final int reminderCount;
  final int estimatedSizeBytes;

  const AstraDatabaseStats({
    required this.taskCount,
    required this.sessionCount,
    required this.messageCount,
    required this.memoryCount,
    required this.reminderCount,
    required this.estimatedSizeBytes,
  });

  String get formattedSize {
    if (estimatedSizeBytes < 1024) return '$estimatedSizeBytes B';
    if (estimatedSizeBytes < 1024 * 1024) return '${(estimatedSizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(estimatedSizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}

/// Service that creates consistent, secret-free SQLite backup exports.
class AstraBackupService {
  final AppDatabase _db;

  const AstraBackupService(this._db);

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

    // Compute approximate payload size in bytes
    final sampleJson = jsonEncode({
      'tasks': tasks.length * 200,
      'messages': messages.length * 150,
      'memories': memories.length * 100,
    });
    final estimatedSize = sampleJson.length + (tasks.length * 200) + (messages.length * 180);

    return AstraDatabaseStats(
      taskCount: tasks.length,
      sessionCount: sessions.length,
      messageCount: messages.length,
      memoryCount: memories.length,
      reminderCount: reminders.length,
      estimatedSizeBytes: estimatedSize,
    );
  }

  /// Creates a consistent, secret-free [AstraBackupPayload].
  Future<AstraBackupPayload> createBackup({
    String appVersion = '2.1.3',
    DateTime? timestamp,
  }) async {
    final now = timestamp ?? DateTime.now().toUtc();

    // Query all persistent user data tables
    final tasks = await _db.select(_db.tasks).get();
    final sessions = await _db.select(_db.chatSessions).get();
    final messages = await _db.select(_db.chatMessages).get();
    final memories = await _db.select(_db.taskContexts).get();
    final reminders = await _db.select(_db.reminders).get();
    final ritualRules = await _db.select(_db.ritualRules).get();
    final inboxItems = await _db.select(_db.inboxItems).get();

    // Serialize each table into raw JSON maps (excluding any potential sensitive data)
    final Map<String, dynamic> dataPayload = {
      'tasks': tasks
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
                'startAt': t.startAt?.toIso8601String(),
                'endAt': t.endAt?.toIso8601String(),
                'completedAt': t.completedAt?.toIso8601String(),
                'createdAt': t.createdAt.toIso8601String(),
                'updatedAt': t.updatedAt.toIso8601String(),
                'source': t.source,
                'sourceId': t.sourceId,
                'category': t.category,
                'organization': t.organization,
                'recurrenceRuleJson': t.recurrenceRuleJson,
              })
          .toList(),
      'chatSessions': sessions
          .map((s) => {
                'id': s.id,
                'title': s.title,
                'createdAt': s.createdAt.toIso8601String(),
                'updatedAt': s.updatedAt.toIso8601String(),
              })
          .toList(),
      'chatMessages': messages
          .map((m) => {
                'id': m.id,
                'sessionId': m.sessionId,
                'role': m.role,
                'content': m.content,
                'messageType': m.messageType,
                'timestamp': m.timestamp.toIso8601String(),
              })
          .toList(),
      'taskContexts': memories
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
          .toList(),
      'reminders': reminders
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
          .toList(),
      'ritualRules': ritualRules
          .map((rr) => {
                'id': rr.id,
                'eventType': rr.eventType,
                'title': rr.title,
                'instructions': rr.instructions,
                'remindDaysBefore': rr.remindDaysBefore,
                'remindAtTime': rr.remindAtTime,
                'isActive': rr.isActive,
              })
          .toList(),
      'inboxItems': inboxItems
          .map((i) => {
                'id': i.id,
                'rawText': i.rawText,
                'sourceType': i.sourceType,
                'processingStatus': i.processingStatus,
                'receivedAt': i.receivedAt.toIso8601String(),
                'createdAt': i.createdAt.toIso8601String(),
                'updatedAt': i.updatedAt.toIso8601String(),
              })
          .toList(),
    };

    // Calculate cryptographic SHA-256 checksum over data payload
    final dataString = jsonEncode(dataPayload);
    final checksum = sha256.convert(utf8.encode(dataString)).toString();

    final metadata = AstraBackupMetadata(
      createdAt: now,
      appVersion: appVersion,
      taskCount: tasks.length,
      sessionCount: sessions.length,
      messageCount: messages.length,
      memoryCount: memories.length,
      reminderCount: reminders.length,
      ritualRuleCount: ritualRules.length,
      checksum: checksum,
    );

    return AstraBackupPayload(
      metadata: metadata,
      data: dataPayload,
    );
  }
}
