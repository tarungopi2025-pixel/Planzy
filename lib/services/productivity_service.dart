import 'package:hive/hive.dart';

import '../models/task.dart';
import '../models/xp_history.dart';
import '../models/streak.dart';

class ProductivityService {
  static int calculateProductivityScore() {
    final taskBox = Hive.box<Task>('tasks');
    final historyBox = Hive.box<XPHistory>('xp_history');
    final streakBox = Hive.box<Streak>('streak');

    final now = DateTime.now();
    final today = _dateOnly(now);
    final sevenDaysAgo = today.subtract(const Duration(days: 6));

    final allHistory =
        historyBox.values.where((history) => history.xpEarned > 0).toList();

    if (allHistory.isEmpty) return 0;

    final recentHistory = allHistory.where((history) {
      final date = _dateOnly(history.date);
      return !date.isBefore(sevenDaysAgo) && !date.isAfter(today);
    }).toList();

    final activeTasks = taskBox.values.toList();

    final streak = streakBox.isNotEmpty ? streakBox.getAt(0) : null;

    final totalRecentXP = recentHistory.fold<int>(
      0,
      (sum, history) => sum + history.xpEarned,
    );

    final completedRecentTasks = recentHistory.fold<int>(
      0,
      (sum, history) => sum + history.tasksCompleted,
    );

    final completedLifetimeTasks = allHistory.fold<int>(
      0,
      (sum, history) => sum + history.tasksCompleted,
    );

    final activePendingTasks =
        activeTasks.where((task) => !task.isCompleted).length;

    final overdueTasks = activeTasks.where((task) {
      if (task.dueDate == null) return false;
      if (task.isCompleted) return false;

      final dueDate = _dateOnly(task.dueDate!);
      return dueDate.isBefore(today);
    }).length;

    final dueTodayTasks = activeTasks.where((task) {
      if (task.dueDate == null) return false;
      if (task.isCompleted) return false;

      final dueDate = _dateOnly(task.dueDate!);
      return dueDate == today;
    }).length;

    final uniqueActiveDays =
        recentHistory.map((history) => _dateOnly(history.date)).toSet().length;

    final currentStreak = streak?.currentStreak ?? 0;
    final longestStreak = streak?.longestStreak ?? 0;

    final activityScore = _calculateActivityScore(
      completedRecentTasks: completedRecentTasks,
      totalRecentXP: totalRecentXP,
    );

    final consistencyScore = _calculateConsistencyScore(
      uniqueActiveDays: uniqueActiveDays,
    );

    final streakScore = _calculateStreakScore(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
    );

    final taskHealthScore = _calculateTaskHealthScore(
      activePendingTasks: activePendingTasks,
      overdueTasks: overdueTasks,
      dueTodayTasks: dueTodayTasks,
    );

    final lifetimeBonus = _calculateLifetimeBonus(
      completedLifetimeTasks: completedLifetimeTasks,
    );

    final rawScore = activityScore +
        consistencyScore +
        streakScore +
        taskHealthScore +
        lifetimeBonus;

    final penalty = _calculatePenalty(
      overdueTasks: overdueTasks,
      activePendingTasks: activePendingTasks,
    );

    final finalScore = rawScore - penalty;

    return finalScore.round().clamp(0, 100);
  }

  static double _calculateActivityScore({
    required int completedRecentTasks,
    required int totalRecentXP,
  }) {
    final double taskPart =
        ((completedRecentTasks / 14).clamp(0, 1) * 24).toDouble();

    final double xpPart = ((totalRecentXP / 300).clamp(0, 1) * 16).toDouble();

    return taskPart + xpPart;
  }

  static double _calculateConsistencyScore({
    required int uniqueActiveDays,
  }) {
    return ((uniqueActiveDays / 7).clamp(0, 1) * 22).toDouble();
  }

  static double _calculateStreakScore({
    required int currentStreak,
    required int longestStreak,
  }) {
    final double currentStreakScore =
        ((currentStreak / 7).clamp(0, 1) * 14).toDouble();

    final double longestStreakScore =
        ((longestStreak / 21).clamp(0, 1) * 6).toDouble();

    return currentStreakScore + longestStreakScore;
  }

  static double _calculateTaskHealthScore({
    required int activePendingTasks,
    required int overdueTasks,
    required int dueTodayTasks,
  }) {
    if (activePendingTasks == 0) {
      return 10.0;
    }

    final double overdueRatio = overdueTasks / activePendingTasks;
    final double dueTodayRatio = dueTodayTasks / activePendingTasks;

    final double overdueHealth =
        ((1 - overdueRatio).clamp(0, 1) * 12).toDouble();

    final double todayFocus =
        ((1 - (dueTodayRatio * 0.4)).clamp(0, 1) * 6).toDouble();

    return overdueHealth + todayFocus;
  }

  static double _calculateLifetimeBonus({
    required int completedLifetimeTasks,
  }) {
    return ((completedLifetimeTasks / 50).clamp(0, 1) * 8).toDouble();
  }

  static double _calculatePenalty({
    required int overdueTasks,
    required int activePendingTasks,
  }) {
    double penalty = 0.0;

    penalty += overdueTasks * 4;

    if (activePendingTasks > 20) {
      penalty += 6;
    }

    if (activePendingTasks > 35) {
      penalty += 8;
    }

    return penalty.clamp(0, 25).toDouble();
  }

  static String getProductivityLevel(int score) {
    if (score == 0) return "Inactive";
    if (score < 20) return "Starting";
    if (score < 40) return "Building";
    if (score < 60) return "Focused";
    if (score < 75) return "Productive";
    if (score < 90) return "Highly Productive";
    return "Elite Performer";
  }

  static String getProductivityMessage(int score) {
    if (score == 0) {
      return "Complete your first task to start building momentum.";
    }

    if (score < 20) {
      return "Start small. Complete one task today.";
    }

    if (score < 40) {
      return "You are building consistency. Keep going.";
    }

    if (score < 60) {
      return "Good focus. Try completing tasks on more days.";
    }

    if (score < 75) {
      return "Strong productivity. Maintain your rhythm.";
    }

    if (score < 90) {
      return "Excellent consistency. You are performing well.";
    }

    return "Elite productivity. Your consistency is outstanding.";
  }

  static DateTime _dateOnly(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    );
  }
}
