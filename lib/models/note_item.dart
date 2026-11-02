import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

@HiveType(typeId: 3)
class NoteItem extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String body;

  @HiveField(3)
  DateTime createdAt;

  @HiveField(4)
  DateTime? updatedAt;

  @HiveField(5)
  String tag; // 'general', 'quiz', 'exam', 'activity'

  @HiveField(6)
  int colorValue;

  @HiveField(7)
  bool isPinned;

  @HiveField(8)
  String? subject;

  NoteItem({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.updatedAt,
    this.tag = 'general',
    required this.colorValue,
    this.isPinned = false,
    this.subject,
  });

  IconData get tagIcon {
    switch (tag.toLowerCase()) {
      case 'quiz':
        return CupertinoIcons.lab_flask_solid;
      case 'exam':
        return CupertinoIcons.doc_plaintext;
      case 'activity':
        return CupertinoIcons.flag_fill;
      case 'general':
      default:
        return CupertinoIcons.pencil_outline;
    }
  }

  String get tagLabel {
    switch (tag.toLowerCase()) {
      case 'quiz':
        return 'Quiz Reviewer';
      case 'exam':
        return 'Exam Notes';
      case 'activity':
        return 'Activity Guide';
      case 'general':
      default:
        return 'General Note';
    }
  }

  String get formattedDate {
    final d = updatedAt ?? createdAt;
    return DateFormat('MMM d, h:mm a').format(d);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'tag': tag,
      'colorValue': colorValue,
      'isPinned': isPinned,
      'subject': subject,
    };
  }

  factory NoteItem.fromMap(Map<String, dynamic> m) {
    return NoteItem(
      id: m['id'] as String,
      title: m['title'] as String,
      body: m['body'] as String,
      createdAt: DateTime.parse(m['createdAt'] as String),
      updatedAt: m['updatedAt'] != null
          ? DateTime.parse(m['updatedAt'] as String)
          : null,
      tag: (m['tag'] as String?) ?? 'general',
      colorValue: (m['colorValue'] as int?) ?? 0xFF5960A0,
      isPinned: (m['isPinned'] as bool?) ?? false,
      subject: m['subject'] as String?,
    );
  }

  String toJson() => json.encode(toMap());

  factory NoteItem.fromJson(String source) =>
      NoteItem.fromMap(json.decode(source) as Map<String, dynamic>);
}

class NoteItemAdapter extends TypeAdapter<NoteItem> {
  @override
  final int typeId = 3;

  @override
  NoteItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NoteItem(
      id: fields[0] as String,
      title: fields[1] as String,
      body: fields[2] as String,
      createdAt: fields[3] as DateTime,
      updatedAt: fields[4] as DateTime?,
      tag: (fields[5] as String?) ?? 'general',
      colorValue: (fields[6] as int?) ?? 0xFF5960A0,
      isPinned: (fields[7] as bool?) ?? false,
      subject: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, NoteItem obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.body)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.updatedAt)
      ..writeByte(5)
      ..write(obj.tag)
      ..writeByte(6)
      ..write(obj.colorValue)
      ..writeByte(7)
      ..write(obj.isPinned)
      ..writeByte(8)
      ..write(obj.subject);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

