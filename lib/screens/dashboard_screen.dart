import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/task.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<Task>('tasks');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box<Task> box, _) {
          final tasks = box.values.toList();

          final total = tasks.length;
          final completed = tasks.where((t) => t.isCompleted).length;
          final pending = total - completed;
          final completionRate =
              total == 0 ? 0 : (completed / total * 100).round();

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _card(
                  icon: Icons.list_alt,
                  title: "Total Tasks",
                  value: total.toString(),
                  color: Colors.blue,
                ),
                const SizedBox(height: 12),
                _card(
                  icon: Icons.check_circle,
                  title: "Completed",
                  value: completed.toString(),
                  color: Colors.green,
                ),
                const SizedBox(height: 12),
                _card(
                  icon: Icons.pending_actions,
                  title: "Pending",
                  value: pending.toString(),
                  color: Colors.orange,
                ),
                const SizedBox(height: 12),
                _card(
                  icon: Icons.trending_up,
                  title: "Completion Rate",
                  value: "$completionRate%",
                  color: Colors.purple,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _card({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5)),
        color: color.withOpacity(0.08),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
