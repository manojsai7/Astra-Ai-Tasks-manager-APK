class AstraTemporal {
  final DateTime? eventStart;
  final DateTime? eventEnd;

  final DateTime? deadline;

  final String? rawDate;
  final String? rawTime;
  final String? rawDeadline;
  final String? rawDeadlineTime;

  final String recurrence;

  final String timezone;

  final bool ambiguous;

  final List<String> warnings;

  const AstraTemporal({
    this.eventStart,
    this.eventEnd,
    this.deadline,
    this.rawDate,
    this.rawTime,
    this.rawDeadline,
    this.rawDeadlineTime,
    this.recurrence = 'NONE',
    this.timezone = 'Asia/Kolkata',
    this.ambiguous = false,
    this.warnings = const [],
  });
}

class AstraCommand {
  final String intent;

  final String eventType;
  final String title;

  final String? action;
  final String? organization;

  final AstraTemporal temporal;

  final String recurrence;
  final String priority;

  final double modelConfidence;
  final double semanticConfidence;

  final bool requiresConfirmation;

  final String route;

  final String originalText;

  const AstraCommand({
    required this.intent,
    required this.eventType,
    required this.title,
    required this.temporal,
    required this.recurrence,
    required this.priority,
    required this.modelConfidence,
    required this.semanticConfidence,
    required this.requiresConfirmation,
    required this.route,
    required this.originalText,
    this.action,
    this.organization,
  });
}
