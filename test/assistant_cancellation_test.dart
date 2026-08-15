import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astra/providers/assistant_provider.dart';
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

  group('Assistant Stop / Request Cancellation Tests', () {
    test('1. Calling stopCommand cancels active loading state and outputs cancellation message', () async {
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

      final notifier = container.read(assistantStateProvider.notifier);

      // Start command and immediately trigger stop
      final future = notifier.sendCommand('sync my emails');
      notifier.stopCommand();
      await future;

      final state = container.read(assistantStateProvider);
      expect(state.isLoading, isFalse);
      expect(state.messages.any((m) => m.text == 'Request cancelled.'), isTrue);

      container.dispose();
      await db.close();
    });

    test('2. Cancelled task creation command discards late execution and does NOT write to database', () async {
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

      final notifier = container.read(assistantStateProvider.notifier);

      // Trigger command and immediately stop before executor completes
      final future = notifier.sendCommand('Microsoft interview Monday at 11am');
      notifier.stopCommand();
      await future;

      final tasks = await db.select(db.tasks).get();
      expect(tasks.isEmpty, isTrue, reason: 'Stop button must prevent task creation in database');

      final reminders = await db.select(db.reminders).get();
      expect(reminders.isEmpty, isTrue, reason: 'Stop button must prevent reminder creation in database');

      container.dispose();
      await db.close();
    });
  });
}
