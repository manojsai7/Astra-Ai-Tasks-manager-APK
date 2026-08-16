import '../../services/ml/b1_event_classifier_client.dart';
import 'astra_command.dart';
import 'astra_temporal_engine.dart';

class AstraSemanticEngine {
  const AstraSemanticEngine({
    this.temporalEngine = const AstraTemporalEngine(),
  });

  final AstraTemporalEngine temporalEngine;

  AstraCommand resolve({
    required String text,
    required String intent,
    B1ClassificationResult? b1,
    DateTime? now,
  }) {
    final normalized = text.trim().toLowerCase();

    final referenceNow = now ?? DateTime.now();

    final organization = _resolveOrganization(
      text,
    );

    final eventType = _resolveEventType(
      normalized,
      b1,
    );

    final action = _resolveAction(
      normalized,
      eventType,
    );

    final title = _resolveTitle(
      text,
      normalized,
      eventType,
      organization,
    );

    final isDeadline = _looksLikeDeadline(
      normalized,
    );

    final temporalResult = temporalEngine.parse(
      text,
      now: referenceNow,
      isDeadline: isDeadline,
    );

    final recurrence = temporalResult.recurrence;

    final modelConfidence =
        b1?.confidence ?? 0.0;

    final semanticConfidence =
        _semanticConfidence(
      normalized,
      eventType,
      b1,
      temporalResult,
    );

    final requiresConfirmation =
        _requiresConfirmation(
      temporalResult,
      action,
    );

    final route = _route(
      semanticConfidence,
      requiresConfirmation,
    );

    return AstraCommand(
      intent: intent,
      eventType: eventType,
      title: title,
      action: action,
      organization: organization,
      temporal: AstraTemporal(
        eventStart: temporalResult.eventStart,
        eventEnd: temporalResult.eventEnd,
        deadline: temporalResult.deadline,
        rawDate: temporalResult.rawDate,
        rawTime: temporalResult.rawTime,
        rawDeadline: temporalResult.rawDeadline,
        rawDeadlineTime: _extractRawDeadlineTime(
          normalized,
        ),
        recurrence: recurrence,
        timezone: 'Asia/Kolkata',
        ambiguous: temporalResult.ambiguous,
        warnings: temporalResult.warnings,
      ),
      recurrence: recurrence,
      priority: _priority(normalized),
      modelConfidence: modelConfidence,
      semanticConfidence: semanticConfidence,
      requiresConfirmation: requiresConfirmation,
      route: route,
      originalText: text,
    );
  }

  String _resolveEventType(
    String text,
    B1ClassificationResult? b1,
  ) {
    if (text.contains('scholarship') &&
        text.contains('application')) {
      return 'APPLICATION';
    }

    if (text.contains('feedback') &&
        text.contains('form')) {
      return 'FEEDBACK';
    }

    if (text.contains('exam') &&
        text.contains('form')) {
      return 'FORM';
    }

    if (text.contains('hall ticket') ||
        text.contains('admit card')) {
      return 'DOCUMENT';
    }

    if (text.contains('interview')) {
      return 'INTERVIEW';
    }

    if (text.contains('exam') ||
        text.contains('retest') ||
        text.contains('checkpoint test')) {
      return 'EXAM';
    }

    if (text.contains('assignment')) {
      return 'ASSIGNMENT';
    }

    if (text.contains('training')) {
      return 'TRAINING';
    }

    if (text.contains('workshop')) {
      return 'WORKSHOP';
    }

    if (text.contains('meeting')) {
      return 'MEETING';
    }

    if (text.contains('class') ||
        text.contains('lecture') ||
        text.contains('classwork')) {
      return 'CLASS';
    }

    if (text.contains('fee') ||
        text.contains('payment')) {
      return 'FEE';
    }

    if (text.contains('feedback')) {
      return 'FEEDBACK';
    }

    if (text.contains('form')) {
      return 'FORM';
    }

    if (text.contains('application')) {
      return 'APPLICATION';
    }

    return b1?.eventType ?? 'OTHER';
  }

  String? _resolveAction(
    String text,
    String eventType,
  ) {
    if (text.contains('collect') ||
        text.contains('pick up')) {
      return 'COLLECT';
    }

    if (text.contains('fill') &&
        text.contains('form')) {
      return 'FILL';
    }

    if (text.contains('submit') ||
        text.contains('turn in') ||
        text.contains('hand in')) {
      return 'SUBMIT';
    }

    if (text.contains('pay') ||
        text.contains('payment')) {
      return 'PAY';
    }

    if (text.contains('apply') ||
        text.contains('application')) {
      return 'APPLY';
    }

    if (text.contains('register')) {
      return 'REGISTER';
    }

    if (text.contains('cancel') ||
        text.contains('cancelled') ||
        text.contains('canceled') ||
        text.contains('postponed')) {
      return 'CANCEL';
    }

    if ([
      'EXAM',
      'INTERVIEW',
      'TRAINING',
      'WORKSHOP',
      'MEETING',
      'CLASS',
      'EVENT',
    ].contains(eventType)) {
      return 'ATTEND';
    }

    return null;
  }

