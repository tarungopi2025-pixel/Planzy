import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/achievement.dart';

class AchievementScreen extends StatelessWidget {
  const AchievementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<Achievement>('achievements');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
      ),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box<Achievement> box, _) {
          final items = box.values.toList();

          if (items.isEmpty) {
            return const Center(
              child: Text('No achievements yet'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final a = items[index];

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: a.unlocked ? Colors.green : Colors.grey.shade400,
                  ),
                  color: a.unlocked
                      ? Colors.green.withOpacity(0.08)
                      : Colors.grey.withOpacity(0.05),
                ),
                child: Row(
                  children: [
                    Icon(
                      a.unlocked ? Icons.verified : Icons.lock_outline,
                      color: a.unlocked ? Colors.green : Colors.grey,
                      size: 28,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            a.description,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (a.unlocked)
                      const Icon(Icons.check_circle, color: Colors.green),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
