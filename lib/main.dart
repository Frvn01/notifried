import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/services.dart';

import 'models/schedule.dart';
import 'models/task_item.dart';
import 'models/note_item.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';
import 'services/widget_service.dart';
import 'theme/app_theme.dart';
import 'screens/nav_shell.dart';
import 'screens/onboarding_screen.dart';
import 'screens/add_schedule_screen.dart';
import 'screens/schedule_detail_screen.dart';
import 'package:provider/provider.dart';
import 'providers/schedule_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Request runtime notification permission on Android 13+
  if (Platform.isAndroid) {
    final status = await Permission.notification.status;
    if (!status.isGranted) {
      await Permission.notification.request();
    }
  }

  await Hive.initFlutter();

  // Register Adapters
  Hive.registerAdapter(ScheduleAdapter());
  Hive.registerAdapter(TaskItemAdapter());
  Hive.registerAdapter(NoteItemAdapter());

  // Open Storage Boxes
  await Hive.openBox<Schedule>('schedules_box');
  await Hive.openBox<TaskItem>('tasks_box');
  await Hive.openBox<NoteItem>('notes_box');
  await Hive.openBox('theme_box');

  await NotificationService().init();

  final storage = StorageService();
  final hasSeen = await storage.hasSeenOnboarding();

  // Populate home screen widgets immediately
  try {
    await WidgetService.syncAll();
  } catch (_) {}

  runApp(NowtifriedApp(hasSeenOnboarding: hasSeen));
}

class NowtifriedApp extends StatefulWidget {
  final bool hasSeenOnboarding;

  const NowtifriedApp({super.key, this.hasSeenOnboarding = false});

  @override
  State<NowtifriedApp> createState() => _NowtifriedAppState();
}

class _NowtifriedAppState extends State<NowtifriedApp>
    with WidgetsBindingObserver {
  final StorageService _storage = StorageService();
  Color _themeColor = AppColors.primaryIndigo;
  String _themeMode = 'lavender';
  bool _showOnboarding = true;

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavShellState> _navShellKey = GlobalKey<NavShellState>();
  static const _channel = MethodChannel('nowtifried/widget');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _showOnboarding = !widget.hasSeenOnboarding;
    _loadTheme();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureNotificationPermission();
      _setupWidgetChannel();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed || state == AppLifecycleState.paused) {
      WidgetService.syncAll();
    }
  }

  Future<void> _ensureNotificationPermission() async {
    if (!Platform.isAndroid) return;
    var status = await Permission.notification.status;
    if (status.isGranted) return;
    if (!mounted) return;

    final retry = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Notifications permission'),
        content: const Text(
          'This app needs permission to show notifications for your schedules, quizzes, and exams.\n\nWould you like to allow notifications?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text('Yes', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (retry == true) {
      final result = await Permission.notification.request();
      if (!result.isGranted) {
        if (!mounted) return;
        final open = await showDialog<bool>(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text('Permission denied'),
            content: const Text(
              'Notifications permission was denied. Open app settings to enable it?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogCtx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Open Settings',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
        if (open == true) {
          await openAppSettings();
        }
      }
    }
  }

  void _setupWidgetChannel() async {
    // Handle runtime widget taps while app is running
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onWidgetTap') {
        final id = call.arguments as String?;
        if (id != null) _openSchedule(id);
      } else if (call.method == 'onNavigateTab') {
        final tab = call.arguments as String?;
        if (tab != null) _navigateToTab(tab);
      }
    });

    // Check initial id when app launched from widget
    try {
      final initId =
          await _channel.invokeMethod<String>('getInitialScheduleId');
      if (initId != null) {
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _openSchedule(initId));
      }
    } catch (_) {}

    // Check initial target tab when app launched from widget
    try {
      final initTab =
          await _channel.invokeMethod<String>('getInitialTargetTab');
      if (initTab != null) {
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _navigateToTab(initTab));
      }
    } catch (_) {}
  }

  void _navigateToTab(String targetTab) {
    if (targetTab == 'tasks' || targetTab == 'deadlines') {
      _navShellKey.currentState?.switchToTab(2); // Tasks tab
    } else if (targetTab == 'schedule') {
      _navShellKey.currentState?.switchToTab(1); // Calendar tab
    }
  }

  void _openSchedule(String id) async {
    final list = await _storage.loadSchedules();
    final matches = list.where((e) => e.id == id);
    if (matches.isNotEmpty) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => ScheduleDetailScreen(scheduleId: id),
        ),
      );
    }
  }

  Future<void> _loadTheme() async {
    final v = await _storage.loadThemeColor();
    final m = await _storage.loadThemeMode();
    if (mounted) {
      setState(() {
        if (v != null) _themeColor = Color(v);
        _themeMode = m;
      });
    }
  }

  void _updateThemeAndMode(Color c, String mode) {
    setState(() {
      _themeColor = c;
      _themeMode = mode;
    });
    WidgetService.syncAll();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ScheduleProvider()..loadData()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Nowtifried',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.getTheme(
          primaryColor: _themeColor,
          themeMode: _themeMode,
        ),
        home: _showOnboarding
            ? OnboardingScreen(
                onCompleted: () {
                  setState(() => _showOnboarding = false);
                },
              )
            : NavShell(
                key: _navShellKey,
                onThemeOrColorChanged: _updateThemeAndMode,
                currentThemeMode: _themeMode,
              ),
        routes: {
          '/add': (_) => const AddScheduleScreen(),
        },
      ),
    );
  }
}
