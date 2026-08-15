import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/assistant/astra_intent_resolver.dart';

final astraIntentResolverProvider =
    Provider<AstraIntentResolver>((ref) {
  return const AstraIntentResolver();
});
