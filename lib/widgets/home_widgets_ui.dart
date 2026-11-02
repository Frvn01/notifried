import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:intl/intl.dart' hide TextDirection;
import 'dart:math' as math;

import '../models/schedule.dart';
import '../models/task_item.dart';
import '../services/widget_service.dart';

// ── Pure color helpers for widget rendering ──
class _WidgetColors {
  final Color textDark;
  final Color textMuted;
  final Color borderColor;
  final Color cardSurface;
  final Color cardBorder;
  final Color pillBg;
  final Color pillBorder;
  final bool isDark;

  const _WidgetColors({
    required this.textDark,
    required this.textMuted,
    required this.borderColor,
    required this.cardSurface,
    required this.cardBorder,
    required this.pillBg,
    required this.pillBorder,
    required this.isDark,
  });

  factory _WidgetColors.forStyle(String style, String mode) {
    final dark = mode == 'dark' || style == 'cyber' || style == 'obsidian';
    if (dark) {
      return const _WidgetColors(
        textDark: Color(0xFFFFFFFF),
        textMuted: Color(0xFFBAC0E2),
        borderColor: Color(0x40FFFFFF),
        cardSurface: Color(0x28FFFFFF),
        cardBorder: Color(0x3DFFFFFF),
        pillBg: Color(0x30FFFFFF),
        pillBorder: Color(0x45FFFFFF),
        isDark: true,
      );
    }
    // Light / Lavender
    return const _WidgetColors(
      textDark: Color(0xFF15182D),
      textMuted: Color(0xFF565E87),
      borderColor: Color(0xB3FFFFFF),
      cardSurface: Color(0x75FFFFFF),
      cardBorder: Color(0x99FFFFFF),
      pillBg: Color(0x55FFFFFF),
      pillBorder: Color(0x80FFFFFF),
      isDark: false,
    );
  }
}

// ── Circular progress painted with CustomPaint ──
class _CircleProgressPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;

  _CircleProgressPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3.5;

    // Track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5,
    );

    // Progress
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ── Aesthetic Multi-Layer Frosted Glass Box with Floating Mesh Orbs ──
class _GlassBox extends StatelessWidget {
  final Widget child;
  final double width;
  final double height;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final String themeMode;
  final String bgStyle;
  final double animationProgress;

