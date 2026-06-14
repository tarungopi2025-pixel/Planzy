import 'package:hive/hive.dart';

import '../models/achievement.dart';
import '../models/settings.dart';
import '../models/streak.dart';
import '../models/xp_history.dart';

class AchievementService {
  static Future<void> initAchievements() async {
    final box = Hive.box<Achievement>('achievements');

    final defaultAchievements = <Achievement>[
      // ================= TASK ACHIEVEMENTS =================
      Achievement(
        id: "task_001",
        title: "First Step",
        description: "Complete your first task.",
        category: AchievementCategory.task,
      ),
      Achievement(
        id: "task_003",
        title: "Getting Started",
        description: "Complete 3 tasks.",
        category: AchievementCategory.task,
      ),
      Achievement(
        id: "task_005",
        title: "Task Builder",
        description: "Complete 5 tasks.",
        category: AchievementCategory.task,
      ),
      Achievement(
        id: "task_010",
        title: "Daily Grinder",
        description: "Complete 10 tasks.",
        category: AchievementCategory.task,
      ),
      Achievement(
        id: "task_020",
        title: "Focused Worker",
        description: "Complete 20 tasks.",
        category: AchievementCategory.task,
      ),
      Achievement(
        id: "task_030",
        title: "Consistency Maker",
        description: "Complete 30 tasks.",
        category: AchievementCategory.task,
      ),
      Achievement(
        id: "task_050",
        title: "Productivity Machine",
        description: "Complete 50 tasks.",
        category: AchievementCategory.task,
      ),
      Achievement(
        id: "task_075",
        title: "Deep Work Mode",
        description: "Complete 75 tasks.",
        category: AchievementCategory.task,
      ),
      Achievement(
        id: "task_100",
        title: "Task Master",
        description: "Complete 100 tasks.",
        category: AchievementCategory.task,
      ),

      // ================= XP ACHIEVEMENTS =================
      Achievement(
        id: "xp_050",
        title: "XP Starter",
        description: "Earn 50 XP.",
        category: AchievementCategory.xp,
      ),
      Achievement(
        id: "xp_100",
        title: "Level Climber",
        description: "Earn 100 XP.",
        category: AchievementCategory.xp,
      ),
      Achievement(
        id: "xp_250",
        title: "Momentum Builder",
        description: "Earn 250 XP.",
        category: AchievementCategory.xp,
      ),
      Achievement(
        id: "xp_500",
        title: "XP Collector",
        description: "Earn 500 XP.",
        category: AchievementCategory.xp,
      ),
      Achievement(
        id: "xp_1000",
        title: "Power Performer",
        description: "Earn 1000 XP.",
        category: AchievementCategory.xp,
      ),
      Achievement(
        id: "xp_1500",
        title: "Productivity Hero",
        description: "Earn 1500 XP.",
        category: AchievementCategory.xp,
      ),
      Achievement(
        id: "xp_2500",
        title: "Elite Achiever",
        description: "Earn 2500 XP.",
        category: AchievementCategory.xp,
      ),

      // ================= STREAK ACHIEVEMENTS =================
      Achievement(
        id: "streak_001",
        title: "Day One Discipline",
        description: "Build a 1 day streak.",
        category: AchievementCategory.streak,
      ),
      Achievement(
        id: "streak_003",
        title: "Three Day Spark",
        description: "Build a 3 day streak.",
        category: AchievementCategory.streak,
      ),
      Achievement(
        id: "streak_005",
        title: "Routine Starter",
        description: "Build a 5 day streak.",
        category: AchievementCategory.streak,
      ),
      Achievement(
        id: "streak_007",
        title: "One Week Strong",
        description: "Build a 7 day streak.",
        category: AchievementCategory.streak,
      ),
      Achievement(
        id: "streak_014",
        title: "Two Week Warrior",
        description: "Build a 14 day streak.",
        category: AchievementCategory.streak,
      ),
      Achievement(
        id: "streak_021",
        title: "Habit Builder",
        description: "Build a 21 day streak.",
        category: AchievementCategory.streak,
      ),
      Achievement(
        id: "streak_030",
        title: "Monthly Discipline",
        description: "Build a 30 day streak.",
        category: AchievementCategory.streak,
      ),
      Achievement(
        id: "streak_050",
        title: "Unbreakable Focus",
        description: "Build a 50 day streak.",
        category: AchievementCategory.streak,
      ),
      Achievement(
        id: "streak_100",
        title: "Legendary Consistency",
        description: "Build a 100 day streak.",
        category: AchievementCategory.streak,
      ),

      // ================= CONSISTENCY / CHALLENGE ACHIEVEMENTS =================
      Achievement(
        id: "consistency_002_days",
        title: "Back Again",
        description: "Complete tasks on 2 different days.",
        category: AchievementCategory.challenge,
      ),
      Achievement(
        id: "consistency_005_days",
        title: "Showing Up",
        description: "Complete tasks on 5 different days.",
        category: AchievementCategory.challenge,
      ),
      Achievement(
        id: "consistency_010_days",
        title: "Reliable Performer",
        description: "Complete tasks on 10 different days.",
        category: AchievementCategory.challenge,
      ),
      Achievement(
        id: "consistency_020_days",
        title: "Consistency Engine",
        description: "Complete tasks on 20 different days.",
        category: AchievementCategory.challenge,
      ),
      Achievement(
        id: "consistency_030_days",
        title: "Discipline Architect",
        description: "Complete tasks on 30 different days.",
        category: AchievementCategory.challenge,
      ),
    ];

    for (final achievement in defaultAchievements) {
      final alreadyExists = box.values.any((item) => item.id == achievement.id);

      if (!alreadyExists) {
        await box.add(achievement);
      }
    }
  }

