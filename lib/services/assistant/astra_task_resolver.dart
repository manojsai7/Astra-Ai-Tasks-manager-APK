import '../../models/task.dart';

/// Outcomes when resolving a target task from a user query.
enum TaskResolutionOutcome {
  exact,
  ambiguous,
  notFound,
}

/// Sealed-style immutable result of task resolution.
class TaskResolutionResult {
  final TaskResolutionOutcome outcome;
  final Task? task;
  final List<Task> candidates;
  final String? query;

  const TaskResolutionResult._({
    required this.outcome,
    this.task,
    this.candidates = const [],
    this.query,
  });

  /// Found exactly one unambiguously matching task.
  factory TaskResolutionResult.exact(Task task) {
    return TaskResolutionResult._(
      outcome: TaskResolutionOutcome.exact,
      task: task,
      candidates: [task],
    );
  }

  /// Found multiple tasks sharing the same best match strength.
  factory TaskResolutionResult.ambiguous(List<Task> candidates) {
    return TaskResolutionResult._(
      outcome: TaskResolutionOutcome.ambiguous,
      candidates: List.unmodifiable(candidates),
    );
  }

  /// Found no matching tasks in the active task list.
  factory TaskResolutionResult.notFound(String query) {
    return TaskResolutionResult._(
      outcome: TaskResolutionOutcome.notFound,
      query: query,
    );
  }

  bool get isExact => outcome == TaskResolutionOutcome.exact;
  bool get isAmbiguous => outcome == TaskResolutionOutcome.ambiguous;
  bool get isNotFound => outcome == TaskResolutionOutcome.notFound;
}

/// Pure deterministic task resolver that matches active/pending tasks from natural language queries.
class AstraTaskResolver {
  const AstraTaskResolver();

  static const Set<String> _stopwords = {
    'my',
    'the',
    'a',
    'an',
    'task',
    'item',
    'to',
    'for',
    'about',
    'reminder',
  };

  /// Resolves the intended task from [tasks] using [query].
  ///
  /// Invariants:
  /// - Considers only active/pending tasks (excludes completed/cancelled).
  /// - Applies deterministic precedence (Exact Title -> Org + Title -> Token Containment -> Positional Reference).
  /// - Returns [TaskResolutionResult.ambiguous] if multiple tasks match with identical strength.
  /// - Returns [TaskResolutionResult.notFound] if no tasks match.
  /// - NEVER arbitrarily falls back to `tasks.first`.
  TaskResolutionResult resolve({
    required List<Task> tasks,
    required String query,
  }) {
    // 1. Filter only active/pending tasks
    final activeTasks = tasks.where((t) => !t.isCompleted && t.status != 'completed' && t.status != 'cancelled').toList();

    if (activeTasks.isEmpty) {
      return TaskResolutionResult.notFound(query);
    }

    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return TaskResolutionResult.notFound(query);
    }

    // 2. Check Positional Reference (e.g. "task 1", "task 2", "item 3", "third task")
    final positionalIndex = _parsePositionalIndex(trimmed);
    if (positionalIndex != null) {
      if (positionalIndex >= 0 && positionalIndex < activeTasks.length) {
        return TaskResolutionResult.exact(activeTasks[positionalIndex]);
      } else {
        return TaskResolutionResult.notFound(query);
      }
    }

    final normalizedQuery = _normalize(trimmed);
    if (normalizedQuery.isEmpty) {
      return TaskResolutionResult.notFound(query);
    }

    // LEVEL 1: Exact normalized title match
    final level1Matches = activeTasks.where((t) {
      final normalizedTitle = _normalize(t.title);
      return normalizedTitle == normalizedQuery;
    }).toList();

    if (level1Matches.length == 1) {
      return TaskResolutionResult.exact(level1Matches.first);
    } else if (level1Matches.length > 1) {
      return TaskResolutionResult.ambiguous(level1Matches);
    }

    // LEVEL 2: Exact organization match or Org + Title composite match
    final level2Matches = activeTasks.where((t) {
      final normTitle = _normalize(t.title);
      final normOrg = t.organization != null ? _normalize(t.organization!) : '';
      if (normOrg.isEmpty) return false;

      final combined = '$normOrg $normTitle'.trim();
      return combined == normalizedQuery ||
          (normOrg == normalizedQuery) ||
          (normalizedQuery.contains(normOrg) && normalizedQuery.contains(normTitle));
    }).toList();

    if (level2Matches.length == 1) {
      return TaskResolutionResult.exact(level2Matches.first);
    } else if (level2Matches.length > 1) {
      return TaskResolutionResult.ambiguous(level2Matches);
    }

