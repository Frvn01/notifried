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
    try {
      tzdata.initializeTimeZones();
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iOS = DarwinInitializationSettings();
      await _plugin.initialize(
        settings: const InitializationSettings(android: android, iOS: iOS),
        onDidReceiveNotificationResponse: (payload) async {
          // handled via payload if needed
        },
      );
    } catch (_) {}
  }

  Future<int?> scheduleForSchedule(Schedule s) async {
    final id = _nextId++;
    const androidDetails = AndroidNotificationDetails(
      'nowtifried_channel',
      'Nowtifried Notifications',
      channelDescription: 'Schedules and reminders',
      importance: Importance.max,
      priority: Priority.high,
      ongoing: false,
      ticker: 'Reminder',
    );
    const iosDetails = DarwinNotificationDetails();

    try {
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime.from(s.start, tz.local);

      // If scheduled time is in the past, do not schedule future alert
      if (scheduledDate.isBefore(now)) {
        return null;
      }

      // Try exact alarm first
      try {
        await _plugin.zonedSchedule(
          id: id,
          title: s.title,
          body: "Today's ${s.type}: ${s.title} from ${_formatTime(s.start)}",
          scheduledDate: scheduledDate,
          notificationDetails: const NotificationDetails(android: androidDetails, iOS: iosDetails),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: s.id,
        );
      } catch (_) {
        // Fallback to inexact alarm on Android 12+ if exact alarm permission is not granted
        await _plugin.zonedSchedule(
          id: id,
          title: s.title,
          body: "Today's ${s.type}: ${s.title} from ${_formatTime(s.start)}",
          scheduledDate: scheduledDate,
          notificationDetails: const NotificationDetails(android: androidDetails, iOS: iosDetails),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: s.id,
        );
      }
      return id;
    } catch (e) {
      // Return null so the schedule creation does not fail
      return null;
    }
  }

  Future<int?> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'nowtifried_channel',
      'Nowtifried Notifications',
      channelDescription: 'Schedules and reminders',
      importance: Importance.max,
      priority: Priority.high,
      ongoing: false,
      ticker: 'Reminder',
    );
    const iosDetails = DarwinNotificationDetails();

    try {
      final now = tz.TZDateTime.now(tz.local);
      var tzDate = tz.TZDateTime.from(scheduledDate, tz.local);
      if (tzDate.isBefore(now)) return null;

      try {
        await _plugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: tzDate,
          notificationDetails: const NotificationDetails(android: androidDetails, iOS: iosDetails),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      } catch (_) {
        await _plugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: tzDate,
          notificationDetails: const NotificationDetails(android: androidDetails, iOS: iosDetails),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
      return id;
    } catch (_) {
      return null;
    }
  }

  Future<void> cancel(int id) async {
    try {
      await _plugin.cancel(id: id);
    } catch (_) {}
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
