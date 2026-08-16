import 'package:intl/intl.dart';

import 'astra_temporal_engine.dart';

/// Represents a single actionable event, training, deadline, or form extracted from a document.
class AstraDocumentItem {
  final String id;
  final String type; // 'training', 'exam', 'meeting', 'form', 'deadline', 'event'
  final String title;
  final String description;
  final String? organization;
  final DateTime? startAt;
  final DateTime? endAt;
  final DateTime? dueAt;
  final int? durationDays;
  final bool actionRequired;
  final double confidence;
  final List<String> reasons;

  const AstraDocumentItem({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    this.organization,
    this.startAt,
    this.endAt,
    this.dueAt,
    this.durationDays,
    this.actionRequired = false,
    this.confidence = 0.90,
    this.reasons = const [],
  });

  bool get isDuration => startAt != null && endAt != null;
  bool get isDeadline => dueAt != null && startAt == null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        'description': description,
        'organization': organization,
        'startAt': startAt?.toIso8601String(),
        'endAt': endAt?.toIso8601String(),
        'dueAt': dueAt?.toIso8601String(),
        'durationDays': durationDays,
        'actionRequired': actionRequired,
        'confidence': confidence,
        'reasons': reasons,
      };
}

/// Comprehensive analysis of an arbitrary long-form document, notice, or email.
class AstraDocumentAnalysis {
  final String title;
  final String summary;
  final String overallImportance; // 'low', 'medium', 'high', 'critical'
  final String sourceType; // 'document', 'email', 'circular'
  final List<AstraDocumentItem> extractedItems;
  final List<String> warnings;
  final String rawText;

  const AstraDocumentAnalysis({
    required this.title,
    required this.summary,
    this.overallImportance = 'medium',
    this.sourceType = 'document',
    required this.extractedItems,
    this.warnings = const [],
    required this.rawText,
  });

  bool get hasActionRequired => extractedItems.any((i) => i.actionRequired);
}

/// 100% on-device deterministic document analyzer.
///
/// Parses complex multi-track trainings, date ranges, deadlines, and form actions
/// with zero external network or LLM calls.
class AstraDocumentAnalyzer {
  final AstraTemporalEngine temporalEngine;

  const AstraDocumentAnalyzer({
    this.temporalEngine = const AstraTemporalEngine(),
  });

  /// Analyzes raw [text] and extracts all distinct facts and candidates.
  AstraDocumentAnalysis analyze(String text, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final trimmed = text.trim();
    final lower = trimmed.toLowerCase();

    final items = <AstraDocumentItem>[];
    final warnings = <String>[];

    // 1. Extract Organization / Batch
    final organization = _extractOrganization(trimmed);

    // 2. Extract Multi-Track Training / Date-Range Events
    final trainingItems = _extractTrainingRanges(trimmed, organization: organization, now: reference);
    items.addAll(trainingItems);

    // 3. Extract Form Submission / Immediate Action Deadlines
    final actionItems = _extractActionAndFormDeadlines(trimmed, organization: organization, now: reference);
    items.addAll(actionItems);

    // 4. Extract Generic Date Ranges / Meetings if not already covered
    if (items.isEmpty) {
      final genericItems = _extractGenericEvents(trimmed, organization: organization, now: reference);
      items.addAll(genericItems);
    }

    // 5. Build Document Title & Summary
    final docTitle = _generateDocumentTitle(trimmed, organization, items);
    final summary = _generateSummary(trimmed, items, organization);
    final importance = _determineOverallImportance(items, lower);

    return AstraDocumentAnalysis(
      title: docTitle,
      summary: summary,
      overallImportance: importance,
      sourceType: _detectSourceType(lower),
      extractedItems: items,
      warnings: warnings,
      rawText: text,
    );
  }

  // ─── Extraction Helpers ───────────────────────────────────────────────────

