import 'package:hive/hive.dart';

part 'settings.g.dart';

@HiveType(typeId: 2)
class Settings extends HiveObject {
  @HiveField(0)
  bool isDarkMode;

  @HiveField(1)
  int totalXP;

  @HiveField(2)
  int currentLevel;

  @HiveField(3)
  bool firstLaunch;

  Settings({
    this.isDarkMode = false,
    this.totalXP = 0,
    this.currentLevel = 1,
    this.firstLaunch = true,
  });
}
