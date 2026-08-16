import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ritual_provider.dart';
import '../services/assistant/astra_memory_engine.dart';
import '../services/assistant/astra_context_builder.dart';
import '../services/assistant/astra_reference_resolver.dart';

/// Provider for [AstraMemoryEngine] backed by Drift SQLite.
final astraMemoryEngineProvider = Provider<AstraMemoryEngine>((ref) {
  final db = ref.watch(databaseProvider);
  return AstraMemoryEngine(db);
});

/// Provider for [AstraContextBuilder] assembling bounded local context.
final astraContextBuilderProvider = Provider<AstraContextBuilder>((ref) {
  final db = ref.watch(databaseProvider);
  final memoryEngine = ref.watch(astraMemoryEngineProvider);
  return AstraContextBuilder(db: db, memoryEngine: memoryEngine);
});

/// Provider for [AstraReferenceResolver] resolving anaphora & definite references.
final astraReferenceResolverProvider = Provider<AstraReferenceResolver>((ref) {
  return const AstraReferenceResolver();
});
