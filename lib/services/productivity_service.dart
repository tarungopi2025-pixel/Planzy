import 'package:hive/hive.dart';

import '../models/task.dart';
import '../models/xp_history.dart';
import '../models/streak.dart';

class ProductivityService {
  static int calculateProductivityScore() {
    final xpBox = Hive.box<XPHistory>('xp_history');
    final taskBox = Hive.box<Task>('tasks');
    final streakBox = Hive.box<Streak>('streak');

    final xpHistory = xpBox.values.toList();
    final tasks = taskBox.values.toList();
    final streak = streakBox.isNotEmpty ? streakBox.getAt(0)! : null;

    // =========================
    // 1. COMPLETION SCORE (0–40)
    // Stable even if no tasks exist
    // =========================
    final completedTasks = tasks.where((t) => t.isCompleted).length;

    final completionScore = tasks.isEmpty
        ? 30 // baseline stability (prevents reset to 0)
        : (completedTasks / tasks.length) * 40;

    // =========================
    // 2. XP PERFORMANCE (0–30)
    // =========================
    final totalXP = xpHistory.fold<int>(
      0,
      (sum, item) => sum + item.xpEarned,
    );

    final xpScore = (totalXP / 500).clamp(0, 1) * 30;

    // =========================
    // 3. STREAK SCORE (0–20)
    // =========================
    final streakScore = (streak?.currentStreak ?? 0).clamp(0, 10) * 2;

    // =========================
    // 4. ACTIVITY SCORE (0–10)
    // =========================
    final activityScore = xpHistory.length.clamp(0, 10);

    final total = completionScore + xpScore + streakScore + activityScore;

    return total.round().clamp(0, 100);
  }

  static String getProductivityLevel(int score) {
    if (score < 30) return "Beginner";
    if (score < 55) return "Focused";
    if (score < 75) return "Productive";
    if (score < 90) return "Highly Productive";
    return "Elite Performer";
  }
}
