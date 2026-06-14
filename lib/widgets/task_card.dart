import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/audio_service.dart';

class TaskCard extends StatefulWidget {
  final Task task;
  final VoidCallback onComplete;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const TaskCard({
    super.key,
    required this.task,
    required this.onComplete,
    this.onDelete,
    this.onTap,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _heightAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isClosing = false;
  bool _isCompleting = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    _fadeAnimation = Tween<double>(
      begin: 1,
      end: 0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.00,
          0.70,
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    _scaleAnimation = Tween<double>(
      begin: 1,
      end: 0.96,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _heightAnimation = Tween<double>(
      begin: 1,
      end: 0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.40,
          1.00,
          curve: Curves.easeInOutCubic,
        ),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.08, 0),
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _priorityColor() {
    switch (widget.task.priority) {
      case TaskPriority.low:
        return const Color(0xFF2EE6A6);
      case TaskPriority.medium:
        return const Color(0xFFFFC857);
      case TaskPriority.high:
        return const Color(0xFFFF5C7A);
    }
  }

  String _priorityText() {
    switch (widget.task.priority) {
      case TaskPriority.low:
        return "LOW";
      case TaskPriority.medium:
        return "MEDIUM";
      case TaskPriority.high:
        return "HIGH";
    }
  }

  bool get isOverdue {
    if (widget.task.dueDate == null) return false;
    if (widget.task.isCompleted) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final due = DateTime(
      widget.task.dueDate!.year,
      widget.task.dueDate!.month,
      widget.task.dueDate!.day,
    );

    return due.isBefore(today);
  }

  bool get isDueToday {
    if (widget.task.dueDate == null) return false;

    final now = DateTime.now();

    return widget.task.dueDate!.year == now.year &&
        widget.task.dueDate!.month == now.month &&
        widget.task.dueDate!.day == now.day;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "";

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return "$day/$month/$year";
  }

  Future<void> _completeWithAnimation() async {
    if (_isClosing) return;

    AudioService.playClick();

    setState(() {
      _isClosing = true;
      _isCompleting = true;
    });

    await _controller.forward();

    if (!mounted) return;

    widget.onComplete();
  }

  Future<void> _deleteWithAnimation() async {
    if (_isClosing) return;

    AudioService.playDelete();

    setState(() {
      _isClosing = true;
      _isCompleting = false;
    });

    await _controller.forward();

    if (!mounted) return;

    widget.onDelete?.call();
  }

  void _openEditScreen() {
    if (_isClosing) return;

    AudioService.playClick();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final priorityColor = _priorityColor();

    return SizeTransition(
      sizeFactor: _heightAnimation,
      axisAlignment: -1,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 0,
                vertical: 5,
              ),
              child: Dismissible(
                key: ValueKey("task_card_${widget.task.key}"),
                direction: DismissDirection.horizontal,
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.startToEnd) {
                    await _completeWithAnimation();
                  } else if (direction == DismissDirection.endToStart) {
                    await _deleteWithAnimation();
                  }

                  return false;
                },
                background: Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 22),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2EE6A6),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: AnimatedScale(
                    scale: _isClosing && _isCompleting ? 1.15 : 1,
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutBack,
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.black,
                      size: 30,
                    ),
                  ),
                ),
                secondaryBackground: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 22),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5C7A),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: AnimatedScale(
                    scale: _isClosing && !_isCompleting ? 1.15 : 1,
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutBack,
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
                child: GestureDetector(
                  onTap: _openEditScreen,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _isClosing && _isCompleting
                          ? const Color(0xFF143B4A)
                          : const Color(0xFF102A4A),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: _isClosing && _isCompleting
                            ? const Color(0xFF2EE6A6)
                            : isOverdue
                                ? const Color(0xFFFF5C7A)
                                : Colors.white.withOpacity(0.06),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: _completeWithAnimation,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeOutBack,
                            width: 26,
                            height: 26,
                            margin: const EdgeInsets.only(top: 2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _isClosing && _isCompleting
                                    ? const Color(0xFF2EE6A6)
                                    : priorityColor,
                                width: 2,
                              ),
                              color: _isClosing && _isCompleting
                                  ? const Color(0xFF2EE6A6)
                                  : widget.task.isCompleted
                                      ? priorityColor
                                      : Colors.transparent,
                            ),
                            child: AnimatedOpacity(
                              opacity: _isClosing && _isCompleting ? 1 : 0,
                              duration: const Duration(milliseconds: 180),
                              curve: Curves.easeOut,
                              child: const Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: AnimatedDefaultTextStyle(
                                      duration:
                                          const Duration(milliseconds: 240),
                                      curve: Curves.easeOutCubic,
                                      style: TextStyle(
                                        color: _isClosing && _isCompleting
                                            ? Colors.white54
                                            : widget.task.isCompleted
                                                ? Colors.white38
                                                : Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        decoration: _isClosing && _isCompleting
                                            ? TextDecoration.lineThrough
                                            : widget.task.isCompleted
                                                ? TextDecoration.lineThrough
                                                : TextDecoration.none,
                                      ),
                                      child: Text(
                                        widget.task.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 260),
                                    curve: Curves.easeOutCubic,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: priorityColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: priorityColor.withOpacity(0.6),
                                      ),
                                    ),
                                    child: Text(
                                      _priorityText(),
                                      style: TextStyle(
                                        color: priorityColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (widget.task.description
                                  .trim()
                                  .isNotEmpty) ...[
                                const SizedBox(height: 6),
                                AnimatedOpacity(
                                  duration: const Duration(milliseconds: 220),
                                  opacity:
                                      _isClosing && _isCompleting ? 0.45 : 1,
                                  child: Text(
                                    widget.task.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: widget.task.isCompleted
                                          ? Colors.white30
                                          : Colors.white60,
                                      fontSize: 12,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                              if (widget.task.dueDate != null) ...[
                                const SizedBox(height: 10),
                                AnimatedOpacity(
                                  duration: const Duration(milliseconds: 220),
                                  opacity:
                                      _isClosing && _isCompleting ? 0.45 : 1,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        size: 14,
                                        color: isOverdue
                                            ? const Color(0xFFFF5C7A)
                                            : isDueToday
                                                ? const Color(0xFFFFC857)
                                                : Colors.white38,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Due ${_formatDate(widget.task.dueDate)}",
                                        style: TextStyle(
                                          color: isOverdue
                                              ? const Color(0xFFFF5C7A)
                                              : isDueToday
                                                  ? const Color(0xFFFFC857)
                                                  : Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (isOverdue) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 7,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFF5C7A)
                                                .withOpacity(0.15),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: const Text(
                                            "OVERDUE",
                                            style: TextStyle(
                                              color: Color(0xFFFF5C7A),
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                      if (isDueToday && !isOverdue) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 7,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFC857)
                                                .withOpacity(0.15),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: const Text(
                                            "TODAY",
                                            style: TextStyle(
                                              color: Color(0xFFFFC857),
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.edit,
                          color: Colors.white.withOpacity(0.22),
                          size: 17,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
