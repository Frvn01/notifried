import 'package:flutter/material.dart';
import '../models/schedule.dart';
import '../theme/app_theme.dart';

class TaskCard extends StatelessWidget {
  final Schedule schedule;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool showDelete;

  const TaskCard({
    super.key,
    required this.schedule,
    this.onTap,
    this.onDelete,
    this.showDelete = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : AppColors.cardWhite;
    final textDark = isDark ? AppColors.darkText : AppColors.textDark;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final isSchool = schedule.isSchool;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(28),
          border: isSchool
              ? Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.35), width: 1.5)
              : null,
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 14,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Time and Countdown Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (isSchool)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.school_rounded, size: 12, color: Theme.of(context).primaryColor),
                            const SizedBox(width: 4),
                            Text(
                              'CLASS',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Text(
                      schedule.timeRangeFormatted,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textMuted,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
                // Countdown Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: schedule.isInProgress
                        ? const Color(0xFFE8F5E9)
                        : (schedule.isPastDue
                            ? const Color(0xFFEEEEEE)
                            : Theme.of(context).primaryColor.withValues(alpha: 0.12)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    schedule.countdownStatus,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: schedule.isInProgress
                          ? const Color(0xFF2E7D32)
                          : (schedule.isPastDue
                              ? Colors.grey[700]
                              : Theme.of(context).primaryColor),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Title
            Text(
              schedule.title,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: textDark,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),

            // Subtitle
            Text(
              _getSubtitle(schedule),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: textMuted,
              ),
            ),
            const SizedBox(height: 16),

            // Bottom Row: Badges and Action Button
            Row(
              children: [
                // Dark pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF32385A) : AppColors.pillDark,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    schedule.isToday ? 'Today' : schedule.type.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Light pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF282D4A) : AppColors.pillLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    schedule.durationFormatted,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : AppColors.pillTextLight,
                    ),
                  ),
                ),
                const Spacer(),
                // Delete button if enabled
                if (showDelete && onDelete != null)
                  GestureDetector(
                    onTap: onDelete,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFEEEE),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        size: 20,
                        color: Color(0xFFE53935),
                      ),
                    ),
                  ),
                // Arrow Launch Button
                GestureDetector(
                  onTap: onTap,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.north_east_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getSubtitle(Schedule s) {
    switch (s.type.toLowerCase()) {
      case 'school':
        return 'School schedule & class countdown';
      case 'work':
        return 'Work smarter and faster.';
      case 'reminder':
        return 'Stay connected, effortlessly';
      case 'goal':
        return 'Personal growth & habits';
      default:
        return 'Stay connected, effortlessly';
    }
  }
}
