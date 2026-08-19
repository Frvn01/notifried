import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/schedule.g.dart';

import 'models/schedule.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';
import 'screens/home_screen.dart';
import 'screens/add_schedule_screen.dart';

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
  Hive.registerAdapter(ScheduleAdapter());
  await Hive.openBox<Schedule>('schedules_box');
  await Hive.openBox('theme_box');
  await NotificationService().init();
  runApp(NowtifriedApp());
}

class NowtifriedApp extends StatefulWidget {
  @override
  State<NowtifriedApp> createState() => _NowtifriedAppState();
}

class _NowtifriedAppState extends State<NowtifriedApp> {
  final StorageService _storage = StorageService();
  Color _themeColor = Colors.blue;

  @override
  void initState() {
    super.initState();
    _loadTheme();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureNotificationPermission());
  }

  Future<void> _ensureNotificationPermission() async {
    if (!Platform.isAndroid) return;
    var status = await Permission.notification.status;
    if (status.isGranted) return;

    final retry = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Notifications permission'),
        content: Text('This app needs permission to show notifications for your schedules.\n\nWould you like to allow notifications?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('No')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Yes')),
        ],
      ),
    );

    if (retry == true) {
      final result = await Permission.notification.request();
      if (!result.isGranted) {
        final open = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('Permission denied'),
            content: Text('Notifications permission was denied. Open app settings to enable it?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Open Settings')),
            ],
          ),
        );
        if (open == true) {
          await openAppSettings();
        }
      }
    }
  }

  Future<void> _loadTheme() async {
    final v = await _storage.loadThemeColor();
    if (v != null) {
      setState(() => _themeColor = Color(v));
    }
  }

  void _updateTheme(Color c) async {
    setState(() => _themeColor = c);
    await _storage.saveThemeColor(c.value);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nowtifried',
      theme: ThemeData(primarySwatch: generateMaterialColor(_themeColor)),
      home: HomeScreen(onThemeChanged: _updateTheme),
      routes: {
        '/add': (_) => AddScheduleScreen(),
      },
    );
  }
}

MaterialColor generateMaterialColor(Color color) {
  Map<int, Color> swatch = {};
  for (var i = 1; i <= 10; i++) {
    final strength = i * 0.1;
    swatch[(i * 100)] = Color.lerp(Colors.white, color, strength) ?? color;
  }
  return MaterialColor(color.value, swatch);
}
