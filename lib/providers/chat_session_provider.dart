import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/database.dart';
import 'ritual_provider.dart';

// ─── Models ──────────────────────────────────────────────────

class ChatSession {
  final int id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });
}

class ChatMessageData {
  final int id;
  final int sessionId;
  final String role; // 'user' or 'assistant'
  final String content;
  final String messageType;
  final DateTime timestamp;

  ChatMessageData({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.content,
    this.messageType = 'text',
    required this.timestamp,
  });
}

// ─── Notifier ───────────────────────────────────────────────

class ChatSessionNotifier extends StateNotifier<List<ChatSession>> {
  final Ref ref;

  ChatSessionNotifier(this.ref) : super([]) {
    loadSessions();
  }

  Future<void> loadSessions() async {
    final db = ref.read(databaseProvider);
    final sessions = await (db.select(db.chatSessions)
          ..orderBy([(t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc)]))
        .get();

    state = sessions
        .map((s) => ChatSession(
              id: s.id,
              title: s.title,
              createdAt: s.createdAt,
              updatedAt: s.updatedAt,
            ))
        .toList();
  }

  Future<int> createSession({String title = 'New Chat'}) async {
    final db = ref.read(databaseProvider);
    final now = DateTime.now();
    final id = await db.into(db.chatSessions).insert(
          ChatSessionsCompanion(
            title: Value(title),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
    await loadSessions();
    return id;
  }

  Future<void> deleteSession(int id) async {
    final db = ref.read(databaseProvider);
    await (db.delete(db.chatMessages)..where((t) => t.sessionId.equals(id))).go();
    await (db.delete(db.chatSessions)..where((t) => t.id.equals(id))).go();
    await loadSessions();
  }

  Future<void> updateSessionTitle(int id, String title) async {
    final db = ref.read(databaseProvider);
    await (db.update(db.chatSessions)..where((t) => t.id.equals(id))).write(
      ChatSessionsCompanion(
        title: Value(title),
        updatedAt: Value(DateTime.now()),
      ),
    );
    await loadSessions();
  }

  Future<List<ChatMessageData>> getMessages(int sessionId) async {
    final db = ref.read(databaseProvider);
    final messages = await (db.select(db.chatMessages)
          ..where((t) => t.sessionId.equals(sessionId))
          ..orderBy([(t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.asc)]))
        .get();

    return messages
        .map((m) => ChatMessageData(
              id: m.id,
              sessionId: m.sessionId,
              role: m.role,
              content: m.content,
              messageType: m.messageType,
              timestamp: m.timestamp,
            ))
        .toList();
  }

  Future<void> addMessage(int sessionId, String role, String content, {String messageType = 'text'}) async {
    final db = ref.read(databaseProvider);
    final now = DateTime.now();
    await db.into(db.chatMessages).insert(
          ChatMessagesCompanion(
            sessionId: Value(sessionId),
            role: Value(role),
            content: Value(content),
            messageType: Value(messageType),
            timestamp: Value(now),
          ),
        );

    await (db.update(db.chatSessions)..where((t) => t.id.equals(sessionId))).write(
      ChatSessionsCompanion(updatedAt: Value(now)),
    );
    await loadSessions();
  }
}

// ─── Providers ─────────────────────────────────────────────────────────────

final chatSessionProvider = StateNotifierProvider<ChatSessionNotifier, List<ChatSession>>((ref) {
  return ChatSessionNotifier(ref);
});

final currentSessionIdProvider = StateProvider<int?>((ref) => null);

final chatMessagesProvider = FutureProvider.family<List<ChatMessageData>, int>((ref, sessionId) async {
  final notifier = ref.read(chatSessionProvider.notifier);
  return await notifier.getMessages(sessionId);
});
