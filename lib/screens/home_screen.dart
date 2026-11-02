import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/schedule.dart';
import '../models/task_item.dart';
import '../models/note_item.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/widget_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';
import 'add_schedule_screen.dart';
import 'schedule_detail_screen.dart';
import 'widget_studio_screen.dart';
import 'widget_gallery_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onViewAllTasks;
  final void Function(String)? onFilterTasks;
  final VoidCallback? onOpenSettings;
  final void Function(Color)? onThemeChanged;

  const HomeScreen({
    super.key,
    this.onViewAllTasks,
    this.onFilterTasks,
    this.onOpenSettings,
    this.onThemeChanged,
  });

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  final StorageService _storage = StorageService();
  final NotificationService _notifier = NotificationService();

  List<Schedule> _schedules = [];
  List<TaskItem> _tasks = [];
  List<NoteItem> _notes = [];
  String _userName = '';
  bool _isLoading = true;

  late AnimationController _ambientController;
  late Animation<double> _ambientAnimation;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat(reverse: true);
    _ambientAnimation = CurvedAnimation(
      parent: _ambientController,
      curve: Curves.easeInOut,
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );

    loadData();
  }

  @override
  void dispose() {
    _ambientController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    final sList = await _storage.loadSchedules();
    final tList = await _storage.loadTasks();
    final nList = await _storage.loadNotes();
    final name = await _storage.loadUserName();

    if (mounted) {
      setState(() {
        _schedules = sList;
        _tasks = tList;
        _notes = nList;
        _userName = name;
        _isLoading = false;
      });
    }
  }

  Future<void> _openAddSchedule() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AddScheduleScreen(initialType: 'school'),
      ),
    );
    loadData();
  }

  Future<void> _openDetail(String id) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ScheduleDetailScreen(scheduleId: id),
      ),
    );
    loadData();
  }

  Future<void> _removeSchedule(Schedule s) async {
    if (s.notificationId != null) {
      await _notifier.cancel(s.notificationId!);
    }
    _schedules.removeWhere((e) => e.id == s.id);
    await _storage.saveSchedules(_schedules);
    await WidgetService.syncAll();
    setState(() {});
  }

  Future<void> _toggleTaskDone(TaskItem task) async {
    task.isDone = !task.isDone;
    await _storage.updateTask(task);
    await WidgetService.syncAll();
    setState(() {});
  }

  int get _todayClassesCount => _schedules.where((s) => s.isToday).length;
  int get _schoolTotalCount => _schedules.where((s) => s.isSchool).length;
  int get _quizzesAndExamsCount =>
      _tasks.where((t) => !t.isDone && (t.type == 'quiz' || t.type == 'exam')).length;
  int get _notesCount => _notes.length;

  List<Schedule> get _todaySchedules {
    final today = _schedules.where((s) => s.isToday).toList();
    today.sort((a, b) => a.start.compareTo(b.start));
    return today;
  }

  Schedule? get _nextSchoolClass {
    final schoolList =
        _schedules.where((s) => s.isSchool && !s.isPastDue).toList();
    schoolList.sort((a, b) => a.start.compareTo(b.start));
    return schoolList.isNotEmpty ? schoolList.first : null;
  }

  TaskItem? get _nextUpcomingExam {
    final exams = _tasks
        .where((t) =>
            !t.isDone &&
            (t.type == 'exam' || t.type == 'quiz') &&
            t.dueDate.isAfter(DateTime.now()))
        .toList();
    exams.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return exams.isNotEmpty ? exams.first : null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textDark = isDark ? AppColors.darkText : AppColors.textDark;
    final primary = Theme.of(context).primaryColor;
    final nextClass = _nextSchoolClass;
    final nextExam = _nextUpcomingExam;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // ── Vivid Floating Ambient Glass Orbs for Real Refraction ──
          AnimatedBuilder(
            animation: _ambientAnimation,
            builder: (context, child) {
              final val = _ambientAnimation.value;
              return Stack(
                children: [
                  Positioned(
                    top: -40 + (val * 25),
                    left: -30 + (val * 15),
                    child: Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF6C5CE7).withValues(alpha: isDark ? 0.35 : 0.45),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 220 - (val * 30),
                    right: -60 + (val * 20),
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primary.withValues(alpha: isDark ? 0.3 : 0.4),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 120 + (val * 35),
                    left: -40 + (val * 20),
                    child: Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF00B894).withValues(alpha: isDark ? 0.25 : 0.35),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -50 - (val * 20),
                    right: -30 + (val * 25),
                    child: Container(
                      width: 290,
                      height: 290,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFF9500).withValues(alpha: isDark ? 0.25 : 0.35),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // Ambient blur layer
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 75, sigmaY: 75),
              child: Container(color: Colors.transparent),
            ),
          ),

          // Main Dashboard Content
          SafeArea(
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
                    // Top App Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Row(
                        children: [
                          // Glass Avatar
                          GlassContainer(
                            width: 46,
                            height: 46,
                            borderRadius: BorderRadius.circular(23),
                            blur: 16,
                            opacity: isDark ? 0.25 : 0.65,
                            child: Center(
                              child: _userName.isNotEmpty
                                  ? Text(
                                      _userName[0].toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w800,
                                        color: primary,
                                      ),
                                    )
                                  : Icon(
                                      CupertinoIcons.person_fill,
                                      size: 20,
                                      color: primary,
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _userName.isNotEmpty ? 'Hey, $_userName' : 'Student Hub',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: textDark,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              Text(
                                'Academic Command Center',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          // Widget Gallery Button (Bento, Glass, Neon, Timeline, Minimal)
                          GlassContainer(
                            width: 44,
                            height: 44,
                            borderRadius: BorderRadius.circular(22),
                            blur: 16,
                            opacity: isDark ? 0.25 : 0.65,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const WidgetGalleryScreen(),
                                ),
                              );
                            },
                            child: Icon(
                              CupertinoIcons.rectangle_stack_fill,
                              size: 18,
                              color: isDark ? Colors.white70 : AppColors.textDark,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Widget Studio Button
                          GlassContainer(
                            width: 44,
                            height: 44,
                            borderRadius: BorderRadius.circular(22),
                            blur: 16,
                            opacity: isDark ? 0.25 : 0.65,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const WidgetStudioScreen(),
                                ),
                              );
                            },
                            child: Icon(
                              CupertinoIcons.sparkles,
                              size: 19,
                              color: isDark ? Colors.white70 : AppColors.textDark,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Settings Button
                          if (widget.onOpenSettings != null)
                            GlassContainer(
                              width: 44,
                              height: 44,
                              borderRadius: BorderRadius.circular(22),
                              blur: 16,
                              opacity: isDark ? 0.25 : 0.65,
                              onTap: widget.onOpenSettings,
                              child: Icon(
                                CupertinoIcons.gear,
                                size: 20,
                                color: isDark ? Colors.white70 : AppColors.textDark,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Hero Headline
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 34,
                            color: textDark,
                            fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
                            height: 1.15,
                            letterSpacing: -1.0,
                          ),
                          children: const [
                            TextSpan(
                              text: 'Plan your ',
                              style: TextStyle(fontWeight: FontWeight.w400),
                            ),
                            TextSpan(
                              text: "academic\nroutine.",
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Next Class Countdown Glass Banner
                    if (nextClass != null) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: GlassContainer(
                          padding: const EdgeInsets.all(18),
                          borderRadius: BorderRadius.circular(28),
                          blur: 24,
                          opacity: isDark ? 0.35 : 0.75,
                          onTap: () => _openDetail(nextClass.id),
                          child: Row(
                            children: [
                              AnimatedBuilder(
                                animation: _pulseAnimation,
                                builder: (context, child) {
                                  final p = _pulseAnimation.value;
                                  return Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: primary,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: primary.withValues(alpha: 0.25 + (p * 0.35)),
                                          blurRadius: 10 + (p * 8),
                                          spreadRadius: p * 2,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: child,
                                  );
                                },
                                child: const Icon(
                                  CupertinoIcons.book_fill,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Text(
                                          'NEXT CLASS',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.textMuted,
                                            letterSpacing: 0.6,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: primary.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              nextClass.countdownStatus,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                                color: primary,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      nextClass.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      nextClass.room != null && nextClass.room!.isNotEmpty
                                          ? '${nextClass.timeRangeFormatted} • ${nextClass.room}'
                                          : nextClass.timeRangeFormatted,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                CupertinoIcons.chevron_right,
                                color: AppColors.textMuted,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Upcoming Exam / Quiz Glass Banner
                    if (nextExam != null) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: GlassContainer(
                          padding: const EdgeInsets.all(18),
                          borderRadius: BorderRadius.circular(28),
                          blur: 24,
                          opacity: isDark ? 0.35 : 0.75,
                          onTap: widget.onViewAllTasks,
                          child: Row(
                            children: [
                              AnimatedBuilder(
                                animation: _pulseAnimation,
                                builder: (context, child) {
                                  final p = _pulseAnimation.value;
                                  return Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: nextExam.priorityColor,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: nextExam.priorityColor.withValues(alpha: 0.25 + (p * 0.35)),
                                          blurRadius: 10 + (p * 8),
                                          spreadRadius: p * 2,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: child,
                                  );
                                },
                                child: Icon(
                                  nextExam.typeIcon,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            'UPCOMING ${nextExam.type.toUpperCase()}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              color: nextExam.priorityColor,
                                              letterSpacing: 0.6,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: nextExam.priorityColor.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              nextExam.priorityLabel,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                                color: nextExam.priorityColor,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      nextExam.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Due ${nextExam.dueFormatted}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                CupertinoIcons.chevron_right,
                                color: AppColors.textMuted,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // 2x2 Frosted Glass Metric Cards
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildMetricGlassCard(
                                  title: "Today's Schedule",
                                  count: _todayClassesCount.toString().padLeft(2, '0'),
                                  subtitle: 'Classes Today',
                                  icon: CupertinoIcons.calendar_today,
                                  badgeBg: const Color(0xFFE4EAFE),
                                  iconColor: primary,
                                  onTap: () => widget.onFilterTasks?.call('In Progress'),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _buildMetricGlassCard(
                                  title: 'Classes',
                                  count: _schoolTotalCount.toString().padLeft(2, '0'),
                                  subtitle: 'Subjects',
                                  icon: CupertinoIcons.book_fill,
                                  badgeBg: const Color(0xFFECE6FE),
                                  iconColor: const Color(0xFF6C5CE7),
                                  onTap: () => widget.onFilterTasks?.call('School'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _buildMetricGlassCard(
                                  title: 'Quizzes & Exams',
                                  count: _quizzesAndExamsCount.toString().padLeft(2, '0'),
                                  subtitle: 'Upcoming',
                                  icon: CupertinoIcons.checkmark_shield_fill,
                                  badgeBg: const Color(0xFFFDECE2),
                                  iconColor: const Color(0xFFFF9500),
                                  onTap: widget.onViewAllTasks,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _buildMetricGlassCard(
                                  title: 'Study Notes',
                                  count: _notesCount.toString().padLeft(2, '0'),
                                  subtitle: 'Reviewers',
                                  icon: CupertinoIcons.doc_text_fill,
                                  badgeBg: const Color(0xFFDEF2F9),
                                  iconColor: const Color(0xFF00B894),
                                  onTap: () {
                                    // Navigate to notes
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Section Header: Today's Routine + View All
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Today's routine",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: textDark,
                              letterSpacing: -0.3,
                            ),
                          ),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: widget.onViewAllTasks,
                            child: Text(
                              'View All',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Today's Routine List
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _isLoading
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32.0),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : _todaySchedules.isEmpty && _tasks.isEmpty
                              ? _buildEmptyState(isDark, textDark)
                              : Column(
                                  children: [
                                    ..._todaySchedules.map(
                                      (s) => _buildTodayScheduleItem(s, isDark, textDark, primary),
                                    ),
                                    ..._tasks.take(3).map(
                                      (t) => _buildTodayTaskItem(t, isDark, textDark, primary),
                                    ),
                                  ],
                                ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricGlassCard({
    required String title,
    required String count,
    required String subtitle,
    required IconData icon,
    required Color badgeBg,
    required Color iconColor,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textDark = isDark ? AppColors.darkText : AppColors.textDark;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return GlassContainer(
      padding: const EdgeInsets.all(18),
      borderRadius: BorderRadius.circular(26),
      blur: 24,
      opacity: isDark ? 0.3 : 0.7,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 15, color: iconColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: (int.tryParse(count) ?? 0).toDouble()),
                duration: const Duration(milliseconds: 650),
                curve: Curves.easeOutCubic,
                builder: (context, val, child) {
                  final display = val.toInt().toString().padLeft(2, '0');
                  return Text(
                    display,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: textDark,
                      letterSpacing: -1.0,
                      height: 1.0,
                    ),
                  );
                },
              ),
              const SizedBox(width: 6),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTodayScheduleItem(
    Schedule s,
    bool isDark,
    Color textDark,
    Color primary,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        padding: const EdgeInsets.all(18),
        borderRadius: BorderRadius.circular(24),
        blur: 24,
        opacity: isDark ? 0.3 : 0.7,
        onTap: () => _openDetail(s.id),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF6C5CE7).withValues(alpha: 0.18),
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
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C5CE7).withValues(alpha: 0.15),
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          s.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: textDark,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Use Flexible so the badge never overflows the row
                      Flexible(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 110),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            s.countdownStatus,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            CupertinoButton(
              padding: EdgeInsets.zero,
              minSize: 24,
              onPressed: () => _removeSchedule(s),
              child: const Icon(
                CupertinoIcons.trash,
                size: 14,
                color: Color(0xFFFF3B30),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayTaskItem(
    TaskItem t,
    bool isDark,
    Color textDark,
    Color primary,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        padding: const EdgeInsets.all(18),
        borderRadius: BorderRadius.circular(24),
        blur: 24,
        opacity: isDark ? 0.3 : 0.7,
        child: Row(
          children: [
            GestureDetector(
              onTap: () => _toggleTaskDone(t),
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
                    ? const Icon(CupertinoIcons.check_mark, size: 14, color: Colors.white)
                    : null,
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
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: t.priorityColor.withValues(alpha: 0.15),
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
                        Expanded(
                          child: Text(
                            t.subject!,
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
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      decoration: t.isDone ? TextDecoration.lineThrough : TextDecoration.none,
                      color: t.isDone ? AppColors.textMuted : textDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                t.dueFormatted,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
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
      blur: 24,
      opacity: isDark ? 0.25 : 0.65,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              CupertinoIcons.calendar_badge_plus,
              size: 30,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No schedules for today',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: textDark,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Create your class timetable or log upcoming quizzes and exams.',
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
            onPressed: _openAddSchedule,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Text(
                'Add Schedule',
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
