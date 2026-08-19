import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;

import '../models/schedule.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  int _nextId = 1000;

  Future<void> init() async {
    tzdata.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOS = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: iOS),
      onDidReceiveNotificationResponse: (payload) async {
        // payload handling is done by the app via streams or navigation
      },
    );
  }

  Future<int> scheduleForSchedule(Schedule s) async {
    final id = _nextId++;
    final androidDetails = AndroidNotificationDetails(
      'nowtifried_channel',
      'Nowtifried Notifications',
      channelDescription: 'Schedules and reminders',
      importance: Importance.max,
      priority: Priority.high,
      ongoing: true,
      ticker: 'Reminder',
    );
    const iosDetails = DarwinNotificationDetails();

    await _plugin.zonedSchedule(
      id,
      s.title,
      "Today's ${s.type}: ${s.title} from ${_formatTime(s.start)}",
      tz.TZDateTime.from(s.start, tz.local),
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: s.id,
      matchDateTimeComponents: null,
    );

    return id;
  }

  Future<void> cancel(int id) async {
    await _plugin.cancel(id);
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
