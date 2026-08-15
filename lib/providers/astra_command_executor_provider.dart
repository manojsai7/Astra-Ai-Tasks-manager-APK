import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/assistant/astra_command_executor.dart';

final astraCommandExecutorProvider =
    Provider<AstraCommandExecutor>((ref) {
  return const AstraCommandExecutor();
});
