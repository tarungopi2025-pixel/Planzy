import 'package:hive/hive.dart';

import '../models/task.dart';
import '../models/settings.dart';
import '../models/xp_history.dart';
import 'achievement_service.dart';

class XPService {
  static const int baseXP = 10;

  static Future<void> addXP(Task task) async {
    final settingsBox = Hive.box<Settings>('settings');
    final historyBox = Hive.box<XPHistory>('xp_history');

    final settings = _getSettings(settingsBox);

    final xpGain = _calculateXP(task);

    // update total XP
    settings.totalXP += xpGain;
    settings.currentLevel = _calculateLevel(settings.totalXP);
    await settings.save();

    // store history (IMPORTANT: consistent field usage)
    await _addHistory(historyBox, xpGain, task);

    await AchievementService.checkAndUnlock();
  }

  static Future<void> removeXP(Task task) async {
    final settingsBox = Hive.box<Settings>('settings');
    final historyBox = Hive.box<XPHistory>('xp_history');

    final settings = _getSettings(settingsBox);

    final xpLoss = _calculateXP(task);

    settings.totalXP -= xpLoss;

    if (settings.totalXP < 0) {
      settings.totalXP = 0;
    }

    settings.currentLevel = _calculateLevel(settings.totalXP);
    await settings.save();

    await _addHistory(historyBox, -xpLoss, task);

    await AchievementService.checkAndUnlock();
  }

  static int _calculateXP(Task task) {
    switch (task.priority) {
      case TaskPriority.low:
        return baseXP;
      case TaskPriority.medium:
        return baseXP * 2;
      case TaskPriority.high:
        return baseXP * 3;
    }
  }

  static int _calculateLevel(int xp) {
    return (xp / 100).floor() + 1;
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

  static Future<void> _addHistory(
    Box<XPHistory> box,
    int xp,
    Task task,
  ) async {
    final history = XPHistory(
      date: DateTime.now(),
      xpEarned: xp,
      tasksCompleted: task.isCompleted ? 1 : 0,
      productivityScore: 0,
    );

    await box.add(history);
  }
}
