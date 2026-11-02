import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/task_item.dart';
import '../../providers/schedule_provider.dart';
import '../shared/animated_check.dart';
import '../shared/filter_chips_row.dart';
import '../shared/urgency_badge.dart';
import '../widget_size.dart';

export '../widget_size.dart';

/// Dark neon / cyberpunk terminal deadlines widget.
/// Always dark with glowing neon borders, monospace typography, and urgency pulses.
class DeadlinesNeon extends StatefulWidget {
  const DeadlinesNeon({
    super.key,
    required this.provider,
    this.size = WidgetSize.medium,
  });

  final ScheduleProvider provider;
  final WidgetSize size;

  @override
  State<DeadlinesNeon> createState() => _DeadlinesNeonState();
}

class _DeadlinesNeonState extends State<DeadlinesNeon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  String? _expandedId;

  static const Color _bgDark = Color(0xFF0A0C14);
  static const Color _cardDark = Color(0xFF111422);
  static const Color _neonCyan = Color(0xFF00E5FF);
  static const Color _neonGreen = Color(0xFF00FF66);
  static const Color _neonAmber = Color(0xFFFFB300);
  static const Color _neonRed = Color(0xFFFF1744);

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Color _neonForTask(TaskItem t) {
    if (t.isOverdue || t.isDueToday || t.isDueTomorrow) return _neonRed;
    final days = t.dueDate.difference(DateTime.now()).inDays;
    if (days <= 3) return _neonAmber;
    return _neonCyan;
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ScheduleProvider>.value(
      value: widget.provider,
      child: Consumer<ScheduleProvider>(
        builder: (context, prov, _) {
          final tasks = prov.filteredDeadlines;

          return Container(
            decoration: BoxDecoration(
              color: _bgDark,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _neonCyan.withValues(alpha: 0.35),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: _neonCyan.withValues(alpha: 0.15),
                  blurRadius: 20,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
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
                        // Terminal Header
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: _neonGreen,
                                boxShadow: [
                                  BoxShadow(
                                    color: _neonGreen,
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'DEADLINE_MATRIX // SYSTEM',
                                style: GoogleFonts.spaceMono(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _neonCyan,
                                  letterSpacing: 1.0,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '[${tasks.length}]',
                              style: GoogleFonts.spaceMono(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _neonGreen,
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
                            _fadeCtrl.forward(from: 0);
                          },
                        ),
                        const SizedBox(height: 12),

                        // Deadlines Terminal List
                        if (tasks.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text(
                                'NO_PENDING_TASKS // CLEAR',
                                style: GoogleFonts.spaceMono(
                                  fontSize: 12,
                                  color: Colors.white38,
                                ),
                              ),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: widget.size == WidgetSize.small
                                ? (tasks.length > 2 ? 2 : tasks.length)
                                : (widget.size == WidgetSize.medium
                                    ? (tasks.length > 2 ? 2 : tasks.length)
                                    : tasks.length),
                              itemBuilder: (context, index) {
                                final item = tasks[index];
                                final neonColor = _neonForTask(item);
                                final isExpanded = _expandedId == item.id;

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _expandedId = isExpanded ? null : item.id;
                                      });
                                    },
                                    onLongPress: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Snooze / Edit for "${item.title}"'),
                                          duration: const Duration(seconds: 1),
                                        ),
                                      );
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: _cardDark,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: neonColor.withValues(alpha: 0.35),
                                          width: 1.2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: neonColor.withValues(alpha: 0.12),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                width: 3.5,
                                                height: 24,
                                                decoration: BoxDecoration(
                                                  color: neonColor,
                                                  borderRadius: BorderRadius.circular(2),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: neonColor.withValues(alpha: 0.6),
                                                      blurRadius: 4,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              AnimatedCheck(
                                                isDone: item.isDone,
                                                onToggle: () => prov.toggleTaskDone(item.id),
                                                color: neonColor,
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      item.title,
                                                      style: GoogleFonts.spaceMono(
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.w700,
                                                        color: Colors.white,
                                                        decoration: item.isDone ? TextDecoration.lineThrough : null,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      item.subject ?? item.typeLabel.toUpperCase(),
                                                      style: GoogleFonts.spaceMono(
                                                        fontSize: 10,
                                                        color: neonColor.withValues(alpha: 0.8),
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              UrgencyBadge(task: item),
                                            ],
                                          ),
                                          if (isExpanded) ...[
                                            const SizedBox(height: 8),
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.black38,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(CupertinoIcons.calendar, size: 12, color: _neonCyan),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: Text(
                                                      item.dueFormatted,
                                                      style: GoogleFonts.spaceMono(
                                                        fontSize: 11,
                                                        color: Colors.white70,
                                                      ),
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
      ),
    );
  }
}
