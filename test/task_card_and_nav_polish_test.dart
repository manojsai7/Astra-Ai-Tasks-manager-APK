import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:astra/models/task.dart';
import 'package:astra/widgets/tasks/astra_task_card.dart';
import 'package:astra/widgets/premium/premium_bottom_nav.dart';
import 'package:astra/screens/tasks_screen.dart';
import 'package:astra/providers/task_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ASTRA UI Pass 2: Bottom Navigation & Task Card Polish Tests (A-K)', () {
    // ─── A. Bottom Navigation Safe Area ─────────────────────────────────────
    testWidgets('A. bottom navigation safe area and responsive height clamping', (tester) async {
      int selectedIndex = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: PremiumBottomNav(
              currentIndex: selectedIndex,
              onTap: (i) => selectedIndex = i,
            ),
          ),
        ),
      );

      expect(find.byType(PremiumBottomNav), findsOneWidget);
      expect(find.byType(SafeArea), findsOneWidget);
      expect(find.text('TASKS'), findsOneWidget);
      expect(find.text('HOME'), findsOneWidget);

      await tester.tap(find.text('TASKS'));
      await tester.pumpAndSettle();
      expect(selectedIndex, 1);
    });

    // ─── B. Last Task Fully Visible ─────────────────────────────────────────
    testWidgets('B. last task remains fully visible above navigation and quick add bar', (tester) async {
      final now = DateTime.now();
      final tasks = List.generate(
        12,
        (i) => Task(
          id: 'task_$i',
          title: 'Task Number $i',
          priority: i % 3 == 0 ? 'high' : (i % 3 == 1 ? 'medium' : 'low'),
          dueDate: DateTime(now.year, now.month, now.day, 12, 0).add(Duration(minutes: i)),
          createdAt: now,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            taskListProvider.overrideWith((ref) => Stream.value(tasks)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: TasksScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Drag list down to reach bottom
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();

      expect(find.text('Task Number 11'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ─── C. Long Title = 2 Lines + Ellipsis ──────────────────────────────────
    testWidgets('C. long task title is bounded to 2 lines with ellipsis', (tester) async {
      final task = Task(
        id: 'long_title_task',
        title: 'PPIs, Cash & MacBooks for Top Performers in Summer Internship 2026 Campus Drive by Microsoft Global Technologies and Development Center',
        description: 'Important coding round and placement information',
        organization: 'Microsoft Global Technologies',
        priority: 'high',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AstraTaskCard(
              task: task,
              onComplete: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AstraTaskCard), findsOneWidget);
      expect(find.text(task.title), findsOneWidget);

      final textWidget = tester.widget<Text>(find.text(task.title));
      expect(textWidget.maxLines, 2);
      expect(textWidget.overflow, TextOverflow.ellipsis);
      expect(tester.takeException(), isNull);
    });

    // ─── D. Long Description Bounded ─────────────────────────────────────────
    testWidgets('D. long description stays bounded with max 2 lines and ellipsis', (tester) async {
      final task = Task(
        id: 'long_desc_task',
        title: 'Submit Assignment',
        description: 'A very long description that spans multiple sentences and includes detailed instructions about file formatting, submission deadlines, code quality guidelines, and grading rubrics that should not take over the card.',
        priority: 'medium',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AstraTaskCard(
              task: task,
              onComplete: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(task.description!), findsOneWidget);
      final descWidget = tester.widget<Text>(find.text(task.description!));
      expect(descWidget.maxLines, 2);
      expect(descWidget.overflow, TextOverflow.ellipsis);
      expect(tester.takeException(), isNull);
    });

    // ─── E. Redundant Description Hidden ─────────────────────────────────────
    testWidgets('E. redundant description identical to title is hidden', (tester) async {
      final task = Task(
        id: 'redundant_desc_task',
        title: 'Dear students',
        description: 'Dear students',
        priority: 'low',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AstraTaskCard(
              task: task,
              onComplete: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Exactly one instance exists (the title). The description is omitted.
      expect(find.text('Dear students'), findsOneWidget);
    });

    // ─── F. Tiny Description Hidden ──────────────────────────────────────────
    testWidgets('F. malformed tiny description (e.g. "t") is hidden', (tester) async {
      final task = Task(
        id: 'malformed_desc_task',
        title: 'Complete Quiz',
        description: 't',
        priority: 'medium',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AstraTaskCard(
              task: task,
              onComplete: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Complete Quiz'), findsOneWidget);
      expect(find.text('t'), findsNothing);
    });

    // ─── G. Status and Priority Chips Don't Overlap ──────────────────────────
    testWidgets('G. status and priority chips render cleanly without overlap', (tester) async {
      final task = Task(
        id: 'chips_task',
        title: 'System Architecture Review',
        priority: 'high',
        organization: 'Astra Core Labs',
        dueDate: DateTime.now().add(const Duration(hours: 3)),
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AstraTaskCard(
              task: task,
              onComplete: () {},
              onStatusCycle: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('HIGH'), findsOneWidget);
      expect(find.text('Astra Core Labs'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ─── H. Delete Button Remains Visible ────────────────────────────────────
    testWidgets('H. delete button remains visible and aligned', (tester) async {
      bool deleted = false;
      final task = Task(
        id: 'delete_task',
        title: 'Task To Delete',
        priority: 'low',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AstraTaskCard(
              task: task,
              onComplete: () {},
              onDelete: () => deleted = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final deleteBtn = find.byTooltip('Delete task');
      expect(deleteBtn, findsOneWidget);
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();
      expect(deleted, isTrue);
    });

    // ─── I. Edit Sheet is Scrollable ─────────────────────────────────────────
    testWidgets('I. edit sheet is vertically scrollable when needed', (tester) async {
      final task = Task(
        id: 'edit_scroll_task',
        title: 'Detailed Project Task',
        description: 'Comprehensive line 1\nLine 2\nLine 3\nLine 4\nLine 5\nLine 6',
        priority: 'high',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            taskListProvider.overrideWith((ref) => Stream.value([task])),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: TasksScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Detailed Project Task'));
      await tester.pumpAndSettle();

      expect(find.text('TASK DETAILS'), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    // ─── J. Edit Sheet Remains Keyboard Safe ─────────────────────────────────
    testWidgets('J. edit sheet remains keyboard safe with bottom insets', (tester) async {
      final task = Task(
        id: 'edit_sheet_kb_task',
        title: 'Interview Preparation',
        description: 'Review Graphs & DP',
        priority: 'high',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            taskListProvider.overrideWith((ref) => Stream.value([task])),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: TasksScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Interview Preparation'));
      await tester.pumpAndSettle();

      expect(find.text('TASK DETAILS'), findsOneWidget);

      // Simulate keyboard open by adding 320px bottom inset
      tester.view.viewInsets = const FakeViewPadding(bottom: 320);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('task_detail_save_button')), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Reset insets
      tester.view.resetViewInsets();
    });

    // ─── K. Narrow-Width Layout Does Not Overflow ───────────────────────────
    testWidgets('K. narrow-width layouts (360dp, 390dp, 412dp) render without overflow', (tester) async {
      const widths = [360.0, 390.0, 412.0];

      final task = Task(
        id: 'narrow_screen_task',
        title: 'Super Long Engineering Task Name That Takes Multiple Lines On Narrow Screen',
        description: 'Detailed description with notes and instructions for testing density',
        organization: 'Super International Enterprise Solutions & Technology Group',
        priority: 'high',
        dueDate: DateTime.now().add(const Duration(hours: 4)),
        createdAt: DateTime.now(),
      );

      for (final width in widths) {
        tester.view.physicalSize = Size(width * 2.0, 780 * 2.0);
        tester.view.devicePixelRatio = 2.0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AstraTaskCard(
                task: task,
                onComplete: () {},
                onDelete: () {},
                onStatusCycle: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'Failed on width $width dp');
        expect(find.byType(AstraTaskCard), findsOneWidget);
      }

      // Reset screen size
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
