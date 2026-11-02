import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../models/task_item.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/widget_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';

class AddTaskScreen extends StatefulWidget {
  final String initialType;
  final TaskItem? existingTask;

  const AddTaskScreen({
    super.key,
    this.initialType = 'quiz',
    this.existingTask,
  });

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _titleCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _subtaskCtrl = TextEditingController();

  late String _type;
  late int _priority; // 0=Low, 1=Med, 2=High
  late DateTime _dueDate;
  final List<String> _subtasks = [];
  bool _setReminder = true;
  bool _isSaving = false;

  final StorageService _storage = StorageService();
  final NotificationService _notifier = NotificationService();

  final List<Map<String, dynamic>> _taskTypes = [
    {'id': 'quiz', 'label': 'Quiz', 'icon': CupertinoIcons.question_circle_fill, 'color': 0xFFFF9500},
    {'id': 'exam', 'label': 'Exam', 'icon': CupertinoIcons.doc_text_fill, 'color': 0xFFFF3B30},
    {'id': 'activity', 'label': 'Activity', 'icon': CupertinoIcons.star_fill, 'color': 0xFF00B894},
    {'id': 'homework', 'label': 'Homework', 'icon': CupertinoIcons.book_fill, 'color': 0xFF0984E3},
    {'id': 'project', 'label': 'Project', 'icon': CupertinoIcons.folder_fill, 'color': 0xFF6C5CE7},
    {'id': 'reminder', 'label': 'Reminder', 'icon': CupertinoIcons.bell_fill, 'color': 0xFF5960A0},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingTask != null) {
      final t = widget.existingTask!;
      _titleCtrl.text = t.title;
      _subjectCtrl.text = t.subject ?? '';
      _notesCtrl.text = t.notes ?? '';
      _type = t.type;
      _priority = t.priority;
      _dueDate = t.dueDate;
      _subtasks.addAll(t.subtasks);
      _setReminder = t.notificationId != null;
    } else {
      _type = widget.initialType;
      _priority = 1;
      _dueDate = DateTime.now().add(const Duration(days: 1, hours: 2));
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subjectCtrl.dispose();
    _notesCtrl.dispose();
    _subtaskCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (d == null || !mounted) return;

    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dueDate),
    );
    if (t == null || !mounted) return;

    setState(() {
      _dueDate = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    });
  }

  void _addSubtask() {
    final text = _subtaskCtrl.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _subtasks.add(text);
        _subtaskCtrl.clear();
      });
    }
  }

  void _removeSubtask(int index) {
    setState(() => _subtasks.removeAt(index));
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a task or exam title')),
      );
      return;
    }

    setState(() => _isSaving = true);

    int? notifId = widget.existingTask?.notificationId;
    if (_setReminder && _dueDate.isAfter(DateTime.now())) {
      try {
        notifId ??= DateTime.now().millisecondsSinceEpoch.remainder(100000);
        await _notifier.scheduleNotification(
          id: notifId,
          title: 'Upcoming ${_type.toUpperCase()}: $title',
          body: _subjectCtrl.text.isNotEmpty
              ? '${_subjectCtrl.text} • Due ${DateFormat('h:mm a').format(_dueDate)}'
              : 'Due at ${DateFormat('h:mm a').format(_dueDate)}',
          scheduledDate: _dueDate.subtract(const Duration(minutes: 30)),
        );
      } catch (_) {}
    }

    final selectedTypeMeta = _taskTypes.firstWhere(
      (m) => m['id'] == _type,
      orElse: () => _taskTypes.first,
    );

    final task = TaskItem(
      id: widget.existingTask?.id ?? Uuid().v4(),
      title: title,
      type: _type,
      dueDate: _dueDate,
      subject: _subjectCtrl.text.trim().isNotEmpty
          ? _subjectCtrl.text.trim()
          : null,
      priority: _priority,
      isDone: widget.existingTask?.isDone ?? false,
      notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
      subtasks: _subtasks,
      colorValue: selectedTypeMeta['color'] as int,
      notificationId: notifId,
    );

    if (widget.existingTask != null) {
      await _storage.updateTask(task);
    } else {
      await _storage.addTask(task);
    }

    await WidgetService.syncAll();

    if (!mounted) return;
    Navigator.of(context).pop(true);
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
          // Background ambient gradient
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                            CupertinoIcons.xmark,
                            size: 16,
                            color: textDark,
                          ),
                        ),
                      ),
                      Text(
                        widget.existingTask != null
                            ? 'Edit Deadline'
                            : 'New Task & Deadline',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: textDark,
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: _isSaving ? null : _save,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
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

                // Form Content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category Type Selector
                        Text(
                          'CATEGORY',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: textMuted,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: _taskTypes.map((typeMeta) {
                              final id = typeMeta['id'] as String;
                              final isSelected = _type == id;
                              final color = Color(typeMeta['color'] as int);

                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: GestureDetector(
                                  onTap: () => setState(() => _type = id),
                                  behavior: HitTestBehavior.opaque,
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? color
                                          : (isDark
                                              ? Colors.white.withOpacity(0.08)
                                              : Colors.white.withOpacity(0.65)),
                                      borderRadius:
                                          BorderRadius.circular(18),
                                      border: Border.all(
                                        color: isSelected
                                            ? color.withOpacity(0.6)
                                            : Colors.white.withOpacity(0.4),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          typeMeta['icon'] as IconData,
                                          size: 14,
                                          color: isSelected
                                              ? Colors.white
                                              : color,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          typeMeta['label'] as String,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: isSelected
                                                ? FontWeight.w800
                                                : FontWeight.w600,
                                            color: isSelected
                                                ? Colors.white
                                                : textDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Title & Subject Card
                        GlassContainer(
                          padding: const EdgeInsets.all(20),
                          borderRadius: BorderRadius.circular(24),
                          opacity: isDark ? 0.22 : 0.65,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                controller: _titleCtrl,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: textDark,
                                ),
                                decoration: InputDecoration(
                                  hintText: _type == 'quiz'
                                      ? 'Quiz Title (e.g. Chapter 4 Quiz)'
                                      : (_type == 'exam'
                                          ? 'Exam Name (e.g. Midterm Exam)'
                                          : 'Title / Deliverable'),
                                  hintStyle: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: textMuted,
                                  ),
                                  border: InputBorder.none,
                                ),
                              ),
                              const Divider(height: 20),
                              TextField(
                                controller: _subjectCtrl,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: textDark,
                                ),
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(
                                    CupertinoIcons.book,
                                    size: 18,
                                    color: AppColors.textMuted,
                                  ),
                                  prefixIconConstraints: const BoxConstraints(
                                      minWidth: 32, minHeight: 0),
                                  hintText: 'Subject / Course (e.g. MATH 101)',
                                  hintStyle: TextStyle(
                                    fontSize: 13,
                                    color: textMuted,
                                  ),
                                  border: InputBorder.none,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Due Date Card
                        GlassContainer(
                          padding: const EdgeInsets.all(18),
                          borderRadius: BorderRadius.circular(24),
                          opacity: isDark ? 0.22 : 0.65,
                          onTap: _pickDueDate,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: primary.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  CupertinoIcons.calendar,
                                  size: 20,
                                  color: primary,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Due Date & Time',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: textMuted,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      DateFormat('EEEE, MMM d • h:mm a')
                                          .format(_dueDate),
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: textDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                CupertinoIcons.chevron_right,
                                size: 16,
                                color: textMuted,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Priority Level Card
                        GlassContainer(
                          padding: const EdgeInsets.all(18),
                          borderRadius: BorderRadius.circular(24),
                          opacity: isDark ? 0.22 : 0.65,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PRIORITY LEVEL',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: textMuted,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  _buildPriorityChip(0, 'Low', const Color(0xFF34C759)),
                                  const SizedBox(width: 10),
                                  _buildPriorityChip(1, 'Medium', const Color(0xFFFF9500)),
                                  const SizedBox(width: 10),
                                  _buildPriorityChip(2, 'High', const Color(0xFFFF3B30)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Subtasks / Checklist Card
                        GlassContainer(
                          padding: const EdgeInsets.all(18),
                          borderRadius: BorderRadius.circular(24),
                          opacity: isDark ? 0.22 : 0.65,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'PREPARATION STEPS / CHECKLIST',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
                                      color: textMuted,
                                    ),
                                  ),
                                  Text(
                                    '${_subtasks.length} items',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Subtask list
                              ..._subtasks.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final val = entry.value;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        CupertinoIcons.circle,
                                        size: 14,
                                        color: AppColors.textMuted,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          val,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: textDark,
                                          ),
                                        ),
                                      ),
                                      CupertinoButton(
                                        padding: EdgeInsets.zero,
                                        minSize: 24,
                                        onPressed: () => _removeSubtask(idx),
                                        child: const Icon(
                                          CupertinoIcons.minus_circle,
                                          size: 16,
                                          color: Color(0xFFFF3B30),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              // Add subtask input
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _subtaskCtrl,
                                      onSubmitted: (_) => _addSubtask(),
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: textDark,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Add a step (e.g. review formulas)...',
                                        hintStyle: TextStyle(
                                          fontSize: 12,
                                          color: textMuted,
                                        ),
                                        border: InputBorder.none,
                                      ),
                                    ),
                                  ),
                                  CupertinoButton(
                                    padding: EdgeInsets.zero,
                                    minSize: 32,
                                    onPressed: _addSubtask,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: primary.withOpacity(0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        CupertinoIcons.plus,
                                        size: 16,
                                        color: primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Additional Notes Card
                        GlassContainer(
                          padding: const EdgeInsets.all(18),
                          borderRadius: BorderRadius.circular(24),
                          opacity: isDark ? 0.22 : 0.65,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'NOTES & INSTRUCTIONS',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: textMuted,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _notesCtrl,
                                maxLines: 3,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: textDark,
                                ),
                                decoration: InputDecoration(
                                  hintText:
                                      'Add any special guidelines, zoom links, or syllabus notes...',
                                  hintStyle: TextStyle(
                                    fontSize: 13,
                                    color: textMuted,
                                  ),
                                  border: InputBorder.none,
                                ),
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

  Widget _buildPriorityChip(int level, String label, Color color) {
    final isSel = _priority == level;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _priority = level),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSel
                ? color
                : (isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.white.withOpacity(0.6)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSel ? color : Colors.white.withOpacity(0.4),
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
              color: isSel
                  ? Colors.white
                  : (isDark ? Colors.white70 : AppColors.textDark),
            ),
          ),
        ),
      ),
    );
  }
}

