import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database.dart';
import '../../../../providers/ritual_provider.dart';
import '../../domain/models/astra_note.dart';

class AstraNoteRepository {
  final AppDatabase db;
  AstraNoteRepository(this.db);

  Future<List<AstraNote>> loadAllNotes() async {
    final entries = await db.getAllNotes();
    return entries.map((e) => AstraNote.fromEntry(e)).toList();
  }

  Future<void> saveNote(AstraNote note) async {
    await db.upsertNote(note.toCompanion());
  }

  Future<void> deleteNote(String id) async {
    await db.deleteNoteById(id);
  }
}

final astraNoteRepositoryProvider = Provider<AstraNoteRepository>((ref) {
  final db = ref.read(databaseProvider);
  return AstraNoteRepository(db);
});

class NoteNotifier extends StateNotifier<List<AstraNote>> {
  final Ref ref;
  NoteNotifier(this.ref) : super(const []) {
    loadNotes();
  }

  Future<void> loadNotes() async {
    final repo = ref.read(astraNoteRepositoryProvider);
    final notes = await repo.loadAllNotes();
    state = notes;
  }

  Future<void> createNote(AstraNote note) async {
    final repo = ref.read(astraNoteRepositoryProvider);
    await repo.saveNote(note);
    await loadNotes();
  }

  Future<void> updateNote(AstraNote note) async {
    final updated = note.copyWith(updatedAt: DateTime.now());
    final repo = ref.read(astraNoteRepositoryProvider);
    await repo.saveNote(updated);
    await loadNotes();
  }

  Future<void> togglePin(String id) async {
    final note = state.firstWhere((n) => n.id == id, orElse: () => throw Exception('Note not found'));
    final updated = note.copyWith(isPinned: !note.isPinned);
    await updateNote(updated);
  }

  Future<void> toggleArchive(String id) async {
    final note = state.firstWhere((n) => n.id == id, orElse: () => throw Exception('Note not found'));
    final updated = note.copyWith(isArchived: !note.isArchived);
    await updateNote(updated);
  }

  Future<void> deleteNote(String id) async {
    final repo = ref.read(astraNoteRepositoryProvider);
    await repo.deleteNote(id);
    await loadNotes();
  }
}

final noteNotifierProvider = StateNotifierProvider<NoteNotifier, List<AstraNote>>((ref) {
  return NoteNotifier(ref);
});
