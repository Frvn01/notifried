import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

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
