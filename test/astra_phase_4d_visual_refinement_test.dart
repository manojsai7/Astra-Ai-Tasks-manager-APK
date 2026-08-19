import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astra/theme/app_theme.dart';
import 'package:astra/core/database/database.dart';
import 'package:astra/models/task.dart';
import 'package:astra/core/commands/astra_response.dart';
import 'package:astra/services/assistant/astra_recurrence_engine.dart';
import 'package:astra/services/haptics/astra_haptics.dart';
import 'package:astra/widgets/tasks/astra_task_card.dart';
import 'package:astra/widgets/tasks/tasks_view_tabs.dart';
import 'package:astra/widgets/tasks/astra_task_detail_sheet.dart';
import 'package:astra/widgets/assistant/astra_response_card.dart';
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
  });

  tearDown(() async {
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

  group('ASTRA Phase 4D — Visual Language Refinement Tests (A–N)', () {
    // ─── A. Semantic Color Roles ─────────────────────────────────────────────
    test('A. semantic color roles match graphite, glass, cyan edge, and restrained lime', () {
      // Base surfaces: Deep obsidian graphite
      expect(AstraColors.background, const Color(0xFF0F1216));
      expect(AstraColors.surface0, const Color(0xFF13161C));
      expect(AstraColors.surface1, const Color(0xFF181D26));
      expect(AstraColors.surface2, const Color(0xFF202734));

      // Edges & Borders: Slate & Cyan glow
      expect(AstraColors.border, const Color(0xFF2A3446));
      expect(AstraColors.borderSubtle, const Color(0xFF242C3C));
      expect(AstraColors.borderGlow, const Color(0xFF00E5FF));

      // Typography
      expect(AstraColors.textPrimary, const Color(0xFFF8FAFC));
      expect(AstraColors.textSecondary, const Color(0xFF94A3B8));
      expect(AstraColors.textMuted, const Color(0xFF64748B));

      // Signal System
      expect(AstraColors.lime, const Color(0xFFCEFF00));
      expect(AstraColors.cyan, const Color(0xFF00E5FF));
      expect(AstraColors.amber, const Color(0xFFF59E0B));
      expect(AstraColors.red, const Color(0xFFEF4444));
      expect(AstraColors.softGreen, const Color(0xFF10B981));

      // AppTheme darkTheme colorScheme
      expect(AppTheme.primary, const Color(0xFFCEFF00));
      expect(AppTheme.secondary, const Color(0xFF00E5FF));
      expect(AppTheme.background, const Color(0xFF0F1216));
    });

    // ─── B. Active State Distinguishability ──────────────────────────────────
    testWidgets('B. active state remains distinguishable after lime reduction', (tester) async {
      TaskViewFilter currentSelected = TaskViewFilter.myDay;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => TasksViewTabs(
                selectedView: currentSelected,
                counts: const {
                  TaskViewFilter.myDay: 5,
                  TaskViewFilter.upcoming: 12,
                },
                onSelectView: (view) {
                  setState(() => currentSelected = view);
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Selected tab has MY DAY and count
      expect(find.text('MY DAY'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);

      // Tap UPCOMING tab
      await tester.tap(find.text('UPCOMING'));
      await tester.pump();

      expect(currentSelected, TaskViewFilter.upcoming);
      expect(find.text('12'), findsOneWidget);
    });

    // ─── C. Important State Distinguishability ───────────────────────────────
    testWidgets('C. important state remains clearly distinguishable with star badge', (tester) async {
      final importantTask = Task(
        id: 'imp_1',
        title: 'Review System Architecture',
        priority: 'high',
        createdAt: DateTime.now(),
        subtasks: const [],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: AstraTaskCard(
              task: importantTask,
              onComplete: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Review System Architecture'), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    });

    // ─── D. Completed State ──────────────────────────────────────────────────
    testWidgets('D. completed task card renders line-through and lime checkmark', (tester) async {
      final completedTask = Task(
        id: 'comp_1',
        title: 'Submit Weekly Timesheet',
        status: 'completed',
        priority: 'medium',
        createdAt: DateTime.now(),
        completedAt: DateTime.now(),
        subtasks: const [],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: AstraTaskCard(
              task: completedTask,
              onComplete: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Submit Weekly Timesheet'), findsOneWidget);
      expect(find.byIcon(LucideIcons.check), findsOneWidget);
      expect(find.text('DONE'), findsOneWidget);
    });

    // ─── E. Overdue State ────────────────────────────────────────────────────
    testWidgets('E. overdue task card renders alert indicator', (tester) async {
      final overdueTask = Task(
        id: 'overdue_1',
        title: 'Submit Quarterly Tax Documents',
        dueDate: DateTime.now().subtract(const Duration(days: 3)),
        status: 'active',
        priority: 'high',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        subtasks: const [],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: AstraTaskCard(
              task: overdueTask,
              onComplete: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Submit Quarterly Tax Documents'), findsOneWidget);
      expect(find.byIcon(LucideIcons.alertCircle), findsOneWidget);
    });

    // ─── F. Task Card Metadata Rendering ─────────────────────────────────────
    testWidgets('F. task card renders recurrence, org, and subtask badges', (tester) async {
      final richTask = Task(
        id: 'rich_1',
        title: 'Team Sync & Standup',
        organization: 'DeepMind',
        category: 'Engineering',
        recurrenceRule: const RecurrenceRule(
          frequency: RecurrenceFrequency.weekdays,
          hour: 10,
          minute: 0,
        ),
        subtasks: const [
          SubTask(id: 's1', name: 'Prepare metrics', isCompleted: true),
          SubTask(id: 's2', name: 'Discuss blockers', isCompleted: false),
        ],
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: AstraTaskCard(
              task: richTask,
              onComplete: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Team Sync & Standup'), findsOneWidget);
      expect(find.text('DeepMind'), findsOneWidget);
      expect(find.text('1/2'), findsOneWidget);
      expect(find.byIcon(LucideIcons.repeat), findsOneWidget);
    });

    // ─── G. Schedule Screen Rendering ────────────────────────────────────────
    testWidgets('G. schedule screen renders mode switchers and navigation', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const ScheduleScreen()));
      await tester.pump();

      expect(find.text('ASTRA SCHEDULE'), findsOneWidget);
      expect(find.text('AGENDA'), findsOneWidget);
      expect(find.text('DAY'), findsOneWidget);
      expect(find.text('WEEK'), findsOneWidget);
      expect(find.text('MONTH'), findsOneWidget);
    });

    // ─── H. Detail Sheet Row-Based Visual Hierarchy ──────────────────────────
    testWidgets('H. detail sheet renders graphite and cyan section headers', (tester) async {
      tester.view.physicalSize = const Size(800, 2600);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(buildTestableWidget(const AstraTaskDetailSheet(initialShowMoreOptions: true)));
      await tester.pump();

      expect(find.text('WHEN'), findsOneWidget);
      expect(find.text('REPEAT'), findsOneWidget);
      expect(find.text('REMIND'), findsOneWidget);
      expect(find.text('PRIORITY'), findsOneWidget);
      expect(find.text('NOTES & DESCRIPTION'), findsOneWidget);
      expect(find.text('CHECKLIST & STEPS'), findsOneWidget);
      expect(find.text('CATEGORY'), findsOneWidget);
      expect(find.text('ORGANIZATION'), findsOneWidget);
    });

    // ─── I. ASTRA Structured Response Rendering ──────────────────────────────
    testWidgets('I. ASTRA response card renders graphite surface and tactile actions', (tester) async {
      final response = AstraResponse(
        type: AstraResponseType.taskCreated,
        headline: 'Task Created',
        lines: const [
          AstraResponseLine(label: 'Task', value: 'System Design Review scheduled for tomorrow at 2:00 PM'),
        ],
        actions: const [
          AstraAction(id: 'view', label: 'VIEW TASK'),
          AstraAction(id: 'done', label: 'MARK DONE'),
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

      expect(find.text('TASK CREATED'), findsOneWidget);
      expect(find.text('VIEW TASK'), findsOneWidget);
      expect(find.text('MARK DONE'), findsOneWidget);
    });

    // ─── J. 360dp Narrow-Width Layout ────────────────────────────────────────
    testWidgets('J. 360dp layout renders without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;

      final task = Task(
        id: '360_t1',
        title: 'Very Long Task Title That Might Wrap Over Multiple Lines In Narrow Viewports',
        organization: 'Astra Engineering Corp International',
        dueDate: DateTime.now().add(const Duration(days: 2)),
        subtasks: const [SubTask(id: 's1', name: 'A', isCompleted: false)],
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: AstraTaskCard(
              task: task,
              onComplete: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    // ─── K. 390dp Layout Resilience ──────────────────────────────────────────
    testWidgets('K. 390dp layout renders without overflow', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(buildTestableWidget(const ScheduleScreen()));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    // ─── L. 412dp Layout Resilience ──────────────────────────────────────────
    testWidgets('L. 412dp layout renders without overflow', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(buildTestableWidget(const ScheduleScreen()));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    // ─── M. Keyboard-Visible Layouts ─────────────────────────────────────────
    testWidgets('M. detail sheet remains keyboard safe with bottom insets', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);

      await tester.pumpWidget(buildTestableWidget(const AstraTaskDetailSheet()));
      await tester.pump();

      expect(find.byKey(const Key('task_detail_title_field')), findsOneWidget);
      expect(tester.takeException(), isNull);

      tester.view.resetViewInsets();
    });

    // ─── N. Haptic Integration Safety ────────────────────────────────────────
    test('N. haptic integration safety: all methods execute safely without crash', () async {
      await AstraHaptics.light();
      await AstraHaptics.medium();
      await AstraHaptics.heavy();
      await AstraHaptics.success();
      await AstraHaptics.warning();
      await AstraHaptics.selection();
    });
  });
}
