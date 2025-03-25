import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/logging_service.dart';
import '../widgets/quick_log_widgets.dart';
import '../main.dart';

class DailyLogScreen extends StatefulWidget {
  const DailyLogScreen({super.key});

  @override
  State<DailyLogScreen> createState() => _DailyLogScreenState();
}

class _DailyLogScreenState extends State<DailyLogScreen> {
  // User ID
  String? userId;
  
  // Selected date (default to today)
  late DateTime selectedDate;
  
  // Data
  List<WeightLogEntry> weightLogs = [];
  List<WaterLogEntry> waterLogs = [];
  List<WorkoutLogEntry> workoutLogs = [];
  List<NutritionLogEntry> nutritionLogs = [];
  
  // Loading state
  bool isLoading = true;
  
  // Total water intake for the day
  int totalWaterIntake = 0;
  
  // Nutrition summary
  NutritionSummary? nutritionSummary;
  
  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    userId = supabase.auth.currentUser?.id;
    
    _loadData();
  }
  
  Future<void> _loadData() async {
    if (userId == null) {
      setState(() => isLoading = false);
      return;
    }
    
    setState(() => isLoading = true);
    
    try {
      // Get start and end of selected day
      final startOfDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      // Load weight logs
      weightLogs = await LoggingService.getWeightLogs(
        userId: userId!,
        startDate: startOfDay,
        endDate: endOfDay,
      );
      
      // Load water logs
      waterLogs = await LoggingService.getWaterLogs(
        userId: userId!,
        startDate: startOfDay,
        endDate: endOfDay,
      );
      
      // Calculate total water intake
      totalWaterIntake = waterLogs.fold<int>(0, (sum, log) => sum + log.amountMl);
      
      // Load workout logs
      workoutLogs = await LoggingService.getWorkoutLogs(
        userId: userId!,
        startDate: startOfDay,
        endDate: endOfDay,
      );
      
      // Load nutrition logs
      nutritionLogs = await LoggingService.getNutritionLogs(
        userId: userId!,
        startDate: startOfDay,
        endDate: endOfDay,
      );
      
      // Get nutrition summary
      nutritionSummary = await LoggingService.getNutritionSummaryForDay(
        userId: userId!,
        date: selectedDate,
      );
      
      setState(() => isLoading = false);
    } catch (e) {
      debugPrint('Error loading daily logs: $e');
      setState(() => isLoading = false);
    }
  }
  
  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: AppTheme.cardColor,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: AppTheme.cardColor,
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Daily Log'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.calendar_today),
            label: Text(
              DateFormat('MMM d, yyyy').format(selectedDate),
            ),
            onPressed: () => _selectDate(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: AppTheme.cardColor,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            builder: (context) => SingleChildScrollView(
              child: QuickLogWidget(
                onLogComplete: _loadData,
              ),
            ),
          );
        },
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Daily Summary Card
                  _buildDailySummaryCard(),
                  
                  const SizedBox(height: 16),
                  
                  // Weight Logs
                  _buildWeightLogsCard(),
                  
                  const SizedBox(height: 16),
                  
                  // Water Logs
                  _buildWaterLogsCard(),
                  
                  const SizedBox(height: 16),
                  
                  // Workout Logs
                  _buildWorkoutLogsCard(),
                  
                  const SizedBox(height: 16),
                  
                  // Nutrition Logs
                  _buildNutritionLogsCard(),
                  
                  // Extra space at bottom for FAB
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }
  
  Widget _buildDailySummaryCard() {
    final bool isToday = selectedDate.year == DateTime.now().year &&
                         selectedDate.month == DateTime.now().month &&
                         selectedDate.day == DateTime.now().day;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isToday ? 'Today\'s Summary' : 'Day Summary',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    icon: Icons.monitor_weight,
                    label: 'Weight',
                    value: weightLogs.isNotEmpty
                        ? '${weightLogs.first.weight} kg'
                        : '---',
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    icon: Icons.water_drop,
                    label: 'Water',
                    value: '${(totalWaterIntake / 1000).toStringAsFixed(1)} L',
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    icon: Icons.fitness_center,
                    label: 'Workouts',
                    value: '${workoutLogs.length}',
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    icon: Icons.restaurant,
                    label: 'Calories',
                    value: nutritionSummary != null
                        ? '${nutritionSummary!.totalCalories}'
                        : '---',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Card(
      elevation: 0,
      color: AppTheme.surfaceColor,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildWeightLogsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Weight',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: AppTheme.primaryColor),
                  onPressed: () {
                    // Show weight entry dialog
                  },
                ),
              ],
            ),
            
            if (weightLogs.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text('No weight logs for today'),
                ),
              )
            else
              ...weightLogs.map((log) => _buildWeightLogItem(log)).toList(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildWeightLogItem(WeightLogEntry log) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.monitor_weight,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${log.weight} kg',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (log.notes != null && log.notes!.isNotEmpty)
                  Text(
                    log.notes!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          Text(
            DateFormat('h:mm a').format(log.date),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
  
  Widget _buildWaterLogsCard() {
    final int targetWaterIntake = 2500; // ml, can be adjusted based on user profile
    final double progress = totalWaterIntake / targetWaterIntake;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Water Intake',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: AppTheme.primaryColor),
                  onPressed: () {
                    // Show water entry dialog
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Progress bar
            LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: AppTheme.cardColor,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            
            const SizedBox(height: 8),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(totalWaterIntake / 1000).toStringAsFixed(1)} L',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Goal: ${(targetWaterIntake / 1000).toStringAsFixed(1)} L',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            if (waterLogs.isEmpty)
              const Center(
                child: Text('No water logs for today'),
              )
            else
              Column(
                children: waterLogs.map((log) => _buildWaterLogItem(log)).toList(),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildWaterLogItem(WaterLogEntry log) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.water_drop,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${log.amountMl} ml',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            DateFormat('h:mm a').format(log.timestamp),
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildWorkoutLogsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Workouts',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: AppTheme.primaryColor),
                  onPressed: () {
                    // Show workout entry dialog
                  },
                ),
              ],
            ),
            
            if (workoutLogs.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text('No workout logs for today'),
                ),
              )
            else
              ...workoutLogs.map((log) => _buildWorkoutLogItem(log)).toList(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildWorkoutLogItem(WorkoutLogEntry log) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.fitness_center,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.workoutType,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${log.durationMinutes} min • ${log.caloriesBurned ?? 0} kcal',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            DateFormat('h:mm a').format(log.date),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
  
  Widget _buildNutritionLogsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Nutrition',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: AppTheme.primaryColor),
                  onPressed: () {
                    // Show nutrition entry dialog
                  },
                ),
              ],
            ),
            
            // Summary
            if (nutritionSummary != null && nutritionSummary!.totalCalories > 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildNutrientItem(
                            label: 'Calories',
                            value: '${nutritionSummary!.totalCalories}',
                            color: Colors.amber,
                          ),
                        ),
                        Expanded(
                          child: _buildNutrientItem(
                            label: 'Protein',
                            value: '${nutritionSummary!.totalProteinG}g',
                            color: Colors.red,
                          ),
                        ),
                        Expanded(
                          child: _buildNutrientItem(
                            label: 'Carbs',
                            value: '${nutritionSummary!.totalCarbsG}g',
                            color: Colors.green,
                          ),
                        ),
                        Expanded(
                          child: _buildNutrientItem(
                            label: 'Fat',
                            value: '${nutritionSummary!.totalFatG}g',
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            
            if (nutritionLogs.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text('No nutrition logs for today'),
                ),
              )
            else
              ...nutritionLogs.map((log) => _buildNutritionLogItem(log)).toList(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNutrientItem({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNutritionLogItem(NutritionLogEntry log) {
    // Choose icon based on meal type
    IconData mealIcon;
    switch (log.mealType.toLowerCase()) {
      case 'breakfast':
        mealIcon = Icons.free_breakfast;
        break;
      case 'lunch':
        mealIcon = Icons.lunch_dining;
        break;
      case 'dinner':
        mealIcon = Icons.dinner_dining;
        break;
      case 'snack':
        mealIcon = Icons.cake;
        break;
      default:
        mealIcon = Icons.restaurant;
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              mealIcon,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${log.mealType}: ${log.foodName}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (log.calories != null)
                  Text(
                    '${log.calories} kcal • P: ${log.proteinG ?? 0}g • C: ${log.carbsG ?? 0}g • F: ${log.fatG ?? 0}g',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          Text(
            DateFormat('h:mm a').format(log.date),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
} 