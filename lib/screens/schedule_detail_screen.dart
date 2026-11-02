import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/schedule.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/widget_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';

class ScheduleDetailScreen extends StatefulWidget {
  final String scheduleId;

  const ScheduleDetailScreen({
    super.key,
    required this.scheduleId,
  });

  @override
  State<ScheduleDetailScreen> createState() => _ScheduleDetailScreenState();
}

class _ScheduleDetailScreenState extends State<ScheduleDetailScreen> {
  final StorageService _storage = StorageService();
  final NotificationService _notifier = NotificationService();
  Schedule? _schedule;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await _storage.loadSchedules();
    final matches = list.where((s) => s.id == widget.scheduleId);
    if (mounted) {
      setState(() {
        _schedule = matches.isNotEmpty ? matches.first : null;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteSchedule() async {
    if (_schedule == null) return;
    if (_schedule!.notificationId != null) {
      await _notifier.cancel(_schedule!.notificationId!);
    }
    final list = await _storage.loadSchedules();
    list.removeWhere((s) => s.id == widget.scheduleId);
    await _storage.saveSchedules(list);
    await WidgetService.syncAll();
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textDark = isDark ? AppColors.darkText : AppColors.textDark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.bgSolid,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_schedule == null) {
      return Scaffold(
        backgroundColor: AppColors.bgSolid,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: Text(
            'Schedule not found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
      );
    }

    final s = _schedule!;
    final timeFmt = DateFormat('h:mm a');
    final dateFmt = DateFormat('EEEE, MMMM d, yyyy');

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppTheme.getBackgroundGradient(isDark ? 'dark' : 'lavender'),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.08)
                              : Colors.white.withOpacity(0.65),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.4),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          CupertinoIcons.chevron_left,
                          size: 18,
                          color: textDark,
                        ),
                      ),
                    ),
                    const Spacer(),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _deleteSchedule,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF3B30).withOpacity(0.12),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFFF3B30).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          CupertinoIcons.trash,
                          size: 18,
                          color: Color(0xFFFF3B30),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Main Frosted Glass Content Card
                      GlassContainer(
                        padding: const EdgeInsets.all(24),
                        borderRadius: BorderRadius.circular(32),
                        opacity: isDark ? 0.25 : 0.7,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Badges Row
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF32385A) : AppColors.primaryDark,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    s.type.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF2E3456) : AppColors.cardLavender,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    s.durationFormatted,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                // Countdown Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    s.countdownStatus,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),

                            // Title
                            Text(
                              s.title,
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: textDark,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Date or Recurring Days Info
                            Row(
                              children: [
                                const Icon(
                                  CupertinoIcons.calendar,
                                  size: 16,
                                  color: AppColors.textMuted,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  (s.daysOfWeek != null && s.daysOfWeek!.isNotEmpty)
                                      ? 'Every ${(s.daysOfWeek!..sort()).map((d) => {1: 'Mon', 2: 'Tue', 3: 'Wed', 4: 'Thu', 5: 'Fri', 6: 'Sat', 7: 'Sun'}[d] ?? '').join(', ')}'
                                      : dateFmt.format(s.start),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: textDark,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Time Range Info
                            Row(
                              children: [
                                const Icon(
                                  CupertinoIcons.time,
                                  size: 16,
                                  color: AppColors.textMuted,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${timeFmt.format(s.start)} - ${timeFmt.format(s.end)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: textDark,
                                  ),
                                ),
                              ],
                            ),
                            if (s.room != null && s.room!.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(
                                    CupertinoIcons.location_solid,
                                    size: 16,
                                    color: AppColors.textMuted,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    s.room!,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: textDark,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 24),

                            // Status / Countdown Indicator Card
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: s.isPastDue
                                    ? (isDark ? const Color(0xFF382E26) : AppColors.cardPeach)
                                    : (isDark ? const Color(0xFF223640) : AppColors.cardSkyBlue),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    s.isPastDue
                                        ? CupertinoIcons.checkmark_circle_fill
                                        : (s.isSchool ? CupertinoIcons.book_fill : CupertinoIcons.clock_fill),
                                    color: textDark,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          s.isPastDue
                                              ? 'Schedule Completed'
                                              : (s.isInProgress
                                                  ? 'In Progress'
                                                  : s.countdownStatus),
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: textDark,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          s.isPastDue
                                              ? 'Completed at ${timeFmt.format(s.end)}'
                                              : 'Local notification set for ${timeFmt.format(s.start)}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