  List<AstraDocumentItem> _extractTrainingRanges(
    String text, {
    String? organization,
    required DateTime now,
  }) {
    final items = <AstraDocumentItem>[];

    // Match patterns like:
    // "17-08-2026 to 22-08-2026(6 Days) for Apptitude"
    // "17-08-2026 to 25-08-2026(8 days) for Fullstack"
    // "17-08-2026 to 22-08-2026 for Aptitude"
    final rangeRegex = RegExp(
      r'(\d{1,2}[-/.](?:\d{1,2}|[A-Za-z]{3})[-/.]\d{2,4})\s*(?:to|[-–—]|until)\s*(\d{1,2}[-/.](?:\d{1,2}|[A-Za-z]{3})[-/.]\d{2,4})(?:\s*\(\s*(\d+)\s*days?\s*\))?\s*(?:for|:|-)?\s*([A-Za-z0-9\s/]+?)(?=(?:\s+and\s+\d{1,2}|\s*\.|\s*,|\s*\n|\s+we\s+have|\s+therefore|$))',
      caseSensitive: false,
    );

    int trackIdx = 1;
    for (final match in rangeRegex.allMatches(text)) {
      final rawStart = match.group(1)!;
      final rawEnd = match.group(2)!;
      final rawDays = match.group(3);
      var trackName = (match.group(4) ?? '').trim();

      // Clean track name
      trackName = trackName.replaceAll(RegExp(r'\s+and$', caseSensitive: false), '').trim();
      if (trackName.isEmpty) trackName = 'Track $trackIdx';

      // Fix common typos like "Apptitude" -> "Aptitude"
      if (trackName.toLowerCase().contains('apptitude')) {
        trackName = trackName.replaceAll(RegExp(r'apptitude', caseSensitive: false), 'Aptitude');
      }

      final startParsed = _parseFormattedDate(rawStart, defaultHour: 9);
      final endParsed = _parseFormattedDate(rawEnd, defaultHour: 17);

      final days = rawDays != null ? int.tryParse(rawDays) : (startParsed != null && endParsed != null ? endParsed.difference(startParsed).inDays + 1 : null);

      final orgPrefix = organization != null ? '$organization ' : '';
      final title = '$orgPrefix$trackName Training'.replaceAll(RegExp(r'\s+'), ' ').trim();
      final dateStr = startParsed != null && endParsed != null
          ? '${DateFormat("d MMM").format(startParsed)} – ${DateFormat("d MMM yyyy").format(endParsed)}'
          : '$rawStart to $rawEnd';

      items.add(
        AstraDocumentItem(
          id: 'doc_item_track_$trackIdx',
          type: 'training',
          title: _toTitleCase(title),
          description: '$trackName Training ($dateStr${days != null ? ' · $days Days' : ''})',
          organization: organization,
          startAt: startParsed,
          endAt: endParsed,
          dueAt: null,
          durationDays: days,
          actionRequired: false,
          confidence: 0.96,
          reasons: ['Extracted multi-day training range for $trackName ($dateStr)'],
        ),
      );
      trackIdx++;
    }

    if (items.isEmpty && text.toLowerCase().contains('training')) {
      final rangeRegex2 = RegExp(
        r'(?:([A-Za-z0-9\s/]+?)\s+)?(?:training\s+)?(?:is\s+going\s+to\s+start\s+)?(?:starts?\s+)?(?:from\s+)?(\d{1,2}[-/.](?:\d{1,2}|[A-Za-z]{3})[-/.]\d{2,4})\s*(?:to|[-–—]|until)\s*(\d{1,2}[-/.](?:\d{1,2}|[A-Za-z]{3})[-/.]\d{2,4})(?:\s*\(\s*(\d+)\s*days?\s*\))?',
        caseSensitive: false,
      );

      for (final match in rangeRegex2.allMatches(text)) {
        var trackName = (match.group(1) ?? '').trim();
        final rawStart = match.group(2)!;
        final rawEnd = match.group(3)!;
        final rawDays = match.group(4);

        if (trackName.toLowerCase().contains('apptitude')) {
          trackName = trackName.replaceAll(RegExp(r'apptitude', caseSensitive: false), 'Aptitude');
        }

        final startParsed = _parseFormattedDate(rawStart, defaultHour: 9);
        final endParsed = _parseFormattedDate(rawEnd, defaultHour: 17);
        final days = rawDays != null ? int.tryParse(rawDays) : (startParsed != null && endParsed != null ? endParsed.difference(startParsed).inDays + 1 : null);

        final title = trackName.isNotEmpty
            ? '${organization != null ? "$organization " : ""}$trackName Training'.replaceAll(RegExp(r'\s+'), ' ').trim()
            : '${organization != null ? "$organization " : ""}Training';

        final dateStr = startParsed != null && endParsed != null
            ? '${DateFormat("d MMM").format(startParsed)} – ${DateFormat("d MMM yyyy").format(endParsed)}'
            : '$rawStart to $rawEnd';

        items.add(
          AstraDocumentItem(
            id: 'doc_item_track_$trackIdx',
            type: 'training',
            title: _toTitleCase(title),
            description: '${trackName.isNotEmpty ? trackName : "Scheduled"} Training ($dateStr${days != null ? ' · $days Days' : ''})',
            organization: organization,
            startAt: startParsed,
            endAt: endParsed,
            dueAt: null,
            durationDays: days,
            actionRequired: false,
            confidence: 0.96,
            reasons: ['Extracted multi-day training range ($dateStr)'],
          ),
        );
        trackIdx++;
      }
    }

    return items;
  }

