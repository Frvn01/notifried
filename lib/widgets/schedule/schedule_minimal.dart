import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/schedule.dart';
import '../../providers/schedule_provider.dart';
import '../../theme/app_theme.dart';
import '../shared/countdown_text.dart';
import '../shared/day_strip.dart';
import '../widget_size.dart';

// Re-export so callers that import this file also get WidgetSize.
export '../widget_size.dart';

/// Flat, Material-card-style schedule widget. No blur, clean typography.
class ScheduleMinimal extends StatefulWidget {
  const ScheduleMinimal({
    super.key,
    required this.provider,
    this.size = WidgetSize.medium,
  });

  final ScheduleProvider provider;
  final WidgetSize size;

  @override
  State<ScheduleMinimal> createState() => _ScheduleMinimalState();
}

class _ScheduleMinimalState extends State<ScheduleMinimal>
    with TickerProviderStateMixin {
  // Entry stagger controller
  late final AnimationController _entryCtrl;
  // Shimmer for in-progress class
  late final AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    // Delay entry until first frame to respect disableAnimations.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final disable = MediaQuery.of(context).disableAnimations;
        if (disable) {
          _entryCtrl.value = 1.0;
        } else {
          _entryCtrl.forward();
        }
      }
    });
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.provider,
      child: Consumer<ScheduleProvider>(
        builder: (context, prov, _) => _MinimalBody(
          provider: prov,
          size: widget.size,
          entryCtrl: _entryCtrl,
          shimmerCtrl: _shimmerCtrl,
        ),
      ),
    );
  }
}

class _MinimalBody extends StatelessWidget {
  const _MinimalBody({
    required this.provider,
    required this.size,
    required this.entryCtrl,
    required this.shimmerCtrl,
  });

  final ScheduleProvider provider;
  final WidgetSize size;
  final AnimationController entryCtrl;
  final AnimationController shimmerCtrl;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final surface =
        isDark ? const Color(0xFF1E2138) : const Color(0xFFF8F9FF);
    final textDark = isDark ? AppColors.darkText : AppColors.textDark;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    final dayClasses = provider.schedulesForDay(provider.selectedWeekday);
    final nextClass = provider.nextClass;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = size == WidgetSize.small ||
            constraints.maxWidth < 320;
        final isLarge = size == WidgetSize.large &&
            constraints.maxWidth >= 480;

        if (isSmall) {
          return Container(
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: _NextClassCard(
                nextClass: nextClass,
                primary: primary,
                textDark: textDark,
                textMuted: textMuted,
                isDark: isDark,
                compact: true,
              ),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Next-class card ────────────────────────────────
                _NextClassCard(
                  nextClass: nextClass,
                  primary: primary,
                  textDark: textDark,
                  textMuted: textMuted,
                  isDark: isDark,
                  compact: isSmall,
                ),
                // ── Day strip ─────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DayStrip(
                    selectedDay: provider.selectedWeekday,
                    onDaySelected: provider.selectWeekday,
                  ),
                ),
                const SizedBox(height: 4),
                // ── Schedule list ──────────────────────────────────
                if (dayClasses.isEmpty)
                  _EmptyState(textMuted: textMuted)
                else
                  _StaggeredList(
                    schedules: dayClasses,
                    entryCtrl: entryCtrl,
                    shimmerCtrl: shimmerCtrl,
                    textDark: textDark,
                    textMuted: textMuted,
                    isDark: isDark,
                    isLarge: isLarge,
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Next-class hero card ──────────────────────────────────────────────────────

class _NextClassCard extends StatelessWidget {
  const _NextClassCard({
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
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: isDark ? 0.18 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primary.withValues(alpha: isDark ? 0.28 : 0.18),
        ),
      ),
      child: Row(
        children: [
          // Left: icon badge
          Container(
            width: compact ? 36 : 44,
            height: compact ? 36 : 44,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              nextClass?.isInProgress == true
                  ? Icons.play_circle_outline_rounded
                  : Icons.schedule_rounded,
              color: primary,
              size: compact ? 18 : 22,
            ),
          ),
          const SizedBox(width: 12),
          // Center: title + countdown
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
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
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: textMuted,
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
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                if (!compact && nextClass != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      nextClass!.timeRangeFormatted,
                      style: TextStyle(
                        fontSize: 12,
                        color: textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

// ── Staggered list ────────────────────────────────────────────────────────────

class _StaggeredList extends StatelessWidget {
  const _StaggeredList({
    required this.schedules,
    required this.entryCtrl,
    required this.shimmerCtrl,
    required this.textDark,
    required this.textMuted,
    required this.isDark,
    required this.isLarge,
  });

  final List<Schedule> schedules;
  final AnimationController entryCtrl;
  final AnimationController shimmerCtrl;
  final Color textDark;
  final Color textMuted;
  final bool isDark;
  final bool isLarge;

  @override
  Widget build(BuildContext context) {
    final visibleCount = isLarge ? schedules.length : schedules.length.clamp(0, 2);
    return Column(
      children: List.generate(visibleCount, (i) {
        // Stagger: row i starts at i*0.1, ends at i*0.1+0.4, clamped to [0,1]
        final start = (i * 0.1).clamp(0.0, 0.8);
        final end = (start + 0.4).clamp(0.0, 1.0);
        final stagger = CurvedAnimation(
          parent: entryCtrl,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        );
        return AnimatedBuilder(
          animation: stagger,
          builder: (context, child) => Opacity(
            opacity: stagger.value,
            child: Transform.translate(
              offset: Offset(0, 12 * (1 - stagger.value)),
              child: child,
            ),
          ),
          child: _ScheduleRow(
            schedule: schedules[i],
            shimmerCtrl: shimmerCtrl,
            textDark: textDark,
            textMuted: textMuted,
            isDark: isDark,
          ),
        );
      }),
    );
  }
}

// ── Individual schedule row ───────────────────────────────────────────────────

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({
    required this.schedule,
    required this.shimmerCtrl,
    required this.textDark,
    required this.textMuted,
    required this.isDark,
  });

  final Schedule schedule;
  final AnimationController shimmerCtrl;
  final Color textDark;
  final Color textMuted;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final subjectColor = Color(schedule.colorValue);

    Widget row = Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
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
          const SizedBox(width: 8),
          // Subject name
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
          // Time range
          Expanded(
            flex: 2,
            child: Text(
              schedule.timeRangeFormatted,
              style: TextStyle(
                fontSize: 12,
                color: textMuted,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );

    // Shimmer highlight when in-progress
    if (schedule.isInProgress) {
      row = AnimatedBuilder(
        animation: shimmerCtrl,
        builder: (context, child) {
          return ShaderMask(
            shaderCallback: (rect) {
              return LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.transparent,
                  subjectColor.withValues(alpha: 0.18),
                  Colors.transparent,
                ],
                stops: [
                  (shimmerCtrl.value - 0.3).clamp(0.0, 1.0),
                  shimmerCtrl.value,
                  (shimmerCtrl.value + 0.3).clamp(0.0, 1.0),
                ],
              ).createShader(rect);
            },
            blendMode: BlendMode.srcATop,
            child: child,
          );
        },
        child: row,
      );
    }

    return row;
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.textMuted});
  final Color textMuted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          'No classes today',
          style: TextStyle(
            fontSize: 14,
            color: textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
