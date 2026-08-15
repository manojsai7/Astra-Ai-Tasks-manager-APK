import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/assistant/astra_semantic_engine.dart';

final astraSemanticEngineProvider =
    Provider<AstraSemanticEngine>((ref) {
  return const AstraSemanticEngine();
});
