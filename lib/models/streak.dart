import 'package:hive/hive.dart';

part 'streak.g.dart';

@HiveType(typeId: 3)
class Streak extends HiveObject {
  @HiveField(0)
  int currentStreak;

  @HiveField(1)
  int longestStreak;

  @HiveField(2)
  DateTime lastActiveDate;

  Streak({
    required this.currentStreak,
    required this.longestStreak,
    required this.lastActiveDate,
  });
}
