import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/backend_config.dart';
import '../services/ml/intent_classifier_client.dart';

final intentClassifierProvider =
    Provider<IntentClassifierClient>((ref) {
  final client = IntentClassifierClient(
    baseUrl: BackendConfig.baseUrl,
  );

  ref.onDispose(client.dispose);

  return client;
});
