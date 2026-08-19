import 'dart:convert';

import 'package:home_widget/home_widget.dart';

import '../models/schedule.dart';

class WidgetService {
  static Future<void> updateWidget(List<Schedule> schedules) async {
    try {
      final data = schedules
          .map((s) => {
                'id': s.id,
                'title': s.title,
                'start': s.start.toIso8601String(),
                'end': s.end.toIso8601String(),
                'color': s.colorValue
              })
          .toList();
      await HomeWidget.saveWidgetData<String>('schedules_json', json.encode(data));
      await HomeWidget.updateWidget(name: 'NowtifriedWidgetProvider');
    } catch (e) {
      // ignore errors; native parts may not be installed yet
    }
  }

  // Debug helper: returns a map of shared preference names and their schedules_json value (if present)
  static Future<Map<String, String?>> dumpSharedPrefsCandidates() async {
    final candidates = ['com.example.nowtifried.HomeWidget', 'home_widget', 'FlutterSharedPreferences', 'com.example.nowtifried'];
    final result = <String, String?>{};
    for (var name in candidates) {
      try {
        final val = await HomeWidget.getWidgetData<String>('schedules_json');
        // Note: HomeWidget.getWidgetData reads the plugin-managed store; it may return the saved JSON or null.
        result[name] = val;
      } catch (e) {
        result[name] = null;
      }
    }
    return result;
  }
}
