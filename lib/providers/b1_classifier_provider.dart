import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/backend_config.dart';
import '../services/ml/b1_event_classifier_client.dart';

final b1EventClassifierProvider =
    Provider<B1EventClassifierClient>((ref) {
  final client = B1EventClassifierClient(
    baseUrl: BackendConfig.baseUrl,
  );

  ref.onDispose(client.dispose);

  return client;
});
