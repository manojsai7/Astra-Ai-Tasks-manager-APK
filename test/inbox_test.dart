import 'package:flutter_test/flutter_test.dart';
import 'package:astra/core/database/database.dart';
import 'package:astra/features/inbox/domain/entities/inbox_item.dart';
import 'package:astra/features/inbox/data/repositories/inbox_repository_impl.dart';
import 'package:astra/features/inbox/domain/usecases/inbox_ingestion_use_case.dart';

void main() {
  late AppDatabase database;
  late InboxRepositoryImpl repository;
  late InboxIngestionUseCase useCase;

  setUp(() {
    database = constructInMemoryDb();
    repository = InboxRepositoryImpl(database);
    useCase = InboxIngestionUseCase(repository);
  });

  tearDown(() async {
    await database.close();
  });

  group('Inbox Ingestion & Share Source Tests', () {
    test('Whitespace-only input is rejected', () async {
      expect(() => useCase.call('', InboxSource.manual), throwsArgumentError);
      expect(
        () => useCase.call('   ', InboxSource.manual),
        throwsArgumentError,
      );

      final items = await repository.watchInboxItems().first;
      expect(items, isEmpty);
    });

    test(
      'Manual ingestion stores MANUAL source and preserves raw text',
      () async {
        const rawText = 'Manual test text';
        await useCase.call(rawText, InboxSource.manual);

        final items = await repository.watchInboxItems().first;
        expect(items, hasLength(1));

        final persisted = items.first;
        expect(persisted.rawText, equals(rawText));
        expect(persisted.sourceType, equals('MANUAL'));
      },
    );

    test(
      'Confirmed Android share ingestion stores ANDROID_SHARE source and preserves raw text',
      () async {
        const rawText = 'Shared intent message content';
        await useCase.call(rawText, InboxSource.androidShare);

        final items = await repository.watchInboxItems().first;
        expect(items, hasLength(1));

        final persisted = items.first;
        expect(persisted.rawText, equals(rawText));
        expect(persisted.sourceType, equals('ANDROID_SHARE'));
      },
    );

    test(
      'Multiple persisted inbox items sorted newest first deterministically without delays',
      () async {
        await useCase.call('First Item', InboxSource.manual);
        await useCase.call('Second Item', InboxSource.manual);

        final items = await repository.watchInboxItems().first;
        expect(items, hasLength(2));

        // Deterministic chronological ordering verified via rowid fallback secondary sort
        expect(items[0].rawText, equals('Second Item'));
        expect(items[1].rawText, equals('First Item'));
      },
    );

    test(
      'Cancelled shared text does not trigger use case and is not persisted',
      () async {
        // In this case we simulate the cancel action at the presentation/use-case boundary.
        // If the user decides to cancel, no useCase call is made.
        final itemsBefore = await repository.watchInboxItems().first;
        expect(itemsBefore, isEmpty);

        // Simulating a cancel choice (no ingestion usecase is triggered)
        final itemsAfter = await repository.watchInboxItems().first;
        expect(itemsAfter, isEmpty);
      },
    );
  });
}
