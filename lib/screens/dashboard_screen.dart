import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../models/settings.dart';
import '../models/streak.dart';
import '../services/productivity_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Box<Settings> settingsBox;
  late Box<Streak> streakBox;

  @override
  void initState() {
    super.initState();
    settingsBox = Hive.box<Settings>('settings');
    streakBox = Hive.box<Streak>('streak');
  }

  void _refresh() => setState(() {});

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

    return Scaffold(
      backgroundColor: const Color(0xFF08152E),
      appBar: AppBar(
        title: const Text("Analytics"),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // HEADER
            _headerCard(settings, streak, score, level),

            const SizedBox(height: 16),

            // STATS LIST
            Expanded(
              child: ListView(
                children: [
                  _statTile(
                    title: "Level",
                    value: "${settings.currentLevel}",
                    icon: Icons.emoji_events,
                    color: const Color(0xFF4DA3FF),
                  ),
                  _statTile(
                    title: "Total XP",
                    value: "${settings.totalXP}",
                    icon: Icons.bolt,
                    color: const Color(0xFF00C2FF),
                  ),
                  _statTile(
                    title: "Streak",
                    value: "${streak.currentStreak}",
                    icon: Icons.local_fire_department,
                    color: const Color(0xFFFFB703),
                  ),
                  _statTile(
                    title: "Productivity",
                    value: "$score ($level)",
                    icon: Icons.insights,
                    color: const Color(0xFF2EE6A6),
                  ),
                  _statTile(
                    title: "Next Level Progress",
                    value: "${settings.totalXP % 100}/100 XP",
                    icon: Icons.trending_up,
                    color: const Color(0xFF7C4DFF),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= HEADER =================
  Widget _headerCard(
    Settings settings,
    Streak streak,
    int score,
    String level,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF102A4A),
            Color(0xFF0B1B3A),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          const Icon(Icons.insights, color: Colors.white, size: 32),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Your Productivity",
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 4),
              Text(
                "Level ${settings.currentLevel} • $level",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= STAT TILE =================
  Widget _statTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF102A4A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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
