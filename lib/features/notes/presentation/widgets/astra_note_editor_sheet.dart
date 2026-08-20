import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../services/haptics/astra_haptics.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/design_system/astra_3d_button.dart';
import '../../data/repositories/astra_note_repository.dart';
import '../../domain/models/astra_note.dart';
import '../../domain/services/astra_note_action_service.dart';

class AstraNoteEditorSheet extends ConsumerStatefulWidget {
  final AstraNote? note;
  const AstraNoteEditorSheet({super.key, this.note});

  static Future<void> show(BuildContext context, {AstraNote? note}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AstraNoteEditorSheet(note: note),
    );
  }

  @override
  ConsumerState<AstraNoteEditorSheet> createState() => _AstraNoteEditorSheetState();
}

class _AstraNoteEditorSheetState extends ConsumerState<AstraNoteEditorSheet> {
  late TextEditingController _titleController;
  late TextEditingController _bodyController;
  late TextEditingController _tagInputController;
  late TextEditingController _checklistInputController;
  late TextEditingController _orgController;

  late bool _isPinned;
  late bool _isArchived;
  late List<String> _tags;
  late List<NoteChecklistItem> _checklist;
  late List<String> _links;

  String? _statusMessage;
  bool _isSuccessMessage = true;

  @override
  void initState() {
    super.initState();
    final n = widget.note;
    _titleController = TextEditingController(text: n?.title ?? '');
    _bodyController = TextEditingController(text: n?.body ?? '');
    _tagInputController = TextEditingController();
    _checklistInputController = TextEditingController();
    _orgController = TextEditingController(text: n?.organization ?? '');

    _isPinned = n?.isPinned ?? false;
    _isArchived = n?.isArchived ?? false;
    _tags = List.from(n?.tags ?? []);
    _checklist = List.from(n?.checklist ?? []);
    _links = List.from(n?.links ?? []);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _tagInputController.dispose();
    _checklistInputController.dispose();
    _orgController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    final org = _orgController.text.trim();

    if (title.isEmpty && body.isEmpty && _checklist.isEmpty) {
      Navigator.pop(context);
      return;
    }

    final notifier = ref.read(noteNotifierProvider.notifier);
    if (widget.note == null) {
      final newNote = AstraNote.create(
        title: title,
        body: body,
        tags: _tags,
        organization: org.isNotEmpty ? org : null,
        checklist: _checklist,
        links: _links,
        isPinned: _isPinned,
      );
      await notifier.createNote(newNote);
    } else {
      final updated = widget.note!.copyWith(
        title: title,
        body: body,
        isPinned: _isPinned,
        isArchived: _isArchived,
        tags: _tags,
        organization: org,
        clearOrganization: org.isEmpty,
        checklist: _checklist,
        links: _links,
      );
      await notifier.updateNote(updated);
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _handleConvertToTask() async {
    final tempNote = _buildCurrentNoteState();
    final taskId = await AstraNoteActionService.convertNoteToTask(ref, tempNote);
    if (mounted) {
      setState(() {
        _statusMessage = 'Converted to Task! (ID: ${taskId.substring(0, 8)})';
        _isSuccessMessage = true;
      });
    }
  }

  Future<void> _handleScheduleReminder() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (pickedTime == null || !mounted) return;

    final scheduledAt = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    final tempNote = _buildCurrentNoteState();
    await AstraNoteActionService.scheduleNoteReminder(ref, tempNote, scheduledAt);
    if (mounted) {
      setState(() {
        _statusMessage = 'Reminder scheduled for ${scheduledAt.month}/${scheduledAt.day} at ${pickedTime.format(context)}';
        _isSuccessMessage = true;
      });
    }
  }

  void _handleSaveToMemory() {
    final tempNote = _buildCurrentNoteState();
    AstraNoteActionService.storeNoteInMemory(ref, tempNote);
    setState(() {
      _statusMessage = 'Saved to Astra Memory Engine!';
      _isSuccessMessage = true;
    });
  }

  AstraNote _buildCurrentNoteState() {
    return widget.note?.copyWith(
          title: _titleController.text.trim(),
          body: _bodyController.text.trim(),
          tags: _tags,
          organization: _orgController.text.trim(),
          checklist: _checklist,
        ) ??
        AstraNote.create(
          title: _titleController.text.trim(),
          body: _bodyController.text.trim(),
          tags: _tags,
          organization: _orgController.text.trim().isNotEmpty ? _orgController.text.trim() : null,
          checklist: _checklist,
        );
  }

  void _addChecklistItem() {
    final text = _checklistInputController.text.trim();
    if (text.isEmpty) return;
    AstraHaptics.light();
    setState(() {
      _checklist.add(NoteChecklistItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: text,
      ));
      _checklistInputController.clear();
    });
  }

