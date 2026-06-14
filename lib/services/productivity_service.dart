import 'package:hive/hive.dart';

import '../models/task.dart';
import '../models/xp_history.dart';
import '../models/streak.dart';

class ProductivityService {
  static int calculateProductivityScore() {
    final taskBox = Hive.box<Task>('tasks');
    final xpBox = Hive.box<XPHistory>('xp_history');
    final streakBox = Hive.box<Streak>('streak');

    final tasks = taskBox.values.toList();
    final xpHistory = xpBox.values.toList();
    final streak = streakBox.isNotEmpty ? streakBox.getAt(0)! : null;

    if (tasks.isEmpty) return 0;

    // Completion score (0–40)
    final completed = tasks.where((t) => t.isCompleted).length;
    final completionScore = (completed / tasks.length) * 40;

    // XP score (0–30)
    final totalXP = xpHistory.fold<int>(
      0,
      (sum, item) => sum + item.xpEarned,
    );
    final xpScore = (totalXP / 500).clamp(0, 1) * 30;

    // Streak score (0–20)
    final streakScore =
        streak == null ? 0 : streak.currentStreak.clamp(0, 10) * 2;

    // Activity score (0–10)
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
