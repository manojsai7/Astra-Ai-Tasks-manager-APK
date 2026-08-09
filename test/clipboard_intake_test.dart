import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:astra/core/database/database.dart';
import 'package:astra/features/inbox/domain/entities/inbox_item.dart';
import 'package:astra/features/inbox/data/repositories/inbox_repository_impl.dart';
import 'package:astra/features/inbox/domain/usecases/inbox_ingestion_use_case.dart';
import 'package:astra/features/inbox/domain/services/clipboard_intake_service.dart';
import 'package:astra/features/inbox/presentation/widgets/clipboard_review_dialog.dart';
import 'package:astra/app/app.dart';
import 'package:astra/core/native_bridge/native_bridge.dart';
import 'package:astra/features/tasks/data/repositories/task_repository_impl.dart';
import 'package:astra/features/tasks/data/services/fake_task_extraction_service.dart';
import 'package:astra/features/tasks/domain/usecases/confirm_task_use_case.dart';

void main() {
  group('ClipboardIntakeService Unit Tests', () {
    test('empty clipboard content (null/whitespace) is ignored', () async {
      final service = ClipboardIntakeService(clipboardGetter: () async => null);

      final text = await service.getClipboardText();
      expect(text, isNull);
      expect(service.shouldPrompt(text), isFalse);

      final serviceEmpty = ClipboardIntakeService(
        clipboardGetter: () async => '   ',
      );
      final textEmpty = await serviceEmpty.getClipboardText();
      expect(textEmpty, equals('   '));
      expect(serviceEmpty.shouldPrompt(textEmpty), isFalse);
    });

    test('non-empty text clipboard content is proposed', () async {
      final service = ClipboardIntakeService(
        clipboardGetter: () async => 'Copied message',
      );

      final text = await service.getClipboardText();
      expect(text, equals('Copied message'));
      expect(service.shouldPrompt(text), isTrue);
    });

    test(
      'same clipboard content is not repeatedly proposed during the same runtime after Ignore/Processed',
      () async {
        final service = ClipboardIntakeService(
          clipboardGetter: () async => 'WhatsApp message text',
        );

        final text = await service.getClipboardText();
        expect(service.shouldPrompt(text), isTrue);

        // Simulate user ignoring or successfully ingesting the text
        service.markProcessed(text);

        // Same content should not prompt again
        expect(service.shouldPrompt(text), isFalse);

        // Different text should prompt
        expect(service.shouldPrompt('Different text'), isTrue);
      },
    );
  });

  group('Database Ingestion & Clipboard Integration Tests', () {
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

    test('clipboard source persists as CLIPBOARD', () async {
      const clipboardText = 'Ingested clipboard item text';
      await useCase.call(clipboardText, InboxSource.clipboard);

      final items = await repository.watchInboxItems().first;
      expect(items, hasLength(1));

      final persisted = items.first;
      expect(persisted.rawText, equals(clipboardText));
      expect(persisted.sourceType, equals('CLIPBOARD'));
    });

    test('confirmed edited clipboard text is preserved exactly', () async {
      const originalText = 'Raw copy from chat';
      const editedText = 'Cleaned up text for inbox';

      // Verify the edit is preserved exactly when calling usecase
      await useCase.call(editedText, InboxSource.clipboard);

      final items = await repository.watchInboxItems().first;
      expect(items, hasLength(1));

      final persisted = items.first;
      expect(persisted.rawText, equals(editedText));
      expect(persisted.rawText, isNot(equals(originalText)));
      expect(persisted.sourceType, equals('CLIPBOARD'));
    });
  });

  group('ClipboardReviewDialog Widget Tests', () {
    testWidgets('renders dialog with initial text and actions', (
      WidgetTester tester,
    ) async {
      String? resultText;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    resultText = await ClipboardReviewDialog.show(
                      context,
                      'Original Clipboard Text',
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('New Clipboard Text'), findsOneWidget);
      expect(find.text('Original Clipboard Text'), findsOneWidget);
      expect(find.text('Ignore'), findsOneWidget);
      expect(find.text('Add to Inbox'), findsOneWidget);

      // Tap Ignore
      await tester.tap(find.text('Ignore'));
      await tester.pumpAndSettle();

      expect(find.text('New Clipboard Text'), findsNothing);
      expect(resultText, isNull);
    });

    testWidgets('allows editing and returns confirmed edited text', (
      WidgetTester tester,
    ) async {
      String? resultText;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    resultText = await ClipboardReviewDialog.show(
                      context,
                      'Initial content',
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Find the TextField and edit it
      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget);

      await tester.enterText(textFieldFinder, 'Edited content');
      await tester.pumpAndSettle();

      // Tap Add to Inbox
      await tester.tap(find.text('Add to Inbox'));
      await tester.pumpAndSettle();

      expect(resultText, equals('Edited content'));
    });

    testWidgets(
      'disables Add to Inbox button when text is empty or whitespace only',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ClipboardReviewDialog(initialText: 'Original text'),
            ),
          ),
        );

        final addButtonFinder = find.widgetWithText(
          FilledButton,
          'Add to Inbox',
        );
        expect(addButtonFinder, findsOneWidget);

        // Button should be enabled initially
        var filledButton = tester.widget<FilledButton>(addButtonFinder);
        expect(filledButton.onPressed, isNotNull);

        // Edit text to empty
        await tester.enterText(find.byType(TextField), '');
        await tester.pump();

        filledButton = tester.widget<FilledButton>(addButtonFinder);
        expect(filledButton.onPressed, isNull);

        // Edit text to whitespace
        await tester.enterText(find.byType(TextField), '    ');
        await tester.pump();

        filledButton = tester.widget<FilledButton>(addButtonFinder);
        expect(filledButton.onPressed, isNull);

        // Edit back to valid text
        await tester.enterText(find.byType(TextField), 'valid');
        await tester.pump();

        filledButton = tester.widget<FilledButton>(addButtonFinder);
        expect(filledButton.onPressed, isNotNull);
      },
    );
  });

  group('AstraApp Clipboard Intake Lifecycle Integration', () {
    testWidgets('triggers dialog on startup if clipboard has new content', (
      WidgetTester tester,
    ) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('dev.codehunters.astra/share_bridge'),
        (methodCall) async {
          if (methodCall.method == 'getInitialShareText') {
            return null;
          }
          return null;
        },
      );

      final db = constructInMemoryDb();
      final repository = InboxRepositoryImpl(db);
      final useCase = InboxIngestionUseCase(repository);
      final nativeBridge = NativeBridge();

      final clipboardService = ClipboardIntakeService(
        clipboardGetter: () async => 'Clipboard message startup',
      );

      final taskRepository = TaskRepositoryImpl(db);
      final confirmTaskUseCase = ConfirmTaskUseCase(taskRepository);
      final taskExtractionService = FakeTaskExtractionService();

      final dependencies = Dependencies(
        database: db,
        inboxRepository: repository,
        inboxIngestionUseCase: useCase,
        nativeBridge: nativeBridge,
        clipboardIntakeService: clipboardService,
        taskRepository: taskRepository,
        confirmTaskUseCase: confirmTaskUseCase,
        taskExtractionService: taskExtractionService,
      );

      await tester.pumpWidget(AstraApp(dependencies: dependencies));
      await tester.pump();
      await tester.idle();
      await tester.pumpAndSettle();

      // It should trigger checking clipboard on startup and show the dialog
      expect(find.text('New Clipboard Text'), findsOneWidget);
      expect(find.text('Clipboard message startup'), findsOneWidget);

      // Clean up method handler
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('dev.codehunters.astra/share_bridge'),
        null,
      );
      await db.close();
    });

    testWidgets('triggers clipboard check and dialog on app resume', (
      WidgetTester tester,
    ) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('dev.codehunters.astra/share_bridge'),
        (methodCall) async => null,
      );

      final db = constructInMemoryDb();
      final repository = InboxRepositoryImpl(db);
      final useCase = InboxIngestionUseCase(repository);
      final nativeBridge = NativeBridge();

      String? currentClipboardText = 'First copy';
      final clipboardService = ClipboardIntakeService(
        clipboardGetter: () async => currentClipboardText,
      );

      final taskRepository = TaskRepositoryImpl(db);
      final confirmTaskUseCase = ConfirmTaskUseCase(taskRepository);
      final taskExtractionService = FakeTaskExtractionService();

      final dependencies = Dependencies(
        database: db,
        inboxRepository: repository,
        inboxIngestionUseCase: useCase,
        nativeBridge: nativeBridge,
        clipboardIntakeService: clipboardService,
        taskRepository: taskRepository,
        confirmTaskUseCase: confirmTaskUseCase,
        taskExtractionService: taskExtractionService,
      );

      await tester.pumpWidget(AstraApp(dependencies: dependencies));
      await tester.pump();
      await tester.idle();
      await tester.pumpAndSettle();

      // Startup prompt shows up
      expect(find.text('New Clipboard Text'), findsOneWidget);
      expect(find.text('First copy'), findsOneWidget);

      // Ignore it
      await tester.tap(find.text('Ignore'));
      await tester.pumpAndSettle();
      expect(find.text('New Clipboard Text'), findsNothing);

      // Simulate App Resuming with same content -> should NOT show dialog again
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.idle();
      await tester.pumpAndSettle();
      expect(find.text('New Clipboard Text'), findsNothing);

      // Simulate App Resuming with new content -> should show dialog
      currentClipboardText = 'Second copy';
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.idle();
      await tester.pumpAndSettle();
      expect(find.text('New Clipboard Text'), findsOneWidget);
      expect(find.text('Second copy'), findsOneWidget);

      // Clean up
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('dev.codehunters.astra/share_bridge'),
        null,
      );
      await db.close();
    });
  });
}
