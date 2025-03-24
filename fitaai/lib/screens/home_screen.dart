import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_nav_bar.dart';
import '../widgets/ui_components.dart';
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

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
                      'Dashboard',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                    expandedTitleScale: 1.3,
                  ),
                  actions: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                      child: IconButton(
                        icon: const Icon(Icons.person, color: AppTheme.primaryColor),
                        onPressed: () {
                          // Navigate to profile
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                ),
                
                // Daily Progress
                SliverToBoxAdapter(
                  child: _buildDailyProgress(),
                ),
                
                // Today's Plan
                SliverToBoxAdapter(
                  child: _buildTodaysPlan(),
                ),
                
                // Progress Overview
                SliverToBoxAdapter(
                  child: _buildProgressOverview(),
                ),
                
                // AI Insights
                SliverToBoxAdapter(
                  child: _buildAIInsights(),
                ),
                
                // Quick Actions
                SliverToBoxAdapter(
                  child: _buildQuickActions(),
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
                } else if (index == 1) {
                  // Navigate to Workout screen
                  Navigator.of(context).pushReplacementNamed('/workout');
                } else if (index == 2) {
                  // Navigate to Nutrition screen
                  Navigator.of(context).pushReplacementNamed('/nutrition');
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
  
  Widget _buildDailyProgress() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Progress',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildProgressCircle(
                  'Calories', 
                  0.65, 
                  '1,300/2,000',
                  AppTheme.primaryColor
                ),
              ),
              Expanded(
                child: _buildProgressCircle(
                  'Protein', 
                  0.72, 
                  '72g/100g',
                  AppTheme.secondaryColor
                ),
              ),
              Expanded(
                child: _buildProgressCircle(
                  'Water', 
                  0.45, 
                  '900/2000ml',
                  Colors.blue
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildProgressCircle(String label, double progress, String text, Color color) {
    return Column(
      children: [
        SizedBox(
          height: 100,
          width: 100,
          child: Stack(
            children: [
              SizedBox(
                height: 100,
                width: 100,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 10,
                  backgroundColor: AppTheme.cardColor,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      progress == 0 ? '0%' : '${(progress * 100).toInt()}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      text,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
  
  Widget _buildTodaysPlan() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today\'s Plan',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          _buildPlanCard(
            icon: Icons.fitness_center,
            title: 'Upper Body Workout',
            subtitle: '4:00 PM · 45 minutes',
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: 12),
          _buildPlanCard(
            icon: Icons.restaurant,
            title: 'Nutrition Target',
            subtitle: '2000 kcal, 130g protein, 65g fat',
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          _buildPlanCard(
            icon: Icons.water_drop,
            title: 'Water Intake',
            subtitle: 'Target: 2000ml',
            color: Colors.blue,
            trailing: _buildWaterTracker(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
  
  Widget _buildPlanCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
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
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
  
  Widget _buildWaterTracker() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
          onPressed: () {
            // Add water
          },
        ),
      ],
    );
  }
  
  Widget _buildProgressOverview() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progress Overview',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AppTheme.cardDecoration(),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildTrendCard(
                        title: 'Weight',
                        value: '72 kg',
                        trend: '-0.5 kg',
                        isPositive: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTrendCard(
                        title: 'Workout Completion',
                        value: '85%',
                        trend: '+10%',
                        isPositive: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildStreakCalendar(),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTrendCard({
    required String title,
    required String value,
    required String trend,
    required bool isPositive,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isPositive ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                    color: isPositive ? Colors.green : Colors.red,
                    size: 12,
                  ),
                  Text(
                    trend,
                    style: TextStyle(
                      color: isPositive ? Colors.green : Colors.red,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildStreakCalendar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Workout Streak',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (index) {
            bool isActive = index < 5;
            String day = ['M', 'T', 'W', 'T', 'F', 'S', 'S'][index];
            return Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isActive ? AppTheme.primaryColor : AppTheme.cardColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      day,
                      style: TextStyle(
                        color: isActive ? Colors.white : AppTheme.textSecondary,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
  
  Widget _buildAIInsights() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI Insights',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryColor.withOpacity(0.8),
                  AppTheme.secondaryColor.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Personalized Tip',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Based on your recent workouts, increasing your protein intake by 20g daily could help accelerate muscle recovery and growth.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      // Show more details
                    },
                    icon: const Icon(Icons.arrow_forward, color: Colors.white),
                    label: const Text(
                      'Learn More',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.monitor_weight_outlined,
                  label: 'Log Weight',
                  color: Colors.orange,
                  onTap: () {
                    // Log weight
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.restaurant_outlined,
                  label: 'Log Food',
                  color: Colors.green,
                  onTap: () {
                    // Log food
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.fitness_center_outlined,
                  label: 'Start Workout',
                  color: AppTheme.primaryColor,
                  onTap: () {
                    // Start workout
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.chat_bubble_outline,
                  label: 'Chat with AI',
                  color: AppTheme.secondaryColor,
                  onTap: () {
                    Navigator.of(context).pushNamed('/chat');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 