import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/task.dart';
import '../models/settings.dart';
import '../models/streak.dart';
import '../models/user_profile.dart';

import '../services/xp_service.dart';
import '../services/achievement_service.dart';
import '../services/productivity_service.dart';
import '../services/streak_service.dart';
import '../services/audio_service.dart';

import '../widgets/task_card.dart';

import 'add_task_screen.dart';
import 'edit_task_screen.dart';
import 'dashboard_screen.dart';
import 'focus_timer_screen.dart';
import '../screens/achivement_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Box<Task> taskBox;
  late Box<Settings> settingsBox;
  late Box<Streak> streakBox;
  late Box<UserProfile> userBox;

  DateTime _lastCheck = DateTime.now();

  OverlayEntry? _xpPopup;
  OverlayEntry? _levelPopup;

  final List<String> motivationQuotes = const [
    "Small steps every day create big results.",
    "Discipline beats motivation when motivation fades.",
    "Your future self is built by what you do today.",
    "Consistency is the quiet power behind success.",
    "One focused task can change the direction of your day.",
    "Progress does not need to be loud. It just needs to continue.",
    "Win today first. Tomorrow will respect it.",
    "You do not need more time. You need more focus.",
    "A productive day starts with one completed task.",
    "Show up today, even if it is not perfect.",
    "Every task completed is proof that you are improving.",
    "Great routines are built from simple actions repeated daily.",
    "Focus on progress, not pressure.",
    "The best way to build momentum is to begin.",
    "Your goals need action more than excuses.",
    "A calm mind and a clear task can do a lot.",
    "Today’s effort becomes tomorrow’s confidence.",
    "Do the next right thing. Then repeat.",
    "Success is built in ordinary days like this.",
    "Stay consistent. Results will catch up.",
    "You are one task away from momentum.",
    "Make today count in a simple, focused way.",
    "Energy follows action.",
    "Start small. Finish strong.",
    "Your consistency is your advantage.",
    "A clear plan makes hard work easier.",
    "Every completed task is a vote for who you are becoming.",
    "Build the habit. The results will follow.",
    "Do not wait for the perfect mood. Begin anyway.",
    "Focus turns effort into progress.",
  ];

  @override
  void initState() {
    super.initState();

    taskBox = Hive.box<Task>('tasks');
    settingsBox = Hive.box<Settings>('settings');
    streakBox = Hive.box<Streak>('streak');
    userBox = Hive.box<UserProfile>('user_profile');

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await StreakService.refreshStreakStatus();
      _checkTaskAchievements();
      _safeRefresh();
    });
  }

  @override
  void dispose() {
    _xpPopup?.remove();
    _levelPopup?.remove();
    _xpPopup = null;
    _levelPopup = null;
    super.dispose();
  }

  String get userName {
    if (userBox.isEmpty) return "there";

    final profile = userBox.getAt(0);
    final name = profile?.name.trim() ?? "";

    if (name.isEmpty) return "there";

    return name;
  }

  String get greetingText {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return "Good Morning";
    } else if (hour >= 12 && hour < 17) {
      return "Good Afternoon";
    } else {
      return "Good Evening";
    }
  }

  String get dailyQuote {
    final now = DateTime.now();
    final dayKey = now.year * 10000 + now.month * 100 + now.day;
    final index = dayKey % motivationQuotes.length;

    return motivationQuotes[index];
  }

  void _safeRefresh() {
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _openAddTaskScreen() async {
    await AudioService.playOpen();
    HapticFeedback.selectionClick();

    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 420),
        reverseTransitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (context, animation, secondaryAnimation) {
          return const AddTaskScreen();
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );

          return FadeTransition(
            opacity: curvedAnimation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.06),
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: child,
            ),
          );
        },
      ),
    );

    if (result is Task) {
      await taskBox.add(result);
      await AudioService.playAddTask();
      _checkTaskAchievements();
      _safeRefresh();
    }
  }

  Future<void> _openEditTaskScreen(Task task) async {
    await AudioService.playOpen();
    HapticFeedback.selectionClick();

    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 420),
        reverseTransitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (context, animation, secondaryAnimation) {
          return EditTaskScreen(task: task);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );

          return FadeTransition(
            opacity: curvedAnimation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.06),
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: child,
            ),
          );
        },
      ),
    );

    if (result == true) {
      _checkTaskAchievements();
      _safeRefresh();
    }
  }

  void _showXpPopup(int xp) {
    if (!mounted) return;

    _xpPopup?.remove();

    _xpPopup = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: 120,
          left: MediaQuery.of(context).size.width / 2 - 62,
          child: Material(
            color: Colors.transparent,
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 700),
              tween: Tween<double>(begin: 0, end: 1),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: 1 - value,
                  child: Transform.translate(
                    offset: Offset(0, -26 * value),
                    child: Transform.scale(
                      scale: 1 + (0.08 * value),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2EE6A6),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.18),
                              blurRadius: 14,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Text(
                          "+$xp XP",
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_xpPopup!);

    Future.delayed(const Duration(milliseconds: 760), () {
      _xpPopup?.remove();
      _xpPopup = null;
    });
  }

  void _showLevelPopup(int level) {
    if (!mounted) return;

    _levelPopup?.remove();

    _levelPopup = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: 190,
          left: MediaQuery.of(context).size.width * 0.12,
          right: MediaQuery.of(context).size.width * 0.12,
          child: Material(
            color: Colors.transparent,
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 700),
              tween: Tween<double>(begin: 0, end: 1),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value.clamp(0, 1),
                  child: Transform.scale(
                    scale: 0.86 + (value * 0.14),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF102A4A),
                            Color(0xFF163B66),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFF2EE6A6).withOpacity(0.65),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.22),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2EE6A6).withOpacity(0.15),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF2EE6A6).withOpacity(0.6),
                              ),
                            ),
                            child: const Icon(
                              Icons.emoji_events,
                              color: Color(0xFF2EE6A6),
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            "Level Up",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "You reached Level $level",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_levelPopup!);

    Future.delayed(const Duration(milliseconds: 1250), () {
      _levelPopup?.remove();
      _levelPopup = null;
    });
  }

  void _checkTaskAchievements() {
    final now = DateTime.now();

    if (now.difference(_lastCheck).inMilliseconds < 300) return;

    _lastCheck = now;

    final tasks = taskBox.values.toList();

    AchievementService.unlockTaskAchievements(
      tasks.length,
      tasks.where((task) => task.isCompleted).length,
    );
  }

  Future<void> completeTask(Task task) async {
    final key = task.key;

    if (key == null) return;

    final storedTask = taskBox.get(key);

    if (storedTask == null) return;

    HapticFeedback.mediumImpact();

    storedTask.isCompleted = true;
    await storedTask.save();

    final result = await XPService.addXP(storedTask);

    await taskBox.delete(key);

    _showXpPopup(result.xpChange);

    final settings = settingsBox.isNotEmpty ? settingsBox.getAt(0) : null;

    if (settings != null && result.leveledUp) {
      _showLevelPopup(settings.currentLevel);
    }

    _checkTaskAchievements();

    _safeRefresh();
  }

  Future<void> deleteTask(Task task) async {
    final key = task.key;

    if (key == null) return;

    HapticFeedback.mediumImpact();
    await AudioService.playDelete();

    await taskBox.delete(key);

    _checkTaskAchievements();

    _safeRefresh();
  }

  @override
  Widget build(BuildContext context) {
    final settings =
        settingsBox.isNotEmpty ? settingsBox.getAt(0)! : Settings();

    final streak = streakBox.isNotEmpty
        ? streakBox.getAt(0)!
        : Streak(
            currentStreak: 0,
            longestStreak: 0,
            lastActiveDate: DateTime.now(),
          );

    final score = ProductivityService.calculateProductivityScore();
    final level = ProductivityService.getProductivityLevel(score);

    final progressPercent = XPService.progressToNextLevel(settings.totalXP);
    final currentLevelXP = XPService.xpIntoCurrentLevel(settings.totalXP);
    final neededLevelXP = XPService.xpNeededForCurrentLevel(settings.totalXP);

    return Scaffold(
      backgroundColor: const Color(0xFF08152E),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddTaskScreen,
        backgroundColor: const Color(0xFF2EE6A6),
        foregroundColor: Colors.black,
        elevation: 6,
        icon: const Icon(Icons.add_task),
        label: const Text(
          "Add Task",
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _premiumHeader(),
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: userBox.listenable(),
                builder: (context, Box<UserProfile> box, _) {
                  return Column(
                    children: [
                      _welcomeSection(),
                      _statsSection(
                        settings: settings,
                        streak: streak,
                        score: score,
                        level: level,
                        progressPercent: progressPercent,
                        currentLevelXP: currentLevelXP,
                        neededLevelXP: neededLevelXP,
                      ),
                      Expanded(
                        child: _taskList(),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _premiumHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF2EE6A6),
                  Color(0xFF62D6FF),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(17),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.16),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.black,
              size: 23,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "PLANZY",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.7,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  "Productivity redefined",
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          _headerButton(
            icon: Icons.insights,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DashboardScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 10),
          _headerButton(
            icon: Icons.timer,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const FocusTimerScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 10),
          _headerButton(
            icon: Icons.emoji_events,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AchievementScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _welcomeSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 550),
        tween: Tween<double>(begin: 0, end: 1),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 12 * (1 - value)),
              child: child,
            ),
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF102A4A),
                Color(0xFF123156),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withOpacity(0.07),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.14),
                blurRadius: 18,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "$greetingText, $userName",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                dailyQuote,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.58),
                  fontSize: 12.5,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        AudioService.playClick();
        onTap();
      },
      child: Container(
        width: 43,
        height: 43,
        decoration: BoxDecoration(
          color: const Color(0xFF102A4A),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: Colors.white.withOpacity(0.07),
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 21,
        ),
      ),
    );
  }

  Widget _statsSection({
    required Settings settings,
    required Streak streak,
    required int score,
    required String level,
    required double progressPercent,
    required int currentLevelXP,
    required int neededLevelXP,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF102A4A),
                  Color(0xFF163B66),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withOpacity(0.07),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.16),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "Current Progress",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2EE6A6).withOpacity(0.14),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF2EE6A6).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        "Level ${settings.currentLevel}",
                        style: const TextStyle(
                          color: Color(0xFF2EE6A6),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    minHeight: 9,
                    value: progressPercent,
                    backgroundColor: Colors.white.withOpacity(0.08),
                    valueColor: const AlwaysStoppedAnimation(
                      Color(0xFF2EE6A6),
                    ),
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  "$currentLevelXP/$neededLevelXP XP to next level",
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _miniCard(
                  "Streak",
                  "${streak.currentStreak} days",
                  Icons.local_fire_department,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _miniCard(
                  "Score",
                  "$score",
                  Icons.insights,
                  Colors.blueAccent,
                  subtitle: level,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _taskList() {
    return ValueListenableBuilder(
      valueListenable: taskBox.listenable(),
      builder: (context, Box<Task> box, _) {
        final tasks = box.values.toList().reversed.toList();

        if (tasks.isEmpty) {
          return _emptyState();
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 96),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];

            return TaskCard(
              key: ValueKey(task.key),
              task: task,
              onTap: () => _openEditTaskScreen(task),
              onComplete: () => completeTask(task),
              onDelete: () => deleteTask(task),
            );
          },
        );
      },
    );
  }

  Widget _emptyState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 18, 28, 90),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 700),
                    tween: Tween<double>(begin: 0.92, end: 1),
                    curve: Curves.easeOutBack,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Container(
                          width: 74,
                          height: 74,
                          decoration: BoxDecoration(
                            color: const Color(0xFF102A4A),
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.08),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.16),
                                blurRadius: 14,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.add_task,
                            color: Color(0xFF2EE6A6),
                            size: 34,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    "No tasks yet",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    "Create your first task and start earning XP.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 13,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 18),
                  GestureDetector(
                    onTap: _openAddTaskScreen,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2EE6A6),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.16),
                            blurRadius: 14,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Text(
                        "Create Task",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _miniCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF102A4A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.07),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.13),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle == null ? value : "$value • $subtitle",
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
