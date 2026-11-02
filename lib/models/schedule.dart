import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';

part 'schedule.g.dart';

@HiveType(typeId: 1)
class Schedule extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String type; // school, work, reminder, goal

  @HiveField(3)
  DateTime start;

  @HiveField(4)
  DateTime end;

  @HiveField(5)
  int colorValue;

  @HiveField(6)
  int? notificationId;

  @HiveField(7)
  List<int>? daysOfWeek;

  @HiveField(8)
  String? room;

  Schedule({
    required this.id,
    required this.title,
    required this.type,
    required this.start,
    required this.end,
    required this.colorValue,
    this.notificationId,
    this.daysOfWeek,
    this.room,
  });

  String get timeRangeFormatted {
    final startFmt = DateFormat('h:mm').format(start);
    final endFmt = DateFormat('h:mm a').format(end);
    return '$startFmt-$endFmt';
  }

  String get durationFormatted {
    final diff = end.difference(start);
    final hours = diff.inHours;
    final mins = diff.inMinutes % 60;
    if (hours > 0 && mins > 0) {
      return '${hours}h ${mins}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${mins > 0 ? mins : 30}m';
    }
  }

  DateTime get todayStart {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, start.hour, start.minute);
  }

  DateTime get todayEnd {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, end.hour, end.minute);
  }

  bool get isSchool => type.toLowerCase() == 'school';

  bool get isToday {
    final now = DateTime.now();
    if (isSchool) {
      if (daysOfWeek != null && daysOfWeek!.isNotEmpty) {
        return daysOfWeek!.contains(now.weekday);
      }
      return start.weekday == now.weekday;
    }
    return start.year == now.year && start.month == now.month && start.day == now.day;
  }

  bool get isPastDue {
    if (isSchool) {
      if (!isToday) return false;
      return DateTime.now().isAfter(todayEnd);
    }
    return end.isBefore(DateTime.now());
  }

  bool get isInProgress {
    final now = DateTime.now();
    if (isSchool) {
      if (!isToday) return false;
      return now.isAfter(todayStart) && now.isBefore(todayEnd);
    }
    return now.isAfter(start) && now.isBefore(end);
  }

  DateTime get nextOccurrence {
    final now = DateTime.now();
    if (isSchool) {
      if (isToday && now.isBefore(todayEnd)) {
        return todayStart;
      }
      final days = daysOfWeek ?? [start.weekday];
      if (days.isEmpty) return start;
      int minDaysAhead = 7;
      for (final d in days) {
        int diff = d - now.weekday;
        if (diff <= 0) diff += 7;
        if (diff < minDaysAhead) minDaysAhead = diff;
      }
      final targetDate = now.add(Duration(days: minDaysAhead));
      return DateTime(
        targetDate.year,
        targetDate.month,
        targetDate.day,
        start.hour,
        start.minute,
      );
    }
    return start;
  }

  int get minutesUntilNext {
    final now = DateTime.now();
    final next = nextOccurrence;
    final diff = next.difference(now).inMinutes;
    return diff > 0 ? diff : 0;
  }

  String get countdownStatus {
    final now = DateTime.now();
    if (isSchool) {
      if (isToday) {
        final tStart = todayStart;
        final tEnd = todayEnd;
        if (now.isBefore(tStart)) {
          final diff = tStart.difference(now);
          if (diff.inMinutes <= 0) return 'Starting now';
          if (diff.inMinutes < 60) return 'Starts in ${diff.inMinutes}m';
          final m = diff.inMinutes % 60;
          return m > 0 ? 'Starts in ${diff.inHours}h ${m}m' : 'Starts in ${diff.inHours}h';
        } else if (now.isAfter(tStart) && now.isBefore(tEnd)) {
          final left = tEnd.difference(now).inMinutes;
          return 'In Progress (${left > 0 ? '$left' : '1'}m left)';
        } else {
          return 'Completed today';
        }
      } else {
        final days = daysOfWeek ?? [start.weekday];
        if (days.isEmpty) return 'Repeats weekly';
        int minDaysAhead = 7;
        for (final d in days) {
          int diff = d - now.weekday;
          if (diff <= 0) diff += 7;
          if (diff < minDaysAhead) minDaysAhead = diff;
        }
        return minDaysAhead == 1 ? 'Tomorrow' : 'In $minDaysAhead days';
      }
    }

    if (now.isBefore(start)) {
      final diff = start.difference(now);
      if (diff.inMinutes <= 0) {
        return 'Starting now';
      } else if (diff.inMinutes < 60) {
        return 'Starts in ${diff.inMinutes}m';
      } else if (diff.inHours < 24) {
        final m = diff.inMinutes % 60;
        return m > 0 ? 'Starts in ${diff.inHours}h ${m}m' : 'Starts in ${diff.inHours}h';
      } else {
        return 'Starts in ${diff.inDays}d';
      }
    } else if (now.isAfter(start) && now.isBefore(end)) {
      final left = end.difference(now).inMinutes;
      return 'In Progress (${left > 0 ? '$left' : '1'}m left)';
    } else {
      return 'Completed';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
      'colorValue': colorValue,
      'notificationId': notificationId,
      'daysOfWeek': daysOfWeek,
      'room': room,
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
      daysOfWeek: m['daysOfWeek'] != null ? List<int>.from(m['daysOfWeek']) : null,
      room: m['room'] as String?,
    );
  }

  String toJson() => json.encode(toMap());

  factory Schedule.fromJson(String source) => Schedule.fromMap(json.decode(source));
}
