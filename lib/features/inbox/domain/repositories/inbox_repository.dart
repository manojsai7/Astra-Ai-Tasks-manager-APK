import '../entities/inbox_item.dart';

/// Repository contract defining required operations for ASTRA Local Inbox.
///
/// Follows YAGNI and contains only methods required for Phase 1A.
abstract interface class InboxRepository {
  /// Persists a new [InboxItem] in the local SQLite database.
  Future<void> createInboxItem(InboxItem item);

  /// Exposes a stream of all persisted [InboxItem]s, sorted newest first.
  Stream<List<InboxItem>> watchInboxItems();
}
