import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/schedule_provider.dart';
import '../../theme/app_theme.dart';
import '../shared/animated_check.dart';
import '../shared/filter_chips_row.dart';
import '../widget_size.dart';

export '../widget_size.dart';

/// Bento Grid style deadlines widget.
/// Renders tasks as modular Bento tiles with big countdown numbers,
/// urgency-tinted cards, and interactive tap-to-expand states.
class DeadlinesBento extends StatefulWidget {
  const DeadlinesBento({
    super.key,
    required this.provider,
    this.size = WidgetSize.medium,
  });

  final ScheduleProvider provider;
  final WidgetSize size;

  @override
  State<DeadlinesBento> createState() => _DeadlinesBentoState();
}

class _DeadlinesBentoState extends State<DeadlinesBento>
    with SingleTickerProviderStateMixin {
  late final AnimationController _staggerCtrl;
  String? _expandedId;

  @override
  void initState() {
    super.initState();
    _staggerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _staggerCtrl.forward();
  }

  @override
  void dispose() {
    _staggerCtrl.dispose();
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
          final surface = isDark ? const Color(0xFF131627) : const Color(0xFFF7F8FE);
          final tileSurface = isDark ? const Color(0xFF1C2035) : Colors.white;
          final textPrimary = isDark ? AppColors.darkText : AppColors.textDark;
          final textMuted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

          final tasks = prov.filteredDeadlines;

          // Compute counts for summary
          final examCount = tasks.where((t) => t.type == 'exam').length;
          final quizCount = tasks.where((t) => t.type == 'quiz').length;
          final otherCount = tasks.length - examCount - quizCount;

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
                      // ── Slim Bar layout (renderH < 115) ─────────────────────
                      if (isSlimBar) {
                        final topTask = tasks.isNotEmpty ? tasks.first : null;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: (topTask != null ? prov.urgencyColor(topTask) : primary).withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  topTask != null ? topTask.typeIcon : CupertinoIcons.checkmark_alt_circle_fill,
                                  color: topTask != null ? prov.urgencyColor(topTask) : primary,
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
                                      topTask?.title ?? 'All tasks completed!',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: textPrimary,
                                        decoration: (topTask?.isDone ?? false) ? TextDecoration.lineThrough : null,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (topTask != null)
                                      Text(
                                        '${topTask.subject != null ? "${topTask.subject} • " : ""}Due ${topTask.dueFormatted}',
                                        style: TextStyle(fontSize: 10, color: textMuted, fontWeight: FontWeight.w600),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                              if (topTask != null)
                                AnimatedCheck(
                                  isDone: topTask.isDone,
                                  onToggle: () => prov.toggleTaskDone(topTask.id),
                                  color: prov.urgencyColor(topTask),
                                ),
                            ],
                          ),
                        );
                      }

                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                        // Bento Header Row with Summary
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                CupertinoIcons.square_grid_2x2_fill,
                                size: 16,
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
                                    prov.deadlineFilter == 'task'
                                        ? 'Academic Tasks'
                                        : (prov.deadlineFilter == 'all'
                                            ? 'Academic Deadlines'
                                            : '${prov.deadlineFilter[0].toUpperCase()}${prov.deadlineFilter.substring(1)} Deadlines'),
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: textPrimary,
                                      letterSpacing: -0.3,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '$examCount exams · $quizCount quizzes · $otherCount tasks',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: textMuted,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Filter Chips (omit in small widget)
                        if (widget.size != WidgetSize.small) ...[
                          FilterChipsRow(
                            selected: prov.deadlineFilter,
                            onSelected: (filter) {
                              prov.setDeadlineFilter(filter);
                              _staggerCtrl.forward(from: 0);
                            },
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Bento Grid Tiles
                        if (tasks.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text(
                                'No deadlines in this category',
                                style: TextStyle(fontSize: 13, color: textMuted),
                              ),
                            ),
                          )
                        else
                          GridView.builder(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: isSquare ? 1 : 2,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                childAspectRatio: isSquare ? 2.8 : 1.45,
                              ),
                              itemCount: (isSquare || isMedium || widget.size == WidgetSize.small || widget.size == WidgetSize.medium)
                                  ? (tasks.length > 2 ? 2 : tasks.length)
                                  : tasks.length,
                              itemBuilder: (context, index) {
                                final item = tasks[index];
                                final isExpanded = _expandedId == item.id;
                                final urgencyCol = prov.urgencyColor(item);
                                final days = item.dueDate.difference(DateTime.now()).inDays;

                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _expandedId = isExpanded ? null : item.id;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: tileSurface,
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: urgencyCol.withValues(alpha: isDark ? 0.45 : 0.25),
                                        width: 1.2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: urgencyCol.withValues(alpha: 0.08),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Top Row: Type Icon & Checkbox
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: urgencyCol.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Icon(
                                                item.typeIcon,
                                                size: 14,
                                                color: urgencyCol,
                                              ),
                                            ),
                                            AnimatedCheck(
                                              isDone: item.isDone,
                                              onToggle: () => prov.toggleTaskDone(item.id),
                                              color: urgencyCol,
                                            ),
                                          ],
                                        ),

                                        // Title & Subject
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              item.title,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w800,
                                                color: textPrimary,
                                                decoration: item.isDone ? TextDecoration.lineThrough : null,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              item.subject ?? item.typeLabel,
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: textMuted,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),

                                        // Bottom Row: Urgency text
                                        Row(
                                          children: [
                                            Container(
                                              width: 6,
                                              height: 6,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: urgencyCol,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                days <= 0
                                                    ? 'Due Today'
                                                    : days == 1
                                                        ? 'Due Tomorrow'
                                                        : 'in $days days',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  color: urgencyCol,
                                                ),
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
                              },
                            ),
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
}
