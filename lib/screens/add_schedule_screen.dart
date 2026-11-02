import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../models/schedule.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/widget_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';

class AddScheduleScreen extends StatefulWidget {
  final String initialType;

  const AddScheduleScreen({
    super.key,
    this.initialType = 'school',
  });

  @override
  State<AddScheduleScreen> createState() => _AddScheduleScreenState();
}

class _AddScheduleScreenState extends State<AddScheduleScreen> {
  final _titleCtrl = TextEditingController();
  final _roomCtrl = TextEditingController();
  late String _type;
  DateTime _start = DateTime.now().add(const Duration(minutes: 10));
  DateTime _end = DateTime.now().add(const Duration(hours: 1, minutes: 10));
  Color _color = AppColors.primaryIndigo;
  final Set<int> _selectedDays = {1}; // Default Monday only

  final StorageService _storage = StorageService();
  final NotificationService _notifier = NotificationService();
  bool _isSaving = false;

  final List<Color> _presetColors = const [
    AppColors.primaryIndigo,
    Color(0xFF6C5CE7),
    Color(0xFF00B894),
    Color(0xFF0984E3),
    Color(0xFFFF9500),
    Color(0xFFFF3B30),
    Color(0xFFE84393),
  ];

  final List<Map<String, dynamic>> _categories = const [
    {'id': 'school', 'label': 'Class Schedule', 'icon': CupertinoIcons.book_fill},
    {'id': 'task', 'label': 'One-off Event', 'icon': CupertinoIcons.calendar},
  ];

