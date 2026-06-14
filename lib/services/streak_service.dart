import 'package:hive/hive.dart';

import '../models/streak.dart';
import 'audio_service.dart';

class StreakService {
  static Box<Streak> get _box => Hive.box<Streak>('streak');

  static Streak get _streak {
    if (_box.isEmpty) {
      final s = Streak(
        currentStreak: 0,
        longestStreak: 0,
        lastActiveDate: DateTime.now(),
      );
      _box.add(s);
      return s;
    }
    return _box.getAt(0)!;
  }

  static Future<void> updateStreak() async {
    final streak = _streak;

    final now = DateTime.now();
    final last = streak.lastActiveDate;

    // Normalize dates (important fix)
    final today = DateTime(now.year, now.month, now.day);
    final lastDay = DateTime(last.year, last.month, last.day);

    final difference = today.difference(lastDay).inDays;

    // Same day → do nothing
    if (difference == 0) return;

    // Next day → increment streak
    if (difference == 1) {
      streak.currentStreak += 1;

      await AudioService.playStreak();
    }
    // Missed days → reset streak
    else {
      streak.currentStreak = 1;
    }

    // Update longest streak
    if (streak.currentStreak > streak.longestStreak) {
      streak.longestStreak = streak.currentStreak;
    }

    streak.lastActiveDate = now;

    await streak.save();
  }

  static int getCurrentStreak() {
    return _streak.currentStreak;
  }

  static int getLongestStreak() {
    return _streak.longestStreak;
  }
}
