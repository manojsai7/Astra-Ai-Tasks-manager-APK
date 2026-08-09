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

/// The local application database.
@DriftDatabase(tables: [InboxItems, Tasks])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(tasks);
      }
    },
  );
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
