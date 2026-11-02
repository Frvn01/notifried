import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/sample_data.dart';
import '../models/task_item.dart';
import '../providers/schedule_provider.dart';
import '../services/storage_service.dart';
import '../services/widget_service.dart';
import '../theme/app_theme.dart';

// Family A: Schedule Variants
import '../widgets/schedule/schedule_minimal.dart';
import '../widgets/schedule/schedule_glass.dart';
import '../widgets/schedule/schedule_neon.dart';
import '../widgets/schedule/schedule_timeline.dart';
import '../widgets/schedule/schedule_bento.dart';

// Family B: Deadlines Variants
import '../widgets/deadlines/deadlines_minimal.dart';
import '../widgets/deadlines/deadlines_glass.dart';
import '../widgets/deadlines/deadlines_neon.dart';
import '../widgets/deadlines/deadlines_timeline.dart';
import '../widgets/deadlines/deadlines_bento.dart';

/// Interactive Widget Gallery screen allowing students to explore, preview,
/// customize, and apply all 10 animated widget variants in Small, Medium, and Large sizes.
class WidgetGalleryScreen extends StatefulWidget {
  const WidgetGalleryScreen({super.key});

  @override
  State<WidgetGalleryScreen> createState() => _WidgetGalleryScreenState();
}

class _WidgetGalleryScreenState extends State<WidgetGalleryScreen>
    with SingleTickerProviderStateMixin {
  final StorageService _storage = StorageService();
  late final TabController _tabController;
  final PageController _schedulePageCtrl = PageController(viewportFraction: 0.90);
  final PageController _deadlinesPageCtrl = PageController(viewportFraction: 0.90);

  int _selectedSchedulePage = 0;
  int _selectedDeadlinesPage = 0;
  WidgetSize _selectedSize = WidgetSize.medium;
  String _bgStyle = 'aurora';
  Color _accentColor = const Color(0xFF6C5CE7);
  String _customTitle = '';
  bool _isApplying = false;

  final List<String> _variantNames = const [
    'Minimal Card',
    'Glassmorphism',
    'Dark Neon',
    'Timeline',
    'Bento Grid',
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
      'label': 'Lavender Frost',
      'desc': 'Soft pastel purple & milky white glass',
      'icon': CupertinoIcons.drop_fill,
      'color': Color(0xFFA29BFE),
    },
    {
      'id': 'minimal',
      'label': 'Minimal Frost',
      'desc': 'Clean monochrome glass with pure contrast',
      'icon': CupertinoIcons.square_fill,
      'color': Color(0xFF636E72),
    },
  ];

  final List<Color> _accentColors = const [
    Color(0xFF6C5CE7), // Lavender / Purple
    Color(0xFF00CEC9), // Cyan Neon
    Color(0xFF0984E3), // Electric Blue
    Color(0xFFFF7675), // Sunset Coral
    Color(0xFFFFA502), // Amber Gold
    Color(0xFF00B894), // Emerald Mint
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSavedPreferences();
  }

  Future<void> _loadSavedPreferences() async {
    final style = await _storage.loadWidgetBgStyle();
    final colVal = await _storage.loadThemeColor();
    final title = await _storage.loadWidgetCustomTitle();
    final family = await _storage.loadWidgetFamily();
    final variant = await _storage.loadWidgetVariant();

    if (mounted) {
      setState(() {
        _bgStyle = style;
        if (colVal != null) _accentColor = Color(colVal);
        _customTitle = title;

        if (family == 'deadlines' || family == 'tasks') {
          _tabController.index = 1;
        }

        final variantIdx = variant == 'minimal'
            ? 0
            : (variant == 'glass'
                ? 1
                : (variant == 'neon'
                    ? 2
                    : (variant == 'timeline' ? 3 : 4)));
        _selectedSchedulePage = variantIdx;
        _selectedDeadlinesPage = variantIdx;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _schedulePageCtrl.dispose();
    _deadlinesPageCtrl.dispose();
    super.dispose();
  }

  Future<void> _applyCurrentWidget(BuildContext context, ScheduleProvider prov) async {
    setState(() => _isApplying = true);
    final isSchedule = _tabController.index == 0;
    final variantIndex = isSchedule ? _selectedSchedulePage : _selectedDeadlinesPage;
    final variantName = _variantNames[variantIndex];
    final family = isSchedule ? 'Schedule' : 'Deadlines';

    final variantKey = variantIndex == 0
        ? 'minimal'
        : (variantIndex == 1
            ? 'glass'
            : (variantIndex == 2
                ? 'neon'
                : (variantIndex == 3 ? 'timeline' : 'bento')));

    await _storage.saveWidgetBgStyle(_bgStyle);
    await _storage.saveWidgetVariant(variantKey);
    await _storage.saveWidgetFamily(isSchedule ? 'schedule' : 'deadlines');
    await _storage.saveThemeColor(_accentColor.toARGB32());

    await WidgetService.syncAll();

    if (!mounted || !context.mounted) return;
    setState(() => _isApplying = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(CupertinoIcons.checkmark_seal_fill, color: Color(0xFF00B894), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Applied $variantName ($family, ${_selectedSize.name.toUpperCase()}) to your widgets!',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E2138),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showApplyDialog(BuildContext context, ScheduleProvider prov) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textDark = isDark ? AppColors.darkText : AppColors.textDark;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final primary = _accentColor;

    String selectedFamily = _tabController.index == 0 ? 'schedule' : 'deadlines';
    int selectedVariantIndex = _tabController.index == 0 ? _selectedSchedulePage : _selectedDeadlinesPage;
    final titleController = TextEditingController(text: _customTitle.isNotEmpty ? _customTitle : 'Academic Schedule');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF141728) : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 25,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white24 : Colors.black12,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Set Home Screen Widget',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: textDark,
                                  ),
                                ),
                                Text(
                                  'Choose widget purpose, formal title, and variant',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () => Navigator.pop(ctx),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05),
                              ),
                              child: Icon(CupertinoIcons.xmark, size: 14, color: textDark),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // 1. Widget Purpose
                      Text(
                        'WHAT SHOULD THIS WIDGET DISPLAY?',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: textMuted,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _buildFamilyChoiceCard(
                            id: 'schedule',
                            title: 'Schedule',
                            subtitle: 'Classes & Room',
                            icon: CupertinoIcons.calendar_today,
                            isSelected: selectedFamily == 'schedule',
                            primary: primary,
                            isDark: isDark,
                            onTap: () {
                              setModalState(() {
                                selectedFamily = 'schedule';
                                if (titleController.text.isEmpty ||
                                    titleController.text == 'Deadlines' ||
                                    titleController.text == 'Tasks') {
                                  titleController.text = 'Schedule';
                                }
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildFamilyChoiceCard(
                            id: 'deadlines',
                            title: 'Deadlines',
                            subtitle: 'Exams & Quizzes',
                            icon: CupertinoIcons.exclamationmark_circle_fill,
                            isSelected: selectedFamily == 'deadlines',
                            primary: primary,
                            isDark: isDark,
                            onTap: () {
                              setModalState(() {
                                selectedFamily = 'deadlines';
                                if (titleController.text.isEmpty ||
                                    titleController.text == 'Schedule' ||
                                    titleController.text == 'Tasks') {
                                  titleController.text = 'Deadlines';
                                }
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildFamilyChoiceCard(
                            id: 'tasks',
                            title: 'Tasks',
                            subtitle: 'Checklist & To-Do',
                            icon: CupertinoIcons.checkmark_circle_fill,
                            isSelected: selectedFamily == 'tasks',
                            primary: primary,
                            isDark: isDark,
                            onTap: () {
                              setModalState(() {
                                selectedFamily = 'tasks';
                                if (titleController.text.isEmpty ||
                                    titleController.text == 'Schedule' ||
                                    titleController.text == 'Deadlines') {
                                  titleController.text = 'Tasks';
                                }
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // 2. Custom Title Input
                      Text(
                        'CUSTOM WIDGET TITLE (FORMAL TEXT)',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: textMuted,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF0F2FA),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08),
                          ),
                        ),
                        child: TextField(
                          controller: titleController,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: textDark,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Enter widget title (e.g., Academic Schedule)',
                            hintStyle: TextStyle(
                              fontSize: 13,
                              color: textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
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
                              setModalState(() {
                                titleController.text = preset;
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
                      const SizedBox(height: 20),

                      // 3. Design Variant Selection
                      Text(
                        'DESIGN VARIANT: ${_variantNames[selectedVariantIndex].toUpperCase()}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: textMuted,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 38,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: _variantNames.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, i) {
                            final isSel = selectedVariantIndex == i;
                            return GestureDetector(
                              onTap: () => setModalState(() => selectedVariantIndex = i),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSel ? primary : (isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF0F2FA)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _variantNames[i],
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                                    color: isSel ? Colors.white : textDark,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Confirm & Apply Button
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () async {
                          Navigator.pop(ctx);
                          final chosenVariantKey = selectedVariantIndex == 0
                              ? 'minimal'
                              : (selectedVariantIndex == 1
                                  ? 'glass'
                                  : (selectedVariantIndex == 2
                                      ? 'neon'
                                      : (selectedVariantIndex == 3 ? 'timeline' : 'bento')));

                          final customTitleText = titleController.text.trim();
                          await _storage.saveWidgetFamily(selectedFamily);
                          await _storage.saveWidgetVariant(chosenVariantKey);
                          await _storage.saveWidgetCustomTitle(customTitleText);
                          await _storage.saveWidgetBgStyle(_bgStyle);
                          await _storage.saveThemeColor(_accentColor.toARGB32());

                          setState(() {
                            _customTitle = customTitleText;
                          });

                          if (!mounted || !context.mounted) return;
                          await _applyCurrentWidget(context, prov);
                        },
                        child: Container(
                          width: double.infinity,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [primary, const Color(0xFF6C5CE7)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: primary.withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'Confirm & Apply to Android Widget',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFamilyChoiceCard({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required Color primary,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? primary.withValues(alpha: isDark ? 0.3 : 0.15)
                : (isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF0F2FA)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? primary : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? primary : (isDark ? Colors.white70 : Colors.black54),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? primary : (isDark ? Colors.white : Colors.black87),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? primary.withValues(alpha: 0.8)
                      : (isDark ? Colors.white38 : Colors.black38),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCustomizeSheet(BuildContext context, ScheduleProvider prov) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textDark = isDark ? AppColors.darkText : AppColors.textDark;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final titleController = TextEditingController(text: _customTitle);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF141728) : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 25,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white24 : Colors.black12,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Customize Widget',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: textDark,
                                  ),
                                ),
                                Text(
                                  'Personalize theme, title, background, and accent glow',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () => Navigator.pop(ctx),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05),
                              ),
                              child: Icon(CupertinoIcons.xmark, size: 14, color: textDark),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Custom Title Section
                      Text(
                        'WIDGET HEADER TITLE (CUSTOM TEXT)',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: textMuted,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF0F2FA),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08),
                          ),
                        ),
                        child: TextField(
                          controller: titleController,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: textDark,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Enter formal title (e.g. Academic Schedule)',
                            hintStyle: TextStyle(
                              fontSize: 12,
                              color: textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Section 1: Background Aesthetic Style
                      Text(
                        'BACKGROUND AESTHETIC STYLE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: textMuted,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 80,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: _bgStyles.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, i) {
                            final item = _bgStyles[i];
                            final isSelected = _bgStyle == item['id'];
                            final col = item['color'] as Color;
                            return GestureDetector(
                              onTap: () {
                                setModalState(() => _bgStyle = item['id'] as String);
                                setState(() => _bgStyle = item['id'] as String);
                                _storage.saveWidgetBgStyle(item['id'] as String);
                              },
                              child: Container(
                                width: 135,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? col
                                      : (isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF0F2FA)),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected ? col : Colors.transparent,
                                    width: 1.5,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(item['icon'] as IconData, size: 13, color: isSelected ? Colors.white : col),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            item['label'] as String,
                                            style: TextStyle(
                                              fontSize: 11,
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
                                        color: isSelected ? Colors.white.withValues(alpha: 0.85) : textMuted,
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
                      const SizedBox(height: 18),

                      // Section 2: Accent Color
                      Text(
                        'ACCENT COLOR PALETTE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: textMuted,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: _accentColors.map((col) {
                          final isSelected = _accentColor.toARGB32() == col.toARGB32();
                          return GestureDetector(
                            onTap: () {
                              setModalState(() => _accentColor = col);
                              setState(() => _accentColor = col);
                              _storage.saveThemeColor(col.toARGB32());
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: col,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? Colors.white : Colors.transparent,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: col.withValues(alpha: isSelected ? 0.5 : 0.25),
                                    blurRadius: isSelected ? 10 : 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: isSelected
                                  ? const Icon(CupertinoIcons.checkmark, size: 18, color: Colors.white)
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // Section 3: Data Presets & Testing
                      Text(
                        'DATA CONTROLS & TESTING',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: textMuted,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                prov.seedIfEmpty(
                                  sampleSchedules: sampleSchedules,
                                  sampleTasks: sampleTasks,
                                );
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Sample schedules & deadlines reloaded!'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              child: Container(
                                height: 38,
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF0F2FA),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(CupertinoIcons.arrow_counterclockwise, size: 14, color: _accentColor),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Reload Sample Data',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: textDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                final newTask = TaskItem(
                                  id: 'quick_${DateTime.now().millisecondsSinceEpoch}',
                                  title: 'Quick Practice Quiz',
                                  type: 'quiz',
                                  dueDate: DateTime.now().add(const Duration(days: 1)),
                                  subject: 'Academic Center',
                                  priority: 2,
                                  colorValue: _accentColor.toARGB32(),
                                );
                                prov.addTask(newTask);
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Added new sample quiz deadline!'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              child: Container(
                                height: 38,
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF0F2FA),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(CupertinoIcons.plus_circle, size: 14, color: _accentColor),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Quick Add Deadline',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: textDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () async {
                          Navigator.pop(ctx);
                          final customTitleText = titleController.text.trim();
                          await _storage.saveWidgetCustomTitle(customTitleText);
                          setState(() {
                            _customTitle = customTitleText;
                          });
                          if (!mounted || !context.mounted) return;
                          await _applyCurrentWidget(context, prov);
                        },
                        child: Container(
                          width: double.infinity,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [_accentColor, const Color(0xFF6C5CE7)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: _accentColor.withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'Save & Apply Widget Settings',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = _accentColor;
    final textDark = isDark ? AppColors.darkText : AppColors.textDark;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return ChangeNotifierProvider<ScheduleProvider>(
      create: (_) {
        final prov = ScheduleProvider();
        prov.loadData().then((_) {
          prov.seedIfEmpty(
            sampleSchedules: sampleSchedules,
            sampleTasks: sampleTasks,
          );
        });
        return prov;
      },
      child: Consumer<ScheduleProvider>(
        builder: (context, prov, _) {
          return Scaffold(
            backgroundColor: isDark ? const Color(0xFF0C0E1A) : const Color(0xFFCCD3FA),
            body: Stack(
              children: [
                // Ambient Orbs
                Positioned(
                  top: -40,
                  left: -30,
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primary.withValues(alpha: isDark ? 0.35 : 0.45),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 40,
                  right: -40,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF6C5CE7).withValues(alpha: isDark ? 0.3 : 0.4),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                    child: Container(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                ),

                // Main Content
                SafeArea(
                  child: Column(
                    children: [
                      // App Bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () => Navigator.pop(context),
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.1)
                                      : Colors.white.withValues(alpha: 0.7),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.45),
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
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Widget Gallery',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: textDark,
                                      letterSpacing: -0.4,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Student Schedule & Deadlines • 10 Styles',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: textMuted,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),

                            // Customize shortcut button
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () => _showCustomizeSheet(context, prov),
                              child: Container(
                                width: 34,
                                height: 34,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.1)
                                      : Colors.white.withValues(alpha: 0.7),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.45),
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  CupertinoIcons.slider_horizontal_3,
                                  size: 16,
                                  color: primary,
                                ),
                              ),
                            ),

                            // Size Switcher Pills (S / M / L)
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : Colors.white.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.35),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildSizePill('S', WidgetSize.small, primary),
                                  _buildSizePill('M', WidgetSize.medium, primary),
                                  _buildSizePill('L', WidgetSize.large, primary),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Family Segment TabBar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: Container(
                          height: 42,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.white.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(21),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            indicator: BoxDecoration(
                              color: primary,
                              borderRadius: BorderRadius.circular(21),
                              boxShadow: [
                                BoxShadow(
                                  color: primary.withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            labelColor: Colors.white,
                            unselectedLabelColor: textMuted,
                            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                            unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            dividerColor: Colors.transparent,
                            tabs: const [
                              Tab(text: 'Schedule (5)'),
                              Tab(text: 'Deadlines (5)'),
                            ],
                          ),
                        ),
                      ),

                      // TabBarView with PageViews
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            // Schedule Family
                            _buildFamilyCarousel(
                              pageController: _schedulePageCtrl,
                              currentPage: _selectedSchedulePage,
                              onPageChanged: (page) => setState(() => _selectedSchedulePage = page),
                              builder: (pageIndex) => _buildScheduleVariant(pageIndex, prov),
                            ),

                            // Deadlines Family
                            _buildFamilyCarousel(
                              pageController: _deadlinesPageCtrl,
                              currentPage: _selectedDeadlinesPage,
                              onPageChanged: (page) => setState(() => _selectedDeadlinesPage = page),
                              builder: (pageIndex) => _buildDeadlinesVariant(pageIndex, prov),
                            ),
                          ],
                        ),
                      ),

                      // Bottom Action Bar: Customize Style & Apply Widget
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: () => _showCustomizeSheet(context, prov),
                                child: Container(
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.1)
                                        : Colors.white.withValues(alpha: 0.8),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.15)
                                          : Colors.white.withValues(alpha: 0.6),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(CupertinoIcons.slider_horizontal_3, size: 16, color: primary),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Customize Style',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: textDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: _isApplying ? null : () => _showApplyDialog(context, prov),
                                child: Container(
                                  height: 44,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [primary, const Color(0xFF6C5CE7)],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: primary.withValues(alpha: 0.35),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _isApplying
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Icon(CupertinoIcons.checkmark_seal_fill, size: 16, color: Colors.white),
                                      const SizedBox(width: 8),
                                      Text(
                                        _isApplying ? 'Applying...' : 'Apply Widget',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
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
          );
        },
      ),
    );
  }

  Widget _buildSizePill(String label, WidgetSize size, Color primary) {
    final isSelected = _selectedSize == size;
    return GestureDetector(
      onTap: () => setState(() => _selectedSize = size),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildFamilyCarousel({
    required PageController pageController,
    required int currentPage,
    required ValueChanged<int> onPageChanged,
    required Widget Function(int pageIndex) builder,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = _accentColor;
    final textDark = isDark ? AppColors.darkText : AppColors.textDark;

    return Column(
      children: [
        // Variant Label & Index Tag
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: primary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  _variantNames[currentPage],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: primary,
                  ),
                ),
              ),
              Text(
                'Variant ${currentPage + 1} of 5',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: textDark.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),

        // Carousel Slider
        Expanded(
          child: PageView.builder(
            controller: pageController,
            onPageChanged: onPageChanged,
            itemCount: 5,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: builder(index),
                  ),
                ),
              );
            },
          ),
        ),

        // Page Indicator Dots
        Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final isCurrent = index == currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isCurrent ? 22 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isCurrent ? primary : primary.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleVariant(int index, ScheduleProvider prov) {
    switch (index) {
      case 0:
        return ScheduleMinimal(provider: prov, size: _selectedSize);
      case 1:
        return ScheduleGlass(provider: prov, size: _selectedSize);
      case 2:
        return ScheduleNeon(provider: prov, size: _selectedSize);
      case 3:
        return ScheduleTimeline(provider: prov, size: _selectedSize);
      case 4:
      default:
        return ScheduleBento(provider: prov, size: _selectedSize);
    }
  }

  Widget _buildDeadlinesVariant(int index, ScheduleProvider prov) {
    switch (index) {
      case 0:
        return DeadlinesMinimal(provider: prov, size: _selectedSize);
      case 1:
        return DeadlinesGlass(provider: prov, size: _selectedSize);
      case 2:
        return DeadlinesNeon(provider: prov, size: _selectedSize);
      case 3:
        return DeadlinesTimeline(provider: prov, size: _selectedSize);
      case 4:
      default:
        return DeadlinesBento(provider: prov, size: _selectedSize);
    }
  }
}
