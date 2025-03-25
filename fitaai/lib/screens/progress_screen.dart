import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_nav_bar.dart';
import '../widgets/ui_components.dart';
import '../main.dart';
import 'daily_log_screen.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> with SingleTickerProviderStateMixin {
  // Navigation
  int _selectedIndex = 3; // Progress tab
  
  // Tab controller
  late TabController _tabController;
  
  // Time range selection
  String _selectedTimeRange = 'Week'; // Default: Week
  final List<String> _timeRanges = ['Week', 'Month', '3 Months', 'Year'];
  
  // Weight data
  List<WeightEntry> _weightData = [];
  double _targetWeight = 70.0; // Default target weight
  
  // Water intake data
  List<WaterIntakeEntry> _waterData = [];
  int _targetWaterIntake = 2500; // Default target in ml
  
  // Workout data
  List<WorkoutEntry> _workoutData = [];
  
  // Nutrition data
  List<NutritionEntry> _nutritionData = [];
  
  // Loading states
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize tab controller
    _tabController = TabController(length: 4, vsync: this);
    
    // Load data
    _loadUserData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  // Load user data from database
  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        // Not logged in
        setState(() => _isLoading = false);
        return;
      }
      
      // For demonstration, generate some mock data
      _generateMockData();
      
      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error loading user data: $e');
      setState(() => _isLoading = false);
    }
  }
  
  // Generate mock data for demonstration
  void _generateMockData() {
    final random = Random();
    final now = DateTime.now();
    
    // Generate weight data for the past 30 days
    _weightData = List.generate(30, (index) {
      final date = now.subtract(Duration(days: 29 - index));
      return WeightEntry(
        date: date,
        weight: 75.0 - index * 0.1 + (random.nextDouble() * 1.0 - 0.5),
      );
    });
    
    // Generate water intake data for the past 30 days
    _waterData = List.generate(30, (index) {
      final date = now.subtract(Duration(days: 29 - index));
      return WaterIntakeEntry(
        date: date,
        intake: 2000 + random.nextInt(1000), // Random intake between 2000-3000ml
      );
    });
    
    // Generate workout data for the past 30 days
    _workoutData = List.generate(15, (index) { // Workouts every other day
      final date = now.subtract(Duration(days: 29 - index * 2));
      return WorkoutEntry(
        date: date,
        duration: 30 + random.nextInt(30), // 30-60 minutes
        caloriesBurned: 200 + random.nextInt(300), // 200-500 calories
        workoutType: ['Strength', 'Cardio', 'HIIT', 'Yoga'][random.nextInt(4)],
      );
    });
    
    // Generate nutrition data for the past 30 days
    _nutritionData = List.generate(30, (index) {
      final date = now.subtract(Duration(days: 29 - index));
      final baseCal = 2000 + (random.nextInt(200) - 100);
      return NutritionEntry(
        date: date,
        calories: baseCal,
        protein: (baseCal * 0.3 / 4).round(), // 30% protein
        carbs: (baseCal * 0.5 / 4).round(),   // 50% carbs
        fat: (baseCal * 0.2 / 9).round(),     // 20% fat
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Progress'),
        scrolledUnderElevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Weight'),
            Tab(text: 'Workouts'),
            Tab(text: 'Nutrition'),
          ],
          dividerHeight: 0,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildWeightTab(),
          _buildWorkoutsTab(),
          _buildNutritionTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showQuickLogOptions(context);
        },
        heroTag: 'progress_fab',
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: CustomNavBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == _selectedIndex) return;
          
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/home');
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/workout');
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, '/nutrition');
          } else if (index == 4) {
            Navigator.pushNamed(context, '/chat');
          } else {
            setState(() {
              _selectedIndex = index;
            });
          }
        },
      ),
    );
  }
  
  Widget _buildOverviewTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return RefreshIndicator(
      onRefresh: _loadUserData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildWeeklyProgress(),
          const SizedBox(height: 16),
          _buildMonthlyComparison(),
          const SizedBox(height: 16),
          _buildGoalsProgressCard(),
        ],
      ),
    );
  }
  
  Widget _buildWeeklyProgress() {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly Progress',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: Center(
                child: Text(
                  'Weekly progress chart would go here',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMonthlyComparison() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Comparison',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildComparisonCard(
                    'Weight',
                    '72.5kg',
                    '74.0kg',
                    isPositive: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildComparisonCard(
                    'Body Fat',
                    '18.2%',
                    '19.5%',
                    isPositive: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildComparisonCard(
                    'Resting HR',
                    '65 bpm',
                    '68 bpm',
                    isPositive: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildComparisonCard(
                    'Avg. Sleep',
                    '7.2 hrs',
                    '6.8 hrs',
                    isPositive: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildComparisonCard(
    String title,
    String current,
    String previous,
    {required bool isPositive}
  ) {
    return Card(
      color: AppTheme.surfaceColor,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              current,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  isPositive ? Icons.arrow_downward : Icons.arrow_upward,
                  color: isPositive ? Colors.green : Colors.red,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  'From $previous',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isPositive ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildGoalsProgressCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Goals Progress',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildGoalProgressItem(
              'Lose 5kg',
              0.45,
              '2.3/5kg',
              Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildGoalProgressItem(
              'Workout 5 days/week',
              0.8,
              '4/5 days',
              Colors.green,
            ),
            const SizedBox(height: 12),
            _buildGoalProgressItem(
              'Sleep 8 hours/night',
              0.6,
              '6.5/8 hours',
              Colors.blue,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildGoalProgressItem(
    String goal,
    double progress,
    String value,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          goal,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 7,
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppTheme.cardColor,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildWeightTab() {
    return const Center(
      child: Text('Weight tracking data will go here'),
    );
  }
  
  Widget _buildWorkoutsTab() {
    return const Center(
      child: Text('Workout tracking data will go here'),
    );
  }
  
  Widget _buildNutritionTab() {
    return const Center(
      child: Text('Nutrition tracking data will go here'),
    );
  }
  
  void _showQuickLogOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 16),
              child: Text(
                'Quick Log',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.monitor_weight),
              title: const Text('Weight'),
              subtitle: const Text('Update your weight measurement'),
              onTap: () {
                Navigator.pop(context);
                // Show weight logging sheet
              },
            ),
            ListTile(
              leading: const Icon(Icons.water_drop),
              title: const Text('Water'),
              subtitle: const Text('Log water intake'),
              onTap: () {
                Navigator.pop(context);
                // Show water logging sheet
              },
            ),
            ListTile(
              leading: const Icon(Icons.fitness_center),
              title: const Text('Workout'),
              subtitle: const Text('Record a workout session'),
              onTap: () {
                Navigator.pop(context);
                // Show workout logging sheet
              },
            ),
            ListTile(
              leading: const Icon(Icons.restaurant),
              title: const Text('Meal'),
              subtitle: const Text('Log your food intake'),
              onTap: () {
                Navigator.pop(context);
                // Show meal logging sheet
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Data Models
class WeightEntry {
  final DateTime date;
  final double weight;
  
  WeightEntry({
    required this.date,
    required this.weight,
  });
}

class WaterIntakeEntry {
  final DateTime date;
  final int intake; // in milliliters
  
  WaterIntakeEntry({
    required this.date,
    required this.intake,
  });
}

class WorkoutEntry {
  final DateTime date;
  final int duration; // in minutes
  final int caloriesBurned;
  final String workoutType;
  
  WorkoutEntry({
    required this.date,
    required this.duration,
    required this.caloriesBurned,
    required this.workoutType,
  });
}

class NutritionEntry {
  final DateTime date;
  final int calories;
  final int protein; // in grams
  final int carbs; // in grams
  final int fat; // in grams
  
  NutritionEntry({
    required this.date,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });
}

// Delegate for the SliverPersistentHeader with the TabBar
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: Colors.black.withOpacity(0.1),
          child: tabBar,
        ),
      ),
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
} 