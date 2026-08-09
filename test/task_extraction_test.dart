import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:astra/app/app.dart';
import 'package:astra/core/database/database.dart';
import 'package:astra/core/native_bridge/native_bridge.dart';
import 'package:astra/features/inbox/domain/entities/inbox_item.dart';
import 'package:astra/features/inbox/data/repositories/inbox_repository_impl.dart';
import 'package:astra/features/inbox/domain/usecases/inbox_ingestion_use_case.dart';
import 'package:astra/features/inbox/domain/services/clipboard_intake_service.dart';
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

  group('Fake Extraction UI Flow Widget Tests', () {
    testWidgets('fake extraction service drives the complete flow', (
      WidgetTester tester,
    ) async {
      // Mock NativeBridge channel to prevent native call exception
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('dev.codehunters.astra/share_bridge'),
        (methodCall) async => null,
      );

      final db = constructInMemoryDb();
      final inboxRepository = InboxRepositoryImpl(db);
      final inboxUseCase = InboxIngestionUseCase(inboxRepository);
      final taskRepository = TaskRepositoryImpl(db);
      final confirmTaskUseCase = ConfirmTaskUseCase(taskRepository);
      final extractionService = FakeTaskExtractionService();
      final nativeBridge = NativeBridge();
      final clipboardService = ClipboardIntakeService(
        clipboardGetter: () async => null,
      );

      // Populate an inbox item
      await inboxUseCase(
        'Amazon is hiring for SDE interns. Apply before 20 July.',
        InboxSource.manual,
      );

      final dependencies = Dependencies(
        database: db,
        inboxRepository: inboxRepository,
        inboxIngestionUseCase: inboxUseCase,
        nativeBridge: nativeBridge,
        clipboardIntakeService: clipboardService,
        taskRepository: taskRepository,
        confirmTaskUseCase: confirmTaskUseCase,
        taskExtractionService: extractionService,
      );

      await tester.pumpWidget(AstraApp(dependencies: dependencies));
      await tester.pumpAndSettle();

      // Go to Inbox
      await tester.tap(find.text('Go to Inbox'));
      await tester.pumpAndSettle();

      // Verify Inbox screen loaded and shows our item
      expect(find.text('Recent Raw Items'), findsOneWidget);
      expect(find.textContaining('Amazon is hiring'), findsOneWidget);

      // Tap Extract Task button
      final extractButtonFinder = find.text('Extract Task');
      expect(extractButtonFinder, findsOneWidget);
      await tester.tap(extractButtonFinder);

      // Pump to handle the async extraction call and page navigation
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Verify we navigated to TaskReviewScreen
      expect(find.text('Review Extracted Task'), findsOneWidget);

      // Verify title is prefilled correctly
      expect(find.text('Apply for Amazon SDE Internship'), findsOneWidget);

      // Tap Confirm Task button
      final confirmButtonFinder = find.text('Confirm Task');
      expect(confirmButtonFinder, findsOneWidget);
      await tester.tap(confirmButtonFinder);
      await tester.pumpAndSettle();

      // It should display SnackBar success and pop back to Inbox
      expect(find.text('Task saved successfully!'), findsOneWidget);
      expect(find.text('Recent Raw Items'), findsOneWidget);

      // Go back to HomeScreen
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      // Go to Tasks Screen
      await tester.tap(find.text('Go to Tasks'));
      await tester.pumpAndSettle();

      // Verify task shows up in list
      expect(find.text('Persisted Tasks'), findsOneWidget);
      expect(find.text('Apply for Amazon SDE Internship'), findsOneWidget);

      // Clean up
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('dev.codehunters.astra/share_bridge'),
        null,
      );
      await db.close();
    });
  });
}
