import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/inbox/presentation/screens/inbox_screen.dart';
import '../../../features/notes/data/repositories/astra_note_repository.dart';
import '../../../models/task.dart';
import '../../../providers/task_provider.dart';

enum UnifiedResultType { task, note, chat, email }

class UnifiedSearchResultItem {
  final String id;
  final UnifiedResultType type;
  final String title;
  final String subtitle;
  final DateTime? timestamp;
  final Map<String, dynamic> metadata;

  const UnifiedSearchResultItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    this.timestamp,
    this.metadata = const {},
  });
}

class AstraUnifiedSearchService {
  /// Performs unified local search across Tasks, Notes, Chat Messages, and Inbox metadata.
  static Future<List<UnifiedSearchResultItem>> search({
    required dynamic ref,
    required String query,
  }) async {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return const [];

    final results = <UnifiedSearchResultItem>[];
    final dynamic r = ref;

    // 1. Search Tasks
    try {
      final tasksAsync = r.read(taskListProvider);
      final List<Task> tasks = (tasksAsync is AsyncValue<List<Task>>)
          ? (tasksAsync.value ?? const [])
          : (tasksAsync is List<Task> ? tasksAsync : const []);

      for (final t in tasks) {
        final matchTitle = t.title.toLowerCase().contains(trimmed);
        final matchDesc = (t.description ?? '').toLowerCase().contains(trimmed);
        final matchOrg = (t.organization ?? '').toLowerCase().contains(trimmed);

        if (matchTitle || matchDesc || matchOrg) {
          results.add(UnifiedSearchResultItem(
            id: t.id,
            type: UnifiedResultType.task,
            title: t.title,
            subtitle: t.description?.isNotEmpty == true ? t.description! : 'Priority: ${t.priority.toUpperCase()}',
            timestamp: t.dueDate ?? t.createdAt,
            metadata: {'status': t.status, 'priority': t.priority},
          ));
        }
      }
    } catch (_) {}

    // 2. Search Notes
    try {
      final notes = r.read(noteNotifierProvider);
      if (notes is List) {
        for (final n in notes) {
          final matchTitle = n.title.toLowerCase().contains(trimmed);
          final matchBody = n.body.toLowerCase().contains(trimmed);
          final matchTags = n.tags.any((tag) => tag.toString().toLowerCase().contains(trimmed));

          if (matchTitle || matchBody || matchTags) {
            results.add(UnifiedSearchResultItem(
              id: n.id,
              type: UnifiedResultType.note,
              title: n.title.isNotEmpty ? n.title : 'Untitled Note',
              subtitle: n.body,
              timestamp: n.updatedAt,
              metadata: {'isPinned': n.isPinned, 'tags': n.tags},
            ));
          }
        }
      }
    } catch (_) {}

    // 3. Search Inbox Emails (if loaded)
    try {
      final emailsAsync = r.read(inboxEmailsProvider);
      final emails = emailsAsync.value ?? const [];
      for (final e in emails) {
        final matchSubject = e.subject.toLowerCase().contains(trimmed);
        final matchSender = e.sender.toLowerCase().contains(trimmed);
        final matchSnippet = e.snippet.toLowerCase().contains(trimmed);

        if (matchSubject || matchSender || matchSnippet) {
          results.add(UnifiedSearchResultItem(
            id: e.id,
            type: UnifiedResultType.email,
            title: e.subject.isNotEmpty ? e.subject : 'No Subject',
            subtitle: 'From: ${e.sender} — ${e.snippet}',
            timestamp: e.date,
            metadata: {'sender': e.sender},
          ));
        }
      }
    } catch (_) {}

    // Sort by timestamp descending
    results.sort((a, b) {
      final tA = a.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
      final tB = b.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
      return tB.compareTo(tA);
    });

    return results;
  }
}
