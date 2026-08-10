import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

/// Local SQLite table schema for Inbox items.
@DataClassName('InboxItemEntry')
class InboxItems extends Table {
  TextColumn get id => text()();
  TextColumn get rawText => text()();
  TextColumn get sourceType => text()();
  TextColumn get processingStatus => text()();
  DateTimeColumn get receivedAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local SQLite table schema for Tasks.
@DataClassName('TaskEntry')
class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get inboxItemId => text().nullable()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get taskType => text()();
  TextColumn get priority => text()();
  TextColumn get status => text()();
  DateTimeColumn get dueAt => dateTime().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Panchang events table – stores pre-computed Ekadashi, Purnima, Amavasya dates.
@DataClassName('PanchangEventEntry')
class PanchangEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get eventName => text()();        // e.g. 'Ekadashi', 'Purnima', 'Amavasya'
  TextColumn get displayName => text()();      // e.g. 'Phalguna Shukla Ekadashi'
  DateTimeColumn get eventDate => dateTime()();
  TextColumn get paksha => text()();           // 'Shukla' or 'Krishna'
  TextColumn get lunarMonth => text()();
  TextColumn get description => text().nullable()();
  IntColumn get calendarYear => integer()();
  BoolColumn get notificationScheduled => boolean().withDefault(const Constant(false))();
}

/// Ritual rules – user-configurable reminder rules per event type.
@DataClassName('RitualRuleEntry')
class RitualRules extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get eventType => text()();         // 'Ekadashi', 'Purnima', 'Amavasya'
  TextColumn get title => text()();
  TextColumn get instructions => text().nullable()();
  IntColumn get remindDaysBefore => integer().withDefault(const Constant(1))();
  TextColumn get remindAtTime => text().withDefault(const Constant('06:00'))(); // HH:mm
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}

/// Local SQLite table schema for full task context (Company, Role, Requirements, Links, AI Email summary).
@DataClassName('TaskContextEntry')
class TaskContexts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get taskId => text()();
  TextColumn get companyName => text().nullable()();
  TextColumn get role => text().nullable()();
  TextColumn get requirements => text().nullable()();
  TextColumn get applicationLink => text().nullable()();
  TextColumn get emailSnippet => text().nullable()();
  TextColumn get fullEmail => text().nullable()();
  BoolColumn get hasApplied => boolean().withDefault(const Constant(false))();
  DateTimeColumn get appliedAt => dateTime().nullable()();
  TextColumn get eventType => text().nullable()(); // 'exam', 'application', 'meeting', 'reminder'
  TextColumn get location => text().nullable()();
  TextColumn get stipend => text().nullable()();
  TextColumn get actionItems => text().nullable()();
  TextColumn get source => text().withDefault(const Constant('gmail'))();
}

/// The local application database.
@DriftDatabase(tables: [InboxItems, Tasks, PanchangEvents, RitualRules, TaskContexts])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(tasks);
      }
      if (from < 3) {
        await m.createTable(panchangEvents);
        await m.createTable(ritualRules);
      }
      if (from < 4) {
        await m.createTable(taskContexts);
      }
    },
  );

  // --- PanchangEvent Queries ---

  Future<List<PanchangEventEntry>> getUpcomingEvents({int days = 90}) {
    final now = DateTime.now();
    final future = now.add(Duration(days: days));
    return (select(panchangEvents)
          ..where((e) => e.eventDate.isBiggerOrEqualValue(now))
          ..where((e) => e.eventDate.isSmallerOrEqualValue(future))
          ..orderBy([(e) => OrderingTerm.asc(e.eventDate)]))
        .get();
  }

  Future<List<PanchangEventEntry>> getEventsByYear(int year) {
    return (select(panchangEvents)
          ..where((e) => e.calendarYear.equals(year))
          ..orderBy([(e) => OrderingTerm.asc(e.eventDate)]))
        .get();
  }

  Future<void> insertOrReplaceEvents(List<PanchangEventsCompanion> events) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(panchangEvents, events);
    });
  }

  // --- RitualRules Queries ---

  Future<List<RitualRuleEntry>> getActiveRules() {
    return (select(ritualRules)..where((r) => r.isActive.equals(true))).get();
  }

  Future<void> seedDefaultRules() async {
    final existing = await select(ritualRules).get();
    if (existing.isEmpty) {
      await batch((b) {
        b.insertAll(ritualRules, [
          const RitualRulesCompanion(
            eventType: Value('Ekadashi'),
            title: Value('Ekadashi Fasting'),
            instructions: Value('Observe fast. Avoid rice and grains. Break fast on Dwadashi.'),
            remindDaysBefore: Value(1),
            remindAtTime: Value('06:00'),
          ),
          const RitualRulesCompanion(
            eventType: Value('Purnima'),
            title: Value('Purnima Pooja'),
            instructions: Value('Satyanarayan pooja. Visit temple. Donate to charity.'),
            remindDaysBefore: Value(1),
            remindAtTime: Value('07:00'),
          ),
          const RitualRulesCompanion(
            eventType: Value('Amavasya'),
            title: Value('Pitru Tarpan'),
            instructions: Value('Perform tarpan for ancestors. Donate food and clothes.'),
            remindDaysBefore: Value(1),
            remindAtTime: Value('07:00'),
          ),
        ]);
      });
    }
  }

  // --- TaskContext Queries ---

  Future<TaskContextEntry?> getTaskContextByTaskId(String taskId) {
    return (select(taskContexts)..where((c) => c.taskId.equals(taskId))).getSingleOrNull();
  }

  Stream<TaskContextEntry?> watchTaskContextByTaskId(String taskId) {
    return (select(taskContexts)..where((c) => c.taskId.equals(taskId))).watchSingleOrNull();
  }

  Future<void> saveTaskContext(TaskContextsCompanion contextCompanion) async {
    final existing = await getTaskContextByTaskId(contextCompanion.taskId.value);
    if (existing != null) {
      await (update(taskContexts)..where((c) => c.taskId.equals(contextCompanion.taskId.value)))
          .write(contextCompanion);
    } else {
      await into(taskContexts).insert(contextCompanion);
    }
  }

  Future<void> updateAppliedStatus(String taskId, bool hasApplied, {DateTime? appliedAt}) async {
    await (update(taskContexts)..where((c) => c.taskId.equals(taskId))).write(
      TaskContextsCompanion(
        hasApplied: Value(hasApplied),
        appliedAt: Value(appliedAt ?? (hasApplied ? DateTime.now() : null)),
      ),
    );
  }
}

/// Dynamic SQLite database constructor for device runtime.
AppDatabase constructDb() {
  final db = LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'astra.db'));
    return NativeDatabase.createInBackground(file);
  });
  return AppDatabase(db);
}

/// In-memory SQLite database constructor for unit and integration testing.
AppDatabase constructInMemoryDb() {
  return AppDatabase(NativeDatabase.memory());
}
