import 'package:intl/intl.dart';

import '../assistant/astra_temporal_engine.dart';
import '../../features/scheduler/data/services/gmail_sync_service.dart';

/// Categories for classified emails.
enum EmailCategory {
  important,
  deadline,
  actionRequired,
  informational,
  lowPriority,
}

/// Importance levels for emails.
enum EmailImportance {
  low,
  medium,
  high,
  critical,
}

/// Structured result of analyzing an email locally.
class AstraEmailAnalysis {
  final EmailCategory category;
  final EmailImportance importance;
  final String? actionRequired;
  final DateTime? deadline;
  final DateTime? eventDateTime;
  final String? organization;
  final String suggestedTaskTitle;
  final double confidence;
  final List<String> reasons;
  final bool isActionable;
  final bool isEvent;
  final bool requiresConfirmation;
  final List<String> warnings;

  const AstraEmailAnalysis({
    required this.category,
    required this.importance,
    this.actionRequired,
    this.deadline,
    this.eventDateTime,
    this.organization,
    required this.suggestedTaskTitle,
    this.confidence = 0.90,
    this.reasons = const [],
    this.isActionable = false,
    this.isEvent = false,
    this.requiresConfirmation = false,
    this.warnings = const [],
  });

  DateTime? get actionDateTime => deadline ?? eventDateTime;
}

/// 100% on-device deterministic email intelligence analyzer.
///
/// Uses rule-based NLP, pattern matching, and [AstraTemporalEngine] to extract
/// actionable tasks, deadlines, and events from emails without sending content
/// to Gemini or remote backends.
class AstraEmailAnalyzer {
  final AstraTemporalEngine temporalEngine;

  const AstraEmailAnalyzer({
    this.temporalEngine = const AstraTemporalEngine(),
  });