  static Future<List<Achievement>> checkAndUnlock() async {
    await initAchievements();

    final achievementBox = Hive.box<Achievement>('achievements');
    final settingsBox = Hive.box<Settings>('settings');
    final streakBox = Hive.box<Streak>('streak');
    final xpHistoryBox = Hive.box<XPHistory>('xp_history');

    final settings = settingsBox.isNotEmpty ? settingsBox.getAt(0) : null;
    final streak = streakBox.isNotEmpty ? streakBox.getAt(0) : null;

    final totalXP = settings?.totalXP ?? 0;

    final positiveHistory =
        xpHistoryBox.values.where((item) => item.xpEarned > 0).toList();

    final completedTasks = positiveHistory.fold<int>(
      0,
      (sum, item) => sum + item.tasksCompleted,
    );

    final activeStreak = streak?.currentStreak ?? 0;

    final uniqueDays = positiveHistory
        .map(
          (item) => DateTime(
            item.date.year,
            item.date.month,
            item.date.day,
          ).toString(),
        )
        .toSet()
        .length;

    final newlyUnlocked = <Achievement>[];

    for (final achievement in achievementBox.values) {
      if (achievement.unlocked) continue;

      final shouldUnlock = _shouldUnlock(
        id: achievement.id,
        completedTasks: completedTasks,
        totalXP: totalXP,
        activeStreak: activeStreak,
        uniqueDays: uniqueDays,
      );

      if (shouldUnlock) {
        achievement.unlocked = true;
        achievement.unlockedAt = DateTime.now();
        await achievement.save();

        newlyUnlocked.add(achievement);
      }
    }

    return newlyUnlocked;
  }

  static Future<List<Achievement>> unlockTaskAchievements(
    int totalTasks,
    int completedTasks,
  ) async {
    return checkAndUnlock();
  }

  static bool _shouldUnlock({
    required String id,
    required int completedTasks,
    required int totalXP,
    required int activeStreak,
    required int uniqueDays,
  }) {
    switch (id) {
      // ================= TASK =================
      case "task_001":
        return completedTasks >= 1;
      case "task_003":
        return completedTasks >= 3;
      case "task_005":
        return completedTasks >= 5;
      case "task_010":
        return completedTasks >= 10;
      case "task_020":
        return completedTasks >= 20;
      case "task_030":
        return completedTasks >= 30;
      case "task_050":
        return completedTasks >= 50;
      case "task_075":
        return completedTasks >= 75;
      case "task_100":
        return completedTasks >= 100;

      // ================= XP =================
      case "xp_050":
        return totalXP >= 50;
      case "xp_100":
        return totalXP >= 100;
      case "xp_250":
        return totalXP >= 250;
      case "xp_500":
        return totalXP >= 500;
      case "xp_1000":
        return totalXP >= 1000;
      case "xp_1500":
        return totalXP >= 1500;
      case "xp_2500":
        return totalXP >= 2500;

      // ================= STREAK =================
      case "streak_001":
        return activeStreak >= 1;
      case "streak_003":
        return activeStreak >= 3;
      case "streak_005":
        return activeStreak >= 5;
      case "streak_007":
        return activeStreak >= 7;
      case "streak_014":
        return activeStreak >= 14;
      case "streak_021":
        return activeStreak >= 21;
      case "streak_030":
        return activeStreak >= 30;
      case "streak_050":
        return activeStreak >= 50;
      case "streak_100":
        return activeStreak >= 100;

      // ================= CONSISTENCY =================
      case "consistency_002_days":
        return uniqueDays >= 2;
      case "consistency_005_days":
        return uniqueDays >= 5;
      case "consistency_010_days":
        return uniqueDays >= 10;
      case "consistency_020_days":
        return uniqueDays >= 20;
      case "consistency_030_days":
        return uniqueDays >= 30;

      default:
        return false;
    }
  }
}
