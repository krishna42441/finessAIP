import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart'; // Import for supabase client
import '../config.dart';
import '../services/plan_service.dart';
import '../models/plan_models.dart';
import '../services/mcp_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:built_value/built_value.dart';
import '../utils/string_builder.dart';

class GeminiService {
  // Get Gemini API key from config
  static final String _apiKey = AppConfig.geminiApiKey;

  // Define a gemini client instance
  static final _geminiClient = GenerativeModel(
    model: 'gemini-1.5-pro',
    apiKey: AppConfig.geminiApiKey,
  );

  // Generate both nutrition and workout plans for a user
  static Future<Map<String, dynamic>> generatePlans(String userId) async {
    try {
      // Get user profile data
      final userProfile = await supabase
          .from('user_profiles')
          .select('*')
          .eq('user_id', userId)
          .single();
      
      debugPrint('Generating AI plans for user: $userId with profile: $userProfile');
      
      // Generate workout plan
      Map<String, dynamic> workoutPlan;
      String? workoutPlanId;
      try {
        workoutPlan = await generateWorkoutPlan(userProfile);
        
        // Transform workout_days to days to match the expected structure
        if (workoutPlan.containsKey('workout_days') && !workoutPlan.containsKey('days')) {
          workoutPlan['days'] = workoutPlan['workout_days'];
        }
        
        workoutPlanId = await storeWorkoutPlan(userId, workoutPlan);
        debugPrint('Successfully generated and stored workout plan: $workoutPlanId');
      } catch (e) {
        debugPrint('Error generating workout plan: $e');
        throw Exception('Failed to generate workout plan: $e');
      }
      
      // Generate nutrition plan
      Map<String, dynamic> nutritionPlan;
      String? nutritionPlanId;
      try {
        nutritionPlan = await generateNutritionPlan(userProfile, workoutPlan: workoutPlan);
        nutritionPlanId = await storeNutritionPlan(userId, nutritionPlan);
        debugPrint('Successfully generated and stored nutrition plan: $nutritionPlanId');
      } catch (e) {
        debugPrint('Error generating nutrition plan: $e');
        throw Exception('Failed to generate nutrition plan: $e');
      }
      
      return {
        'success': true,
        'message': 'AI-generated plans created successfully',
        'workout_plan_id': workoutPlanId,
        'nutrition_plan_id': nutritionPlanId,
      };
    } catch (e) {
      debugPrint('Error generating AI plans: $e');
      return {
        'success': false,
        'message': 'Failed to generate AI plans: $e',
        'workout_plan_id': null,
        'nutrition_plan_id': null,
      };
    }
  }

  // Clean and repair potentially malformed JSON from AI responses
  static String _aggressiveJsonCleaning(String jsonText) {
    try {
      // Find the main structure
      int startBrace = jsonText.indexOf('{');
      int endBrace = jsonText.lastIndexOf('}');
      
      if (startBrace == -1 || endBrace == -1 || startBrace > endBrace) {
        throw Exception('Invalid JSON structure');
      }
      
      // Extract the main JSON object
      String fixedJson = jsonText.substring(startBrace, endBrace + 1);
      
      // Find the days array
      int daysStart = fixedJson.indexOf('"days"');
      if (daysStart != -1) {
        // Find the start of the days array
        int arrayStart = fixedJson.indexOf('[', daysStart);
        if (arrayStart != -1) {
          // Process each day object
          List<String> validDayObjects = [];
          int pos = arrayStart + 1;
          int depth = 0;
          int startPos = pos;
          
          while (pos < fixedJson.length) {
            if (fixedJson[pos] == '{') depth++;
            if (fixedJson[pos] == '}') {
              depth--;
              if (depth == 0) {
                // We've found a complete day object
                String dayObject = fixedJson.substring(startPos, pos + 1);
                
                // Verify the day object is complete
                try {
                  jsonDecode(dayObject);
                  validDayObjects.add(dayObject);
                } catch (e) {
                  // If parsing fails, try to repair the day object
                  String repairedDay = _repairDayObject(dayObject);
                  if (repairedDay.isNotEmpty) {
                    validDayObjects.add(repairedDay);
                  }
                }
                
                // Look for the next object
                int nextObjStart = -1;
                for (int i = pos + 1; i < fixedJson.length; i++) {
                  if (fixedJson[i] == '{') {
                    nextObjStart = i;
                    break;
                  } else if (fixedJson[i] == ']') {
                    break;
                  }
                }
                
                if (nextObjStart == -1) break;
                startPos = nextObjStart;
                pos = nextObjStart;
                depth = 0;
              }
            }
            pos++;
          }
          
          // Reconstruct the JSON with valid day objects
          String repairedJson = fixedJson.substring(0, arrayStart + 1);
          for (int i = 0; i < validDayObjects.length; i++) {
            repairedJson += validDayObjects[i];
            if (i < validDayObjects.length - 1) {
              repairedJson += ",";
            }
          }
          repairedJson += "]}";
          
          return repairedJson;
        }
      }
    } catch (e) {
      debugPrint('Error in aggressive JSON cleaning: $e');
    }
    
    return jsonText;
  }

  static String _repairDayObject(String dayJson) {
    try {
      // Find required fields
      final dayOfWeekMatch = RegExp(r'"dayOfWeek":\s*(\d+)').firstMatch(dayJson);
      final focusAreaMatch = RegExp(r'"focusArea":\s*"([^"]+)"').firstMatch(dayJson);
      
      if (dayOfWeekMatch != null && focusAreaMatch != null) {
        // Extract exercises array if present
        final exercisesStart = dayJson.indexOf('"exercises"');
        if (exercisesStart != -1) {
          final arrayStart = dayJson.indexOf('[', exercisesStart);
          if (arrayStart != -1) {
            List<String> validExercises = [];
            int pos = arrayStart + 1;
            int depth = 0;
            int startPos = pos;
            
            while (pos < dayJson.length) {
              if (dayJson[pos] == '{') depth++;
              if (dayJson[pos] == '}') {
                depth--;
                if (depth == 0) {
                  String exercise = dayJson.substring(startPos, pos + 1);
                  try {
                    jsonDecode(exercise);
                    validExercises.add(exercise);
                  } catch (e) {
                    // Skip invalid exercise
                  }
                  
                  // Look for next exercise
                  int nextStart = -1;
                  for (int i = pos + 1; i < dayJson.length; i++) {
                    if (dayJson[i] == '{') {
                      nextStart = i;
                      break;
                    } else if (dayJson[i] == ']') {
                      break;
                    }
                  }
                  
                  if (nextStart == -1) break;
                  startPos = nextStart;
                  pos = nextStart;
                  depth = 0;
                }
              }
              pos++;
            }
            
            // Reconstruct the day object with valid exercises
            return '''
{
  "dayOfWeek": ${dayOfWeekMatch.group(1)},
  "focusArea": "${focusAreaMatch.group(1)}",
  "exercises": [${validExercises.join(',')}]
}''';
          }
        }
      }
    } catch (e) {
      debugPrint('Error repairing day object: $e');
    }
    
    return '';
  }

