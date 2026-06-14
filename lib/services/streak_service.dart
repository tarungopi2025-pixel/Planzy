import 'package:hive/hive.dart';

import '../models/streak.dart';
import 'audio_service.dart';

class StreakService {
  static Box<Streak> get _box => Hive.box<Streak>('streak');

  static Streak get _streak {
    if (_box.isEmpty) {
      final streak = Streak(
        currentStreak: 0,
        longestStreak: 0,
        lastActiveDate: DateTime(2000, 1, 1),
      );

      _box.add(streak);
      return streak;
    }

    return _box.getAt(0)!;
  }

  static DateTime _dateOnly(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    );
  }

  /// Call this whenever the user COMPLETES a task.
  ///
  /// Rule:
  /// One completed task per day keeps the streak alive.
  /// Creating a task alone does not count.
  static Future<void> updateStreak() async {
    final streak = _streak;

    final now = DateTime.now();
    final today = _dateOnly(now);
    final lastActiveDay = _dateOnly(streak.lastActiveDate);

    final difference = today.difference(lastActiveDay).inDays;

    // Safety: if device date/time changed into future or corrupted.
    if (difference < 0) {
      streak.currentStreak = 1;
      streak.lastActiveDate = now;

      if (streak.currentStreak > streak.longestStreak) {
        streak.longestStreak = streak.currentStreak;
      }

      await streak.save();
      return;
    }

    // First valid completion ever.
    if (streak.currentStreak == 0) {
      streak.currentStreak = 1;
      streak.lastActiveDate = now;

      if (streak.currentStreak > streak.longestStreak) {
        streak.longestStreak = streak.currentStreak;
      }

      await streak.save();
      await AudioService.playAchievement();
      return;
    }

    // Same day completion:
    // Do not increase streak multiple times in one day.
    if (difference == 0) {
      return;
    }

    // Next day completion:
    // User maintained consistency.
    if (difference == 1) {
      streak.currentStreak += 1;
      streak.lastActiveDate = now;

      if (streak.currentStreak > streak.longestStreak) {
        streak.longestStreak = streak.currentStreak;
      }

      await streak.save();
      await AudioService.playAchievement();
      return;
    }

    // Missed one or more full days:
    // Old streak is broken. New streak starts today.
    if (difference > 1) {
      streak.currentStreak = 1;
      streak.lastActiveDate = now;

      if (streak.currentStreak > streak.longestStreak) {
        streak.longestStreak = streak.currentStreak;
      }

      await streak.save();
      return;
    }
  }

  /// Call this when HomeScreen opens or refreshes.
  ///
  /// This makes the streak become 0 automatically if the user missed a day,
  /// even before they complete another task.
  static Future<void> refreshStreakStatus() async {
    final streak = _streak;

    if (streak.currentStreak == 0) return;

    final now = DateTime.now();
    final today = _dateOnly(now);
    final lastActiveDay = _dateOnly(streak.lastActiveDate);

    final difference = today.difference(lastActiveDay).inDays;

    // Same day or next day: streak is still alive.
    if (difference == 0 || difference == 1) return;

    // Missed one full day or more: streak breaks.
    if (difference > 1) {
      streak.currentStreak = 0;
      await streak.save();
    }

    // Safety for wrong/future device date.
    if (difference < 0) {
      streak.currentStreak = 0;
      streak.lastActiveDate = now;
      await streak.save();
    }
  }

  static int getCurrentStreak() {
    return _streak.currentStreak;
  }

  static int getLongestStreak() {
    return _streak.longestStreak;
  }

  static DateTime getLastActiveDate() {
    return _streak.lastActiveDate;
  }

  static Future<void> resetStreak() async {
    final streak = _streak;

    streak.currentStreak = 0;
    streak.lastActiveDate = DateTime(2000, 1, 1);

    await streak.save();
  }
}
