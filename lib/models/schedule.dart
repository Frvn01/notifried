import 'dart:convert';
import 'package:hive/hive.dart';

part 'schedule.g.dart';

@HiveType(typeId: 1)
class Schedule extends HiveObject {
  String id;
  String title;
  String type; // school, work, reminder
  DateTime start;
  DateTime end;
  int colorValue;
  int? notificationId;

  Schedule({
    required this.id,
    required this.title,
    required this.type,
    required this.start,
    required this.end,
    required this.colorValue,
    this.notificationId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
      'colorValue': colorValue,
      'notificationId': notificationId,
    };
  }

  factory Schedule.fromMap(Map<String, dynamic> m) {
    return Schedule(
      id: m['id'],
      title: m['title'],
      type: m['type'],
      start: DateTime.parse(m['start']),
      end: DateTime.parse(m['end']),
      colorValue: m['colorValue'],
      notificationId: m['notificationId'],
    );
  }

  String toJson() => json.encode(toMap());

  factory Schedule.fromJson(String source) => Schedule.fromMap(json.decode(source));
}
