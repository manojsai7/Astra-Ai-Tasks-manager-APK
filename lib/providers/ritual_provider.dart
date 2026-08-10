import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/database.dart';

// ---------------------------------------------------------------------------
// Database provider — single AppDatabase instance for the app.
// ---------------------------------------------------------------------------

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = constructDb();
  ref.onDispose(db.close);
  return db;
});

// ---------------------------------------------------------------------------
// Ritual Rules providers
// ---------------------------------------------------------------------------

/// All active ritual rules (Ekadashi fast, Purnima pooja, etc.)
final ritualRulesProvider = FutureProvider<List<RitualRuleEntry>>((ref) async {
  final db = ref.read(databaseProvider);
  await db.seedDefaultRules();
  return db.getActiveRules();
});

/// StateNotifier for CRUD on ritual rules.
class RitualNotifier extends StateNotifier<List<RitualRuleEntry>> {
  final Ref _ref;
  RitualNotifier(this._ref) : super([]) {
    _load();
  }

  AppDatabase get _db => _ref.read(databaseProvider);

  Future<void> _load() async {
    await _db.seedDefaultRules();
    state = await _db.getActiveRules();
  }

  Future<void> addRule(RitualRulesCompanion companion) async {
    await _db.into(_db.ritualRules).insert(companion);
    await _load();
  }

  Future<void> toggleActive(int id) async {
    final rule = state.firstWhere((r) => r.id == id);
    await (_db.update(_db.ritualRules)..where((r) => r.id.equals(id))).write(
      RitualRulesCompanion(isActive: Value(!rule.isActive)),
    );
    await _load();
  }

  Future<void> deleteRule(int id) async {
    await (_db.delete(_db.ritualRules)..where((r) => r.id.equals(id))).go();
    await _load();
  }

  Future<void> updateRemindDaysBefore(int id, int days) async {
    await (_db.update(_db.ritualRules)..where((r) => r.id.equals(id))).write(
      RitualRulesCompanion(remindDaysBefore: Value(days)),
    );
    await _load();
  }
}

final ritualNotifierProvider =
    StateNotifierProvider<RitualNotifier, List<RitualRuleEntry>>(
  (ref) => RitualNotifier(ref),
);