  /// Generate a workout plan based on user profile
  static Future<Map<String, dynamic>> generateWorkoutPlan(Map<String, dynamic> userProfile) async {
    try {
      debugPrint('Generating workout plan for user profile');
      
      // Ensure all profile attributes are included
      final fullProfile = {
        'age': userProfile['age'] ?? 30,
        'gender': userProfile['gender'] ?? 'not specified',
        'fitness_level': userProfile['fitness_level'] ?? 'beginner',
        'primary_fitness_goal': userProfile['primary_fitness_goal'] ?? 'general fitness',
        'weight_kg': userProfile['weight_kg'] ?? 70,
        'height_cm': userProfile['height_cm'] ?? 170,
        'workout_days_per_week': userProfile['workout_days_per_week'] ?? 3,
        'equipment_access': userProfile['equipment_access'] ?? 'minimal',
        'fitness_concerns': userProfile['fitness_concerns'] ?? '',
        'specific_targets': userProfile['specific_targets'] ?? '',
        'additional_notes': userProfile['additional_notes'] ?? '',
        'experience_years': userProfile['experience_years'] ?? 0,
        'preferred_workout_time': userProfile['preferred_workout_time'] ?? 'morning',
        'preferred_workout_duration': userProfile['preferred_workout_duration'] ?? 60,
        'activity_level': userProfile['activity_level'] ?? 'moderate',
        'injury_history': userProfile['injury_history'] ?? '',
      };
      
      // Prepare the system prompt with user profile information
      final systemPrompt = _buildWorkoutPlanSystemPrompt(fullProfile);
      
      // Create generative model
      final model = GenerativeModel(
        model: 'gemini-1.5-pro',
        apiKey: AppConfig.geminiApiKey,
        systemInstruction: Content.text(systemPrompt),
      );
      
      // Generate the workout plan
      final content = [Content.text('Generate a personalized workout plan based on my profile')];
      final response = await model.generateContent(content);
      
      // Get the response text and extract JSON
      final responseText = response.text ?? '';
      debugPrint('Raw response: $responseText');
      
      // Clean the response to extract only the JSON part
      final jsonString = _extractJsonFromResponse(responseText);
      
      // Parse the JSON
      try {
        final workoutPlan = jsonDecode(jsonString);
        return workoutPlan;
      } catch (e) {
        debugPrint('Error parsing workout plan JSON: $e');
        throw Exception('Failed to parse workout plan: $e');
      }
    } catch (e) {
      debugPrint('Error generating workout plan: $e');
      throw Exception('Failed to generate workout plan: $e');
    }
  }
  
