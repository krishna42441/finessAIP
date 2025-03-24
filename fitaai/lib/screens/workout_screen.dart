import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_nav_bar.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  int _selectedIndex = 1; // Workout tab is selected
  int _selectedDay = DateTime.now().weekday - 1;
  
  final List<String> _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final List<String> _workoutTypes = ['Upper', 'Lower', 'Rest', 'Push', 'Pull', 'Rest', 'Full Body'];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: AppTheme.gradientBackground(),
          ),
          
          // Main content
          SafeArea(
            child: CustomScrollView(
              slivers: [
                // App Bar
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  expandedHeight: 120,
                  pinned: true,
                  elevation: 0,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      'Workouts',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                    expandedTitleScale: 1.3,
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () {
                        // Open search
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.filter_list),
                      onPressed: () {
                        // Open filters
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
                
                // Weekly Calendar
                SliverToBoxAdapter(
                  child: _buildWeeklyCalendar(),
                ),
                
                // Today's Workout
                SliverToBoxAdapter(
                  child: _buildTodaysWorkout(),
                ),
                
                // Current Plan Overview
                SliverToBoxAdapter(
                  child: _buildPlanOverview(),
                ),
                
                // Recent Workouts
                SliverToBoxAdapter(
                  child: _buildRecentWorkouts(),
                ),
                
                // Exercise Library
                SliverToBoxAdapter(
                  child: _buildExerciseLibrary(),
                ),
                
                // Bottom Padding for NavBar
                const SliverToBoxAdapter(
                  child: SizedBox(height: 80),
                ),
              ],
            ),
          ),
          
          // Bottom Navigation Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomNavBar(
              currentIndex: _selectedIndex,
              onTap: (index) {
                if (index == 4) {
                  // Navigate to Chat screen
                  Navigator.of(context).pushNamed('/chat');
                } else if (index == 0) {
                  // Navigate to Home screen
                  Navigator.of(context).pushReplacementNamed('/home');
                } else {
                  setState(() {
                    _selectedIndex = index;
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildWeeklyCalendar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly Schedule',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Container(
            height: 100,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: AppTheme.cardDecoration(),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 7,
              itemBuilder: (context, index) {
                final isSelected = index == _selectedDay;
                final hasWorkout = _workoutTypes[index] != 'Rest';
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDay = index;
                    });
                  },
                  child: Container(
                    width: 60,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? AppTheme.primaryColor.withOpacity(0.2) 
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? Border.all(color: AppTheme.primaryColor, width: 2)
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _weekdays[index],
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: hasWorkout
                                ? (isSelected ? AppTheme.primaryColor : AppTheme.cardColor)
                                : Colors.transparent,
                          ),
                          child: Center(
                            child: hasWorkout
                                ? Icon(
                                    Icons.fitness_center,
                                    size: 16,
                                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                                  )
                                : Icon(
                                    Icons.hotel,
                                    size: 16,
                                    color: AppTheme.textSecondary,
                                  ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _workoutTypes[index],
                          style: TextStyle(
                            fontSize: 10,
                            color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTodaysWorkout() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today\'s Workout',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.fitness_center,
                        color: AppTheme.primaryColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Upper Body Strength',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            '8 exercises · 45 minutes · Intermediate',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildWorkoutInfoChip(Icons.timer, '45 min'),
                    _buildWorkoutInfoChip(Icons.whatshot, '320 cal'),
                    _buildWorkoutInfoChip(Icons.fitness_center, 'Weights'),
                  ],
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () {
                    // Start workout
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('START WORKOUT'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
  
  Widget _buildWorkoutInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface2,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPlanOverview() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Plan',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AppTheme.cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Muscle Builder Pro',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Focus: Strength & Hypertrophy',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: 0.35,
                    backgroundColor: AppTheme.surface1,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Week 3 of 8',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () {
                    // View full plan
                  },
                  child: const Text('VIEW FULL PLAN'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 40),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRecentWorkouts() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Workouts',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextButton(
                onPressed: () {
                  // View all history
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildRecentWorkoutCard('Lower Body', 'Monday', '32 min', '4 exercises'),
          const SizedBox(height: 12),
          _buildRecentWorkoutCard('Push Day', 'Saturday', '45 min', '6 exercises'),
        ],
      ),
    );
  }
  
  Widget _buildRecentWorkoutCard(String title, String day, String duration, String exercises) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(
                Icons.fitness_center,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  day,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                duration,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                exercises,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildExerciseLibrary() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Exercise Library',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextButton(
                onPressed: () {
                  // View all exercises
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildExerciseCategory('Chest', 'assets/icons/chest.png'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildExerciseCategory('Back', 'assets/icons/back.png'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildExerciseCategory('Legs', 'assets/icons/legs.png'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildExerciseCategory('Arms', 'assets/icons/arms.png'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildExerciseCategory('Core', 'assets/icons/core.png'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildExerciseCategory('Cardio', 'assets/icons/cardio.png'),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildExerciseCategory(String name, String iconPath) {
    return GestureDetector(
      onTap: () {
        // Navigate to category
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.cardDecoration(),
        child: Column(
          children: [
            // Since we may not have the actual assets, we'll use an Icon instead
            Icon(
              Icons.fitness_center,
              color: AppTheme.primaryColor,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
} 