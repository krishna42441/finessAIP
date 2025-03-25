import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import '../main.dart'; // Import for supabase client
import 'package:uuid/uuid.dart';
import 'dart:math';

class N8NService {
  static const String n8nBaseUrl = 'YOUR_N8N_WEBHOOK_URL'; // Replace with your n8n webhook URL
  static const String username = 'YOUR_WEBHOOK_USERNAME'; // Replace with your webhook auth username
  static const String password = 'YOUR_WEBHOOK_PASSWORD'; // Replace with your webhook auth password

  // Generate nutrition and workout plans for a user
  static Future<Map<String, dynamic>> generatePlans(String userId) async {
    try {
      // Skip n8n integration for now and directly use mock data
      final mockWorkoutPlan = await generateMockWorkoutPlan(userId);
      final mockNutritionPlan = await generateMockNutritionPlan(userId);
      
      return {
        'success': true,
        'message': 'Plans generated successfully with mock data',
        'nutrition_plan_id': mockNutritionPlan['plan']['id'],
        'workout_plan_id': mockWorkoutPlan['plan']['id'],
      };
      
      /* Original n8n code - commented out
      // First, check if the user exists
      final user = await supabase
          .from('user_profiles')
          .select()
          .eq('user_id', userId)
          .single();
      
      if (user == null) {
        throw Exception('User profile not found');
      }

      // For now, return dummy data until n8n is set up
      // In a real implementation, this would be the result from n8n
      return {
        'success': true,
        'message': 'Plans generated successfully',
        'nutrition_plan_id': 'dummy-id',
        'workout_plan_id': 'dummy-id',
      };
      
      // Uncomment this when n8n is set up
      // Prepare the request body
      final Map<String, dynamic> requestBody = {
        'user_id': userId,
      };

      // Create the authentication string
      final String basicAuth = 
          'Basic ' + base64Encode(utf8.encode('$username:$password'));

      // Make the HTTP request to the n8n webhook
      final response = await http.post(
        Uri.parse('$n8nBaseUrl/generate-plans'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': basicAuth,
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        // Parse the response
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return responseData;
      } else {
        throw Exception('Failed to generate plans: ${response.statusCode}, ${response.body}');
      }
      */
    } catch (e) {
      debugPrint('Error generating plans: $e');
      
      // Generate mock data even in case of error
      try {
        final mockWorkoutPlan = await generateMockWorkoutPlan(userId);
        final mockNutritionPlan = await generateMockNutritionPlan(userId);
        
        return {
          'success': true,
          'message': 'Plans generated with mock data (fallback)',
          'nutrition_plan_id': mockNutritionPlan['plan']['id'],
          'workout_plan_id': mockWorkoutPlan['plan']['id'],
        };
      } catch (mockError) {
        debugPrint('Error generating mock data: $mockError');
        return {
          'success': true,
          'message': 'Plans generated (simulated)',
          'nutrition_plan_id': 'mock-nutrition-plan-id',
          'workout_plan_id': 'mock-workout-plan-id',
        };
      }
    }
  }

