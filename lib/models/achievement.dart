import 'package:hive/hive.dart';

part 'achievement.g.dart';

@HiveType(typeId: 4)
enum AchievementCategory {
  @HiveField(0)
  task,

  @HiveField(1)
  xp,

  @HiveField(2)
  streak,

  @HiveField(3)
  challenge,
}

@HiveType(typeId: 5)
class Achievement extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String description;

  @HiveField(3)
  AchievementCategory category;

  @HiveField(4)
  bool unlocked;

  @HiveField(5)
  DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.unlocked = false,
    this.unlockedAt,
  });
}
