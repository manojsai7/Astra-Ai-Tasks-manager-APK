import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/assistant/astra_execution_gate.dart';

final astraExecutionGateProvider = Provider<AstraExecutionGate>((ref) {
  return const AstraExecutionGate();
});