  List<AstraDocumentItem> _extractActionAndFormDeadlines(
    String text, {
    String? organization,
    required DateTime now,
  }) {
    final items = <AstraDocumentItem>[];
    final lower = text.toLowerCase();

    // Check for form response requirement:
    // "respond to the form immediately, before today evening"
    // "fill the form before 5pm"
    // "submit the application by Friday"
    final formMatch = RegExp(
      r'(?:respond\s+to\s+(?:the\s+)?form|fill\s+(?:the\s+)?form|submit\s+(?:the\s+)?form|register\s+(?:through|via|on|in)\s+(?:the\s+)?form)(?:[^\n.]+?)(?:before|by|until)\s+([^\n.,;]+)',
      caseSensitive: false,
    ).firstMatch(text);

    if (formMatch != null) {
      final deadlinePortion = formMatch.group(1)!.trim();
      final parsedDeadline = _parseDeadlineText(deadlinePortion, now: now);

      final orgPrefix = organization != null ? '$organization ' : '';
      final title = 'Respond to ${orgPrefix}Training Form'.replaceAll(RegExp(r'\s+'), ' ').trim();

      items.add(
        AstraDocumentItem(
          id: 'doc_item_action_form',
          type: 'form',
          title: _toTitleCase(title),
          description: 'Submit response to the shared form (${deadlinePortion.isNotEmpty ? deadlinePortion : "Action required"}).',
          organization: organization,
          startAt: null,
          endAt: null,
          dueAt: parsedDeadline,
          durationDays: null,
          actionRequired: true,
          confidence: 0.95,
          reasons: ['Form submission action requirement identified: "$deadlinePortion"'],
        ),
      );
    } else if (lower.contains('form') && (lower.contains('immediately') || lower.contains('respond') || lower.contains('fill') || lower.contains('submit'))) {
      // Form mentioned with urgency but without explicit "before" clause
      DateTime? evening;
      if (lower.contains('today evening') || lower.contains('this evening')) {
        evening = DateTime(now.year, now.month, now.day, 18, 0);
      }

      final orgPrefix = organization != null ? '$organization ' : '';
      items.add(
        AstraDocumentItem(
          id: 'doc_item_action_form',
          type: 'form',
          title: _toTitleCase('Respond to ${orgPrefix}Training Form'.trim()),
          description: 'Respond to the training form immediately${evening != null ? " (before today evening)" : ""}.',
          organization: organization,
          startAt: null,
          endAt: null,
          dueAt: evening,
          durationDays: null,
          actionRequired: true,
          confidence: 0.92,
          reasons: ['Urgent form response requested in notice'],
        ),
      );
    }

    return items;
  }

  List<AstraDocumentItem> _extractGenericEvents(
    String text, {
    String? organization,
    required DateTime now,
  }) {
    final items = <AstraDocumentItem>[];
    final temporalResult = temporalEngine.parse(text, now: now);

    if (temporalResult.eventStart != null || temporalResult.deadline != null) {
      final isMeeting = RegExp(r'\b(?:meeting|sync|discussion|call|session)\b', caseSensitive: false).hasMatch(text);
      final isExam = RegExp(r'\b(?:exam|test|assessment|quiz|interview)\b', caseSensitive: false).hasMatch(text);
      final type = isExam ? 'exam' : (isMeeting ? 'meeting' : 'event');

      items.add(
        AstraDocumentItem(
          id: 'doc_item_event_1',
          type: type,
          title: _extractGenericTitle(text, organization, type),
          description: text.length > 80 ? '${text.substring(0, 80)}...' : text,
          organization: organization,
          startAt: temporalResult.eventStart,
          endAt: temporalResult.eventEnd,
          dueAt: temporalResult.deadline,
          actionRequired: isExam || type == 'exam',
          confidence: 0.88,
          reasons: ['Single event date parsed with temporal engine'],
        ),
      );
    }

    return items;
  }

  // ─── Parsing Utilities ────────────────────────────────────────────────────