  @override
  void initState() {
    super.initState();
    _type = widget.initialType == 'school' ? 'school' : 'task';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _roomCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickStart() async {
    DateTime baseDate = _start;
    if (_type == 'task') {
      final d = await showDatePicker(
        context: context,
        initialDate: _start,
        firstDate: DateTime.now().subtract(const Duration(days: 365)),
        lastDate: DateTime.now().add(const Duration(days: 3650)),
      );
      if (d == null || !mounted) return;
      baseDate = d;
    }
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_start),
    );
    if (t == null) return;
    setState(() => _start = DateTime(baseDate.year, baseDate.month, baseDate.day, t.hour, t.minute));
  }

  Future<void> _pickEnd() async {
    DateTime baseDate = _end;
    if (_type == 'task') {
      final d = await showDatePicker(
        context: context,
        initialDate: _end,
        firstDate: _start,
        lastDate: DateTime.now().add(const Duration(days: 3650)),
      );
      if (d == null || !mounted) return;
      baseDate = d;
    }
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_end),
    );
    if (t == null) return;
    setState(() => _end = DateTime(baseDate.year, baseDate.month, baseDate.day, t.hour, t.minute));
  }

  String get _durationFormatted {
    final diff = _end.difference(_start);
    final hours = diff.inHours;
    final mins = diff.inMinutes % 60;
    if (hours > 0 && mins > 0) {
      return '${hours}h ${mins}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${mins > 0 ? mins : 30}m';
    }
  }

  String _formatDaysSelected() {
    if (_selectedDays.isEmpty) return 'No days selected';
    if (_selectedDays.length == 7) return 'Everyday';
    final map = {1: 'Mon', 2: 'Tue', 3: 'Wed', 4: 'Thu', 5: 'Fri', 6: 'Sat', 7: 'Sun'};
    final list = _selectedDays.toList()..sort();
    return 'Every ${list.map((d) => map[d] ?? '').join(', ')}';
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_type == 'school'
              ? 'Please enter a course or subject title'
              : 'Please enter a schedule title'),
        ),
      );
      return;
    }

    if (_type == 'school' && _selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one day for this class schedule'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final id = Uuid().v4();
    final roomText = _roomCtrl.text.trim();
    final s = Schedule(
      id: id,
      title: title,
      type: _type,
      start: _start,
      end: _end,
      colorValue: _color.toARGB32(),
      daysOfWeek: _type == 'school' ? _selectedDays.toList() : null,
      room: roomText.isNotEmpty ? roomText : null,
    );

    // Schedule notification
    try {
      final notifId = await _notifier.scheduleForSchedule(s);
      s.notificationId = notifId;
    } catch (_) {}

    final list = await _storage.loadSchedules();
    list.add(s);
    await _storage.saveSchedules(list);

    try {
      await WidgetService.syncAll();
    } catch (_) {}

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textDark = isDark ? AppColors.darkText : AppColors.textDark;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final primary = Theme.of(context).primaryColor;
    final timeFmt = DateFormat('h:mm a');
    final dateFmt = DateFormat('EEE, MMM d');

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF131524) : const Color(0xFFCCD2F8),
      body: Stack(
        children: [
          // Ambient Gradient Orbs in Background
          Positioned(
            top: -60,
            left: -40,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6C5CE7).withValues(alpha: 0.28),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primary.withValues(alpha: 0.22),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Frosted Top Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.white.withValues(alpha: 0.65),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            CupertinoIcons.xmark,
                            size: 16,
                            color: textDark,
                          ),
                        ),
                      ),
                      Text(
                        _type == 'school' ? 'Add Class Timetable' : 'Create Schedule',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: textDark,
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: _isSaving ? null : _save,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                          decoration: BoxDecoration(
                            color: primary,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: primary.withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Save',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Form Content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Schedule Type Toggle
                        Text(
                          'SCHEDULE TYPE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: textMuted,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: _categories.map((cat) {
                            final id = cat['id'] as String;
                            final isSel = _type == id;
                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(right: id == 'school' ? 8 : 0),
                                child: GestureDetector(
                                  onTap: () => setState(() => _type = id),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: isSel
                                          ? primary
                                          : (isDark
                                              ? Colors.white.withValues(alpha: 0.08)
                                              : Colors.white.withValues(alpha: 0.65)),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: isSel
                                            ? primary
                                            : Colors.white.withValues(alpha: 0.35),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          cat['icon'] as IconData,
                                          size: 16,
                                          color: isSel ? Colors.white : textDark,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          cat['label'] as String,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                                            color: isSel ? Colors.white : textDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 18),

                        // Title & Course Card
                        GlassContainer(
                          padding: const EdgeInsets.all(20),
                          borderRadius: BorderRadius.circular(24),
                          opacity: isDark ? 0.25 : 0.7,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                controller: _titleCtrl,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: textDark,
                                ),
                                decoration: InputDecoration(
                                  hintText: _type == 'school'
                                      ? 'Subject Title (e.g. Calculus I, CS 50)'
                                      : 'Event / Schedule Title',
                                  hintStyle: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: textMuted,
                                  ),
                                  border: InputBorder.none,
                                ),
                              ),
                              if (_type == 'school') ...[
                                const Divider(height: 18),
                                TextField(
                                  controller: _roomCtrl,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: textDark,
                                  ),
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(
                                      CupertinoIcons.location_solid,
                                      size: 16,
                                      color: AppColors.textMuted,
                                    ),
                                    prefixIconConstraints: const BoxConstraints(minWidth: 28, minHeight: 0),
                                    hintText: 'Room or Building (e.g. Science Hall 302)',
                                    hintStyle: TextStyle(fontSize: 13, color: textMuted),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Recurring Days (For School Timetable)
                        if (_type == 'school') ...[
                          GlassContainer(
                            padding: const EdgeInsets.all(18),
                            borderRadius: BorderRadius.circular(24),
                            opacity: isDark ? 0.25 : 0.7,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'CLASS DAYS',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.8,
                                        color: textMuted,
                                      ),
                                    ),
                                    Text(
                                      _formatDaysSelected(),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: List.generate(7, (index) {
                                    final dayNum = index + 1; // 1 = Mon, 7 = Sun
                                    final dayLabel = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][index];
                                    final isSelected = _selectedDays.contains(dayNum);

                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          if (isSelected) {
                                            _selectedDays.remove(dayNum);
                                          } else {
                                            _selectedDays.add(dayNum);
                                          }
                                        });
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 180),
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? primary
                                              : (isDark
                                                  ? Colors.white.withValues(alpha: 0.08)
                                                  : Colors.white.withValues(alpha: 0.65)),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isSelected
                                                ? primary
                                                : Colors.white.withValues(alpha: 0.35),
                                            width: isSelected ? 1.5 : 1,
                                          ),
                                          boxShadow: isSelected
                                              ? [
                                                  BoxShadow(
                                                    color: primary.withValues(alpha: 0.35),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 3),
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        alignment: Alignment.center,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              dayLabel,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                                color: isSelected ? Colors.white : textDark,
                                              ),
                                            ),
                                            if (isSelected)
                                              Container(
                                                margin: const EdgeInsets.only(top: 3),
                                                width: 4,
                                                height: 4,
                                                decoration: const BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                        ],

                        // Time Range Selectors (NO DATES FOR SCHOOL CLASSES!)
                        GlassContainer(
                          padding: const EdgeInsets.all(18),
                          borderRadius: BorderRadius.circular(24),
                          opacity: isDark ? 0.25 : 0.7,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _type == 'school' ? 'CLASS TIME' : 'TIME & DATE',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
                                      color: textMuted,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: primary.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _durationFormatted,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  // Starts Card
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: _pickStart,
                                      behavior: HitTestBehavior.opaque,
                                      child: Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? Colors.white.withValues(alpha: 0.08)
                                              : Colors.white.withValues(alpha: 0.65),
                                          borderRadius: BorderRadius.circular(18),
                                          border: Border.all(
                                            color: Colors.white.withValues(alpha: 0.35),
                                            width: 1,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'STARTS',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.textMuted,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              timeFmt.format(_start),
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w800,
                                                color: textDark,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              _type == 'school'
                                                  ? 'Repeats weekly'
                                                  : dateFmt.format(_start),
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Ends Card
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: _pickEnd,
                                      behavior: HitTestBehavior.opaque,
                                      child: Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? Colors.white.withValues(alpha: 0.08)
                                              : Colors.white.withValues(alpha: 0.65),
                                          borderRadius: BorderRadius.circular(18),
                                          border: Border.all(
                                            color: Colors.white.withValues(alpha: 0.35),
                                            width: 1,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'ENDS',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.textMuted,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              timeFmt.format(_end),
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w800,
                                                color: textDark,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              _type == 'school'
                                                  ? _durationFormatted
                                                  : dateFmt.format(_end),
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Color Tag
                        GlassContainer(
                          padding: const EdgeInsets.all(18),
                          borderRadius: BorderRadius.circular(24),
                          opacity: isDark ? 0.25 : 0.7,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SUBJECT COLOR TAG',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: textMuted,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 12,
                                runSpacing: 10,
                                children: _presetColors.map((col) {
                                  final isSel = _color.toARGB32() == col.toARGB32();
                                  return GestureDetector(
                                    onTap: () => setState(() => _color = col),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 180),
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: col,
                                        shape: BoxShape.circle,
                                        border: isSel
                                            ? Border.all(color: Colors.white, width: 3)
                                            : null,
                                        boxShadow: [
                                          BoxShadow(
                                            color: col.withValues(alpha: 0.35),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: isSel
                                          ? const Icon(CupertinoIcons.check_mark, size: 16, color: Colors.white)
                                          : null,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
