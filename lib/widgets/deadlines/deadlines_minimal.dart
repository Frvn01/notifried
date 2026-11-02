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

/// Flat-card style deadlines list with staggered entry animations and
/// urgency-colored left borders. Supports dark mode natively.
class DeadlinesMinimal extends StatefulWidget {
  const DeadlinesMinimal({
    super.key,
    required this.provider,
    required this.size,
  });

  final ScheduleProvider provider;
  final WidgetSize size;

  @override
  State<DeadlinesMinimal> createState() => _DeadlinesMinimalState();
}

class _DeadlinesMinimalState extends State<DeadlinesMinimal>
    with TickerProviderStateMixin {
  // Controls staggered entry for the current list
  late AnimationController _staggerCtrl;

  // Track the filter to re-trigger stagger on change
  String _lastFilter = '';

  @override
  void initState() {
    super.initState();
    _staggerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _lastFilter = widget.provider.deadlineFilter;
    _runStagger();
  }

  void _runStagger() {
    _staggerCtrl.forward(from: 0);
  }

  @override
  void dispose() {
    _staggerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ScheduleProvider>(
      builder: (context, prov, _) {
        // Re-trigger stagger when filter changes
        if (_lastFilter != prov.deadlineFilter) {
          _lastFilter = prov.deadlineFilter;
          WidgetsBinding.instance.addPostFrameCallback((_) => _runStagger());
        }

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bg = isDark ? const Color(0xFF111320) : Colors.white;

        return Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'Deadlines',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.darkText : AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 12),

                // Filter chips
                FilterChipsRow(
                  selected: prov.deadlineFilter,
                  onSelected: prov.setDeadlineFilter,
                ),
                const SizedBox(height: 12),

                // Animated list swap on filter change
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, anim) =>
                      FadeTransition(opacity: anim, child: child),
                  child: KeyedSubtree(
                    key: ValueKey<String>(prov.deadlineFilter),
                    child: _buildList(context, prov, isDark),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildList(
      BuildContext context, ScheduleProvider prov, bool isDark) {
    final items = prov.filteredDeadlines;
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            'No upcoming deadlines',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
            ),
          ),
        ),
      );
    }

    final int maxItems = widget.size == WidgetSize.small
        ? 2
        : (widget.size == WidgetSize.medium ? 2 : items.length);
    final count = items.length > maxItems ? maxItems : items.length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        // Each row staggered by 60 ms
        final start = (i * 0.12).clamp(0.0, 0.85);
        final end = (start + 0.35).clamp(0.0, 1.0);
        final interval = CurvedAnimation(
          parent: _staggerCtrl,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        );
        return _MinimalRow(
          key: ValueKey(items[i].id),
          task: items[i],
          entryAnim: interval,
          isDark: isDark,
          urgencyColor: prov.urgencyColor(items[i]),
          onToggle: () => prov.toggleTaskDone(items[i].id),
        );
      }),
    );
  }
}

// ── Per-row widget ────────────────────────────────────────────────────────────

class _MinimalRow extends StatefulWidget {
  const _MinimalRow({
    super.key,
    required this.task,
    required this.entryAnim,
    required this.isDark,
    required this.urgencyColor,
    required this.onToggle,
  });

  final TaskItem task;
  final Animation<double> entryAnim;
  final bool isDark;
  final Color urgencyColor;
  final VoidCallback onToggle;

  @override
  State<_MinimalRow> createState() => _MinimalRowState();
}

class _MinimalRowState extends State<_MinimalRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.task;
    final reduce = MediaQuery.of(context).disableAnimations;
    final surfaceColor = widget.isDark
        ? const Color(0xFF1E2138)
        : const Color(0xFFF7F8FC);

    // Fade + slide-up entry
    Widget row = FadeTransition(
      opacity: widget.entryAnim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.18),
          end: Offset.zero,
        ).animate(widget.entryAnim),
        child: GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          onLongPress: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Snooze / Edit coming soon')),
            );
          },
          child: AnimatedContainer(
            duration: reduce
                ? Duration.zero
                : const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : widget.urgencyColor.withValues(alpha: 0.25),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: widget.isDark ? 0.2 : 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 3.5,
                        height: 28,
                        decoration: BoxDecoration(
                          color: widget.urgencyColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Type icon
                      Icon(
                        t.typeIcon,
                        size: 16,
                        color: widget.urgencyColor,
                      ),
                      const SizedBox(width: 8),

                      // Title + subject
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: widget.isDark
                                    ? AppColors.darkText
                                    : AppColors.textDark,
                                decoration: t.isDone
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            if (t.subject != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                t.subject!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: widget.isDark
                                      ? AppColors.darkTextMuted
                                      : AppColors.textMuted,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Urgency badge
                      UrgencyBadge(task: t),
                      const SizedBox(width: 8),

                      // Animated checkbox
                      AnimatedCheck(
                        isDone: t.isDone,
                        onToggle: widget.onToggle,
                        color: widget.urgencyColor,
                      ),
                    ],
                  ),

                  // Expandable details
                  AnimatedCrossFade(
                    firstChild: const SizedBox.shrink(),
                    secondChild: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: _ExpandedDetails(
                        task: t,
                        isDark: widget.isDark,
                      ),
                    ),
                    crossFadeState: _expanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: reduce
                        ? Duration.zero
                        : const Duration(milliseconds: 260),
                    sizeCurve: Curves.easeOutCubic,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // Skip animation if system requests reduced motion
    if (reduce) return row;
    return AnimatedBuilder(
      animation: widget.entryAnim,
      builder: (_, child) => child!,
      child: row,
    );
  }
}

// ── Shared expanded detail panel ──────────────────────────────────────────────

class _ExpandedDetails extends StatelessWidget {
  const _ExpandedDetails({
    required this.task,
    required this.isDark,
  });

  final TaskItem task;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final muted =
        isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: muted.withValues(alpha: 0.25), height: 1),
        const SizedBox(height: 8),
        _DetailRow(
          icon: CupertinoIcons.calendar,
          text: task.dueFormatted,
          muted: muted,
        ),
        if (task.notes != null && task.notes!.isNotEmpty) ...[
          const SizedBox(height: 4),
          _DetailRow(
            icon: CupertinoIcons.doc_text,
            text: task.notes!,
            muted: muted,
            maxLines: 2,
          ),
        ],
        const SizedBox(height: 4),
        _DetailRow(
          icon: CupertinoIcons.flag,
          text: '${task.priorityLabel} priority · ${task.typeLabel}',
          muted: muted,
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.text,
    required this.muted,
    this.maxLines = 1,
  });

  final IconData icon;
  final String text;
  final Color muted;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: muted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: muted),
          ),
        ),
      ],
    );
  }
}

