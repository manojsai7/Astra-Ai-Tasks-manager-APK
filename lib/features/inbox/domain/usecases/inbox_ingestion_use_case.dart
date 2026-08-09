import 'package:uuid/uuid.dart';
import '../entities/inbox_item.dart';
import '../repositories/inbox_repository.dart';

/// Use case that manages new raw message ingestion into ASTRA's Inbox.
///
/// Under Phase 1B specifications:
///  - Rejects empty/whitespace strings.
///  - Preserves raw input exactly.
///  - Generates a UUID for tracking.
///  - Validates and requires the explicit [InboxSource] origin.
///  - Processing status defaults to RECEIVED.
class InboxIngestionUseCase {
  final InboxRepository _repository;
  final _uuid = const Uuid();

  InboxIngestionUseCase(this._repository);

  /// Executes raw text ingestion into the repository database.
  Future<void> call(String rawText, InboxSource source) async {
    final trimmed = rawText.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Input text cannot be empty or whitespace only.');
    }

    final now = DateTime.now();
    final item = InboxItem(
      id: _uuid.v4(),
      rawText: rawText, // Preserved exactly as input
      sourceType: source.value,
      processingStatus: 'RECEIVED',
      receivedAt: now,
      createdAt: now,
      updatedAt: now,
    );

    await _repository.createInboxItem(item);
  }
}
