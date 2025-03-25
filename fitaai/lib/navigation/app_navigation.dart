import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/workout_screen.dart';
import '../screens/progress_screen.dart';
import '../screens/daily_log_screen.dart';
import '../theme/app_theme.dart';

class AppNavigation extends StatefulWidget {
  final String? userId;
  
  const AppNavigation({
    super.key,
    required this.userId,
  });

  @override
  State<AppNavigation> createState() => _AppNavigationState();
}

class _AppNavigationState extends State<AppNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const WorkoutScreen(),
    const DailyLogScreen(),
    const ProfileScreen(),
    const ProgressScreen(),
  ];

  final List<BottomNavigationBarItem> _navigationItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.home),
      label: 'Home',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.fitness_center),
      label: 'Workouts',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.add_chart),
      label: 'Log',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.person),
      label: 'Profile',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.bar_chart),
      label: 'Progress',
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 0,
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppTheme.darkBackgroundColor,
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: Colors.white.withOpacity(0.5),
          items: _navigationItems,
        ),
      ),
    );
  }
} 