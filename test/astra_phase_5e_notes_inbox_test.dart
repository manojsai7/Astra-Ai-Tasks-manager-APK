import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:astra/core/database/database.dart';
import 'package:astra/features/notes/domain/models/astra_note.dart';
import 'package:astra/features/notes/data/repositories/astra_note_repository.dart';
import 'package:astra/features/notes/domain/services/astra_note_action_service.dart';
import 'package:astra/services/search/astra_unified_search_service.dart';
import 'package:astra/providers/astra_memory_provider.dart';
import 'package:astra/providers/ritual_provider.dart';
import 'package:astra/features/scheduler/data/services/gmail_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Phase 5E — Notes Domain & Serialization', () {
    test('AstraNote serialization & checklist parsing', () {
      final note = AstraNote.create(
        title: 'Project Roadmap',
        body: 'Build Notes + Inbox foundation',
        tags: ['Work', 'ASTRA'],
        organization: 'Engineering',
        checklist: const [
          NoteChecklistItem(id: 'c1', text: 'Drift schema v11', isDone: true),
          NoteChecklistItem(id: 'c2', text: 'Notes UI', isDone: false),
        ],
      );

      expect(note.title, equals('Project Roadmap'));
      expect(note.tags, contains('ASTRA'));
      expect(note.checklist.length, equals(2));
      expect(note.checklist.first.isDone, isTrue);

      final companion = note.toCompanion();
      expect(companion.title.value, equals('Project Roadmap'));
    });
  });

  group('Phase 5E — Drift Database Notes Persistence', () {
    test('upsertNote & getAllNotes retrieve persisted note with tags & checklist', () async {
      final note = AstraNote.create(
        title: 'Database Note',
        body: 'Stored in SQLite via Drift',
        tags: ['Database', 'SQLite'],
        isPinned: true,
      );

      await db.upsertNote(note.toCompanion());
      final retrievedEntries = await db.getAllNotes();

      expect(retrievedEntries.length, equals(1));
      final retrieved = AstraNote.fromEntry(retrievedEntries.first);
      expect(retrieved.title, equals('Database Note'));
      expect(retrieved.isPinned, isTrue);
      expect(retrieved.tags, contains('Database'));
    });

    test('deleteNoteById removes note from database', () async {
      final note = AstraNote.create(title: 'To Delete', body: 'Temp note');
      await db.upsertNote(note.toCompanion());

      var notes = await db.getAllNotes();
      expect(notes.length, equals(1));

      await db.deleteNoteById(note.id);
      notes = await db.getAllNotes();
      expect(notes.length, equals(0));
    });
  });

  group('Phase 5E — Cross-System Actions (Note -> Task/Reminder/Memory)', () {
    test('Note -> TaskIntent conversion creates executable task', () async {
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
      );
      addTearDown(container.dispose);

      final note = AstraNote.create(
        title: 'Study Machine Learning',
        body: 'Complete chapter 4 on decision trees',
        organization: 'Academics',
        checklist: const [
          NoteChecklistItem(id: '1', text: 'Read chapter', isDone: true),
          NoteChecklistItem(id: '2', text: 'Solve exercises', isDone: false),
        ],
      );

      final taskId = await AstraNoteActionService.convertNoteToTask(container, note);
      expect(taskId.isNotEmpty, isTrue);
    });

    test('Note -> AstraMemoryEngine stores note in structured memory', () {
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
      );
      addTearDown(container.dispose);

      final note = AstraNote.create(
        title: 'Exam Syllabus',
        body: 'Mathematics III exam on Thursday',
        tags: ['Exam'],
      );

      AstraNoteActionService.storeNoteInMemory(container, note);

      final memories = container.read(astraMemoryEngineProvider).memories;
      expect(memories.isNotEmpty, isTrue);
      expect(memories.first.value, contains('Mathematics III'));
    });
  });

  group('Phase 5E — Inbox Data & Note Conversion', () {
    test('Email -> AstraNote creates structured note with Email tag', () async {
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
      );
      addTearDown(container.dispose);

      final email = GmailMessageData(
        id: 'msg_101',
        threadId: 'th_101',
        snippet: 'Your application for Senior Developer position has been received.',
        date: DateTime.now(),
        bodyText: 'Full email body content',
        subject: 'Job Application Received',
        sender: 'hr@techcorp.com',
      );

      final newNote = AstraNote.create(
        title: 'Email: ${email.subject}',
        body: 'From: ${email.sender}\n\n${email.snippet}',
        tags: ['Email'],
        organization: 'Inbox',
      );

      await container.read(noteNotifierProvider.notifier).createNote(newNote);

      final notes = container.read(noteNotifierProvider);
      expect(notes.length, equals(1));
      expect(notes.first.title, contains('Job Application Received'));
      expect(notes.first.tags, contains('Email'));
    });
  });

  group('Phase 5E — Unified Search Service', () {
    test('AstraUnifiedSearchService returns matching Notes', () async {
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
      );
      addTearDown(container.dispose);

      // Create Note
      final note = AstraNote.create(title: 'Cybersecurity Lecture', body: 'Encryption & Hashing');
      await container.read(noteNotifierProvider.notifier).createNote(note);

      // Perform Unified Search
      final searchResults = await AstraUnifiedSearchService.search(
        ref: container,
        query: 'Cybersecurity',
      );

      expect(searchResults.isNotEmpty, isTrue);
      expect(searchResults.first.title, equals('Cybersecurity Lecture'));
      expect(searchResults.first.type, equals(UnifiedResultType.note));
    });
  });
}
