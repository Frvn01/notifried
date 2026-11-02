import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/storage_service.dart';
import '../services/widget_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';
import 'onboarding_screen.dart';
import 'widget_studio_screen.dart';
import 'widget_gallery_screen.dart';

class ProfileScreen extends StatefulWidget {
  final void Function(Color, String)? onThemeOrColorChanged;

  const ProfileScreen({super.key, this.onThemeOrColorChanged});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final StorageService _storage = StorageService();
  String _userName = '';
  String _currentThemeMode = 'lavender';
  Color _currentColor = AppColors.primaryIndigo;

  final List<Map<String, dynamic>> _themeModes = const [
    {'id': 'lavender', 'label': 'Lavender', 'icon': CupertinoIcons.sparkles},
    {'id': 'dark', 'label': 'Dark', 'icon': CupertinoIcons.moon_fill},
    {'id': 'light', 'label': 'Light', 'icon': CupertinoIcons.sun_max_fill},
  ];

  final List<Color> _presetAccents = const [
    AppColors.primaryIndigo,
    Color(0xFF6C5CE7),
    Color(0xFF00B894),
    Color(0xFF0984E3),
    Color(0xFFFF9500),
    Color(0xFFFF3B30),
    Color(0xFFE84393),
    Color(0xFF2D3436),
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final name = await _storage.loadUserName();
    final mode = await _storage.loadThemeMode();
    final colVal = await _storage.loadThemeColor();
    if (mounted) {
      setState(() {
        _userName = name;
        _currentThemeMode = mode;
        if (colVal != null) {
          _currentColor = Color(colVal);
        }
      });
    }
  }

  Future<void> _updateThemeMode(String mode) async {
    setState(() => _currentThemeMode = mode);
    await _storage.saveThemeMode(mode);
    widget.onThemeOrColorChanged?.call(_currentColor, mode);
  }

  Future<void> _updateAccentColor(Color color) async {
    setState(() => _currentColor = color);
    await _storage.saveThemeColor(color.toARGB32());
    widget.onThemeOrColorChanged?.call(color, _currentThemeMode);
  }

  Future<void> _editUserName() async {
    final ctrl = TextEditingController(text: _userName);
    final res = await showDialog<String>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Edit Display Name', style: TextStyle(fontWeight: FontWeight.w800)),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            hintText: 'Enter your name...',
            filled: true,
            fillColor: AppColors.pillLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, ctrl.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (res != null) {
      setState(() => _userName = res);
      await _storage.saveUserName(res);
      await WidgetService.syncAll();
    }
  }

