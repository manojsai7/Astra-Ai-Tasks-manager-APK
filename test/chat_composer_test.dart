import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:astra/widgets/assistant/astra_chat_composer.dart';
import 'package:astra/widgets/design_system/astra_3d_button.dart';

void main() {
  group('AstraChatComposer Widget Tests', () {
    testWidgets('A. short input renders correctly and enables send', (tester) async {
      final controller = TextEditingController();
      bool sent = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AstraChatComposer(
              controller: controller,
              onSend: () => sent = true,
              onStop: () {},
            ),
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(Astra3DIconButton), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Hello ASTRA');
      await tester.pumpAndSettle();

      expect(controller.text, 'Hello ASTRA');
      await tester.tap(find.byKey(const ValueKey('chat_send_button')));
      expect(sent, isTrue);
    });

    testWidgets('B. multiline input expands gracefully', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AstraChatComposer(
              controller: controller,
              onSend: () {},
              onStop: () {},
            ),
          ),
        ),
      );

      final initialHeight = tester.getSize(find.byType(AstraChatComposer)).height;

      await tester.enterText(
        find.byType(TextField),
        'Line 1\nLine 2\nLine 3\nLine 4',
      );
      await tester.pumpAndSettle();

      final multilineHeight = tester.getSize(find.byType(AstraChatComposer)).height;
      expect(multilineHeight, greaterThan(initialHeight));
      expect(multilineHeight, lessThanOrEqualTo(170.0)); // bounded by maxHeight + container padding
    });

    testWidgets('C. long input remains bounded by maxHeight', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AstraChatComposer(
              controller: controller,
              maxHeight: 140.0,
              onSend: () {},
              onStop: () {},
            ),
          ),
        ),
      );

      final longText = List.generate(40, (i) => 'This is line $i of a very long message').join('\n');
      await tester.enterText(find.byType(TextField), longText);
      await tester.pumpAndSettle();

      final composerSize = tester.getSize(find.byType(AstraChatComposer));
      // Max height constraint (140) + container top/bottom padding (18) + borders (3) = 161.0
      expect(composerSize.height, lessThanOrEqualTo(165.0));
      expect(composerSize.height, greaterThan(150.0));
    });

    testWidgets('D. send button remains present and clickable with long input', (tester) async {
      final controller = TextEditingController();
      bool sent = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AstraChatComposer(
              controller: controller,
              onSend: () => sent = true,
              onStop: () {},
            ),
          ),
        ),
      );

      final longNotice = '''
      MICROSOFT SWE INTERNSHIP 2026
      Requirements:
      - 3rd year or 4th year B.Tech/M.Tech
      - Proficient in DSA, C++, Java or Python
      - Strong knowledge of System Design, Databases, and OS
      - Application deadline: Friday, 22 August 2026, 5:00 PM IST
      - Location: Hyderabad / Bangalore
      Please submit resume and transcript at https://careers.microsoft.com
      ''';

      await tester.enterText(find.byType(TextField), longNotice);
      await tester.pumpAndSettle();

      final sendButton = find.byKey(const ValueKey('chat_send_button'));
      expect(sendButton, findsOneWidget);

      await tester.tap(sendButton);
      expect(sent, isTrue);
    });

    testWidgets('E. empty input disables send', (tester) async {
      final controller = TextEditingController(text: '   ');
      bool sent = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AstraChatComposer(
              controller: controller,
              onSend: () => sent = true,
              onStop: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('chat_send_button')));
      expect(sent, isFalse);
    });

    testWidgets('F. non-empty input enables send', (tester) async {
      final controller = TextEditingController();
      bool sent = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AstraChatComposer(
              controller: controller,
              onSend: () => sent = true,
              onStop: () {},
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Valid command');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('chat_send_button')));
      expect(sent, isTrue);
    });

    testWidgets('G. processing state shows STOP button and triggers onStop', (tester) async {
      final controller = TextEditingController(text: 'Working...');
      bool stopped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AstraChatComposer(
              controller: controller,
              isLoading: true,
              onSend: () {},
              onStop: () => stopped = true,
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('chat_stop_button')), findsOneWidget);
      expect(find.byKey(const ValueKey('chat_send_button')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('chat_stop_button')));
      expect(stopped, isTrue);
    });

    testWidgets('H. keyboard-safe layout inside Column with Expanded message list', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: 20,
                      itemBuilder: (ctx, i) => ListTile(title: Text('Message $i')),
                    ),
                  ),
                  AstraChatComposer(
                    controller: controller,
                    onSend: () {},
                    onStop: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Simulate keyboard open by adding viewInsets
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(AstraChatComposer), findsOneWidget);
      expect(find.byKey(const ValueKey('chat_send_button')), findsOneWidget);

      // Reset viewInsets
      tester.view.resetViewInsets();
    });

    testWidgets('I. no overflow for 10,000+ characters pasted notice', (tester) async {
      final controller = TextEditingController();
      final massiveText = 'A' * 12000;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Expanded(
                  child: ListView(
                    children: const [
                      Text('Previous messages'),
                    ],
                  ),
                ),
                AstraChatComposer(
                  controller: controller,
                  onSend: () {},
                  onStop: () {},
                ),
              ],
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), massiveText);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(AstraChatComposer), findsOneWidget);
      expect(find.byKey(const ValueKey('chat_send_button')), findsOneWidget);
    });
  });
}
