import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../models/note_item.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';

class NoteDetailScreen extends StatefulWidget {
  final NoteItem? existingNote;
  final String initialTag;

  const NoteDetailScreen({
    super.key,
    this.existingNote,
    this.initialTag = 'general',
  });

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();

  late String _tag;
  late int _colorValue;
  late bool _isPinned;
  bool _isSaving = false;

  final StorageService _storage = StorageService();

  final List<Map<String, dynamic>> _tagOptions = [
    {'id': 'general', 'label': 'General', 'color': 0xFF5960A0},
    {'id': 'quiz', 'label': 'Quiz', 'color': 0xFFFF9500},
    {'id': 'exam', 'label': 'Exam', 'color': 0xFFFF3B30},
    {'id': 'activity', 'label': 'Activity', 'color': 0xFF00B894},
  ];

  final List<int> _colorPalette = [
    0xFF5960A0, // Indigo
    0xFF6C5CE7, // Purple
    0xFF00B894, // Mint
    0xFF0984E3, // Sky Blue
    0xFFFF9500, // Orange
    0xFFFF3B30, // Coral Red
    0xFFE84393, // Pink
    0xFF2D3436, // Slate
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingNote != null) {
      final n = widget.existingNote!;
      _titleCtrl.text = n.title;
      _bodyCtrl.text = n.body;
      _subjectCtrl.text = n.subject ?? '';
      _tag = n.tag;
      _colorValue = n.colorValue;
      _isPinned = n.isPinned;
    } else {
      _tag = widget.initialTag;
      _colorValue = 0xFF5960A0;
      _isPinned = false;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _subjectCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();

    if (title.isEmpty && body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note cannot be completely empty')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final note = NoteItem(
      id: widget.existingNote?.id ?? Uuid().v4(),
      title: title.isNotEmpty ? title : 'Untitled Note',
      body: body,
      createdAt: widget.existingNote?.createdAt ?? DateTime.now(),
      updatedAt: widget.existingNote != null ? DateTime.now() : null,
      tag: _tag,
      colorValue: _colorValue,
      isPinned: _isPinned,
      subject: _subjectCtrl.text.trim().isNotEmpty
          ? _subjectCtrl.text.trim()
          : null,
    );

    if (widget.existingNote != null) {
      await _storage.updateNote(note);
    } else {
      await _storage.addNote(note);
    }

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<void> _delete() async {
    if (widget.existingNote == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete Note?',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('Are you sure you want to delete this study note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF3B30),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _storage.deleteNote(widget.existingNote!.id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textDark = isDark ? AppColors.darkText : AppColors.textDark;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final primary = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF131524) : const Color(0xFFD7DBF5),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: AppTheme.getBackgroundGradient(
                    isDark ? 'dark' : 'lavender'),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Frosted Top Bar
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
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
                            CupertinoIcons.chevron_left,
                            size: 18,
                            color: textDark,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Pin toggle
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => setState(() => _isPinned = !_isPinned),
                        child: Container(
                          width: 40,
                          height: 40,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: _isPinned
                                ? const Color(0xFFFF9500).withOpacity(0.2)
                                : (isDark
                                    ? Colors.white.withOpacity(0.08)
                                    : Colors.white.withOpacity(0.65)),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _isPinned
                                  ? const Color(0xFFFF9500).withOpacity(0.6)
                                  : Colors.white.withOpacity(0.4),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            _isPinned
                                ? CupertinoIcons.pin_fill
                                : CupertinoIcons.pin,
                            size: 18,
                            color: _isPinned
                                ? const Color(0xFFFF9500)
                                : textDark,
                          ),
                        ),
                      ),
                      // Delete (if editing)
                      if (widget.existingNote != null)
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: _delete,
                          child: Container(
                            width: 40,
                            height: 40,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF3B30).withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              CupertinoIcons.trash,
                              size: 18,
                              color: Color(0xFFFF3B30),
                            ),
                          ),
                        ),
                      // Save button
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: _isSaving ? null : _save,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 9),
                          decoration: BoxDecoration(
                            color: primary,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: primary.withOpacity(0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Save',
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
                ),

                // Note Editor Content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tag pills row
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: _tagOptions.map((opt) {
                              final id = opt['id'] as String;
                              final isSel = _tag == id;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: GlassPill(
                                  label: opt['label'] as String,
                                  isSelected: isSel,
                                  activeColor: Color(opt['color'] as int),
                                  onTap: () => setState(() => _tag = id),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Title & Body Glass Canvas
                        GlassContainer(
                          padding: const EdgeInsets.all(22),
                          borderRadius: BorderRadius.circular(28),
                          opacity: isDark ? 0.22 : 0.65,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title input
                              TextField(
                                controller: _titleCtrl,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  fontFamily:
                                      GoogleFonts.plusJakartaSans().fontFamily,
                                  color: textDark,
                                  height: 1.2,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Note Title...',
                                  hintStyle: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: textMuted,
                                  ),
                                  border: InputBorder.none,
                                ),
                              ),
                              const Divider(height: 18),

                              // Optional Subject tag
                              TextField(
                                controller: _subjectCtrl,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: textDark,
                                ),
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(
                                    CupertinoIcons.tag,
                                    size: 16,
                                    color: AppColors.textMuted,
                                  ),
                                  prefixIconConstraints: const BoxConstraints(
                                      minWidth: 28, minHeight: 0),
                                  hintText: 'Subject tag (e.g. Bio 101, Midterms)',
                                  hintStyle: TextStyle(
                                    fontSize: 12,
                                    color: textMuted,
                                  ),
                                  border: InputBorder.none,
                                ),
                              ),
                              const Divider(height: 18),

                              // Body text input
                              TextField(
                                controller: _bodyCtrl,
                                maxLines: null,
                                minLines: 12,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: textDark,
                                  height: 1.5,
                                ),
                                decoration: InputDecoration(
                                  hintText:
                                      'Start writing study notes, key terms, formulas, or reminders...',
                                  hintStyle: TextStyle(
                                    fontSize: 15,
                                    color: textMuted,
                                  ),
                                  border: InputBorder.none,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Card Tint Palette
                        GlassContainer(
                          padding: const EdgeInsets.all(18),
                          borderRadius: BorderRadius.circular(24),
                          opacity: isDark ? 0.22 : 0.65,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'NOTE ACCENT COLOR',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: textMuted,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: _colorPalette.map((colVal) {
                                  final isSel = _colorValue == colVal;
                                  return GestureDetector(
                                    onTap: () =>
                                        setState(() => _colorValue = colVal),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 180),
                                      width: 34,
                                      height: 34,
                                      decoration: BoxDecoration(
                                        color: Color(colVal),
                                        shape: BoxShape.circle,
                                        border: isSel
                                            ? Border.all(
                                                color: Colors.white, width: 3)
                                            : null,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Color(colVal)
                                                .withOpacity(0.35),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: isSel
                                          ? const Icon(
                                              CupertinoIcons.check_mark,
                                              size: 16,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