  Future<void> _pickCustomColor() async {
    Color temp = _currentColor;
    final picked = await showDialog<Color>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Custom Accent Color', style: TextStyle(fontWeight: FontWeight.w800)),
        content: SingleChildScrollView(
          child: StatefulBuilder(
            builder: (c, setDialogState) => BlockPicker(
              pickerColor: temp,
              onColorChanged: (col) => setDialogState(() => temp = col),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, temp),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Apply', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (picked != null) {
      _updateAccentColor(picked);
    }
  }

  Future<void> _clearAllDatabase() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Reset All Schedules & Tasks?', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('This will delete all saved timetable classes, tasks, and notes.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF3B30),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _storage.clearAllSchedules();
      await _storage.clearAllTasks();
      await _storage.clearAllNotes();
      await WidgetService.syncAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All data cleared successfully.')),
      );
    }
  }

  Future<void> _checkWidgetSync() async {
    await WidgetService.syncAll();
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Row(
          children: [
            const Icon(CupertinoIcons.checkmark_circle_fill, color: Color(0xFF00B894)),
            const SizedBox(width: 10),
            const Text('Widget Synchronized', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
        content: const Text(
          'Android home screen widget is updated with your latest timetable and deadlines.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('OK', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _requestNotificationPermission() async {
    final status = await Permission.notification.request();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          status.isGranted
              ? 'Notifications are enabled!'
              : 'Notification permission is required for schedule alerts.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _currentThemeMode == 'dark';
    final textDark = isDark ? AppColors.darkText : AppColors.textDark;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final primary = _currentColor;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0C0E1A)
          : (_currentThemeMode == 'light'
              ? const Color(0xFFF5F7FC)
              : const Color(0xFFCCD3FA)),
      body: Stack(
        children: [
          // Background ambient gradient that matches the chosen appearance
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: AppTheme.getBackgroundGradient(_currentThemeMode),
                ),
              ),
            ),
          ),

          // Vivid ambient glow orbs for authentic frosted glass refraction
          Positioned(
            top: -40,
            left: -40,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6C5CE7).withValues(alpha: isDark ? 0.55 : 0.50),
              ),
            ),
          ),
          Positioned(
            top: 260,
            right: -60,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primary.withValues(alpha: isDark ? 0.50 : 0.45),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: -50,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00B894).withValues(alpha: isDark ? 0.40 : 0.40),
              ),
            ),
          ),

          // Soft blur backdrop — keeps orb colors vivid through glass
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.10)
                    : Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),

          // Main Content
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Header Bar with Back Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.white.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            CupertinoIcons.gear_alt_fill,
                            size: 20,
                            color: primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Settings & Theme',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: textDark,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
              const SizedBox(height: 14),

              // User Profile Frosted Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GlassContainer(
                  padding: const EdgeInsets.all(20),
                  borderRadius: BorderRadius.circular(28),
                  opacity: isDark ? 0.25 : 0.7,
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primary.withValues(alpha: 0.18),
                          border: Border.all(color: primary.withValues(alpha: 0.35), width: 1.5),
                        ),
                        child: Center(
                          child: _userName.isNotEmpty
                              ? Text(
                                  _userName[0].toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: primary,
                                  ),
                                )
                              : Icon(
                                  CupertinoIcons.person_fill,
                                  size: 26,
                                  color: primary,
                                ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _userName.isNotEmpty ? _userName : 'Student User',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: textDark,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Personal Academic Profile',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: _editUserName,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            'Edit',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Theme Mode Selector Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GlassContainer(
                  padding: const EdgeInsets.all(20),
                  borderRadius: BorderRadius.circular(28),
                  opacity: isDark ? 0.25 : 0.7,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'APPEARANCE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: textMuted,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: _themeModes.map((mode) {
                          final isSel = _currentThemeMode == mode['id'];
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => _updateThemeMode(mode['id'] as String),
                              behavior: HitTestBehavior.opaque,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: isSel
                                      ? primary
                                      : (isDark
                                          ? Colors.white.withValues(alpha: 0.08)
                                          : Colors.white.withValues(alpha: 0.6)),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: isSel
                                        ? primary
                                        : Colors.white.withValues(alpha: 0.35),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      mode['icon'] as IconData,
                                      size: 20,
                                      color: isSel ? Colors.white : textDark,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      mode['label'] as String,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                                        color: isSel ? Colors.white : textDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Accent Color Palette Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GlassContainer(
                  padding: const EdgeInsets.all(20),
                  borderRadius: BorderRadius.circular(28),
                  opacity: isDark ? 0.25 : 0.7,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'ACCENT COLOR',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: textMuted,
                            ),
                          ),
                          GestureDetector(
                            onTap: _pickCustomColor,
                            child: Text(
                              'Custom...',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: _presetAccents.map((col) {
                          final isSel = _currentColor.toARGB32() == col.toARGB32();
                          return GestureDetector(
                            onTap: () => _updateAccentColor(col),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: col,
                                shape: BoxShape.circle,
                                border: isSel
                                    ? Border.all(
                                        color: Colors.white,
                                        width: 3,
                                      )
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
                                  ? const Icon(CupertinoIcons.check_mark, size: 18, color: Colors.white)
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Feature Tour & Walkthrough Tile
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GlassContainer(
                  padding: const EdgeInsets.all(18),
                  borderRadius: BorderRadius.circular(24),
                  opacity: isDark ? 0.25 : 0.7,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OnboardingScreen(
                          onCompleted: () => Navigator.pop(context),
                        ),
                        fullscreenDialog: true,
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C5CE7).withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(CupertinoIcons.sparkles, color: Color(0xFF6C5CE7), size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome Tour & Feature Guide',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: textDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Replay the animated features walkthrough',
                              style: TextStyle(fontSize: 12, color: textMuted),
                            ),
                          ],
                        ),
                      ),
                      const Icon(CupertinoIcons.chevron_right, size: 16, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Grouped Preferences (Apple Settings Style)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GlassContainer(
                  borderRadius: BorderRadius.circular(28),
                  opacity: isDark ? 0.25 : 0.7,
                  child: Column(
                    children: [
                      _buildSettingsTile(
                        icon: CupertinoIcons.bell_fill,
                        iconBg: const Color(0xFFE4EAFE),
                        iconColor: primary,
                        title: 'Notifications Permission',
                        subtitle: 'Enable or check class and deadline alerts',
                        onTap: _requestNotificationPermission,
                      ),
                      Divider(height: 1, indent: 64, color: Colors.white.withValues(alpha: 0.3)),
                      _buildSettingsTile(
                        icon: CupertinoIcons.rectangle_stack_fill,
                        iconBg: const Color(0xFFE8EAF6),
                        iconColor: const Color(0xFF3F51B5),
                        title: 'Widget Gallery',
                        subtitle: "Preview 10 animated widget styles (Bento, Glass, Neon, Timeline, Minimal)",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const WidgetGalleryScreen()),
                          );
                        },
                      ),
                      Divider(height: 1, indent: 64, color: Colors.white.withValues(alpha: 0.3)),
                      _buildSettingsTile(
                        icon: CupertinoIcons.sparkles,
                        iconBg: const Color(0xFFEDE7F6),
                        iconColor: const Color(0xFF6C5CE7),
                        title: 'Widget Studio & Customization',
                        subtitle: 'Preview 5 widget sizes, animations & live sync',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const WidgetStudioScreen()),
                          );
                        },
                      ),
                      Divider(height: 1, indent: 64, color: Colors.white.withValues(alpha: 0.3)),
                      _buildSettingsTile(
                        icon: CupertinoIcons.square_stack_3d_up_fill,
                        iconBg: const Color(0xFFDEF2F9),
                        iconColor: const Color(0xFF0984E3),
                        title: 'Sync Home Widgets',
                        subtitle: 'Refresh Android home screen widgets now',
                        onTap: _checkWidgetSync,
                      ),
                      Divider(height: 1, indent: 64, color: Colors.white.withValues(alpha: 0.3)),
                      _buildSettingsTile(
                        icon: CupertinoIcons.trash_fill,
                        iconBg: const Color(0xFFFFEEEE),
                        iconColor: const Color(0xFFFF3B30),
                        title: 'Reset All Data',
                        subtitle: 'Clear all classes, tasks, and notes',
                        onTap: _clearAllDatabase,
                      ),
                      Divider(height: 1, indent: 64, color: Colors.white.withValues(alpha: 0.3)),
                      _buildSettingsTile(
                        icon: CupertinoIcons.info,
                        iconBg: const Color(0xFFFDECE2),
                        iconColor: const Color(0xFFFF9500),
                        title: 'About Nowtifried',
                        subtitle: 'Version 2.0 • Personal Student System',
                        onTap: () {
                          showAboutDialog(
                            context: context,
                            applicationName: 'Nowtifried',
                            applicationVersion: '2.0.0',
                            applicationLegalese: 'Personal Student System with frosted glass aesthetics.',
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = _currentThemeMode == 'dark';
    final textDark = isDark ? AppColors.darkText : AppColors.textDark;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_right,
              color: AppColors.textMuted,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
