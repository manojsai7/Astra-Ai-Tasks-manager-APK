import 'package:drift/drift.dart';
import '../../core/database/database.dart';
import 'astra_memory_engine.dart';

/// Context container encapsulating all relevant local knowledge for the current turn.
class AstraContext {
  final String currentText;
  final int? sessionId;
  final List<ChatMessageEntry> recentMessages;
  final List<TaskEntry> activeTasks;
  final List<PanchangEventEntry> upcomingEvents;
  final List<AstraMemoryItem> structuredMemories;
  final DateTime now;

  const AstraContext({
    required this.currentText,
    this.sessionId,
    this.recentMessages = const [],
    this.activeTasks = const [],
    this.upcomingEvents = const [],
    this.structuredMemories = const [],
    required this.now,
  });
}

/// Builds focused local context for user turns without unneeded overhead.
class AstraContextBuilder {
  final AppDatabase db;
  final AstraMemoryEngine memoryEngine;

  AstraContextBuilder({
    required this.db,
    required this.memoryEngine,
  });

  /// Assembles the smallest relevant local context for [currentText].
  Future<AstraContext> buildContext({
    required String currentText,
    int? sessionId,
    DateTime? now,
    int messageLimit = 20,
    int taskLimit = 15,
  }) async {
    final referenceNow = now ?? DateTime.now();

    // 1. Fetch recent messages if in an active session
    List<ChatMessageEntry> recentMessages = [];
    if (sessionId != null) {
      recentMessages = await memoryEngine.getRecentMessages(
        sessionId: sessionId,
        limit: messageLimit,
      );
    }

    // 2. Fetch active tasks (pending/active status)
    final tasksQuery = db.select(db.tasks)
      ..where((t) => t.status.isIn(['pending', 'active']))
      ..orderBy([(t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc)])
      ..limit(taskLimit);
    final activeTasks = await tasksQuery.get();

    // 3. Fetch structured memories from working memory
    final structuredMemories = memoryEngine.getAllWorkingMemories();

    // 4. Fetch upcoming panchang events if relevant
    List<PanchangEventEntry> upcomingEvents = [];
    try {
      upcomingEvents = await db.getUpcomingEvents(days: 14);
    } catch (_) {}

    return AstraContext(
      currentText: currentText,
      sessionId: sessionId,
      recentMessages: recentMessages,
      activeTasks: activeTasks,
      upcomingEvents: upcomingEvents,
      structuredMemories: structuredMemories,
      now: referenceNow,
    );
  }
}
