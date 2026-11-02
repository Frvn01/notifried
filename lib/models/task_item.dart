import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

@HiveType(typeId: 2)
class TaskItem extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String type; // 'quiz', 'exam', 'activity', 'homework', 'project', 'reminder'

  @HiveField(3)
  DateTime dueDate;

  @HiveField(4)
  String? subject; // e.g. "Calculus 101", "CS 50"

  @HiveField(5)
  int priority; // 0=Low, 1=Medium, 2=High

  @HiveField(6)
  bool isDone;

  @HiveField(7)
  String? notes;

  @HiveField(8)
  List<String> subtasks;

  @HiveField(9)
  int colorValue;

  @HiveField(10)
  int? notificationId;

  @HiveField(11)
  DateTime createdAt;

  TaskItem({
    required this.id,
    required this.title,
    required this.type,
    required this.dueDate,
    this.subject,
    this.priority = 1,
    this.isDone = false,
    this.notes,
    List<String>? subtasks,
    required this.colorValue,
    this.notificationId,
    DateTime? createdAt,
  })  : subtasks = subtasks ?? [],
        createdAt = createdAt ?? DateTime.now();

  bool get isOverdue => !isDone && dueDate.isBefore(DateTime.now());

  bool get isDueToday {
    final now = DateTime.now();
    return dueDate.year == now.year &&
        dueDate.month == now.month &&
        dueDate.day == now.day;
  }

  bool get isDueTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return dueDate.year == tomorrow.year &&
        dueDate.month == tomorrow.month &&
        dueDate.day == tomorrow.day;
  }

  String get dueFormatted {
    if (isDueToday) {
      return 'Today at ${DateFormat('h:mm a').format(dueDate)}';
    } else if (isDueTomorrow) {
      return 'Tomorrow at ${DateFormat('h:mm a').format(dueDate)}';
    }
    return DateFormat('MMM d, h:mm a').format(dueDate);
  }

  String get priorityLabel {
    switch (priority) {
      case 2:
        return 'High';
      case 1:
        return 'Medium';
      case 0:
      default:
        return 'Low';
    }
  }

  Color get priorityColor {
    switch (priority) {
      case 2:
        return const Color(0xFFFF3B30); // Apple Red
      case 1:
        return const Color(0xFFFF9500); // Apple Orange
      case 0:
      default:
        return const Color(0xFF34C759); // Apple Green
    }
  }

  IconData get typeIcon {
    switch (type.toLowerCase()) {
      case 'quiz':
        return CupertinoIcons.lab_flask_solid;
      case 'exam':
        return CupertinoIcons.doc_plaintext;
      case 'activity':
        return CupertinoIcons.flag_fill;
      case 'homework':
        return CupertinoIcons.book_fill;
      case 'project':
        return CupertinoIcons.folder_fill;
      case 'reminder':
      default:
        return CupertinoIcons.bell_fill;
    }
  }

  String get typeLabel {
    switch (type.toLowerCase()) {
      case 'quiz':
        return 'Quiz';
      case 'exam':
        return 'Exam';
      case 'activity':
        return 'Activity';
      case 'homework':
        return 'Homework';
      case 'project':
        return 'Project';
      case 'reminder':
      default:
        return 'Reminder';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'dueDate': dueDate.toIso8601String(),
      'subject': subject,
      'priority': priority,
      'isDone': isDone,
      'notes': notes,
      'subtasks': subtasks,
      'colorValue': colorValue,
      'notificationId': notificationId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TaskItem.fromMap(Map<String, dynamic> m) {
    return TaskItem(
      id: m['id'] as String,
      title: m['title'] as String,
      type: (m['type'] as String?) ?? 'activity',
      dueDate: DateTime.parse(m['dueDate'] as String),
      subject: m['subject'] as String?,
      priority: (m['priority'] as int?) ?? 1,
      isDone: (m['isDone'] as bool?) ?? false,
      notes: m['notes'] as String?,
      subtasks: (m['subtasks'] as List?)?.cast<String>() ?? [],
      colorValue: (m['colorValue'] as int?) ?? 0xFF5960A0,
      notificationId: m['notificationId'] as int?,
      createdAt: m['createdAt'] != null
          ? DateTime.parse(m['createdAt'] as String)
          : DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());

  factory TaskItem.fromJson(String source) =>
      TaskItem.fromMap(json.decode(source) as Map<String, dynamic>);
}

class TaskItemAdapter extends TypeAdapter<TaskItem> {
  @override
  final int typeId = 2;

  @override
  TaskItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TaskItem(
      id: fields[0] as String,
      title: fields[1] as String,
      type: (fields[2] as String?) ?? 'activity',
      dueDate: fields[3] as DateTime,
      subject: fields[4] as String?,
      priority: (fields[5] as int?) ?? 1,
      isDone: (fields[6] as bool?) ?? false,
      notes: fields[7] as String?,
      subtasks: (fields[8] as List?)?.cast<String>() ?? [],
      colorValue: (fields[9] as int?) ?? 0xFF5960A0,
      notificationId: fields[10] as int?,
      createdAt: fields[11] as DateTime? ?? DateTime.now(),
    );
  }

  @override
  void write(BinaryWriter writer, TaskItem obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.dueDate)
      ..writeByte(4)
      ..write(obj.subject)
      ..writeByte(5)
      ..write(obj.priority)
      ..writeByte(6)
      ..write(obj.isDone)
      ..writeByte(7)
      ..write(obj.notes)
      ..writeByte(8)
      ..write(obj.subtasks)
      ..writeByte(9)
      ..write(obj.colorValue)
      ..writeByte(10)
      ..write(obj.notificationId)
      ..writeByte(11)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
