import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'calendar_screen.dart';
import 'tasks_screen.dart';
import 'notes_screen.dart';
import 'profile_screen.dart';
import 'add_schedule_screen.dart';
import 'add_task_screen.dart';
import 'note_detail_screen.dart';

class NavShell extends StatefulWidget {
  final void Function(Color, String)? onThemeOrColorChanged;
  final String currentThemeMode;

  const NavShell({
    super.key,
    this.onThemeOrColorChanged,
    this.currentThemeMode = 'lavender',
  });

  @override
  State<NavShell> createState() => NavShellState();
}

class NavShellState extends State<NavShell>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;

  void switchToTab(int index) {
    if (index >= 0 && index < 4) {
      _onTabSelected(index);
    }
  }

  late AnimationController _ambientController;
  late Animation<double> _ambientAnimation;

  final GlobalKey<HomeScreenState> _homeKey = GlobalKey<HomeScreenState>();
  final GlobalKey<CalendarScreenState> _calendarKey =
      GlobalKey<CalendarScreenState>();
  final GlobalKey<TasksScreenState> _tasksKey = GlobalKey<TasksScreenState>();
  final GlobalKey<NotesScreenState> _notesKey = GlobalKey<NotesScreenState>();

  @override
  void initState() {
    super.initState();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _ambientAnimation = CurvedAnimation(
      parent: _ambientController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _ambientController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);
    if (index == 0) {
      _homeKey.currentState?.loadData();
    } else if (index == 1) {
      _calendarKey.currentState?.loadData();
    } else if (index == 2) {
      _tasksKey.currentState?.loadData();
    } else if (index == 3) {
      _notesKey.currentState?.loadData();
    }
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          onThemeOrColorChanged: widget.onThemeOrColorChanged,
        ),
      ),
    );
  }

  void _showAddActionSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).primaryColor;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 34),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E2235).withValues(alpha: 0.85)
                    : Colors.white.withValues(alpha: 0.9),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(36)),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.35),
                  width: 1.2,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Pull indicator
                  Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Create New',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.darkText : AppColors.textDark,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Options with Clean Cupertino Icons (NO EMOJIS)
                  _buildSheetOption(
                    ctx: ctx,
                    icon: CupertinoIcons.book_fill,
                    title: 'Class Schedule',
                    subtitle: 'Add course timetable, recurring days & alerts',
                    accent: const Color(0xFF6C5CE7),
                    onTap: () async {
                      Navigator.pop(ctx);
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const AddScheduleScreen(initialType: 'school'),
                          fullscreenDialog: true,
                        ),
                      );
                      _refreshAll();
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildSheetOption(
                    ctx: ctx,
                    icon: CupertinoIcons.lab_flask_solid,
                    title: 'Quiz Deadline',
                    subtitle: 'Schedule a chapter quiz with prep checklist',
                    accent: const Color(0xFFFF9500),
                    onTap: () async {
                      Navigator.pop(ctx);
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const AddTaskScreen(initialType: 'quiz'),
                          fullscreenDialog: true,
                        ),
                      );
                      _refreshAll();
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildSheetOption(
                    ctx: ctx,
                    icon: CupertinoIcons.doc_plaintext,
                    title: 'Major Exam',
                    subtitle: 'Log midterms, finals, and syllabus steps',
                    accent: const Color(0xFFFF3B30),
                    onTap: () async {
                      Navigator.pop(ctx);
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const AddTaskScreen(initialType: 'exam'),
                          fullscreenDialog: true,
                        ),
                      );
                      _refreshAll();
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildSheetOption(
                    ctx: ctx,
                    icon: CupertinoIcons.flag_fill,
                    title: 'Activity / Homework',
                    subtitle: 'Track school projects, lab reports and tasks',
                    accent: const Color(0xFF00B894),
                    onTap: () async {
                      Navigator.pop(ctx);
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const AddTaskScreen(initialType: 'activity'),
                          fullscreenDialog: true,
                        ),
                      );
                      _refreshAll();
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildSheetOption(
                    ctx: ctx,
                    icon: CupertinoIcons.pencil_outline,
                    title: 'Quick Note / Reviewer',
                    subtitle: 'Capture formulas, review sheets and notes',
                    accent: primary,
                    onTap: () async {
                      Navigator.pop(ctx);
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NoteDetailScreen(),
                          fullscreenDialog: true,
                        ),
                      );
                      _refreshAll();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _refreshAll() {
    _homeKey.currentState?.loadData();
    _calendarKey.currentState?.loadData();
    _tasksKey.currentState?.loadData();
    _notesKey.currentState?.loadData();
  }

  Widget _buildSheetOption({
    required BuildContext ctx,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accent,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 20, color: accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkText : AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.textMuted,
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

  List<Color> _getAmbientColors(String mode) {
    if (mode == 'dark') {
      return [
        const Color(0xFF6C5CE7).withValues(alpha: 0.38),
        const Color(0xFF0984E3).withValues(alpha: 0.32),
        const Color(0xFF00B894).withValues(alpha: 0.25),
        const Color(0xFFFF9500).withValues(alpha: 0.28),
      ];
    } else if (mode == 'light') {
      return [
        const Color(0xFF74B9FF).withValues(alpha: 0.45),
        const Color(0xFFA29BFE).withValues(alpha: 0.42),
        const Color(0xFF81ECEC).withValues(alpha: 0.38),
        const Color(0xFFFF7675).withValues(alpha: 0.32),
      ];
    }
    // Lavender
    return [
      const Color(0xFF7C6BE8).withValues(alpha: 0.48),
      const Color(0xFF5960A0).withValues(alpha: 0.4),
      const Color(0xFFA29BFE).withValues(alpha: 0.38),
      const Color(0xFF00B894).withValues(alpha: 0.3),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final bgGradients =
        AppTheme.getBackgroundGradient(widget.currentThemeMode);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ambientCols = _getAmbientColors(widget.currentThemeMode);

    final screens = [
      HomeScreen(
        key: _homeKey,
        onViewAllTasks: () => _onTabSelected(2),
        onFilterTasks: (filter) {
          _tasksKey.currentState?.setFilter(filter);
          _onTabSelected(2);
        },
        onOpenSettings: _openSettings,
        onThemeChanged: (c) => widget.onThemeOrColorChanged?.call(
          c,
          widget.currentThemeMode,
        ),
      ),
      CalendarScreen(
        key: _calendarKey,
        onOpenSettings: _openSettings,
        onAddNew: _showAddActionSheet,
      ),
      TasksScreen(
        key: _tasksKey,
        onBack: () => _onTabSelected(0),
        onOpenSettings: _openSettings,
      ),
      NotesScreen(
        key: _notesKey,
        onOpenSettings: _openSettings,
      ),
    ];

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // Background Gradient Layer
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: bgGradients,
              ),
            ),
          ),

          // Fluid Animated Ambient Glass Glow Orbs (Global across all tabs)
          AnimatedBuilder(
            animation: _ambientAnimation,
            builder: (context, child) {
              final val = _ambientAnimation.value;
              return Stack(
                children: [
                  Positioned(
                    top: -50 + (val * 30),
                    left: -40 + (val * 20),
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ambientCols[0],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 240 - (val * 35),
                    right: -70 + (val * 25),
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ambientCols[1],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 140 + (val * 40),
                    left: -50 + (val * 25),
                    child: Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ambientCols[2],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -60 - (val * 25),
                    right: -40 + (val * 30),
                    child: Container(
                      width: 310,
                      height: 310,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ambientCols[3],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // Global Ambient Blur Layer
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 75, sigmaY: 75),
              child: Container(color: Colors.transparent),
            ),
          ),

          // Main Screen Stack
          IndexedStack(
            index: _currentIndex,
            children: screens,
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(isDark),
    );
  }

  Widget _buildBottomNav(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1A1D30).withValues(alpha: 0.65)
                  : Colors.white.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(36),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.16)
                    : Colors.white.withValues(alpha: 0.8),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? const Color(0x40000000)
                      : const Color(0x18000000),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: _buildNavItem(
                    0,
                    _currentIndex == 0
                        ? CupertinoIcons.house_fill
                        : CupertinoIcons.house,
                    'Home',
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    1,
                    _currentIndex == 1
                        ? CupertinoIcons.calendar_today
                        : CupertinoIcons.calendar,
                    'Calendar',
                  ),
                ),
                // Center Floating '+' Action Button
                GestureDetector(
                  onTap: _showAddActionSheet,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context)
                              .primaryColor
                              .withValues(alpha: 0.45),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      CupertinoIcons.plus,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    2,
                    _currentIndex == 2
                        ? CupertinoIcons.checkmark_shield_fill
                        : CupertinoIcons.checkmark_shield,
                    'Tasks',
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    3,
                    _currentIndex == 3
                        ? CupertinoIcons.doc_text_fill
                        : CupertinoIcons.doc_text,
                    'Notes',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    final primary = Theme.of(context).primaryColor;

    return GestureDetector(
      onTap: () => _onTabSelected(index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 21,
              color: isSelected ? primary : AppColors.textMuted,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? primary : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isSelected ? 4 : 0,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? primary : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
