import 'package:flutter/material.dart';
import '../../models/task_item.dart';

/// Compact pill badge showing days remaining for a [TaskItem].
/// Urgent items (daysLeft <= 1) gently pulse between scale 1.0 and 1.05.
class UrgencyBadge extends StatelessWidget {
  const UrgencyBadge({super.key, required this.task});

  final TaskItem task;

  // ── Color logic ──────────────────────────────────────────────────────

  static Color _badgeColor(TaskItem task, int daysLeft) {
    if (task.isOverdue || daysLeft <= 0) return const Color(0xFFFF3B30);
    if (daysLeft <= 3) return const Color(0xFFFF9500);
    return const Color(0xFF7B82B8); // muted grey-purple
  }

  // ── Label logic ──────────────────────────────────────────────────────

  static String _label(TaskItem task, int daysLeft) {
    if (task.isOverdue) return 'Overdue';
    if (daysLeft <= 0 || task.isDueToday) return 'Today';
    if (task.isDueTomorrow) return 'Tomorrow';
    return '${daysLeft}d left';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Strip time so comparisons are day-level
    final todayMidnight = DateTime(now.year, now.month, now.day);
    final dueMidnight = DateTime(
      task.dueDate.year,
      task.dueDate.month,
      task.dueDate.day,
    );
    final daysLeft = dueMidnight.difference(todayMidnight).inDays;

    final color = _badgeColor(task, daysLeft);
    final label = _label(task, daysLeft);
    final isUrgent = daysLeft <= 1 && !task.isDone;

    final pill = _BadgePill(color: color, label: label);

    if (!isUrgent) return pill;

    // Repeating scale pulse for urgent badges (1.0 → 1.05 → 1.0, 1.5 s period)
    return _PulsingBadge(color: color, label: label);
  }
}

// ── Internal static pill ─────────────────────────────────────────────────────

class _BadgePill extends StatelessWidget {
  const _BadgePill({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

// ── Pulsing wrapper using TweenAnimationBuilder ───────────────────────────────

class _PulsingBadge extends StatelessWidget {
  const _PulsingBadge({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    // TweenAnimationBuilder drives a looping pulse by cascading rebuilds.
    return _LoopingPulse(
      child: _BadgePill(color: color, label: label),
    );
  }
}

/// Loops a scale tween between 1.0 and 1.05 indefinitely by rebuilding in
/// the onEnd callback. Uses [TweenAnimationBuilder] — no controller needed.
class _LoopingPulse extends StatefulWidget {
  const _LoopingPulse({required this.child});
  final Widget child;

  @override
  State<_LoopingPulse> createState() => _LoopingPulseState();
}

class _LoopingPulseState extends State<_LoopingPulse> {
  double _target = 1.05;

  void _flip() {
    if (!mounted) return;
    setState(() => _target = _target == 1.05 ? 1.0 : 1.05);
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 1.0, end: _target),
      duration: const Duration(milliseconds: 750),
      curve: Curves.easeInOut,
      onEnd: _flip,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: widget.child,
    );
  }
}
