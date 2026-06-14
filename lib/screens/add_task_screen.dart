import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../models/task.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();

  TaskPriority selectedPriority = TaskPriority.medium;
  DateTime? selectedDueDate;

  Future<void> pickDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (date == null) return;

    setState(() => selectedDueDate = date);
  }

  Future<void> saveTask() async {
    if (titleController.text.trim().isEmpty) return;

    final task = Task(
      title: titleController.text.trim(),
      description: descriptionController.text.trim(),
      priority: selectedPriority,
      dueDate: selectedDueDate,
    );

    final box = Hive.box<Task>('tasks');
    await box.add(task);

    if (!mounted) return;
    Navigator.pop(context);
  }

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(icon, color: const Color(0xFF2EE6A6)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2EE6A6), width: 1.5),
      ),
      filled: true,
      fillColor: const Color(0xFF0B1B3A),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF08152E),
      appBar: AppBar(
        title: const Text('Create Task'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF102A4A),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Column(
              children: [
                // TITLE
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _decoration("Task Title", Icons.title),
                ),

                const SizedBox(height: 14),

                // DESCRIPTION
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: _decoration("Description", Icons.notes),
                ),

                const SizedBox(height: 14),

                // PRIORITY
                DropdownButtonFormField<TaskPriority>(
                  value: selectedPriority,
                  dropdownColor: const Color(0xFF102A4A),
                  decoration: _decoration("Priority", Icons.flag),
                  items: TaskPriority.values.map((priority) {
                    return DropdownMenuItem(
                      value: priority,
                      child: Text(
                        priority.name.toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => selectedPriority = value);
                  },
                ),

                const SizedBox(height: 14),

                // DUE DATE
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B1B3A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: TextButton.icon(
                    onPressed: pickDueDate,
                    icon: const Icon(Icons.calendar_today,
                        color: Color(0xFF2EE6A6)),
                    label: Text(
                      selectedDueDate == null
                          ? "Set Due Date"
                          : "Due: ${selectedDueDate!.day}/${selectedDueDate!.month}/${selectedDueDate!.year}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 🔥 PREMIUM BUTTON (FIXED VISIBILITY)
                Container(
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF2EE6A6),
                        Color(0xFF00C2FF),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2EE6A6).withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      )
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: saveTask,
                      child: const Center(
                        child: Text(
                          "CREATE TASK",
                          style: TextStyle(
                            color: Colors.white, // 🔥 FIXED VISIBILITY
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.3,
                          ),
                        ),
                      ),
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
}
