import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/note_item.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';
import 'note_detail_screen.dart';

class NotesScreen extends StatefulWidget {
  final VoidCallback? onOpenSettings;

  const NotesScreen({super.key, this.onOpenSettings});

  @override
  State<NotesScreen> createState() => NotesScreenState();
}

class NotesScreenState extends State<NotesScreen> {
  final StorageService _storage = StorageService();
  List<NoteItem> _notes = [];
  String _selectedFilter = 'all';
  bool _isLoading = true;

  final List<Map<String, String>> _tags = [
    {'id': 'all', 'label': 'All Notes'},
    {'id': 'quiz', 'label': 'Quizzes'},
    {'id': 'exam', 'label': 'Exams'},
    {'id': 'activity', 'label': 'Activities'},
    {'id': 'general', 'label': 'General'},
  ];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final list = await _storage.loadNotes();
    if (mounted) {
      setState(() {
        _notes = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _openAddNote({String tag = 'general'}) async {
    final res = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NoteDetailScreen(initialTag: tag),
        fullscreenDialog: true,
      ),
    );
    if (res == true) {
      loadData();
    }
  }

  Future<void> _openEditNote(NoteItem note) async {
    final res = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NoteDetailScreen(existingNote: note),
        fullscreenDialog: true,
      ),
    );
    if (res == true) {
      loadData();
    }
  }

  Future<void> _deleteNote(NoteItem note) async {
    await _storage.deleteNote(note.id);
    _notes.removeWhere((n) => n.id == note.id);
    setState(() {});
  }

  List<NoteItem> get _filteredNotes {
    if (_selectedFilter == 'all') return _notes;
    return _notes
        .where((n) => n.tag.toLowerCase() == _selectedFilter.toLowerCase())
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textDark = isDark ? AppColors.darkText : AppColors.textDark;
    final primary = Theme.of(context).primaryColor;
    final filtered = _filteredNotes;

    final pinnedNotes = filtered.where((n) => n.isPinned).toList();
    final otherNotes = filtered.where((n) => !n.isPinned).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: loadData,
          color: primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Bar
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.08)
                              : Colors.white.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.4),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          CupertinoIcons.doc_text_fill,
                          size: 20,
                          color: const Color(0xFF00B894),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Student Notes',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: textDark,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const Spacer(),
                      // Add Note shortcut
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => _openAddNote(
                          tag: _selectedFilter == 'all'
                              ? 'general'
                              : _selectedFilter,
                        ),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: primary.withOpacity(0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            CupertinoIcons.plus,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (widget.onOpenSettings != null)
                        GestureDetector(
                          onTap: widget.onOpenSettings,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.08)
                                  : Colors.white.withOpacity(0.65),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.4),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              CupertinoIcons.gear,
                              size: 18,
                              color: isDark
                                  ? Colors.white70
                                  : AppColors.textDark,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Hero Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Reviewers &\nstudy guides.',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
                      color: textDark,
                      height: 1.15,
                      letterSpacing: -1.0,
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Tags Filter Carousel
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: _tags.map((tag) {
                      final id = tag['id']!;
                      final isSelected = _selectedFilter == id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GlassPill(
                          label: tag['label']!,
                          isSelected: isSelected,
                          onTap: () => setState(() => _selectedFilter = id),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),

                // Notes Masonry Grid
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _isLoading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : filtered.isEmpty
                          ? _buildEmptyState(isDark, textDark)
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (pinnedNotes.isNotEmpty) ...[
                                  Row(
                                    children: [
                                      const Icon(
                                        CupertinoIcons.pin_fill,
                                        size: 14,
                                        color: AppColors.textMuted,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'PINNED REVIEWERS',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.8,
                                          color: isDark
                                              ? AppColors.darkTextMuted
                                              : AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  _buildTwoColumnGrid(
                                      pinnedNotes, isDark, textDark),
                                  const SizedBox(height: 24),
                                ],
                                if (otherNotes.isNotEmpty) ...[
                                  if (pinnedNotes.isNotEmpty)
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 12),
                                      child: Text(
                                        'ALL NOTES',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.8,
                                          color: isDark
                                              ? AppColors.darkTextMuted
                                              : AppColors.textMuted,
                                        ),
                                      ),
                                    ),
                                  _buildTwoColumnGrid(
                                      otherNotes, isDark, textDark),
                                ],
                              ],
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTwoColumnGrid(
    List<NoteItem> notesList,
    bool isDark,
    Color textDark,
  ) {
    final leftCol = <NoteItem>[];
    final rightCol = <NoteItem>[];

    for (int i = 0; i < notesList.length; i++) {
      if (i % 2 == 0) {
        leftCol.add(notesList[i]);
      } else {
        rightCol.add(notesList[i]);
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: leftCol
                .map((n) => _buildNoteCard(n, isDark, textDark))
                .toList(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: rightCol
                .map((n) => _buildNoteCard(n, isDark, textDark))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildNoteCard(NoteItem note, bool isDark, Color textDark) {
    final cardColor = Color(note.colorValue);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(22),
        opacity: isDark ? 0.22 : 0.65,
        onTap: () => _openEditNote(note),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Tag emoji/label + pin icon
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: cardColor.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        note.tagIcon,
                        size: 11,
                        color: cardColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        note.tag.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: cardColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (note.isPinned)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(
                      CupertinoIcons.pin_fill,
                      size: 13,
                      color: Color(0xFFFF9500),
                    ),
                  ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 20,
                  onPressed: () => _deleteNote(note),
                  child: const Icon(
                    CupertinoIcons.xmark_circle,
                    size: 14,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Title
            Text(
              note.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: textDark,
              ),
            ),
            const SizedBox(height: 6),

            // Body snippet
            Text(
              note.body,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),

            // Date & Subject footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (note.subject != null)
                  Expanded(
                    child: Text(
                      note.subject!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: cardColor,
                      ),
                    ),
                  )
                else
                  const Spacer(),
                Text(
                  note.formattedDate,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, Color textDark) {
    return GlassContainer(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      borderRadius: BorderRadius.circular(28),
      opacity: isDark ? 0.2 : 0.6,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF00B894).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.doc_text_fill,
              size: 30,
              color: Color(0xFF00B894),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _selectedFilter == 'all'
                ? 'No notes yet'
                : 'No $_selectedFilter notes found',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: textDark,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Keep formulas, quiz answers, and study notes ready at all times.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 18),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => _openAddNote(
              tag: _selectedFilter == 'all' ? 'general' : _selectedFilter,
            ),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Text(
                'Write Note',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

