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
  static const int baseXP = 10;

  /// =========================
  /// ADD XP (TASK COMPLETED)
  /// =========================
  static Future<XPResult> addXP(Task task) async {
    final settingsBox = Hive.box<Settings>('settings');
    final historyBox = Hive.box<XPHistory>('xp_history');

    final settings = _getSettings(settingsBox);
    final oldLevel = settings.currentLevel;

    final xpGain = _calculateXP(task);

    settings.totalXP += xpGain;
    settings.currentLevel = _calculateLevel(settings.totalXP);

    await settings.save();

    await _addHistory(historyBox, xpGain, task);

    await StreakService.updateStreak();
    await AchievementService.checkAndUnlock();
    await AudioService.playComplete();

    final leveledUp = settings.currentLevel > oldLevel;

    if (leveledUp) {
      await AudioService.playLevelUp();
    }

    return XPResult(xpGain, leveledUp);
  }

  /// =========================
  /// REMOVE XP (TASK UNCHECK)
  /// =========================
  static Future<XPResult> removeXP(Task task) async {
    final settingsBox = Hive.box<Settings>('settings');
    final settings = _getSettings(settingsBox);

    final xpLoss = _calculateXP(task);

    settings.totalXP -= xpLoss;
    if (settings.totalXP < 0) settings.totalXP = 0;

    settings.currentLevel = _calculateLevel(settings.totalXP);

    await settings.save();

    // IMPORTANT:
    // No history write on negative XP (prevents productivity inflation bugs)

    await AchievementService.checkAndUnlock();

    return XPResult(-xpLoss, false);
  }

  /// =========================
  /// XP CALCULATION (SOURCE OF TRUTH)
  /// =========================
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

  /// =========================
  /// LEVEL SYSTEM
  /// =========================
  static int _calculateLevel(int xp) {
    return (xp / 100).floor() + 1;
  }

  /// =========================
  /// SAFE SETTINGS ACCESS
  /// =========================
  static Settings _getSettings(Box<Settings> box) {
    if (box.isEmpty) {
      final s = Settings();
      box.add(s);
      return s;
    }
    return box.getAt(0)!;
  }

  /// =========================
  /// XP HISTORY TRACKER
  /// =========================
  static Future<void> _addHistory(
    Box<XPHistory> box,
    int xp,
    Task task,
  ) async {
    // ONLY store positive XP events
    if (xp <= 0) return;

    final history = XPHistory(
      date: DateTime.now(),
      xpEarned: xp,
      tasksCompleted: 1,
      productivityScore: 0,
    );

    await box.add(history);
  }
}
