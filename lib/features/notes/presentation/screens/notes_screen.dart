import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../services/haptics/astra_haptics.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/design_system/astra_3d_button.dart';
import '../../data/repositories/astra_note_repository.dart';
import '../widgets/astra_note_card.dart';
import '../widgets/astra_note_editor_sheet.dart';

enum NoteFilterTab { all, pinned, archived }

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  NoteFilterTab _selectedTab = NoteFilterTab.all;
  String _searchQuery = '';
  String? _selectedTagFilter;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allNotes = ref.watch(noteNotifierProvider);

    // Collect all available unique tags across notes
    final allTags = allNotes.expand((n) => n.tags).toSet().toList();

    // Filter notes
    final filteredNotes = allNotes.where((note) {
      // Tab filter
      if (_selectedTab == NoteFilterTab.pinned && !note.isPinned) return false;
      if (_selectedTab == NoteFilterTab.archived && !note.isArchived) return false;
      if (_selectedTab != NoteFilterTab.archived && note.isArchived) return false;

      // Tag filter
      if (_selectedTagFilter != null && !note.tags.contains(_selectedTagFilter)) return false;

      // Search query
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchTitle = note.title.toLowerCase().contains(q);
        final matchBody = note.body.toLowerCase().contains(q);
        final matchTags = note.tags.any((t) => t.toLowerCase().contains(q));
        if (!matchTitle && !matchBody && !matchTags) return false;
      }

      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AstraColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ASTRA', style: AstraText.label(size: 11, color: AstraColors.cyan)),
                      const SizedBox(height: 2),
                      Text('NOTES', style: AstraText.displayL(size: 32)),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AstraColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AstraColors.edgeSoft),
                    ),
                    child: Text(
                      '${filteredNotes.length} notes',
                      style: AstraText.label(size: 11, color: AstraColors.lime),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: Astra3DButton(
                      height: 42,
                      depth: AstraDepth.small,
                      color: AstraColors.lime,
                      depthColor: AstraDepthColors.limeDepth,
                      borderColor: AstraDepthColors.limeBorder,
                      onPressed: () => AstraNoteEditorSheet.show(context),
                      child: const Icon(LucideIcons.plus, size: 20, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AstraColors.surface0,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AstraColors.edgeSoft),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.search, size: 16, color: AstraColors.textMuted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(fontSize: 13, color: AstraColors.textPrimary),
                        decoration: const InputDecoration(
                          hintText: 'Search notes, tags, or content...',
                          hintStyle: TextStyle(color: AstraColors.textDisabled, fontSize: 13),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onChanged: (val) => setState(() => _searchQuery = val.trim()),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        child: const Icon(LucideIcons.x, size: 14, color: AstraColors.textMuted),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Filter Tabs & Tags Scroll
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _buildTabChip('All', NoteFilterTab.all),
                  const SizedBox(width: 6),
                  _buildTabChip('Pinned 📌', NoteFilterTab.pinned),
                  const SizedBox(width: 6),
                  _buildTabChip('Archived 📦', NoteFilterTab.archived),
                  if (allTags.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    const Text('|', style: TextStyle(color: AstraColors.edgeSoft)),
                    const SizedBox(width: 12),
                    ...allTags.map((tag) {
                      final isSelected = _selectedTagFilter == tag;
                      return GestureDetector(
                        onTap: () {
                          AstraHaptics.selection();
                          setState(() {
                            _selectedTagFilter = isSelected ? null : tag;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isSelected ? AstraColors.cyan.withValues(alpha: 0.2) : AstraColors.surface0,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? AstraColors.cyan : AstraColors.edgeSoft,
                            ),
                          ),
                          child: Text(
                            '#$tag',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? AstraColors.cyan : AstraColors.textMuted,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Notes List / Grid View
            Expanded(
              child: filteredNotes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.notebookPen, size: 36, color: AstraColors.textMuted),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isNotEmpty ? 'No notes matching "$_searchQuery"' : 'No notes here yet',
                            style: const TextStyle(fontSize: 14, color: AstraColors.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Tap + to create your first note or checklist',
                            style: TextStyle(fontSize: 11, color: AstraColors.textMuted),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                      itemCount: filteredNotes.length,
                      itemBuilder: (context, index) {
                        final note = filteredNotes[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: AstraNoteCard(
                            note: note,
                            onTap: () => AstraNoteEditorSheet.show(context, note: note),
                            onTogglePin: () => ref.read(noteNotifierProvider.notifier).togglePin(note.id),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabChip(String label, NoteFilterTab tab) {
    final isSelected = _selectedTab == tab;
    return GestureDetector(
      onTap: () {
        AstraHaptics.selection();
        setState(() => _selectedTab = tab);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AstraColors.surface1 : AstraColors.surface0,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AstraColors.lime : AstraColors.edgeSoft,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? AstraColors.lime : AstraColors.textMuted,
          ),
        ),
      ),
    );
  }
}