  /// Analyzes a [GmailMessageData] object and returns structured [AstraEmailAnalysis].
  AstraEmailAnalysis analyze(GmailMessageData email, {DateTime? referenceTime}) {
    final baseTime = referenceTime ?? email.receivedAt;
    final subject = email.subject.trim();
    final body = email.bodyText.trim();
    final sender = email.sender.trim();
    final fullText = '$subject\n$body';
    final fullLower = '$subject $body $sender'.toLowerCase();

    final reasons = <String>[];
    final warnings = <String>[];

    // ── 1. Organization Extraction ──────────────────────────────────────────
    final org = _extractOrganization(email);

    // ── 2. Low-Priority / Noise Check ───────────────────────────────────────
    if (_isLowPriorityNewsletterOrDigest(fullLower, sender)) {
      reasons.add('Classified as newsletter or informational digest.');
      return AstraEmailAnalysis(
        category: EmailCategory.lowPriority,
        importance: EmailImportance.low,
        suggestedTaskTitle: subject.isNotEmpty ? subject : 'Newsletter',
        confidence: 0.95,
        reasons: reasons,
        isActionable: false,
      );
    }

    // ── 3. Action and Event Type Detection ───────────────────────────────────
    final isExam = _matchesPattern(fullLower, _examPatterns);
    final isInterview = _matchesPattern(fullLower, _interviewPatterns);
    final isAssignment = _matchesPattern(fullLower, _assignmentPatterns);
    final isApplication = _matchesPattern(fullLower, _applicationPatterns);
    final isPayment = _matchesPattern(fullLower, _paymentPatterns);
    final isMeeting = _matchesPattern(fullLower, _meetingPatterns);

    String? action;
    if (isExam) {
      action = 'exam';
      reasons.add('Exam or academic assessment detected.');
    } else if (isInterview) {
      action = 'interview';
      reasons.add('Interview or hiring round detected.');
    } else if (isAssignment) {
      action = 'submit';
      reasons.add('Assignment or project submission detected.');
    } else if (isApplication) {
      action = 'apply';
      reasons.add('Application or registration deadline detected.');
    } else if (isPayment) {
      action = 'pay';
      reasons.add('Fee payment or invoice deadline detected.');
    } else if (isMeeting) {
      action = 'attend';
      reasons.add('Meeting or session invitation detected.');
    } else {
      action = _detectGenericAction(fullLower);
      if (action != null) {
        reasons.add('Action phrase "$action" detected.');
      }
    }

    // ── 4. Temporal & Deadline Extraction ────────────────────────────────────
    final temporalResult = _extractTemporalDetails(fullText, baseTime);
    final deadline = temporalResult.deadline;
    final eventStart = temporalResult.eventStart;
    final hasAmbiguousDate = temporalResult.isAmbiguous;

    if (deadline != null) {
      reasons.add('Deadline detected: ${DateFormat('EEE, MMM d · h:mm a').format(deadline)}.');
    } else if (eventStart != null) {
      reasons.add('Event time detected: ${DateFormat('EEE, MMM d · h:mm a').format(eventStart)}.');
    } else if (hasAmbiguousDate) {
      warnings.add('Temporal reference found but exact date/time could not be resolved with certainty.');
    }

    // ── 5. Category & Importance Assignment ──────────────────────────────────
    EmailCategory category;
    EmailImportance importance;

    if (isExam) {
      category = EmailCategory.important;
      importance = EmailImportance.high;
    } else if (isInterview) {
      category = EmailCategory.important;
      importance = EmailImportance.high;
    } else if (deadline != null || isAssignment || isApplication || isPayment) {
      category = EmailCategory.deadline;
      importance = (fullLower.contains('urgent') || fullLower.contains('critical') || fullLower.contains('final date'))
          ? EmailImportance.critical
          : EmailImportance.high;
    } else if (action != null) {
      category = EmailCategory.actionRequired;
      importance = EmailImportance.medium;
    } else {
      category = EmailCategory.informational;
      importance = EmailImportance.low;
      reasons.add('Informational message with no required immediate action.');
    }

    final isActionable = category != EmailCategory.informational && category != EmailCategory.lowPriority;
    final isEvent = isInterview || isExam || isMeeting || (eventStart != null && deadline == null);

    // ── 6. Suggested Task Title Generation ───────────────────────────────────
    final taskTitle = _generateTaskTitle(
      subject: subject,
      action: action,
      org: org,
      isExam: isExam,
      isInterview: isInterview,
      isAssignment: isAssignment,
      isApplication: isApplication,
      isPayment: isPayment,
    );

    return AstraEmailAnalysis(
      category: category,
      importance: importance,
      actionRequired: action,
      deadline: deadline,
      eventDateTime: eventStart,
      organization: org,
      suggestedTaskTitle: taskTitle,
      confidence: isActionable ? 0.92 : 0.85,
      reasons: reasons,
      isActionable: isActionable,
      isEvent: isEvent,
      requiresConfirmation: hasAmbiguousDate || (isActionable && deadline == null && eventStart == null),
      warnings: warnings,
    );
  }

  // ─── Extraction Helpers ───────────────────────────────────────────────────

  String? _extractOrganization(GmailMessageData email) {
    final senderLower = email.sender.toLowerCase();
    final senderName = email.senderName.trim();
    final subject = email.subject;

    // 1. Check known brand keywords
    for (final brand in _knownBrands) {
      if (senderLower.contains(brand.toLowerCase()) || subject.toLowerCase().contains(brand.toLowerCase())) {
        return brand;
      }
    }

    // 2. Extract company from display name if standard
    if (senderName.isNotEmpty && senderName != 'Unknown' && !senderName.contains('@')) {
      final nameClean = senderName
          .replaceAll(RegExp(r'\b(?:team|support|admissions|careers|recruiting|hiring|notifications|updates)\b', caseSensitive: false), '')
          .trim();
      if (nameClean.isNotEmpty && nameClean.length < 30) {
        return nameClean;
      }
    }

    // 3. Extract domain name
    final domainMatch = RegExp(r'@([a-zA-Z0-9.-]+)\.([a-zA-Z]{2,})').firstMatch(email.senderEmail);
    if (domainMatch != null) {
      final domainPart = domainMatch.group(1)!;
      final skipDomains = {'gmail', 'yahoo', 'hotmail', 'outlook', 'icloud', 'proton', 'mail'};
      if (!skipDomains.contains(domainPart.toLowerCase())) {
        return domainPart[0].toUpperCase() + domainPart.substring(1);
      }
    }

    return null;
  }

