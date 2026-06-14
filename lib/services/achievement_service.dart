import 'package:hive/hive.dart';

import '../models/achievement.dart';
import '../models/settings.dart';
import 'notification_service.dart';

class AchievementService {
  static Box<Achievement>? _box;
  static Box<Settings>? _settingsBox;

  /// Must be called once in splash/home init
  static Future<void> init() async {
    _box = Hive.box<Achievement>('achievements');
    _settingsBox = Hive.box<Settings>('settings');

    _ensureBaseAchievements();
  }

  /// Safe entry point used everywhere
  static Future<void> checkAndUnlock() async {
    await init();

    final settings = _getSettings();

    _unlockXP(settings.totalXP);
    _unlockLevel(settings.currentLevel);
  }

  // ---------------- XP ACHIEVEMENTS ----------------

  static void _unlockXP(int xp) {
    _unlock(
      id: 'xp_1',
      title: 'First Step',
      description: 'Earn 1 XP',
      category: AchievementCategory.xp,
      condition: xp >= 1,
    );

    _unlock(
      id: 'xp_100',
      title: 'Getting Started',
      description: 'Reach 100 XP',
      category: AchievementCategory.xp,
      condition: xp >= 100,
    );

    _unlock(
      id: 'xp_250',
      title: 'Focused Mind',
      description: 'Reach 250 XP',
      category: AchievementCategory.xp,
      condition: xp >= 250,
    );

    _unlock(
      id: 'xp_500',
      title: 'Hard Worker',
      description: 'Reach 500 XP',
      category: AchievementCategory.xp,
      condition: xp >= 500,
    );

    _unlock(
      id: 'xp_1000',
      title: 'Elite Grinder',
      description: 'Reach 1000 XP',
      category: AchievementCategory.xp,
      condition: xp >= 1000,
    );
  }

  // ---------------- LEVEL ACHIEVEMENTS ----------------

  static void _unlockLevel(int level) {
    _unlock(
      id: 'lvl_1',
      title: 'Beginner',
      description: 'Reach Level 1',
      category: AchievementCategory.task,
      condition: level >= 1,
    );

    _unlock(
      id: 'lvl_5',
      title: 'Task Builder',
      description: 'Reach Level 5',
      category: AchievementCategory.task,
      condition: level >= 5,
    );

    _unlock(
      id: 'lvl_10',
      title: 'Task Master',
      description: 'Reach Level 10',
      category: AchievementCategory.task,
      condition: level >= 10,
    );

    _unlock(
      id: 'lvl_15',
      title: 'Task Legend',
      description: 'Reach Level 15',
      category: AchievementCategory.task,
      condition: level >= 15,
    );
  }

  // ---------------- TASK ACHIEVEMENTS ----------------

  static void unlockTaskAchievements(int totalTasks, int completedTasks) {
    init();

    _unlock(
      id: 'task_1',
      title: 'First Task',
      description: 'Create your first task',
      category: AchievementCategory.task,
      condition: totalTasks >= 1,
    );

    _unlock(
      id: 'task_10',
      title: 'Getting Organized',
      description: 'Create 10 tasks',
      category: AchievementCategory.task,
      condition: totalTasks >= 10,
    );

    _unlock(
      id: 'task_25',
      title: 'Task Builder',
      description: 'Create 25 tasks',
      category: AchievementCategory.task,
      condition: totalTasks >= 25,
    );

    _unlock(
      id: 'task_50',
      title: 'Task Mastermind',
      description: 'Create 50 tasks',
      category: AchievementCategory.task,
      condition: totalTasks >= 50,
    );

    _unlock(
      id: 'complete_1',
      title: 'First Completion',
      description: 'Complete 1 task',
      category: AchievementCategory.task,
      condition: completedTasks >= 1,
    );

    _unlock(
      id: 'complete_10',
      title: 'Consistency Starter',
      description: 'Complete 10 tasks',
      category: AchievementCategory.task,
      condition: completedTasks >= 10,
    );

    _unlock(
      id: 'complete_25',
      title: 'Productive Mind',
      description: 'Complete 25 tasks',
      category: AchievementCategory.task,
      condition: completedTasks >= 25,
    );

    _unlock(
      id: 'complete_50',
      title: 'Execution Expert',
      description: 'Complete 50 tasks',
      category: AchievementCategory.task,
      condition: completedTasks >= 50,
    );
  }

  // ---------------- CORE LOGIC ----------------

  static Future<void> _unlock({
    required String id,
    required String title,
    required String description,
    required AchievementCategory category,
    required bool condition,
  }) async {
    if (!condition) return;

    await init();

    final box = _box!;
    final settings = _settingsBox!;

    final existing = box.values.where((e) => e.id == id);

    if (existing.isNotEmpty) {
      final ach = existing.first;

      if (ach.unlocked) return;

      ach.unlocked = true;
      ach.unlockedAt = DateTime.now();
      await ach.save();

      _notify(title, description);
      return;
    }

    final achievement = Achievement(
      id: id,
      title: title,
      description: description,
      category: category,
      unlocked: true,
      unlockedAt: DateTime.now(),
    );

    await box.add(achievement);

    _notify(title, description);
  }

  // ---------------- NOTIFICATIONS ----------------

  static void _notify(String title, String description) {
    NotificationService.showAchievement(
      title: title,
      description: description,
    );
  }

  // ---------------- BASE DATA ----------------

  static void _ensureBaseAchievements() {
    if (_box == null || _box!.isNotEmpty) return;

    final box = _box!;

    final base = [
      _create('xp_1', 'First Step', 'Earn 1 XP', AchievementCategory.xp),
      _create(
          'xp_100', 'Getting Started', 'Reach 100 XP', AchievementCategory.xp),
      _create('xp_250', 'Focused Mind', 'Reach 250 XP', AchievementCategory.xp),
      _create('xp_500', 'Hard Worker', 'Reach 500 XP', AchievementCategory.xp),
      _create(
          'xp_1000', 'Elite Grinder', 'Reach 1000 XP', AchievementCategory.xp),
      _create('task_1', 'First Task', 'Create your first task',
          AchievementCategory.task),
      _create('task_10', 'Getting Organized', 'Create 10 tasks',
          AchievementCategory.task),
      _create('task_25', 'Task Builder', 'Create 25 tasks',
          AchievementCategory.task),
      _create('task_50', 'Task Mastermind', 'Create 50 tasks',
          AchievementCategory.task),
      _create('complete_1', 'First Completion', 'Complete 1 task',
          AchievementCategory.task),
      _create('complete_10', 'Consistency Starter', 'Complete 10 tasks',
          AchievementCategory.task),
      _create('complete_25', 'Productive Mind', 'Complete 25 tasks',
          AchievementCategory.task),
      _create('complete_50', 'Execution Expert', 'Complete 50 tasks',
          AchievementCategory.task),
    ];

    for (final a in base) {
      box.add(a);
    }
  }

  static Achievement _create(
    String id,
    String title,
    String description,
    AchievementCategory category,
  ) {
    return Achievement(
      id: id,
      title: title,
      description: description,
      category: category,
      unlocked: false,
      unlockedAt: null,
    );
  }

  static Settings _getSettings() {
    return _settingsBox!.getAt(0)!;
  }
}
