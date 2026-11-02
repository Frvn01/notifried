import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/task_item.dart';
import '../../providers/schedule_provider.dart';
import '../../theme/app_theme.dart';
import '../shared/animated_check.dart';
import '../shared/urgency_badge.dart';
import '../widget_size.dart';

/// Glassmorphic deadlines widget with frosted blur cards, gradient orbs,
/// and glass-pill filter chips.
class DeadlinesGlass extends StatefulWidget {
  const DeadlinesGlass({
    super.key,
    required this.provider,
    required this.size,
  });

  final ScheduleProvider provider;
  final WidgetSize size;

  @override
  State<DeadlinesGlass> createState() => _DeadlinesGlassState();
}

class _DeadlinesGlassState extends State<DeadlinesGlass>
    with SingleTickerProviderStateMixin {
  // Drives slow orb drift (8 s cycle)
  late final AnimationController _orbCtrl;

  @override
  void initState() {
    super.initState();
    _orbCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _orbCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ScheduleProvider>(
      builder: (context, prov, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        final gradTop = isDark
            ? const Color(0xFF1A1D35)
            : const Color(0xFFD6DBF7);
        final gradBottom = isDark
            ? const Color(0xFF0D1020)
            : const Color(0xFFC1C9F5);

        return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [gradTop, gradBottom],
              ),
            ),
            child: Stack(
              children: [
                // ── Background orbs ─────────────────────────────────────
                _AnimatedOrb(
                  controller: _orbCtrl,
                  alignment: const Alignment(-0.6, -0.7),
                  targetAlignment: const Alignment(-0.3, -0.4),
                  size: 200,
                  color: AppColors.accentPurple.withValues(alpha: 0.22),
                ),
                _AnimatedOrb(
                  controller: _orbCtrl,
                  alignment: const Alignment(0.7, 0.5),
                  targetAlignment: const Alignment(0.4, 0.8),
                  size: 160,
                  color: AppColors.primaryIndigo.withValues(alpha: 0.18),
                ),

                // ── Content ──────────────────────────────────────────────
                Padding(
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
                          color: isDark
                              ? AppColors.darkText
                              : AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Glass pill filter chips
                      _GlassFilterChips(
                        selected: prov.deadlineFilter,
                        onSelected: prov.setDeadlineFilter,
                      ),
                      const SizedBox(height: 12),

                      // Animated switcher wraps list for smooth filter swap
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 320),
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
    final displayItems = items.take(maxItems).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: displayItems
          .map((t) => _GlassDeadlineRow(
                key: ValueKey(t.id),
                task: t,
                urgencyColor: prov.urgencyColor(t),
                isDark: isDark,
                onToggle: () => prov.toggleTaskDone(t.id),
              ))
          .toList(),
    );
  }
}

// ── Orb widget ────────────────────────────────────────────────────────────────

class _AnimatedOrb extends StatelessWidget {
  const _AnimatedOrb({
    required this.controller,
    required this.alignment,
    required this.targetAlignment,
    required this.size,
    required this.color,
  });

  final AnimationController controller;
  final Alignment alignment;
  final Alignment targetAlignment;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    if (reduce) {
      return Positioned.fill(
        child: Align(
          alignment: alignment,
          child: _orbCircle(size, color),
        ),
      );
    }
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final lerped = Alignment.lerp(
          alignment,
          targetAlignment,
          controller.value,
        )!;
        return Positioned.fill(
          child: Align(
            alignment: lerped,
            child: _orbCircle(size, color),
          ),
        );
      },
    );
  }

  Widget _orbCircle(double s, Color c) => Container(
        width: s,
        height: s,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: c,
        ),
      );
}

// ── Glass filter chips ────────────────────────────────────────────────────────

class _GlassFilterChips extends StatelessWidget {
  const _GlassFilterChips({
    required this.selected,
    required this.onSelected,
  });

  final String selected;
  final void Function(String) onSelected;

  static const _chips = [
    ('all', 'All'),
    ('exam', 'Exams'),
    ('quiz', 'Quizzes'),
    ('task', 'Tasks'),
  ];

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Row(
      children: _chips.map((c) {
        final isSelected = c.$1 == selected;
        return Flexible(
          child: GestureDetector(
            onTap: () => onSelected(c.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.only(right: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? primary.withValues(alpha: 0.75)
                          : Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? primary.withValues(alpha: 0.8)
                            : Colors.white.withValues(alpha: 0.3),
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      c.$2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Per-row glass card ────────────────────────────────────────────────────────

class _GlassDeadlineRow extends StatefulWidget {
  const _GlassDeadlineRow({
    super.key,
    required this.task,
    required this.urgencyColor,
    required this.isDark,
    required this.onToggle,
  });

  final TaskItem task;
  final Color urgencyColor;
  final bool isDark;
  final VoidCallback onToggle;

  @override
  State<_GlassDeadlineRow> createState() => _GlassDeadlineRowState();
}

class _GlassDeadlineRowState extends State<_GlassDeadlineRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.task;
    final reduce = MediaQuery.of(context).disableAnimations;

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      onLongPress: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Snooze / Edit coming soon')),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: AnimatedContainer(
              duration: reduce
                  ? Duration.zero
                  : const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25),
                  width: 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Type icon in colored circle
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: widget.urgencyColor.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          t.typeIcon,
                          size: 16,
                          color: widget.urgencyColor,
                        ),
                      ),
                      const SizedBox(width: 10),

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
                                  fontSize: 11,
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
                      UrgencyBadge(task: t),
                      const SizedBox(width: 8),
                      AnimatedCheck(
                        isDone: t.isDone,
                        onToggle: widget.onToggle,
                        color: widget.urgencyColor,
                      ),
                    ],
                  ),

                  // Expanded detail
                  AnimatedCrossFade(
                    firstChild: const SizedBox.shrink(),
                    secondChild: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: _GlassExpandedDetail(
                        task: t,
                        muted: widget.isDark
                            ? AppColors.darkTextMuted
                            : AppColors.textMuted,
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
  }
}

class _GlassExpandedDetail extends StatelessWidget {
  const _GlassExpandedDetail({
    required this.task,
    required this.muted,
  });

  final TaskItem task;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: Colors.white.withValues(alpha: 0.2), height: 1),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(CupertinoIcons.calendar, size: 12, color: muted),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                task.dueFormatted,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: muted),
              ),
            ),
          ],
        ),
        if (task.notes != null && task.notes!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(CupertinoIcons.doc_text, size: 12, color: muted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  task.notes!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: muted),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(CupertinoIcons.flag, size: 12, color: muted),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '${task.priorityLabel} priority · ${task.typeLabel}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: muted),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