  void _addTag() {
    final tag = _tagInputController.text.trim().replaceAll('#', '');
    if (tag.isEmpty || _tags.contains(tag)) return;
    AstraHaptics.light();
    setState(() {
      _tags.add(tag);
      _tagInputController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.fromLTRB(12, 0, 12, 16 + bottomInset),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: BoxDecoration(
        color: AstraColors.surface0,
        borderRadius: BorderRadius.circular(AstraRadii.lg),
        border: Border.all(color: AstraColors.edge, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Controls: Pin, Archive, Delete, Close
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AstraColors.surface1,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AstraColors.edgeSoft),
                    ),
                    child: Text(
                      widget.note == null ? 'NEW NOTE' : 'EDIT NOTE',
                      style: AstraText.label(color: AstraColors.lime, size: 11),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      _isPinned ? LucideIcons.pin : LucideIcons.pinOff,
                      color: _isPinned ? AstraColors.lime : AstraColors.textMuted,
                      size: 18,
                    ),
                    onPressed: () => setState(() => _isPinned = !_isPinned),
                  ),
                  if (widget.note != null) ...[
                    IconButton(
                      icon: Icon(
                        _isArchived ? LucideIcons.archiveRestore : LucideIcons.archive,
                        color: _isArchived ? AstraColors.cyan : AstraColors.textMuted,
                        size: 18,
                      ),
                      onPressed: () => setState(() => _isArchived = !_isArchived),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.trash2, color: AstraColors.red, size: 18),
                      onPressed: () async {
                        AstraHaptics.medium();
                        await ref.read(noteNotifierProvider.notifier).deleteNote(widget.note!.id);
                        if (context.mounted) Navigator.pop(context);
                      },
                    ),
                  ],
                  IconButton(
                    icon: const Icon(LucideIcons.x, color: AstraColors.textMuted, size: 18),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Title TextField
              TextField(
                controller: _titleController,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AstraColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Note Title',
                  hintStyle: TextStyle(color: AstraColors.textDisabled, fontSize: 18, fontWeight: FontWeight.bold),
                  border: InputBorder.none,
                ),
              ),
              const Divider(color: AstraColors.edgeSoft, height: 16),

              // Body TextField
              TextField(
                controller: _bodyController,
                maxLines: 5,
                minLines: 2,
                style: const TextStyle(fontSize: 13.5, color: AstraColors.textSecondary, height: 1.4),
                decoration: const InputDecoration(
                  hintText: 'Type your notes, ideas, or thoughts here...',
                  hintStyle: TextStyle(color: AstraColors.textDisabled, fontSize: 13),
                  border: InputBorder.none,
                ),
              ),
              const SizedBox(height: 12),

              // Checklist Section
              if (_checklist.isNotEmpty) ...[
                const Text('CHECKLIST', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AstraColors.cyan, letterSpacing: 0.8)),
                const SizedBox(height: 6),
                ..._checklist.asMap().entries.map((e) {
                  final idx = e.key;
                  final item = e.value;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Checkbox(
                          value: item.isDone,
                          activeColor: AstraColors.lime,
                          onChanged: (val) {
                            setState(() {
                              _checklist[idx] = item.copyWith(isDone: val ?? false);
                            });
                          },
                        ),
                        Expanded(
                          child: Text(
                            item.text,
                            style: TextStyle(
                              fontSize: 13,
                              color: item.isDone ? AstraColors.textMuted : AstraColors.textPrimary,
                              decoration: item.isDone ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.x, size: 14, color: AstraColors.textMuted),
                          onPressed: () => setState(() => _checklist.removeAt(idx)),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),
              ],

              // Checklist Item Input Row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _checklistInputController,
                      style: const TextStyle(fontSize: 12, color: AstraColors.textPrimary),
                      decoration: const InputDecoration(
                        hintText: '+ Add checklist item...',
                        hintStyle: TextStyle(color: AstraColors.textDisabled, fontSize: 12),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      onSubmitted: (_) => _addChecklistItem(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.plus, color: AstraColors.lime, size: 18),
                    onPressed: _addChecklistItem,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Tags Row
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ..._tags.map((tag) => Chip(
                        label: Text('#$tag', style: const TextStyle(fontSize: 11, color: AstraColors.textPrimary)),
                        backgroundColor: AstraColors.surface1,
                        deleteIcon: const Icon(LucideIcons.x, size: 12, color: AstraColors.textMuted),
                        onDeleted: () => setState(() => _tags.remove(tag)),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      )),
                  SizedBox(
                    width: 100,
                    child: TextField(
                      controller: _tagInputController,
                      style: const TextStyle(fontSize: 11, color: AstraColors.textPrimary),
                      decoration: const InputDecoration(
                        hintText: '+ Tag',
                        hintStyle: TextStyle(color: AstraColors.textDisabled, fontSize: 11),
                        isDense: true,
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _addTag(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Cross-System Action Bar
              const Text('CROSS-SYSTEM ACTIONS', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AstraColors.textMuted, letterSpacing: 0.8)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AstraColors.lime,
                        side: BorderSide(color: AstraColors.lime.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onPressed: _handleConvertToTask,
                      icon: const Icon(LucideIcons.checkSquare, size: 14),
                      label: const Text('TASK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AstraColors.cyan,
                        side: BorderSide(color: AstraColors.cyan.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onPressed: _handleScheduleReminder,
                      icon: const Icon(LucideIcons.bell, size: 14),
                      label: const Text('REMIND', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AstraColors.softGreen,
                        side: BorderSide(color: AstraColors.softGreen.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onPressed: _handleSaveToMemory,
                      icon: const Icon(LucideIcons.brain, size: 14),
                      label: const Text('MEMORY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),

              if (_statusMessage != null) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _isSuccessMessage ? const Color(0x1ACEFF00) : AstraColors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _statusMessage!,
                    style: TextStyle(fontSize: 11, color: _isSuccessMessage ? AstraColors.lime : AstraColors.red),
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: Astra3DButton(
                  label: 'SAVE NOTE',
                  palette: AstraMaterials.lime,
                  height: 48,
                  onPressed: _handleSave,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
