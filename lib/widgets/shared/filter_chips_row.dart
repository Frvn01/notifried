import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// A row of filter chips (All / Exams / Quizzes / Tasks) with an optional
/// [child] slot below that wraps in [AnimatedSwitcher] for smooth list swaps.
class FilterChipsRow extends StatelessWidget {
  const FilterChipsRow({
    super.key,
    required this.selected,
    required this.onSelected,
    this.child,
  });

  /// One of: 'all', 'exam', 'quiz', 'task'
  final String selected;
  final void Function(String) onSelected;

  /// Optional content area below the chips (e.g. the filtered task list).
  final Widget? child;

  static const _chips = [
    _ChipDef(value: 'all', label: 'All'),
    _ChipDef(value: 'exam', label: 'Exams'),
    _ChipDef(value: 'quiz', label: 'Quizzes'),
    _ChipDef(value: 'task', label: 'Tasks'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    final surfaceUnselected = isDark
        ? AppColors.darkCard.withValues(alpha: 0.7)
        : AppColors.cardLavender;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chip row
        Row(
          children: _chips.map((chip) {
            final isSelected = chip.value == selected;
            return Flexible(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onSelected(chip.value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? primary : surfaceUnselected,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    chip.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : (isDark
                              ? AppColors.darkTextMuted
                              : AppColors.textMuted),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        // Optional animated content slot below chips
        if (child != null) ...[
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: child,
            ),
            child: KeyedSubtree(
              key: ValueKey<String>(selected),
              child: child!,
            ),
          ),
        ],
      ],
    );
  }
}

class _ChipDef {
  const _ChipDef({required this.value, required this.label});
  final String value;
  final String label;
}
