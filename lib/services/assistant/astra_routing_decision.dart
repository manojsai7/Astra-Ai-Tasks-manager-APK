class AstraRoutingDecision {
  final String intent;
  final bool requiresEventClassification;
  final bool requiresTemporalParsing;
  final String reason;

  const AstraRoutingDecision({
    required this.intent,
    required this.requiresEventClassification,
    required this.requiresTemporalParsing,
    required this.reason,
  });
}