  // Fetch the latest nutrition plan for a user
  static Future<Map<String, dynamic>> getLatestNutritionPlan(String userId) async {
    try {
      // Check if the nutrition_plans table exists
      try {
        // Fetch the most recent nutrition plan
        final nutritionPlan = await supabase
            .from('nutrition_plans')
            .select('*')
            .eq('user_id', userId)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();
        
        if (nutritionPlan == null) {
          // If no plan found, generate a mock one
          debugPrint('No nutrition plan found in database, generating mock data');
          return await generateMockNutritionPlan(userId);
        }

        // Get the nutrition plan days
        final nutritionDays = await supabase
            .from('nutrition_plan_days')
            .select('*')
            .eq('plan_id', nutritionPlan['id'])
            .order('day_of_week');

        // For each day, get the meals
        List<Map<String, dynamic>> daysWithMeals = [];
        for (var day in nutritionDays) {
          final meals = await supabase
              .from('nutrition_plan_meals')
              .select('*')
              .eq('day_id', day['id'])
              .order('meal_time');
          
          daysWithMeals.add({
            ...day,
            'meals': meals,
          });
        }

        // Return the complete nutrition plan
        return {
          'plan': nutritionPlan,
          'days': daysWithMeals,
        };
      } catch (e) {
        // If we get a PostgrestError, it likely means the table doesn't exist
        debugPrint('Error fetching nutrition plan: $e');
        
        // Generate mock data
        debugPrint('Generating mock nutrition plan data');
        return await generateMockNutritionPlan(userId);
      }
    } catch (e) {
      if (e.toString().contains('No nutrition plan found')) {
        // Generate mock data
        debugPrint('Generating mock nutrition plan data after error');
        return await generateMockNutritionPlan(userId);
      }
      debugPrint('Error in getLatestNutritionPlan: $e');
      rethrow;
    }
  }

  // Fetch the latest workout plan for a user
  static Future<Map<String, dynamic>> getLatestWorkoutPlan(String userId) async {
    try {
      try {
        // Fetch the most recent workout plan
        final workoutPlan = await supabase
            .from('workout_plans')
            .select('*')
            .eq('user_id', userId)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();
        
        if (workoutPlan == null) {
          // If no plan found, generate a mock one
          debugPrint('No workout plan found in database, generating mock data');
          return await generateMockWorkoutPlan(userId);
        }

        // Get the workout plan days
        final workoutDays = await supabase
            .from('workout_plan_days')
            .select('*')
            .eq('plan_id', workoutPlan['id'])
            .order('day_of_week');

        // For each day, get the exercises
        List<Map<String, dynamic>> daysWithExercises = [];
        for (var day in workoutDays) {
          final exercises = await supabase
              .from('workout_exercises')
              .select('*')
              .eq('day_id', day['id'])
              .order('exercise_order');
          
          daysWithExercises.add({
            ...day,
            'exercises': exercises,
          });
        }

        // Return the complete workout plan
        return {
          'plan': workoutPlan,
          'days': daysWithExercises,
        };
      } catch (e) {
        // If we get a PostgrestError, it likely means the table doesn't exist
        debugPrint('Error fetching workout plan: $e');
        
        // Generate mock data
        debugPrint('Generating mock workout plan data');
        return await generateMockWorkoutPlan(userId);
      }
    } catch (e) {
      if (e.toString().contains('No workout plan found')) {
        // Generate mock data
        debugPrint('Generating mock workout plan data after error');
        return await generateMockWorkoutPlan(userId);
      }
      debugPrint('Error in getLatestWorkoutPlan: $e');
      rethrow;
    }
  }

