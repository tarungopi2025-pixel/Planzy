import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/task.dart';
import '../services/audio_service.dart';

class EditTaskScreen extends StatefulWidget {
  final Task task;

  const EditTaskScreen({
    super.key,
    required this.task,
  });

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen>
    with TickerProviderStateMixin {
  late TextEditingController titleController;
  late TextEditingController descriptionController;

  final FocusNode titleFocus = FocusNode();
  final FocusNode descriptionFocus = FocusNode();

  late AnimationController entranceController;
  late Animation<double> fadeAnimation;
  late Animation<Offset> slideAnimation;
  late Animation<double> scaleAnimation;

  late TaskPriority selectedPriority;
  DateTime? selectedDueDate;

  bool isSaving = false;

  @override
  void initState() {
    super.initState();

    titleController = TextEditingController(text: widget.task.title);
    descriptionController =
        TextEditingController(text: widget.task.description);

    selectedPriority = widget.task.priority;
    selectedDueDate = widget.task.dueDate;

    entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    fadeAnimation = CurvedAnimation(
      parent: entranceController,
      curve: Curves.easeOut,
    );

    slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: entranceController,
        curve: Curves.easeOutCubic,
      ),
    );

    scaleAnimation = Tween<double>(
      begin: 0.96,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: entranceController,
        curve: Curves.easeOutCubic,
      ),
    );

    entranceController.forward();
    AudioService.playOpen();
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();

    titleFocus.dispose();
    descriptionFocus.dispose();

    entranceController.dispose();

    super.dispose();
  }

  Color get priorityColor {
    switch (selectedPriority) {
      case TaskPriority.low:
        return const Color(0xFF2EE6A6);
      case TaskPriority.medium:
        return const Color(0xFFFFC857);
      case TaskPriority.high:
        return const Color(0xFFFF5C7A);
    }
  }

  String get priorityText {
    switch (selectedPriority) {
      case TaskPriority.low:
        return "Low Priority";
      case TaskPriority.medium:
        return "Medium Priority";
      case TaskPriority.high:
        return "High Priority";
    }
  }

  String get dueDateText {
    if (selectedDueDate == null) return "No due date";

    final day = selectedDueDate!.day.toString().padLeft(2, '0');
    final month = selectedDueDate!.month.toString().padLeft(2, '0');
    final year = selectedDueDate!.year.toString();

    return "$day/$month/$year";
  }

  Future<void> pickDueDate() async {
    HapticFeedback.selectionClick();
    AudioService.playClick();

    final now = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDueDate ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 5),
      helpText: "Choose Due Date",
      confirmText: "Select",
      cancelText: "Cancel",
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF2EE6A6),
              onPrimary: Colors.black,
              surface: Color(0xFF102A4A),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF08152E),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        selectedDueDate = pickedDate;
      });
    }
  }

  void selectPriority(TaskPriority priority) {
    HapticFeedback.selectionClick();
    AudioService.playClick();

    setState(() {
      selectedPriority = priority;
    });
  }

  void postponeByDays(int days) {
    HapticFeedback.selectionClick();
    AudioService.playClick();

    final baseDate = selectedDueDate ?? DateTime.now();

    setState(() {
      selectedDueDate = DateTime(
        baseDate.year,
        baseDate.month,
        baseDate.day + days,
      );
    });
  }

  void clearDueDate() {
    HapticFeedback.selectionClick();
    AudioService.playClick();

    setState(() {
      selectedDueDate = null;
    });
  }

  Future<void> saveTask() async {
    final title = titleController.text.trim();
    final description = descriptionController.text.trim();

    if (title.isEmpty) {
      HapticFeedback.heavyImpact();
      await AudioService.playError();
      _showSnack("Task name cannot be empty");
      return;
    }

    if (isSaving) return;

    setState(() {
      isSaving = true;
    });

    HapticFeedback.mediumImpact();
    await AudioService.playAddTask();

    final key = widget.task.key;

    if (key == null) {
      if (!mounted) return;
      Navigator.pop(context, false);
      return;
    }

    final taskBox = Hive.box<Task>('tasks');
    final storedTask = taskBox.get(key);

    if (storedTask == null) {
      if (!mounted) return;
      Navigator.pop(context, false);
      return;
    }

    storedTask.title = title;
    storedTask.description = description;
    storedTask.priority = selectedPriority;
    storedTask.dueDate = selectedDueDate;

    await storedTask.save();

    await Future.delayed(const Duration(milliseconds: 180));

    if (!mounted) return;

    Navigator.pop(context, true);
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
    return Scaffold(
      backgroundColor: const Color(0xFF08152E),
      body: SafeArea(
        child: FadeTransition(
          opacity: fadeAnimation,
          child: SlideTransition(
            position: slideAnimation,
            child: ScaleTransition(
              scale: scaleAnimation,
              child: Column(
                children: [
                  _header(),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _heroCard(),
                          const SizedBox(height: 18),
                          _sectionTitle("Task Details"),
                          const SizedBox(height: 10),
                          _inputCard(
                            child: Column(
                              children: [
                                _premiumTextField(
                                  controller: titleController,
                                  focusNode: titleFocus,
                                  hintText: "Task name",
                                  maxLines: 1,
                                  icon: Icons.edit_note,
                                ),
                                const SizedBox(height: 14),
                                _premiumTextField(
                                  controller: descriptionController,
                                  focusNode: descriptionFocus,
                                  hintText: "Description",
                                  maxLines: 4,
                                  icon: Icons.notes,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),
                          _sectionTitle("Priority"),
                          const SizedBox(height: 10),
                          _prioritySelector(),
                          const SizedBox(height: 22),
                          _sectionTitle("Due Date"),
                          const SizedBox(height: 10),
                          _dateSelector(),
                          const SizedBox(height: 14),
                          _postponeOptions(),
                          const SizedBox(height: 22),
                          _summaryCard(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _bottomSaveButton(),
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
              Navigator.pop(context, false);
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
            child: Text(
              "Edit Task",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF102A4A),
            priorityColor.withOpacity(0.14),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: priorityColor.withOpacity(0.26),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.16),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: priorityColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: priorityColor.withOpacity(0.36),
              ),
            ),
            child: Icon(
              Icons.tune,
              color: priorityColor,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Refine your task",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "Edit the name, priority, description, or postpone the due date.",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.58),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withOpacity(0.72),
        fontSize: 13,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _inputCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF102A4A),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withOpacity(0.07),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.16),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _premiumTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    required int maxLines,
    required IconData icon,
  }) {
    return AnimatedBuilder(
      animation: focusNode,
      builder: (context, child) {
        final focused = focusNode.hasFocus;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: focused
                ? const Color(0xFF16365D)
                : const Color(0xFF08152E).withOpacity(0.75),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: focused
                  ? priorityColor.withOpacity(0.65)
                  : Colors.white.withOpacity(0.06),
            ),
          ),
          child: Row(
            crossAxisAlignment: maxLines > 1
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.only(top: maxLines > 1 ? 12 : 0),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: focused
                        ? priorityColor.withOpacity(0.16)
                        : Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: focused ? priorityColor : Colors.white38,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  maxLines: maxLines,
                  cursorColor: priorityColor,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.32),
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _prioritySelector() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF102A4A),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withOpacity(0.07),
        ),
      ),
      child: Row(
        children: [
          _priorityChip(
            label: "Low",
            priority: TaskPriority.low,
            icon: Icons.spa,
            color: const Color(0xFF2EE6A6),
          ),
          const SizedBox(width: 8),
          _priorityChip(
            label: "Medium",
            priority: TaskPriority.medium,
            icon: Icons.bolt,
            color: const Color(0xFFFFC857),
          ),
          const SizedBox(width: 8),
          _priorityChip(
            label: "High",
            priority: TaskPriority.high,
            icon: Icons.local_fire_department,
            color: const Color(0xFFFF5C7A),
          ),
        ],
      ),
    );
  }

  Widget _priorityChip({
    required String label,
    required TaskPriority priority,
    required IconData icon,
    required Color color,
  }) {
    final selected = selectedPriority == priority;

    return Expanded(
      child: GestureDetector(
        onTap: () => selectPriority(priority),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          scale: selected ? 1.03 : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              color: selected ? color.withOpacity(0.17) : Colors.transparent,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                color: selected
                    ? color.withOpacity(0.75)
                    : Colors.white.withOpacity(0.05),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  color: selected ? color : Colors.white,
                  size: 21,
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dateSelector() {
    return GestureDetector(
      onTap: pickDueDate,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF102A4A),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selectedDueDate == null
                ? Colors.white.withOpacity(0.07)
                : priorityColor.withOpacity(0.4),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: selectedDueDate == null
                    ? Colors.white.withOpacity(0.05)
                    : priorityColor.withOpacity(0.16),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.calendar_month,
                color: selectedDueDate == null ? Colors.white38 : priorityColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedDueDate == null ? "Due Date" : "Selected Date",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dueDateText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            if (selectedDueDate != null)
              GestureDetector(
                onTap: clearDueDate,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white54,
                    size: 18,
                  ),
                ),
              )
            else
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white30,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  Widget _postponeOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle("Postpone"),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _postponeChip(
                label: "Tomorrow",
                days: 1,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _postponeChip(
                label: "+3 Days",
                days: 3,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _postponeChip(
                label: "+1 Week",
                days: 7,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _postponeChip({
    required String label,
    required int days,
  }) {
    return GestureDetector(
      onTap: () => postponeByDays(days),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF102A4A),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: priorityColor.withOpacity(0.24),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: priorityColor,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: priorityColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: priorityColor.withOpacity(0.24),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.update,
            color: priorityColor,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "$priorityText task • $dueDateText",
              style: TextStyle(
                color: Colors.white.withOpacity(0.72),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomSaveButton() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
        decoration: BoxDecoration(
          color: const Color(0xFF08152E).withOpacity(0.96),
          border: Border(
            top: BorderSide(
              color: Colors.white.withOpacity(0.06),
            ),
          ),
        ),
        child: GestureDetector(
          onTap: saveTask,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            height: 58,
            decoration: BoxDecoration(
              color: priorityColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.16),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: isSaving
                    ? const SizedBox(
                        key: ValueKey("loader"),
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor: AlwaysStoppedAnimation(
                            Colors.black,
                          ),
                        ),
                      )
                    : const Row(
                        key: ValueKey("save"),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.save,
                            color: Colors.black,
                            size: 22,
                          ),
                          SizedBox(width: 10),
                          Text(
                            "Save Changes",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
