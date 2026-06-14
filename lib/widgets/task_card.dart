import 'package:flutter/material.dart';
import '../models/task.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;

  const TaskCard({
    super.key,
    required this.task,
    required this.onToggle,
  });

  Color _priorityColor() {
    switch (task.priority) {
      case TaskPriority.low:
        return const Color(0xFF2EE6A6);
      case TaskPriority.medium:
        return const Color(0xFFFFB020);
      case TaskPriority.high:
        return const Color(0xFFFF4D4D);
    }
  }

  String _priorityText() {
    switch (task.priority) {
      case TaskPriority.low:
        return 'LOW';
      case TaskPriority.medium:
        return 'MEDIUM';
      case TaskPriority.high:
        return 'HIGH';
    }
  }

  bool get isOverdue {
    if (task.isCompleted) return false;
    if (task.dueDate == null) return false;

    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    return task.dueDate!.isBefore(today);
  }

  bool get isDueToday {
    if (task.isCompleted) return false;
    if (task.dueDate == null) return false;

    final now = DateTime.now();

    return task.dueDate!.year == now.year &&
        task.dueDate!.month == now.month &&
        task.dueDate!.day == now.day;
  }

  // ✅ NEW: format date safely
  String _formatDate(DateTime? date) {
    if (date == null) return "No due date";
    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = task.isCompleted
        ? const Color(0xFF2EE6A6)
        : isOverdue
            ? const Color(0xFFFF4D4D)
            : isDueToday
                ? const Color(0xFFFFB020)
                : _priorityColor();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: task.isCompleted
            ? const Color(0xFF0F2A1F)
            : const Color(0xFF102A4A),
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left: BorderSide(
            color: borderColor,
            width: 4,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: task.isCompleted
                      ? const Color(0xFF2EE6A6)
                      : Colors.white30,
                ),
                color: task.isCompleted
                    ? const Color(0xFF2EE6A6)
                    : Colors.transparent,
              ),
              child: task.isCompleted
                  ? const Icon(Icons.check, size: 16, color: Colors.black)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    decoration:
                        task.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),

                const SizedBox(height: 6),

                if (task.description.isNotEmpty)
                  Text(
                    task.description,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),

                const SizedBox(height: 6),

                // ✅ NEW: DUE DATE DISPLAY (THIS WAS MISSING)
                Text(
                  "Due: ${_formatDate(task.dueDate)}",
                  style: TextStyle(
                    color: isOverdue
                        ? const Color(0xFFFF4D4D)
                        : isDueToday
                            ? const Color(0xFFFFB020)
                            : Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _priorityColor().withOpacity(0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _priorityText(),
                        style: TextStyle(
                          color: _priorityColor(),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (!task.isCompleted && task.dueDate != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: isOverdue
                              ? const Color(0xFFFF4D4D).withOpacity(0.15)
                              : isDueToday
                                  ? const Color(0xFFFFB020).withOpacity(0.15)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: isOverdue
                                ? const Color(0xFFFF4D4D)
                                : const Color(0xFFFFB020),
                          ),
                        ),
                        child: Text(
                          isOverdue
                              ? "OVERDUE"
                              : isDueToday
                                  ? "DUE TODAY"
                                  : "",
                          style: TextStyle(
                            color: isOverdue
                                ? const Color(0xFFFF4D4D)
                                : const Color(0xFFFFB020),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
