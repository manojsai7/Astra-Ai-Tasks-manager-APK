import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:astra/core/database/database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ASTRA SQLite Migration Idempotency Tests', () {
    test('1. OnUpgrade handles duplicate column addition without throwing SqliteException', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final migrator = db.createMigrator();

      // When opening a memory database, onCreate creates all tables including start_at & end_at.
      // Running onUpgrade from 8 to 9 (which attempts to add start_at and end_at)
      // must complete smoothly and idempotently without throwing SqliteException(1): duplicate column name.
      await expectLater(
        db.migration.onUpgrade(migrator, 8, 9),
        completes,
      );

      await db.close();
    });

    test('2. OnUpgrade from version 1 to 9 creates full schema safely', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final migrator = db.createMigrator();

      await expectLater(
        db.migration.onUpgrade(migrator, 1, 9),
        completes,
      );

      // Verify all tables exist and query without crashing
      final tasks = await db.select(db.tasks).get();
      final panchang = await db.select(db.panchangEvents).get();
      final reminders = await db.select(db.reminders).get();
      final sessions = await db.select(db.chatSessions).get();

      expect(tasks, isEmpty);
      expect(panchang, isEmpty);
      expect(reminders, isEmpty);
      expect(sessions, isEmpty);

      await db.close();
    });
  });
}
