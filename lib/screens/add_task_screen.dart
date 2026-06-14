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

  Future<void> saveTask() async {
    if (titleController.text.trim().isEmpty) return;

    final task = Task(
      title: titleController.text.trim(),
      description: descriptionController.text.trim(),
      priority: selectedPriority,
    );

    final box = Hive.box<Task>('tasks');

    await box.add(task);

    if (!mounted) return;

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Task'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Task Title',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Description',
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<TaskPriority>(
              value: selectedPriority,
              decoration: const InputDecoration(
                labelText: 'Priority',
              ),
              items: TaskPriority.values.map((priority) {
                return DropdownMenuItem(
                  value: priority,
                  child: Text(
                    priority.name.toUpperCase(),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  selectedPriority = value;
                });
              },
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saveTask,
                child: const Text('Create Task'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
