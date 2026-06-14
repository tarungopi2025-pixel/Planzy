import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/task.dart';
import '../models/settings.dart';
import '../models/streak.dart';

import '../services/xp_service.dart';
import '../services/achievement_service.dart';
import '../services/productivity_service.dart';

import '../widgets/task_card.dart';

import 'add_task_screen.dart';
import 'dashboard_screen.dart';
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

  DateTime _lastCheck = DateTime.now();
  OverlayEntry? _xpPopup;
  OverlayEntry? _levelPopup;

  @override
  void initState() {
    super.initState();
    taskBox = Hive.box<Task>('tasks');
    settingsBox = Hive.box<Settings>('settings');
    streakBox = Hive.box<Streak>('streak');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkTaskAchievements();
    });
  }

  // ================= XP POPUP =================
  void _showXpPopup(int xp) {
    _xpPopup?.remove();

    _xpPopup = OverlayEntry(
      builder: (context) => Positioned(
        top: 120,
        left: MediaQuery.of(context).size.width / 2 - 60,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder(
            duration: const Duration(milliseconds: 600),
            tween: Tween<double>(begin: 0, end: 1),
            builder: (context, double value, child) {
              return Opacity(
                opacity: 1 - value,
                child: Transform.translate(
                  offset: Offset(0, -20 * value),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2EE6A6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "+$xp XP",
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_xpPopup!);

    Future.delayed(const Duration(milliseconds: 700), () {
      _xpPopup?.remove();
      _xpPopup = null;
    });
  }

  // ================= LEVEL POPUP =================
  void _showLevelPopup(int level) {
    _levelPopup?.remove();

    _levelPopup = OverlayEntry(
      builder: (context) => Positioned(
        top: 200,
        left: MediaQuery.of(context).size.width * 0.15,
        right: MediaQuery.of(context).size.width * 0.15,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder(
            duration: const Duration(milliseconds: 900),
            tween: Tween<double>(begin: 0, end: 1),
            builder: (context, double value, child) {
              return Opacity(
                opacity: 1 - value,
                child: Transform.scale(
                  scale: 0.95 + (value * 0.05),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF102A4A),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF2EE6A6)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.emoji_events,
                          color: Color(0xFF2EE6A6),
                          size: 40,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Level Up",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "You reached Level $level",
                          style: const TextStyle(
                            color: Colors.white70,
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
      ),
    );

    Overlay.of(context).insert(_levelPopup!);

    Future.delayed(const Duration(milliseconds: 1200), () {
      _levelPopup?.remove();
      _levelPopup = null;
    });
  }

  // ================= ACHIEVEMENTS =================
  void _checkTaskAchievements() {
    final now = DateTime.now();

    if (now.difference(_lastCheck).inMilliseconds < 300) return;

    _lastCheck = now;

    final tasks = taskBox.values.toList();

    AchievementService.unlockTaskAchievements(
      tasks.length,
      tasks.where((t) => t.isCompleted).length,
    );
  }

  // ================= TASK TOGGLE =================
  Future<void> toggleTask(int index, Task task) async {
    final wasCompleted = task.isCompleted;

    task.isCompleted = !task.isCompleted;
    await task.save();

    if (task.isCompleted && !wasCompleted) {
      final result = await XPService.addXP(task);

      _showXpPopup(result.xpChange);

      if (result.leveledUp) {
        final settings = settingsBox.getAt(0);
        if (settings != null) {
          _showLevelPopup(settings.currentLevel);
        }
      }
    } else if (!task.isCompleted && wasCompleted) {
      await XPService.removeXP(task);
    }

    _checkTaskAchievements();

    if (mounted) setState(() {});
  }

  Future<void> deleteTask(int index) async {
    await taskBox.deleteAt(index);
    _checkTaskAchievements();

    if (mounted) setState(() {});
  }

  void _onDelete(Task task) {
    HapticFeedback.mediumImpact();
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

    final progress = settings.totalXP % 100;
    final progressPercent = progress / 100;

    return Scaffold(
      backgroundColor: const Color(0xFF08152E),
      appBar: AppBar(
        title: const Text('PLANZY'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.insights),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DashboardScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.emoji_events),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AchievementScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddTaskScreen(),
                ),
              ).then((_) {
                _checkTaskAchievements();
                if (mounted) setState(() {});
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF102A4A),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Level ${settings.currentLevel}",
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: progressPercent,
                        backgroundColor: Colors.white12,
                        valueColor: const AlwaysStoppedAnimation(
                          Color(0xFF2EE6A6),
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
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _miniCard(
                        "Productivity Score",
                        "$score ($level)",
                        Colors.blueAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: taskBox.listenable(),
              builder: (context, Box<Task> box, _) {
                final tasks = box.values.toList();

                if (tasks.isEmpty) {
                  return const Center(
                    child: Text(
                      'No tasks yet',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];

                    return Dismissible(
                      key: Key(task.key.toString()),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFFFF4B2B),
                              Color(0xFFFF416C),
                            ],
                          ),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: TaskCard(
                          task: task,
                          onToggle: () => toggleTask(index, task),
                        ),
                      ),
                      onDismissed: (_) async {
                        _onDelete(task);
                        await deleteTask(index);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF102A4A),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
