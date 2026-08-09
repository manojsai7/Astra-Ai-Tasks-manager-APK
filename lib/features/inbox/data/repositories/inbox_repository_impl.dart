import 'package:drift/drift.dart';
import '../../../../core/database/database.dart';
import '../../domain/entities/inbox_item.dart';
import '../../domain/repositories/inbox_repository.dart';

/// Database-driven implementation of [InboxRepository] using Drift.
class InboxRepositoryImpl implements InboxRepository {
  final AppDatabase _db;

  InboxRepositoryImpl(this._db);

  @override
  Future<void> createInboxItem(InboxItem item) async {
    await _db
        .into(_db.inboxItems)
        .insert(
          InboxItemsCompanion.insert(
            id: item.id,
            rawText: item.rawText,
            sourceType: item.sourceType,
            processingStatus: item.processingStatus,
            receivedAt: item.receivedAt,
            createdAt: item.createdAt,
            updatedAt: item.updatedAt,
          ),
        );
  }

  @override
  Stream<List<InboxItem>> watchInboxItems() {
    final query = _db.select(_db.inboxItems)
      ..orderBy([
        (t) => OrderingTerm(expression: t.receivedAt, mode: OrderingMode.desc),
        (t) => OrderingTerm(
          expression: const CustomExpression<int>('rowid'),
          mode: OrderingMode.desc,
        ),
      ]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return InboxItem(
          id: row.id,
          rawText: row.rawText,
          sourceType: row.sourceType,
          processingStatus: row.processingStatus,
          receivedAt: row.receivedAt,
          createdAt: row.createdAt,
          updatedAt: row.updatedAt,
        );
      }).toList();
    });
  }
}
