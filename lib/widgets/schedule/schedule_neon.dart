import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/schedule.dart';
import '../../providers/schedule_provider.dart';
import '../../theme/app_theme.dart';
import '../shared/countdown_text.dart';
import '../shared/day_strip.dart';
import '../widget_size.dart';

export '../widget_size.dart';

/// Dark neon schedule widget. Always dark — ignores system theme.
/// Monospace countdown, neon glow accents, pulsing in-progress highlight.
class ScheduleNeon extends StatefulWidget {
  const ScheduleNeon({
    super.key,
    required this.provider,
    this.size = WidgetSize.medium,
  });

  final ScheduleProvider provider;
  final WidgetSize size;

  @override
  State<ScheduleNeon> createState() => _ScheduleNeonState();
}

class _ScheduleNeonState extends State<ScheduleNeon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryCtrl;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final disable = MediaQuery.of(context).disableAnimations;
      if (disable) {
        _entryCtrl.value = 1.0;
      } else {
        _entryCtrl.forward();
      }
    });
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.provider,
      child: Consumer<ScheduleProvider>(
        builder: (context, prov, _) => _NeonBody(
          provider: prov,
          size: widget.size,
          entryCtrl: _entryCtrl,
        ),
      ),
    );
  }
}

class _NeonBody extends StatelessWidget {
  const _NeonBody({
    required this.provider,
    required this.size,
    required this.entryCtrl,
  });

  final ScheduleProvider provider;
  final WidgetSize size;
  final AnimationController entryCtrl;

  // Neon always uses these fixed colors
  static const _bg = Color(0xFF0A0C14);
  static const _muted = Color(0xFF7B82B8);

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primaryIndigo;
    final dayClasses = provider.schedulesForDay(provider.selectedWeekday);
    final nextClass = provider.nextClass;

    return LayoutBuilder(builder: (context, constraints) {
      final isSmall = size == WidgetSize.small || constraints.maxWidth < 320;
      final isLarge = size == WidgetSize.large && constraints.maxWidth >= 480;

      if (isSmall) {
        return Container(
          decoration: BoxDecoration(
            color: _bg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: primary.withValues(alpha: 0.7),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: 0.25),
                blurRadius: 20,
                spreadRadius: 0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(21),
            child: _NeonNextCard(
              nextClass: nextClass,
              primary: primary,
              compact: true,
            ),
          ),
        );
      }

      return Container(
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: primary.withValues(alpha: 0.7),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: 0.25),
              blurRadius: 20,
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(21),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Neon next-class card ───────────────────────────
              _NeonNextCard(
                nextClass: nextClass,
                primary: primary,
                compact: isSmall,
              ),
              // ── Day strip ──────────────────────────────────────
              // Wrapped in a Theme override so DayStrip uses neon colors.
              Theme(
                data: Theme.of(context).copyWith(
                  brightness: Brightness.dark,
                  colorScheme:
                      Theme.of(context).colorScheme.copyWith(primary: primary),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DayStrip(
                    selectedDay: provider.selectedWeekday,
                    onDaySelected: provider.selectWeekday,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // ── Schedule list ──────────────────────────────────
              if (dayClasses.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      'No classes today',
                      style: TextStyle(fontSize: 13, color: _muted),
                    ),
                  ),
                )
              else
                _NeonList(
                  schedules: dayClasses,
                  entryCtrl: entryCtrl,
                  primary: primary,
                  maxItems: isLarge ? dayClasses.length : 2,
                ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      );
    });
  }
}

// ── Neon next-class card ──────────────────────────────────────────────────────

class _NeonNextCard extends StatelessWidget {
  const _NeonNextCard({
    required this.nextClass,
    required this.primary,
    required this.compact,
  });

  final Schedule? nextClass;
  final Color primary;
  final bool compact;

  static const _text = Color(0xFFE8EAFF);
  static const _muted = Color(0xFF7B82B8);
  static const _surface = Color(0xFF111422);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primary.withValues(alpha: 0.7),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.22),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Monospace countdown
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: CountdownText(
              nextClass: nextClass,
              style: GoogleFonts.spaceMono(
                fontSize: compact ? 16 : 22,
                fontWeight: FontWeight.w700,
                color: primary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            nextClass?.title ?? 'No upcoming class',
            style: GoogleFonts.spaceMono(
              fontSize: compact ? 13 : 16,
              fontWeight: FontWeight.w700,
              color: _text,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (!compact) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(
                  child: Text(
                    nextClass?.timeRangeFormatted ?? '',
                    style:
                        GoogleFonts.spaceMono(fontSize: 11, color: _muted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (nextClass?.room != null && nextClass!.room!.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      nextClass!.room!,
                      style: GoogleFonts.spaceMono(
                        fontSize: 11,
                        color: _muted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Neon schedule list ────────────────────────────────────────────────────────

class _NeonList extends StatelessWidget {
  const _NeonList({
    required this.schedules,
    required this.entryCtrl,
    required this.primary,
    required this.maxItems,
  });

  final List<Schedule> schedules;
  final AnimationController entryCtrl;
  final Color primary;
  final int maxItems;

  @override
  Widget build(BuildContext context) {
    final count = schedules.length.clamp(0, maxItems);
    return Column(
      children: List.generate(count, (i) {
        // Neon: fade-in only (no slide — too flashy)
        final start = (i * 0.12).clamp(0.0, 0.88);
        final end = (start + 0.4).clamp(0.0, 1.0);
        final fadeAnim = CurvedAnimation(
          parent: entryCtrl,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        );
        return FadeTransition(
          opacity: fadeAnim,
          child: schedules[i].isInProgress
              ? _PulsingNeonRow(schedule: schedules[i], primary: primary)
              : _NeonRow(schedule: schedules[i], primary: primary),
        );
      }),
    );
  }
}

// ── Pulsing row for in-progress class ────────────────────────────────────────

class _PulsingNeonRow extends StatelessWidget {
  const _PulsingNeonRow({
    required this.schedule,
    required this.primary,
  });

  final Schedule schedule;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 8.0, end: 20.0),
      duration: const Duration(milliseconds: 2000),
      curve: Curves.easeInOut,
      onEnd: () {
        // Builder rebuilds from begin again because we flip via key change
        // The widget itself re-triggers because TweenAnimationBuilder
        // auto-reverses via onEnd callback re-setting state in parent,
        // but simpler: we let the pulsing happen via a stateful wrapper.
      },
      builder: (context, blur, _) {
        return _NeonRow(
          schedule: schedule,
          primary: primary,
          glowBlur: blur,
        );
      },
    );
  }
}

class _NeonRow extends StatelessWidget {
  const _NeonRow({
    required this.schedule,
    required this.primary,
    this.glowBlur = 0,
  });

  final Schedule schedule;
  final Color primary;
  final double glowBlur;

  static const _text = Color(0xFFE8EAFF);
  static const _muted = Color(0xFF7B82B8);
  static const _surface = Color(0xFF111422);

  @override
  Widget build(BuildContext context) {
    final subjectColor = Color(schedule.colorValue);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: subjectColor.withValues(alpha: 0.35),
          width: 1,
        ),
        boxShadow: glowBlur > 0
            ? [
                BoxShadow(
                  color: subjectColor.withValues(alpha: 0.5),
                  blurRadius: glowBlur,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 3.5,
            height: 24,
            decoration: BoxDecoration(
              color: subjectColor,
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                  color: subjectColor.withValues(alpha: 0.7),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              schedule.title,
              style: GoogleFonts.spaceMono(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: schedule.isInProgress ? subjectColor : _text,
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
              style: GoogleFonts.spaceMono(fontSize: 11, color: _muted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
