// GENERATED CODE - manual adapter
import 'package:hive/hive.dart';
import 'schedule.dart';

class ScheduleAdapter extends TypeAdapter<Schedule> {
  @override
  final int typeId = 1;

  @override
  Schedule read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < numOfFields; i++) {
      final key = reader.readByte();
      fields[key] = reader.read();
    }
    return Schedule(
      id: fields[0] as String,
      title: fields[1] as String,
      type: fields[2] as String,
      start: DateTime.parse(fields[3] as String),
      end: DateTime.parse(fields[4] as String),
      colorValue: fields[5] as int,
      notificationId: fields[6] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, Schedule obj) {
    writer.writeByte(7);
    writer.writeByte(0);
    writer.write(obj.id);
    writer.writeByte(1);
    writer.write(obj.title);
    writer.writeByte(2);
    writer.write(obj.type);
    writer.writeByte(3);
    writer.write(obj.start.toIso8601String());
    writer.writeByte(4);
    writer.write(obj.end.toIso8601String());
    writer.writeByte(5);
    writer.write(obj.colorValue);
    writer.writeByte(6);
    writer.write(obj.notificationId);
  }
}
