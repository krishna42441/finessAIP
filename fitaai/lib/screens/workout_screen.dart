import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_nav_bar.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui';
import '../services/n8n_service.dart';
import '../services/gemini_service.dart';
import '../main.dart';
import '../widgets/edit_plan_dialog.dart';
import '../models/plan_models.dart';
import '../services/plan_service.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  int _selectedIndex = 1; // Workout tab is selected
  int _selectedDay = DateTime.now().weekday - 1;
  bool _isLoading = true;
  Map<String, dynamic>? _workoutPlan;
  String? _errorMessage;
  
  final List<String> _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  List<String> _workoutTypes = ['Rest', 'Rest', 'Rest', 'Rest', 'Rest', 'Rest', 'Rest'];
  
  @override
  void initState() {
    super.initState();
    _loadWorkoutPlan();
  }
  
  Future<void> _loadWorkoutPlan() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        _errorMessage = 'User not authenticated';
      });
      
      return;
    }
    
    try {
      // Use the new PlanService
      final workoutPlan = await PlanService.getWorkoutPlan(userId);
      
      if (!mounted) return;
      
      if (workoutPlan == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No workout plan found. Go to your profile to generate one.';
        });
        return;
      }
      
      setState(() {
        // Convert the structured workout plan to the format expected by the UI
        _workoutPlan = workoutPlan.toDbJson();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading workout plan: $e');
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load workout plan: $e';
      });
    }
  }
  
  Map<String, dynamic>? _getCurrentDayWorkout() {
    if (_workoutPlan == null || _workoutPlan!['days'] == null) return null;
    
    final days = _workoutPlan!['days'] as List;
    for (var day in days) {
      final dayOfWeek = day['day_of_week'] as int;
      if (dayOfWeek == _selectedDay + 1) {
        return Map<String, dynamic>.from(day);
      }
    }
    
    return null;
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(_workoutPlan?['plan_name'] ?? 'Workout Plan'),
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadWorkoutPlan(),
            tooltip: 'Reload plan',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : _buildWorkoutPlanView(),
      bottomNavigationBar: CustomNavBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == _selectedIndex) return;
          
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/home');
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, '/nutrition');
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
  
  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center,
              size: 64,
              color: Colors.grey.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Workout Plan Not Available',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
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
  
  Widget _buildWorkoutPlanView() {
    return Column(
      children: [
        // AI Message Card
        if (_workoutPlan != null && _workoutPlan!['is_generated'] == true)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              color: AppTheme.primaryColor.withOpacity(0.1),
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
                        Icon(
                          Icons.auto_awesome,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'AI-Generated Workout Plan',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'I\'ve created a personalized workout plan based on your goals and preferences. Feel free to edit any exercise or details to better match your needs!',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        
        // Day selector
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: SizedBox(
            height: 64,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _weekdays.length,
              itemBuilder: (context, index) {
                final workoutType = _workoutTypes[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _buildDayChip(index, _weekdays[index], workoutType),
                );
              },
            ),
          ),
        ),
        
        // Divider
        const Divider(height: 1),
        
        // Workout content
        Expanded(
          child: _buildDayWorkout(_getCurrentDayWorkout()),
        ),
      ],
    );
  }
  
  Widget _buildDayChip(int dayIndex, String dayName, String workoutType) {
    final isSelected = _selectedDay == dayIndex;
    final isToday = DateTime.now().weekday - 1 == dayIndex;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedDay = dayIndex;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 80,
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
                workoutType,
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
  
  Widget _buildDayWorkout(Map<String, dynamic>? dayWorkout) {
    if (dayWorkout == null) {
      return Center(
        child: Text(
          'Rest Day',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 18,
          ),
        ),
      );
    }

    final exercises = dayWorkout['exercises'] as List? ?? [];
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            onTap: () => _showEditExerciseDialog(exercise),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          exercise['exercise_name'] ?? 'Exercise',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showEditExerciseDialog(exercise),
                        tooltip: 'Edit exercise',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildExerciseDetail(
                        Icons.repeat,
                        'Sets',
                        exercise['sets']?.toString() ?? '0',
                      ),
                      const SizedBox(width: 24),
                      _buildExerciseDetail(
                        Icons.fitness_center,
                        'Reps',
                        exercise['reps']?.toString() ?? '0',
                      ),
                    ],
                  ),
                  if (exercise['notes']?.isNotEmpty == true) ...[
                    const SizedBox(height: 8),
                    Text(
                      exercise['notes'],
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildExerciseDetail(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppTheme.textSecondary,
        ),
        const SizedBox(width: 4),
        Text(
          '$label: $value',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
  
  void _showEditExerciseDialog(Map<String, dynamic> exercise) {
    showDialog(
      context: context,
      builder: (context) => EditPlanDialog(
        plan: {'exercise': exercise},
        isWorkout: true,
        onSave: (editedPlan) async {
          try {
            final editedExercise = editedPlan['exercise'];
            await supabase
                .from('workout_exercises')
                .update({
                  'exercise_name': editedExercise['exercise_name'],
                  'sets': editedExercise['sets'],
                  'reps': editedExercise['reps'],
                  'notes': editedExercise['notes'],
                })
                .eq('id', exercise['id']);
            
            // Refresh the workout plan
            _loadWorkoutPlan();
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Exercise updated successfully'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error updating exercise: $e'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }
} 