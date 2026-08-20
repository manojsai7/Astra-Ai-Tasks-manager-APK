import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/database.dart';

class NoteChecklistItem {
  final String id;
  final String text;
  final bool isDone;

  const NoteChecklistItem({
    required this.id,
    required this.text,
    this.isDone = false,
  });

  NoteChecklistItem copyWith({
    String? id,
    String? text,
    bool? isDone,
  }) {
    return NoteChecklistItem(
      id: id ?? this.id,
      text: text ?? this.text,
      isDone: isDone ?? this.isDone,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'isDone': isDone,
      };

  factory NoteChecklistItem.fromJson(Map<String, dynamic> json) => NoteChecklistItem(
        id: json['id'] as String? ?? const Uuid().v4(),
        text: json['text'] as String? ?? '',
        isDone: json['isDone'] as bool? ?? false,
      );
}

class AstraNote {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPinned;
  final bool isArchived;
  final List<String> tags;
  final String? organization;
  final List<NoteChecklistItem> checklist;
  final List<String> links;

  const AstraNote({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
    this.isPinned = false,
    this.isArchived = false,
    this.tags = const [],
    this.organization,
    this.checklist = const [],
    this.links = const [],
  });

  factory AstraNote.create({
    required String title,
    required String body,
    List<String> tags = const [],
    String? organization,
    List<NoteChecklistItem> checklist = const [],
    List<String> links = const [],
    bool isPinned = false,
  }) {
    final now = DateTime.now();
    return AstraNote(
      id: const Uuid().v4(),
      title: title,
      body: body,
      createdAt: now,
      updatedAt: now,
      isPinned: isPinned,
      isArchived: false,
      tags: tags,
      organization: organization,
      checklist: checklist,
      links: links,
    );
  }

  AstraNote copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPinned,
    bool? isArchived,
    List<String>? tags,
    String? organization,
    bool clearOrganization = false,
    List<NoteChecklistItem>? checklist,
    List<String>? links,
  }) {
    return AstraNote(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      tags: tags ?? this.tags,
      organization: clearOrganization ? null : (organization ?? this.organization),
      checklist: checklist ?? this.checklist,
      links: links ?? this.links,
    );
  }

  factory AstraNote.fromEntry(NoteEntry entry) {
    List<String> parsedTags = [];
    try {
      final list = jsonDecode(entry.tagsJson) as List<dynamic>;
      parsedTags = list.map((e) => e.toString()).toList();
    } catch (_) {}

    List<NoteChecklistItem> parsedChecklist = [];
    try {
      final list = jsonDecode(entry.checklistJson) as List<dynamic>;
      parsedChecklist = list.map((e) => NoteChecklistItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {}

    List<String> parsedLinks = [];
    try {
      final list = jsonDecode(entry.linksJson) as List<dynamic>;
      parsedLinks = list.map((e) => e.toString()).toList();
    } catch (_) {}

    return AstraNote(
      id: entry.id,
      title: entry.title,
      body: entry.body,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
      isPinned: entry.isPinned,
      isArchived: entry.isArchived,
      tags: parsedTags,
      organization: entry.organization,
      checklist: parsedChecklist,
      links: parsedLinks,
    );
  }

  NotesCompanion toCompanion() {
    return NotesCompanion(
      id: Value(id),
      title: Value(title),
      body: Value(body),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      isPinned: Value(isPinned),
      isArchived: Value(isArchived),
      tagsJson: Value(jsonEncode(tags)),
      organization: Value(organization),
      checklistJson: Value(jsonEncode(checklist.map((c) => c.toJson()).toList())),
      linksJson: Value(jsonEncode(links)),
    );
  }
}
