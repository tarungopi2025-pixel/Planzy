import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/achievement.dart';
import '../services/achievement_service.dart';

class AchievementScreen extends StatefulWidget {
  const AchievementScreen({super.key});

  @override
  State<AchievementScreen> createState() => _AchievementScreenState();
}

class _AchievementScreenState extends State<AchievementScreen>
    with TickerProviderStateMixin {
  late Box<Achievement> achievementBox;

  late AnimationController entranceController;
  late Animation<double> fadeAnimation;
  late Animation<Offset> slideAnimation;

  bool isLoadingAchievements = true;

  @override
  void initState() {
    super.initState();

    achievementBox = Hive.box<Achievement>('achievements');

    entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    fadeAnimation = CurvedAnimation(
      parent: entranceController,
      curve: Curves.easeOut,
    );

    slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: entranceController,
        curve: Curves.easeOutCubic,
      ),
    );

    entranceController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await AchievementService.initAchievements();
      await AchievementService.checkAndUnlock();

      if (mounted) {
        setState(() {
          isLoadingAchievements = false;
        });
      }
    });
  }

  @override
  void dispose() {
    entranceController.dispose();
    super.dispose();
  }

  Color _categoryColor(AchievementCategory category) {
    switch (category) {
      case AchievementCategory.task:
        return const Color(0xFF2EE6A6);
      case AchievementCategory.xp:
        return const Color(0xFF62D6FF);
      case AchievementCategory.streak:
        return const Color(0xFFFFC857);
      case AchievementCategory.challenge:
        return const Color(0xFFFF5C7A);
    }
  }

  IconData _categoryIcon(AchievementCategory category) {
    switch (category) {
      case AchievementCategory.task:
        return Icons.task_alt;
      case AchievementCategory.xp:
        return Icons.bolt;
      case AchievementCategory.streak:
        return Icons.local_fire_department;
      case AchievementCategory.challenge:
        return Icons.flag;
    }
  }

  String _categoryText(AchievementCategory category) {
    switch (category) {
      case AchievementCategory.task:
        return "Tasks";
      case AchievementCategory.xp:
        return "XP";
      case AchievementCategory.streak:
        return "Streak";
      case AchievementCategory.challenge:
        return "Consistency";
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "Locked";

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return "$day/$month/$year";
  }

  int _unlockedCount(List<Achievement> achievements) {
    return achievements.where((achievement) => achievement.unlocked).length;
  }

  double _progress(List<Achievement> achievements) {
    if (achievements.isEmpty) return 0;
    return _unlockedCount(achievements) / achievements.length;
  }

  List<Achievement> _sortedAchievements(List<Achievement> achievements) {
    final list = achievements.toList();

    list.sort((a, b) {
      if (a.unlocked != b.unlocked) {
        return a.unlocked ? -1 : 1;
      }

      final categoryCompare = a.category.index.compareTo(b.category.index);
      if (categoryCompare != 0) return categoryCompare;

      return a.id.compareTo(b.id);
    });

    return list;
  }

  @override
  Widget build(BuildContext context) {
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
                    valueListenable: achievementBox.listenable(),
                    builder: (context, Box<Achievement> box, _) {
                      final achievements =
                          _sortedAchievements(box.values.toList());

                      if (isLoadingAchievements && achievements.isEmpty) {
                        return _loadingState();
                      }

                      if (achievements.isEmpty) {
                        return _emptyState();
                      }

                      final unlocked = _unlockedCount(achievements);
                      final progress = _progress(achievements);

                      return CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
                              child: Column(
                                children: [
                                  _heroCard(
                                    unlocked: unlocked,
                                    total: achievements.length,
                                    progress: progress,
                                  ),
                                  const SizedBox(height: 14),
                                  _categorySummary(achievements),
                                  const SizedBox(height: 18),
                                  _sectionTitle("Your Achievements"),
                                ],
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final achievement = achievements[index];

                                  return TweenAnimationBuilder<double>(
                                    duration: Duration(
                                      milliseconds: 360 + (index * 28),
                                    ),
                                    tween: Tween<double>(begin: 0, end: 1),
                                    curve: Curves.easeOutCubic,
                                    builder: (context, value, child) {
                                      return Opacity(
                                        opacity: value,
                                        child: Transform.translate(
                                          offset: Offset(0, 16 * (1 - value)),
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: _achievementCard(achievement),
                                  );
                                },
                                childCount: achievements.length,
                              ),
                            ),
                          ),
                        ],
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
      padding: const EdgeInsets.fromLTRB(14, 10, 18, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.pop(context);
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
                  "Achievements",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  "Build consistency one milestone at a time",
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

  Widget _heroCard({
    required int unlocked,
    required int total,
    required double progress,
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
      child: Row(
        children: [
          SizedBox(
            width: 86,
            height: 86,
            child: Stack(
              alignment: Alignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 900),
                  tween: Tween<double>(begin: 0, end: progress),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return CircularProgressIndicator(
                      value: value,
                      strokeWidth: 8,
                      backgroundColor: Colors.white.withOpacity(0.08),
                      valueColor: const AlwaysStoppedAnimation(
                        Color(0xFF2EE6A6),
                      ),
                    );
                  },
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "$unlocked",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      "/$total",
                      style: const TextStyle(
                        color: Colors.white,
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
                  "Achievement Vault",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Unlock milestones by completing tasks, earning XP, and showing up consistently.",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.56),
                    fontSize: 12,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2EE6A6).withOpacity(0.13),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF2EE6A6).withOpacity(0.28),
                    ),
                  ),
                  child: Text(
                    "${(progress * 100).round()}% Completed",
                    style: const TextStyle(
                      color: Color(0xFF2EE6A6),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _categorySummary(List<Achievement> achievements) {
    final categories = AchievementCategory.values;

    return Row(
      children: categories.map((category) {
        final total = achievements
            .where((achievement) => achievement.category == category)
            .length;

        final unlocked = achievements
            .where(
              (achievement) =>
                  achievement.category == category && achievement.unlocked,
            )
            .length;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: category == categories.last ? 0 : 8,
            ),
            child: _categoryChip(
              category: category,
              unlocked: unlocked,
              total: total,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _categoryChip({
    required AchievementCategory category,
    required int unlocked,
    required int total,
  }) {
    final color = _categoryColor(category);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF102A4A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.07),
        ),
      ),
      child: Column(
        children: [
          Icon(
            _categoryIcon(category),
            color: color,
            size: 20,
          ),
          const SizedBox(height: 7),
          Text(
            "$unlocked/$total",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            _categoryText(category),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 1,
            color: Colors.white.withOpacity(0.07),
          ),
        ),
      ],
    );
  }

  Widget _achievementCard(Achievement achievement) {
    final color = _categoryColor(achievement.category);
    final unlocked = achievement.unlocked;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: unlocked ? const Color(0xFF102A4A) : const Color(0xFF0D1D38),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: unlocked
                ? color.withOpacity(0.42)
                : Colors.white.withOpacity(0.06),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 16,
              offset: const Offset(0, 9),
            ),
          ],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: unlocked
                    ? color.withOpacity(0.14)
                    : Colors.white.withOpacity(0.045),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: unlocked
                      ? color.withOpacity(0.36)
                      : Colors.white.withOpacity(0.06),
                ),
              ),
              child: Icon(
                unlocked ? _categoryIcon(achievement.category) : Icons.lock,
                color: unlocked ? color : Colors.white30,
                size: 25,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    achievement.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: unlocked ? Colors.white : Colors.white38,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    achievement.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: unlocked ? Colors.white54 : Colors.white24,
                      fontSize: 12,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: unlocked
                              ? color.withOpacity(0.12)
                              : Colors.white.withOpacity(0.045),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _categoryText(achievement.category),
                          style: TextStyle(
                            color: unlocked ? color : Colors.white30,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          unlocked
                              ? "Unlocked ${_formatDate(achievement.unlockedAt)}"
                              : "Locked",
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: unlocked ? Colors.white38 : Colors.white24,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              unlocked ? Icons.verified_rounded : Icons.circle_outlined,
              color: unlocked ? color : Colors.white24,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _loadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation(
          Color(0xFF2EE6A6),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 40, 28, 80),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              color: const Color(0xFF102A4A),
              borderRadius: BorderRadius.circular(30),
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
              Icons.emoji_events,
              color: Color(0xFF2EE6A6),
              size: 38,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            "No achievements yet",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Complete tasks to start unlocking milestones.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white54,
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