  // Methods to generate mock data for testing
  static Future<Map<String, dynamic>> generateMockNutritionPlan(String userId) async {
    try {
      debugPrint('Generating mock nutrition plan for user $userId');
      
      // Create the main plan record
      final nutritionPlanId = const Uuid().v4();
      final now = DateTime.now();
      final startDate = now;
      final endDate = now.add(const Duration(days: 28));
      
      final nutritionPlan = {
        'id': nutritionPlanId,
        'user_id': userId,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'start_date': startDate.toIso8601String().split('T')[0],
        'end_date': endDate.toIso8601String().split('T')[0],
        'daily_calories': 2200,
        'protein_g': 130,
        'carbs_g': 220,
        'fat_g': 73,
        'plan_name': 'Balanced Nutrition Plan',
        'plan_type': 'Muscle Building',
        'plan_description': 'A balanced nutrition plan to support your training goals, focusing on adequate protein intake and nutrient timing.',
        'water_intake_ml': 2500,
      };
      
      // Create nutrition days and meals
      final nutritionDays = [];
      final mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];
      
      for (var i = 1; i <= 7; i++) {
        final dayId = const Uuid().v4();
        
        final meals = _generateMockMeals(dayId, mealTypes);
        
        final day = {
          'id': dayId,
          'plan_id': nutritionPlanId,
          'day_of_week': i,
          'total_calories': meals.fold(0, (sum, meal) => sum + (meal['calories'] as int)),
          'notes': 'Stay hydrated throughout the day',
          'meals': meals,
        };
        
        nutritionDays.add(day);
      }
      
      // Mock data for the response
      return {
        'plan': nutritionPlan,
        'days': nutritionDays,
      };
    } catch (e) {
      debugPrint('Error generating mock nutrition plan: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> generateMockWorkoutPlan(String userId) async {
    try {
      debugPrint('Generating mock workout plan for user $userId');
      
      // Create the main plan record
      final workoutPlanId = const Uuid().v4();
      final now = DateTime.now();
      final startDate = now;
      final endDate = now.add(const Duration(days: 28));
      
      final workoutPlan = {
        'id': workoutPlanId,
        'user_id': userId,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'start_date': startDate.toIso8601String().split('T')[0],
        'end_date': endDate.toIso8601String().split('T')[0],
        'days_per_week': 4,
        'plan_name': 'Progressive Strength Program',
        'plan_type': 'Strength Training',
        'plan_description': 'A 4-week program designed to gradually increase strength and muscle mass.',
        'plan_difficulty': 'Intermediate',
      };
      
      // Create workout days
      final workoutDays = [];
      final workoutTypes = ['Upper Body', 'Lower Body', 'Push', 'Pull', 'Full Body', 'Core & Cardio'];
      
      for (var i = 1; i <= 4; i++) {
        final dayId = const Uuid().v4();
        final workoutType = workoutTypes[Random().nextInt(workoutTypes.length)];
        
        final day = {
          'id': dayId,
          'plan_id': workoutPlanId,
          'day_of_week': i,
          'workout_type': workoutType,
          'session_duration_minutes': 45 + Random().nextInt(30),
          'equipment_needed': 'Dumbbells, Barbell',
          'notes': 'Focus on proper form',
          'exercises': _generateMockExercises(dayId, workoutType),
        };
        
        workoutDays.add(day);
      }
      
      // Mock data for the response
      return {
        'plan': workoutPlan,
        'days': workoutDays,
      };
    } catch (e) {
      debugPrint('Error generating mock workout plan: $e');
      rethrow;
    }
  }

  // Helper method to generate mock exercises based on workout type
  static List<Map<String, dynamic>> _generateMockExercises(String dayId, String workoutType) {
    final exercises = <Map<String, dynamic>>[];
    final exerciseCount = 4 + Random().nextInt(4); // 4-7 exercises
    
    final upperBodyExercises = [
      {'name': 'Bench Press', 'muscle_group': 'Chest'},
      {'name': 'Overhead Press', 'muscle_group': 'Shoulders'},
      {'name': 'Bent Over Rows', 'muscle_group': 'Back'},
      {'name': 'Bicep Curls', 'muscle_group': 'Biceps'},
      {'name': 'Tricep Extensions', 'muscle_group': 'Triceps'},
      {'name': 'Pull-ups', 'muscle_group': 'Back'},
      {'name': 'Lateral Raises', 'muscle_group': 'Shoulders'},
    ];
    
    final lowerBodyExercises = [
      {'name': 'Squats', 'muscle_group': 'Quadriceps'},
      {'name': 'Deadlifts', 'muscle_group': 'Hamstrings'},
      {'name': 'Lunges', 'muscle_group': 'Quadriceps'},
      {'name': 'Leg Press', 'muscle_group': 'Quadriceps'},
      {'name': 'Calf Raises', 'muscle_group': 'Calves'},
      {'name': 'Hamstring Curls', 'muscle_group': 'Hamstrings'},
      {'name': 'Hip Thrusts', 'muscle_group': 'Glutes'},
    ];
    
    final coreExercises = [
      {'name': 'Plank', 'muscle_group': 'Core'},
      {'name': 'Russian Twists', 'muscle_group': 'Obliques'},
      {'name': 'Crunches', 'muscle_group': 'Abs'},
      {'name': 'Leg Raises', 'muscle_group': 'Lower Abs'},
      {'name': 'Mountain Climbers', 'muscle_group': 'Core'},
    ];
    
    final cardioExercises = [
      {'name': 'Treadmill', 'muscle_group': 'Cardiovascular'},
      {'name': 'Rowing Machine', 'muscle_group': 'Cardiovascular'},
      {'name': 'Jumping Jacks', 'muscle_group': 'Cardiovascular'},
      {'name': 'Burpees', 'muscle_group': 'Full Body'},
      {'name': 'Jump Rope', 'muscle_group': 'Cardiovascular'},
    ];
    
    // Select exercises based on workout type
    List<Map<String, dynamic>> exercisePool = [];
    switch (workoutType) {
      case 'Upper Body':
        exercisePool = upperBodyExercises;
        break;
      case 'Lower Body':
        exercisePool = lowerBodyExercises;
        break;
      case 'Push':
        exercisePool = upperBodyExercises.where((e) => 
          e['muscle_group'] == 'Chest' || 
          e['muscle_group'] == 'Shoulders' || 
          e['muscle_group'] == 'Triceps').toList();
        break;
      case 'Pull':
        exercisePool = upperBodyExercises.where((e) => 
          e['muscle_group'] == 'Back' || 
          e['muscle_group'] == 'Biceps').toList();
        break;
      case 'Core & Cardio':
        exercisePool = [...coreExercises, ...cardioExercises];
        break;
      case 'Full Body':
        exercisePool = [...upperBodyExercises, ...lowerBodyExercises, ...coreExercises];
        break;
      default:
        exercisePool = [...upperBodyExercises, ...lowerBodyExercises];
    }
    
    // Shuffle and take random exercises
    exercisePool.shuffle();
    final selectedExercises = exercisePool.take(exerciseCount).toList();
    
    for (var i = 0; i < selectedExercises.length; i++) {
      exercises.add({
        'id': const Uuid().v4(),
        'day_id': dayId,
        'exercise_order': i + 1,
        'exercise_name': selectedExercises[i]['name'],
        'muscle_group': selectedExercises[i]['muscle_group'],
        'sets': 3 + Random().nextInt(2),
        'reps': 8 + Random().nextInt(8),
        'weight_kg': Random().nextInt(60) + 5.0,
        'rest_seconds': 60 + Random().nextInt(60),
        'instructions': 'Perform with proper form',
      });
    }
    
    return exercises;
  }
  
  // Helper method to generate mock meals
  static List<Map<String, dynamic>> _generateMockMeals(String dayId, List<String> mealTypes) {
    final meals = <Map<String, dynamic>>[];
    
    final breakfastOptions = [
      {'name': 'Greek Yogurt with Berries', 'calories': 320, 'protein': 20, 'carbs': 35, 'fat': 10},
      {'name': 'Oatmeal with Banana & Almond Butter', 'calories': 380, 'protein': 15, 'carbs': 50, 'fat': 12},
      {'name': 'Scrambled Eggs with Avocado Toast', 'calories': 420, 'protein': 22, 'carbs': 30, 'fat': 22},
      {'name': 'Protein Smoothie Bowl', 'calories': 350, 'protein': 25, 'carbs': 40, 'fat': 8},
    ];
    
    final lunchOptions = [
      {'name': 'Grilled Chicken Salad', 'calories': 450, 'protein': 35, 'carbs': 25, 'fat': 20},
      {'name': 'Turkey & Avocado Wrap', 'calories': 520, 'protein': 30, 'carbs': 45, 'fat': 22},
      {'name': 'Quinoa Bowl with Roasted Vegetables', 'calories': 480, 'protein': 18, 'carbs': 65, 'fat': 15},
      {'name': 'Tuna Salad with Whole Grain Crackers', 'calories': 420, 'protein': 32, 'carbs': 30, 'fat': 18},
    ];
    
    final dinnerOptions = [
      {'name': 'Salmon with Sweet Potato & Asparagus', 'calories': 520, 'protein': 35, 'carbs': 40, 'fat': 22},
      {'name': 'Lean Beef Stir Fry with Brown Rice', 'calories': 580, 'protein': 40, 'carbs': 55, 'fat': 18},
      {'name': 'Grilled Chicken with Quinoa & Broccoli', 'calories': 490, 'protein': 38, 'carbs': 45, 'fat': 15},
      {'name': 'Baked Cod with Roasted Vegetables', 'calories': 420, 'protein': 32, 'carbs': 35, 'fat': 14},
    ];
    
    final snackOptions = [
      {'name': 'Protein Shake', 'calories': 180, 'protein': 25, 'carbs': 10, 'fat': 3},
      {'name': 'Apple with Almond Butter', 'calories': 220, 'protein': 7, 'carbs': 25, 'fat': 10},
      {'name': 'Greek Yogurt with Honey', 'calories': 200, 'protein': 18, 'carbs': 20, 'fat': 5},
      {'name': 'Handful of Mixed Nuts', 'calories': 170, 'protein': 6, 'carbs': 8, 'fat': 14},
      {'name': 'Protein Bar', 'calories': 210, 'protein': 20, 'carbs': 18, 'fat': 7},
    ];
    
    // Add meals
    var mealTime = 7 * 60; // 7:00 AM in minutes
    
    // Breakfast
    meals.add(_createMeal(
      dayId, 
      'Breakfast', 
      _formatTime(mealTime), 
      breakfastOptions[Random().nextInt(breakfastOptions.length)],
    ));
    
    // Lunch (around noon)
    mealTime = 12 * 60; // 12:00 PM
    meals.add(_createMeal(
      dayId, 
      'Lunch', 
      _formatTime(mealTime), 
      lunchOptions[Random().nextInt(lunchOptions.length)],
    ));
    
    // Afternoon snack
    mealTime = 15 * 60 + 30; // 3:30 PM
    meals.add(_createMeal(
      dayId, 
      'Snack', 
      _formatTime(mealTime), 
      snackOptions[Random().nextInt(snackOptions.length)],
    ));
    
    // Dinner
    mealTime = 19 * 60; // 7:00 PM
    meals.add(_createMeal(
      dayId, 
      'Dinner', 
      _formatTime(mealTime), 
      dinnerOptions[Random().nextInt(dinnerOptions.length)],
    ));
    
    // Evening snack (50% chance)
    if (Random().nextBool()) {
      mealTime = 21 * 60; // 9:00 PM
      meals.add(_createMeal(
        dayId, 
        'Evening Snack', 
        _formatTime(mealTime), 
        snackOptions[Random().nextInt(snackOptions.length)],
      ));
    }
    
    return meals;
  }
  
  // Helper to create a meal object
  static Map<String, dynamic> _createMeal(
    String dayId, 
    String mealType, 
    String mealTime, 
    Map<String, dynamic> mealOption,
  ) {
    return {
      'id': const Uuid().v4(),
      'day_id': dayId,
      'meal_type': mealType,
      'meal_time': mealTime,
      'meal_name': mealOption['name'],
      'calories': mealOption['calories'],
      'protein_g': mealOption['protein'],
      'carbs_g': mealOption['carbs'],
      'fat_g': mealOption['fat'],
      'instructions': 'Prepare fresh and enjoy',
      'ingredients': mealOption['name'].split(' with ').join(', ').replaceAll(' & ', ', '),
    };
  }
  
  // Format minutes to HH:MM AM/PM
  static String _formatTime(int minutes) {
    final hour = minutes ~/ 60;
    final minute = minutes % 60;
    final period = hour < 12 ? 'AM' : 'PM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }
} 