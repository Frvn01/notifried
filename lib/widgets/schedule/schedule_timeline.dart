import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/schedule.dart';
import '../../providers/schedule_provider.dart';
import '../../theme/app_theme.dart';
import '../shared/countdown_text.dart';
import '../shared/day_strip.dart';
import '../widget_size.dart';

export '../widget_size.dart';

/// Vertical timeline schedule widget variant.
/// Connects classes with a continuous vertical line and stateful dots
/// (past = muted, in-progress = glowing/pulsing, upcoming = outlined/solid).
class ScheduleTimeline extends StatefulWidget {
  const ScheduleTimeline({
    super.key,
    required this.provider,
    this.size = WidgetSize.medium,
  });

  final ScheduleProvider provider;
  final WidgetSize size;

  @override
  State<ScheduleTimeline> createState() => _ScheduleTimelineState();
}

class _ScheduleTimelineState extends State<ScheduleTimeline>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryCtrl;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ScheduleProvider>.value(
      value: widget.provider,
      child: Consumer<ScheduleProvider>(
        builder: (context, prov, _) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final primary = Theme.of(context).primaryColor;
          final surface = isDark ? const Color(0xFF161929) : const Color(0xFFF9FAFF);
          final textPrimary = isDark ? AppColors.darkText : AppColors.textDark;
          final textMuted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

          final classes = prov.schedulesForDay(prov.selectedWeekday);
          final nextClass = prov.nextClass;

          return LayoutBuilder(
            builder: (context, constraints) {
              final hasBoundedH = constraints.hasBoundedHeight;
              final renderH = hasBoundedH
                  ? constraints.maxHeight
                  : (widget.size == WidgetSize.small
                      ? 180.0
                      : (widget.size == WidgetSize.medium ? 220.0 : 340.0));
              final renderW = constraints.hasBoundedWidth ? constraints.maxWidth : 380.0;
              final isSquare = renderW < 240 && renderH >= 120;
              final isSlimBar = renderH < 115;
              final isMedium = renderH < 210;

              return Container(
                width: double.infinity,
                height: hasBoundedH ? double.infinity : null,
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : primary.withValues(alpha: 0.12),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.45)
                          : primary.withValues(alpha: 0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Builder(
                    builder: (context) {
                      // ── Square 2x2 layout ──────────────────────────────────
                      if (isSquare || (widget.size == WidgetSize.small && renderW < 240)) {
                        return Padding(
                          padding: const EdgeInsets.all(12),
                          child: _buildNextClassCard(
                            context,
                            nextClass: nextClass,
                            isDark: isDark,
                            primary: primary,
                            textPrimary: textPrimary,
                            textMuted: textMuted,
                          ),
                        );
                      }

                      // ── Slim Bar layout (renderH < 115) ─────────────────────
                      if (isSlimBar) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          child: _buildSlimBar(
                            context,
                            nextClass: nextClass,
                            isDark: isDark,
                            primary: primary,
                            textPrimary: textPrimary,
                            textMuted: textMuted,
                          ),
                        );
                      }

                      // ── Medium & Large layouts ──────────────────────────────
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Next Class Hero Card
                            _buildNextClassCard(
                              context,
                              nextClass: nextClass,
                              isDark: isDark,
                              primary: primary,
                              textPrimary: textPrimary,
                              textMuted: textMuted,
                            ),
                            if (!isMedium) ...[
                              const SizedBox(height: 12),
                              // Day Strip
                              DayStrip(
                                selectedDay: prov.selectedWeekday,
                                onDaySelected: (day) {
                                  prov.selectWeekday(day);
                                  if (!_entryCtrl.isAnimating) {
                                    _entryCtrl.forward(from: 0);
                                  }
                                },
                              ),
                            ],
                            const SizedBox(height: 12),

                            // Timeline Header / Count
                            Row(
                              children: [
                                Icon(
                                  CupertinoIcons.time,
                                  size: 13,
                                  color: primary,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '${classes.length} ${classes.length == 1 ? 'class' : 'classes'} on timeline',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: textMuted,
                                      letterSpacing: 0.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Timeline list or empty state
                            if (classes.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                child: Center(
                                  child: Text(
                                    'No classes scheduled for this day',
                                    style: TextStyle(fontSize: 13, color: textMuted),
                                  ),
                                ),
                              )
                            else ...[
                              ListView.builder(
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: isMedium
                                    ? (classes.length > 2 ? 2 : classes.length)
                                    : classes.length,
                                itemBuilder: (context, index) {
                                  final item = classes[index];
                                  final isFirst = index == 0;
                                  final isLast = index == (isMedium
                                      ? (classes.length > 2 ? 1 : classes.length - 1)
                                      : classes.length - 1);

                                  return _buildTimelineRow(
                                    item: item,
                                    isFirst: isFirst,
                                    isLast: isLast,
                                    isDark: isDark,
                                    primary: primary,
                                    textPrimary: textPrimary,
                                    textMuted: textMuted,
                                  );
                                },
                              ),
                              // If only 1 class in Large layout, fill space with an executive productive card
                              if (!isMedium && classes.length == 1 && renderH >= 260)
                                Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: primary.withValues(alpha: isDark ? 0.12 : 0.05),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: primary.withValues(alpha: 0.18),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: primary.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(CupertinoIcons.sparkles, size: 14, color: primary),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'All clear after this class!',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                                color: textPrimary,
                                              ),
                                            ),
                                            Text(
                                              'No more subjects scheduled for today.',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: textMuted,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNextClassCard(
    BuildContext context, {
    required Schedule? nextClass,
    required bool isDark,
    required Color primary,
    required Color textPrimary,
    required Color textMuted,
  }) {
    final bg = isDark
        ? const Color(0xFF1F2338)
        : primary.withValues(alpha: 0.08);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primary.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              CupertinoIcons.book_fill,
              color: primary,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  nextClass?.title ?? 'No upcoming class',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                if (nextClass != null)
                  Text(
                    nextClass.timeRangeFormatted,
                    style: TextStyle(
                      fontSize: 11,
                      color: textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                else
                  Text(
                    'Enjoy your free time',
                    style: TextStyle(
                      fontSize: 11,
                      color: textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                if (nextClass?.room != null && nextClass!.room!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      children: [
                        Icon(CupertinoIcons.location_solid, size: 9, color: textMuted),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            nextClass.room!,
                            style: TextStyle(
                              fontSize: 10,
                              color: textMuted,
                              fontWeight: FontWeight.w600,
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
          ),
          const SizedBox(width: 8),
          Flexible(
            child: CountdownText(
              nextClass: nextClass,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlimBar(
    BuildContext context, {
    required Schedule? nextClass,
    required bool isDark,
    required Color primary,
    required Color textPrimary,
    required Color textMuted,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            CupertinoIcons.book_fill,
            color: primary,
            size: 14,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                nextClass?.title ?? 'No upcoming class',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Row(
                children: [
                  if (nextClass != null)
                    Text(
                      nextClass.timeRangeFormatted,
                      style: TextStyle(fontSize: 10, color: textMuted, fontWeight: FontWeight.w600),
                    ),
                  if (nextClass?.room != null && nextClass!.room!.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Icon(CupertinoIcons.location_solid, size: 8, color: textMuted),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        nextClass.room!,
                        style: TextStyle(fontSize: 10, color: textMuted, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        CountdownText(
          nextClass: nextClass,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: primary),
        ),
      ],
    );
  }

  Widget _buildTimelineRow({
    required Schedule item,
    required bool isFirst,
    required bool isLast,
    required bool isDark,
    required Color primary,
    required Color textPrimary,
    required Color textMuted,
  }) {
    final isInProgress = item.isInProgress;
    final isPast = item.isPastDue;
    final itemColor = Color(item.colorValue);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Vertical Line + Node Dot
          SizedBox(
            width: 28,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Connecting vertical line
                Positioned(
                  top: isFirst ? 14 : 0,
                  bottom: isLast ? 14 : 0,
                  child: Container(
                    width: 2,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.15)
                        : primary.withValues(alpha: 0.25),
                  ),
                ),
                // Indicator Dot
                Align(
                  alignment: Alignment.center,
                  child: isInProgress
                      ? _buildPulsingDot(itemColor)
                      : Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isPast
                                ? textMuted.withValues(alpha: 0.4)
                                : itemColor,
                            border: Border.all(
                              color: isDark ? const Color(0xFF161929) : Colors.white,
                              width: 1.5,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Content Card
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isInProgress
                    ? primary.withValues(alpha: isDark ? 0.18 : 0.08)
                    : (isDark ? const Color(0xFF1E2238) : Colors.white),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isInProgress
                      ? primary.withValues(alpha: 0.4)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.05)),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isInProgress ? FontWeight.w800 : FontWeight.w600,
                            color: isPast
                                ? textMuted
                                : textPrimary,
                            decoration: isPast ? TextDecoration.lineThrough : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            if (item.room != null && item.room!.isNotEmpty) ...[
                              Icon(
                                CupertinoIcons.location_solid,
                                size: 10,
                                color: textMuted,
                              ),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  item.room!,
                                  style: TextStyle(fontSize: 10, color: textMuted),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              item.durationFormatted,
                              style: TextStyle(fontSize: 10, color: textMuted),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item.timeRangeFormatted,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isInProgress ? primary : textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPulsingDot(Color color) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 8.0, end: 14.0),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      builder: (context, size, _) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.6),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        );
      },
    );
  }
}

