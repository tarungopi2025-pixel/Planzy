import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'dashboard_screen.dart';
import 'achivement_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;

  final pages = const [
    HomeScreen(),
    DashboardScreen(),
    AchievementScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) {
          setState(() {
            index = i;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.task_alt),
            label: "Tasks",
          ),
          NavigationDestination(
            icon: Icon(Icons.insights),
            label: "Dashboard",
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events),
            label: "Achievements",
          ),
        ],
      ),
    );
  }
}