  /// Extract JSON from a text response that might contain markdown code blocks
  static String _extractJsonFromResponse(String response) {
    // Try to find JSON inside markdown code blocks
    final codeBlockRegex = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```');
    final match = codeBlockRegex.firstMatch(response);
    
    if (match != null && match.groupCount >= 1) {
      return match.group(1)!.trim();
    }
    
    // If no code block, look for JSON object pattern
    final jsonObjectRegex = RegExp(r'{[\s\S]*}');
    final objectMatch = jsonObjectRegex.firstMatch(response);
    
    if (objectMatch != null) {
      return objectMatch.group(0)!.trim();
    }
    
    // Return the original string if no pattern matches
    return response.trim();
  }

  /// Generates a nutrition plan using Gemini AI
  static Future<Map<String, dynamic>> generateNutritionPlan(
      Map<String, dynamic> userProfile, {Map<String, dynamic>? workoutPlan}) async {
    try {
      debugPrint('Starting nutrition plan generation with Gemini...');

      // Build comprehensive prompt with user profile and workout data
      final StringBuilder promptBuilder = StringBuilder();
      
      promptBuilder.appendLine('You are a certified nutritionist and fitness expert. Create a personalized nutrition plan for a user based on their profile information and workout plan.');
      
      promptBuilder.appendLine('\nUser Profile:');
      // Add basic user info
      final String gender = userProfile['gender'] ?? 'Not specified';
      final int age = userProfile['age'] ?? 30;
      final int heightCm = userProfile['height_cm'] ?? 175;
      final int weightKg = userProfile['weight_kg'] ?? 75;
      
      // Calculate BMI & estimated daily calories
      final double bmi = weightKg / ((heightCm / 100) * (heightCm / 100));
      int dailyCalories = 0;
      
      // Simplified BMR calculation based on gender (Mifflin-St Jeor equation)
      if (gender == 'Male' || gender == 'male') {
        dailyCalories = ((10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5).round();
      } else {
        dailyCalories = ((10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161).round();
      }
      
      // Adjust for activity level
      final String activityLevel = userProfile['daily_activity_level'] ?? 'Moderate';
      double activityMultiplier = 1.55; // Default to moderate
      
      switch (activityLevel.toLowerCase()) {
        case 'sedentary':
          activityMultiplier = 1.2;
          break;
        case 'lightly active':
          activityMultiplier = 1.375;
          break;
        case 'moderate':
          activityMultiplier = 1.55;
          break;
        case 'very active':
          activityMultiplier = 1.725;
          break;
        case 'extra active':
          activityMultiplier = 1.9;
          break;
      }
      
      dailyCalories = (dailyCalories * activityMultiplier).round();
      
      // Adjust for goal
      final String fitnessGoal = userProfile['primary_fitness_goal'] ?? 'Maintain weight';
      if (fitnessGoal.toLowerCase().contains('weight loss') || 
          fitnessGoal.toLowerCase().contains('fat loss')) {
        dailyCalories = (dailyCalories * 0.85).round(); // 15% deficit
      } else if (fitnessGoal.toLowerCase().contains('muscle') || 
                fitnessGoal.toLowerCase().contains('gain')) {
        dailyCalories = (dailyCalories * 1.1).round(); // 10% surplus
      }
      
      promptBuilder.appendLine('- Gender: $gender');
      promptBuilder.appendLine('- Age: $age years');
      promptBuilder.appendLine('- Height: $heightCm cm');
      promptBuilder.appendLine('- Weight: $weightKg kg');
      promptBuilder.appendLine('- BMI: ${bmi.toStringAsFixed(1)}');
      promptBuilder.appendLine('- Estimated daily calories: $dailyCalories kcal');
      promptBuilder.appendLine('- Activity level: $activityLevel');
      promptBuilder.appendLine('- Primary fitness goal: $fitnessGoal');
      
      // Add dietary preferences
      final String eatingHabits = userProfile['eating_habits'] ?? 'No specific diet';
      Map<String, dynamic> dietaryRestrictions = {};
      
      try {
        if (userProfile['dietary_restrictions'] != null) {
          if (userProfile['dietary_restrictions'] is String) {
            // Try to parse JSON if it's a string
            dietaryRestrictions = 
                json.decode(userProfile['dietary_restrictions'] as String) as Map<String, dynamic>;
          } else if (userProfile['dietary_restrictions'] is Map) {
            dietaryRestrictions = 
                Map<String, dynamic>.from(userProfile['dietary_restrictions'] as Map);
          }
      }
    } catch (e) {
        debugPrint('Error parsing dietary restrictions: $e');
      }
      
      promptBuilder.appendLine('- Eating habits: $eatingHabits');
      
      if (dietaryRestrictions.isNotEmpty) {
        promptBuilder.appendLine('- Dietary restrictions:');
        dietaryRestrictions.forEach((key, value) {
          if (value == true) {
            promptBuilder.appendLine('  * ${key.replaceAll('_', ' ')}');
          }
        });
      }
      
      // Favorite and avoided foods
      final String favoriteFoods = userProfile['favorite_foods'] ?? 'Not specified';
      final String avoidedFoods = userProfile['avoided_foods'] ?? 'Not specified';
      
      if (favoriteFoods != 'Not specified') {
        promptBuilder.appendLine('- Favorite foods: $favoriteFoods');
      }
      
      if (avoidedFoods != 'Not specified') {
        promptBuilder.appendLine('- Avoided foods: $avoidedFoods');
      }
      
      // Add medical considerations
      final String medicalConditions = userProfile['medical_conditions'] ?? 'None';
      final String medications = userProfile['medications'] ?? 'None';
      
      if (medicalConditions != 'None') {
        promptBuilder.appendLine('- Medical conditions: $medicalConditions');
      }
      
      if (medications != 'None') {
        promptBuilder.appendLine('- Medications: $medications');
      }
      
      // Add workout plan information if available
      if (workoutPlan != null) {
        promptBuilder.appendLine('\nWorkout Plan Information:');
        promptBuilder.appendLine('- Plan name: ${workoutPlan['plan_name'] ?? 'General fitness plan'}');
        promptBuilder.appendLine('- Plan type: ${workoutPlan['plan_type'] ?? 'General fitness'}');
        promptBuilder.appendLine('- Difficulty: ${workoutPlan['plan_difficulty'] ?? 'Intermediate'}');
        
        // Add day-specific workout information
        if (workoutPlan['workout_days'] is List && (workoutPlan['workout_days'] as List).isNotEmpty) {
          promptBuilder.appendLine('\nWorkout Schedule:');
          
          for (var day in workoutPlan['workout_days']) {
            final int dayOfWeek = day['day_of_week'] ?? 0;
            final String dayName = _getDayName(dayOfWeek);
            final String workoutType = day['workout_type'] ?? 'Rest';
            final String intensity = _getWorkoutIntensity(workoutType);
            
            promptBuilder.appendLine('- $dayName: $workoutType (Intensity: $intensity)');
            
            // Add exercise counts for more detailed nutrition planning
            if (day['exercises'] is List && (day['exercises'] as List).isNotEmpty) {
              final exerciseCount = (day['exercises'] as List).length;
              promptBuilder.appendLine('  * Contains $exerciseCount exercises');
            }
          }
        }
      }
      
      // Add nutrition plan requirements
      promptBuilder.appendLine('\nNutrition Plan Requirements:');
      promptBuilder.appendLine('1. Create a day-by-day nutrition plan aligned with the workout schedule.');
      promptBuilder.appendLine('2. For each day, specify the following:');
      promptBuilder.appendLine('   - Total calories recommended for that day based on workout intensity');
      promptBuilder.appendLine('   - Macronutrient breakdown (protein, carbs, fat) in grams');
      promptBuilder.appendLine('   - Recommended meal timing (number of meals and when to eat them)');
      promptBuilder.appendLine('   - Hydration recommendations');
      promptBuilder.appendLine('   - Any specific micronutrients to focus on based on the workout');
      promptBuilder.appendLine('3. Adjust calorie and macronutrient targets for workout vs. rest days.');
      promptBuilder.appendLine('4. Provide higher carbohydrates on intense workout days.');
      promptBuilder.appendLine('5. Provide higher protein on strength training days.');
      promptBuilder.appendLine('6. Account for dietary restrictions, favored and avoided foods.');
      promptBuilder.appendLine('7. Consider potential supplement recommendations if appropriate.');
      
      // Request JSON format
      promptBuilder.appendLine('\nPlease return your response as a JSON object with the following structure:');
      promptBuilder.appendLine('''
{
  "plan_name": "Personalized Nutrition Plan",
  "daily_calories": 2000,
  "macro_distribution": {
    "protein": "30% (150g)",
    "carbs": "50% (250g)",
    "fat": "20% (44g)"
  },
  "days": [
    {
      "day_of_week": 1,
      "total_calories": 2200,
      "total_protein": 165,
      "total_carbs": 275,
      "total_fat": 49,
      "meal_timing_recommendation": "4-5 meals, with post-workout nutrition within 1 hour",
      "is_workout_day": true,
      "workout_type": "Legs",
      "workout_intensity": "High",
      "hydration_needs": "3-4 liters",
      "key_micronutrients": ["Magnesium", "Potassium", "Vitamin D"],
      "special_recommendations": "Increase carbohydrates due to leg day intensity."
    }
    // Repeat for all 7 days of the week
  ]
}
''');
      
      // Generate nutrition plan using Gemini
      final promptText = promptBuilder.toString();
      
      // Log the prompt for debugging (exclude from production)
      // debugPrint('Nutrition Plan Prompt: $promptText');
      
      final geminiResponse = await _geminiClient.generateContent([
        Content.text(promptText),
      ]);
      
      // Log the response for debugging
      // debugPrint('Gemini Response Raw: ${geminiResponse.text ?? "No text response"}');
      
      // Extract JSON from the response
      final jsonText = _extractJsonFromResponse(geminiResponse.text ?? '');
      final nutritionPlan = json.decode(jsonText) as Map<String, dynamic>;
      
      // Add the user profile data for reference
      nutritionPlan['user_id'] = userProfile['user_id'] ?? '';
      nutritionPlan['is_generated'] = true;
      nutritionPlan['generation_date'] = DateTime.now().toIso8601String();
      
      // Log success
      debugPrint('Successfully generated nutrition plan from Gemini');
      
      return nutritionPlan;
    } catch (e) {
      debugPrint('Error generating nutrition plan with Gemini: $e');
      throw Exception('Failed to generate nutrition plan: $e');
    }
  }
  
  /// Get day name from day of week number (1 = Monday, 7 = Sunday)
  static String _getDayName(int dayOfWeek) {
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
  
  /// Get workout intensity level based on workout type
  static String _getWorkoutIntensity(String workoutType) {
    if (workoutType == 'Rest') {
      return 'Low';
    } else if (workoutType.contains('HIIT') || 
               workoutType.contains('Cardio') || 
               workoutType.contains('Full Body')) {
      return 'High';
    } else if (workoutType.contains('Strength') || 
               workoutType.contains('Legs') || 
               workoutType.contains('Push') || 
               workoutType.contains('Pull')) {
      return 'Medium-High';
    } else {
      return 'Medium';
    }
  }

  // Store the generated workout plan in the database
  static Future<String?> storeWorkoutPlan(String userId, Map<String, dynamic> workoutPlan) async {
    try {
      debugPrint('Storing workout plan for user: $userId');
      
      // First, debug the structure of the workout plan
      debugPrint('Workout plan structure: ${workoutPlan.keys.toList()}');
      
      // Determine workout days - check both possible keys and ensure we have the data
      List<dynamic>? workoutDays;
      if (workoutPlan.containsKey('workout_days') && workoutPlan['workout_days'] is List) {
        workoutDays = workoutPlan['workout_days'] as List<dynamic>;
        debugPrint('Found workout_days with ${workoutDays.length} days');
      } else if (workoutPlan.containsKey('days') && workoutPlan['days'] is List) {
        workoutDays = workoutPlan['days'] as List<dynamic>;
        debugPrint('Found days with ${workoutDays.length} days');
      } else {
        debugPrint('No workout days found in plan');
        workoutDays = [];
      }
      
      // Count actual workout days (non-rest days)
      int workoutDayCount = workoutDays.length;
      
      // Ensure we never have 0 days per week
      if (workoutDayCount == 0) {
        workoutDayCount = 3; // Default to 3 if no days found
        debugPrint('Using default of 3 days per week');
      }
      
      // Create a copy of the plan with only necessary fields for database
      Map<String, dynamic> planToStore = {
        'user_id': userId,
        'plan_name': workoutPlan['plan_name'] ?? 'Custom Workout Plan',
        'plan_description': workoutPlan['plan_description'] ?? '',
        'plan_type': workoutPlan['plan_type'] ?? 'General Fitness',
        'plan_difficulty': workoutPlan['plan_difficulty'] ?? 'Intermediate',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'start_date': DateTime.now().toIso8601String().split('T')[0],
        'end_date': DateTime.now().add(const Duration(days: 28)).toIso8601String().split('T')[0],
        'days_per_week': workoutDayCount,
        'workout_days_per_week': workoutDayCount,
      };
      
      debugPrint('Plan to store: $planToStore');
      
      // Insert into database
      final response = await supabase
          .from('workout_plans')
          .insert(planToStore)
          .select('id')
          .single();
      
      final planId = response['id'] as String;
      debugPrint('Workout plan stored with ID: $planId');
      
      // Store workout days if available
      if (workoutDays.isNotEmpty) {
        for (var day in workoutDays) {
          try {
            // Create day record
        final dayId = const Uuid().v4();
            final dayData = {
          'id': dayId,
          'plan_id': planId,
              'day_of_week': day['day_of_week'] ?? 1,
              'is_rest_day': day['is_rest_day'] ?? false,
              'workout_type': day['workout_type'] ?? 'General',
              'workout_focus': day['focus'] ?? day['workout_type'] ?? '',
              'notes': day['notes'] ?? ''
            };
            
            debugPrint('Storing workout day: ${dayData['day_of_week']} - ${dayData['workout_type']}');
            await supabase.from('workout_plan_days').insert(dayData);
            
            // Add exercises for this day if available
            if (day['exercises'] != null && day['exercises'] is List) {
              for (var i = 0; i < day['exercises'].length; i++) {
                var exercise = day['exercises'][i];
                
                final exerciseData = {
              'id': const Uuid().v4(),
              'day_id': dayId,
                  'exercise_name': exercise['name'] ?? 'Exercise',
                  'exercise_order': i + 1,
                  'sets': exercise['sets'] ?? 3,
                  'reps': exercise['reps'] ?? '10-12',
                  'rest_seconds': _parseRestTime(exercise['rest'] ?? '60 seconds'),
                  'instructions': exercise['notes'] ?? exercise['instructions'] ?? 'Perform with proper form'
                };
                
                debugPrint('Storing exercise: ${exerciseData['exercise_name']}');
                await supabase.from('workout_exercises').insert(exerciseData);
              }
            }
          } catch (e) {
            debugPrint('Error storing workout day: $e');
            // Continue with other days even if one fails
          }
        }
      }
      
      return planId;
    } catch (e) {
      debugPrint('Error storing workout plan: $e');
      return null;
    }
  }
  
  // Helper to parse rest time from string to seconds
  static int _parseRestTime(String restTime) {
    try {
      // Extract the number from strings like "60 seconds" or "1 minute"
      final numMatch = RegExp(r'(\d+)').firstMatch(restTime);
      if (numMatch == null) return 60; // Default
      
      final num = int.tryParse(numMatch.group(1) ?? '60') ?? 60;
      
      // Check if it's minutes or seconds
      if (restTime.toLowerCase().contains('minute')) {
        return num * 60; // Convert minutes to seconds
            } else {
        return num; // Already in seconds
          }
        } catch (e) {
      return 60; // Default to 60 seconds
    }
  }

  // Store the generated nutrition plan in the database
  static Future<String?> storeNutritionPlan(String userId, Map<String, dynamic> nutritionPlan) async {
    try {
      debugPrint('Storing nutrition plan for user: $userId');
      
      // Create a copy of the plan with only necessary fields for database
      Map<String, dynamic> planToStore = {
        'user_id': userId,
        'total_daily_calories': nutritionPlan['daily_calories'] ?? 2000,
        'protein_daily_grams': _extractMacroGrams(nutritionPlan, 'protein'),
        'carbs_daily_grams': _extractMacroGrams(nutritionPlan, 'carbs'),
        'fat_daily_grams': _extractMacroGrams(nutritionPlan, 'fat'),
        'meals_per_day': _calculateMealsPerDay(nutritionPlan),
        'plan_notes': 'Generated nutrition plan',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'start_date': DateTime.now().toIso8601String().split('T')[0],
        'end_date': DateTime.now().add(const Duration(days: 28)).toIso8601String().split('T')[0],
      };
      
      // Insert into database
      final response = await supabase
          .from('nutrition_plans')
          .insert(planToStore)
          .select('id')
          .single();
      
      final planId = response['id'] as String;
      debugPrint('Nutrition plan stored with ID: $planId');
      
      // Now store the nutrition days and meals
      if (nutritionPlan['days'] != null && nutritionPlan['days'] is List) {
        for (var day in nutritionPlan['days']) {
          // Create day record
        final dayId = const Uuid().v4();
        await supabase.from('nutrition_plan_days').insert({
          'id': dayId,
          'plan_id': planId,
            'day_of_week': day['day_of_week'],
            'total_calories': day['total_calories'] ?? planToStore['total_daily_calories'],
            'total_protein': day['total_protein'] ?? planToStore['protein_daily_grams'],
            'total_carbs': day['total_carbs'] ?? planToStore['carbs_daily_grams'],
            'total_fat': day['total_fat'] ?? planToStore['fat_daily_grams'],
            'notes': day['meal_timing_recommendation'] ?? ''
          });
          
          // Add meals for this day if available
        if (day['meals'] != null && day['meals'] is List) {
          for (var meal in day['meals']) {
            await supabase.from('nutrition_plan_meals').insert({
              'id': const Uuid().v4(),
              'day_id': dayId,
              'meal_name': meal['name'] ?? 'Meal',
              'meal_time': meal['time'] ?? '12:00 PM',
              'total_calories': meal['calories'] ?? 0,
              'protein_grams': meal['protein'] ?? 0,
              'carbs_grams': meal['carbs'] ?? 0,
              'fat_grams': meal['fat'] ?? 0,
                'description': meal['description'] ?? '',
              'foods': '[]'
            });
            }
          }
        }
      }
      
      return planId;
    } catch (e) {
      debugPrint('Error storing nutrition plan: $e');
      return null;
    }
  }
  
  // Helper method to extract macro grams
  static int _extractMacroGrams(Map<String, dynamic> plan, String macroType) {
    if (plan['macro_distribution'] == null) return 0;
    
    try {
      final macros = Map<String, dynamic>.from(plan['macro_distribution'] as Map);
      final macroValue = macros[macroType];
      if (macroValue == null) return 0;
      
      // Try to extract grams from format like "30% (150g)"
      final gramsMatch = RegExp(r'(\d+)g').firstMatch(macroValue.toString());
      if (gramsMatch != null) {
        return int.tryParse(gramsMatch.group(1) ?? '0') ?? 0;
      }
      
      // Calculate from percentage if no direct gram value
      final percentMatch = RegExp(r'(\d+)%').firstMatch(macroValue.toString());
      if (percentMatch != null) {
        final percent = int.tryParse(percentMatch.group(1) ?? '0') ?? 0;
        final dailyCalories = plan['daily_calories'] ?? 2000;
        
        // Convert percentage to grams based on calorie content
        if (macroType == 'protein' || macroType == 'carbs') {
          // 4 calories per gram
          return ((dailyCalories * percent / 100) / 4).round();
        } else if (macroType == 'fat') {
          // 9 calories per gram
          return ((dailyCalories * percent / 100) / 9).round();
        }
      }
    } catch (e) {
      debugPrint('Error extracting $macroType grams: $e');
    }
    
    // Default values if extraction fails
    if (macroType == 'protein') return 150;
    if (macroType == 'carbs') return 200;
    if (macroType == 'fat') return 60;
    return 0;
  }
  
  // Helper to calculate meals per day
  static int _calculateMealsPerDay(Map<String, dynamic> plan) {
    if (plan['days'] == null || !(plan['days'] is List) || (plan['days'] as List).isEmpty) {
      return 3; // Default
    }
    
    try {
      final day = (plan['days'] as List)[0];
      if (day['meal_timing_recommendation'] != null) {
        final mealMatch = RegExp(r'(\d+)-(\d+)').firstMatch(day['meal_timing_recommendation'].toString());
        if (mealMatch != null) {
          return int.tryParse(mealMatch.group(2) ?? '3') ?? 3; // Use upper range
        }
      }
      
      // If there are meals defined, count them
      if (day['meals'] != null && day['meals'] is List) {
        return (day['meals'] as List).length;
      }
    } catch (e) {
      debugPrint('Error calculating meals per day: $e');
    }
    
    return 3; // Default to 3 meals if we can't determine
  }

  // Get latest workout plan for a user
  static Future<Map<String, dynamic>?> getLatestWorkoutPlan(String userId) async {
    try {
      // Get the latest workout plan for this user
      final planData = await supabase
          .from('workout_plans')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .single();
      
      if (planData == null) return null;
      
      // Get all days for this plan
      final daysData = await supabase
          .from('workout_plan_days')
          .select('*')
          .eq('plan_id', planData['id'])
          .order('day_of_week', ascending: true);
      
      if (daysData == null) return null;
      
      // For each day, get all exercises
      List<Map<String, dynamic>> days = [];
      for (var day in daysData) {
        final exercisesData = await supabase
            .from('workout_exercises')
            .select('*')
            .eq('day_id', day['id'])
            .order('exercise_order', ascending: true);
        
        Map<String, dynamic> dayWithExercises = Map<String, dynamic>.from(day);
        dayWithExercises['exercises'] = exercisesData ?? [];
        days.add(dayWithExercises);
      }
      
      // Return the full plan with all days and exercises
      return {
        'plan': planData,
        'days': days,
      };
    } catch (e) {
      debugPrint('Error fetching workout plan: $e');
      return null;
    }
  }
  
  // Get latest nutrition plan for a user
  static Future<Map<String, dynamic>?> getLatestNutritionPlan(String userId) async {
    try {
      // Get the latest nutrition plan for this user
      final planData = await supabase
          .from('nutrition_plans')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .single();
      
      if (planData == null) return null;
      
      // Get all days for this plan
      final daysData = await supabase
          .from('nutrition_plan_days')
          .select('*')
          .eq('plan_id', planData['id'])
          .order('day_of_week', ascending: true);
      
      if (daysData == null) return null;
      
      // For each day, get all meals
      List<Map<String, dynamic>> days = [];
      for (var day in daysData) {
        final mealsData = await supabase
            .from('nutrition_plan_meals')
            .select('*')
            .eq('day_id', day['id'])
            .order('meal_time', ascending: true);
        
        Map<String, dynamic> dayWithMeals = Map<String, dynamic>.from(day);
        dayWithMeals['meals'] = mealsData ?? [];
        days.add(dayWithMeals);
      }
      
      // Return the full plan with all days and meals
      return {
        'plan': planData,
        'days': days,
      };
    } catch (e) {
      debugPrint('Error fetching nutrition plan: $e');
      return null;
    }
  }
  
  // Format workout plan for display
  static String _formatWorkoutPlanSummary(Map<String, dynamic>? workoutPlan) {
    if (workoutPlan == null || workoutPlan.isEmpty) return 'No workout plan available';
    
    String summary = '';
    if (workoutPlan.containsKey('plan') && workoutPlan['plan'] is Map) {
      final plan = workoutPlan['plan'] as Map;
      summary += 'Plan: ${plan['plan_name'] ?? 'Custom Plan'}\n';
      summary += 'Type: ${plan['plan_type'] ?? 'General Fitness'}\n';
      summary += 'Difficulty: ${plan['plan_difficulty'] ?? 'Intermediate'}\n\n';
    }
    
    if (workoutPlan.containsKey('days') && workoutPlan['days'] is List) {
      final days = workoutPlan['days'] as List;
      if (days.isNotEmpty) {
        summary += 'Schedule:\n';
        
        for (var day in days) {
          if (day is Map) {
            final dayName = _getDayName(day['day_of_week'] ?? 0);
            final focus = day['workout_type'] ?? 'Rest';
            final exercises = day['exercises'] is List ? 
                (day['exercises'] as List).length : 0;
            
            summary += '- $dayName: $focus ($exercises exercises)\n';
          }
        }
      }
    }
    
    return summary;
  }
  
  // Format nutrition plan for display
  static String _formatNutritionPlanSummary(Map<String, dynamic>? nutritionPlan) {
    if (nutritionPlan == null || nutritionPlan.isEmpty) return 'No nutrition plan available';
    
    String summary = '';
    if (nutritionPlan.containsKey('plan') && nutritionPlan['plan'] is Map) {
      final plan = nutritionPlan['plan'] as Map;
      summary += 'Daily Targets:\n';
      summary += '- Calories: ${plan['total_daily_calories'] ?? 'Not set'}\n';
      summary += '- Protein: ${plan['protein_daily_grams'] ?? 'Not set'}g\n';
      summary += '- Carbs: ${plan['carbs_daily_grams'] ?? 'Not set'}g\n';
      summary += '- Fat: ${plan['fat_daily_grams'] ?? 'Not set'}g\n\n';
    }
    
    if (nutritionPlan.containsKey('days') && nutritionPlan['days'] is List) {
      final days = nutritionPlan['days'] as List;
      if (days.isNotEmpty) {
        summary += 'Meal Schedule:\n';
        
        for (var day in days) {
          if (day is Map) {
            final dayName = _getDayName(day['day_of_week'] ?? 0);
            final meals = day['meals'] is List ? 
                (day['meals'] as List).length : 0;
            
            summary += '- $dayName: ($meals meals)\n';
            if (meals > 0) {
              for (var meal in day['meals']) {
                summary += '  • ${meal['meal_name']} (${meal['total_calories']} cal)\n';
              }
            }
          }
        }
      }
    }
    
    return summary;
  }

  // Process and apply workout updates
  static Future<Map<String, dynamic>> _processWorkoutUpdates(
    String userId, 
    Map<String, dynamic> workoutUpdates,
    Map<String, dynamic>? currentWorkoutPlan
  ) async {
    try {
      if (currentWorkoutPlan == null || !currentWorkoutPlan.containsKey('plan')) {
        return {
          "success": false,
          "message": "Sorry, I couldn't find an existing workout plan to update. Please generate a plan first."
        };
      }
      
      final planId = currentWorkoutPlan['plan']['id'];
      
      // Handle instruction updates for exercises
      if (workoutUpdates['fullPlanUpdate'] == true && 
          workoutUpdates['updateType'] == 'instructions') {
        
        // This is a special case for updating instructions only
        int updatedExercises = 0;
        String? exerciseName = workoutUpdates['exerciseName'];
        String? newInstructions = workoutUpdates['newInstructions'];
        
        if (newInstructions != null && newInstructions.isNotEmpty) {
          // Get all workout days
          for (var day in currentWorkoutPlan['days']) {
            final dayId = day['id'];
            List<dynamic>? exercises = day['exercises'];
            
            if (exercises != null && exercises.isNotEmpty) {
              // If exercise name is specified, update only that exercise
              // Otherwise, update all exercises
              for (var exercise in exercises) {
                if (exerciseName == null || 
                    exercise['exercise_name'].toString().toLowerCase().contains(exerciseName.toLowerCase())) {
                  
                  // Update the exercise instructions
                  final updateResult = await McpService.updateExerciseInstructions(
                    exercise['id'],
                    newInstructions
                  );
                  
                  if (updateResult) {
                    updatedExercises++;
                  }
                }
              }
            }
          }
          
          if (updatedExercises > 0) {
            return {
              "success": true,
              "message": "👍 Updated instructions for $updatedExercises exercises in your workout plan! The instructions should now be clearer and easier to follow."
            };
          } else {
            return {
              "success": false,
              "message": "I couldn't find any exercises to update. Please specify a particular exercise or day."
            };
          }
        }
      } else if (workoutUpdates['fullPlanUpdate'] == true) {
        // Handle other types of full plan updates
        return {
          "success": false,
          "message": "Full workout plan updates aren't supported yet. Please specify changes to a particular day or exercise."
        };
      }
      
      // Handle specific day updates
      if (workoutUpdates.containsKey('specificDay') && workoutUpdates['specificDay'] != null) {
        final dayUpdate = workoutUpdates['specificDay'];
        final dayOfWeek = dayUpdate['dayOfWeek'];
        
        // Find the day in the current plan
        String? dayId;
        for (var day in currentWorkoutPlan['days']) {
          if (day['day_of_week'] == dayOfWeek) {
            dayId = day['id'];
            break;
          }
        }
        
        if (dayId == null) {
          return {
            "success": false,
            "message": "I couldn't find the specified day (${_getDayName(dayOfWeek)}) in your workout plan."
          };
        }
        
        // Process each change
        if (dayUpdate.containsKey('changes') && dayUpdate['changes'] is List) {
          final changes = dayUpdate['changes'] as List;
          int changesMade = 0;
          
          for (var change in changes) {
            final changeType = change['type'];
            final exerciseName = change['exerciseName'];
            
            if (changeType == 'add_exercise') {
              // Add the new exercise using McpService
              final added = await McpService.addExerciseToWorkoutDay(
                dayId,
                exerciseName,
                change['sets'] ?? 3,
                change['reps'] ?? '10-12',
                change['instructions'] ?? 'Perform with proper form.',
                change['restSeconds'] ?? 60
              );
              
              if (added) {
                changesMade++;
              }
            } else if (changeType == 'remove_exercise') {
              // Find the exercise ID
              String? exerciseId;
              for (var exercise in currentWorkoutPlan['days']) {
                if (exercise['day_id'] == dayId && 
                    exercise['exercise_name'].toString().toLowerCase() == exerciseName.toLowerCase()) {
                  exerciseId = exercise['id'];
                  break;
                }
              }
              
              if (exerciseId != null) {
                // Remove the exercise using McpService
                final removed = await McpService.removeExerciseFromWorkout(exerciseId);
                if (removed) {
                  changesMade++;
                }
              }
            } else if (changeType == 'modify_exercise') {
              // Find the exercise ID
              String? exerciseId;
              for (var day in currentWorkoutPlan['days']) {
                if (day['id'] == dayId) {
                  for (var exercise in day['exercises']) {
                    if (exercise['exercise_name'].toString().toLowerCase() == exerciseName.toLowerCase()) {
                      exerciseId = exercise['id'];
                      break;
                    }
                  }
                }
              }
              
              if (exerciseId != null) {
                // Update the exercise using McpService
                final updated = await McpService.updateExercise(
                  exerciseId,
                  change['sets'],
                  change['reps'],
                  change['instructions'],
                  change['restSeconds']
                );
                
                if (updated) {
                  changesMade++;
                }
              }
            }
          }
          
          if (changesMade > 0) {
            return {
              "success": true,
              "message": "✅ Successfully updated your workout for ${_getDayName(dayOfWeek)}! Made $changesMade changes to your exercises."
            };
          } else {
            return {
              "success": false,
              "message": "I couldn't make any of the requested changes to your workout plan. Please try a different approach."
            };
          }
        }
      }
      
      // If we reach here, no supported update was found
      return {
        "success": false,
        "message": "I'm not sure how to process your workout update request. Please be more specific about what you'd like to change."
      };
    } catch (e) {
      debugPrint('Error processing workout updates: $e');
      return {
        "success": false,
        "message": "I encountered an error while trying to update your workout plan. Please try again with a more specific request."
      };
    }
  }
  
  // Process and apply nutrition updates
  static Future<Map<String, dynamic>> _processNutritionUpdates(
    String userId, 
    Map<String, dynamic> nutritionUpdates,
    Map<String, dynamic>? currentNutritionPlan
  ) async {
    try {
      if (currentNutritionPlan == null || !currentNutritionPlan.containsKey('plan')) {
        return {
          "success": false,
          "message": "Sorry, I couldn't find an existing nutrition plan to update. Please generate a plan first."
        };
      }
      
      final planId = currentNutritionPlan['plan']['id'];
      
      // Handle macro updates
      if (nutritionUpdates['updateType'] == 'macros') {
        final calories = nutritionUpdates['calories'];
        final protein = nutritionUpdates['protein'];
        final carbs = nutritionUpdates['carbs'];
        final fat = nutritionUpdates['fat'];
        
        // Update plan macros using McpService
        final updated = await McpService.updateNutritionPlanMacros(
          planId,
          calories,
          protein,
          carbs,
          fat
        );
        
        if (updated) {
          return {
            "success": true,
            "message": "✅ Successfully updated your nutrition plan macros! Your new daily targets are:\n\n" +
                      "Calories: ${calories}kcal\n" +
                      "Protein: ${protein}g\n" +
                      "Carbs: ${carbs}g\n" +
                      "Fat: ${fat}g"
          };
        } else {
          return {
            "success": false,
            "message": "I couldn't update your nutrition plan macros. Please try again."
          };
        }
      }
      
      // Handle meal updates
      if (nutritionUpdates['updateType'] == 'meal' && nutritionUpdates.containsKey('mealUpdates')) {
        final mealUpdates = nutritionUpdates['mealUpdates'];
        final dayOfWeek = mealUpdates['dayOfWeek'];
        
        // Find the day in the current plan
        String? dayId;
        for (var day in currentNutritionPlan['days']) {
          if (day['day_of_week'] == dayOfWeek) {
            dayId = day['id'];
            break;
          }
        }
        
        if (dayId == null) {
          return {
            "success": false,
            "message": "I couldn't find the specified day (${_getDayName(dayOfWeek)}) in your nutrition plan."
          };
        }
        
        // Process meal changes
        if (mealUpdates.containsKey('changes') && mealUpdates['changes'] is List) {
          final changes = mealUpdates['changes'] as List;
          int changesMade = 0;
          
          for (var change in changes) {
            final changeType = change['type'];
            
            if (changeType == 'add_meal') {
              // Add a new meal using McpService
              final added = await McpService.addMealToNutritionDay(
                dayId,
                change['mealName'],
                change['mealTime'],
                change['calories'] ?? 0,
                change['protein'] ?? 0,
                change['carbs'] ?? 0,
                change['fat'] ?? 0,
                change['description'] ?? ''
              );
              
              if (added) {
                changesMade++;
              }
            } else if (changeType == 'remove_meal') {
              final mealName = change['mealName'];
              
              // Find the meal ID
              String? mealId;
              for (var day in currentNutritionPlan['days']) {
                if (day['id'] == dayId) {
                  for (var meal in day['meals']) {
                    if (meal['meal_name'].toString().toLowerCase() == mealName.toLowerCase()) {
                      mealId = meal['id'];
                      break;
                    }
                  }
                }
              }
              
              if (mealId != null) {
                // Remove the meal using McpService
                final removed = await McpService.removeMealFromNutritionPlan(mealId);
                if (removed) {
                  changesMade++;
                }
              }
            } else if (changeType == 'modify_meal') {
              final mealName = change['mealName'];
              
              // Find the meal ID
              String? mealId;
              for (var day in currentNutritionPlan['days']) {
                if (day['id'] == dayId) {
                  for (var meal in day['meals']) {
                    if (meal['meal_name'].toString().toLowerCase() == mealName.toLowerCase()) {
                      mealId = meal['id'];
                      break;
                    }
                  }
                }
              }
              
              if (mealId != null) {
                // Update the meal using McpService
                final updated = await McpService.updateMeal(
                  mealId,
                  change['newMealName'] ?? null,
                  change['mealTime'] ?? null,
                  change['calories'] ?? null,
                  change['protein'] ?? null,
                  change['carbs'] ?? null,
                  change['fat'] ?? null,
                  change['description'] ?? null
                );
                
                if (updated) {
                  changesMade++;
                }
              }
            }
          }
          
          if (changesMade > 0) {
            return {
              "success": true,
              "message": "✅ Successfully updated your nutrition plan for ${_getDayName(dayOfWeek)}! Made $changesMade changes to your meals."
            };
          } else {
            return {
              "success": false,
              "message": "I couldn't make any of the requested changes to your nutrition plan. Please try a different approach."
            };
          }
        }
      }
      
      // If we reach here, no supported update was found
      return {
        "success": false,
        "message": "I'm not sure how to process your nutrition update request. Please be more specific about what you'd like to change."
      };
    } catch (e) {
      debugPrint('Error processing nutrition updates: $e');
      return {
        "success": false,
        "message": "I encountered an error while trying to update your nutrition plan. Please try again with a more specific request."
      };
    }
  }

  // Process a user request to update their workout or nutrition plan
  static Future<Map<String, dynamic>> processUserPlanUpdate(String userId, String userMessage) async {
    try {
      // Check for direct JSON-like instructions in the message (used for workout instruction updates)
      if (userMessage.contains('{"updateType": "instructions"')) {
        try {
          // Extract the JSON part
          int jsonStart = userMessage.indexOf('{');
          int jsonEnd = userMessage.lastIndexOf('}') + 1;
          
          if (jsonStart >= 0 && jsonEnd > jsonStart) {
            String jsonPart = userMessage.substring(jsonStart, jsonEnd);
            Map<String, dynamic> instructionUpdate = jsonDecode(jsonPart);
            
            // Get current workout plan
            Map<String, dynamic>? workoutPlan = await McpService.getLatestWorkoutPlan(userId);
            
            // Process the instruction update
            return await _processWorkoutUpdates(userId, instructionUpdate, workoutPlan);
          }
        } catch (e) {
          debugPrint('Error parsing instruction update JSON: $e');
        }
      }
      
      // Get current workout and nutrition plans to provide context
      Map<String, dynamic>? workoutPlan = await McpService.getLatestWorkoutPlan(userId);
      Map<String, dynamic>? nutritionPlan = await McpService.getLatestNutritionPlan(userId);
      
      // Check for instruction-specific keywords
      bool likelyInstructionUpdate = userMessage.toLowerCase().contains('instruction') ||
                                    userMessage.toLowerCase().contains('clearer') ||
                                    userMessage.toLowerCase().contains('steps') ||
                                    userMessage.toLowerCase().contains('unclear');
                                    
      // Create prompt for Gemini
      String prompt = '';
      
      if (likelyInstructionUpdate) {
        prompt = '''
You are an AI assistant that helps update fitness workout instructions based on user requests.
The user wants clearer or better instructions for exercises in their workout plan.

User message: "$userMessage"

Current workout plan summary:
${workoutPlan != null ? 'Plan ID: ${workoutPlan['plan']?['id'] ?? 'N/A'}' : 'No workout plan available'}
${_formatWorkoutPlanSummary(workoutPlan)}

Return ONLY a valid JSON object with this structure:
{
  "intent": "update_instructions",
  "updates": {
    "workout": {
      "shouldUpdate": true,
      "updateType": "instructions",
      "exerciseId": "exercise_id_here",
      "newInstructions": "Clearer instructions here"
    }
  },
  "userFriendlyResponse": "I've updated the instructions for [exercise name] to be clearer."
}
''';
      } else {
        prompt = '''
You are an AI assistant that helps update fitness and nutrition plans based on user requests.
Analyze the user's message and determine if they want to update their workout or nutrition plan.

User message: "$userMessage"

Current workout plan summary:
${workoutPlan != null ? 'Plan ID: ${workoutPlan['plan']?['id'] ?? 'N/A'}' : 'No workout plan available'}
${_formatWorkoutPlanSummary(workoutPlan)}

Current nutrition plan summary:
${nutritionPlan != null ? 'Plan ID: ${nutritionPlan['plan']?['id'] ?? 'N/A'}' : 'No nutrition plan available'}
${_formatNutritionPlanSummary(nutritionPlan)}

Return ONLY a valid JSON object with this structure:
{
  "intent": "update_plan",
  "updates": {
    "workout": {
      "shouldUpdate": true/false,
      "updateType": "full_plan/day/exercise",
      "dayOfWeek": 1-7 (if applicable),
      "exerciseId": "exercise_id_here" (if applicable),
      "changes": {
        // Specific changes to make
      }
    },
    "nutrition": {
      "shouldUpdate": true/false,
      "updateType": "full_plan/day/meal",
      "dayOfWeek": 1-7 (if applicable),
      "mealId": "meal_id_here" (if applicable),
      "changes": {
        // Specific changes to make
      }
    }
  },
  "userFriendlyResponse": "A friendly message explaining what changes will be made."
}
''';
      }
      
      // Configure Gemini model
      final model = GenerativeModel(
        model: 'gemini-1.5-pro',
        apiKey: AppConfig.geminiApiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          maxOutputTokens: 2048,
        ),
      );
      
      // Generate content with Gemini
      final response = await model.generateContent([Content.text(prompt)]);
      String jsonText = response.text ?? '';
      
      if (jsonText.isEmpty) {
        return {
          "success": false,
          "message": "Failed to analyze your request. Please try being more specific about what changes you'd like to make to your plan."
        };
      }
      
      // Clean and parse the response
      if (jsonText.contains("```json")) {
        jsonText = jsonText.replaceAll("```json", "").replaceAll("```", "");
      } else if (jsonText.contains("```")) {
        jsonText = jsonText.replaceAll("```", "");
      }
      