  String? _resolveOrganization(String text) {
    const knownOrgs = [
      'Microsoft',
      'Google',
      'Amazon',
      'Meta',
      'Apple',
      'NPTEL',
      'SIVI Quant Labs',
      'Infosys',
      'TCS',
      'Wipro',
      'Coursera',
      'Udemy',
      'IIT',
      'NIT',
      'AICTE',
    ];

    for (final org in knownOrgs) {
      final pattern = RegExp(
        r'\b' + RegExp.escape(org) + r'\b',
        caseSensitive: false,
      );
      if (pattern.hasMatch(text)) {
        return org;
      }
    }

    return null;
  }

  String _resolveTitle(
    String originalText,
    String normalized,
    String eventType,
    String? organization,
  ) {
    final simpleTitle = _extractSimpleReminderTitle(originalText);
    if (simpleTitle != null && simpleTitle.isNotEmpty) {
      return simpleTitle;
    }

    if (normalized.contains('hall ticket')) {
      return 'Hall Ticket';
    }

    if (normalized.contains('admit card')) {
      return 'Admit Card';
    }

    if (normalized.contains('scholarship') &&
        normalized.contains('application')) {
      return 'Scholarship Application';
    }

    if (normalized.contains('feedback form')) {
      return 'Feedback Form';
    }

    if (normalized.contains('exam form')) {
      return 'Exam Form';
    }

    String baseTitle;
    switch (eventType) {
      case 'EXAM':
        baseTitle = 'Exam';
        break;
      case 'ASSIGNMENT':
        baseTitle = 'Assignment';
        break;
      case 'TRAINING':
        baseTitle = 'Training';
        break;
      case 'WORKSHOP':
        baseTitle = 'Workshop';
        break;
      case 'MEETING':
        baseTitle = 'Meeting';
        break;
      case 'INTERVIEW':
        baseTitle = 'Interview';
        break;
      case 'FEE':
        baseTitle = 'Fee Payment';
        break;
      case 'FORM':
        baseTitle = 'Form';
        break;
      case 'CLASS':
        baseTitle = 'Class';
        break;
      case 'DOCUMENT':
        baseTitle = 'Document';
        break;
      default:
        baseTitle = eventType == 'OTHER' ? 'Task' : eventType;
    }

    // If baseTitle defaulted to generic 'Task' or 'OTHER', try extracting custom activity from text
    // (e.g. "standup every weekday at 10am" -> "Standup")
    if (baseTitle == 'Task' || baseTitle == 'OTHER') {
      final customTitle = _cleanTemporalFromReminder(originalText);
      if (customTitle.isNotEmpty && customTitle.length >= 2) {
        baseTitle = customTitle[0].toUpperCase() + customTitle.substring(1);
      }
    }

    if (organization != null && organization.isNotEmpty) {
      if (!baseTitle.toLowerCase().contains(organization.toLowerCase())) {
        return '$organization $baseTitle';
      }
    }

    return baseTitle;
  }

  String? _extractSimpleReminderTitle(String text) {
    final t = text.trim();
    final lower = t.toLowerCase();

    const prefixes = [
      'remind me to ',
      'reminder to ',
      'notify me to ',
      'alert me to ',
      'remind me ',
    ];

    String? subject;
    for (final prefix in prefixes) {
      if (lower.startsWith(prefix)) {
        subject = t.substring(prefix.length).trim();
        break;
      }
    }

    if (subject == null || subject.isEmpty) {
      return null;
    }

    // Strip trailing or leading temporal clauses from the reminder subject
    subject = _cleanTemporalFromReminder(subject);

    if (subject.isEmpty || subject.length < 2) {
      return null;
    }

    // Capitalize first letter
    return subject[0].toUpperCase() + subject.substring(1);
  }

