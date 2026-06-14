import 'package:hive/hive.dart';

part 'streak.g.dart';

@HiveType(typeId: 3)
class Streak extends HiveObject {
  @HiveField(0)
  int currentStreak;

  @HiveField(1)
  int longestStreak;

  @HiveField(2)
  DateTime? lastActiveDate;

  @HiveField(3)
  int totalActiveDays;

  Streak({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastActiveDate,
    this.totalActiveDays = 0,
  });
}
