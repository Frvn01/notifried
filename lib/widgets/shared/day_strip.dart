import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Horizontal weekday strip (Mon–Sat). Selected day is highlighted with an
/// animated filled pill; others show plain text. Uses [LayoutBuilder] and
/// [Expanded] cells — no hardcoded widths.
class DayStrip extends StatelessWidget {
  const DayStrip({
    super.key,
    required this.selectedDay,
    required this.onDaySelected,
  });

  /// 1 = Monday … 6 = Saturday
  final int selectedDay;
  final void Function(int) onDaySelected;

  static const _labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: List.generate(6, (i) {
            final dayIndex = i + 1; // 1-based
            final isSelected = dayIndex == selectedDay;

            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onDaySelected(dayIndex),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : (isDark
                              ? AppColors.darkTextMuted
                              : AppColors.textMuted),
                      overflow: TextOverflow.ellipsis,
                    ),
                    child: Text(
                      _labels[i],
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
