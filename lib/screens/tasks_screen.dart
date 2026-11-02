import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/task_item.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/widget_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';
import 'add_task_screen.dart';

class TasksScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onOpenSettings;
  final String initialFilter;

  const TasksScreen({
    super.key,
    this.onBack,
    this.onOpenSettings,
    this.initialFilter = 'All',
  });

  @override
  State<TasksScreen> createState() => TasksScreenState();
}

class TasksScreenState extends State<TasksScreen> {
  final StorageService _storage = StorageService();
  final NotificationService _notifier = NotificationService();

  List<TaskItem> _tasks = [];
  String _selectedFilter = 'All';
  bool _isLoading = true;

  final List<Map<String, String>> _filterTabs = [
    {'id': 'All', 'label': 'All Tasks'},
    {'id': 'quiz', 'label': 'Quizzes'},
    {'id': 'exam', 'label': 'Exams'},
    {'id': 'activity', 'label': 'Activities'},
    {'id': 'homework', 'label': 'Homework'},
    {'id': 'done', 'label': 'Completed'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter;
    loadData();
  }

  void setFilter(String filter) {
    setState(() => _selectedFilter = filter);
  }

  Future<void> loadData() async {
    final list = await _storage.loadTasks();
    if (mounted) {
      setState(() {
        _tasks = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _openAddTask({String initialType = 'quiz'}) async {
    final res = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddTaskScreen(initialType: initialType),
        fullscreenDialog: true,
      ),
    );
    if (res == true) {
      loadData();
    }
  }

  Future<void> _openEditTask(TaskItem task) async {
    final res = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddTaskScreen(existingTask: task),
        fullscreenDialog: true,
      ),
    );
    if (res == true) {
      loadData();
    }
  }

  Future<void> _toggleDone(TaskItem task) async {
    task.isDone = !task.isDone;
    await _storage.updateTask(task);
    await WidgetService.syncAll();
    setState(() {});
  }

  Future<void> _deleteTask(TaskItem task) async {
    if (task.notificationId != null) {
      await _notifier.cancel(task.notificationId!);
    }
    await _storage.deleteTask(task.id);
    _tasks.removeWhere((t) => t.id == task.id);
    await WidgetService.syncAll();
    setState(() {});
  }

  List<TaskItem> get _filteredTasks {
    if (_selectedFilter == 'done') {
      return _tasks.where((t) => t.isDone).toList();
    }
    final active = _tasks.where((t) => !t.isDone).toList();
    if (_selectedFilter == 'All') {
      // Sort: high priority first, then closest due date
      active.sort((a, b) {
        if (a.priority != b.priority) {
          return b.priority.compareTo(a.priority);
        }
        return a.dueDate.compareTo(b.dueDate);
      });
      return active;
    }
    return active.where((t) => t.type.toLowerCase() == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textDark = isDark ? AppColors.darkText : AppColors.textDark;
    final primary = Theme.of(context).primaryColor;
    final filtered = _filteredTasks;

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
                      if (widget.onBack != null)
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: widget.onBack,
                          child: Container(
                            width: 40,
                            height: 40,
                            margin: const EdgeInsets.only(right: 12),
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
                          CupertinoIcons.checkmark_shield_fill,
                          size: 20,
                          color: const Color(0xFFFF9500),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Tasks & Deadlines',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: textDark,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const Spacer(),
                      // Add task shortcut
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => _openAddTask(
                          initialType: _selectedFilter == 'All' ||
                                  _selectedFilter == 'done'
                              ? 'quiz'
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
                    'Track exams,\nquizzes & tasks.',
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

                // Filter Tabs Carousel
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: _filterTabs.map((tab) {
                      final id = tab['id']!;
                      final isSelected = _selectedFilter == id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GlassPill(
                          label: tab['label']!,
                          isSelected: isSelected,
                          onTap: () => setState(() => _selectedFilter = id),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),

                // Tasks List
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
                              children: filtered.map((task) {
                                return _buildTaskCardItem(
                                    task, isDark, textDark, primary);
                              }).toList(),
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCardItem(
    TaskItem task,
    bool isDark,
    Color textDark,
    Color primary,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GlassContainer(
        padding: const EdgeInsets.all(18),
        borderRadius: BorderRadius.circular(24),
        opacity: isDark ? 0.22 : 0.65,
        onTap: () => _openEditTask(task),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Type Pill, Subject, Priority Badge, Delete
            Row(
              children: [
                // Category Pill
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Color(task.colorValue).withOpacity(0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        task.typeIcon,
                        size: 11,
                        color: Color(task.colorValue),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        task.typeLabel.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Color(task.colorValue),
                        ),
                      ),
                    ],
                  ),
                ),
                if (task.subject != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    task.subject!,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
                const Spacer(),
                // Priority Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: task.priorityColor.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    task.priorityLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: task.priorityColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Delete button
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 26,
                  onPressed: () => _deleteTask(task),
                  child: const Icon(
                    CupertinoIcons.trash,
                    size: 15,
                    color: Color(0xFFFF3B30),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Middle: Checkbox + Title
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => _toggleDone(task),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 26,
                    height: 26,
                    margin: const EdgeInsets.only(top: 2, right: 12),
                    decoration: BoxDecoration(
                      color: task.isDone ? primary : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: task.isDone
                            ? primary
                            : (isDark ? Colors.white38 : Colors.black26),
                        width: 2,
                      ),
                    ),
                    child: task.isDone
                        ? const Icon(
                            CupertinoIcons.check_mark,
                            size: 14,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          decoration: task.isDone
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          color: task.isDone
                              ? AppColors.textMuted
                              : textDark,
                        ),
                      ),
                      if (task.notes != null && task.notes!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          task.notes!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Bottom Row: Due date countdown & Subtask progress
            Row(
              children: [
                Icon(
                  CupertinoIcons.time,
                  size: 13,
                  color: task.isOverdue
                      ? const Color(0xFFFF3B30)
                      : AppColors.textMuted,
                ),
                const SizedBox(width: 5),
                Text(
                  task.dueFormatted,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: task.isOverdue
                        ? const Color(0xFFFF3B30)
                        : AppColors.textMuted,
                  ),
                ),
                if (task.subtasks.isNotEmpty) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.08)
                          : Colors.white.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${task.subtasks.length} steps',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
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
              color: Theme.of(context).primaryColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              CupertinoIcons.checkmark_shield_fill,
              size: 30,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _selectedFilter == 'done'
                ? 'No completed tasks yet'
                : 'No ${_selectedFilter == 'All' ? 'pending' : _selectedFilter} tasks found',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: textDark,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Keep your study routine organized. Add a quiz, exam, or activity to track.',
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
            onPressed: () => _openAddTask(
              initialType: _selectedFilter == 'All' || _selectedFilter == 'done'
                  ? 'quiz'
                  : _selectedFilter,
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
                'Add Deadline',
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
