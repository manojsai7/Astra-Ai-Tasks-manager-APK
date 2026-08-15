import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/assistant/astra_temporal_engine.dart';

final astraTemporalEngineProvider =
    Provider<AstraTemporalEngine>((ref) {
  return const AstraTemporalEngine();
});
