// ASTRA — Foundation smoke test
//
// Verifies that AstraApp pumps without crashing and that the
// HomeScreen renders the ASTRA title.

import 'package:flutter_test/flutter_test.dart';

import 'package:astra/app/app.dart';
import 'package:astra/core/database/database.dart';
import 'package:astra/core/native_bridge/native_bridge.dart';
import 'package:astra/features/inbox/data/repositories/inbox_repository_impl.dart';
import 'package:astra/features/inbox/domain/services/clipboard_intake_service.dart';
import 'package:astra/features/inbox/domain/usecases/inbox_ingestion_use_case.dart';
import 'package:astra/features/tasks/data/repositories/task_repository_impl.dart';
import 'package:astra/features/tasks/data/services/fake_task_extraction_service.dart';
import 'package:astra/features/tasks/domain/usecases/confirm_task_use_case.dart';

void main() {
  testWidgets('AstraApp renders without errors', (WidgetTester tester) async {
    final db = constructInMemoryDb();
    final repository = InboxRepositoryImpl(db);
    final useCase = InboxIngestionUseCase(repository);
    final nativeBridge = NativeBridge();
    final clipboardService = ClipboardIntakeService();
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

    // HomeScreen should display the ASTRA wordmark.
    expect(find.text('ASTRA'), findsWidgets);

    // Clean up the database connection
    await db.close();
  });
}
