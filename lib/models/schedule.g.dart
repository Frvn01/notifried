// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ScheduleAdapter extends TypeAdapter<Schedule> {
  @override
  final int typeId = 1;

  @override
  Schedule read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Schedule(
      id: fields[0] as String,
      title: fields[1] as String,
      type: fields[2] as String,
      start: fields[3] as DateTime,
      end: fields[4] as DateTime,
      colorValue: fields[5] as int,
      notificationId: fields[6] as int?,
      daysOfWeek: (fields[7] as List?)?.cast<int>(),
      room: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Schedule obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.start)
      ..writeByte(4)
      ..write(obj.end)
      ..writeByte(5)
      ..write(obj.colorValue)
      ..writeByte(6)
      ..write(obj.notificationId)
      ..writeByte(7)
      ..write(obj.daysOfWeek)
      ..writeByte(8)
      ..write(obj.room);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
