import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_nav_bar.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui';
import '../services/n8n_service.dart';
import '../services/gemini_service.dart';
import '../main.dart';

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
    
    try {
      final userId = supabase.auth.currentUser!.id;
      
      // Try to get the latest workout plan
      try {
        final plan = await GeminiService.getLatestWorkoutPlan(userId);
        if (!mounted) return;
        
        setState(() {
          _workoutPlan = plan;
          _isLoading = false;
          
          // Update workout types based on the plan
          if (plan != null && plan['days'] != null) {
            final days = plan['days'] as List;
            _workoutTypes = List.filled(7, 'Rest');
            for (var day in days) {
              final dayOfWeek = day['day_of_week'] as int;
              if (dayOfWeek >= 1 && dayOfWeek <= 7) {
                _workoutTypes[dayOfWeek - 1] = day['focus_area'] ?? 'Workout';
              }
            }
          }
        });
      } catch (e) {
        // If no plan exists, generate one
        if (e.toString().contains('No workout plan found')) {
          _showGeneratePlanDialog();
        } else {
          throw e;
        }
      }
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load workout plan: ${e.toString()}';
      });
    }
  }
  
  void _showGeneratePlanDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('No Workout Plan Found'),
        content: const Text('Would you like to generate a personalized workout plan based on your profile?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isLoading = false;
                _errorMessage = 'No workout plan available';
              });
            },
            child: const Text('Not Now'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _generateWorkoutPlan();
            },
            child: const Text('Generate Plan'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _generateWorkoutPlan() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    final userId = supabase.auth.currentUser!.id;
    
    try {
      // Try to use GeminiService
      final result = await GeminiService.generatePlans(userId);
      
      if (!mounted) return;
      
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workout plan generated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        await _loadWorkoutPlan();
      } else {
        throw Exception(result['message']);
      }
    } catch (e) {
      debugPrint('Error with Gemini: $e');
      
      // If Gemini fails, try the mock data generation
      try {
        final mockResult = await N8NService.generateMockWorkoutPlan(userId);
        
        if (!mounted) return;
        
        if (mockResult != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Generated fallback workout plan'),
              backgroundColor: Colors.orange,
            ),
          );
          
          await _loadWorkoutPlan();
        }
      } catch (mockError) {
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate workout plan: $mockError'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
            onPressed: () => _generateWorkoutPlan(),
            tooltip: 'Generate new plan',
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
            FilledButton.icon(
              onPressed: _generateWorkoutPlan,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Generate Plan'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildWorkoutPlanView() {
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
              itemCount: 7,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _buildDayChip(index),
                );
              },
            ),
          ),
        ),
        
        // Divider
        const Divider(height: 1),
                
        // Workout content
        Expanded(
          child: _selectedDay >= 0 && _selectedDay < 7
              ? _buildDayWorkout()
              : const Center(child: Text('Select a day to view workouts')),
        ),
      ],
    );
  }
  
  Widget _buildDayChip(int dayIndex) {
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
                _weekdays[dayIndex],
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : null,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _workoutTypes[dayIndex],
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
  
  Widget _buildDayWorkout() {
    final currentDayWorkout = _getCurrentDayWorkout();
    
    if (currentDayWorkout == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.hotel,
                size: 64,
                color: Colors.grey.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Rest Day',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Take some time to recover and prepare for your next workout.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }
    
    final exercises = currentDayWorkout['exercises'] as List?;
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Day focus area
        Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.fitness_center,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      currentDayWorkout['focus_area'] ?? 'Workout',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                if (currentDayWorkout['description'] != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    currentDayWorkout['description'],
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Exercises
        if (exercises != null && exercises.isNotEmpty) ...[
          Text(
            'Exercises',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...exercises.map<Widget>((exercise) => _buildExerciseCard(exercise)).toList(),
        ] else ...[
          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'No exercises found for this day',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
  
  Widget _buildExerciseCard(dynamic exercise) {
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.fitness_center,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    exercise['exercise_name'] ?? exercise['name'] ?? 'Exercise',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildExerciseDetail('Sets', '${exercise['sets'] ?? '-'}'),
                _buildExerciseDetail('Reps', '${exercise['reps'] ?? '-'}'),
                _buildExerciseDetail('Rest', '${exercise['rest_seconds'] ?? 60}s'),
              ],
            ),
            if (exercise['instructions'] != null) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Instructions:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                exercise['instructions'] ?? 'No instructions provided',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildExerciseDetail(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
} 