  const _GlassBox({
    required this.child,
    required this.width,
    required this.height,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 28,
    this.themeMode = 'lavender',
    this.bgStyle = 'aurora',
    this.animationProgress = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = themeMode == 'dark' || bgStyle == 'cyber' || bgStyle == 'obsidian';
    final colors = _WidgetColors.forStyle(bgStyle, themeMode);

    // Background gradient palette & floating orb colors
    List<Color> baseColors;
    Color orb1, orb2, orb3;

    switch (bgStyle) {
      case 'sunset':
        baseColors = isDark
            ? [const Color(0xFF1E1428), const Color(0xFF100B17)]
            : [const Color(0xFFFFECE5), const Color(0xFFFBE0D6)];
        orb1 = const Color(0xFFFF7675);
        orb2 = const Color(0xFFFDCB6E);
        orb3 = const Color(0xFF6C5CE7);
        break;
      case 'cyber':
        baseColors = [const Color(0xFF090C16), const Color(0xFF04060A)];
        orb1 = const Color(0xFF00CEC9);
        orb2 = const Color(0xFFE84393);
        orb3 = const Color(0xFF6C5CE7);
        break;
      case 'obsidian':
        baseColors = [const Color(0xFF0D0F18), const Color(0xFF06070B)];
        orb1 = const Color(0xFF4834D4);
        orb2 = const Color(0xFF00B894);
        orb3 = const Color(0xFF2D3436);
        break;
      case 'lavender':
        baseColors = isDark
            ? [const Color(0xFF17192C), const Color(0xFF0E101D)]
            : [const Color(0xFFECEEFC), const Color(0xFFDCE0F9)];
        orb1 = const Color(0xFF7B61FF);
        orb2 = const Color(0xFFA29BFE);
        orb3 = const Color(0xFF74B9FF);
        break;
      case 'emerald':
        baseColors = isDark
            ? [const Color(0xFF0D1D19), const Color(0xFF06100E)]
            : [const Color(0xFFE6F8F3), const Color(0xFFD4F2E9)];
        orb1 = const Color(0xFF00B894);
        orb2 = const Color(0xFF55EFC4);
        orb3 = const Color(0xFF0984E3);
        break;
      case 'aurora':
      default:
        baseColors = isDark
            ? [const Color(0xFF13162A), const Color(0xFF0C0E1B)]
            : [const Color(0xFFEBF0FE), const Color(0xFFDCE3FA)];
        orb1 = const Color(0xFF6C5CE7);
        orb2 = const Color(0xFFFD79A8);
        orb3 = const Color(0xFF00CECB);
        break;
    }

    // Dynamic wave drift for interactive animation in studio
    final t = animationProgress * 2 * math.pi;
    final dx1 = math.sin(t) * 16.0;
    final dy1 = math.cos(t) * 10.0;
    final dx2 = math.cos(t * 0.8) * 14.0;
    final dy2 = math.sin(t * 0.8) * 12.0;
    final dx3 = math.sin(t * 1.2) * 12.0;
    final dy3 = math.cos(t * 1.2) * 9.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: colors.borderColor,
            width: 1.5,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: baseColors,
          ),
        ),
        child: Stack(
          children: [
            // Floating Ambient Mesh Orb 1 (Top Left)
            Positioned(
              left: -30 + dx1,
              top: -30 + dy1,
              child: Container(
                width: width * 0.65,
                height: height * 0.65,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: orb1.withValues(alpha: isDark ? 0.38 : 0.45),
                ),
              ),
            ),

            // Floating Ambient Mesh Orb 2 (Top Right)
            Positioned(
              right: -30 + dx2,
              top: -20 + dy2,
              child: Container(
                width: width * 0.6,
                height: height * 0.6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: orb2.withValues(alpha: isDark ? 0.34 : 0.40),
                ),
              ),
            ),

