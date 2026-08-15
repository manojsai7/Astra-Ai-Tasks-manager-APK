import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astra/core/database/database.dart';
import 'package:astra/services/assistant/astra_memory_engine.dart';
import 'package:astra/services/assistant/astra_context_builder.dart';
import 'package:astra/services/assistant/astra_reference_resolver.dart';
import 'package:astra/services/assistant/astra_update_command.dart';
import 'helpers/test_database_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late AstraMemoryEngine memoryEngine;
  late AstraContextBuilder contextBuilder;
  const referenceResolver = AstraReferenceResolver();
  const updateParser = AstraUpdateParser();
  final refNow = DateTime(2026, 8, 15, 10, 0); // Saturday 10:00 AM

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = TestDatabaseHelper.createMemoryDatabase();
    memoryEngine = AstraMemoryEngine(db);
    contextBuilder = AstraContextBuilder(db: db, memoryEngine: memoryEngine);
  });

  tearDown(() async {
    await db.close();
  });

  group('ASTRA Phase M1: Memory, Context & Reference Resolution Tests', () {
    // A. Recent-message memory
    test('A. Recent-message memory saves and retrieves up to limit in chronological order', () async {
      final session = await db.into(db.chatSessions).insertReturning(
            ChatSessionsCompanion.insert(
              createdAt: refNow,
              updatedAt: refNow,
            ),
          );

      await memoryEngine.saveMessage(sessionId: session.id, role: 'user', content: 'Msg 1');
      await memoryEngine.saveMessage(sessionId: session.id, role: 'assistant', content: 'Msg 2');
      await memoryEngine.saveMessage(sessionId: session.id, role: 'user', content: 'Msg 3');

      final recent = await memoryEngine.getRecentMessages(sessionId: session.id, limit: 20);
      expect(recent.length, 3);
      expect(recent[0].content, 'Msg 1');
      expect(recent[1].content, 'Msg 2');
      expect(recent[2].content, 'Msg 3');
    });

    // B. Session isolation
    test('B. Session isolation: messages from session A do not leak into session B', () async {
      final s1 = await db.into(db.chatSessions).insertReturning(
            ChatSessionsCompanion.insert(createdAt: refNow, updatedAt: refNow),
          );
      final s2 = await db.into(db.chatSessions).insertReturning(
            ChatSessionsCompanion.insert(createdAt: refNow, updatedAt: refNow),
          );

      await memoryEngine.saveMessage(sessionId: s1.id, role: 'user', content: 'S1 Secret');
      await memoryEngine.saveMessage(sessionId: s2.id, role: 'user', content: 'S2 Data');

      final s1Messages = await memoryEngine.getRecentMessages(sessionId: s1.id);
      final s2Messages = await memoryEngine.getRecentMessages(sessionId: s2.id);

      expect(s1Messages.length, 1);
      expect(s1Messages.first.content, 'S1 Secret');
      expect(s2Messages.length, 1);
      expect(s2Messages.first.content, 'S2 Data');
    });

    // C. "it" resolution against single active task
    test('C. "it" resolution resolves to single active task', () async {
      await TestDatabaseHelper.insertTaskRow(
        db,
        id: 'task-exam-1',
        title: 'Microsoft Exam',
        dueAt: DateTime(2026, 8, 16, 10, 0),
        status: 'pending',
      );

      final context = await contextBuilder.buildContext(
        currentText: 'make it 11am',
        now: refNow,
      );

      final result = referenceResolver.resolveReference('make it 11am', context);
      expect(result.isResolved, isTrue);
      expect(result.resolvedTitle, 'Microsoft Exam');
      expect(result.resolvedTaskId, 'task-exam-1');
      expect(result.confidence, greaterThanOrEqualTo(0.90));
    });

    // D. "the exam" resolution against active tasks
    test('D. "the exam" resolution matches active task', () async {
      await TestDatabaseHelper.insertTaskRow(
        db,
        id: 'task-interview-1',
        title: 'Amazon Interview',
        dueAt: DateTime(2026, 8, 18, 14, 0),
        status: 'pending',
      );
      await TestDatabaseHelper.insertTaskRow(
        db,
        id: 'task-exam-2',
        title: 'Physics Exam',
        dueAt: DateTime(2026, 8, 17, 9, 0),
        status: 'pending',
      );

      final context = await contextBuilder.buildContext(
        currentText: 'move the exam to 2pm',
        now: refNow,
      );

      final result = referenceResolver.resolveReference('move the exam to 2pm', context);
      expect(result.isResolved, isTrue);
      expect(result.resolvedTitle, 'Physics Exam');
      expect(result.resolvedTaskId, 'task-exam-2');
    });

    // E. Organization-based resolution ("the Microsoft one")
    test('E. Organization-based resolution ("the Microsoft one")', () async {
      await TestDatabaseHelper.insertTaskRow(
        db,
        id: 'task-ms-1',
        title: 'Final Round Interview',
        organization: 'Microsoft',
        dueAt: DateTime(2026, 8, 17, 11, 0),
        status: 'pending',
      );
      await TestDatabaseHelper.insertTaskRow(
        db,
        id: 'task-gg-1',
        title: 'Technical Screen',
        organization: 'Google',
        dueAt: DateTime(2026, 8, 19, 15, 0),
        status: 'pending',
      );

      final context = await contextBuilder.buildContext(
        currentText: 'reschedule the Microsoft one to 3pm',
        now: refNow,
      );

      final result = referenceResolver.resolveReference('reschedule the Microsoft one to 3pm', context);
      expect(result.isResolved, isTrue);
      expect(result.resolvedTitle, 'Final Round Interview');
      expect(result.resolvedTaskId, 'task-ms-1');
    });

    // F. Ambiguous reference (multiple matching candidates)
    test('F. Ambiguous reference returns unresolved without guessing', () async {
      await TestDatabaseHelper.insertTaskRow(
        db,
        id: 'task-ex-1',
        title: 'Physics Exam',
        dueAt: DateTime(2026, 8, 17, 9, 0),
        status: 'pending',
      );
      await TestDatabaseHelper.insertTaskRow(
        db,
        id: 'task-ex-2',
        title: 'Maths Exam',
        dueAt: DateTime(2026, 8, 18, 9, 0),
        status: 'pending',
      );

      final context = await contextBuilder.buildContext(
        currentText: 'move the exam to 2pm',
        now: refNow,
      );

      final result = referenceResolver.resolveReference('move the exam to 2pm', context);
      expect(result.isResolved, isFalse);
      expect(result.reason, contains('Ambiguous'));
    });

    // G. Unresolved reference when no entities match
    test('G. Unresolved reference when no match exists', () async {
      final context = await contextBuilder.buildContext(
        currentText: 'move the meeting to 4pm',
        now: refNow,
      );

      final result = referenceResolver.resolveReference('move the meeting to 4pm', context);
      expect(result.isResolved, isFalse);
    });

    // H. Task reference resolution with structured memory
    test('H. Structured memory item can be retrieved and resolved', () {
      memoryEngine.storeMemory(
        AstraMemoryItem(
          id: 'mem-1',
          type: 'EVENT_REFERENCE',
          key: 'current_discussion',
          value: 'Chemistry Assignment',
          createdAt: refNow,
          updatedAt: refNow,
        ),
      );

      final mem = memoryEngine.getMemory('current_discussion');
      expect(mem, isNotNull);
      expect(mem!.value, 'Chemistry Assignment');
    });

    // I. Conversation -> UPDATE_TASK reference resolution
    test('I. Conversation context allows "make it 11am" to target previous entity for UPDATE_TASK', () async {
      final session = await db.into(db.chatSessions).insertReturning(
            ChatSessionsCompanion.insert(createdAt: refNow, updatedAt: refNow),
          );

      await memoryEngine.saveMessage(
        sessionId: session.id,
        role: 'user',
        content: 'I have a Microsoft exam tomorrow at 10',
      );

      final context = await contextBuilder.buildContext(
        currentText: 'make it 11am',
        sessionId: session.id,
        now: refNow,
      );

      final refResult = referenceResolver.resolveReference('make it 11am', context);
      expect(refResult.isResolved, isTrue);
      expect(refResult.resolvedTitle, 'Microsoft Exam');

      // Now feed resolved title into AstraUpdateParser
      final parsedUpdate = updateParser.parse(
        text: 'move ${refResult.resolvedTitle} to 11am',
        now: refNow,
      );
      expect(parsedUpdate.targetQuery, 'Microsoft Exam');
      expect(parsedUpdate.newDueAt, DateTime(2026, 8, 15, 11, 0));
      expect(parsedUpdate.requiresConfirmation, isFalse);
    });

    // J. Conversation -> CREATE_REMINDER reference resolution
    test('J. Conversation context allows "remind me about it" to identify entity', () async {
      final session = await db.into(db.chatSessions).insertReturning(
            ChatSessionsCompanion.insert(createdAt: refNow, updatedAt: refNow),
          );

      await memoryEngine.saveMessage(
        sessionId: session.id,
        role: 'user',
        content: 'I have an assignment due Friday',
      );

      final context = await contextBuilder.buildContext(
        currentText: 'remind me about it Thursday at 8pm',
        sessionId: session.id,
        now: refNow,
      );

      final refResult = referenceResolver.resolveReference('remind me about it Thursday at 8pm', context);
      expect(refResult.isResolved, isTrue);
      expect(refResult.resolvedTitle, 'Assignment');
    });
  });
}
