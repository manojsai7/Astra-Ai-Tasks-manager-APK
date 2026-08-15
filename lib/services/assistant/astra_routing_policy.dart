import 'astra_routing_decision.dart';

class AstraRoutingPolicy {
  const AstraRoutingPolicy();

  AstraRoutingDecision decide(
    String intent, {
    required String text,
  }) {
    switch (intent) {
      case 'CREATE_TASK':
        return AstraRoutingDecision(
          intent: intent,
          requiresEventClassification: true,
          requiresTemporalParsing: true,
          reason: 'task_creation_requires_semantic_context',
        );

      case 'CREATE_CALENDAR_EVENT':
        return AstraRoutingDecision(
          intent: intent,
          requiresEventClassification: true,
          requiresTemporalParsing: true,
          reason: 'calendar_event_requires_semantic_context',
        );

      case 'UPDATE_TASK':
        return AstraRoutingDecision(
          intent: intent,
          requiresEventClassification: true,
          requiresTemporalParsing: true,
          reason: 'task_update_requires_semantic_context',
        );

      case 'CREATE_REMINDER':
        final simpleReminder = _looksLikeSimpleReminder(text);

        return AstraRoutingDecision(
          intent: intent,
          requiresEventClassification: !simpleReminder,
          requiresTemporalParsing: true,
          reason: simpleReminder
              ? 'simple_reminder_does_not_require_event_classification'
              : 'reminder_contains_event_semantics',
        );

      default:
        return AstraRoutingDecision(
          intent: intent,
          requiresEventClassification: false,
          requiresTemporalParsing: false,
          reason: 'direct_operation',
        );
    }
  }

  bool _looksLikeSimpleReminder(String text) {
    final t = text.toLowerCase().trim();

    // Explicitly generic reminder language.
    const genericPatterns = [
      'remind me to',
      'reminder to',
      'notify me to',
      'alert me to',
    ];

    return genericPatterns.any(t.startsWith);
  }
}