            // Floating Ambient Mesh Orb 3 (Bottom Center)
            Positioned(
              left: width * 0.22 + dx3,
              bottom: -40 + dy3,
              child: Container(
                width: width * 0.7,
                height: height * 0.7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: orb3.withValues(alpha: isDark ? 0.30 : 0.38),
                ),
              ),
            ),

            // Apple Specular Glass Reflection Gloss (top 45%)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: height * 0.45,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: isDark ? 0.12 : 0.32),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),

            // Foreground Content
            Padding(
              padding: padding,
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// EXTRA LARGE WIDGET (4×4) - "Agenda & Command Center"
// ═══════════════════════════════════════════════════════════════
class ExtraLargeWidgetUI extends StatelessWidget {
  final WidgetDataBundle? bundle;
  final List<Schedule> schedules;
  final double animationProgress;

  const ExtraLargeWidgetUI({
    super.key,
    this.bundle,
    this.schedules = const [],
    this.animationProgress = 0.0,
  });

  WidgetDataBundle get _activeBundle {
    if (bundle != null) return bundle!;
    return WidgetDataBundle(
      schedules: schedules,
      tasks: const <TaskItem>[],
    );
  }

  @override
  Widget build(BuildContext context) {
    final b = _activeBundle;
    final nextClass = b.nextSchoolClass;
    final themeMode = b.themeMode;
    final bgStyle = b.bgStyle;
    final accent = b.accentColor;
    final colors = _WidgetColors.forStyle(bgStyle, themeMode);

    final isLive = nextClass?.isInProgress ?? false;
    final isToday = nextClass?.isToday ?? false;
    final minutesLeft = nextClass?.minutesUntilNext ?? 0;

    // Subsequent classes today
    final otherClasses = b.schedules
        .where((s) => s.isSchool && s.isToday && s.id != nextClass?.id)
        .take(2)
        .toList();

    // Urgent task or exam
    final pendingTasks = b.tasks.where((t) => !t.isDone).toList();
    final urgentTask = pendingTasks.isNotEmpty ? pendingTasks.first : null;

    final dateStr = DateFormat('EEEE, MMMM d').format(DateTime.now());

    return Directionality(
      textDirection: TextDirection.ltr,
      child: _GlassBox(
        width: 400,
        height: 380,
        borderRadius: 32,
        themeMode: themeMode,
        bgStyle: bgStyle,
        animationProgress: animationProgress,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Row: App Logo + Title + Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [accent, accent.withValues(alpha: 0.8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'N',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFFFFFFF),
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      b.customTitle.isNotEmpty
                          ? b.customTitle
                          : (b.widgetFamily == 'deadlines'
                              ? 'Academic Deadlines'
                              : (b.widgetFamily == 'tasks'
                                  ? 'Tasks & Checklist'
                                  : 'Schedule')),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: colors.textDark,
                        letterSpacing: -0.3,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.pillBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.pillBorder, width: 1),
                  ),
                  child: Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: colors.textDark,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ],
            ),

            // Hero Next Class Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.cardSurface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: colors.cardBorder, width: 1.2),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isLive
                            ? const [Color(0xFF00B894), Color(0xFF55EFC4)]
                            : [accent, accent.withValues(alpha: 0.75)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (isLive ? const Color(0xFF00B894) : accent)
                              .withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      isLive ? CupertinoIcons.play_circle_fill : CupertinoIcons.book_fill,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: isLive
                                    ? const Color(0xFF00B894)
                                    : accent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isLive ? 'LIVE NOW' : 'NEXT CLASS',
                                style: const TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                nextClass?.countdownStatus ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: colors.textMuted,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          nextClass?.title ?? 'No classes today',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: colors.textDark,
                            decoration: TextDecoration.none,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                nextClass?.timeRangeFormatted ?? 'Enjoy your day',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: colors.textMuted,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),
                            if (nextClass?.room != null &&
                                nextClass!.room!.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: accent.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: accent.withValues(alpha: 0.35),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        CupertinoIcons.location_solid,
                                        size: 9,
                                        color: accent,
                                      ),
                                      const SizedBox(width: 3),
                                      Flexible(
                                        child: Text(
                                          nextClass.room!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                            color: accent,
                                            decoration: TextDecoration.none,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Right Status Indicator (Live or Countdown or Date)
                  if (nextClass != null) ...[
                    if (isLive)
                      _buildLiveBadge()
                    else if (isToday && minutesLeft <= 180)
                      _buildCountdownGauge(minutesLeft, accent, colors)
                    else
                      _buildScheduleStatusChip(nextClass, accent, colors),
                  ],
                ],
              ),
            ),

            // Today's Follow-up Schedule Items (if any)
            if (otherClasses.isNotEmpty) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LATER TODAY',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: colors.textMuted,
                      letterSpacing: 0.6,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: otherClasses.map((item) {
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: colors.pillBg,
                            borderRadius: BorderRadius.circular(14),
                            border:
                                Border.all(color: colors.pillBorder, width: 1),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: colors.textDark,
                                  decoration: TextDecoration.none,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      item.timeRangeFormatted,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: colors.textMuted,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                  ),
                                  if (item.room != null &&
                                      item.room!.isNotEmpty) ...[
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        '• ${item.room!}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: accent,
                                          decoration: TextDecoration.none,
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
                    }).toList(),
                  ),
                ],
              ),
            ] else if (urgentTask != null) ...[
              // Urgent Task / Exam Bar
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: urgentTask.priorityColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: urgentTask.priorityColor.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      urgentTask.typeIcon,
                      size: 14,
                      color: urgentTask.priorityColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${urgentTask.type.toUpperCase()}: ${urgentTask.title}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: colors.textDark,
                          decoration: TextDecoration.none,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      urgentTask.dueFormatted,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: urgentTask.priorityColor,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Bottom Metrics Pill Row (Classes, Exams, Quizzes, Tasks)
            Row(
              children: [
                _buildStatPill(
                  'CLASSES',
                  '${b.todayClassesCount}',
                  CupertinoIcons.book_fill,
                  accent,
                  colors,
                ),
                const SizedBox(width: 8),
                _buildStatPill(
                  'EXAMS',
                  '${b.upcomingExamsCount}',
                  CupertinoIcons.exclamationmark_circle_fill,
                  const Color(0xFFFF7675),
                  colors,
                ),
                const SizedBox(width: 8),
                _buildStatPill(
                  'QUIZZES',
                  '${b.upcomingQuizzesCount}',
                  CupertinoIcons.pencil_circle_fill,
                  const Color(0xFFFF9F43),
                  colors,
                ),
                const SizedBox(width: 8),
                _buildStatPill(
                  'TASKS',
                  '${b.pendingTasksCount}',
                  CupertinoIcons.checkmark_circle_fill,
                  const Color(0xFF00B894),
                  colors,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildLiveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF00B894).withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00B894).withValues(alpha: 0.45),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(CupertinoIcons.circle_fill, size: 8, color: Color(0xFF00B894)),
          SizedBox(width: 5),
          Text(
            'LIVE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Color(0xFF00B894),
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildCountdownGauge(
      int minutesLeft, Color accent, _WidgetColors colors) {
    return SizedBox(
      width: 50,
      height: 50,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(50, 50),
            painter: _CircleProgressPainter(
              progress: (60 - minutesLeft.clamp(0, 60)) / 60,
              trackColor: colors.pillBorder,
              progressColor: accent,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$minutesLeft',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: colors.textDark,
                  decoration: TextDecoration.none,
                ),
              ),
              Text(
                'min',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: colors.textMuted,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _buildScheduleStatusChip(
      Schedule s, Color accent, _WidgetColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colors.pillBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.pillBorder, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CupertinoIcons.calendar, size: 14, color: accent),
          const SizedBox(height: 2),
          Text(
            s.countdownStatus,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: accent,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(
    String label,
    String count,
    IconData icon,
    Color dotColor,
    _WidgetColors colors,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: colors.pillBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.pillBorder, width: 1),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 11, color: dotColor),
                const SizedBox(width: 4),
                Text(
                  count,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: colors.textDark,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: colors.textMuted,
                letterSpacing: 0.4,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// LARGE WIDGET (4×2) - Frosted Class Hero + Metrics
// ═══════════════════════════════════════════════════════════════
class LargeWidgetUI extends StatelessWidget {
  final WidgetDataBundle? bundle;
  final List<Schedule> schedules;
  final double animationProgress;

  const LargeWidgetUI({
    super.key,
    this.bundle,
    this.schedules = const [],
    this.animationProgress = 0.0,
  });

  WidgetDataBundle get _activeBundle {
    if (bundle != null) return bundle!;
    return WidgetDataBundle(
      schedules: schedules,
      tasks: const <TaskItem>[],
    );
  }

  @override
  Widget build(BuildContext context) {
    final b = _activeBundle;
    final nextClass = b.nextSchoolClass;
    final themeMode = b.themeMode;
    final bgStyle = b.bgStyle;
    final accent = b.accentColor;
    final colors = _WidgetColors.forStyle(bgStyle, themeMode);

    final isLive = nextClass?.isInProgress ?? false;
    final isToday = nextClass?.isToday ?? false;
    final minutesLeft = nextClass?.minutesUntilNext ?? 0;

    final dateStr = DateFormat('EEEE, MMM d').format(DateTime.now());

    return Directionality(
      textDirection: TextDirection.ltr,
      child: _GlassBox(
        width: 400,
        height: 200,
        borderRadius: 30,
        themeMode: themeMode,
        bgStyle: bgStyle,
        animationProgress: animationProgress,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Row: App Branding + Today's Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [accent, accent.withValues(alpha: 0.8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(7),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'N',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFFFFFFF),
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Nowtifried',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: colors.textDark,
                        letterSpacing: -0.3,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.pillBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.pillBorder, width: 1),
                  ),
                  child: Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: colors.textDark,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ],
            ),

            // Middle Class Countdown Frosted Hero
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.cardSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colors.cardBorder, width: 1.2),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isLive
                            ? const [Color(0xFF00B894), Color(0xFF55EFC4)]
                            : [accent, accent.withValues(alpha: 0.75)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (isLive ? const Color(0xFF00B894) : accent)
                              .withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      isLive ? CupertinoIcons.play_circle_fill : CupertinoIcons.book_fill,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: isLive
                                    ? const Color(0xFF00B894)
                                    : accent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isLive ? 'LIVE NOW' : 'NEXT CLASS',
                                style: const TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                  color: Colors.white,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),
                            if (nextClass != null) ...[
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  nextClass.countdownStatus,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: colors.textMuted,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          nextClass?.title ?? 'No classes today',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: colors.textDark,
                            decoration: TextDecoration.none,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                nextClass?.timeRangeFormatted ?? 'Enjoy your day',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: colors.textMuted,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),
                            if (nextClass?.room != null &&
                                nextClass!.room!.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: accent.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: accent.withValues(alpha: 0.35),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        CupertinoIcons.location_solid,
                                        size: 8,
                                        color: accent,
                                      ),
                                      const SizedBox(width: 3),
                                      Flexible(
                                        child: Text(
                                          nextClass.room!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                            color: accent,
                                            decoration: TextDecoration.none,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Right Indicator
                  if (nextClass != null) ...[
                    if (isLive)
                      ExtraLargeWidgetUI._buildLiveBadge()
                    else if (isToday && minutesLeft <= 180)
                      ExtraLargeWidgetUI._buildCountdownGauge(
                          minutesLeft, accent, colors)
                    else
                      ExtraLargeWidgetUI._buildScheduleStatusChip(
                          nextClass, accent, colors),
                  ],
                ],
              ),
            ),

            // Bottom Metrics Pill Row (Classes, Exams, Quizzes, Tasks)
            Row(
              children: [
                _buildStatPill(
                  'CLASSES',
                  '${b.todayClassesCount}',
                  CupertinoIcons.book_fill,
                  accent,
                  colors,
                ),
                const SizedBox(width: 8),
                _buildStatPill(
                  'EXAMS',
                  '${b.upcomingExamsCount}',
                  CupertinoIcons.exclamationmark_circle_fill,
                  const Color(0xFFFF7675),
                  colors,
                ),
                const SizedBox(width: 8),
                _buildStatPill(
                  'QUIZZES',
                  '${b.upcomingQuizzesCount}',
                  CupertinoIcons.pencil_circle_fill,
                  const Color(0xFFFF9F43),
                  colors,
                ),
                const SizedBox(width: 8),
                _buildStatPill(
                  'TASKS',
                  '${b.pendingTasksCount}',
                  CupertinoIcons.checkmark_circle_fill,
                  const Color(0xFF00B894),
                  colors,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatPill(
    String label,
    String count,
    IconData icon,
    Color dotColor,
    _WidgetColors colors,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: colors.pillBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.pillBorder, width: 1),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 10, color: dotColor),
                const SizedBox(width: 4),
                Text(
                  count,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: colors.textDark,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: colors.textMuted,
                letterSpacing: 0.4,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// GLANCE WIDGET (4×1 Slim Strip) - "Dynamic Island Bar"
// ═══════════════════════════════════════════════════════════════
class GlanceWidgetUI extends StatelessWidget {
  final WidgetDataBundle? bundle;
  final List<Schedule> schedules;
  final double animationProgress;

  const GlanceWidgetUI({
    super.key,
    this.bundle,
    this.schedules = const [],
    this.animationProgress = 0.0,
  });

  WidgetDataBundle get _activeBundle {
    if (bundle != null) return bundle!;
    return WidgetDataBundle(
      schedules: schedules,
      tasks: const <TaskItem>[],
    );
  }

  @override
  Widget build(BuildContext context) {
    final b = _activeBundle;
    final nextClass = b.nextSchoolClass;
    final themeMode = b.themeMode;
    final bgStyle = b.bgStyle;
    final accent = b.accentColor;
    final colors = _WidgetColors.forStyle(bgStyle, themeMode);

    final isLive = nextClass?.isInProgress ?? false;
    final isToday = nextClass?.isToday ?? false;
    final minutesLeft = nextClass?.minutesUntilNext ?? 0;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: _GlassBox(
        width: 380,
        height: 75,
        borderRadius: 24,
        themeMode: themeMode,
        bgStyle: bgStyle,
        animationProgress: animationProgress,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isLive
                      ? const [Color(0xFF00B894), Color(0xFF55EFC4)]
                      : [accent, accent.withValues(alpha: 0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: (isLive ? const Color(0xFF00B894) : accent)
                        .withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Icon(
                isLive ? CupertinoIcons.play_circle_fill : CupertinoIcons.book_fill,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    nextClass?.title ?? 'No classes scheduled',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: colors.textDark,
                      decoration: TextDecoration.none,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          nextClass?.timeRangeFormatted ?? 'All clear',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: colors.textMuted,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                      if (nextClass?.room != null &&
                          nextClass!.room!.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  CupertinoIcons.location_solid,
                                  size: 8,
                                  color: accent,
                                ),
                                const SizedBox(width: 2),
                                Flexible(
                                  child: Text(
                                    nextClass.room!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w800,
                                      color: accent,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isLive
                    ? const Color(0xFF00B894)
                    : (isToday && minutesLeft <= 180 ? accent : colors.pillBg),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isLive
                      ? const Color(0xFF00B894)
                      : (isToday && minutesLeft <= 180 ? accent : colors.pillBorder),
                  width: 1,
                ),
              ),
              child: Text(
                isLive
                    ? 'LIVE'
                    : (nextClass != null
                        ? (isToday && minutesLeft <= 180 ? '${minutesLeft}m left' : nextClass.countdownStatus)
                        : 'Clear'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: (isLive || (isToday && minutesLeft <= 180)) ? Colors.white : colors.textDark,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// MEDIUM WIDGET (4×1)
// ═══════════════════════════════════════════════════════════════
class MediumWidgetUI extends StatelessWidget {
  final WidgetDataBundle? bundle;
  final List<Schedule> schedules;
  final double animationProgress;

  const MediumWidgetUI({
    super.key,
    this.bundle,
    this.schedules = const [],
    this.animationProgress = 0.0,
  });

  WidgetDataBundle get _activeBundle {
    if (bundle != null) return bundle!;
    return WidgetDataBundle(
      schedules: schedules,
      tasks: const <TaskItem>[],
    );
  }

  @override
  Widget build(BuildContext context) {
    final b = _activeBundle;
    final nextClass = b.nextSchoolClass;
    final themeMode = b.themeMode;
    final bgStyle = b.bgStyle;
    final accent = b.accentColor;
    final colors = _WidgetColors.forStyle(bgStyle, themeMode);

    final isLive = nextClass?.isInProgress ?? false;
    final isToday = nextClass?.isToday ?? false;
    final minutesLeft = nextClass?.minutesUntilNext ?? 0;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: _GlassBox(
        width: 400,
        height: 110,
        borderRadius: 28,
        themeMode: themeMode,
        bgStyle: bgStyle,
        animationProgress: animationProgress,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isLive
                      ? const [Color(0xFF00B894), Color(0xFF55EFC4)]
                      : [accent, accent.withValues(alpha: 0.75)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (isLive ? const Color(0xFF00B894) : accent)
                        .withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Icon(
                isLive ? CupertinoIcons.play_circle_fill : CupertinoIcons.book_fill,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isLive ? const Color(0xFF00B894) : accent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isLive ? 'LIVE NOW' : 'NEXT CLASS',
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          nextClass?.timeRangeFormatted ?? 'Today',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: colors.textMuted,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    nextClass?.title ?? 'No classes today',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: colors.textDark,
                      decoration: TextDecoration.none,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (nextClass?.room != null &&
                      nextClass!.room!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.location_solid,
                          size: 9,
                          color: accent,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            nextClass.room!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: accent,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (nextClass != null) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isLive
                      ? const Color(0xFF00B894)
                      : (isToday && minutesLeft <= 180 ? accent : colors.pillBg),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isLive
                        ? const Color(0xFF00B894)
                        : (isToday && minutesLeft <= 180 ? accent : colors.pillBorder),
                    width: 1,
                  ),
                ),
                child: Text(
                  isLive
                      ? 'IN PROGRESS'
                      : (isToday && minutesLeft <= 180
                          ? '${minutesLeft}m left'
                          : nextClass.countdownStatus),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: (isLive || (isToday && minutesLeft <= 180)) ? Colors.white : colors.textDark,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SMALL WIDGET (2×2)
// ═══════════════════════════════════════════════════════════════
class SmallWidgetUI extends StatelessWidget {
  final WidgetDataBundle? bundle;
  final List<Schedule> schedules;
  final double animationProgress;

  const SmallWidgetUI({
    super.key,
    this.bundle,
    this.schedules = const [],
    this.animationProgress = 0.0,
  });

  WidgetDataBundle get _activeBundle {
    if (bundle != null) return bundle!;
    return WidgetDataBundle(
      schedules: schedules,
      tasks: const <TaskItem>[],
    );
  }

  @override
  Widget build(BuildContext context) {
    final b = _activeBundle;
    final nextClass = b.nextSchoolClass;
    final themeMode = b.themeMode;
    final bgStyle = b.bgStyle;
    final accent = b.accentColor;
    final colors = _WidgetColors.forStyle(bgStyle, themeMode);

    final isLive = nextClass?.isInProgress ?? false;
    final isToday = nextClass?.isToday ?? false;
    final minutesLeft = nextClass?.minutesUntilNext ?? 0;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: _GlassBox(
        width: 200,
        height: 200,
        borderRadius: 28,
        themeMode: themeMode,
        bgStyle: bgStyle,
        animationProgress: animationProgress,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accent, accent.withValues(alpha: 0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'N',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFFFFFFF),
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isLive ? const Color(0xFF00B894) : accent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isLive ? 'LIVE' : 'CLASS',
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ],
            ),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isLive
                      ? const [Color(0xFF00B894), Color(0xFF55EFC4)]
                      : [accent, accent.withValues(alpha: 0.75)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (isLive ? const Color(0xFF00B894) : accent)
                        .withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Icon(
                isLive ? CupertinoIcons.play_circle_fill : CupertinoIcons.book_fill,
                color: Colors.white,
                size: 20,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    nextClass?.title ?? 'No classes',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: colors.textDark,
                      decoration: TextDecoration.none,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isLive
                        ? 'In progress'
                        : (nextClass != null
                            ? (isToday && minutesLeft <= 180 ? '${minutesLeft}m left' : nextClass.countdownStatus)
                            : 'All clear'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isLive ? const Color(0xFF00B894) : accent,
                      decoration: TextDecoration.none,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    nextClass != null &&
                            nextClass.room != null &&
                            nextClass.room!.isNotEmpty
                        ? '${nextClass.timeRangeFormatted} • ${nextClass.room}'
                        : (nextClass?.timeRangeFormatted ?? '-'),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: colors.textMuted,
                      decoration: TextDecoration.none,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
