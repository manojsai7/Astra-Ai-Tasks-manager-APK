import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astra/providers/assistant_provider.dart';
import 'package:astra/providers/chat_session_provider.dart';
import 'package:astra/providers/ritual_provider.dart';
import 'package:astra/providers/task_provider.dart';
import 'package:astra/providers/reminder_provider.dart';
import 'package:astra/services/reminder_service.dart';
import 'package:astra/providers/intent_classifier_provider.dart';
import 'package:astra/providers/b1_classifier_provider.dart';
import 'helpers/test_database_helper.dart';
import 'helpers/test_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Chat History Restoration Tests (Bug 1)', () {
    test('Tapping/opening an existing session restores its messages and does not create a new session', () async {
      SharedPreferences.setMockInitialValues({});
      final db = TestDatabaseHelper.createMemoryDatabase();

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          reminderServiceProvider.overrideWithValue(ReminderService(db)),
          taskNotifierProvider.overrideWith((ref) => TaskNotifier(db, ReminderService(db))..loadTasks()),
          intentClassifierProvider.overrideWithValue(FakeIntentClassifierClient()),
          b1EventClassifierProvider.overrideWithValue(FakeB1EventClassifierClient()),
        ],
      );

      final sessionNotifier = container.read(chatSessionProvider.notifier);
      final assistantNotifier = container.read(assistantStateProvider.notifier);
      // Keep chatSessionProvider alive in tests
      container.listen(chatSessionProvider, (_, _) {});

      // Create session 1 and simulate user + assistant interaction
      final session1Id = await sessionNotifier.createSession(title: 'Exam Planning');
      container.read(currentSessionIdProvider.notifier).state = session1Id;
      assistantNotifier.addMessage('When is my exam?', isUser: true);
      assistantNotifier.addMessage('Your exam is tomorrow at 6 PM.');

      final session1DbMessages = await sessionNotifier.getMessages(session1Id);
      expect(session1DbMessages.length, 2);

      // Create session 2
      final session2Id = await sessionNotifier.createSession(title: 'Grocery List');
      container.read(currentSessionIdProvider.notifier).state = session2Id;
      assistantNotifier.clearMessages();
      assistantNotifier.addMessage('Add apples to grocery', isUser: true);
      assistantNotifier.addMessage('Added apples to grocery.');

      // Restore session 1
      container.read(currentSessionIdProvider.notifier).state = session1Id;
      await assistantNotifier.loadSessionMessages(session1Id);

      final state = container.read(assistantStateProvider);
      expect(state.messages.length, 2);
      expect(state.messages[0].text, 'When is my exam?');
      expect(state.messages[0].isUser, isTrue);
      expect(state.messages[1].text, 'Your exam is tomorrow at 6 PM.');
      expect(state.messages[1].isUser, isFalse);

      // Verify no extra sessions were created
      final allSessions = await db.select(db.chatSessions).get();
      expect(allSessions.length, 2);
      expect(allSessions.map((s) => s.id), containsAll([session1Id, session2Id]));

      container.dispose();
      await db.close();
    });
  });
}
