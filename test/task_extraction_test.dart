import 'package:flutter_test/flutter_test.dart';
import 'package:astra/core/database/database.dart';
import 'package:astra/features/inbox/domain/entities/inbox_item.dart';
import 'package:astra/features/inbox/data/repositories/inbox_repository_impl.dart';
import 'package:astra/features/inbox/domain/usecases/inbox_ingestion_use_case.dart';
import 'package:astra/features/tasks/domain/entities/task.dart';
import 'package:astra/features/tasks/data/repositories/task_repository_impl.dart';
import 'package:astra/features/tasks/domain/usecases/confirm_task_use_case.dart';
import 'package:astra/features/tasks/domain/utils/temporal_resolver.dart';
import 'package:astra/features/tasks/data/services/fake_task_extraction_service.dart';

void main() {
  group('TemporalResolver Unit Tests', () {
    final refTime = DateTime(2026, 7, 13, 22, 30, 0); // Mon, July 13, 2026

    test('resolves today correctly', () {
      final resolved = TemporalResolver.resolve(
        dateExpression: 'today',
        timeExpression: null,
        referenceTime: refTime,
      );
      expect(resolved, isNotNull);
      expect(resolved!.year, equals(2026));
      expect(resolved.month, equals(7));
      expect(resolved.day, equals(13));
      expect(resolved.hour, equals(0));
      expect(resolved.minute, equals(0));
    });

    test('resolves tomorrow correctly', () {
      final resolved = TemporalResolver.resolve(
        dateExpression: 'tomorrow',
        timeExpression: '2:00 PM',
        referenceTime: refTime,
      );
      expect(resolved, isNotNull);
      expect(resolved!.year, equals(2026));
      expect(resolved.month, equals(7));
      expect(resolved.day, equals(14));
      expect(resolved.hour, equals(14));
      expect(resolved.minute, equals(0));
    });

    test('resolves DD Month format correctly', () {
      final resolved = TemporalResolver.resolve(
        dateExpression: '20 July',
        timeExpression: null,
        referenceTime: refTime,
      );
      expect(resolved, isNotNull);
      expect(resolved!.year, equals(2026));
      expect(resolved.month, equals(7));
      expect(resolved.day, equals(20));
    });

    test('resolves Month DD format correctly', () {
      final resolved = TemporalResolver.resolve(
        dateExpression: 'July 20',
        timeExpression: null,
        referenceTime: refTime,
      );
      expect(resolved, isNotNull);
      expect(resolved!.year, equals(2026));
      expect(resolved.month, equals(7));
      expect(resolved.day, equals(20));
    });

    test('ambiguous date remains unresolved (returns null)', () {
      final resolved = TemporalResolver.resolve(
        dateExpression: 'some day next week',
        timeExpression: null,
        referenceTime: refTime,
      );
      expect(resolved, isNull);
    });
  });

  group('Task Extraction & Ingestion Verification Tests', () {
    late AppDatabase database;
    late InboxRepositoryImpl inboxRepository;
    late InboxIngestionUseCase inboxUseCase;
    late TaskRepositoryImpl taskRepository;
    late ConfirmTaskUseCase confirmTaskUseCase;
    late FakeTaskExtractionService extractionService;

    setUp(() {
      database = constructInMemoryDb();
      inboxRepository = InboxRepositoryImpl(database);
      inboxUseCase = InboxIngestionUseCase(inboxRepository);
      taskRepository = TaskRepositoryImpl(database);
      confirmTaskUseCase = ConfirmTaskUseCase(taskRepository);
      extractionService = FakeTaskExtractionService();
    });

    tearDown(() async {
      await database.close();
    });

    test('AI proposal does not directly persist a Task', () async {
      const rawMessage =
          'Amazon is hiring for SDE interns. Apply before 20 July.';
      final refTime = DateTime.now();

      // Get proposal (simulating AI request)
      final proposal = await extractionService.extractTask(rawMessage, refTime);
      expect(proposal.title, equals('Apply for Amazon SDE Internship'));

      // Check database to ensure no task is persisted automatically
      final tasks = await taskRepository.watchTasks().first;
      expect(tasks, isEmpty);
    });

    test('confirmed proposal persists a Task', () async {
      final refTime = DateTime(2026, 7, 13);
      const rawMessage =
          'Amazon is hiring for SDE interns. Apply before 20 July.';

      final proposal = await extractionService.extractTask(rawMessage, refTime);

      final resolvedDue = TemporalResolver.resolve(
        dateExpression: proposal.dateExpression,
        timeExpression: proposal.timeExpression,
        referenceTime: refTime,
      );

      // Explicitly confirm task (simulating confirm button action)
      await confirmTaskUseCase(
        title: proposal.title,
        description: proposal.description,
        taskType: proposal.taskType,
        priority: proposal.priority,
        dueAt: resolvedDue,
        inboxItemId: 'mock-inbox-id',
      );

      final tasks = await taskRepository.watchTasks().first;
      expect(tasks, hasLength(1));

      final persisted = tasks.first;
      expect(persisted.title, equals('Apply for Amazon SDE Internship'));
      expect(persisted.taskType, equals(TaskType.application));
      expect(persisted.priority, equals(TaskPriority.high));
      expect(persisted.status, equals(TaskStatus.pending));
      expect(persisted.dueAt, equals(DateTime(2026, 7, 20)));
    });

    test('invalid/empty title is rejected', () async {
      expect(
        () => confirmTaskUseCase(
          title: '',
          taskType: TaskType.todo,
          priority: TaskPriority.medium,
        ),
        throwsArgumentError,
      );

      expect(
        () => confirmTaskUseCase(
          title: '   ',
          taskType: TaskType.todo,
          priority: TaskPriority.medium,
        ),
        throwsArgumentError,
      );
    });

    test('raw Inbox message remains unchanged after task extraction', () async {
      const rawMessage =
          'Amazon is hiring for SDE interns. Apply before 20 July.';
      await inboxUseCase(rawMessage, InboxSource.manual);

      // Verify inbox item is stored
      final inboxItemsBefore = await inboxRepository.watchInboxItems().first;
      expect(inboxItemsBefore, hasLength(1));
      final originalItem = inboxItemsBefore.first;
      expect(originalItem.rawText, equals(rawMessage));

      // Extract task
      final proposal = await extractionService.extractTask(
        originalItem.rawText,
        originalItem.receivedAt,
      );

      // Confirm task
      await confirmTaskUseCase(
        title: proposal.title,
        taskType: proposal.taskType,
        priority: proposal.priority,
        inboxItemId: originalItem.id,
      );

      // Verify task exists
      final tasks = await taskRepository.watchTasks().first;
      expect(tasks, hasLength(1));

      // Verify inbox item is completely untouched
      final inboxItemsAfter = await inboxRepository.watchInboxItems().first;
      expect(inboxItemsAfter, hasLength(1));
      expect(inboxItemsAfter.first.rawText, equals(rawMessage));
      expect(inboxItemsAfter.first.id, equals(originalItem.id));
    });
  });

  group('Fake Extraction Pipeline Integration Tests', () {
    test('fake extraction service drives the complete flow', () async {
      final db = constructInMemoryDb();
      final inboxRepository = InboxRepositoryImpl(db);
      final inboxUseCase = InboxIngestionUseCase(inboxRepository);
      final taskRepository = TaskRepositoryImpl(db);
      final confirmTaskUseCase = ConfirmTaskUseCase(taskRepository);
      final extractionService = FakeTaskExtractionService();

      // 1. Ingest raw item
      const rawMessage = 'Amazon is hiring for SDE interns. Apply before 20 July.';
      await inboxUseCase(rawMessage, InboxSource.manual);
      final inboxItems = await inboxRepository.watchInboxItems().first;
      expect(inboxItems, hasLength(1));

      // 2. Extract proposal
      final proposal = await extractionService.extractTask(
        inboxItems.first.rawText,
        inboxItems.first.receivedAt,
      );
      expect(proposal.title, contains('Amazon'));

      final resolvedDue = TemporalResolver.resolve(
        dateExpression: proposal.dateExpression,
        timeExpression: proposal.timeExpression,
        referenceTime: inboxItems.first.receivedAt,
      );

      // 3. Confirm task
      await confirmTaskUseCase(
        title: proposal.title,
        taskType: proposal.taskType,
        priority: proposal.priority,
        dueAt: resolvedDue,
        inboxItemId: inboxItems.first.id,
      );

      // 4. Verify persisted in TaskRepository
      final tasks = await taskRepository.watchTasks().first;
      expect(tasks, hasLength(1));
      expect(tasks.first.title, contains('Amazon'));

      await db.close();
    });
  });
}
