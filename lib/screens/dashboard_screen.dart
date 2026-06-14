import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/task.dart';
import '../models/settings.dart';
import '../models/streak.dart';
import '../models/xp_history.dart';

import '../services/productivity_service.dart';
import '../services/xp_service.dart';
import '../services/audio_service.dart';

import 'progress_report_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late Box<Task> taskBox;
  late Box<Settings> settingsBox;
  late Box<Streak> streakBox;
  late Box<XPHistory> historyBox;

  late AnimationController animationController;
  late Animation<double> fadeAnimation;
  late Animation<Offset> slideAnimation;

  @override
  void initState() {
    super.initState();

    taskBox = Hive.box<Task>('tasks');
    settingsBox = Hive.box<Settings>('settings');
    streakBox = Hive.box<Streak>('streak');
    historyBox = Hive.box<XPHistory>('xp_history');

    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    fadeAnimation = CurvedAnimation(
      parent: animationController,
      curve: Curves.easeOut,
    );

    slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    animationController.forward();
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    );
  }

  int _completedToday() {
    final today = _dateOnly(DateTime.now());

    return historyBox.values.where((history) {
      final date = _dateOnly(history.date);
      return date == today && history.tasksCompleted > 0;
    }).fold<int>(
      0,
      (sum, history) => sum + history.tasksCompleted,
    );
  }

  int _xpToday() {
    final today = _dateOnly(DateTime.now());

    return historyBox.values.where((history) {
      final date = _dateOnly(history.date);
      return date == today && history.xpEarned > 0;
    }).fold<int>(
      0,
      (sum, history) => sum + history.xpEarned,
    );
  }

  int _totalCompletedTasks() {
    return historyBox.values.where((history) {
      return history.tasksCompleted > 0;
    }).fold<int>(
      0,
      (sum, history) => sum + history.tasksCompleted,
    );
  }

  int _completedThisWeek() {
    final today = _dateOnly(DateTime.now());
    final weekStart = today.subtract(const Duration(days: 6));

    return historyBox.values.where((history) {
      final date = _dateOnly(history.date);
      return !date.isBefore(weekStart) &&
          !date.isAfter(today) &&
          history.tasksCompleted > 0;
    }).fold<int>(
      0,
      (sum, history) => sum + history.tasksCompleted,
    );
  }

  int _xpThisWeek() {
    final today = _dateOnly(DateTime.now());
    final weekStart = today.subtract(const Duration(days: 6));

    return historyBox.values.where((history) {
      final date = _dateOnly(history.date);
      return !date.isBefore(weekStart) &&
          !date.isAfter(today) &&
          history.xpEarned > 0;
    }).fold<int>(
      0,
      (sum, history) => sum + history.xpEarned,
    );
  }

  int _activeDaysThisWeek() {
    final today = _dateOnly(DateTime.now());
    final weekStart = today.subtract(const Duration(days: 6));

    return historyBox.values
        .where((history) {
          final date = _dateOnly(history.date);
          return !date.isBefore(weekStart) &&
              !date.isAfter(today) &&
              history.xpEarned > 0;
        })
        .map((history) => _dateOnly(history.date))
        .toSet()
        .length;
  }

  int _pendingTasks() {
    return taskBox.values.where((task) => !task.isCompleted).length;
  }

  int _overdueTasks() {
    final today = _dateOnly(DateTime.now());

    return taskBox.values.where((task) {
      if (task.dueDate == null) return false;
      if (task.isCompleted) return false;

      final dueDate = _dateOnly(task.dueDate!);
      return dueDate.isBefore(today);
    }).length;
  }

  int _dueTodayTasks() {
    final today = _dateOnly(DateTime.now());

    return taskBox.values.where((task) {
      if (task.dueDate == null) return false;
      if (task.isCompleted) return false;

      final dueDate = _dateOnly(task.dueDate!);
      return dueDate == today;
    }).length;
  }

  List<int> _weeklyTaskData() {
    final today = _dateOnly(DateTime.now());

    return List.generate(7, (index) {
      final date = today.subtract(Duration(days: 6 - index));

      return historyBox.values.where((history) {
        final historyDate = _dateOnly(history.date);
        return historyDate == date && history.tasksCompleted > 0;
      }).fold<int>(
        0,
        (sum, history) => sum + history.tasksCompleted,
      );
    });
  }

  List<String> _weeklyLabels() {
    final today = _dateOnly(DateTime.now());

    const labels = [
      "Mon",
      "Tue",
      "Wed",
      "Thu",
      "Fri",
      "Sat",
      "Sun",
    ];

    return List.generate(7, (index) {
      final date = today.subtract(Duration(days: 6 - index));
      return labels[date.weekday - 1];
    });
  }

  Future<void> _openProgressReport() async {
    HapticFeedback.selectionClick();
    await AudioService.playClick();

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ProgressReportScreen(
          autoShare: true,
        ),
      ),
    );
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
    final productivityLevel = ProductivityService.getProductivityLevel(score);
    final productivityMessage =
        ProductivityService.getProductivityMessage(score);

    final progressPercent = XPService.progressToNextLevel(settings.totalXP);
    final currentLevelXP = XPService.xpIntoCurrentLevel(settings.totalXP);
    final neededLevelXP = XPService.xpNeededForCurrentLevel(settings.totalXP);

    final completedToday = _completedToday();
    final xpToday = _xpToday();
    final totalCompleted = _totalCompletedTasks();
    final completedWeek = _completedThisWeek();
    final xpWeek = _xpThisWeek();
    final activeDaysWeek = _activeDaysThisWeek();
    final pendingTasks = _pendingTasks();
    final overdueTasks = _overdueTasks();
    final dueTodayTasks = _dueTodayTasks();

    final weeklyData = _weeklyTaskData();
    final weeklyLabels = _weeklyLabels();

    return Scaffold(
      backgroundColor: const Color(0xFF08152E),
      body: SafeArea(
        child: FadeTransition(
          opacity: fadeAnimation,
          child: SlideTransition(
            position: slideAnimation,
            child: Column(
              children: [
                _header(),
                Expanded(
                  child: ValueListenableBuilder(
                    valueListenable: historyBox.listenable(),
                    builder: (context, Box<XPHistory> box, _) {
                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _productivityHero(
                              score: score,
                              level: productivityLevel,
                              message: productivityMessage,
                            ),
                            const SizedBox(height: 14),
                            _levelProgressCard(
                              settings: settings,
                              progressPercent: progressPercent,
                              currentLevelXP: currentLevelXP,
                              neededLevelXP: neededLevelXP,
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: _miniStatCard(
                                    title: "Today",
                                    value: "$completedToday",
                                    subtitle: "Tasks done",
                                    icon: Icons.today,
                                    color: const Color(0xFF2EE6A6),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _miniStatCard(
                                    title: "XP Today",
                                    value: "$xpToday",
                                    subtitle: "XP earned",
                                    icon: Icons.bolt,
                                    color: const Color(0xFFFFC857),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _miniStatCard(
                                    title: "Streak",
                                    value: "${streak.currentStreak}",
                                    subtitle: "Current days",
                                    icon: Icons.local_fire_department,
                                    color: Colors.orange,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _miniStatCard(
                                    title: "Best",
                                    value: "${streak.longestStreak}",
                                    subtitle: "Longest streak",
                                    icon: Icons.emoji_events,
                                    color: Colors.blueAccent,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            _sectionTitle("Weekly Analytics"),
                            const SizedBox(height: 10),
                            _weeklyChart(
                              data: weeklyData,
                              labels: weeklyLabels,
                            ),
                            const SizedBox(height: 18),
                            _sectionTitle("Task Health"),
                            const SizedBox(height: 10),
                            _taskHealthCard(
                              pendingTasks: pendingTasks,
                              overdueTasks: overdueTasks,
                              dueTodayTasks: dueTodayTasks,
                            ),
                            const SizedBox(height: 18),
                            _sectionTitle("Progress Summary"),
                            const SizedBox(height: 10),
                            _summaryGrid(
                              totalCompleted: totalCompleted,
                              completedWeek: completedWeek,
                              xpWeek: xpWeek,
                              activeDaysWeek: activeDaysWeek,
                              totalXP: settings.totalXP,
                              currentLevel: settings.currentLevel,
                            ),
                            const SizedBox(height: 18),
                            _reportCardButton(),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              AudioService.playClick();
              Navigator.pop(context);
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF102A4A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.07),
                ),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Analytics",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  "Your productivity overview",
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _openProgressReport,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF2EE6A6),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.16),
                    blurRadius: 12,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: const Icon(
                Icons.ios_share,
                color: Colors.black,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _productivityHero({
    required int score,
    required String level,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF102A4A),
            Color(0xFF163B66),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: const Color(0xFF2EE6A6).withOpacity(0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 104,
            height: 104,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 96,
                  height: 96,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 9,
                    backgroundColor: Colors.white.withOpacity(0.08),
                    valueColor: const AlwaysStoppedAnimation(
                      Color(0xFF2EE6A6),
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "$score",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const Text(
                      "/100",
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Productivity Score",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  level,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.55),
                    fontSize: 12.5,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _levelProgressCard({
    required Settings settings,
    required double progressPercent,
    required int currentLevelXP,
    required int neededLevelXP,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF102A4A),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withOpacity(0.07),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  "Level Progress",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
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
                    color: const Color(0xFF2EE6A6).withOpacity(0.32),
                  ),
                ),
                child: Text(
                  "Level ${settings.currentLevel}",
                  style: const TextStyle(
                    color: Color(0xFF2EE6A6),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progressPercent,
              minHeight: 9,
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
    );
  }

  Widget _miniStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF102A4A),
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: Colors.white.withOpacity(0.07),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 39,
            height: 39,
            decoration: BoxDecoration(
              color: color.withOpacity(0.13),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              icon,
              color: color,
              size: 21,
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
                const SizedBox(height: 3),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: Colors.white.withOpacity(0.76),
        fontSize: 14,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget _weeklyChart({
    required List<int> data,
    required List<String> labels,
  }) {
    final maxValue =
        data.isEmpty ? 1 : data.reduce((a, b) => a > b ? a : b).clamp(1, 999);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF102A4A),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withOpacity(0.07),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Tasks completed in last 7 days",
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(data.length, (index) {
                final value = data[index];
                final barHeight = maxValue == 0
                    ? 0.0
                    : (value / maxValue).clamp(0.06, 1.0) * 110;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          "$value",
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 7),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOutCubic,
                          height: barHeight,
                          decoration: BoxDecoration(
                            color: value == 0
                                ? Colors.white.withOpacity(0.08)
                                : const Color(0xFF2EE6A6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          labels[index],
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _taskHealthCard({
    required int pendingTasks,
    required int overdueTasks,
    required int dueTodayTasks,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF102A4A),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: overdueTasks > 0
              ? const Color(0xFFFF5C7A).withOpacity(0.25)
              : Colors.white.withOpacity(0.07),
        ),
      ),
      child: Column(
        children: [
          _healthRow(
            title: "Pending tasks",
            value: "$pendingTasks",
            icon: Icons.task_alt,
            color: const Color(0xFF62D6FF),
          ),
          const SizedBox(height: 12),
          _healthRow(
            title: "Due today",
            value: "$dueTodayTasks",
            icon: Icons.today,
            color: const Color(0xFFFFC857),
          ),
          const SizedBox(height: 12),
          _healthRow(
            title: "Overdue tasks",
            value: "$overdueTasks",
            icon: Icons.warning_rounded,
            color: const Color(0xFFFF5C7A),
          ),
        ],
      ),
    );
  }

  Widget _healthRow({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.13),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            icon,
            color: color,
            size: 19,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _summaryGrid({
    required int totalCompleted,
    required int completedWeek,
    required int xpWeek,
    required int activeDaysWeek,
    required int totalXP,
    required int currentLevel,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _summaryTile(
                title: "Total Done",
                value: "$totalCompleted",
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _summaryTile(
                title: "Week Done",
                value: "$completedWeek",
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _summaryTile(
                title: "Week XP",
                value: "$xpWeek",
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _summaryTile(
                title: "Active Days",
                value: "$activeDaysWeek/7",
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _summaryTile(
                title: "Total XP",
                value: "$totalXP",
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _summaryTile(
                title: "Level",
                value: "$currentLevel",
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _summaryTile({
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF102A4A),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: Colors.white.withOpacity(0.07),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(0.45),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _reportCardButton() {
    return GestureDetector(
      onTap: _openProgressReport,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: const Color(0xFF2EE6A6),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.16),
              blurRadius: 16,
              offset: const Offset(0, 9),
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(
              Icons.ios_share,
              color: Colors.black,
              size: 24,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                "Share Image Report",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.black,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