  String _cleanTemporalFromReminder(String text) {
    var s = text;

    // Patterns matching trailing temporal clauses
    final trailingPatterns = [
      RegExp(r'\s+every\s+(?:weekday|day|week|month|morning|evening|monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b.*$', caseSensitive: false),
      RegExp(r'\s+daily\b.*$', caseSensitive: false),
      RegExp(r'\s+weekly\b.*$', caseSensitive: false),
      RegExp(r'\s+monthly\b.*$', caseSensitive: false),
      RegExp(r'\s+(?:in|after|next)?\s*(?:the\s+)?(?:next|one|\d+)?\s*(?:mins?|minutes?|hours?|hrs?|days?|secs?|seconds?)(?:\s+from\s+now)?\b.*$', caseSensitive: false),
      RegExp(r'\s+at\s+\d{1,2}(?:(?:\s*:\s*|\s+)\d{2})?\s*(?:am|pm)?\b.*$', caseSensitive: false),
      RegExp(r'\s+by\s+\d{1,2}(?:(?:\s*:\s*|\s+)\d{2})?\s*(?:am|pm)?\b.*$', caseSensitive: false),
      RegExp(r'\s+before\s+\d{1,2}(?:(?:\s*:\s*|\s+)\d{2})?\s*(?:am|pm)?\b.*$', caseSensitive: false),
      RegExp(r'\s+(?:today|tomorrow|day after tomorrow)\s*(?:at\s+\d{1,2}(?:(?:\s*:\s*|\s+)\d{2})?\s*(?:am|pm))?.*$', caseSensitive: false),
      RegExp(r'\s+on\s+(?:monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b.*$', caseSensitive: false),
    ];

    for (final pattern in trailingPatterns) {
      s = s.replaceAll(pattern, '').trim();
    }

    return s;
  }

  String _priority(String text) {
    if (text.contains('critical') ||
        text.contains('without fail') ||
        text.contains('mandatory') ||
        text.contains('do not miss')) {
      return 'critical';
    }

    if (text.contains('urgent') ||
        text.contains('important') ||
        text.contains('priority')) {
      return 'high';
    }

    return 'normal';
  }

  bool _looksLikeDeadline(
    String text,
  ) {
    return text.contains('deadline') ||
        text.contains('due') ||
        text.contains('last date') ||
        text.contains('submit') &&
            (text.contains(' by ') ||
                text.contains(' before ')) ||
        text.contains('fill') &&
            text.contains(' before ') ||
        text.contains('pay') &&
            text.contains(' by ') ||
        text.contains('closes') ||
        text.contains('expires');
  }

  double _semanticConfidence(
    String text,
    String eventType,
    B1ClassificationResult? b1,
    AstraTemporalResult temporal,
  ) {
    double confidence = b1?.confidence ?? 0.0;

    if (eventType == 'EXAM' &&
        text.contains('exam')) {
      confidence = 0.95;
    }

    if (eventType == 'INTERVIEW' &&
        text.contains('interview')) {
      confidence = 0.95;
    }

    if (eventType == 'DOCUMENT' &&
        (text.contains('hall ticket') ||
            text.contains('admit card'))) {
      confidence = 0.95;
    }

    if (eventType == 'APPLICATION' &&
        text.contains('application')) {
      confidence = 0.95;
    }

    if (temporal.eventStart != null ||
        temporal.deadline != null ||
        temporal.recurrence != 'NONE') {
      confidence = confidence < 0.90
          ? 0.90
          : confidence;
    }

    return confidence;
  }

  bool _requiresConfirmation(
    AstraTemporalResult temporal,
    String? action,
  ) {
    if (temporal.ambiguous) {
      return true;
    }

    if (temporal.warnings.isNotEmpty) {
      return true;
    }

    if (action == 'SUBMIT' ||
        action == 'FILL' ||
        action == 'PAY' ||
        action == 'APPLY' ||
        action == 'REGISTER' ||
        action == 'COLLECT') {
      if (temporal.eventStart == null &&
          temporal.deadline == null &&
          temporal.recurrence == 'NONE') {
        return true;
      }
    }

    return false;
  }

  String _route(
    double confidence,
    bool confirmation,
  ) {
    if (confirmation) {
      return 'CONFIRM';
    }

    if (confidence >= 0.85) {
      return 'EXECUTE';
    }

    if (confidence >= 0.65) {
      return 'CONFIRM';
    }

    return 'LLM_FALLBACK';
  }

  String? _extractRawDeadlineTime(
    String text,
  ) {
    final explicit = RegExp(
      r'\b\d{1,2}(?:\s*:\s*\d{2})?\s*(?:am|pm)\b',
      caseSensitive: false,
    ).firstMatch(text);

    if (explicit != null) {
      return explicit.group(0);
    }

    final bare = RegExp(
      r'\b(?:by|before)\s+(\d{1,2})\b',
      caseSensitive: false,
    ).firstMatch(text);

    return bare?.group(1);
  }
}
