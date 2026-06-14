// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'xp_history.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class XPHistoryAdapter extends TypeAdapter<XPHistory> {
  @override
  final int typeId = 6;

  @override
  XPHistory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return XPHistory(
      date: fields[0] as DateTime,
      xpEarned: fields[1] as int,
      tasksCompleted: fields[2] as int,
      productivityScore: fields[3] as double,
    );
  }

  @override
  void write(BinaryWriter writer, XPHistory obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.xpEarned)
      ..writeByte(2)
      ..write(obj.tasksCompleted)
      ..writeByte(3)
      ..write(obj.productivityScore);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is XPHistoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
