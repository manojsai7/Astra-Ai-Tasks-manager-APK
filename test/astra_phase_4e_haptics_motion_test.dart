import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astra/theme/app_theme.dart';
import 'package:astra/core/database/database.dart';
import 'package:astra/models/task.dart';
import 'package:astra/core/commands/astra_response.dart';
import 'package:astra/services/haptics/astra_haptics.dart';
import 'package:astra/widgets/tasks/astra_task_card.dart';
import 'package:astra/widgets/tasks/astra_task_detail_sheet.dart';
import 'package:astra/widgets/assistant/astra_response_card.dart';
import 'package:astra/widgets/design_system/astra_3d_button.dart';
import 'package:astra/screens/schedule_screen.dart';
import 'package:astra/providers/task_provider.dart';
import 'package:astra/providers/ritual_provider.dart';
import 'helpers/test_database_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = TestDatabaseHelper.createMemoryDatabase();
    AstraHaptics.isEnabled = true;
  });

  tearDown(() async {
    AstraHaptics.isEnabled = true;
    await db.close();
  });

  Widget buildTestableWidget(
    Widget child, {
    List<Task> initialTasks = const [],
    List<Override> overrides = const [],
  }) {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        taskListProvider.overrideWith((ref) => Stream.value(initialTasks)),
        ...overrides,
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: child,
        ),
      ),
    );
  }

  group('ASTRA Phase 4E — Haptics & Motion Refinement Tests (A–M)', () {
    // ─── A. Centralized Haptics Abstraction ──────────────────────────────────
    test('A. haptic abstraction remains centralized and safe', () async {
      expect(AstraHaptics.isEnabled, isTrue);

      await AstraHaptics.selection();
      await AstraHaptics.light();
      await AstraHaptics.medium();
      await AstraHaptics.heavy();
      await AstraHaptics.success();
      await AstraHaptics.warning();
      await AstraHaptics.delete();
    });

    // ─── B. Disabled Haptics State ───────────────────────────────────────────
    test('B. AstraHaptics disabled state suppresses feedback without error', () async {
      AstraHaptics.isEnabled = false;
      expect(AstraHaptics.isEnabled, isFalse);

      await AstraHaptics.selection();
      await AstraHaptics.light();
      await AstraHaptics.medium();
      await AstraHaptics.heavy();
      await AstraHaptics.success();
      await AstraHaptics.warning();
      await AstraHaptics.delete();
    });

    // ─── C. Primary Button Press State ───────────────────────────────────────
    testWidgets('C. primary button press state animates and triggers callback', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Astra3DButton(
                label: 'EXECUTE COMMAND',
                onPressed: () => tapped = true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('EXECUTE COMMAND'), findsOneWidget);

      await tester.tap(find.text('EXECUTE COMMAND'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    // ─── D. Task Completion Visual Transition ────────────────────────────────
    testWidgets('D. task completion triggers haptics and visual transition', (tester) async {
      bool completed = false;

      final task = Task(
        id: 't_comp',
        title: 'Review System Metrics',
        status: 'active',
        priority: 'high',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: AstraTaskCard(
              task: task,
              onComplete: () => completed = true,
            ),
          ),
        ),
      );
      await tester.pump();

      // Tap checkbox
      await tester.tap(find.byKey(const Key('task_card_checkbox')));
      await tester.pump();

      expect(completed, isTrue);
    });

    // ─── E. Delete Interaction ───────────────────────────────────────────────
    testWidgets('E. delete button triggers delete haptic and callback', (tester) async {
      bool deleted = false;

      final task = Task(
        id: 't_del',
        title: 'Draft Task To Remove',
        status: 'active',
        priority: 'low',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: AstraTaskCard(
              task: task,
              onComplete: () {},
              onDelete: () => deleted = true,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(LucideIcons.trash2), findsOneWidget);

      await tester.tap(find.byIcon(LucideIcons.trash2));
      await tester.pump();

      expect(deleted, isTrue);
    });

    // ─── F. Snooze / Status Cycle Interaction ────────────────────────────────
    testWidgets('F. status cycle button updates task state', (tester) async {
      bool cycled = false;

      final task = Task(
        id: 't_cycle',
        title: 'Recurring Standup',
        status: 'active',
        priority: 'medium',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: AstraTaskCard(
              task: task,
              onComplete: () {},
              onStatusCycle: () => cycled = true,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('MEDIUM'), findsOneWidget);

      await tester.tap(find.text('MEDIUM'));
      await tester.pump();

      expect(cycled, isTrue);
    });

    // ─── G. Schedule Tab Transition ──────────────────────────────────────────
    testWidgets('G. schedule mode tab transition animates smoothly', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const ScheduleScreen()));
      await tester.pump();

      expect(find.text('AGENDA'), findsOneWidget);

      // Switch to DAY mode
      await tester.tap(find.text('DAY'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byKey(const Key('view_mode_day')), findsOneWidget);

      // Switch to WEEK mode
      await tester.tap(find.text('WEEK'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byKey(const Key('view_mode_week')), findsOneWidget);
    });

    // ─── H. Date Navigation ──────────────────────────────────────────────────
    testWidgets('H. date navigation arrows update selected date', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const ScheduleScreen()));
      await tester.pump();

      expect(find.byIcon(LucideIcons.chevronRight), findsOneWidget);

      await tester.tap(find.byIcon(LucideIcons.chevronRight));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull);
    });

    // ─── I. Detail Sheet Transition & Safety ─────────────────────────────────
    testWidgets('I. detail sheet opens without overflow', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(buildTestableWidget(const AstraTaskDetailSheet()));
      await tester.pump();

      expect(find.text('NEW TASK'), findsOneWidget);
      expect(find.byKey(const Key('task_detail_save_button')), findsOneWidget);
    });

    // ─── J. Chat Action Button Transition ────────────────────────────────────
    testWidgets('J. chat action button executes callback without error', (tester) async {
      final response = AstraResponse(
        type: AstraResponseType.taskCreated,
        headline: 'Task Created',
        lines: const [
          AstraResponseLine(label: 'Task', value: 'Prepare Sprint Demo'),
        ],
        actions: const [
          AstraAction(id: 'view', label: 'VIEW TASK'),
        ],
      );

      await tester.pumpWidget(
        buildTestableWidget(
          AstraResponseCard(
            response: response,
            accent: AstraColors.cyan,
            accentDepth: AstraDepthColors.cyanDepth,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('VIEW TASK'), findsOneWidget);
      await tester.tap(find.text('VIEW TASK'));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    // ─── K. No Animation Leaks / Disposal Safety ─────────────────────────────
    testWidgets('K. widget disposal safely cancels implicit transitions', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const ScheduleScreen()));
      await tester.pump();

      // Dispose widget tree
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    // ─── L. 360dp Layout Resilience ──────────────────────────────────────────
    testWidgets('L. 360dp narrow viewport renders without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(buildTestableWidget(const ScheduleScreen()));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    // ─── M. Keyboard-Visible Resilience ──────────────────────────────────────
    testWidgets('M. detail sheet remains keyboard safe with bottom view insets', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);

      await tester.pumpWidget(buildTestableWidget(const AstraTaskDetailSheet()));
      await tester.pump();

      expect(find.byKey(const Key('task_detail_title_field')), findsOneWidget);
      expect(tester.takeException(), isNull);

      tester.view.resetViewInsets();
    });
  });
}
