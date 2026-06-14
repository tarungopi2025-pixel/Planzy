import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/task.dart';
import 'models/settings.dart';
import 'models/streak.dart';
import 'models/achievement.dart';
import 'models/xp_history.dart';
import 'models/daily_challenge.dart';

import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  // ================= MODELS =================
  Hive.registerAdapter(TaskAdapter());
  Hive.registerAdapter(TaskPriorityAdapter());

  Hive.registerAdapter(SettingsAdapter());
  Hive.registerAdapter(StreakAdapter());

  Hive.registerAdapter(AchievementAdapter());
  Hive.registerAdapter(AchievementCategoryAdapter());

  Hive.registerAdapter(XPHistoryAdapter());
  Hive.registerAdapter(DailyChallengeAdapter());

  // ================= BOXES =================
  await Hive.openBox<Task>('tasks');
  await Hive.openBox<Settings>('settings');
  await Hive.openBox<Streak>('streak');
  await Hive.openBox<Achievement>('achievements');
  await Hive.openBox<XPHistory>('xp_history');
  await Hive.openBox<DailyChallenge>('daily_challenges');

  // ================= SAFE INIT =================
  _initSafeDefaults();

  runApp(const PlanzyApp());
}

/// Ensures app never crashes due to empty Hive boxes
void _initSafeDefaults() {
  final settingsBox = Hive.box<Settings>('settings');
  final streakBox = Hive.box<Streak>('streak');

  if (settingsBox.isEmpty) {
    settingsBox.add(Settings(
      totalXP: 0,
      currentLevel: 1,
    ));
  }

  if (streakBox.isEmpty) {
    streakBox.add(Streak(
      currentStreak: 0,
      longestStreak: 0,
      lastActiveDate: DateTime.now(),
    ));
  }
}

class PlanzyApp extends StatelessWidget {
  const PlanzyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PLANZY',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
    );
  }
}
