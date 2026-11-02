import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/schedule.dart';
import '../../providers/schedule_provider.dart';
import '../../theme/app_theme.dart';
import '../shared/countdown_text.dart';
import '../shared/day_strip.dart';
import '../widget_size.dart';

export '../widget_size.dart';

/// Glassmorphism schedule widget: frosted BackdropFilter + pastel orb drift.
class ScheduleGlass extends StatefulWidget {
  const ScheduleGlass({
    super.key,
    required this.provider,
    this.size = WidgetSize.medium,
  });

  final ScheduleProvider provider;
  final WidgetSize size;

  @override
  State<ScheduleGlass> createState() => _ScheduleGlassState();
}

class _ScheduleGlassState extends State<ScheduleGlass>
    with TickerProviderStateMixin {
  late final AnimationController _orbCtrl;
  late final AnimationController _entryCtrl;

  @override
  void initState() {
    super.initState();
    _orbCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat(reverse: true);

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final disable = MediaQuery.of(context).disableAnimations;
      if (disable) {
        _entryCtrl.value = 1.0;
        _orbCtrl.value = 0.0;
      } else {
        _entryCtrl.forward();
      }
    });
  }

  @override
  void dispose() {
    _orbCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.provider,
      child: Consumer<ScheduleProvider>(
        builder: (context, prov, _) => _GlassBody(
          provider: prov,
          size: widget.size,
          orbCtrl: _orbCtrl,
          entryCtrl: _entryCtrl,
        ),
      ),
    );
  }
}

class _GlassBody extends StatelessWidget {
  const _GlassBody({
    required this.provider,
    required this.size,
    required this.orbCtrl,
    required this.entryCtrl,
  });

  final ScheduleProvider provider;
  final WidgetSize size;
  final AnimationController orbCtrl;
  final AnimationController entryCtrl;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final textDark = isDark ? AppColors.darkText : AppColors.textDark;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    final dayClasses = provider.schedulesForDay(provider.selectedWeekday);
    final nextClass = provider.nextClass;

