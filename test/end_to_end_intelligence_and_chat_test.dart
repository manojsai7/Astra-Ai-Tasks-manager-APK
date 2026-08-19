import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:astra/services/assistant/astra_document_analyzer.dart';
import 'package:astra/services/assistant/astra_intent_resolver.dart';
import 'package:astra/services/assistant/astra_semantic_engine.dart';
import 'package:astra/services/assistant/astra_memory_engine.dart';
import 'package:astra/widgets/assistant/astra_chat_composer.dart';
import 'package:astra/screens/assistant_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ASTRA End-to-End Intelligence & Chat Robustness Tests', () {
    // ─── A. Chat Layout Resilience ──────────────────────────────────────────

    testWidgets('A1. Composer handles 10,000+ character circular without overflow on 360dp screen', (tester) async {
      tester.view.physicalSize = const Size(360 * 2.0, 640 * 2.0);
      tester.view.devicePixelRatio = 2.0;

      final controller = TextEditingController();
      final repeatedNotice = 'Important circular notice line with instructions and details.\n' * 200;
      final longNotice = 'Dear students,\n$repeatedNotice';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  const Expanded(child: Center(child: Text('Message List'))),
                  AstraChatComposer(
                    controller: controller,
                    isLoading: false,
                    onSend: () {},
                    onStop: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      controller.text = longNotice;
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(AstraChatComposer), findsOneWidget);

      // Simulate keyboard open
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Reset
      tester.view.resetViewInsets();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // ─── B. Multi-Candidate Circular Ingestion ──────────────────────────────

    test('B1. Long circular extracts multiple distinct candidates', () {
      const circularText = '''
Dear students,
Microsoft assessment must be completed by Friday 5 PM.
NPTEL form closes Thursday at 4 PM.
Hackathon registration closes Wednesday.
Bring your ID for the workshop.
''';

      const analyzer = AstraDocumentAnalyzer();
      final now = DateTime(2026, 8, 17, 10, 0); // Monday
      final analysis = analyzer.analyze(circularText, now: now);

      expect(analysis.extractedItems.length, greaterThanOrEqualTo(3));

      // 1. Check Microsoft Assessment
      final msft = analysis.extractedItems.firstWhere(
        (i) => i.title.toLowerCase().contains('microsoft'),
        orElse: () => analysis.extractedItems.first,
      );
      expect(msft.title.toLowerCase(), contains('microsoft'));
      expect(msft.organization, 'Microsoft');
      expect(msft.actionRequired, isTrue);

      // 2. Check NPTEL Form
      final nptel = analysis.extractedItems.firstWhere(
        (i) => i.title.toLowerCase().contains('nptel'),
        orElse: () => analysis.extractedItems[1],
      );
      expect(nptel.title.toLowerCase(), contains('nptel'));
      expect(nptel.organization, 'NPTEL');

      // 3. Check Hackathon
      final hackathon = analysis.extractedItems.firstWhere(
        (i) => i.title.toLowerCase().contains('hackathon'),
        orElse: () => analysis.extractedItems.last,
      );
      expect(hackathon.title.toLowerCase(), contains('hackathon'));
    });

    // ─── C. Conversational Task & Reminder Parsing ──────────────────────────

    test('C1. "bruh i have exam today at 6pm" resolves to CREATE_TASK and Exam title', () {
      const input = 'bruh i have exam today at 6pm';
      const resolver = AstraIntentResolver();
      final resolved = resolver.resolve(text: input, ml: null);

      expect(resolved.intent, 'CREATE_TASK');

      const semanticEngine = AstraSemanticEngine();
      final now = DateTime(2026, 8, 18, 10, 0);
      final cmd = semanticEngine.resolve(
        text: input,
        intent: resolved.intent,
        now: now,
      );

      expect(cmd.title, 'Exam');
      expect(cmd.eventType, 'EXAM');
      expect(cmd.temporal.deadline?.hour ?? cmd.temporal.eventStart?.hour, 18);
    });

    test('C2. "remind me to drink water in the next 2 mins" resolves title and relative time', () {
      const input = 'remind me to drink water in the next 2 mins';
      const resolver = AstraIntentResolver();
      final resolved = resolver.resolve(text: input, ml: null);

      expect(resolved.intent, 'CREATE_REMINDER');

      const semanticEngine = AstraSemanticEngine();
      final now = DateTime(2026, 8, 18, 10, 0);
      final cmd = semanticEngine.resolve(
        text: input,
        intent: resolved.intent,
        now: now,
      );

      expect(cmd.title, 'Drink water');
      final scheduled = cmd.temporal.deadline ?? cmd.temporal.eventStart;
      expect(scheduled, isNotNull);
      expect(scheduled!.difference(now).inMinutes, 2);
    });

    test('C3. "don\'t let me forget the Microsoft interview tomorrow" extracts organization and title', () {
      const input = "don't let me forget the Microsoft interview tomorrow";
      const resolver = AstraIntentResolver();
      final resolved = resolver.resolve(text: input, ml: null);

      expect(resolved.intent, 'CREATE_REMINDER');

      const semanticEngine = AstraSemanticEngine();
      final now = DateTime(2026, 8, 18, 10, 0);
      final cmd = semanticEngine.resolve(
        text: input,
        intent: resolved.intent,
        now: now,
      );

      expect(cmd.organization, 'Microsoft');
      expect(cmd.title, contains('Interview'));
    });

    // ─── D. Query & Context Recall ──────────────────────────────────────────

    test('D1. "what is my Microsoft deadline?" resolves to QUERY_TASK', () {
      const input = 'what is my Microsoft deadline?';
      const resolver = AstraIntentResolver();
      final resolved = resolver.resolve(text: input, ml: null);

      expect(resolved.intent, 'QUERY_TASK');
    });

    test('D2. Memory Engine stores structured entity and allows recall', () {
      final memoryEngine = AstraMemoryEngine();
      final now = DateTime(2026, 8, 18, 10, 0);

      memoryEngine.storeMemory(
        AstraMemoryItem(
          id: 'task_msft_1',
          type: 'TASK_ENTITY',
          key: 'last_entity',
          value: 'Microsoft Assessment',
          createdAt: now,
          updatedAt: now,
          metadata: {
            'organization': 'Microsoft',
            'dueAt': DateTime(2026, 8, 21, 17, 0).toIso8601String(),
          },
        ),
      );

      final memories = memoryEngine.memories;
      expect(memories.length, 1);
      expect(memories.first.value, 'Microsoft Assessment');
      expect(memories.first.metadata?['organization'], 'Microsoft');
    });

    // ─── E. Full AssistantScreen Integration ────────────────────────────────

    testWidgets('E1. AssistantScreen renders header, empty state, and composer safely', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AssistantScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('ASTRA'), findsOneWidget);
      expect(find.byType(AstraChatComposer), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
