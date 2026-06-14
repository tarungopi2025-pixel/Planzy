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

  InputDecoration _input(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white60),
      prefixIcon: Icon(icon, color: const Color(0xFF2EE6A6)),
      filled: true,
      fillColor: const Color(0xFF0B1B3A),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2EE6A6)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF08152E),
      appBar: AppBar(
        title: const Text("Create Task"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF102A4A),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TITLE
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white),
                decoration: _input("Task Title", Icons.title),
              ),

              const SizedBox(height: 14),

              // DESCRIPTION
              TextField(
                controller: descriptionController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: _input("Description", Icons.notes),
              ),

              const SizedBox(height: 14),

              // PRIORITY
              DropdownButtonFormField<TaskPriority>(
                value: selectedPriority,
                dropdownColor: const Color(0xFF102A4A),
                decoration: _input("Priority", Icons.flag),
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
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),

              const SizedBox(height: 22),

              // FINAL BUTTON (CLEAN + PREMIUM)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: saveTask,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2EE6A6),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Colors.white10),
                    ),
                  ),
                  child: const Text(
                    "CREATE TASK",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
