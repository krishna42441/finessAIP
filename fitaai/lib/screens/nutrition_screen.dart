import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_nav_bar.dart';
import 'dart:ui';
import 'package:flutter/rendering.dart';
import '../services/n8n_service.dart';
import '../services/gemini_service.dart';
import '../main.dart';
import '../widgets/edit_plan_dialog.dart';
import '../models/plan_models.dart';
import '../services/plan_service.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  int _selectedIndex = 2; // Nutrition tab is selected
  bool _isLoading = true;
  Map<String, dynamic>? _nutritionPlan;
  String? _errorMessage;
  bool _isGenerating = false;
  int _selectedDayIndex = 0;
  bool _hasNutritionPlan = true;
  Map<String, dynamic>? _workoutPlan;
  
  // Add weekdays array like in the workout screen
  final List<String> _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  
  @override
  void initState() {
    super.initState();
    _loadNutritionPlan();
  }
  
  /// Load the nutrition plan from the database
  Future<void> _loadNutritionPlan() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get user ID
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        setState(() {
          _isLoading = false;
          _hasNutritionPlan = false;
        });
        return;
      }
      
      // Load nutrition plan
      final nutritionPlan = await PlanService.getNutritionPlan(userId);
      
      // Load workout plan to get workout information
      final workoutPlan = await PlanService.getWorkoutPlan(userId);
      
      setState(() {
        // Convert to Map<String, dynamic> for easier access
        _nutritionPlan = nutritionPlan?.toDbJson();
        _workoutPlan = workoutPlan?.toDbJson();
        _hasNutritionPlan = nutritionPlan != null;
        _isLoading = false;
        
        // Set day to today if not already set
        if (_selectedDayIndex == 0 && _nutritionPlan != null) {
          final now = DateTime.now();
          // Convert from 1-7 day of week to 0-6 index
          _selectedDayIndex = now.weekday - 1;
        }
      });
    } catch (e) {
      debugPrint('Error loading nutrition plan: $e');
      setState(() {
        _isLoading = false;
        _hasNutritionPlan = false;
      });
    }
  }

  // Find the index of today's day in the nutrition plan
  int _findTodayIndex(Map<String, dynamic>? plan) {
    if (plan == null || !plan.containsKey('days') || plan['days'] == null) {
      return 0; // Default to first day if no plan or days
    }
    
    final today = DateTime.now().weekday; // 1 for Monday, 7 for Sunday
    
    for (int i = 0; i < plan['days'].length; i++) {
      if (plan['days'][i]['day_of_week'] == today) {
        return i;
      }
    }
    
    return 0; // Default to first day if today not found
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(_nutritionPlan?['plan_name'] ?? 'Nutrition Plan'),
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadNutritionPlan(),
            tooltip: 'Reload plan',
          ),
        ],
      ),
      body: _isLoading || _isGenerating
          ? const Center(child: CircularProgressIndicator())
          : _nutritionPlan == null
              ? _buildEmptyState()
              : _buildNutritionPlanView(),
      bottomNavigationBar: CustomNavBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == _selectedIndex) return;
          
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/home');
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/workout');
          } else if (index == 3) {
            Navigator.pushReplacementNamed(context, '/progress');
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
  
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant,
              size: 64,
              color: Colors.grey.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Nutrition Plan Found',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Generate a personalized nutrition plan from your profile',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/profile');
              },
              icon: const Icon(Icons.person),
              label: const Text('Go to Profile to Generate Plan'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNutritionPlanView() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          // Day selector
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 7,
              itemBuilder: (context, index) {
                return _buildDayChip(index + 1);
              },
            ),
          ),
          const SizedBox(height: 16),
          
          // Card with AI-generated nutrition plan
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline, 
                          color: AppTheme.accentColor, size: 24),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'AI-Generated Nutrition Plan',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Based on your profile and workout plan, here are your personalized nutrition targets for each day of the week.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDayNutrition(),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Hydration card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.water_drop_outlined, 
                          color: Colors.blue, size: 24),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Hydration',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildHydrationRecommendation(),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Micronutrients and tips card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.health_and_safety_outlined, 
                          color: Colors.green, size: 24),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Key Micronutrients & Tips',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildMicronutrientsAndTips(),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }
  
  Widget _buildDayChip(int dayOfWeek) {
    final isSelected = dayOfWeek == _selectedDayIndex + 1;
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final workoutType = _getWorkoutTypeForDay(dayOfWeek);
    final isWorkoutDay = workoutType != 'Rest' && workoutType != 'No workout';
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedDayIndex = dayOfWeek - 1;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: isSelected 
                ? AppTheme.primaryColor 
                : (isWorkoutDay ? Colors.grey[200] : Colors.white),
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(
              color: isSelected 
                  ? AppTheme.primaryColor 
                  : Colors.grey[300]!,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                dayNames[dayOfWeek - 1],
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (isWorkoutDay && !isSelected)
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildDayNutrition() {
    if (_nutritionPlan == null || !(_nutritionPlan!.containsKey('days'))) {
      return const Center(
        child: Text('No nutrition data available for this day'),
      );
    }

    // Find the selected day's nutrition data
    Map<String, dynamic>? dayData;
    for (var day in _nutritionPlan!['days']) {
      if (day['day_of_week'] == _selectedDayIndex + 1) {
        dayData = Map<String, dynamic>.from(day);
        break;
      }
    }

    if (dayData == null) {
      return const Center(
        child: Text('No nutrition data available for this day'),
      );
    }

    // Get the workout type for this day
    final workoutType = _getWorkoutTypeForDay(_selectedDayIndex + 1);
    final isWorkoutDay = workoutType != 'Rest' && workoutType != 'No workout';
    
    // Get nutrition data
    final totalCalories = dayData['total_calories'] ?? 0;
    final totalProtein = dayData['total_protein'] ?? 0;
    final totalCarbs = dayData['total_carbs'] ?? 0;
    final totalFat = dayData['total_fat'] ?? 0;
    final mealTiming = dayData['meal_timing_recommendation'] ?? 'No specific recommendations';
    final specialRecommendations = dayData['special_recommendations'] ?? '';

    // Calculate percentages for macros
    final totalMacroGrams = totalProtein + totalCarbs + totalFat;
    final proteinPct = totalMacroGrams > 0 ? (totalProtein / totalMacroGrams * 100).round() : 0;
    final carbsPct = totalMacroGrams > 0 ? (totalCarbs / totalMacroGrams * 100).round() : 0;
    final fatPct = totalMacroGrams > 0 ? (totalFat / totalMacroGrams * 100).round() : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day title with workout type
        Row(
          children: [
            Text(
              _getDayName(_selectedDayIndex + 1),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isWorkoutDay ? AppTheme.accentColor.withOpacity(0.2) : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                workoutType,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isWorkoutDay ? AppTheme.accentColor : Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Calories target
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total Daily Calories',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.textColor,
              ),
            ),
            Text(
              '$totalCalories kcal',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.accentColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Macronutrients
        Text(
          'Macronutrients',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppTheme.textColor,
          ),
        ),
        const SizedBox(height: 8),
        
        // Protein
        Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.red[400],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Protein',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textColor,
                ),
              ),
            ),
            Text(
              '$totalProtein g ($proteinPct%)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        
        // Carbs
        Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.blue[400],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Carbohydrates',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textColor,
                ),
              ),
            ),
            Text(
              '$totalCarbs g ($carbsPct%)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        
        // Fat
        Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.yellow[700],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Fat',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textColor,
                ),
              ),
            ),
            Text(
              '$totalFat g ($fatPct%)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textColor,
              ),
            ),
          ],
        ),
        
        // Macro distribution visual
        const SizedBox(height: 12),
        Container(
          height: 16,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.hardEdge,
          child: Row(
            children: [
              Expanded(
                flex: proteinPct,
                child: Container(color: Colors.red[400]),
              ),
              Expanded(
                flex: carbsPct,
                child: Container(color: Colors.blue[400]),
              ),
              Expanded(
                flex: fatPct,
                child: Container(color: Colors.yellow[700]),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Meal timing recommendation
        Text(
          'Meal Timing',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppTheme.textColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          mealTiming,
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textColor,
          ),
        ),
        
        // Special recommendation if available
        if (specialRecommendations.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Special Recommendations',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            specialRecommendations,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textColor,
            ),
          ),
        ],
      ],
    );
  }
  
  Widget _buildHydrationRecommendation() {
    if (_nutritionPlan == null || !(_nutritionPlan!.containsKey('days'))) {
      return const Text('No hydration data available');
    }

    // Find the selected day's nutrition data
    Map<String, dynamic>? dayData;
    for (var day in _nutritionPlan!['days']) {
      if (day['day_of_week'] == _selectedDayIndex + 1) {
        dayData = Map<String, dynamic>.from(day);
        break;
      }
    }

    if (dayData == null) {
      return const Text('No hydration data available');
    }

    final hydrationNeeds = dayData['hydration_needs'] ?? '2.5-3 liters';
    final workoutIntensity = dayData['workout_intensity'] ?? 'Medium';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.water_drop, color: Colors.blue, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Recommended water intake: $hydrationNeeds',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          workoutIntensity == 'High'
              ? 'Ensure proper hydration before, during, and after your high-intensity workout. Consider adding electrolytes on heavy training days.'
              : (workoutIntensity == 'Medium-High' 
                  ? 'Drink water throughout the day, with extra fluid intake around your workout session.'
                  : 'Maintain consistent water intake throughout the day.'),
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
  
  Widget _buildMicronutrientsAndTips() {
    if (_nutritionPlan == null || !(_nutritionPlan!.containsKey('days'))) {
      return const Text('No micronutrient data available');
    }

    // Find the selected day's nutrition data
    Map<String, dynamic>? dayData;
    for (var day in _nutritionPlan!['days']) {
      if (day['day_of_week'] == _selectedDayIndex + 1) {
        dayData = Map<String, dynamic>.from(day);
        break;
      }
    }

    if (dayData == null) {
      return const Text('No micronutrient data available');
    }

    final keyMicronutrients = dayData['key_micronutrients'] ?? [];
    final workoutType = _getWorkoutTypeForDay(_selectedDayIndex + 1);
    
    // Default tips based on workout type
    String nutritionTip = '';
    if (workoutType.contains('Strength') || workoutType.contains('Push') || 
        workoutType.contains('Pull') || workoutType.contains('Legs')) {
      nutritionTip = 'Focus on protein consumption and carb timing for optimal muscle recovery.';
    } else if (workoutType.contains('Cardio') || workoutType.contains('HIIT')) {
      nutritionTip = 'Prioritize carbohydrates for energy and rapid glycogen replenishment post-workout.';
    } else if (workoutType.contains('Rest')) {
      nutritionTip = 'Lower your carbohydrate intake slightly on rest days while maintaining protein levels.';
    } else {
      nutritionTip = 'Balance all macronutrients for optimal energy and recovery.';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Micronutrients
        Text(
          'Key Micronutrients to Focus On:',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppTheme.textColor,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (keyMicronutrients is List && keyMicronutrients.isNotEmpty)
              ...keyMicronutrients.map((nutrient) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green[300]!, width: 1),
                    ),
                    child: Text(
                      nutrient.toString(),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.green[800],
                      ),
                    ),
                  ))
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[300]!, width: 1),
                ),
                child: Text(
                  'General vitamins & minerals',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Workout-specific nutrition tip
        Text(
          'Nutrition Tip for ${workoutType != 'Rest' ? workoutType : 'Rest Day'}:',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppTheme.textColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          nutritionTip,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
  
  String _getDayName(int dayOfWeek) {
    switch (dayOfWeek) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      default: return 'Unknown';
    }
  }
  
  String _getWorkoutTypeForDay(int dayOfWeek) {
    if (_nutritionPlan == null || 
        _nutritionPlan!['workout_days'] == null ||
        (_nutritionPlan!['workout_days'] as List).isEmpty) {
      return 'No workout';
    }
    
    // Find the workout for this day
    for (var day in _nutritionPlan!['workout_days']) {
      if (day['day_of_week'] == dayOfWeek) {
        return day['workout_type'] ?? 'Rest';
      }
    }
    
    return 'Rest';
  }
} 