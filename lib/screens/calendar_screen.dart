import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/schedule.dart';
import '../models/task_item.dart';
import '../models/note_item.dart';
import '../services/storage_service.dart';
import '../services/widget_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';
import 'schedule_detail_screen.dart';

class CalendarScreen extends StatefulWidget {
  final VoidCallback? onOpenSettings;
  final VoidCallback? onAddNew;

  const CalendarScreen({
    super.key,
    this.onOpenSettings,
    this.onAddNew,
  });

  @override
  State<CalendarScreen> createState() => CalendarScreenState();
}

class CalendarScreenState extends State<CalendarScreen> {
  final StorageService _storage = StorageService();

  DateTime _focusedMonth = DateTime.now();
  DateTime _selectedDate = DateTime.now();

  List<Schedule> _schedules = [];
  List<TaskItem> _tasks = [];
  List<NoteItem> _notes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final sList = await _storage.loadSchedules();
    final tList = await _storage.loadTasks();
    final nList = await _storage.loadNotes();
    if (mounted) {
      setState(() {
        _schedules = sList;
        _tasks = tList;
        _notes = nList;
        _isLoading = false;
      });
    }
  }

  void _prevMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
    });
  }

  void _jumpToToday() {
    final now = DateTime.now();
    setState(() {
      _focusedMonth = DateTime(now.year, now.month, 1);
      _selectedDate = now;
    });
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Returns classes scheduled for a given day.
  /// School schedules recur on their selected [daysOfWeek].
  /// If [daysOfWeek] is missing (legacy), fall back to the exact start date.
  /// Non-school schedules match only their exact start date.
  List<Schedule> _getSchedulesForDay(DateTime date) {
    final weekday = date.weekday; // 1 = Monday, 7 = Sunday
    return _schedules.where((s) {
      if (s.isSchool) {
        if (s.daysOfWeek != null && s.daysOfWeek!.isNotEmpty) {
          // Recurring: show on every matching weekday
          return s.daysOfWeek!.contains(weekday);
        }
        // Legacy entry without daysOfWeek — show only on the original date
        return _isSameDay(s.start, date);
      }
      return _isSameDay(s.start, date);
    }).toList();
  }

  /// Returns tasks due on a given day
  List<TaskItem> _getTasksForDay(DateTime date) {
    return _tasks.where((t) => _isSameDay(t.dueDate, date)).toList();
  }

  /// Returns notes created on a given day
  List<NoteItem> _getNotesForDay(DateTime date) {
    return _notes.where((n) => _isSameDay(n.createdAt, date)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textDark = isDark ? AppColors.darkText : AppColors.textDark;
    final primary = Theme.of(context).primaryColor;

    final selectedDaySchedules = _getSchedulesForDay(_selectedDate);
    final selectedDayTasks = _getTasksForDay(_selectedDate);
    final selectedDayNotes = _getNotesForDay(_selectedDate);

    final totalEvents = selectedDaySchedules.length +
        selectedDayTasks.length +
        selectedDayNotes.length;

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
                          CupertinoIcons.calendar,
                          size: 20,
                          color: primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Academic Calendar',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: textDark,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const Spacer(),
                      // Today button
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: _jumpToToday,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: primary.withOpacity(0.35),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'Today',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Settings
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

                // Calendar Month Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GlassContainer(
                    padding: const EdgeInsets.all(18),
                    borderRadius: BorderRadius.circular(28),
                    blur: 20,
                    opacity: isDark ? 0.22 : 0.65,
                    child: Column(
                      children: [
                        // Month Navigation Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('MMMM yyyy').format(_focusedMonth),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: textDark,
                                letterSpacing: -0.3,
                              ),
                            ),
                            Row(
                              children: [
                                CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: _prevMonth,
                                  minSize: 32,
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white.withOpacity(0.08)
                                          : Colors.white.withOpacity(0.7),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      CupertinoIcons.chevron_left,
                                      size: 16,
                                      color: textDark,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: _nextMonth,
                                  minSize: 32,
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white.withOpacity(0.08)
                                          : Colors.white.withOpacity(0.7),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      CupertinoIcons.chevron_right,
                                      size: 16,
                                      color: textDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Day of week labels (S M T W T F S)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: const ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                              .map(
                                (d) => SizedBox(
                                  width: 36,
                                  child: Center(
                                    child: Text(
                                      d,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 10),

                        // Month Grid Days
                        _buildDaysGrid(isDark, primary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Selected Date Agenda Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isSameDay(_selectedDate, DateTime.now())
                                ? "Today's Agenda"
                                : DateFormat('EEEE, MMM d')
                                    .format(_selectedDate),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: textDark,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            '$totalEvents event${totalEvents == 1 ? '' : 's'} scheduled',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      // Dot Legend
                      Row(
                        children: [
                          _buildLegendDot(
                              const Color(0xFF6C5CE7), 'Class'),
                          const SizedBox(width: 8),
                          _buildLegendDot(
                              const Color(0xFFFF9500), 'Quiz/Exam'),
                          const SizedBox(width: 8),
                          _buildLegendDot(
                              const Color(0xFF00B894), 'Activity'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Selected Day Timeline List
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _isLoading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : totalEvents == 0
                          ? _buildEmptyAgenda(isDark, textDark)
                          : Column(
                              children: [
                                // Classes
                                ...selectedDaySchedules.map((s) => _buildClassCard(s, isDark, primary)),
                                // Tasks (Quizzes, Exams, Activities)
                                ...selectedDayTasks.map((t) => _buildTaskCard(t, isDark, primary)),
                                // Notes
                                ...selectedDayNotes.map((n) => _buildNoteCard(n, isDark)),
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

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildDaysGrid(bool isDark, Color primary) {
    final firstDayOfMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final startWeekday = firstDayOfMonth.weekday % 7; // Sunday = 0

    final cells = <Widget>[];

    // Leading empty cells
    for (int i = 0; i < startWeekday; i++) {
      cells.add(const SizedBox(width: 36, height: 42));
    }

    // Days in current month
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
      final isSelected = _isSameDay(date, _selectedDate);
      final isToday = _isSameDay(date, DateTime.now());

      final daySchedules = _getSchedulesForDay(date);
      final dayTasks = _getTasksForDay(date);
      final dayNotes = _getNotesForDay(date);

      final hasClass = daySchedules.isNotEmpty;
      final hasQuizExam = dayTasks.any(
          (t) => t.type == 'quiz' || t.type == 'exam');
      final hasActivity = dayTasks.any(
          (t) => t.type != 'quiz' && t.type != 'exam');
      final hasNotes = dayNotes.isNotEmpty;

      cells.add(
        GestureDetector(
          onTap: () => setState(() => _selectedDate = date),
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 36,
            height: 42,
            decoration: BoxDecoration(
              color: isSelected
                  ? primary
                  : (isToday
                      ? primary.withOpacity(0.15)
                      : Colors.transparent),
              borderRadius: BorderRadius.circular(14),
              border: isToday && !isSelected
                  ? Border.all(color: primary.withOpacity(0.6), width: 1.2)
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  day.toString(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isSelected || isToday ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? AppColors.darkText : AppColors.textDark),
                  ),
                ),
                const SizedBox(height: 3),
                // Indicator dots row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (hasClass)
                      _buildIndicatorDot(
                        isSelected ? Colors.white : const Color(0xFF6C5CE7),
                      ),
                    if (hasQuizExam)
                      _buildIndicatorDot(
                        isSelected ? Colors.white : const Color(0xFFFF9500),
                      ),
                    if (hasActivity)
                      _buildIndicatorDot(
                        isSelected ? Colors.white : const Color(0xFF00B894),
                      ),
                    if (hasNotes && !hasClass && !hasQuizExam && !hasActivity)
                      _buildIndicatorDot(
                        isSelected ? Colors.white : const Color(0xFF0984E3),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    final totalCells = cells.length;
    final rowCount = (totalCells / 7).ceil();
    final rows = <Widget>[];
    for (int r = 0; r < rowCount; r++) {
      final rowChildren = <Widget>[];
      for (int c = 0; c < 7; c++) {
        final index = r * 7 + c;
        if (index < totalCells) {
          rowChildren.add(cells[index]);
        } else {
          rowChildren.add(const SizedBox(width: 36, height: 42));
        }
      }
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: rowChildren,
          ),
        ),
      );
    }

    return Column(children: rows);
  }

  Widget _buildIndicatorDot(Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1),
      width: 4,
      height: 4,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildClassCard(Schedule s, bool isDark, Color primary) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(22),
        opacity: isDark ? 0.22 : 0.65,
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ScheduleDetailScreen(scheduleId: s.id),
            ),
          );
          loadData();
        },
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF6C5CE7).withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                CupertinoIcons.book_fill,
                size: 20,
                color: Color(0xFF6C5CE7),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C5CE7).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'CLASS',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF6C5CE7),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          s.room != null && s.room!.isNotEmpty
                              ? '${s.timeRangeFormatted} • ${s.room}'
                              : s.timeRangeFormatted,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.darkText : AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(TaskItem t, bool isDark, Color primary) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(22),
        opacity: isDark ? 0.22 : 0.65,
        child: Row(
          children: [
            // Checkbox
            GestureDetector(
              onTap: () async {
                t.isDone = !t.isDone;
                await _storage.updateTask(t);
                await WidgetService.syncAll();
                setState(() {});
              },
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: t.isDone ? primary : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: t.isDone
                        ? primary
                        : (isDark ? Colors.white38 : Colors.black26),
                    width: 2,
                  ),
                ),
                child: t.isDone
                    ? const Icon(CupertinoIcons.check_mark,
                        size: 14, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: t.priorityColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(t.typeIcon, size: 10, color: t.priorityColor),
                            const SizedBox(width: 4),
                            Text(
                              t.typeLabel.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: t.priorityColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (t.subject != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          t.subject!,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      decoration: t.isDone
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      color: t.isDone
                          ? AppColors.textMuted
                          : (isDark ? AppColors.darkText : AppColors.textDark),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: t.priorityColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                t.priorityLabel,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: t.priorityColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteCard(NoteItem n, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(22),
        opacity: isDark ? 0.22 : 0.65,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Color(n.colorValue).withOpacity(0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(n.tagIcon, size: 16, color: Color(n.colorValue)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    n.tagLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(n.colorValue),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    n.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkText : AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyAgenda(bool isDark, Color textDark) {
    return GlassContainer(
      padding: const EdgeInsets.all(28),
      borderRadius: BorderRadius.circular(28),
      opacity: isDark ? 0.18 : 0.55,
      child: Center(
        child: Column(
          children: [
            Icon(
              CupertinoIcons.sparkles,
              size: 34,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 12),
            Text(
              'No events scheduled for this day',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: textDark,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Enjoy your free time or add a study task.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