  bool _isLowPriorityNewsletterOrDigest(String text, String sender) {
    final noiseTerms = [
      'unsubscribe',
      'newsletter',
      'weekly digest',
      'daily digest',
      'marketing',
      'promotional',
      'shop now',
      'special offer',
      'discount code',
      'terms of service update',
      'privacy policy update',
    ];
    int hits = 0;
    for (final term in noiseTerms) {
      if (text.contains(term)) hits++;
    }
    return hits >= 2 && !text.contains('interview') && !text.contains('exam') && !text.contains('deadline');
  }

  bool _matchesPattern(String text, List<RegExp> patterns) {
    for (final p in patterns) {
      if (p.hasMatch(text)) return true;
    }
    return false;
  }

  String? _detectGenericAction(String text) {
    final actions = [
      'submit',
      'register',
      'apply',
      'attend',
      'upload',
      'complete',
      'reply',
      'confirm',
      'pay',
      'schedule',
      'review',
    ];
    for (final act in actions) {
      if (RegExp('\\b$act(?:ing|ed|s)?\\b').hasMatch(text)) {
        return act;
      }
    }
    return null;
  }

  _TemporalExtractionResult _extractTemporalDetails(String text, DateTime baseTime) {
    // 1. Check explicit deadline regex patterns
    final deadlinePatterns = [
      RegExp(r'(?:due\s+(?:date\s+is\s+|date:\s*|by|on|at|before)|deadline\s+(?:is\s+|is\s+on\s+|is\s+at\s+|:\s*)?|submit\s+(?:before|by|on|at)|last\s+date\s+(?:is\s+|to\s+apply\s+is\s+|to\s+submit\s+is\s+|:\s*)?|closes\s+(?:at|on)|ends\s+(?:on|at)|reply\s+by)\s+([^\n.,;]+)', caseSensitive: false),
      RegExp(r'(?:before|by)\s+((?:today|tomorrow|monday|tuesday|wednesday|thursday|friday|saturday|sunday|\d{1,2}(?:st|nd|rd|th)?\s+[a-zA-Z]+|\d{1,2}/\d{1,2}/\d{2,4})(?:\s+(?:at\s+)?\d{1,2}(?::\d{2})?\s*(?:am|pm)?)?)', caseSensitive: false),
    ];

    for (final dp in deadlinePatterns) {
      final match = dp.firstMatch(text);
      if (match != null) {
        final phrase = match.group(1)?.trim();
        if (phrase != null && phrase.isNotEmpty) {
          final parsed = temporalEngine.parse(phrase, now: baseTime);
          final res = parsed.deadline ?? parsed.eventStart;
          if (res != null) {
            return _TemporalExtractionResult(deadline: res);
          }
        }
      }
    }

    // 2. Check explicit event / interview / exam date patterns
    final eventPatterns = [
      RegExp(r'(?:scheduled\s+(?:for|on)|interview\s+(?:on|at)|exam\s+(?:on|at)|meeting\s+(?:on|at))\s+([^\n.,;]+)', caseSensitive: false),
      RegExp(r'(?:on\s+)?((?:today|tomorrow|monday|tuesday|wednesday|thursday|friday|saturday|sunday|\d{1,2}(?:st|nd|rd|th)?\s+[a-zA-Z]+)\s+at\s+\d{1,2}(?::\d{2})?\s*(?:am|pm))', caseSensitive: false),
    ];

    for (final ep in eventPatterns) {
      final match = ep.firstMatch(text);
      if (match != null) {
        final phrase = match.group(1)?.trim();
        if (phrase != null && phrase.isNotEmpty) {
          final parsed = temporalEngine.parse(phrase, now: baseTime);
          final res = parsed.eventStart ?? parsed.deadline;
          if (res != null) {
            return _TemporalExtractionResult(eventStart: res);
          }
        }
      }
    }

    // 3. Fallback: general temporal engine sweep on entire text snippet if short
    final firstLines = text.split('\n').take(5).join(' ');
    final generalParsed = temporalEngine.parse(firstLines, now: baseTime);
    if (generalParsed.deadline != null) {
      return _TemporalExtractionResult(deadline: generalParsed.deadline);
    }
    if (generalParsed.eventStart != null) {
      return _TemporalExtractionResult(eventStart: generalParsed.eventStart);
    }

    // Check if there was an unresolvable date keyword like "soon", "later", "next week"
    final ambiguousKeyword = RegExp(r'\b(?:soon|later|next\s+week|sometime|asap)\b', caseSensitive: false).hasMatch(text);

    return _TemporalExtractionResult(isAmbiguous: ambiguousKeyword);
  }