  DateTime? _parseFormattedDate(String dateStr, {int defaultHour = 9}) {
    final cleaned = dateStr.trim();
    // 1. Try DD-MM-YYYY or DD/MM/YYYY
    final dmyMatch = RegExp(r'^(\d{1,2})[-/.](\d{1,2})[-/.](\d{2,4})$').firstMatch(cleaned);
    if (dmyMatch != null) {
      final day = int.parse(dmyMatch.group(1)!);
      final month = int.parse(dmyMatch.group(2)!);
      var year = int.parse(dmyMatch.group(3)!);
      if (year < 100) year += 2000;
      return DateTime(year, month, day, defaultHour, 0);
    }

    // 2. Try "17 Aug 2026" or "17 August"
    final namedMonthMatch = RegExp(r'^(\d{1,2})(?:st|nd|rd|th)?\s+([A-Za-z]{3,9})(?:\s+(\d{4}))?$').firstMatch(cleaned);
    if (namedMonthMatch != null) {
      final day = int.parse(namedMonthMatch.group(1)!);
      final monthName = namedMonthMatch.group(2)!.toLowerCase();
      final yearStr = namedMonthMatch.group(3);
      final year = yearStr != null ? int.parse(yearStr) : DateTime.now().year;

      const months = {
        'jan': 1, 'january': 1,
        'feb': 2, 'february': 2,
        'mar': 3, 'march': 3,
        'apr': 4, 'april': 4,
        'may': 5,
        'jun': 6, 'june': 6,
        'jul': 7, 'july': 7,
        'aug': 8, 'august': 8,
        'sep': 9, 'september': 9,
        'oct': 10, 'october': 10,
        'nov': 11, 'november': 11,
        'dec': 12, 'december': 12,
      };

      final m = months[monthName] ?? months[monthName.substring(0, 3)] ?? 1;
      return DateTime(year, m, day, defaultHour, 0);
    }

    return null;
  }

  DateTime? _parseDeadlineText(String text, {required DateTime now}) {
    final lower = text.toLowerCase().trim();
    if (lower.contains('today evening') || lower.contains('this evening') || lower.contains('evening')) {
      return DateTime(now.year, now.month, now.day, 18, 0);
    }
    if (lower.contains('tomorrow evening')) {
      final tmrw = now.add(const Duration(days: 1));
      return DateTime(tmrw.year, tmrw.month, tmrw.day, 18, 0);
    }
    if (lower.contains('tomorrow')) {
      final tmrw = now.add(const Duration(days: 1));
      return DateTime(tmrw.year, tmrw.month, tmrw.day, 17, 0);
    }
    if (lower.contains('tonight')) {
      return DateTime(now.year, now.month, now.day, 21, 0);
    }

    final parsed = temporalEngine.parse(text, now: now);
    return parsed.deadline ?? parsed.eventStart;
  }

  String? _extractOrganization(String text) {
    final patterns = [
      RegExp(r'\b(GB\s*2027(?:\s*Batch)?)\b', caseSensitive: false),
      RegExp(r'\b(SBT(?:\s*Training)?)\b', caseSensitive: false),
      RegExp(r'\b(Microsoft|Google|Amazon|TCS|Infosys|Wipro|Cognizant|Capgemini|Accenture)\b', caseSensitive: false),
      RegExp(r'\b(Placement\s+Cell|Training\s+and\s+Placement|Dept\s+of\s+[A-Za-z]+)\b', caseSensitive: false),
    ];

    for (final pat in patterns) {
      final match = pat.firstMatch(text);
      if (match != null) {
        return match.group(1)!.trim();
      }
    }
    return null;
  }

  String _generateDocumentTitle(String text, String? org, List<AstraDocumentItem> items) {
    if (text.toLowerCase().contains('sbt training') || text.toLowerCase().contains('sbt')) {
      return '${org != null ? "$org: " : ""}SBT Training Schedule & Notice';
    }
    if (items.isNotEmpty) {
      return '${org != null ? "$org: " : ""}${items.first.title} & Updates';
    }
    return org != null ? '$org Announcement' : 'Document Notice';
  }

  String _generateSummary(String text, List<AstraDocumentItem> items, String? org) {
    if (items.length >= 2) {
      final names = items.map((i) => i.title).join(', ');
      return 'Identified ${items.length} actionable items ($names).';
    } else if (items.length == 1) {
      return 'Identified 1 action item: ${items.first.title}.';
    }
    return text.length > 100 ? '${text.substring(0, 100)}...' : text;
  }

  String _determineOverallImportance(List<AstraDocumentItem> items, String lower) {
    if (items.any((i) => i.actionRequired) || lower.contains('immediately') || lower.contains('mandatory') || lower.contains('urgent')) {
      return 'high';
    }
    if (items.isNotEmpty) {
      return 'medium';
    }
    return 'low';
  }

  String _detectSourceType(String lower) {
    if (lower.contains('subject:') || lower.contains('dear students') || lower.contains('regards,')) {
      return 'email';
    }
    if (lower.contains('circular') || lower.contains('notice')) {
      return 'circular';
    }
    return 'document';
  }

  String _extractGenericTitle(String text, String? org, String type) {
    final firstLine = text.split('\n').first.trim();
    if (firstLine.length > 5 && firstLine.length < 40) {
      return firstLine;
    }
    return '${org != null ? "$org " : ""}${_toTitleCase(type)}';
  }

  String _toTitleCase(String text) {
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return '${word[0].toUpperCase()}${word.substring(1)}';
    }).join(' ');
  }
}
