import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/task_item.dart';
import '../../providers/schedule_provider.dart';
import '../../theme/app_theme.dart';
import '../shared/animated_check.dart';
import '../shared/filter_chips_row.dart';
import '../shared/urgency_badge.dart';
import '../widget_size.dart';

export '../widget_size.dart';

/// Vertical timeline deadlines widget.
/// Renders tasks connected chronologically with stateful node dots
/// colored according to deadline urgency.
class DeadlinesTimeline extends StatefulWidget {
  const DeadlinesTimeline({
    super.key,
    required this.provider,
    this.size = WidgetSize.medium,
  });

  final ScheduleProvider provider;
  final WidgetSize size;

  @override
  State<DeadlinesTimeline> createState() => _DeadlinesTimelineState();
}

class _DeadlinesTimelineState extends State<DeadlinesTimeline>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  String? _expandedId;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
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
          final surface = isDark ? const Color(0xFF141727) : const Color(0xFFF9FAFF);
          final textPrimary = isDark ? AppColors.darkText : AppColors.textDark;
          final textMuted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

          final tasks = prov.filteredDeadlines;

          return Container(
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                CupertinoIcons.sort_down,
                                size: 16,
                                color: primary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Deadlines Timeline',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: textPrimary,
                                  letterSpacing: -0.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${tasks.length} due',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: textMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Filter Chips
                        FilterChipsRow(
                          selected: prov.deadlineFilter,
                          onSelected: (filter) {
                            prov.setDeadlineFilter(filter);
                            _entryCtrl.forward(from: 0);
                          },
                        ),
                        const SizedBox(height: 14),

                        // Timeline Items or Empty State
                        if (tasks.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text(
                                'No upcoming deadlines found',
                                style: TextStyle(fontSize: 13, color: textMuted),
                              ),
                            ),
                          )
                        else () {
                          final int maxItems = widget.size == WidgetSize.small
                              ? 2
                              : (widget.size == WidgetSize.medium ? 3 : tasks.length);
                          final count = tasks.length > maxItems ? maxItems : tasks.length;
                          return ListView.builder(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: count,
                            itemBuilder: (context, index) {
                              final item = tasks[index];
                              final isFirst = index == 0;
                              final isLast = index == count - 1;
                              final isExpanded = _expandedId == item.id;
                              final urgencyCol = prov.urgencyColor(item);

                                // Staggered Animation
                                final disableAnim = MediaQuery.of(context).disableAnimations;
                                final startInterval = (index * 0.1).clamp(0.0, 0.6);
                                final endInterval = (startInterval + 0.35).clamp(0.0, 1.0);
                                final anim = CurvedAnimation(
                                  parent: _entryCtrl,
                                  curve: Interval(startInterval, endInterval, curve: Curves.easeOutCubic),
                                );

                                final rowWidget = _buildTimelineRow(
                                  context: context,
                                  prov: prov,
                                  item: item,
                                  isFirst: isFirst,
                                  isLast: isLast,
                                  isExpanded: isExpanded,
                                  urgencyCol: urgencyCol,
                                  isDark: isDark,
                                  primary: primary,
                                  textPrimary: textPrimary,
                                  textMuted: textMuted,
                                );

                                if (disableAnim) return rowWidget;

                                return SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(-0.1, 0),
                                    end: Offset.zero,
                                  ).animate(anim),
                                  child: FadeTransition(
                                    opacity: anim,
                                    child: rowWidget,
                                  ),
                                );
                              },
                            );
                          }(),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimelineRow({
    required BuildContext context,
    required ScheduleProvider prov,
    required TaskItem item,
    required bool isFirst,
    required bool isLast,
    required bool isExpanded,
    required Color urgencyCol,
    required bool isDark,
    required Color primary,
    required Color textPrimary,
    required Color textMuted,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Vertical connector & urgency dot
          SizedBox(
            width: 28,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: isFirst ? 14 : 0,
                  bottom: isLast ? 14 : 0,
                  child: Container(
                    width: 2,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : primary.withValues(alpha: 0.2),
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: urgencyCol,
                      border: Border.all(
                        color: isDark ? const Color(0xFF141727) : Colors.white,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: urgencyCol.withValues(alpha: 0.4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Card
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _expandedId = isExpanded ? null : item.id;
                });
              },
              onLongPress: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Options for "${item.title}"'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C2034) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.05),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        AnimatedCheck(
                          isDone: item.isDone,
                          onToggle: () => prov.toggleTaskDone(item.id),
                          color: urgencyCol,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                item.title,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                  decoration: item.isDone ? TextDecoration.lineThrough : null,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.subject ?? item.typeLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: textMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        UrgencyBadge(task: item),
                      ],
                    ),
                    if (isExpanded) ...[
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(CupertinoIcons.time, size: 12, color: textMuted),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                item.dueFormatted,
                                style: TextStyle(fontSize: 11, color: textMuted),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