  String _generateTaskTitle({
    required String subject,
    required String? action,
    required String? org,
    required bool isExam,
    required bool isInterview,
    required bool isAssignment,
    required bool isApplication,
    required bool isPayment,
  }) {
    final cleanSubject = subject
        .replaceAll(RegExp(r'^(?:Fwd|Re|FW|RE):\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'\[[^\]]*\]'), '')
        .trim();

    if (isInterview) {
      return org != null ? '$org Interview' : (cleanSubject.isNotEmpty ? cleanSubject : 'Interview');
    }

    if (isExam) {
      if (cleanSubject.toLowerCase().contains('exam') || cleanSubject.toLowerCase().contains('quiz')) {
        return cleanSubject;
      }
      return org != null ? '$org Exam' : 'Exam Preparation';
    }

    if (isAssignment) {
      if (cleanSubject.toLowerCase().contains('assignment') || cleanSubject.toLowerCase().contains('project')) {
        return cleanSubject.toLowerCase().startsWith('submit') ? cleanSubject : 'Submit $cleanSubject';
      }
      return 'Submit Assignment';
    }

    if (isApplication) {
      if (cleanSubject.toLowerCase().contains('application') || cleanSubject.toLowerCase().contains('registration')) {
        return cleanSubject;
      }
      return org != null ? 'Apply for $org' : 'Complete Application';
    }

    if (isPayment) {
      return org != null ? 'Pay $org Fee' : (cleanSubject.isNotEmpty ? cleanSubject : 'Pay Bill');
    }

    if (action != null && action.isNotEmpty) {
      final actCap = action[0].toUpperCase() + action.substring(1);
      if (cleanSubject.isNotEmpty) {
        return cleanSubject;
      }
      return org != null ? '$actCap $org' : actCap;
    }

    return cleanSubject.isNotEmpty ? cleanSubject : 'Email Task';
  }

  static final List<String> _knownBrands = [
    'Microsoft',
    'Google',
    'Amazon',
    'Apple',
    'Coursera',
    'Canvas',
    'GitHub',
    'LinkedIn',
    'Netflix',
    'Spotify',
    'Uber',
    'OpenAI',
    'Meta',
    'Salesforce',
    'Stripe',
  ];

  static final List<RegExp> _examPatterns = [
    RegExp(r'\b(?:exam|examination|midterm|finals|quiz|test|assessment)\b', caseSensitive: false),
  ];

  static final List<RegExp> _interviewPatterns = [
    RegExp(r'\b(?:interview|screening\s+round|technical\s+round|hiring\s+manager|interview\s+invitation)\b', caseSensitive: false),
  ];

  static final List<RegExp> _assignmentPatterns = [
    RegExp(r'\b(?:assignment|homework|lab\s+submission|project\s+submission|submit\s+assignment)\b', caseSensitive: false),
  ];

  static final List<RegExp> _applicationPatterns = [
    RegExp(r'\b(?:application\s+deadline|registration\s+closes|apply\s+by|last\s+date\s+to\s+apply|registration\s+open)\b', caseSensitive: false),
  ];

  static final List<RegExp> _paymentPatterns = [
    RegExp(r'\b(?:tuition|fee\s+due|payment\s+due|invoice|pay\s+bill|billing\s+statement)\b', caseSensitive: false),
  ];

  static final List<RegExp> _meetingPatterns = [
    RegExp(r'\b(?:meeting|appointment|sync|discussion|webinar)\b', caseSensitive: false),
  ];
}

class _TemporalExtractionResult {
  final DateTime? deadline;
  final DateTime? eventStart;
  final bool isAmbiguous;

  _TemporalExtractionResult({
    this.deadline,
    this.eventStart,
    this.isAmbiguous = false,
  });
}
