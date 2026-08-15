import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/assistant/astra_routing_policy.dart';

final astraRoutingPolicyProvider = Provider<AstraRoutingPolicy>((ref) {
  return const AstraRoutingPolicy();
});
