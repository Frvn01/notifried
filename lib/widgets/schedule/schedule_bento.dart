import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/schedule_provider.dart';
import '../../theme/app_theme.dart';
import '../shared/countdown_text.dart';
import '../shared/day_strip.dart';
import '../widget_size.dart';

export '../widget_size.dart';

/// Bento Grid style schedule widget.
/// Modular tile arrangement with large countdown metric tile,
/// compact day strip, and subject quick-chips.
class ScheduleBento extends StatefulWidget {
  const ScheduleBento({
    super.key,
    required this.provider,
    this.size = WidgetSize.medium,
  });

  final ScheduleProvider provider;
  final WidgetSize size;

  @override
  State<ScheduleBento> createState() => _ScheduleBentoState();
}

class _ScheduleBentoState extends State<ScheduleBento>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleCtrl;
  String? _expandedId;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleCtrl.forward();
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
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
          final surface = isDark ? const Color(0xFF141727) : const Color(0xFFF6F8FD);
          final tileSurface = isDark ? const Color(0xFF1E2238) : Colors.white;
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
                      ? 100.0
                      : (widget.size == WidgetSize.medium ? 180.0 : 340.0));
              final renderW = constraints.hasBoundedWidth ? constraints.maxWidth : 380.0;
              final isSquare = renderW < 240 && renderH >= 120;
              final isSlimBar = renderH < 115;
              final isMedium = renderH < 210;

              return Container(
                width: double.infinity,
                height: hasBoundedH ? double.infinity : null,
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : primary.withValues(alpha: 0.14),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.4)
                          : primary.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: Builder(
                    builder: (context) {
                      // ── Square 2x2 layout (e.g. 200x200) ──────────────────────
                      if (isSquare || (widget.size == WidgetSize.small && renderW < 240)) {
                    return Padding(
                      padding: const EdgeInsets.all(12),
                      child: _buildBentoTile(
                        isDark: isDark,
                        tileSurface: tileSurface,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: primary.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'NEXT CLASS',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: primary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  CupertinoIcons.timer,
                                  size: 14,
                                  color: primary,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: CountdownText(
                                nextClass: nextClass,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: textPrimary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              nextClass?.title ?? 'No classes today',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            if (nextClass != null)
                              Text(
                                nextClass.timeRangeFormatted,
                                style: TextStyle(fontSize: 10, color: textMuted, fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            if (nextClass?.room != null && nextClass!.room!.isNotEmpty)
                              Row(
                                children: [
                                  Icon(CupertinoIcons.location_solid, size: 9, color: textMuted),
                                  const SizedBox(width: 3),
                                  Expanded(
                                    child: Text(
                                      nextClass.room!,
                                      style: TextStyle(fontSize: 10, color: textMuted, fontWeight: FontWeight.w600),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    );
                  }

                  // ── Slim bar layout (height < 115, e.g. 400x90) ───────────
                  if (isSlimBar) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(CupertinoIcons.clock_fill, size: 18, color: primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: CountdownText(
                                    nextClass: nextClass,
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                      color: textPrimary,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        nextClass?.title ?? 'No class today',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: primary),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (nextClass?.room != null && nextClass!.room!.isNotEmpty) ...[
                                      const SizedBox(width: 6),
                                      Icon(CupertinoIcons.location_solid, size: 9, color: textMuted),
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
                        ],
                      ),
                    );
                  }

                  // ── Medium card layout (115 ≤ height < 210, e.g. 400x170) ─
                  if (isMedium) {
                    return Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Hero row: countdown tile + schedule count tile
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  flex: 58,
                                  child: _buildBentoTile(
                                    isDark: isDark,
                                    tileSurface: tileSurface,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: primary.withValues(alpha: 0.16),
                                                borderRadius: BorderRadius.circular(7),
                                              ),
                                              child: Text('NEXT CLASS',
                                                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: primary, letterSpacing: 0.5)),
                                            ),
                                            const Spacer(),
                                            Icon(CupertinoIcons.timer, size: 12, color: primary),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerLeft,
                                          child: CountdownText(
                                            nextClass: nextClass,
                                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textPrimary, letterSpacing: -0.5),
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          nextClass?.title ?? 'No class today',
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: primary),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        // Time on its own line
                                        if (nextClass != null)
                                          Text(
                                            nextClass.timeRangeFormatted,
                                            style: TextStyle(fontSize: 10, color: textMuted, fontWeight: FontWeight.w600),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        // Room on its own line with pin icon
                                        if (nextClass?.room != null && nextClass!.room!.isNotEmpty)
                                          Row(
                                            children: [
                                              Icon(CupertinoIcons.location_solid, size: 9, color: textMuted),
                                              const SizedBox(width: 3),
                                              Expanded(
                                                child: Text(
                                                  nextClass.room!,
                                                  style: TextStyle(fontSize: 10, color: textMuted, fontWeight: FontWeight.w600),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 42,
                                  child: _buildBentoTile(
                                    isDark: isDark,
                                    tileSurface: tileSurface,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(CupertinoIcons.calendar_today, size: 11, color: primary),
                                            const SizedBox(width: 3),
                                            Text('SCHEDULE',
                                                style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: textMuted, letterSpacing: 0.5)),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text('${classes.length}',
                                            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: textPrimary, height: 1.0)),
                                        Text(
                                          classes.length == 1 ? 'subject today' : 'subjects today',
                                          style: TextStyle(fontSize: 9, color: textMuted, fontWeight: FontWeight.w600),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Up to 2 subject chips
                          if (classes.isNotEmpty)
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: classes.take(2).map((item) {
                                final itemColor = Color(item.colorValue);
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: itemColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: itemColor.withValues(alpha: 0.3), width: 1),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: itemColor)),
                                      const SizedBox(width: 5),
                                      Text(item.title,
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textPrimary),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                      const SizedBox(width: 5),
                                      Text(item.timeRangeFormatted,
                                          style: TextStyle(fontSize: 9, color: textMuted)),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    );
                  }

                  // ── Full / Large layout (height ≥ 220) ────────────────────
                  // Two-column bento tiles + day-strip + full chip grid.
                  final displayClasses = classes;

                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Top Bento Grid (2 Tiles: Big Countdown & Status Tile)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Big Hero Countdown Tile (58% width)
                            Expanded(
                              flex: 58,
                              child: _buildBentoTile(
                                isDark: isDark,
                                tileSurface: tileSurface,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: primary.withValues(alpha: 0.16),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'NEXT CLASS',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                              color: primary,
                                              letterSpacing: 0.6,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        Icon(
                                          CupertinoIcons.timer,
                                          size: 14,
                                          color: primary,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: CountdownText(
                                        nextClass: nextClass,
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                          color: textPrimary,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      nextClass?.title ?? 'No classes today',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: primary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                     const SizedBox(height: 3),
                                    // Time on its own line
                                    if (nextClass != null)
                                      Text(
                                        nextClass.timeRangeFormatted,
                                        style: TextStyle(fontSize: 10, color: textMuted, fontWeight: FontWeight.w600),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    // Room on its own line with pin icon (full room name, not truncated with time)
                                    if (nextClass?.room != null && nextClass!.room!.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Row(
                                          children: [
                                            Icon(CupertinoIcons.location_solid, size: 10, color: textMuted),
                                            const SizedBox(width: 3),
                                            Expanded(
                                              child: Text(
                                                nextClass.room!,
                                                style: TextStyle(fontSize: 10, color: textMuted, fontWeight: FontWeight.w600),
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
                            ),
                            const SizedBox(width: 10),

                            // Day Summary Tile (42% width)
                            Expanded(
                              flex: 42,
                              child: _buildBentoTile(
                                isDark: isDark,
                                tileSurface: tileSurface,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          CupertinoIcons.calendar_today,
                                          size: 13,
                                          color: primary,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            'SCHEDULE',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                              color: textMuted,
                                              letterSpacing: 0.6,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${classes.length}',
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                        color: textPrimary,
                                        height: 1.1,
                                      ),
                                    ),
                                    Text(
                                      classes.length == 1 ? 'subject today' : 'subjects today',
                                      style: TextStyle(fontSize: 10, color: textMuted, fontWeight: FontWeight.w600),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Day Strip — shows today highlighted; in-app taps work,
                        // but taps on the Android home-screen widget are not possible
                        // since the widget is rendered as a static PNG bitmap.
                        DayStrip(
                          selectedDay: prov.selectedWeekday,
                          onDaySelected: (day) {
                            prov.selectWeekday(day);
                            // Guard: skip animation when tickers are disabled (offscreen render)
                            if (_scaleCtrl.isAnimating == false) {
                              _scaleCtrl.forward(from: 0);
                            }
                          },
                        ),
                        const SizedBox(height: 12),

                        // Bento Subject Chips Grid
                        if (displayClasses.isEmpty)
                          _buildEmptyDayCard(
                            context,
                            prov: prov,
                            isDark: isDark,
                            primary: primary,
                            tileSurface: tileSurface,
                            textPrimary: textPrimary,
                            textMuted: textMuted,
                          )
                        else ...[
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: displayClasses.map((item) {
                                final isExpanded = _expandedId == item.id;
                                final isInProgress = item.isInProgress;
                                final itemColor = Color(item.colorValue);

                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _expandedId = isExpanded ? null : item.id;
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    curve: Curves.easeOutCubic,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isInProgress
                                          ? primary.withValues(alpha: isDark ? 0.25 : 0.12)
                                          : tileSurface,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isInProgress
                                            ? primary
                                            : isExpanded
                                                ? itemColor
                                                : isDark
                                                    ? Colors.white.withValues(alpha: 0.08)
                                                    : Colors.black.withValues(alpha: 0.06),
                                        width: isInProgress || isExpanded ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: itemColor,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            item.title,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: textPrimary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          item.timeRangeFormatted,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: textMuted,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          // If only 1 class and widget has vertical room (e.g. 400x260 or 400x380),
                          // show an upcoming task or status tile so there is no awkward blank space.
                          if (displayClasses.length == 1 && renderH >= 230) ...[
                            const SizedBox(height: 10),
                            _buildRestOfDayTile(
                              context,
                              prov: prov,
                              isDark: isDark,
                              primary: primary,
                              tileSurface: tileSurface,
                              textPrimary: textPrimary,
                              textMuted: textMuted,
                            ),
                          ],
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

  Widget _buildRestOfDayTile(
    BuildContext context, {
    required ScheduleProvider prov,
    required bool isDark,
    required Color primary,
    required Color tileSurface,
    required Color textPrimary,
    required Color textMuted,
  }) {
    final pendingTasks = prov.tasks.where((t) => !t.isDone).toList();
    final topTask = pendingTasks.isNotEmpty ? pendingTasks.first : null;

    if (topTask != null) {
      final urgencyCol = prov.urgencyColor(topTask);
      return _buildBentoTile(
        isDark: isDark,
        tileSurface: tileSurface,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: urgencyCol.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(topTask.typeIcon, size: 14, color: urgencyCol),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: urgencyCol.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          topTask.type.toUpperCase(),
                          style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: urgencyCol),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Due ${topTask.dueFormatted}',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    topTask.title,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(CupertinoIcons.chevron_right, size: 12, color: textMuted),
          ],
        ),
      );
    }

    return _buildBentoTile(
      isDark: isDark,
      tileSurface: tileSurface,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFF00B894).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(CupertinoIcons.checkmark_seal_fill, size: 14, color: Color(0xFF00B894)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'No more classes today',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: textPrimary),
                ),
                Text(
                  'All clear! Review your materials or relax.',
                  style: TextStyle(fontSize: 9, color: textMuted, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDayCard(
    BuildContext context, {
    required ScheduleProvider prov,
    required bool isDark,
    required Color primary,
    required Color tileSurface,
    required Color textPrimary,
    required Color textMuted,
  }) {
    final pendingTasks = prov.tasks.where((t) => !t.isDone).toList();
    final topTask = pendingTasks.isNotEmpty ? pendingTasks.first : null;

    return _buildBentoTile(
      isDark: isDark,
      tileSurface: tileSurface,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              topTask != null ? CupertinoIcons.square_list_fill : CupertinoIcons.calendar_badge_minus,
              size: 14,
              color: primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  topTask != null ? 'Free Day · Next: ${topTask.title}' : 'No classes scheduled for this day',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  topTask != null ? 'Due ${topTask.dueFormatted} · Tap to view checklist' : 'Enjoy your free time!',
                  style: TextStyle(fontSize: 9, color: textMuted, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBentoTile({
    required bool isDark,
    required Color tileSurface,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tileSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
