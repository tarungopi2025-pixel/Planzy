import 'package:hive/hive.dart';

import '../models/task.dart';
import '../models/settings.dart';
import '../models/xp_history.dart';

import 'achievement_service.dart';
import 'streak_service.dart';
import 'audio_service.dart';

class XPResult {
  final int xpChange;
  final bool leveledUp;

  XPResult(this.xpChange, this.leveledUp);
}

class XPService {
  static const int xpPerTask = 10;
  static const int firstLevelRequirement = 100;
  static const int levelRequirementIncrease = 50;

  static Future<XPResult> addXP(Task task) async {
    final settingsBox = Hive.box<Settings>('settings');
    final historyBox = Hive.box<XPHistory>('xp_history');

    final settings = _getSettings(settingsBox);

    final oldLevel = settings.currentLevel;
    final xpGain = xpPerTask;

    settings.totalXP += xpGain;
    settings.currentLevel = calculateLevel(settings.totalXP);

    await settings.save();

    await historyBox.add(
      XPHistory(
        date: DateTime.now(),
        xpEarned: xpGain,
        tasksCompleted: 1,
        productivityScore: 0,
      ),
    );

    await StreakService.updateStreak();

    final newlyUnlocked = await AchievementService.checkAndUnlock();

    await AudioService.playComplete();

    if (newlyUnlocked.isNotEmpty) {
      await AudioService.playAchievement();
    }

    final leveledUp = settings.currentLevel > oldLevel;

    if (leveledUp) {
      await AudioService.playLevelUp();
    }

    return XPResult(xpGain, leveledUp);
  }

  static Future<XPResult> addFocusXP({
    required int xpAmount,
  }) async {
    final settingsBox = Hive.box<Settings>('settings');
    final historyBox = Hive.box<XPHistory>('xp_history');

    final settings = _getSettings(settingsBox);

    final oldLevel = settings.currentLevel;

    settings.totalXP += xpAmount;
    settings.currentLevel = calculateLevel(settings.totalXP);

    await settings.save();

    await historyBox.add(
      XPHistory(
        date: DateTime.now(),
        xpEarned: xpAmount,
        tasksCompleted: 0,
        productivityScore: 0,
      ),
    );

    final newlyUnlocked = await AchievementService.checkAndUnlock();

    if (newlyUnlocked.isNotEmpty) {
      await AudioService.playAchievement();
    }

    final leveledUp = settings.currentLevel > oldLevel;

    if (leveledUp) {
      await AudioService.playLevelUp();
    }

    return XPResult(xpAmount, leveledUp);
  }

  static Future<XPResult> removeXP(Task task) async {
    final settingsBox = Hive.box<Settings>('settings');
    final settings = _getSettings(settingsBox);

    settings.totalXP -= xpPerTask;

    if (settings.totalXP < 0) {
      settings.totalXP = 0;
    }

    settings.currentLevel = calculateLevel(settings.totalXP);

    await settings.save();

    return XPResult(-xpPerTask, false);
  }

  static int calculateLevel(int totalXP) {
    int level = 1;
    int remainingXP = totalXP;

    while (remainingXP >= xpNeededForLevel(level)) {
      remainingXP -= xpNeededForLevel(level);
      level++;
    }

    return level;
  }

  static int xpNeededForLevel(int level) {
    return firstLevelRequirement + ((level - 1) * levelRequirementIncrease);
  }

  static int xpAtStartOfLevel(int level) {
    int total = 0;

    for (int i = 1; i < level; i++) {
      total += xpNeededForLevel(i);
    }

    return total;
  }

  static int xpIntoCurrentLevel(int totalXP) {
    final level = calculateLevel(totalXP);
    final levelStartXP = xpAtStartOfLevel(level);

    return totalXP - levelStartXP;
  }

  static int xpNeededForCurrentLevel(int totalXP) {
    final level = calculateLevel(totalXP);
    return xpNeededForLevel(level);
  }

  static double progressToNextLevel(int totalXP) {
    final currentXP = xpIntoCurrentLevel(totalXP);
    final neededXP = xpNeededForCurrentLevel(totalXP);

    if (neededXP <= 0) return 0;

    return (currentXP / neededXP).clamp(0, 1).toDouble();
  }

  static Settings _getSettings(Box<Settings> box) {
    if (box.isEmpty) {
      final settings = Settings(
        totalXP: 0,
        currentLevel: 1,
      );

      box.add(settings);
      return settings;
    }

    return box.getAt(0)!;
  }
}
