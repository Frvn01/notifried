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
}
