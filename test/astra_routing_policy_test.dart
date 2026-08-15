import 'package:flutter_test/flutter_test.dart';

import 'package:astra/services/assistant/astra_routing_policy.dart';

void main() {
  const policy = AstraRoutingPolicy();

  test(
    'simple reminder bypasses Set B',
    () {
      final result = policy.decide(
        'CREATE_REMINDER',
        text: 'remind me to drink water in 2 mins',
      );

      expect(
        result.requiresEventClassification,
        false,
      );

      expect(
        result.requiresTemporalParsing,
        true,
      );
    },
  );

  test(
    'interview reminder uses Set B',
    () {
      final result = policy.decide(
        'CREATE_REMINDER',
        text: 'remind me about my Microsoft interview Monday at 11am',
      );

      expect(
        result.requiresEventClassification,
        true,
      );
    },
  );

  test(
    'task creation uses Set B',
    () {
      final result = policy.decide(
        'CREATE_TASK',
        text: 'bruh i have exam today at 6pm',
      );

      expect(
        result.requiresEventClassification,
        true,
      );
    },
  );

  test(
    'sync email bypasses Set B',
    () {
      final result = policy.decide(
        'SYNC_EMAIL',
        text: 'update inbox',
      );

      expect(
        result.requiresEventClassification,
        false,
      );

      expect(
        result.requiresTemporalParsing,
        false,
      );
    },
  );
}
