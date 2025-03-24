import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_nav_bar.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  int _selectedIndex = 2; // Nutrition tab is selected
  
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
                      'Nutrition',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                    expandedTitleScale: 1.3,
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () {
                        // Show calendar
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings),
                      onPressed: () {
                        // Show nutrition settings
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
                
                // Macro Progress
                SliverToBoxAdapter(
                  child: _buildMacroProgress(),
                ),
                
                // Meal Timeline
                SliverToBoxAdapter(
                  child: _buildMealTimeline(),
                ),
                
                // Water Intake
                SliverToBoxAdapter(
                  child: _buildWaterIntake(),
                ),
                
                // Quick Add Food
                SliverToBoxAdapter(
                  child: _buildQuickAddFood(),
                ),
                
                // Weekly Summary
                SliverToBoxAdapter(
                  child: _buildWeeklySummary(),
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
                } else if (index == 1) {
                  // Navigate to Workout screen
                  Navigator.of(context).pushReplacementNamed('/workout');
                } else {
                  setState(() {
                    _selectedIndex = index;
                  });
                }
              },
            ),
          ),
          
          // Floating Action Button for adding food
          Positioned(
            right: 16,
            bottom: 80,
            child: FloatingActionButton(
              onPressed: () {
                _showFoodLoggingOptions();
              },
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showFoodLoggingOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Log Food',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              _buildLoggingOption(
                icon: Icons.search,
                title: 'Search Food',
                subtitle: 'Search our food database',
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to food search
                },
              ),
              const SizedBox(height: 16),
              _buildLoggingOption(
                icon: Icons.camera_alt,
                title: 'Take Photo',
                subtitle: 'Identify food with AI',
                onTap: () {
                  Navigator.pop(context);
                  // Open camera
                },
              ),
              const SizedBox(height: 16),
              _buildLoggingOption(
                icon: Icons.qr_code_scanner,
                title: 'Scan Barcode',
                subtitle: 'Scan product barcode',
                onTap: () {
                  Navigator.pop(context);
                  // Open barcode scanner
                },
              ),
              const SizedBox(height: 16),
              _buildLoggingOption(
                icon: Icons.add_circle_outline,
                title: 'Create Custom',
                subtitle: 'Add a custom food item',
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to custom food form
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildLoggingOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: AppTheme.primaryColor,
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
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMacroProgress() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today\'s Nutrition',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.cardDecoration(),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Calories',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '1,450',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextSpan(
                                text: ' / 2,200',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        value: 0.66,
                        strokeWidth: 8,
                        backgroundColor: AppTheme.cardColor,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildMacronutrientProgress(
                        'Protein', 
                        '85g', 
                        '130g', 
                        0.65, 
                        Colors.blue,
                      ),
                    ),
                    Expanded(
                      child: _buildMacronutrientProgress(
                        'Carbs', 
                        '180g', 
                        '220g', 
                        0.82, 
                        Colors.orange,
                      ),
                    ),
                    Expanded(
                      child: _buildMacronutrientProgress(
                        'Fat', 
                        '42g', 
                        '73g', 
                        0.57, 
                        Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMacronutrientProgress(
    String label, 
    String current, 
    String target, 
    double progress, 
    Color color,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 50,
          height: 50,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 6,
            backgroundColor: AppTheme.cardColor,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: current,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: '/$target',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildMealTimeline() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Meal Timeline',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          _buildMealCard(
            mealType: 'Breakfast',
            time: '7:30 AM',
            calories: 420,
            items: ['Greek Yogurt', 'Berries', 'Honey', 'Granola'],
            completed: true,
          ),
          _buildTimelineDivider(),
          _buildMealCard(
            mealType: 'Lunch',
            time: '12:30 PM',
            calories: 650,
            items: ['Grilled Chicken Salad', 'Quinoa', 'Olive Oil'],
            completed: true,
          ),
          _buildTimelineDivider(),
          _buildMealCard(
            mealType: 'Snack',
            time: '3:30 PM',
            calories: 180,
            items: ['Protein Shake', 'Almonds'],
            completed: true,
          ),
          _buildTimelineDivider(),
          _buildMealCard(
            mealType: 'Dinner',
            time: '7:00 PM',
            calories: 580,
            items: ['Salmon', 'Sweet Potato', 'Broccoli'],
            completed: false,
          ),
        ],
      ),
    );
  }
  
  Widget _buildTimelineDivider() {
    return Container(
      margin: const EdgeInsets.only(left: 20),
      height: 30,
      width: 2,
      color: AppTheme.primaryColor.withOpacity(0.3),
    );
  }
  
  Widget _buildMealCard({
    required String mealType,
    required String time,
    required int calories,
    required List<String> items,
    required bool completed,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: completed 
                ? AppTheme.primaryColor 
                : AppTheme.primaryColor.withOpacity(0.3),
          ),
          child: Center(
            child: Icon(
              completed ? Icons.check : Icons.restaurant,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: AppTheme.cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      mealType,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      time,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '$calories calories',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: items.map((item) => Chip(
                    label: Text(
                      item,
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: AppTheme.surface2,
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  )).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildWaterIntake() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Water Intake',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.cardDecoration(),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '1.2 / 2.5L',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '48% of daily goal',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: 0.48,
                              backgroundColor: AppTheme.surface1,
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                              minHeight: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Image.asset(
                        'assets/images/water_bottle.png',
                        height: 80,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.water_drop,
                            color: Colors.blue,
                            size: 80,
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildWaterButton('+100ml'),
                    _buildWaterButton('+200ml'),
                    _buildWaterButton('+300ml'),
                    _buildWaterButton('Custom'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildWaterButton(String label) {
    return ElevatedButton(
      onPressed: () {
        // Add water
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size.zero,
        textStyle: const TextStyle(fontSize: 12),
      ),
      child: Text(label),
    );
  }
  
  Widget _buildQuickAddFood() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Add',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Container(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildQuickAddCard('Protein Shake', '180 cal'),
                _buildQuickAddCard('Greek Yogurt', '120 cal'),
                _buildQuickAddCard('Chicken Breast', '165 cal'),
                _buildQuickAddCard('Banana', '105 cal'),
                _buildQuickAddCard('Oatmeal', '150 cal'),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuickAddCard(String food, String calories) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            food,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            calories,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Icon(
            Icons.add_circle,
            color: AppTheme.primaryColor,
            size: 20,
          ),
        ],
      ),
    );
  }
  
  Widget _buildWeeklySummary() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly Summary',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.cardDecoration(),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildWeeklyStat('Avg. Calories', '1,980'),
                    _buildWeeklyStat('Avg. Protein', '115g'),
                    _buildWeeklyStat('Avg. Carbs', '210g'),
                  ],
                ),
                const SizedBox(height: 24),
                // Bar chart would go here
                Container(
                  height: 150,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildBarChartColumn('M', 0.7),
                      _buildBarChartColumn('T', 0.85),
                      _buildBarChartColumn('W', 0.65),
                      _buildBarChartColumn('T', 0.9),
                      _buildBarChartColumn('F', 0.8),
                      _buildBarChartColumn('S', 0.6),
                      _buildBarChartColumn('S', 0.75),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () {
                    // View nutrition analysis
                  },
                  child: const Text('VIEW DETAILED ANALYSIS'),
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
  
  Widget _buildWeeklyStat(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
  
  Widget _buildBarChartColumn(String day, double height) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 30,
          height: 120 * height,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(4),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.primaryColor,
                AppTheme.secondaryColor,
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          day,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
} 