    // LEVEL 3: Token containment / Substring match
    final queryTokens = _tokenize(normalizedQuery);
    if (queryTokens.isEmpty) {
      return TaskResolutionResult.notFound(query);
    }

    // Score candidates by token match count
    final scoredCandidates = <Task, int>{};

    for (final task in activeTasks) {
      final taskTitleTokens = _tokenize(_normalize(task.title));
      final taskOrgTokens = task.organization != null ? _tokenize(_normalize(task.organization!)) : <String>{};
      final allTaskTokens = {...taskTitleTokens, ...taskOrgTokens};

      // Check how many query tokens match task tokens exactly
      int matchedQueryTokens = 0;
      for (final qToken in queryTokens) {
        if (allTaskTokens.contains(qToken)) {
          matchedQueryTokens++;
        }
      }

      int score = 0;
      // If full multi-word substring match in title or org
      final normalizedTitle = _normalize(task.title);
      final normalizedOrg = task.organization != null ? _normalize(task.organization!) : '';
      if (normalizedTitle.contains(normalizedQuery) || (normalizedOrg.isNotEmpty && normalizedOrg.contains(normalizedQuery))) {
        score += 10;
      } else if (normalizedTitle.isNotEmpty && normalizedQuery.contains(normalizedTitle)) {
        // Reverse containment: query contains title (e.g. query: "project meeting", title: "Meeting")
        score += 8;
      }

      // If all query tokens matched in task tokens
      if (matchedQueryTokens == queryTokens.length) {
        score += 5;
      } else if (taskTitleTokens.isNotEmpty && taskTitleTokens.every((t) => queryTokens.contains(t))) {
        // Task tokens are subset of query tokens
        score += 6;
      } else if (matchedQueryTokens > 0 && queryTokens.length == 1) {
        score += matchedQueryTokens * 2;
      }

      if (score > 0) {
        scoredCandidates[task] = score;
      }
    }

    if (scoredCandidates.isEmpty) {
      return TaskResolutionResult.notFound(query);
    }

    // Find highest score
    int maxScore = 0;
    for (final score in scoredCandidates.values) {
      if (score > maxScore) {
        maxScore = score;
      }
    }

    final topMatches = scoredCandidates.entries.where((e) => e.value == maxScore).map((e) => e.key).toList();

    if (topMatches.length == 1) {
      return TaskResolutionResult.exact(topMatches.first);
    } else {
      return TaskResolutionResult.ambiguous(topMatches);
    }
  }

  /// Normalizes a string by lowercasing, stripping punctuation, and removing stopwords.
  String _normalize(String input) {
    var text = input.toLowerCase();

    // Replace punctuation and special characters with spaces
    text = text.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');

    final rawTokens = text.split(RegExp(r'\s+')).map((t) => t.trim()).where((t) => t.isNotEmpty).toList();

    final filtered = rawTokens.where((t) => !_stopwords.contains(t)).toList();

    return filtered.join(' ');
  }

  Set<String> _tokenize(String normalizedText) {
    return normalizedText.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toSet();
  }

  /// Parses positional patterns like "task 1", "task 2", "item 3", "first task", "second task".
  /// Returns 0-based index or null if not a positional pattern.
  int? _parsePositionalIndex(String text) {
    final lower = text.toLowerCase().trim();

    // Digits: "task 1", "task #2", "item 3", "number 4", "#1", "1st task", "2nd"
    final digitMatch = RegExp(r'^(?:(?:task|item|number|no\.?|\#)\s*(?:\#\s*)?(\d+)(?:st|nd|rd|th)?|(?:\#\s*)?(\d+)(?:st|nd|rd|th)\s*(?:task|item)?)$').firstMatch(lower);
    if (digitMatch != null) {
      final str = digitMatch.group(1) ?? digitMatch.group(2);
      final numVal = str != null ? int.tryParse(str) : null;
      if (numVal != null && numVal > 0) {
        return numVal - 1; // 1-based to 0-based
      }
    }

    // Word ordinals: "first task", "second task", "third", "1st item"
    final ordinalMap = {
      'first': 0,
      '1st': 0,
      'second': 1,
      '2nd': 1,
      'third': 2,
      '3rd': 2,
      'fourth': 3,
      '4th': 3,
      'fifth': 4,
      '5th': 4,
      'sixth': 5,
      '6th': 5,
      'seventh': 6,
      '7th': 6,
      'eighth': 7,
      '8th': 7,
      'ninth': 8,
      '9th': 8,
      'tenth': 9,
      '10th': 9,
    };

    for (final entry in ordinalMap.entries) {
      if (lower == entry.key || lower == '${entry.key} task' || lower == '${entry.key} item') {
        return entry.value;
      }
    }

    return null;
  }
}
