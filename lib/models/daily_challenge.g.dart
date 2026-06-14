// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_challenge.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DailyChallengeAdapter extends TypeAdapter<DailyChallenge> {
  @override
  final int typeId = 7;

  @override
  DailyChallenge read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyChallenge(
      id: fields[0] as String,
      title: fields[1] as String,
      target: fields[2] as int,
      rewardXP: fields[4] as int,
      generatedDate: fields[6] as DateTime,
      progress: fields[3] as int,
      completed: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, DailyChallenge obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.target)
      ..writeByte(3)
      ..write(obj.progress)
      ..writeByte(4)
      ..write(obj.rewardXP)
      ..writeByte(5)
      ..write(obj.completed)
      ..writeByte(6)
      ..write(obj.generatedDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyChallengeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
