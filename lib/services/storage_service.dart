import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import '../models/schedule.dart';
import 'widget_service.dart';

class StorageService {
  static const _schedulesKey = 'schedules_v1';
  static const _themeColorKey = 'theme_color_v1';

  Future<List<Schedule>> loadSchedules() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_schedulesKey) ?? [];
    return raw.map((e) => Schedule.fromJson(e)).toList();
  }

  Future<void> saveSchedules(List<Schedule> list) async {
    final prefs = await SharedPreferences.getInstance();
    final data = list.map((s) => s.toJson()).toList();
    await prefs.setStringList(_schedulesKey, data);
    // update home-screen widget data (best-effort)
    try {
      await WidgetService.updateWidget(list);
    } catch (_) {}
  }

  Future<int?> loadThemeColor() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_themeColorKey);
  }

  Future<void> saveThemeColor(int colorValue) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeColorKey, colorValue);
  }
}
