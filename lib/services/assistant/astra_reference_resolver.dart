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

    // B. Definite reference ("the exam", "the interview", "tomorrow's exam", "the assignment", "the assignment from email")
    if (definiteMatch != null && !isPronoun) {
      final query = definiteMatch.group(1)!.trim().toLowerCase();
      final cleanQuery = query
          .replaceAll(RegExp(r'\b(tomorrow|today|my)\b', caseSensitive: false), '')
          .replaceAll(RegExp(r'\b(?:from|in)\s+(?:the\s+)?(?:email|mail|gmail|calendar)\b', caseSensitive: false), '')
          .trim();

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

        // Search in structured memories (e.g. email task memories)
        final memoryMatches = context.structuredMemories.where((m) {
          final val = m.value.toLowerCase();
          final metaSubj = (m.metadata?['subject'] as String?)?.toLowerCase() ?? '';
          final metaOrg = (m.metadata?['organization'] as String?)?.toLowerCase() ?? '';
          return val.contains(cleanQuery) || metaSubj.contains(cleanQuery) || metaOrg.contains(cleanQuery);
        }).toList();

        if (memoryMatches.length == 1) {
          final match = memoryMatches.first;
          return AstraReferenceResult(
            isResolved: true,
            resolvedTitle: match.value,
            resolvedTaskId: match.metadata?['taskId'] as String?,
            resolvedType: 'memory',
            confidence: 0.93,
            reason: 'Resolved "$query" from structured memory "${match.value}".',
            memoryItem: match,
          );
        }
      }
    }

    // C. Pronoun reference ("it", "that", "this")
    if (isPronoun) {
      // 1. Resolve against most recent conversation entity first (what user just said in the current session)
      final recentEntities = _extractEntitiesFromMessages(context.recentMessages);
      if (recentEntities.isNotEmpty) {
        final lastEntity = recentEntities.last;
        // Verify if it matches an active task
        final matchingTask = context.activeTasks.where(
          (t) => t.title.toLowerCase() == lastEntity.toLowerCase() || t.title.toLowerCase().contains(lastEntity.toLowerCase()),
        ).firstOrNull;

        return AstraReferenceResult(
          isResolved: true,
          resolvedTitle: matchingTask?.title ?? lastEntity,
          resolvedTaskId: matchingTask?.id,
          resolvedType: matchingTask != null ? 'task' : 'conversation',
          confidence: 0.95,
          reason: 'Resolved pronoun "it" to most recent entity "$lastEntity".',
          taskEntry: matchingTask,
        );
      }

      // 2. Most recent active task if single active task exists
      if (context.activeTasks.length == 1) {
        final singleTask = context.activeTasks.first;
        return AstraReferenceResult(
          isResolved: true,
          resolvedTitle: singleTask.title,
          resolvedTaskId: singleTask.id,
          resolvedType: 'task',
          confidence: 0.92,
          reason: 'Resolved pronoun "it" to the single active task "${singleTask.title}".',
          taskEntry: singleTask,
        );
      } else if (context.activeTasks.length > 1) {
        return const AstraReferenceResult.unresolved(
          reason: 'Ambiguous: Multiple active tasks exist and no recent entity was referenced.',
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
      if (msg.role != 'user') continue;
      final text = msg.content;
      // Heuristic extraction of common task subjects (e.g. "exam", "interview", "assignment", "meeting")
      final patterns = [
        RegExp(r'\b(?:(?:have|got|my)\s+(?:a\s+|an\s+)?)([A-Za-z0-9]+\s+(?:exam|interview|assignment|meeting|standup|homework|task|project))\b', caseSensitive: false),
        RegExp(r'\b([A-Za-z0-9]+\s+(?:exam|interview|assignment|meeting|standup|homework|task|project))\b', caseSensitive: false),
        RegExp(r'\b(?:(?:have|got|my)\s+(?:a\s+|an\s+)?)(exam|interview|assignment|meeting|standup|homework|task|project)\b', caseSensitive: false),
        RegExp(r'\b(?:an?\s+)(exam|interview|assignment|meeting|standup|homework|task|project)\b', caseSensitive: false),
      ];

      for (final p in patterns) {
        final matches = p.allMatches(text);
        if (matches.isNotEmpty) {
          for (final m in matches) {
            var matched = m.group(1)!.trim();
            // Filter out responses like "Created Assignment" or "Task Created"
            if (matched.toLowerCase().startsWith('created ') || matched.toLowerCase().startsWith('updated ')) {
              continue;
            }

            // Strip leading helper words
            matched = matched.replaceAll(RegExp(r'^(?:have|got|a|an|my|the)\s+', caseSensitive: false), '').trim();

            // Title case each word cleanly
            final words = matched.split(RegExp(r'\s+'));
            final formatted = words.map((w) {
              if (w.isEmpty) return w;
              final lower = w.toLowerCase();
              if (lower == 'microsoft') return 'Microsoft';
              if (lower == 'google') return 'Google';
              if (lower == 'amazon') return 'Amazon';
              return '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}';
            }).join(' ');

            if (formatted.isNotEmpty && !entities.contains(formatted)) {
              entities.add(formatted);
            }
          }
          break; // Stop at highest priority pattern match for this message
        }
      }
    }
    return entities;
  }
}