      // Find the start and end of the JSON object
      int startBrace = jsonText.indexOf('{');
      int endBrace = jsonText.lastIndexOf('}');
      
      if (startBrace == -1 || endBrace == -1 || startBrace > endBrace) {
        return {
          "success": false,
          "message": "I couldn't process your update request properly. Could you please rephrase what changes you'd like to make to your plan?"
        };
      }
      
      // Extract just the JSON part
      jsonText = jsonText.substring(startBrace, endBrace + 1);
      
      try {
        // Parse the JSON
        final updateInstructions = Map<String, dynamic>.from(jsonDecode(jsonText));
        
        // Check if we should perform an update
        if (updateInstructions['intent'] == 'no_update') {
          return {
            "success": true,
            "changes_made": false,
            "message": updateInstructions['userFriendlyResponse'] ?? "I couldn't detect a specific plan update request in your message. Please try being more specific about what changes you'd like to make."
          };
        }
        
        // Process the updates based on the instructions
        final updates = updateInstructions['updates'];
        bool changesMade = false;
        String updateSummary = "";
        
        // Process workout updates if needed
        if (updates['workout']?['shouldUpdate'] == true) {
          final workoutUpdates = await _processWorkoutUpdates(userId, updates['workout'], workoutPlan);
          changesMade = changesMade || workoutUpdates['success'];
          updateSummary += workoutUpdates['message'] + "\n\n";
        }
        
        // Process nutrition updates if needed
        if (updates['nutrition']?['shouldUpdate'] == true) {
          final nutritionUpdates = await _processNutritionUpdates(userId, updates['nutrition'], nutritionPlan);
          changesMade = changesMade || nutritionUpdates['success'];
          updateSummary += nutritionUpdates['message'];
        }
        
        // Return the result
        return {
          "success": true,
          "changes_made": changesMade,
          "message": updateSummary.isNotEmpty 
            ? updateSummary 
            : updateInstructions['userFriendlyResponse'] ?? "I've processed your request, but couldn't make any specific updates to your plan."
        };
        
      } catch (e) {
        debugPrint('Error processing plan update: $e');
        return {
          "success": false,
          "message": "I encountered an error while trying to update your plan. Please try again with more specific instructions."
        };
      }
    } catch (e) {
      debugPrint('Error in processUserPlanUpdate: $e');
      return {
        "success": false,
        "message": "Sorry, I encountered an error while trying to update your plan. Please try again later."
      };
    }
  }

  /// Generate a chat response based on user's message
  static Future<String> generateChatResponse(String userId, String message) async {
    try {
      debugPrint('Generating chat response for message: $message');
      
      // Get user profile
      final userProfile = await McpService.getUserProfile(userId);
      
      // Get latest workout plan
      final workoutPlan = await McpService.getLatestWorkoutPlan(userId);
      
      // Get latest nutrition plan
      final nutritionPlan = await McpService.getLatestNutritionPlan(userId);
      
      // Prepare user profile summary for the system prompt
      final userProfileSummary = _formatUserProfile(userProfile);
      
      // Get current date and day of week information
      final now = DateTime.now();
      final currentDayOfWeek = now.weekday; // 1 = Monday, 7 = Sunday
      final currentDayName = _getDayName(currentDayOfWeek);
      final currentDate = "${now.day}/${now.month}/${now.year}";
      
      // Create summary of workout plan if exists
      String workoutPlanSummary = "No workout plan available.";
      String todaysWorkoutSummary = "No workout scheduled for today.";
      
      if (workoutPlan != null) {
        final planData = workoutPlan['plan'];
        final daysData = workoutPlan['days'] as List;
        workoutPlanSummary = "WORKOUT PLAN: ${planData['plan_name']}\n";
        workoutPlanSummary += "Type: ${planData['plan_type']}\n";
        workoutPlanSummary += "Difficulty: ${planData['plan_difficulty']}\n";
        workoutPlanSummary += "Days per week: ${planData['days_per_week']}\n\n";
        
        // Find today's workout
        Map<String, dynamic>? todaysWorkout;
        for (var day in daysData) {
          if (day['day_of_week'] == currentDayOfWeek) {
            todaysWorkout = day;
          }
          
          workoutPlanSummary += "Day ${day['day_of_week']} (${_getDayName(day['day_of_week'])}): ${day['workout_type']}\n";
          final exercises = day['exercises'] as List;
          for (var exercise in exercises) {
            workoutPlanSummary += "- ${exercise['exercise_name']}: ${exercise['sets']} sets of ${exercise['reps']}\n";
          }
          workoutPlanSummary += "\n";
        }
        
        // Format today's workout summary if found
        if (todaysWorkout != null) {
          todaysWorkoutSummary = "TODAY'S WORKOUT (${currentDayName}):\n";
          todaysWorkoutSummary += "Focus: ${todaysWorkout['workout_type']}\n";
          
          final exercises = todaysWorkout['exercises'] as List;
          if (exercises.isNotEmpty) {
            todaysWorkoutSummary += "Exercises:\n";
            for (var exercise in exercises) {
              todaysWorkoutSummary += "- ${exercise['exercise_name']}: ${exercise['sets']} sets of ${exercise['reps']}\n";
            }
          } else {
            todaysWorkoutSummary += "No exercises scheduled for today.\n";
          }
        }
      }
      
      // Create summary of nutrition plan if exists
      String nutritionPlanSummary = "No nutrition plan available.";
      String todaysNutritionSummary = "No nutrition plan scheduled for today.";
      
      if (nutritionPlan != null) {
        final planData = nutritionPlan['plan'];
        final daysData = nutritionPlan['days'] as List;
        
        nutritionPlanSummary = "NUTRITION PLAN:\n";
        nutritionPlanSummary += "Daily calories: ${planData['total_daily_calories']}\n";
        nutritionPlanSummary += "Protein: ${planData['protein_daily_grams']}g, Carbs: ${planData['carbs_daily_grams']}g, Fat: ${planData['fat_daily_grams']}g\n\n";
        
        // Find today's nutrition plan
        Map<String, dynamic>? todaysNutrition;
        for (var day in daysData) {
          if (day['day_of_week'] == currentDayOfWeek) {
            todaysNutrition = day;
          }
          
          nutritionPlanSummary += "Day ${day['day_of_week']} (${_getDayName(day['day_of_week'])}):\n";
          final meals = day['meals'] as List;
          for (var meal in meals) {
            nutritionPlanSummary += "- ${meal['meal_name']} (${meal['meal_time']}): ${meal['total_calories']} calories\n";
          }
          nutritionPlanSummary += "\n";
        }
        
        // Format today's nutrition summary if found
        if (todaysNutrition != null) {
          todaysNutritionSummary = "TODAY'S NUTRITION PLAN (${currentDayName}):\n";
          todaysNutritionSummary += "Total calories: ${todaysNutrition['total_calories']}\n";
          
          final meals = todaysNutrition['meals'] as List;
          if (meals.isNotEmpty) {
            todaysNutritionSummary += "Meals:\n";
            for (var meal in meals) {
              todaysNutritionSummary += "- ${meal['meal_name']} (${meal['meal_time']}): ${meal['total_calories']} calories\n";
              todaysNutritionSummary += "  Protein: ${meal['protein_grams']}g, Carbs: ${meal['carbs_grams']}g, Fat: ${meal['fat_grams']}g\n";
            }
          } else {
            todaysNutritionSummary += "No specific meals scheduled for today.\n";
          }
        }
      }
      
      // Build the system prompt
      final systemPrompt = '''
You are an AI fitness coach and nutrition expert named FitCoach. Your goal is to provide personalized fitness and nutrition guidance.

CURRENT DATE: $currentDate (${currentDayName})

USER PROFILE:
$userProfileSummary

TODAY'S WORKOUT:
$todaysWorkoutSummary

TODAY'S NUTRITION PLAN:
$todaysNutritionSummary

FULL WORKOUT PLAN:
$workoutPlanSummary

FULL NUTRITION PLAN:
$nutritionPlanSummary

GUIDELINES:
1. Be friendly, motivational, and positive in your responses
2. Provide personalized advice based on the user's profile and current plans
3. If asked about specific exercises, explain proper form and technique
4. If asked about nutrition, provide science-based recommendations
5. Always encourage healthy habits and sustainable approaches
6. Keep responses concise and focused on the user's question
7. If the user asks about updating their plan, guide them through the process
8. Use an encouraging but professional tone
9. Always prioritize TODAY'S workout and nutrition information when the user asks about "today"
10. Be aware of the current day of the week ($currentDayName) when discussing scheduling

Please respond to the user's message in a helpful and supportive way.
''';
      
      // Create generative model
      final model = GenerativeModel(
        model: 'gemini-1.5-pro',
        apiKey: AppConfig.geminiApiKey,
        systemInstruction: Content.text(systemPrompt),
      );
      
      // Generate the response
      final content = [Content.text(message)];
      final response = await model.generateContent(content);
      
      // Clean up the response text
      final responseText = response.text?.trim() ?? 'I encountered an error generating a response. Please try again.';
      
      return responseText;
    } catch (e) {
      debugPrint('Error generating chat response: $e');
      return "I'm sorry, I encountered an error while processing your message. Please try again later.";
    }
  }
  
  /// Format user profile for system prompt
  static String _formatUserProfile(Map<String, dynamic>? userProfile) {
    if (userProfile == null) return "No user profile available.";
    
    final buffer = StringBuffer();
    
    buffer.writeln("Name: ${userProfile['full_name'] ?? 'Not specified'}");
    buffer.writeln("Age: ${userProfile['age'] ?? 'Not specified'}");
    buffer.writeln("Gender: ${userProfile['gender'] ?? 'Not specified'}");
    buffer.writeln("Height: ${userProfile['height_cm'] ?? 'Not specified'} cm");
    buffer.writeln("Weight: ${userProfile['weight_kg'] ?? 'Not specified'} kg");
    buffer.writeln("Fitness Level: ${userProfile['fitness_level'] ?? 'Not specified'}");
    buffer.writeln("Primary Goal: ${userProfile['primary_fitness_goal'] ?? 'Not specified'}");
    buffer.writeln("Equipment Access: ${userProfile['equipment_access'] ?? 'Not specified'}");
    buffer.writeln("Workout Days: ${userProfile['workout_days_per_week'] ?? 'Not specified'} days per week");
    
    // Add diet preferences if available
    if (userProfile['dietary_restrictions'] != null) {
      buffer.writeln("Dietary Restrictions: ${userProfile['dietary_restrictions']}");
    }
    
    // Add favorite foods if available
    if (userProfile['favorite_foods'] != null && userProfile['favorite_foods'].isNotEmpty) {
      buffer.writeln("Favorite Foods: ${userProfile['favorite_foods']}");
    }
    
    // Add avoided foods if available
    if (userProfile['avoided_foods'] != null && userProfile['avoided_foods'].isNotEmpty) {
      buffer.writeln("Avoided Foods: ${userProfile['avoided_foods']}");
    }
    
    // Add health concerns if available
    if (userProfile['fitness_concerns'] != null && userProfile['fitness_concerns'].isNotEmpty) {
      buffer.writeln("Health Concerns: ${userProfile['fitness_concerns']}");
    }
    
    return buffer.toString();
  }

  /// Build system prompt for workout plan generation
  static String _buildWorkoutPlanSystemPrompt(Map<String, dynamic> userProfile) {
    // Extract user profile data with defaults
    final age = userProfile['age'] ?? 30;
    final gender = userProfile['gender'] ?? 'not specified';
    final fitnessLevel = userProfile['fitness_level'] ?? 'beginner';
    final fitnessGoal = userProfile['primary_fitness_goal'] ?? 'general fitness';
    final weight = userProfile['weight_kg'] ?? 70;
    final height = userProfile['height_cm'] ?? 170;
    final workoutDays = userProfile['workout_days_per_week'] ?? 3;
    final equipment = userProfile['equipment_access'] ?? 'minimal';
    final concerns = userProfile['fitness_concerns'] ?? '';
    final specificTargets = userProfile['specific_targets'] ?? '';
    final additionalNotes = userProfile['additional_notes'] ?? '';
    
    return '''
You are FitAAI, an AI fitness coach specializing in creating personalized workout plans. 
Your task is to create a detailed, appropriate workout plan based on the user's profile.

USER PROFILE:
- Age: $age
- Gender: $gender
- Fitness Level: $fitnessLevel
- Primary Fitness Goal: $fitnessGoal
- Specific Targets: $specificTargets
- Weight: $weight kg
- Height: $height cm
- Workout Days: $workoutDays days per week
- Equipment Access: $equipment
- Health Concerns: $concerns
- Additional Notes: $additionalNotes

RESPONSE FORMAT:
You must return a valid JSON object (NOT a string) with the following structure:

{
  "plan_name": "Name of the workout plan",
  "plan_description": "Brief description of the workout plan",
  "plan_type": "The type of workout (e.g., strength, hypertrophy, cardio)",
  "workout_days": [
    {
      "day_of_week": 1,
      "workout_type": "Type of workout for this day",
      "session_duration_minutes": 60,
      "estimated_calories": 300,
      "equipment_needed": "Equipment needed for this day",
      "notes": "Any additional notes for this day",
      "warm_up": ["warm up exercise 1", "warm up exercise 2"],
      "exercises": [
        {
          "name": "Exercise name",
          "sets": 3,
          "reps": "8-12",
          "rest": "60s",
          "notes": "Form tips and instructions",
          "equipment": "Equipment needed for this exercise"
        }
      ],
      "cool_down": ["cool down exercise 1", "cool down exercise 2"]
    }
  ]
}

IMPORTANT GUIDELINES:
1. Generate a plan appropriate for the user's fitness level and goals
2. Include proper warm-up and cool-down routines
3. Consider any health concerns in exercise selection
4. Provide detailed instructions for each exercise
5. Ensure the plan follows progressive overload principles
6. Include rest days as appropriate
7. Provide modifications for exercises if needed
8. Be specific about sets, reps, and rest periods
9. Adapt exercises based on available equipment
10. Day of week should be 1-7 (1=Monday, 7=Sunday)
11. The exercises array must be an array of objects, each containing name, sets, reps, rest, and notes

DO NOT include any markdown formatting, explanations, or text outside the JSON. Return ONLY the JSON object.
''';
  }
} 