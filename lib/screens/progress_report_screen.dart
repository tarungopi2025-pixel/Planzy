import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../models/task.dart';
import '../models/settings.dart';
import '../models/streak.dart';
import '../models/xp_history.dart';
import '../models/user_profile.dart';

import '../services/productivity_service.dart';
import '../services/xp_service.dart';
import '../services/audio_service.dart';

class ProgressReportScreen extends StatefulWidget {
  final bool autoShare;

  const ProgressReportScreen({
    super.key,
    this.autoShare = true,
  });

  @override
  State<ProgressReportScreen> createState() => _ProgressReportScreenState();
}

class _ProgressReportScreenState extends State<ProgressReportScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey reportKey = GlobalKey();

  late Box<Task> taskBox;
  late Box<Settings> settingsBox;
  late Box<Streak> streakBox;
  late Box<XPHistory> historyBox;
  late Box<UserProfile> userBox;

  late AnimationController controller;
  late Animation<double> fadeAnimation;
  late Animation<Offset> slideAnimation;

  bool isSharing = false;
  bool autoShareStarted = false;

  @override
  void initState() {
    super.initState();

    taskBox = Hive.box<Task>('tasks');
    settingsBox = Hive.box<Settings>('settings');
    streakBox = Hive.box<Streak>('streak');
    historyBox = Hive.box<XPHistory>('xp_history');
    userBox = Hive.box<UserProfile>('user_profile');

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    fadeAnimation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeOut,
    );

    slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeOutCubic,
      ),
    );

    controller.forward();

    if (widget.autoShare) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Future.delayed(const Duration(milliseconds: 700));

        if (!mounted || autoShareStarted) return;

        autoShareStarted = true;

        await shareReportImage();
      });
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  String get userName {
    if (userBox.isEmpty) return "My";

    final name = userBox.getAt(0)?.name.trim() ?? "";

    if (name.isEmpty) return "My";

    return name;
  }

  int get completedToday {
    final today = _dateOnly(DateTime.now());

    return historyBox.values.where((history) {
      final date = _dateOnly(history.date);
      return date == today && history.tasksCompleted > 0;
    }).fold<int>(
      0,
      (sum, history) => sum + history.tasksCompleted,
    );
  }

  int get xpToday {
    final today = _dateOnly(DateTime.now());

    return historyBox.values.where((history) {
      final date = _dateOnly(history.date);
      return date == today && history.xpEarned > 0;
    }).fold<int>(
      0,
      (sum, history) => sum + history.xpEarned,
    );
  }

  int get totalCompleted {
    return historyBox.values.where((history) {
      return history.tasksCompleted > 0;
    }).fold<int>(
      0,
      (sum, history) => sum + history.tasksCompleted,
    );
  }

  int get completedThisWeek {
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

  int get pendingTasks {
    return taskBox.values.where((task) => !task.isCompleted).length;
  }

  int get overdueTasks {
    final today = _dateOnly(DateTime.now());

    return taskBox.values.where((task) {
      if (task.dueDate == null) return false;
      if (task.isCompleted) return false;

      final due = _dateOnly(task.dueDate!);
      return due.isBefore(today);
    }).length;
  }

  List<int> get weeklyData {
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

  List<String> get weeklyLabels {
    final today = _dateOnly(DateTime.now());

    const labels = [
      "M",
      "T",
      "W",
      "T",
      "F",
      "S",
      "S",
    ];

    return List.generate(7, (index) {
      final date = today.subtract(Duration(days: 6 - index));
      return labels[date.weekday - 1];
    });
  }

  String get formattedDate {
    final now = DateTime.now();

    final day = now.day.toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    final year = now.year.toString();

    return "$day/$month/$year";
  }

  String scoreCaption(int score) {
    if (score == 0) return "Starting my productivity journey";
    if (score < 40) return "Building consistency one task at a time";
    if (score < 70) return "Focused and improving every day";
    if (score < 90) return "Strong productivity momentum";
    return "Elite focus and consistency";
  }

  Future<Uint8List?> captureReportImage() async {
    try {
      final boundary = reportKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;

      if (boundary == null) return null;

      final image = await boundary.toImage(
        pixelRatio: 3.0,
      );

      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  Future<void> shareReportImage() async {
    if (isSharing) return;

    setState(() {
      isSharing = true;
    });

    HapticFeedback.selectionClick();
    await AudioService.playClick();

    final imageBytes = await captureReportImage();

    if (!mounted) return;

    if (imageBytes == null) {
      setState(() {
        isSharing = false;
      });

      _showSnack("Unable to create report image. Try again.");
      return;
    }

    final fileName =
        "planzy_report_${DateTime.now().millisecondsSinceEpoch}.png";

    final xFile = XFile.fromData(
      imageBytes,
      mimeType: "image/png",
      name: fileName,
    );

    await SharePlus.instance.share(
      ShareParams(
        title: "My PLANZY Progress Report",
        text: "My PLANZY productivity progress.",
        files: [xFile],
      ),
    );

    if (!mounted) return;

    setState(() {
      isSharing = false;
    });
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFFF5C7A),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
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
    final levelText = ProductivityService.getProductivityLevel(score);

    final progressPercent = XPService.progressToNextLevel(settings.totalXP);
    final currentLevelXP = XPService.xpIntoCurrentLevel(settings.totalXP);
    final neededLevelXP = XPService.xpNeededForCurrentLevel(settings.totalXP);

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
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
                    child: Column(
                      children: [
                        RepaintBoundary(
                          key: reportKey,
                          child: _reportCard(
                            settings: settings,
                            streak: streak,
                            score: score,
                            levelText: levelText,
                            progressPercent: progressPercent,
                            currentLevelXP: currentLevelXP,
                            neededLevelXP: neededLevelXP,
                          ),
                        ),
                        const SizedBox(height: 18),
                        _shareButton(),
                      ],
                    ),
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
                  "Progress Report",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  "Auto-generated share image",
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
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

  Widget _reportCard({
    required Settings settings,
    required Streak streak,
    required int score,
    required String levelText,
    required double progressPercent,
    required int currentLevelXP,
    required int neededLevelXP,
  }) {
    final data = weeklyData;
    final labels = weeklyLabels;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF071225),
              Color(0xFF102A4A),
              Color(0xFF123156),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: const Color(0xFF2EE6A6).withOpacity(0.25),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.24),
              blurRadius: 24,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _brandHeader(),
            const SizedBox(height: 28),
            Text(
              "$userName's Productivity Report",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 25,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              scoreCaption(score),
              style: TextStyle(
                color: Colors.white.withOpacity(0.58),
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            _scoreBlock(score, levelText),
            const SizedBox(height: 22),
            _levelProgress(
              settings: settings,
              progressPercent: progressPercent,
              currentLevelXP: currentLevelXP,
              neededLevelXP: neededLevelXP,
            ),
            const SizedBox(height: 20),
            _statsGrid(
              settings: settings,
              streak: streak,
            ),
            const SizedBox(height: 22),
            _weeklyReportChart(
              data: data,
              labels: labels,
            ),
            const SizedBox(height: 22),
            _footer(),
          ],
        ),
      ),
    );
  }

  Widget _brandHeader() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF2EE6A6),
                Color(0xFF62D6FF),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(
            Icons.auto_awesome,
            color: Colors.black,
            size: 24,
          ),
        ),
        const SizedBox(width: 13),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "PLANZY",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.7,
                ),
              ),
              SizedBox(height: 2),
              Text(
                "Offline Productivity Tracker",
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Text(
          formattedDate,
          style: TextStyle(
            color: Colors.white.withOpacity(0.42),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _scoreBlock(int score, String levelText) {
    return Row(
      children: [
        SizedBox(
          width: 118,
          height: 118,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 108,
                height: 108,
                child: CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 10,
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
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
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
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Productivity Score",
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                levelText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2EE6A6).withOpacity(0.13),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: const Color(0xFF2EE6A6).withOpacity(0.28),
                  ),
                ),
                child: const Text(
                  "Built with consistency",
                  style: TextStyle(
                    color: Color(0xFF2EE6A6),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _levelProgress({
    required Settings settings,
    required double progressPercent,
    required int currentLevelXP,
    required int neededLevelXP,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.045),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withOpacity(0.07),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  "Level Progress",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                "Level ${settings.currentLevel}",
                style: const TextStyle(
                  color: Color(0xFF2EE6A6),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
          Row(
            children: [
              Expanded(
                child: Text(
                  "$currentLevelXP/$neededLevelXP XP to next level",
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                "${settings.totalXP} total XP",
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statsGrid({
    required Settings settings,
    required Streak streak,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _reportStat(
                title: "Today",
                value: "$completedToday",
                subtitle: "Tasks",
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _reportStat(
                title: "XP Today",
                value: "$xpToday",
                subtitle: "XP",
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _reportStat(
                title: "Total Done",
                value: "$totalCompleted",
                subtitle: "Tasks",
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _reportStat(
                title: "This Week",
                value: "$completedThisWeek",
                subtitle: "Tasks",
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _reportStat(
                title: "Streak",
                value: "${streak.currentStreak}",
                subtitle: "Days",
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _reportStat(
                title: "Best",
                value: "${streak.longestStreak}",
                subtitle: "Days",
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _reportStat(
                title: "Pending",
                value: "$pendingTasks",
                subtitle: "Tasks",
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _reportStat(
                title: "Overdue",
                value: "$overdueTasks",
                subtitle: "Tasks",
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _reportStat({
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.045),
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
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF2EE6A6),
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _weeklyReportChart({
    required List<int> data,
    required List<String> labels,
  }) {
    final maxValue =
        data.isEmpty ? 1 : data.reduce((a, b) => a > b ? a : b).clamp(1, 999);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 15, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.045),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withOpacity(0.07),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Last 7 Days",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 15),
          SizedBox(
            height: 125,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(data.length, (index) {
                final value = data[index];
                final barHeight = (value / maxValue).clamp(0.08, 1.0) * 88;

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
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: barHeight,
                          decoration: BoxDecoration(
                            color: value == 0
                                ? Colors.white.withOpacity(0.08)
                                : const Color(0xFF2EE6A6),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          labels[index],
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
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

  Widget _footer() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 1,
          color: Colors.white.withOpacity(0.08),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            const Expanded(
              child: Text(
                "Shared from PLANZY",
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF2EE6A6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                "FOCUS MODE",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _shareButton() {
    return GestureDetector(
      onTap: shareReportImage,
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
        child: Row(
          children: [
            Icon(
              isSharing ? Icons.hourglass_top : Icons.ios_share,
              color: Colors.black,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isSharing ? "Creating Report Image..." : "Share Image Report",
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const Icon(
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
