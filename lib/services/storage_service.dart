import 'dart:convert';

  import 'package:hive/hive.dart';
import '../models/schedule.dart';
import 'widget_service.dart';

class StorageService {
    static const _schedulesBox = 'schedules_box';
    static const _themeBox = 'theme_box';

  Future<List<Schedule>> loadSchedules() async {
      final box = Hive.box<Schedule>(_schedulesBox);
      return box.values.toList();
  }

  Future<void> saveSchedules(List<Schedule> list) async {
    // update home-screen widget data (best-effort)
    try {
      await WidgetService.updateWidget(list);
    } catch (_) {}
      final box = Hive.box<Schedule>(_schedulesBox);
      await box.clear();
      for (var s in list) {
        await box.add(s);
      }
  }

  Future<int?> loadThemeColor() async {
      final box = Hive.box(_themeBox);
      return box.get('color') as int?;
  }

  Future<void> saveThemeColor(int colorValue) async {
      final box = Hive.box(_themeBox);
      await box.put('color', colorValue);
  }
}
