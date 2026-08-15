import '../../core/database/database.dart';
import 'astra_context_builder.dart';
import 'astra_memory_engine.dart';

/// Represents a resolved reference (e.g. "it", "the exam", "the Microsoft one").
class AstraReferenceResult {
  final bool isResolved;
  final String? resolvedTitle;
  final String? resolvedTaskId;
  final String? resolvedType; // 'task', 'memory', 'event'
  final double confidence;
  final String reason;
  final AstraMemoryItem? memoryItem;
  final TaskEntry? taskEntry;

  const AstraReferenceResult({
    required this.isResolved,
    this.resolvedTitle,
    this.resolvedTaskId,
    this.resolvedType,
    this.confidence = 0.0,
    required this.reason,
    this.memoryItem,
    this.taskEntry,
  });

  const AstraReferenceResult.unresolved({required this.reason})
      : isResolved = false,
        resolvedTitle = null,
        resolvedTaskId = null,
        resolvedType = null,
        confidence = 0.0,
        memoryItem = null,
        taskEntry = null;
}

/// Resolves anaphoric and definite references ("it", "that", "the exam", "the Microsoft one")
/// against local conversation, active tasks, and structured memories.
class AstraReferenceResolver {
  const AstraReferenceResolver();

  /// Resolves any reference contained in [text] given [context].
  AstraReferenceResult resolveReference(
    String text,
    AstraContext context,
  ) {
    final lower = text.trim().toLowerCase();

    // 1. Detect if the text contains an anaphoric or definite reference
    final isPronoun = RegExp(r'\b(it|that|this|them)\b', caseSensitive: false).hasMatch(lower);
    final definiteMatch = RegExp(
      r'\b(?:the|that|my)\s+([a-z0-9_\s]+?)(?:\s+(?:at|to|on|before|by|for|deadline|time)|\s*$)',
      caseSensitive: false,
    ).firstMatch(lower);

    final isOrgReference = RegExp(r'\bthe\s+([a-z0-9]+)\s+one\b', caseSensitive: false).firstMatch(lower);

    if (!isPronoun && definiteMatch == null && isOrgReference == null) {
      return const AstraReferenceResult.unresolved(
        reason: 'No anaphoric or definite reference detected in text.',
      );
    }

    // A. Specific Organization reference ("the Microsoft one", "the Google one")
    if (isOrgReference != null) {
      final org = isOrgReference.group(1)!.trim().toLowerCase();
      final candidates = context.activeTasks.where((t) {
        final taskOrg = t.organization?.toLowerCase() ?? '';
        final taskTitle = t.title.toLowerCase();
        return taskOrg.contains(org) || taskTitle.contains(org);
      }).toList();

      if (candidates.length == 1) {
        final match = candidates.first;
        return AstraReferenceResult(
          isResolved: true,
          resolvedTitle: match.title,
          resolvedTaskId: match.id,
          resolvedType: 'task',
          confidence: 0.95,
          reason: 'Resolved "$org" organization reference to active task "${match.title}".',
          taskEntry: match,
        );
      } else if (candidates.length > 1) {
        return AstraReferenceResult.unresolved(
          reason: 'Ambiguous: Multiple active tasks found matching "$org".',
        );
      }
    }

    // B. Definite reference ("the exam", "the interview", "tomorrow's exam", "the assignment")
    if (definiteMatch != null && !isPronoun) {
      final query = definiteMatch.group(1)!.trim().toLowerCase();
      final cleanQuery = query.replaceAll(RegExp(r'\b(tomorrow|today|my)\b'), '').trim();

      if (cleanQuery.isNotEmpty && cleanQuery != 'one') {
        // Search in active tasks
        final taskMatches = context.activeTasks.where((t) {
          final tTitle = t.title.toLowerCase();
          return tTitle.contains(cleanQuery);
        }).toList();

        if (taskMatches.length == 1) {
          final match = taskMatches.first;
          return AstraReferenceResult(
            isResolved: true,
            resolvedTitle: match.title,
            resolvedTaskId: match.id,
            resolvedType: 'task',
            confidence: 0.95,
            reason: 'Resolved definite reference "$query" to active task "${match.title}".',
            taskEntry: match,
          );
        } else if (taskMatches.length > 1) {
          return AstraReferenceResult.unresolved(
            reason: 'Ambiguous: Multiple active tasks matched "$query".',
          );
        }

        // Search in recent conversation messages
        final recentEntities = _extractEntitiesFromMessages(context.recentMessages);
        final msgMatches = recentEntities.where((e) => e.toLowerCase().contains(cleanQuery)).toList();
        if (msgMatches.length == 1) {
          return AstraReferenceResult(
            isResolved: true,
            resolvedTitle: msgMatches.first,
            resolvedType: 'conversation',
            confidence: 0.90,
            reason: 'Resolved "$query" from recent conversation entity "${msgMatches.first}".',
          );
        }
      }
    }

    // C. Pronoun reference ("it", "that", "this")
    if (isPronoun) {
      // 1. Most recent active task if created/updated very recently
      if (context.activeTasks.isNotEmpty) {
        // Priority to the single latest task if unique or explicitly prominent
        final latestTask = context.activeTasks.first;
        // Check if recent conversation specifically talked about this task or if only 1 task exists
        if (context.activeTasks.length == 1) {
          return AstraReferenceResult(
            isResolved: true,
            resolvedTitle: latestTask.title,
            resolvedTaskId: latestTask.id,
            resolvedType: 'task',
            confidence: 0.92,
            reason: 'Resolved pronoun "it" to the single active task "${latestTask.title}".',
            taskEntry: latestTask,
          );
        }
      }

      // 2. Resolve against most recent conversation entity
      final recentEntities = _extractEntitiesFromMessages(context.recentMessages);
      if (recentEntities.isNotEmpty) {
        final lastEntity = recentEntities.last;
        // Verify if it matches an active task
        final matchingTask = context.activeTasks.where(
          (t) => t.title.toLowerCase() == lastEntity.toLowerCase(),
        ).firstOrNull;

        return AstraReferenceResult(
          isResolved: true,
          resolvedTitle: lastEntity,
          resolvedTaskId: matchingTask?.id,
          resolvedType: matchingTask != null ? 'task' : 'conversation',
          confidence: 0.90,
          reason: 'Resolved pronoun "it" to most recent entity "$lastEntity".',
          taskEntry: matchingTask,
        );
      }

      // 3. Fallback to structured memories
      if (context.structuredMemories.isNotEmpty) {
        final latestMemory = context.structuredMemories.last;
        return AstraReferenceResult(
          isResolved: true,
          resolvedTitle: latestMemory.value,
          resolvedType: 'memory',
          confidence: 0.85,
          reason: 'Resolved pronoun "it" to structured memory "${latestMemory.key}".',
          memoryItem: latestMemory,
        );
      }
    }

    return const AstraReferenceResult.unresolved(
      reason: 'Could not resolve reference against local context.',
    );
  }

  /// Helper extracting meaningful entity titles from recent conversation messages.
  List<String> _extractEntitiesFromMessages(List<ChatMessageEntry> messages) {
    final entities = <String>[];
    for (final msg in messages) {
      final text = msg.content;
      // Heuristic extraction of common task subjects (e.g. "exam", "interview", "assignment", "meeting")
      final patterns = [
        RegExp(r'\b([A-Za-z0-9]+\s+(?:exam|interview|assignment|meeting|standup))\b', caseSensitive: false),
        RegExp(r'\b(?:have\s+(?:a\s+|an\s+)?|my\s+)(exam|interview|assignment|meeting|standup)\b', caseSensitive: false),
      ];

      for (final p in patterns) {
        final m = p.firstMatch(text);
        if (m != null) {
          final matched = m.group(1)!.trim();
          // Title case each word cleanly
          final words = matched.split(RegExp(r'\s+'));
          final formatted = words.map((w) {
            if (w.isEmpty) return w;
            return '${w[0].toUpperCase()}${w.substring(1)}';
          }).join(' ');

          if (!entities.contains(formatted)) {
            entities.add(formatted);
          }
        }
      }
    }
    return entities;
  }
}
