/// Classification kinds for user messages entering ASTRA.
enum AstraInputKind {
  /// Direct single-turn or multi-turn commands (e.g. "remind me to call Mom at 5pm", "move exam to 7pm").
  command,

  /// General knowledge, conversational queries, or greetings (e.g. "hi", "how does photosynthesis work?").
  conversation,

  /// Single-topic announcements, notices, or notes with dates/times.
  document,

  /// Multi-event/multi-training documents, circulars, or schedules with multiple actionable entities.
  multiItemDocument,
}

/// Structured result of classifying raw user text.
class AstraInputClassification {
  final AstraInputKind kind;
  final double confidence;
  final String reason;
  final int dateRangeCount;
  final int dateCount;
  final bool hasEmailOrNoticeStructure;

  const AstraInputClassification({
    required this.kind,
    required this.confidence,
    required this.reason,
    this.dateRangeCount = 0,
    this.dateCount = 0,
    this.hasEmailOrNoticeStructure = false,
  });
}

/// 100% on-device deterministic input classifier.
///
/// Ensures long pasted emails, circulars, and multi-event schedules are NEVER
/// collapsed into a single short command or naive single task like "Form".
class AstraInputClassifier {
  const AstraInputClassifier();

  static final _dateRangeRegex = RegExp(
    r'(?:\b\d{1,2}[-/.](?:\d{1,2}|[A-Za-z]{3})[-/.]\d{2,4}|\b\d{1,2}(?:st|nd|rd|th)?\s+[A-Za-z]{3,9}(?:\s+\d{4})?)\s*(?:to|[-–—]|until|through)\s*(?:\b\d{1,2}[-/.](?:\d{1,2}|[A-Za-z]{3})[-/.]\d{2,4}|\b\d{1,2}(?:st|nd|rd|th)?\s+[A-Za-z]{3,9}(?:\s+\d{4})?)',
    caseSensitive: false,
  );

  static final _singleDateRegex = RegExp(
    r'\b\d{1,2}[-/.](?:\d{1,2}|[A-Za-z]{3})[-/.]\d{2,4}\b|\b\d{1,2}(?:st|nd|rd|th)?\s+(?:jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*(?:\s+\d{4})?\b',
    caseSensitive: false,
  );

  static final _salutationRegex = RegExp(
    r'''\b(?:dear\s+(?:students|all|team|colleagues|faculty|members|sir|ma'?am|everyone)|hello\s+(?:all|team|everyone)|hi\s+(?:all|team|everyone)|to\s+all\s+students|notice|circular|announcement|subject:|fwd:|re:)\b''',
    caseSensitive: false,
  );

  static final _signOffRegex = RegExp(
    r'\b(?:thanks\s+&?\s+regards|best\s+regards|warm\s+regards|sincerely|placement\s+cell|coordinator|head\s+of\s+department|h\.?o\.?d\.?|training\s+officer)\b',
    caseSensitive: false,
  );

  static final _multiActionRegex = RegExp(
    r'\b(?:training\s+is\s+going\s+to\s+start|respond\s+to\s+the\s+form|fill\s+(?:the\s+)?form|submit\s+(?:before|by)|register\s+(?:at|on|before)|attend\s+the\s+session|schedule\s+is\s+as\s+follows)\b',
    caseSensitive: false,
  );

  /// Classifies [text] into an [AstraInputClassification].
  AstraInputClassification classify(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return const AstraInputClassification(
        kind: AstraInputKind.conversation,
        confidence: 1.0,
        reason: 'empty_input',
      );
    }

    final lower = trimmed.toLowerCase();
    final length = trimmed.length;
    final lines = trimmed.split('\n').where((l) => l.trim().isNotEmpty).length;
    final wordCount = trimmed.split(RegExp(r'\s+')).length;

    // Detect structural features
    final dateRangeMatches = _dateRangeRegex.allMatches(trimmed).toList();
    final singleDateMatches = _singleDateRegex.allMatches(trimmed).toList();
    final hasSalutation = _salutationRegex.hasMatch(trimmed);
    final hasSignOff = _signOffRegex.hasMatch(trimmed);
    final multiActionMatches = _multiActionRegex.allMatches(trimmed).toList();

    final dateRangeCount = dateRangeMatches.length;
    final totalDates = singleDateMatches.length;
    final isFormalNotice = hasSalutation || hasSignOff;

    // 1. Multi-Item Document: Multiple date ranges OR (Notice with multiple actions/dates)
    if (dateRangeCount >= 2 ||
        (dateRangeCount >= 1 && multiActionMatches.isNotEmpty && length > 120) ||
        (isFormalNotice && totalDates >= 2 && length > 140)) {
      return AstraInputClassification(
        kind: AstraInputKind.multiItemDocument,
        confidence: 0.98,
        reason: 'multi_date_range_or_multi_action_document',
        dateRangeCount: dateRangeCount,
        dateCount: totalDates,
        hasEmailOrNoticeStructure: isFormalNotice,
      );
    }

    // 2. Single Document: Long structured announcement / notice / notes
    if (length > 180 || (isFormalNotice && length > 90) || (lines >= 4 && length > 120)) {
      return AstraInputClassification(
        kind: AstraInputKind.document,
        confidence: 0.94,
        reason: 'long_structured_document',
        dateRangeCount: dateRangeCount,
        dateCount: totalDates,
        hasEmailOrNoticeStructure: isFormalNotice,
      );
    }

    // 3. Short Command vs. Casual Conversation
    if (_isConversational(lower)) {
      return AstraInputClassification(
        kind: AstraInputKind.conversation,
        confidence: 0.92,
        reason: 'conversational_query',
        dateRangeCount: dateRangeCount,
        dateCount: totalDates,
        hasEmailOrNoticeStructure: false,
      );
    }

    final isShortCommand = _isShortActionCommand(lower);
    if (isShortCommand) {
      return AstraInputClassification(
        kind: AstraInputKind.command,
        confidence: 0.95,
        reason: 'short_action_command',
        dateRangeCount: dateRangeCount,
        dateCount: totalDates,
        hasEmailOrNoticeStructure: false,
      );
    }

    return AstraInputClassification(
      kind: length < 100 && wordCount < 18 ? AstraInputKind.command : AstraInputKind.conversation,
      confidence: 0.88,
      reason: 'standard_short_input',
      dateRangeCount: dateRangeCount,
      dateCount: totalDates,
      hasEmailOrNoticeStructure: false,
    );
  }

  bool _isConversational(String lower) {
    return lower.startsWith('what ') ||
        lower.startsWith('who ') ||
        lower.startsWith('why ') ||
        lower.startsWith('how ') ||
        lower.startsWith('explain ') ||
        lower.startsWith('tell me ') ||
        lower.startsWith('can you ') ||
        lower.startsWith('describe ') ||
        lower.startsWith('hi') ||
        lower.startsWith('hello') ||
        lower.startsWith('hey') ||
        lower.startsWith('good morning') ||
        lower.startsWith('good evening');
  }

  bool _isShortActionCommand(String lower) {
    return lower.startsWith('remind ') ||
        lower.startsWith('set ') ||
        lower.startsWith('add ') ||
        lower.startsWith('create ') ||
        lower.startsWith('move ') ||
        lower.startsWith('reschedule ') ||
        lower.startsWith('make it ') ||
        lower.startsWith('delete ') ||
        lower.startsWith('complete ') ||
        lower.startsWith('show ') ||
        lower.startsWith('list ') ||
        lower.contains('tomorrow at') ||
        lower.contains('today at') ||
        lower.contains('due ') ||
        lower.contains('exam ') ||
        lower.contains('interview ');
  }
}
