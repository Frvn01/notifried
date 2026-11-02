import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/sample_data.dart';
import '../models/schedule.dart';
import '../models/task_item.dart';
import '../providers/schedule_provider.dart';
import '../services/storage_service.dart';
import '../services/widget_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';
import '../widgets/home_widgets_ui.dart';
import '../widgets/schedule/schedule_minimal.dart';
import '../widgets/schedule/schedule_glass.dart';
import '../widgets/schedule/schedule_neon.dart';
import '../widgets/schedule/schedule_timeline.dart';
import '../widgets/schedule/schedule_bento.dart';
import '../widgets/deadlines/deadlines_minimal.dart';
import '../widgets/deadlines/deadlines_glass.dart';
import '../widgets/deadlines/deadlines_neon.dart';
import '../widgets/deadlines/deadlines_timeline.dart';
import '../widgets/deadlines/deadlines_bento.dart';
import 'widget_gallery_screen.dart';

class WidgetStudioScreen extends StatefulWidget {
  const WidgetStudioScreen({super.key});

  @override
  State<WidgetStudioScreen> createState() => _WidgetStudioScreenState();
}

class _WidgetStudioScreenState extends State<WidgetStudioScreen>
    with SingleTickerProviderStateMixin {
  final StorageService _storage = StorageService();
  late final TextEditingController _titleController;

  List<Schedule> _schedules = [];
  List<TaskItem> _tasks = [];
  String _themeMode = 'lavender';
  String _bgStyle = 'aurora';
  Color _accentColor = const Color(0xFF6C5CE7);
  String _userName = '';
  String _widgetFamily = 'schedule'; // 'schedule', 'deadlines', 'tasks'
  String _widgetVariant = 'bento'; // 'bento', 'glass', 'neon', 'timeline', 'minimal', 'classic'
  bool _isLoading = true;
  bool _isSyncing = false;

  int _selectedSizeIndex = 0; // 0: ExtraLarge, 1: Large, 2: Medium, 3: Small, 4: Glance
  late AnimationController _shimmerController;

  final List<Map<String, dynamic>> _variants = const [
    {
      'id': 'bento',
      'label': 'Bento Grid',
      'desc': 'Modular tiles & hero timer',
      'icon': CupertinoIcons.square_grid_2x2_fill,
    },
    {
      'id': 'glass',
      'label': 'Glassmorphism',
      'desc': 'Frosted glass with floating orbs',
      'icon': CupertinoIcons.sparkles,
    },
    {
      'id': 'neon',
      'label': 'Dark Neon',
      'desc': 'Cyber glow & high-contrast monospace',
      'icon': CupertinoIcons.bolt_horizontal_fill,
    },
    {
      'id': 'timeline',
      'label': 'Timeline',
      'desc': 'Sequential vertical node track',
      'icon': CupertinoIcons.time,
    },
    {
      'id': 'minimal',
      'label': 'Minimal Card',
      'desc': 'Clean flat aesthetic with crisp edges',
      'icon': CupertinoIcons.square_fill,
    },
    {
      'id': 'classic',
      'label': 'Classic Studio',
      'desc': 'Original frosted agenda layout',
      'icon': CupertinoIcons.rectangle_fill_on_rectangle_fill,
    },
  ];

  final List<Map<String, dynamic>> _sizes = const [
    {
      'id': 'extra_large',
      'label': 'Agenda 4×4',
      'desc': 'Complete daily schedule, exams & quick metrics',
      'icon': CupertinoIcons.square_grid_2x2_fill,
    },
    {
      'id': 'large',
      'label': 'Hero 4×2',
      'desc': 'Next class countdown, room & 4 stat pills',
      'icon': CupertinoIcons.rectangle_grid_2x2_fill,
    },
    {
      'id': 'medium',
      'label': 'Bar 4×1',
      'desc': 'Class title, time range & room tag',
      'icon': CupertinoIcons.rectangle_fill_badge_xmark,
    },
    {
      'id': 'small',
      'label': 'Square 2×2',
      'desc': 'Compact class status & countdown',
      'icon': CupertinoIcons.square_fill,
    },
    {
      'id': 'glance',
      'label': 'Glance 4×1',
      'desc': 'Ultra-slim dynamic island pill with live badge',
      'icon': CupertinoIcons.capsule_fill,
    },
  ];

  final List<Map<String, dynamic>> _bgStyles = const [
    {
      'id': 'aurora',
      'label': 'Aurora Mesh',
      'desc': 'Liquid violet & hot pink ambient orbs',
      'icon': CupertinoIcons.sparkles,
      'color': Color(0xFF6C5CE7),
    },
    {
      'id': 'sunset',
      'label': 'Sunset Glow',
      'desc': 'Warm coral peach & golden amber glass',
      'icon': CupertinoIcons.sunset_fill,
      'color': Color(0xFFFF7675),
    },
    {
      'id': 'cyber',
      'label': 'Cyber Neon',
      'desc': 'Dark matrix obsidian & neon cyan glow',
      'icon': CupertinoIcons.bolt_horizontal_fill,
      'color': Color(0xFF00CEC9),
    },
    {
      'id': 'obsidian',
      'label': 'OLED Dark',
      'desc': 'Deep space black & subtle indigo glass',
      'icon': CupertinoIcons.moon_fill,
      'color': Color(0xFF2D3436),
    },
    {
      'id': 'lavender',
      'label': 'Lilac Mist',
      'desc': 'Pastel lavender with frosted pearl aura',
      'icon': CupertinoIcons.drop_fill,
      'color': Color(0xFFA29BFE),
    },
    {
      'id': 'emerald',
      'label': 'Mint Sage',
      'desc': 'Botanical emerald green & seafoam glass',
      'icon': CupertinoIcons.leaf_arrow_circlepath,
      'color': Color(0xFF00B894),
    },
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
    _loadData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final sList = await _storage.loadSchedules();
    final tList = await _storage.loadTasks();
    final mode = await _storage.loadThemeMode();
    final style = await _storage.loadWidgetBgStyle();
    final colVal = await _storage.loadThemeColor();
    final name = await _storage.loadUserName();
    final family = await _storage.loadWidgetFamily();
    final variant = await _storage.loadWidgetVariant();
    final title = await _storage.loadWidgetCustomTitle();

    if (mounted) {
      setState(() {
        _schedules = sList;
        _tasks = tList;
        _themeMode = mode;
        _bgStyle = style;
        if (colVal != null) _accentColor = Color(colVal);
        _userName = name;
        _widgetFamily = family;
        _widgetVariant = variant;
        _titleController.text = title;
        _isLoading = false;
      });
    }
  }

  Future<void> _setBgStyle(String style) async {
    setState(() => _bgStyle = style);
    await _storage.saveWidgetBgStyle(style);
    await WidgetService.syncAll();
  }

  Future<void> _syncWidgets() async {
    setState(() => _isSyncing = true);
    await _storage.saveWidgetBgStyle(_bgStyle);
    await _storage.saveWidgetFamily(_widgetFamily);
    await _storage.saveWidgetVariant(_widgetVariant);
    await _storage.saveWidgetCustomTitle(_titleController.text.trim());
    await _storage.saveThemeColor(_accentColor.toARGB32());

    await WidgetService.syncAll();
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _isSyncing = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(CupertinoIcons.checkmark_alt_circle_fill,
                color: Color(0xFF00B894)),
            SizedBox(width: 8),
            Text('Widgets updated and pushed to Android!'),
          ],
        ),
        backgroundColor: const Color(0xFF1E2138),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  WidgetDataBundle get _bundle => WidgetDataBundle(
        schedules: _schedules,
        tasks: _tasks,
        themeMode: _themeMode,
        bgStyle: _bgStyle,
        accentColor: _accentColor,
        userName: _userName,
        widgetFamily: _widgetFamily,
        widgetVariant: _widgetVariant,
        customTitle: _titleController.text.trim(),
      );

  Widget _buildSelectedWidgetPreview(double progress) {
    if (_widgetVariant == 'classic') {
      switch (_selectedSizeIndex) {
        case 0:
          return ExtraLargeWidgetUI(
            bundle: _bundle,
            animationProgress: progress,
          );
        case 1:
          return LargeWidgetUI(
            bundle: _bundle,
            animationProgress: progress,
          );
        case 2:
          return MediumWidgetUI(
            bundle: _bundle,
            animationProgress: progress,
          );
        case 3:
          return SmallWidgetUI(
            bundle: _bundle,
            animationProgress: progress,
          );
        case 4:
        default:
          return GlanceWidgetUI(
            bundle: _bundle,
            animationProgress: progress,
          );
      }
    }

    final WidgetSize size;
    final double targetWidth;
    switch (_selectedSizeIndex) {
      case 0:
        size = WidgetSize.large;
        targetWidth = 360;
        break;
      case 1:
        size = WidgetSize.medium;
        targetWidth = 360;
        break;
      case 2:
        size = WidgetSize.medium;
        targetWidth = 360;
        break;
      case 3:
        size = WidgetSize.small;
        targetWidth = 200;
        break;
      case 4:
      default:
        size = WidgetSize.small;
        targetWidth = 340;
        break;
    }

    final prov = ScheduleProvider();
    prov.schedules = _schedules.isNotEmpty ? _schedules : List.from(sampleSchedules);
    prov.tasks = _tasks.isNotEmpty ? _tasks : List.from(sampleTasks);
    prov.selectedWeekday = DateTime.now().weekday;

    if (_widgetFamily == 'tasks') {
      prov.setDeadlineFilter('task');
    } else if (_widgetFamily == 'deadlines') {
      prov.setDeadlineFilter('all');
    }

    Widget variantWidget;
    if (_widgetFamily == 'schedule') {
      switch (_widgetVariant) {
        case 'minimal':
          variantWidget = ScheduleMinimal(provider: prov, size: size);
          break;
        case 'glass':
          variantWidget = ScheduleGlass(provider: prov, size: size);
          break;
        case 'neon':
          variantWidget = ScheduleNeon(provider: prov, size: size);
          break;
        case 'timeline':
          variantWidget = ScheduleTimeline(provider: prov, size: size);
          break;
        case 'bento':
        default:
          variantWidget = ScheduleBento(provider: prov, size: size);
          break;
      }
    } else {
      switch (_widgetVariant) {
        case 'minimal':
          variantWidget = DeadlinesMinimal(provider: prov, size: size);
          break;
        case 'glass':
          variantWidget = DeadlinesGlass(provider: prov, size: size);
          break;
        case 'neon':
          variantWidget = DeadlinesNeon(provider: prov, size: size);
          break;
        case 'timeline':
          variantWidget = DeadlinesTimeline(provider: prov, size: size);
          break;
        case 'bento':
        default:
          variantWidget = DeadlinesBento(provider: prov, size: size);
          break;
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark ||
        _bgStyle == 'obsidian' ||
        _bgStyle == 'cyber';

    return Theme(
      data: ThemeData(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primaryColor: _accentColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _accentColor,
          brightness: isDark ? Brightness.dark : Brightness.light,
        ),
      ),
      child: ChangeNotifierProvider<ScheduleProvider>.value(
        value: prov,
        child: SizedBox(
          width: targetWidth,
          child: variantWidget,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textDark = isDark ? AppColors.darkText : AppColors.textDark;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final primary = Theme.of(context).primaryColor;

    return Scaffold(
      body: Stack(
        children: [
          // Ambient Gradient Background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: AppTheme.getBackgroundGradient(_themeMode),
                ),
              ),
            ),
          ),

          // Animated Accent Glow Orb Behind Widget Preview
          AnimatedBuilder(
            animation: _shimmerController,
            builder: (context, _) {
              final val = _shimmerController.value;
              return Positioned(
                top: 140,
                left: MediaQuery.of(context).size.width / 2 -
                    120 +
                    (math.sin(val * 2 * math.pi) * 20),
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _accentColor.withValues(
                            alpha: 0.22 +
                                (math.sin(val * 2 * math.pi).abs() * 0.12)),
                        blurRadius: 100,
                        spreadRadius: 30,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          SafeArea(
            child: Column(
              children: [
                // Top Navigation Bar
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GlassContainer(
                        width: 44,
                        height: 44,
                        borderRadius: BorderRadius.circular(22),
                        opacity: isDark ? 0.25 : 0.65,
                        onTap: () => Navigator.pop(context),
                        child: Icon(
                          CupertinoIcons.chevron_left,
                          size: 18,
                          color: textDark,
                        ),
                      ),
                      Column(
                        children: [
                          Text(
                            'WIDGET STUDIO',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: primary,
                            ),
                          ),
                          Text(
                            'Live Aesthetic Engine',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: textDark,
                            ),
                          ),
                        ],
                      ),
                      GlassContainer(
                        width: 44,
                        height: 44,
                        borderRadius: BorderRadius.circular(22),
                        opacity: isDark ? 0.25 : 0.65,
                        onTap: _syncWidgets,
                        child: _isSyncing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(
                                CupertinoIcons.arrow_2_circlepath,
                                size: 18,
                                color: textDark,
                              ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Interactive Live Moving Preview Container
                              Center(
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: AnimatedBuilder(
                                    animation: _shimmerController,
                                    builder: (context, _) {
                                      return _buildSelectedWidgetPreview(
                                          _shimmerController.value);
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Preview hint pill
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.1)
                                      : Colors.white.withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(CupertinoIcons.sparkles,
                                        size: 13, color: primary),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Live animated liquid mesh • Moves in real-time',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Interactive Widget Gallery Banner
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const WidgetGalleryScreen(),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        primary.withValues(alpha: isDark ? 0.25 : 0.15),
                                        const Color(0xFF6C5CE7).withValues(alpha: isDark ? 0.25 : 0.15),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: primary.withValues(alpha: 0.35),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: primary.withValues(alpha: 0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          CupertinoIcons.rectangle_stack_fill,
                                          size: 16,
                                          color: primary,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'Open Widget Gallery',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w800,
                                                color: textDark,
                                              ),
                                            ),
                                            Text(
                                              '10 Bento, Glass, Neon, Timeline & Deadlines styles',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: textMuted,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        CupertinoIcons.chevron_right,
                                        size: 14,
                                        color: primary,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Widget Purpose (Family) Selector
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'WIDGET PURPOSE',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                    color: textMuted,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildFamilyCard(
                                      id: 'schedule',
                                      label: 'Schedule',
                                      sub: 'Class timetable',
                                      icon: CupertinoIcons.calendar,
                                      primary: primary,
                                      isDark: isDark,
                                      textDark: textDark,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildFamilyCard(
                                      id: 'deadlines',
                                      label: 'Deadlines',
                                      sub: 'Exams & Quizzes',
                                      icon: CupertinoIcons.flame_fill,
                                      primary: primary,
                                      isDark: isDark,
                                      textDark: textDark,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildFamilyCard(
                                      id: 'tasks',
                                      label: 'Tasks',
                                      sub: 'To-do checklist',
                                      icon: CupertinoIcons.checkmark_circle_fill,
                                      primary: primary,
                                      isDark: isDark,
                                      textDark: textDark,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Custom Widget Title (Formal)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'CUSTOM WIDGET TITLE (FORMAL)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                    color: textMuted,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08),
                                  ),
                                ),
                                child: TextField(
                                  controller: _titleController,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: textDark,
                                  ),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'e.g., Academic Schedule, Deadlines, Agenda',
                                    hintStyle: TextStyle(
                                      fontSize: 13,
                                      color: textMuted,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  'Schedule',
                                  'Academic Agenda',
                                  'Upcoming Deadlines',
                                  'Daily Tasks',
                                  'University Routine',
                                ].map((preset) {
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _titleController.text = preset;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.1),
                                        ),
                                      ),
                                      child: Text(
                                        preset,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: textDark,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 24),

                              // Design Variant Selector
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'DESIGN VARIANT: ${_widgetVariant.toUpperCase()}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                    color: textMuted,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                height: 78,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: _variants.length,
                                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                                  itemBuilder: (context, i) {
                                    final item = _variants[i];
                                    final isSelected = _widgetVariant == item['id'];
                                    return GestureDetector(
                                      onTap: () => setState(() => _widgetVariant = item['id'] as String),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        width: 130,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? primary
                                              : (isDark
                                                  ? Colors.white.withValues(alpha: 0.08)
                                                  : Colors.white.withValues(alpha: 0.7)),
                                          borderRadius: BorderRadius.circular(18),
                                          border: Border.all(
                                            color: isSelected ? primary : Colors.white.withValues(alpha: 0.3),
                                            width: isSelected ? 2 : 1,
                                          ),
                                          boxShadow: isSelected
                                              ? [
                                                  BoxShadow(
                                                    color: primary.withValues(alpha: 0.35),
                                                    blurRadius: 10,
                                                    offset: const Offset(0, 3),
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  item['icon'] as IconData,
                                                  size: 14,
                                                  color: isSelected ? Colors.white : primary,
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    item['label'] as String,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w800,
                                                      color: isSelected ? Colors.white : textDark,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              item['desc'] as String,
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w500,
                                                color: isSelected
                                                    ? Colors.white.withValues(alpha: 0.85)
                                                    : textMuted,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Aesthetic Background Style Selector
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'AESTHETIC BACKGROUND STYLE',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                    color: textMuted,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),

                              SizedBox(
                                height: 82,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: _bgStyles.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 10),
                                  itemBuilder: (context, i) {
                                    final item = _bgStyles[i];
                                    final isSelected =
                                        _bgStyle == item['id'];
                                    final col = item['color'] as Color;
                                    return GestureDetector(
                                      onTap: () => _setBgStyle(
                                          item['id'] as String),
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        width: 145,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? col
                                              : (isDark
                                                  ? Colors.white.withValues(
                                                      alpha: 0.08)
                                                  : Colors.white.withValues(
                                                      alpha: 0.7)),
                                          borderRadius:
                                              BorderRadius.circular(18),
                                          border: Border.all(
                                            color: isSelected
                                                ? col
                                                : Colors.white.withValues(
                                                    alpha: 0.3),
                                            width: isSelected ? 2 : 1,
                                          ),
                                          boxShadow: isSelected
                                              ? [
                                                  BoxShadow(
                                                    color: col.withValues(
                                                        alpha: 0.4),
                                                    blurRadius: 10,
                                                    offset:
                                                        const Offset(0, 3),
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  item['icon'] as IconData,
                                                  size: 14,
                                                  color: isSelected
                                                      ? Colors.white
                                                      : col,
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    item['label'] as String,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: isSelected
                                                          ? Colors.white
                                                          : textDark,
                                                    ),
                                                    maxLines: 1,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              item['desc'] as String,
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w500,
                                                color: isSelected
                                                    ? Colors.white.withValues(
                                                        alpha: 0.88)
                                                    : textMuted,
                                              ),
                                              maxLines: 2,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Size Selector Carousel
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'WIDGET SIZES (5 SIZES)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                    color: textMuted,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),

                              SizedBox(
                                height: 78,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: _sizes.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 10),
                                  itemBuilder: (context, i) {
                                    final item = _sizes[i];
                                    final isSelected =
                                        _selectedSizeIndex == i;
                                    return GestureDetector(
                                      onTap: () => setState(
                                          () => _selectedSizeIndex = i),
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        width: 140,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? primary
                                              : (isDark
                                                  ? Colors.white.withValues(
                                                      alpha: 0.08)
                                                  : Colors.white.withValues(
                                                      alpha: 0.7)),
                                          borderRadius:
                                              BorderRadius.circular(18),
                                          border: Border.all(
                                            color: isSelected
                                                ? primary
                                                : Colors.white.withValues(
                                                    alpha: 0.3),
                                            width: isSelected ? 2 : 1,
                                          ),
                                          boxShadow: isSelected
                                              ? [
                                                  BoxShadow(
                                                    color: primary
                                                        .withValues(alpha: 0.35),
                                                    blurRadius: 10,
                                                    offset:
                                                        const Offset(0, 3),
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  item['icon'] as IconData,
                                                  size: 14,
                                                  color: isSelected
                                                      ? Colors.white
                                                      : textDark,
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    item['label'] as String,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: isSelected
                                                          ? Colors.white
                                                          : textDark,
                                                    ),
                                                    maxLines: 1,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              item['desc'] as String,
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w500,
                                                color: isSelected
                                                    ? Colors.white.withValues(
                                                        alpha: 0.85)
                                                    : textMuted,
                                              ),
                                              maxLines: 2,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Quick Theme Preview Filter
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'THEME GLASS TINT',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                    color: textMuted,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),

                              Row(
                                children: [
                                  _buildThemeChip(
                                      'lavender',
                                      'Lavender Glass',
                                      CupertinoIcons.sparkles,
                                      primary,
                                      isDark),
                                  const SizedBox(width: 8),
                                  _buildThemeChip(
                                      'dark',
                                      'Dark Obsidian',
                                      CupertinoIcons.moon_fill,
                                      primary,
                                      isDark),
                                  const SizedBox(width: 8),
                                  _buildThemeChip(
                                      'light',
                                      'Crystal Light',
                                      CupertinoIcons.sun_max_fill,
                                      primary,
                                      isDark),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // How to Add Card
                              GlassContainer(
                                padding: const EdgeInsets.all(18),
                                borderRadius: BorderRadius.circular(24),
                                opacity: isDark ? 0.25 : 0.7,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                            CupertinoIcons
                                                .device_phone_portrait,
                                            color: primary,
                                            size: 18),
                                        const SizedBox(width: 8),
                                        Text(
                                          'HOW TO ADD TO ANDROID HOME SCREEN',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.6,
                                            color: primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    _buildStepRow('1',
                                        'Touch and hold an empty space on your Android Home screen.'),
                                    const SizedBox(height: 6),
                                    _buildStepRow('2',
                                        'Tap "Widgets" from the launcher pop-up menu.'),
                                    const SizedBox(height: 6),
                                    _buildStepRow('3',
                                        'Scroll to "Nowtifried" and choose your favorite widget size.'),
                                    const SizedBox(height: 6),
                                    _buildStepRow('4',
                                        'Drag and drop it to place it on your home screen.'),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Big Sync Button
                              GlassButton(
                                onTap: _isSyncing ? null : _syncWidgets,
                                color: primary,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                borderRadius: BorderRadius.circular(20),
                                child: Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _isSyncing
                                            ? CupertinoIcons
                                                .arrow_2_circlepath
                                            : CupertinoIcons.cloud_upload_fill,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _isSyncing
                                            ? 'Updating Widgets...'
                                            : 'Push & Sync to Home Screen',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
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

  Widget _buildThemeChip(String mode, String label, IconData icon,
      Color primary, bool isDark) {
    final isSelected = _themeMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () async {
          setState(() => _themeMode = mode);
          await _storage.saveThemeMode(mode);
          await WidgetService.syncAll();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? primary
                : (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.7)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  isSelected ? primary : Colors.white.withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 12,
                  color: isSelected ? Colors.white : AppColors.textDark),
              const SizedBox(width: 5),
              Text(
                label.split(' ').first,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFamilyCard({
    required String id,
    required String label,
    required String sub,
    required IconData icon,
    required Color primary,
    required bool isDark,
    required Color textDark,
  }) {
    final isSelected = _widgetFamily == id;
    return GestureDetector(
      onTap: () => setState(() => _widgetFamily = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? primary
              : (isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.7)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primary : Colors.white.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.white : primary,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : textDark,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              sub,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.85)
                    : (isDark ? AppColors.darkTextMuted : AppColors.textMuted),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepRow(String step, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            step,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w500, height: 1.3),
          ),
        ),
      ],
    );
  }
}
