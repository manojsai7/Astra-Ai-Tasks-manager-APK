import 'astra_recurrence_engine.dart';
import 'astra_temporal_engine.dart';

/// Represents a structured command to update an existing task.
class AstraUpdateCommand {
  final String originalText;

  /// Existing task identification query (e.g. "exam", "Microsoft interview").
  final String targetQuery;

  /// Optional mutations.
  final String? newTitle;
  final DateTime? newDueAt;
  final String? newPriority;
  final String? newOrganization;
  final RecurrenceRule? newRecurrenceRule;

  /// True when the command expresses an update but lacks the information needed to safely perform it.
  final bool requiresConfirmation;

  final List<String> warnings;

  const AstraUpdateCommand({
    required this.originalText,
    required this.targetQuery,
    this.newTitle,
    this.newDueAt,
    this.newPriority,
    this.newOrganization,
    this.newRecurrenceRule,
    required this.requiresConfirmation,
    this.warnings = const [],
  });

  bool get hasChanges =>
      newTitle != null ||
      newDueAt != null ||
      newPriority != null ||
      newOrganization != null ||
      newRecurrenceRule != null;
}

/// Pure deterministic parser that extracts target task queries and requested mutations from user text.
class AstraUpdateParser {
  const AstraUpdateParser();

  static const _temporalEngine = AstraTemporalEngine();

