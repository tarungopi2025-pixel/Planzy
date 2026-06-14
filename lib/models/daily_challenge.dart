import 'package:hive/hive.dart';

part 'daily_challenge.g.dart';

@HiveType(typeId: 7)
class DailyChallenge extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  int target;

  @HiveField(3)
  int progress;

  @HiveField(4)
  int rewardXP;

  @HiveField(5)
  bool completed;

  @HiveField(6)
  DateTime generatedDate;

  DailyChallenge({
    required this.id,
    required this.title,
    required this.target,
    required this.rewardXP,
    required this.generatedDate,
    this.progress = 0,
    this.completed = false,
  });
}