    return LayoutBuilder(builder: (context, constraints) {
      final isSmall = size == WidgetSize.small || constraints.maxWidth < 320;

      return AnimatedBuilder(
        animation: orbCtrl,
        builder: (context, child) {
          // Smooth orb drift offsets
          final t = orbCtrl.value * math.pi;
          final ox1 = math.sin(t) * 18.0;
          final oy1 = math.cos(t) * 12.0;
          final ox2 = math.cos(t * 0.7) * 16.0;
          final oy2 = math.sin(t * 0.7) * 14.0;

          return ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // ── Background ─────────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? const [Color(0xFF13162A), Color(0xFF0C0E1B)]
                          : const [Color(0xFFEBF0FE), Color(0xFFDCE3FA)],
                    ),
                  ),
                ),
                // ── Orb 1 – lavender ──────────────────────────────
                Positioned(
                  left: -40 + ox1,
                  top: -40 + oy1,
                  child: _Orb(
                    size: constraints.maxWidth * 0.6,
                    color: AppColors.accentPurple
                        .withValues(alpha: isDark ? 0.35 : 0.45),
                  ),
                ),
                // ── Orb 2 – primary ───────────────────────────────
                Positioned(
                  right: -30 + ox2,
                  bottom: -30 + oy2,
                  child: _Orb(
                    size: constraints.maxWidth * 0.55,
                    color: primary.withValues(alpha: isDark ? 0.30 : 0.38),
                  ),
                ),
                // ── Frosted glass layer ───────────────────────────
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.white.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                    child: _GlassContent(
                      provider: provider,
                      size: size,
                      isSmall: isSmall,
                      entryCtrl: entryCtrl,
                      nextClass: nextClass,
                      dayClasses: dayClasses,
                      primary: primary,
                      textDark: textDark,
                      textMuted: textMuted,
                      isDark: isDark,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
  }
}

// ── Orb helper ────────────────────────────────────────────────────────────────

class _Orb extends StatelessWidget {
  const _Orb({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

// ── Glass content ─────────────────────────────────────────────────────────────

class _GlassContent extends StatelessWidget {
  const _GlassContent({
    required this.provider,
    required this.size,
    required this.isSmall,
    required this.entryCtrl,
    required this.nextClass,
    required this.dayClasses,
    required this.primary,
    required this.textDark,
    required this.textMuted,
    required this.isDark,
  });

  final ScheduleProvider provider;
  final WidgetSize size;
  final bool isSmall;
  final AnimationController entryCtrl;
  final Schedule? nextClass;
  final List<Schedule> dayClasses;
  final Color primary;
  final Color textDark;
  final Color textMuted;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    if (isSmall) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: _GlassNextCard(
          nextClass: nextClass,
          primary: primary,
          textDark: textDark,
          textMuted: textMuted,
          isDark: isDark,
          compact: true,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Next-class glass card ──────────────────────────────────
        _GlassNextCard(
          nextClass: nextClass,
          primary: primary,
          textDark: textDark,
          textMuted: textMuted,
          isDark: isDark,
          compact: isSmall,
        ),
        // ── Day strip (glass pill style) ──────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DayStrip(
            selectedDay: provider.selectedWeekday,
            onDaySelected: provider.selectWeekday,
          ),
        ),
        const SizedBox(height: 4),
        // ── Schedule rows ─────────────────────────────────────────
        if (dayClasses.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                'No classes today',
                style: TextStyle(fontSize: 14, color: textMuted),
              ),
            ),
          )
        else
          _GlassScheduleList(
            schedules: dayClasses,
            entryCtrl: entryCtrl,
            textDark: textDark,
            textMuted: textMuted,
            isDark: isDark,
            maxItems: size == WidgetSize.large ? dayClasses.length : 2,
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ── Glass next-class card ─────────────────────────────────────────────────────

class _GlassNextCard extends StatelessWidget {
  const _GlassNextCard({
    required this.nextClass,
    required this.primary,
    required this.textDark,
    required this.textMuted,
    required this.isDark,
    required this.compact,
  });

  final Schedule? nextClass;
  final Color primary;
  final Color textDark;
  final Color textMuted;
  final bool isDark;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            primary.withValues(alpha: isDark ? 0.22 : 0.14),
            AppColors.accentPurple.withValues(alpha: isDark ? 0.16 : 0.10),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: primary.withValues(alpha: isDark ? 0.35 : 0.25),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Padding(
            padding: EdgeInsets.all(compact ? 12 : 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Gradient border label
                      ShaderMask(
                        shaderCallback: (rect) => LinearGradient(
                          colors: [primary, AppColors.accentPurple],
                        ).createShader(rect),
                        child: Text(
                          nextClass?.isInProgress == true
                              ? 'IN PROGRESS'
                              : 'NEXT CLASS',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        nextClass?.title ?? 'No upcoming class',
                        style: TextStyle(
                          fontSize: compact ? 15 : 18,
                          fontWeight: FontWeight.w700,
                          color: textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Expanded(
                            child: CountdownText(
                              nextClass: nextClass,
                              style: TextStyle(
                                fontSize: 12,
                                color: textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (!compact &&
                              nextClass?.room != null &&
                              nextClass!.room!.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                nextClass!.room!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: textMuted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (!compact && nextClass != null)
                        Text(
                          nextClass!.timeRangeFormatted,
                          style: TextStyle(fontSize: 12, color: textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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
}

// ── Glass schedule list ───────────────────────────────────────────────────────

class _GlassScheduleList extends StatelessWidget {
  const _GlassScheduleList({
    required this.schedules,
    required this.entryCtrl,
    required this.textDark,
    required this.textMuted,
    required this.isDark,
    required this.maxItems,
  });

  final List<Schedule> schedules;
  final AnimationController entryCtrl;
  final Color textDark;
  final Color textMuted;
  final bool isDark;
  final int maxItems;

  @override
  Widget build(BuildContext context) {
    final count = schedules.length.clamp(0, maxItems);
    return Column(
      children: List.generate(count, (i) {
        final start = (i * 0.1).clamp(0.0, 0.8);
        final end = (start + 0.4).clamp(0.0, 1.0);
        final stagger = CurvedAnimation(
          parent: entryCtrl,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        );
        return AnimatedBuilder(
          animation: stagger,
          builder: (ctx, child) => Opacity(
            opacity: stagger.value,
            child: Transform.translate(
              offset: Offset(0, 10 * (1 - stagger.value)),
              child: child,
            ),
          ),
          child: _GlassRow(
            schedule: schedules[i],
            textDark: textDark,
            textMuted: textMuted,
            isDark: isDark,
          ),
        );
      }),
    );
  }
}

class _GlassRow extends StatelessWidget {
  const _GlassRow({
    required this.schedule,
    required this.textDark,
    required this.textMuted,
    required this.isDark,
  });

  final Schedule schedule;
  final Color textDark;
  final Color textMuted;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final subjectColor = Color(schedule.colorValue);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.white.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
          child: Row(
            children: [
              Container(
                width: 3.5,
                height: 24,
                decoration: BoxDecoration(
                  color: subjectColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: Text(
                  schedule.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: Text(
                  schedule.timeRangeFormatted,
                  style: TextStyle(fontSize: 12, color: textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}
