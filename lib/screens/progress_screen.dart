import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/schedule.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_top_bar.dart';

class ProgressScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onOpenSettings;

  const ProgressScreen({
    super.key,
    this.onBack,
    this.onOpenSettings,
  });

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final StorageService _storage = StorageService();
  List<Schedule> _schedules = [];
  DateTime _selectedDate = DateTime.now();
  int _selectedDayIndex = 0;
  bool _isFocusModeActive = false;

  final List<String> _daysOfWeek = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  final List<String> _chartDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

  @override
  void initState() {
    super.initState();
    _selectedDayIndex = DateTime.now().weekday % 7;
    _load();
  }

  Future<void> _load() async {
    final list = await _storage.loadSchedules();
    if (mounted) {
      setState(() => _schedules = list);
    }
  }

  DateTime get _startOfWeek {
    final now = _selectedDate;
    return now.subtract(Duration(days: now.weekday % 7));
  }

  int get _completedTasksCount {
    return _schedules.where((s) => s.isPastDue).length;
  }

  int get _focusHoursTotal {
    int totalMinutes = 0;
    for (final s in _schedules) {
      totalMinutes += s.end.difference(s.start).inMinutes;
    }
    return (totalMinutes / 60).round();
  }

  List<double> get _chartHeights {
    if (_schedules.isEmpty) {
      return [0.08, 0.08, 0.08, 0.08, 0.08];
    }
    // Compute day counts for Mon(1) to Fri(5)
    final counts = [0, 0, 0, 0, 0];
    for (final s in _schedules) {
      final wd = s.start.weekday; // 1 = Mon, 5 = Fri
      if (wd >= 1 && wd <= 5) {
        counts[wd - 1]++;
      }
    }
    int maxCount = counts.reduce((a, b) => a > b ? a : b);
    if (maxCount == 0) maxCount = 1;

    return counts.map((c) => (c / maxCount * 0.85).clamp(0.12, 0.95)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final startOfWeek = _startOfWeek;
    final formattedDate = 'Today, ${DateFormat('d MMMM yyyy').format(_selectedDate)}';
    final chartHeights = _chartHeights;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textDark = isDark ? AppColors.darkText : AppColors.textDark;
    final cardBg = isDark ? AppColors.darkCard : AppColors.cardWhite;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar
              AppTopBar(
                showBack: widget.onBack != null,
                onBack: widget.onBack,
                onSettingsTap: widget.onOpenSettings,
              ),
              const SizedBox(height: 16),

              // Hero Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Your Progress',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: textDark,
                    letterSpacing: -1.0,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Date Dropdown Selector
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedDate = picked;
                        _selectedDayIndex = picked.weekday % 7;
                      });
                    }
                  },
                  child: Row(
                    children: [
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: textDark,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Horizontal Weekly Calendar Strip
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                  decoration: BoxDecoration(
                    color: cardBg.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(7, (index) {
                      final dayDate = startOfWeek.add(Duration(days: index));
                      final isSelected = index == _selectedDayIndex;
                      final dayName = _daysOfWeek[index];
                      final dayNum = dayDate.day.toString();

                      return GestureDetector(
                        onTap: () => setState(() => _selectedDayIndex = index),
                        behavior: HitTestBehavior.opaque,
                        child: Column(
                          children: [
                            Text(
                              dayName,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? textDark
                                    : AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 8),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (isDark ? Theme.of(context).primaryColor : AppColors.primaryDark)
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  dayNum,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : textDark,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Focus Mode & Weekly Bar Chart Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x08000000),
                        blurRadius: 16,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row with Interactive Toggle
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isFocusModeActive ? 'Focus mode is active' : 'Focus mode is inactive',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: textDark,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _isFocusModeActive
                                      ? 'Tap to pause focus session'
                                      : 'Tap to start 25-minute focus session',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() => _isFocusModeActive = !_isFocusModeActive);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    _isFocusModeActive
                                        ? 'Focus mode started! Enjoy uninterrupted productivity.'
                                        : 'Focus mode turned off.',
                                  ),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: _isFocusModeActive ? const Color(0xFF00B894) : Theme.of(context).primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _isFocusModeActive ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                size: 22,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Bar Chart Graphic with Real Schedule Activity
                      SizedBox(
                        height: 180,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(_chartDays.length, (i) {
                            final val = chartHeights[i];
                            final day = _chartDays[i];
                            final isHighlight = i == ((DateTime.now().weekday - 1).clamp(0, 4));

                            return Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                // Animated Bar
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: 48,
                                  height: (140 * val).clamp(24.0, 140.0),
                                  decoration: BoxDecoration(
                                    color: isHighlight
                                        ? Theme.of(context).primaryColor
                                        : (isDark ? const Color(0xFF2E3456) : AppColors.cardLavender),
                                    borderRadius: BorderRadius.circular(24),
                                    border: isHighlight
                                        ? null
                                        : Border.all(
                                            color: isDark ? Colors.white12 : const Color(0xFFC7CDFA),
                                            width: 1.5,
                                          ),
                                  ),
                                  child: isHighlight
                                      ? null
                                      : CustomPaint(
                                          painter: _StripedBarPainter(),
                                        ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  day,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isHighlight
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: isHighlight
                                        ? textDark
                                        : AppColors.textMuted,
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Bottom 2-Column Real Metric Cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    // Peach Card (Completed Tasks)
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 24,
                        ),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF382E26) : AppColors.cardPeach,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x06000000),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _completedTasksCount.toString(),
                              style: TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.w800,
                                color: textDark,
                                height: 1.0,
                                letterSpacing: -1.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Tasks Done',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Sky Blue Card (Focus Hours)
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 24,
                        ),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF223640) : AppColors.cardSkyBlue,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x06000000),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _focusHoursTotal.toString(),
                              style: TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.w800,
                                color: textDark,
                                height: 1.0,
                                letterSpacing: -1.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Focus Hours',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StripedBarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF9EA6DC).withValues(alpha: 0.45)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    const spacing = 7.0;
    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i, size.height),
        Offset(i + size.height, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
