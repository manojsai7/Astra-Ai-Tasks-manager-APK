import 'astra_command.dart';

class AstraGateDecision {
  final bool canExecute;
  final String reason;

  const AstraGateDecision({
    required this.canExecute,
    required this.reason,
  });

  static const safeToExecute = AstraGateDecision(
    canExecute: true,
    reason: 'safe_to_execute',
  );

  static const routeNotExecute = AstraGateDecision(
    canExecute: false,
    reason: 'route_not_execute',
  );

  static const confirmationRequired = AstraGateDecision(
    canExecute: false,
    reason: 'confirmation_required',
  );

  static const temporalAmbiguous = AstraGateDecision(
    canExecute: false,
    reason: 'temporal_ambiguous',
  );

  static const temporalMissing = AstraGateDecision(
    canExecute: false,
    reason: 'temporal_missing',
  );
}

class AstraExecutionGate {
  const AstraExecutionGate();

  AstraGateDecision check(AstraCommand command) {
    if (command.route != 'EXECUTE') {
      return AstraGateDecision.routeNotExecute;
    }

    if (command.requiresConfirmation) {
      return AstraGateDecision.confirmationRequired;
    }

    if (command.temporal.ambiguous) {
      return AstraGateDecision.temporalAmbiguous;
    }

    if (command.temporal.warnings.isNotEmpty) {
      final hasTemporalWarning = command.temporal.warnings.any(
        (w) =>
            w.toLowerCase().contains('ambiguous') ||
            w.toLowerCase().contains('missing') ||
            w.toLowerCase().contains('unresolved'),
      );
      if (hasTemporalWarning) {
        return AstraGateDecision.temporalAmbiguous;
      }
    }

    // For deadline-driven or time-sensitive actions, verify temporal presence
    if (command.action == 'SUBMIT' ||
        command.action == 'PAY' ||
        command.action == 'FILL' ||
        command.action == 'APPLY') {
      if (command.temporal.eventStart == null &&
          command.temporal.deadline == null &&
          command.temporal.recurrence == 'NONE') {
        return AstraGateDecision.temporalMissing;
      }
    }

    return AstraGateDecision.safeToExecute;
  }
}
