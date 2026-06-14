import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/task.dart';
import '../services/xp_service.dart';
import '../services/achievement_service.dart';
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

  DateTime _lastCheck = DateTime.now();

  @override
  void initState() {
    super.initState();
    taskBox = Hive.box<Task>('tasks');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkTaskAchievements();
    });
  }

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

  Future<void> toggleTask(int index, Task task) async {
    final wasCompleted = task.isCompleted;

    task.isCompleted = !task.isCompleted;
    await task.save();

    if (task.isCompleted && !wasCompleted) {
      await XPService.addXP(task);
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
    HapticFeedback.mediumImpact(); // 🔥 PREMIUM FEEL
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PLANZY'),
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
      body: ValueListenableBuilder(
        valueListenable: taskBox.listenable(),
        builder: (context, Box<Task> box, _) {
          final tasks = box.values.toList();

          if (tasks.isEmpty) {
            return const Center(
              child: Text('No tasks yet.'),
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
                resizeDuration: const Duration(milliseconds: 200),
                movementDuration: const Duration(milliseconds: 250),
                background: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFF4B2B),
                        Color(0xFFFF416C),
                      ],
                    ),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(
                        Icons.delete_outline,
                        color: Colors.white,
                        size: 28,
                      ),
                      SizedBox(width: 10),
                      Text(
                        "Delete",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: TaskCard(
                    task: task,
                    onToggle: () => toggleTask(index, task),
                  ),
                ),
                onDismissed: (_) async {
                  _onDelete(task); // haptic first
                  await deleteTask(index);
                },
              );
            },
          );
        },
      ),
    );
  }
}