  /// Parses [text] into an [AstraUpdateCommand].
  ///
  /// Invariants:
  /// - Pure and deterministic.
  /// - No database access or side effects.
  /// - Sets `requiresConfirmation = true` if target is missing, new time is ambiguous, or no mutations are specified.
  AstraUpdateCommand parse({
    required String text,
    required DateTime now,
  }) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return AstraUpdateCommand(
        originalText: text,
        targetQuery: '',
        requiresConfirmation: true,
        warnings: const ['Which task would you like to update?'],
      );
    }

    final warnings = <String>[];
    String targetQuery = '';
    String? newTitle;
    DateTime? newDueAt;
    String? newPriority;
    String? newOrganization;
    RecurrenceRule? newRecurrenceRule;
    bool explicitConfirmationRequired = false;

    // 1. Check for Rename / Title modification:
    // e.g. "rename my exam to physics exam", "change name of interview to Final Round Interview"
    final renameMatch = RegExp(
      r'^(?:rename|change\s+(?:the\s+)?(?:title|name)\s+(?:of\s+)?)(?:my\s+)?(?:the\s+)?(.+?)\s+(?:to|as)\s+(.+)$',
      caseSensitive: false,
    ).firstMatch(trimmed);

    if (renameMatch != null) {
      targetQuery = _cleanTarget(renameMatch.group(1)!);
      newTitle = _cleanTitle(renameMatch.group(2)!);
    }

    // 2. Check for Priority modification:
    // e.g. "make the interview high priority", "set my exam to urgent priority", "change priority of task to low"
    if (newTitle == null) {
      final priorityMatch = RegExp(
        r'^(?:make|set|change|mark)\s+(?:the\s+)?(?:my\s+)?(?:priority\s+of\s+)?(.+?)\s+(?:to\s+|as\s+|to\s+be\s+)?(low|medium|high|critical|urgent)(?:\s+priority)?$',
        caseSensitive: false,
      ).firstMatch(trimmed);

      if (priorityMatch != null) {
        targetQuery = _cleanTarget(priorityMatch.group(1)!);
        newPriority = _normalizePriority(priorityMatch.group(2)!);
      } else {
        // Also check "make the interview high priority" where "priority" is at the end
        final trailingPriorityMatch = RegExp(
          r'^(?:make|set)\s+(?:the\s+)?(?:my\s+)?(.+?)\s+(low|medium|high|critical|urgent)\s+priority$',
          caseSensitive: false,
        ).firstMatch(trimmed);

        if (trailingPriorityMatch != null) {
          targetQuery = _cleanTarget(trailingPriorityMatch.group(1)!);
          newPriority = _normalizePriority(trailingPriorityMatch.group(2)!);
        }
      }
    }

    // 3. Check for Organization modification:
    // e.g. "change my interview organization to Microsoft", "set organization of interview to Google"
    if (newTitle == null && newPriority == null) {
      final orgMatch = RegExp(
        r'^(?:change|set)\s+(?:the\s+)?(?:my\s+)?(?:organization|org|company)\s+(?:of\s+)?(?:my\s+)?(.+?)\s+(?:to\s+|as\s+)(.+)$',
        caseSensitive: false,
      ).firstMatch(trimmed);

      if (orgMatch != null) {
        targetQuery = _cleanTarget(orgMatch.group(1)!);
        newOrganization = orgMatch.group(2)!.trim();
      }
    }

    // 4. Check for Reschedule / Move / Deadline changes:
    // e.g. "move my exam to tomorrow at 7pm", "reschedule my Microsoft interview to 2pm", "make it 11", "make it 2pm"
    if (newTitle == null && newPriority == null && newOrganization == null) {
      final moveMatch = RegExp(
        r'^(?:actually\s+|please\s+|can\s+you\s+)?(?:move|reschedule|postpone|delay|shift|change|set)\s+(?:the\s+)?(?:my\s+)?(?:deadline\s+(?:of\s+|for\s+)?)?(.+?)(?:\s+deadline)?\s+(?:to|for|at|on|by|before|around)\s+(\d{1,2}(?::\d{2})?\s*(?:am|pm)?|\d{1,2}|.+)$',
        caseSensitive: false,
      ).firstMatch(trimmed) ?? RegExp(
        r'^(?:actually\s+|please\s+|can\s+you\s+)?(?:make|set|change|shift|move)\s+(it|that|this)\s+(?:to\s+|at\s+)?(\d{1,2}(?::\d{2})?\s*(?:am|pm)?|\d{1,2}|.+)$',
        caseSensitive: false,
      ).firstMatch(trimmed);

      if (moveMatch != null) {
        var rawTarget = moveMatch.group(1)!.trim();
        var temporalPortion = moveMatch.group(2)!.trim();

        // Check if rawTarget starts with a date qualifier (e.g. "my tomorrow exam", "today interview")
        final leadingDateMatch = RegExp(
          r'^(?:my\s+|the\s+)?(today|tomorrow|tmrw|monday|tuesday|wednesday|thursday|friday|saturday|sunday)\s+(.+)$',
          caseSensitive: false,
        ).firstMatch(rawTarget);

        if (leadingDateMatch != null) {
          final dateWord = leadingDateMatch.group(1)!;
          rawTarget = leadingDateMatch.group(2)!;
          // If temporalPortion does not already have a date word, attach this date word to it
          final temporalHasDate = RegExp(
            r'\b(?:today|tomorrow|tmrw|monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b',
            caseSensitive: false,
          ).hasMatch(temporalPortion);

          if (!temporalHasDate) {
            temporalPortion = '$dateWord $temporalPortion';
          }
        }

        targetQuery = _cleanTarget(rawTarget);

        // Check if temporalPortion has bare ambiguous numbers like "tomorrow by 5" or "by 5" without am/pm
        final bareAmbiguousMatch = RegExp(r'\b(?:at|by|before|around)\s+(\d{1,2})\b', caseSensitive: false).firstMatch(temporalPortion);
        final hasAmPm = RegExp(r'\b(?:am|pm)\b', caseSensitive: false).hasMatch(temporalPortion);
        if (bareAmbiguousMatch != null && !hasAmPm) {
          explicitConfirmationRequired = true;
          warnings.add('Time "${bareAmbiguousMatch.group(0)}" is ambiguous (specify am/pm).');
        } else {
          // Normalize bare hour numbers like "11" or "10" -> "11:00" / "11am"
          var effectiveTemporal = temporalPortion;
          if (RegExp(r'^\d{1,2}$').hasMatch(effectiveTemporal)) {
            final hr = int.parse(effectiveTemporal);
            if (hr >= 1 && hr <= 12) {
              // Default to AM/PM based on typical daytime context (9-11 AM, 1-8 PM) or AM if >= 8
              final suffix = (hr >= 8 && hr <= 11) ? 'am' : 'pm';
              effectiveTemporal = '$hr$suffix';
            }
          }

          // Parse temporal portion with AstraTemporalEngine
          final isContextualPronoun = targetQuery == 'it' || targetQuery == 'that' || targetQuery == 'this' || targetQuery.isEmpty;
          final containsDateWord = RegExp(r'\b(?:today|tomorrow|tmrw|monday|tuesday|wednesday|thursday|friday|saturday|sunday|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\b', caseSensitive: false).hasMatch(effectiveTemporal);
          final parseInput = containsDateWord ? effectiveTemporal : 'today at $effectiveTemporal';
          // Check if effectiveTemporal has an explicit time (e.g. "7pm", "7 pm", "10:30am", "6 20pm", "14:00", "18 20")
          final hasExplicitTime = RegExp(r'\b(?:\d{1,2}(?:\s*:\s*|\s+)\d{2}\s*(?:am|pm)?|\d{1,2}\s*(?:am|pm))\b', caseSensitive: false).hasMatch(effectiveTemporal);
          final isPureRelativeDay = RegExp(r'^(?:today|tomorrow|tmrw)$', caseSensitive: false).hasMatch(effectiveTemporal.trim());

          if (isPureRelativeDay && !hasExplicitTime) {
            explicitConfirmationRequired = true;
            warnings.add('Please specify a time for the rescheduled task (e.g. 7pm).');
          } else {
            final temporalResult = _temporalEngine.parse(parseInput, now: now);

            if (temporalResult.ambiguous && (!isContextualPronoun || containsDateWord)) {
              explicitConfirmationRequired = true;
              warnings.addAll(temporalResult.warnings.isNotEmpty
                  ? temporalResult.warnings
                  : ['The new date or time is ambiguous.']);
            } else {
              newDueAt = temporalResult.eventStart ?? temporalResult.deadline;
              if (newDueAt == null) {
                if (temporalResult.ambiguous) {
                  explicitConfirmationRequired = true;
                  warnings.addAll(temporalResult.warnings);
                } else {
                  explicitConfirmationRequired = true;
                  warnings.add('Could not determine new time from "$temporalPortion".');
                }
              }
            }
          }
        }
      } else {
        // Incomplete / Bare update without time:
        // e.g. "move my exam", "reschedule the interview", "change my assignment", "move my exam"
        final bareMatch = RegExp(
          r'^(?:move|reschedule|postpone|delay|shift|change|update)\s+(?:the\s+)?(?:my\s+)?(.+)$',
          caseSensitive: false,
        ).firstMatch(trimmed);

        if (bareMatch != null) {
          targetQuery = _cleanTarget(bareMatch.group(1)!);
          explicitConfirmationRequired = true;
          warnings.add('New date/time or change is required.');
        }
      }
    }

    // Strip trailing prepositions from targetQuery (e.g. "my exam to" -> "my exam")
    targetQuery = targetQuery.replaceAll(RegExp(r'\s+(?:to|at|on|for)$', caseSensitive: false), '').trim();

    // 5. Final Target Validation
    if (targetQuery.isEmpty || targetQuery == 'task' || targetQuery == 'item') {
      targetQuery = '';
      explicitConfirmationRequired = true;
      if (!warnings.contains('Which task would you like to update?')) {
        warnings.add('Which task would you like to update?');
      }
    }

    final hasAnyChange = newTitle != null ||
        newDueAt != null ||
        newPriority != null ||
        newOrganization != null;

    final requiresConfirmation = explicitConfirmationRequired || !hasAnyChange;

    return AstraUpdateCommand(
      originalText: text,
      targetQuery: targetQuery,
      newTitle: newTitle,
      newDueAt: newDueAt,
      newPriority: newPriority,
      newOrganization: newOrganization,
      newRecurrenceRule: newRecurrenceRule,
      requiresConfirmation: requiresConfirmation,
      warnings: warnings,
    );
  }

  /// Cleans target query string by stripping leading stopwords and unwanted tokens.
  String _cleanTarget(String raw) {
    var s = raw.trim();

    // Strip leading "my", "the", "a", "an"
    s = s.replaceAll(RegExp(r'^(?:my|the|a|an)\s+', caseSensitive: false), '');

    // Strip trailing "task", "deadline", "reminder" if preceded by something meaningful
    final words = s.split(RegExp(r'\s+'));
    if (words.length > 1) {
      if (words.last.toLowerCase() == 'task' ||
          words.last.toLowerCase() == 'deadline' ||
          words.last.toLowerCase() == 'reminder') {
        words.removeLast();
        s = words.join(' ');
      }
    }

    return s.trim();
  }

  /// Cleans title string and capitalizes words cleanly.
  String _cleanTitle(String raw) {
    var s = raw.trim();
    // Strip surrounding quotes if present
    if ((s.startsWith('"') && s.endsWith('"')) || (s.startsWith("'") && s.endsWith("'"))) {
      s = s.substring(1, s.length - 1).trim();
    }

    if (s.isEmpty) return '';

    // Title case each word
    final words = s.split(RegExp(r'\s+'));
    final capitalized = words.map((w) {
      if (w.isEmpty) return w;
      return '${w[0].toUpperCase()}${w.substring(1)}';
    }).join(' ');

    return capitalized;
  }

  /// Normalizes priority to application's standard set.
  String? _normalizePriority(String raw) {
    final lower = raw.toLowerCase().trim();
    switch (lower) {
      case 'low':
        return 'low';
      case 'medium':
      case 'normal':
        return 'medium';
      case 'high':
        return 'high';
      case 'critical':
      case 'urgent':
        return 'urgent';
      default:
        return null;
    }
  }
}
