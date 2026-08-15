import 'package:flutter_test/flutter_test.dart';

import 'package:astra/services/assistant/astra_command.dart';
import 'package:astra/services/assistant/astra_execution_gate.dart';

void main() {
  const gate = AstraExecutionGate();

  group('AstraExecutionGate tests', () {
    test('exam today at 6pm is safe to execute', () {
      final command = AstraCommand(
        intent: 'CREATE_TASK',
        eventType: 'EXAM',
        title: 'Exam',
        action: 'ATTEND',
        organization: null,
        temporal: AstraTemporal(
          eventStart: DateTime(2026, 8, 15, 18, 0),
          recurrence: 'NONE',
        ),
        recurrence: 'NONE',
        priority: 'normal',
        modelConfidence: 0.95,
        semanticConfidence: 0.95,
        requiresConfirmation: false,
        route: 'EXECUTE',
        originalText: 'bruh i have exam today at 6pm',
      );

      final decision = gate.check(command);
      expect(decision.canExecute, true);
      expect(decision.reason, 'safe_to_execute');
    });

    test('simple reminder in 2 mins is safe to execute', () {
      final command = AstraCommand(
        intent: 'CREATE_REMINDER',
        eventType: 'OTHER',
        title: 'Drink water',
        action: null,
        organization: null,
        temporal: AstraTemporal(
          eventStart: DateTime.now().add(const Duration(minutes: 2)),
          recurrence: 'NONE',
        ),
        recurrence: 'NONE',
        priority: 'normal',
        modelConfidence: 0.99,
        semanticConfidence: 0.99,
        requiresConfirmation: false,
        route: 'EXECUTE',
        originalText: 'remind me to drink water in 2 mins',
      );

      final decision = gate.check(command);
      expect(decision.canExecute, true);
      expect(decision.reason, 'safe_to_execute');
    });

    test('ambiguous submit assignment tomorrow by 5 is rejected', () {
      final command = AstraCommand(
        intent: 'CREATE_TASK',
        eventType: 'ASSIGNMENT',
        title: 'Assignment',
        action: 'SUBMIT',
        organization: null,
        temporal: const AstraTemporal(
          ambiguous: true,
          warnings: ['Bare deadline time "5" is ambiguous.'],
        ),
        recurrence: 'NONE',
        priority: 'normal',
        modelConfidence: 0.90,
        semanticConfidence: 0.90,
        requiresConfirmation: true,
        route: 'CONFIRM',
        originalText: 'submit assignment tomorrow by 5',
      );

      final decision = gate.check(command);
      expect(decision.canExecute, false);
      expect(decision.reason, 'route_not_execute');
    });

    test('missing-date deadline is rejected', () {
      final command = AstraCommand(
        intent: 'CREATE_TASK',
        eventType: 'FORM',
        title: 'NPTEL Form',
        action: 'FILL',
        organization: 'NPTEL',
        temporal: const AstraTemporal(
          rawTime: '4pm',
        ),
        recurrence: 'NONE',
        priority: 'normal',
        modelConfidence: 0.90,
        semanticConfidence: 0.90,
        requiresConfirmation: true,
        route: 'CONFIRM',
        originalText: 'fill the NPTEL form before 4pm',
      );

      final decision = gate.check(command);
      expect(decision.canExecute, false);
    });

    test('requires_confirmation=true is rejected', () {
      final command = AstraCommand(
        intent: 'CREATE_TASK',
        eventType: 'DOCUMENT',
        title: 'Hall Ticket',
        action: 'COLLECT',
        organization: null,
        temporal: const AstraTemporal(),
        recurrence: 'NONE',
        priority: 'normal',
        modelConfidence: 0.95,
        semanticConfidence: 0.95,
        requiresConfirmation: true,
        route: 'EXECUTE',
        originalText: 'Please collect your hall ticket',
      );

      final decision = gate.check(command);
      expect(decision.canExecute, false);
      expect(decision.reason, 'confirmation_required');
    });

    test('route=CONFIRM is rejected', () {
      final command = AstraCommand(
        intent: 'CREATE_TASK',
        eventType: 'MEETING',
        title: 'Meeting',
        action: 'ATTEND',
        organization: null,
        temporal: const AstraTemporal(),
        recurrence: 'NONE',
        priority: 'normal',
        modelConfidence: 0.70,
        semanticConfidence: 0.70,
        requiresConfirmation: false,
        route: 'CONFIRM',
        originalText: 'sync meeting sometime',
      );

      final decision = gate.check(command);
      expect(decision.canExecute, false);
      expect(decision.reason, 'route_not_execute');
    });
  });
}
