import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_nav_bar.dart';
import 'dart:ui';
import 'package:flutter/rendering.dart';
import '../services/n8n_service.dart';
import '../services/gemini_service.dart';
import '../main.dart';

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
  
  // Add weekdays array like in the workout screen
  final List<String> _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  
  @override
  void initState() {
    super.initState();
    _loadNutritionPlan();
  }
  
  Future<void> _loadNutritionPlan() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });
    
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not authenticated'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    try {
      // Use GeminiService instead of N8NService
      final plan = await GeminiService.getLatestNutritionPlan(userId);
      
      if (!mounted) return;
      
      setState(() {
        _nutritionPlan = plan;
        // Set the initial selected day to today's weekday index
        _selectedDayIndex = _findTodayIndex(plan);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading nutrition plan: $e');
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load nutrition plan: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
  
  void _showGeneratePlanDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('No Nutrition Plan Found'),
        content: const Text('Would you like to generate a personalized nutrition plan based on your profile?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isGenerating = false;
                _errorMessage = 'No nutrition plan available';
              });
            },
            child: const Text('Not Now'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _generateNutritionPlan();
            },
            child: const Text('Generate Plan'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _generateNutritionPlan() async {
    if (!mounted) return;
    
    setState(() {
      _isGenerating = true;
    });
    
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      if (!mounted) return;
      
      setState(() {
        _isGenerating = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not authenticated'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    try {
      // Use GeminiService instead of N8NService
      final result = await GeminiService.generatePlans(userId);
      
      if (!mounted) return;
      
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nutrition plan generated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Reload nutrition plan
        await _loadNutritionPlan();
      } else {
        throw Exception(result['message']);
      }
    } catch (e) {
      debugPrint('Error with Gemini: $e');
      
      // If Gemini fails, try the mock data generation
      try {
        final mockResult = await N8NService.generateMockNutritionPlan(userId);
        
        if (!mounted) return;
        
        if (mockResult != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Generated fallback nutrition plan'),
              backgroundColor: Colors.orange,
            ),
          );
          
          await _loadNutritionPlan();
        }
      } catch (mockError) {
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate nutrition plan: $mockError'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
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
            onPressed: () => _generateNutritionPlan(),
            tooltip: 'Generate new plan',
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
              'Generate a personalized nutrition plan based on your profile',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _generateNutritionPlan,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Generate Plan'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNutritionPlanView() {
    return Column(
      children: [
        // Day selector
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: SizedBox(
            height: 64,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _nutritionPlan?['days']?.length ?? 0,
              itemBuilder: (context, index) {
                final day = _nutritionPlan?['days'][index];
                final dayNumber = day['day_of_week'];
                // Convert from 1-indexed (database) to 0-indexed (array)
                final weekdayIndex = dayNumber - 1;
                final dayName = weekdayIndex >= 0 && weekdayIndex < _weekdays.length 
                    ? _weekdays[weekdayIndex] 
                    : 'Day';
                
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _buildDayChip(index, dayName, dayNumber),
                );
              },
            ),
          ),
        ),
        
        // Divider
        const Divider(height: 1),
                
        // Nutrition content
        Expanded(
          child: _nutritionPlan?['days'] != null && 
                 _nutritionPlan!['days'].isNotEmpty &&
                 _selectedDayIndex < _nutritionPlan!['days'].length
              ? _buildDayNutrition(_nutritionPlan!['days'][_selectedDayIndex])
              : const Center(child: Text('No nutrition plan for this day')),
        ),
      ],
    );
  }
  
  Widget _buildDayChip(int dayIndex, String dayName, int dayNumber) {
    final isSelected = _selectedDayIndex == dayIndex;
    
    // Calculate today based on day_of_week like the workout screen
    // Weekday in DateTime is 1-7, where 1 is Monday and 7 is Sunday
    // day_of_week from database is also 1-7 with same mapping
    final isToday = DateTime.now().weekday == dayNumber;
    
    // Calculate date based on day number (similar to workout screen approach)
    final now = DateTime.now();
    final int daysToAdd = dayNumber - now.weekday;
    final dayDate = now.add(Duration(days: daysToAdd));
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedDayIndex = dayIndex;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 90,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primaryContainer
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isToday
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                dayName,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : null,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${dayDate.day}/${dayDate.month}',
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildDayNutrition(Map<String, dynamic> dayData) {
    final meals = dayData['meals'] as List?;
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Nutrition summary
        Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Summary',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNutrientSummary('Calories', '${dayData['total_calories'] ?? 0}', 'kcal'),
                    _buildNutrientSummary('Protein', '${dayData['total_protein'] ?? 0}', 'g'),
                    _buildNutrientSummary('Carbs', '${dayData['total_carbs'] ?? 0}', 'g'),
                    _buildNutrientSummary('Fat', '${dayData['total_fat'] ?? 0}', 'g'),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Macronutrient Breakdown
        Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Macronutrient Breakdown',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                _buildMacroProgressBar(
                  'Protein', 
                  dayData['total_protein'] ?? 0, 
                  (dayData['protein_goal'] ?? 150).toDouble(), 
                  Colors.red
                ),
                const SizedBox(height: 12),
                _buildMacroProgressBar(
                  'Carbs', 
                  dayData['total_carbs'] ?? 0, 
                  (dayData['carbs_goal'] ?? 250).toDouble(), 
                  Colors.green
                ),
                const SizedBox(height: 12),
                _buildMacroProgressBar(
                  'Fat', 
                  dayData['total_fat'] ?? 0, 
                  (dayData['fat_goal'] ?? 80).toDouble(), 
                  Colors.blue
                ),
                const SizedBox(height: 12),
                _buildMacroProgressBar(
                  'Fiber', 
                  dayData['total_fiber'] ?? 0, 
                  (dayData['fiber_goal'] ?? 35).toDouble(), 
                  Colors.brown
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Micronutrients
        Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Micronutrients',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildMicronutrientChip('Vitamin A', '${dayData['vitamin_a'] ?? 800} μg'),
                    _buildMicronutrientChip('Vitamin C', '${dayData['vitamin_c'] ?? 90} mg'),
                    _buildMicronutrientChip('Vitamin D', '${dayData['vitamin_d'] ?? 15} μg'),
                    _buildMicronutrientChip('Calcium', '${dayData['calcium'] ?? 1000} mg'),
                    _buildMicronutrientChip('Iron', '${dayData['iron'] ?? 18} mg'),
                    _buildMicronutrientChip('Potassium', '${dayData['potassium'] ?? 3500} mg'),
                    _buildMicronutrientChip('Magnesium', '${dayData['magnesium'] ?? 400} mg'),
                    _buildMicronutrientChip('Zinc', '${dayData['zinc'] ?? 11} mg'),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Meals
        if (meals != null && meals.isNotEmpty) ...[
          Text(
            'Meals',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...meals.map<Widget>((meal) => _buildMealCard(meal)).toList(),
        ] else ...[
          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'No meals found for this day',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
  
  Widget _buildNutrientSummary(String label, String value, String unit) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          unit,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
  
  Widget _buildMacroProgressBar(String label, num current, double goal, Color color) {
    final progress = (current / goal).clamp(0.0, 1.0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              '$current / ${goal.toInt()} g',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
  
  Widget _buildMicronutrientChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMealCard(Map<String, dynamic> meal) {
    final foods = meal['foods'] as List?;
    final mealType = meal['meal_type'] ?? 'Meal';
    final calories = meal['calories'] ?? 0;
    final protein = meal['protein'] ?? 0;
    final carbs = meal['carbs'] ?? 0;
    final fat = meal['fat'] ?? 0;
    
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getMealIcon(mealType),
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  mealType,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$calories kcal',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      'P: ${protein}g  C: ${carbs}g  F: ${fat}g',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
            if (foods != null && foods.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              ...foods.map<Widget>((food) => _buildFoodItem(food)).toList(),
            ],
          ],
        ),
      ),
    );
  }
  
  IconData _getMealIcon(String mealType) {
    switch (mealType) {
      case 'Breakfast':
        return Icons.breakfast_dining;
      case 'Lunch':
        return Icons.lunch_dining;
      case 'Dinner':
        return Icons.dinner_dining;
      case 'Snack':
        return Icons.cookie;
      default:
        return Icons.restaurant;
    }
  }
  
  Widget _buildFoodItem(Map<String, dynamic> food) {
    final foodName = food['food_name'] ?? food['name'] ?? 'Unknown Food';
    final servingSize = food['serving_size'] ?? food['amount'] ?? '';
    final calories = food['calories'] ?? 0;
    final protein = food['protein'] ?? 0;
    final carbs = food['carbs'] ?? 0;
    final fat = food['fat'] ?? 0;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                foodName.isNotEmpty ? foodName.substring(0, 1).toUpperCase() : '?',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  foodName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (servingSize.isNotEmpty)
                  Text(
                    servingSize,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$calories kcal',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                'P: ${protein}g  C: ${carbs}g  F: ${fat}g',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
} 