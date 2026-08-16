import 'package:drift/drift.dart';
import '../../core/database/database.dart';

/// Represents an item of structured memory stored or extracted locally.
class AstraMemoryItem {
  final String id;
  final String type; // e.g. 'EVENT_REFERENCE', 'USER_PREFERENCE', 'FACT'
  final String key;
  final String value;
  final String source; // e.g. 'conversation', 'task', 'calendar'
  final double confidence;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  const AstraMemoryItem({
    required this.id,
    required this.type,
    required this.key,
    required this.value,
    this.source = 'conversation',
    this.confidence = 1.0,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'key': key,
        'value': value,
        'source': source,
        'confidence': confidence,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        if (metadata != null) 'metadata': metadata,
      };

  factory AstraMemoryItem.fromJson(Map<String, dynamic> json) => AstraMemoryItem(
        id: json['id'] as String,
        type: json['type'] as String,
        key: json['key'] as String,
        value: json['value'] as String,
        source: json['source'] as String? ?? 'conversation',
        confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        metadata: json['metadata'] as Map<String, dynamic>?,
      );
}

/// Lightweight memory engine for managing working memory and structured entity memory.
class AstraMemoryEngine {
  final AppDatabase _db;
  final Map<String, AstraMemoryItem> _workingMemory = {};

  AstraMemoryEngine(this._db);

  /// Saves a message into the current SQLite chat session.
  Future<void> saveMessage({
    required int sessionId,
    required String role,
    required String content,
    String messageType = 'text',
  }) async {
    final now = DateTime.now();
    await _db.into(_db.chatMessages).insert(
          ChatMessagesCompanion(
            sessionId: Value(sessionId),
            role: Value(role),
            content: Value(content),
            messageType: Value(messageType),
            timestamp: Value(now),
          ),
        );
  }

  /// Retrieves recent messages from the current Drift chat session (up to [limit]).
  Future<List<ChatMessageEntry>> getRecentMessages({
    required int sessionId,
    int limit = 20,
  }) async {
    final query = _db.select(_db.chatMessages)
      ..where((t) => t.sessionId.equals(sessionId))
      ..orderBy([(t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc)])
      ..limit(limit);

    final messages = await query.get();
    // Return in chronological order
    return messages.reversed.toList();
  }

  /// Stores a structured memory item in working memory / cache.
  void storeMemory(AstraMemoryItem item) {
    _workingMemory[item.key] = item;
  }

  /// Records a structured memory item for an email-derived task.
  void storeEmailTaskMemory({
    required String emailId,
    required String title,
    required String taskId,
    DateTime? deadline,
    String? organization,
    String? subject,
  }) {
    final now = DateTime.now();
    final item = AstraMemoryItem(
      id: 'email_task_$taskId',
      type: 'EMAIL_TASK_REFERENCE',
      key: 'email_$emailId',
      value: title,
      source: 'email',
      confidence: 1.0,
      createdAt: now,
      updatedAt: now,
      metadata: {
        'taskId': taskId,
        'emailId': emailId,
        'title': title,
        'deadline': deadline?.toIso8601String(),
        'organization': organization,
        'subject': subject,
      },
    );
    storeMemory(item);
  }

  /// Searches working memory for references matching a query (e.g. "assignment from email").
  List<AstraMemoryItem> searchEmailMemories(String query) {
    final qLower = query.toLowerCase();
    return _workingMemory.values.where((m) {
      if (m.source != 'email') return false;
      final valLower = m.value.toLowerCase();
      final orgLower = (m.metadata?['organization'] as String?)?.toLowerCase() ?? '';
      final subjLower = (m.metadata?['subject'] as String?)?.toLowerCase() ?? '';
      return valLower.contains(qLower) || orgLower.contains(qLower) || subjLower.contains(qLower);
    }).toList();
  }

  /// Retrieves a structured memory item by key.
  AstraMemoryItem? getMemory(String key) {
    return _workingMemory[key];
  }

  /// Returns all working structured memories.
  List<AstraMemoryItem> getAllWorkingMemories() {
    return _workingMemory.values.toList();
  }

  /// Clears in-memory working structured memories.
  void clearWorkingMemory() {
    _workingMemory.clear();
  }
}

/// Tracks a lightweight pending conversation action across turns (e.g. "move my exam" -> "tomorrow at 7").
class PendingConversationAction {
  final String targetEntity;
  final String operation; // e.g. 'UPDATE_TASK', 'CREATE_TASK', 'CREATE_REMINDER'
  final List<String> missingFields; // e.g. ['time', 'title']
  final DateTime createdAt;
  final int? sessionId;

  const PendingConversationAction({
    required this.targetEntity,
    required this.operation,
    required this.missingFields,
    required this.createdAt,
    this.sessionId,
  });
}

