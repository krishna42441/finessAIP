import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart'; // Import for supabase client
import '../config.dart';

class GeminiService {
  // Get Gemini API key from config
  static final String _apiKey = AppConfig.geminiApiKey;

  // Generate both nutrition and workout plans for a user
  static Future<Map<String, dynamic>> generatePlans(String userId) async {
    try {
      // Get user profile data
      final userProfile = await supabase
          .from('user_profiles')
          .select('*')
          .eq('user_id', userId)
          .single();
      
      debugPrint('Generating AI plans for user: $userId');
      
      // Generate workout plan
      final workoutPlan = await generateWorkoutPlan(userProfile);
      
      // Generate nutrition plan
      final nutritionPlan = await generateNutritionPlan(userProfile);
      
      // Store the workout plan in the database
      final workoutPlanId = await _storeWorkoutPlan(userId, workoutPlan, userProfile);
      
      // Store the nutrition plan in the database
      final nutritionPlanId = await _storeNutritionPlan(userId, nutritionPlan);
      
      return {
        'success': true,
        'message': 'AI-generated plans created successfully',
        'workout_plan_id': workoutPlanId,
        'nutrition_plan_id': nutritionPlanId,
      };
    } catch (e) {
      debugPrint('Error generating AI plans: $e');
      
      // Fallback to mock data if there's an error
      return {
        'success': false,
        'message': 'Failed to generate AI plans: $e',
        'workout_plan_id': null,
        'nutrition_plan_id': null,
      };
    }
  }

  // Clean and repair potentially malformed JSON from AI responses
  static String _aggressiveJsonCleaning(String json) {
    // Remove any potential line comments
    final lines = json.split('\n')
      .where((line) => !line.trim().startsWith('//'))
      .join('\n');
    
    // Fix common JSON structure issues
    String fixedJson = lines;
    
    // Fix missing commas between array elements
    fixedJson = fixedJson.replaceAll(RegExp(r'}\s*{'), '}, {');
    fixedJson = fixedJson.replaceAll(RegExp(r'"\s*{'), '", {');
    fixedJson = fixedJson.replaceAll(RegExp(r'}\s*"'), '}, "');
    
    // Fix trailing commas before closing brackets
    fixedJson = fixedJson.replaceAll(RegExp(r',(\s*[\]}])'), r'$1');
    
    // Fix missing closing brackets/braces by counting
    int openBraces = fixedJson.split('{').length - 1;
    int closeBraces = fixedJson.split('}').length - 1;
    int openBrackets = fixedJson.split('[').length - 1;
    int closeBrackets = fixedJson.split(']').length - 1;
    
    // Add missing closing braces/brackets
    if (openBraces > closeBraces) {
      fixedJson += '}' * (openBraces - closeBraces);
    }
    if (openBrackets > closeBrackets) {
      fixedJson += ']' * (openBrackets - closeBrackets);
    }
    
    // Get the basic structure right - find complete days array
    final daysStart = fixedJson.indexOf('"days": [');
    if (daysStart != -1) {
      try {
        // Try to parse the JSON as is
        jsonDecode(fixedJson);
        return fixedJson;
      } catch (e) {
        // If parsing fails, try to fix the days array
        try {
          // Count opening and closing brackets to find the end of the array
          int depth = 0;
          int pos = daysStart + 8; // position after '"days": ['
          
          // Skip the whitespace
          while (pos < fixedJson.length && (fixedJson[pos] == ' ' || fixedJson[pos] == '\n' || fixedJson[pos] == '\t')) {
            pos++;
          }
          
          // If we find the start of an object, begin tracking depth
          if (pos < fixedJson.length && fixedJson[pos] == '{') {
            depth = 1;
            pos++;
            
            // Find all valid day objects
            List<String> validDayObjects = [];
            int startPos = pos - 1; // Include the opening brace
            
            while (pos < fixedJson.length) {
              if (fixedJson[pos] == '{') depth++;
              if (fixedJson[pos] == '}') {
                depth--;
                if (depth == 0) {
                  // We've found a complete day object
                  String dayObject = fixedJson.substring(startPos, pos + 1);
                  validDayObjects.add(dayObject);
                  
                  // Check if there's another object
                  int nextObjStart = -1;
                  for (int i = pos + 1; i < fixedJson.length; i++) {
                    if (fixedJson[i] == '{') {
                      nextObjStart = i;
                      break;
                    } else if (fixedJson[i] == ']') {
                      // We've reached the end of the array
                      break;
                    }
                  }
                  
                  if (nextObjStart == -1) {
                    break; // No more objects in the array
                  } else {
                    startPos = nextObjStart;
                    pos = nextObjStart + 1;
                    depth = 1;
                  }
                }
              }
              if (pos < fixedJson.length) pos++;
            }
            
            // Create a repaired JSON with valid day objects
            String repairedJson = fixedJson.substring(0, daysStart + 8); // up to '"days": ['
            for (int i = 0; i < validDayObjects.length; i++) {
              repairedJson += validDayObjects[i];
              if (i < validDayObjects.length - 1) {
                repairedJson += ",";
              }
            }
            repairedJson += "]}";
            
            return repairedJson;
          }
        } catch (e) {
          debugPrint('Error in advanced JSON repair: $e');
        }
      }
    }
    
    // If we can't fix it properly, return the original with basic fixes
    return fixedJson;
  }

  // Generate a workout plan using Gemini AI
  static Future<Map<String, dynamic>> generateWorkoutPlan(Map<String, dynamic> userProfile) async {
    try {
      // Configure Gemini model
      final model = GenerativeModel(
        model: 'gemini-1.5-pro',
        apiKey: _apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          maxOutputTokens: 2048,
        ),
      );
      
      // Prepare user-specific information for the prompt
      final age = userProfile['age'] ?? 30;
      final gender = userProfile['gender'] ?? 'Not specified';
      final fitnessLevel = userProfile['fitness_level'] ?? 'Beginner';
      final fitnessGoal = userProfile['primary_fitness_goal'] ?? 'General fitness';
      final weight = userProfile['weight_kg'] ?? 70; // kg
      final height = userProfile['height_cm'] ?? 170; // cm
      final limitations = userProfile['fitness_concerns'] ?? 'None';
      
      // Get user's workout preferences
      final workoutDaysPerWeek = userProfile['workout_days_per_week'] ?? 3;
      final workoutMinutesPerSession = userProfile['workout_minutes_per_session'] ?? 45;
      final indoorOutdoorPreference = userProfile['indoor_outdoor_preference'] ?? 'Both';
      final equipmentAccess = userProfile['equipment_access'] ?? 'Basic home equipment';
      final specificTargets = userProfile['specific_targets'] ?? 'Full body';
      final workoutPreferences = userProfile['workout_preferences'] ?? {};
      
      // Create the prompt for Gemini
      final prompt = '''
Create a personalized workout plan for a ${age}-year-old ${gender} with the following details:
- Fitness level: ${fitnessLevel}
- Primary goal: ${fitnessGoal}
- Weight: ${weight} kg
- Height: ${height} cm
- Physical limitations or concerns: ${limitations}
- Specific target areas: ${specificTargets}
- Preferred workout days per week: ${workoutDaysPerWeek}
- Workout session duration: ${workoutMinutesPerSession} minutes
- Indoor/outdoor preference: ${indoorOutdoorPreference}
- Equipment access: ${equipmentAccess}

Return ONLY a valid JSON object with this structure and nothing else - no explanation text before or after the JSON, no comments within the JSON:
{
  "planName": "Name of the workout plan",
  "planDescription": "Description of the plan and how it helps achieve the user's goals",
  "planType": "Type of plan (e.g., 'Muscle Building', 'Weight Loss', 'General Fitness')",
  "days": [
    {
      "dayOfWeek": 1,
      "focusArea": "Name of the body area or focus (e.g., 'Chest and Triceps')",
      "exercises": [
        {
          "name": "Exercise name",
          "sets": 3,
          "reps": "8-12",
          "instructions": "How to perform the exercise correctly",
          "restTime": "60 seconds"
        }
      ]
    }
  ]
}

Important notes:
1. Only include ${workoutDaysPerWeek} workout days per week, with the rest being rest days (no exercises)
2. Design exercises appropriate for ${indoorOutdoorPreference} settings with ${equipmentAccess}
3. Sessions should be around ${workoutMinutesPerSession} minutes in duration
4. Focus particularly on ${specificTargets} as requested by the user
5. Ensure the plan difficulty matches the user's fitness level: ${fitnessLevel}
6. Make sure the JSON is properly formatted and valid
''';
      
      // Generate content with Gemini
      final response = await model.generateContent([Content.text(prompt)]);
      String jsonText = response.text ?? '';
      
      if (jsonText.isEmpty) {
        throw Exception('Empty response from Gemini API');
      }
      
      debugPrint('Raw JSON response: ${jsonText.substring(0, math.min(100, jsonText.length))}...');
      
      // Clean up the response - Gemini might return markdown-formatted JSON
      String cleanedJson = jsonText;
      
      // Remove markdown code blocks if present
      if (cleanedJson.contains("```json")) {
        cleanedJson = cleanedJson.replaceAll("```json", "").replaceAll("```", "");
      } else if (cleanedJson.contains("```")) {
        cleanedJson = cleanedJson.replaceAll("```", "");
      }
      
      // Find the start and end of the JSON object
      int startBrace = cleanedJson.indexOf('{');
      int endBrace = cleanedJson.lastIndexOf('}');
      
      if (startBrace == -1 || endBrace == -1 || startBrace > endBrace) {
        throw Exception('Invalid JSON format in response: $cleanedJson');
      }
      
      // Extract just the JSON part, ignoring any text before or after
      cleanedJson = cleanedJson.substring(startBrace, endBrace + 1);
      
      // Remove any potential inline comments (like "// ...") which are not valid JSON
      RegExp commentRegex = RegExp(r'\/\/.*(?=\n|$)');
      cleanedJson = cleanedJson.replaceAll(commentRegex, '');
      
      // Replace any trailing commas before closing brackets (common JSON error)
      cleanedJson = cleanedJson.replaceAll(RegExp(r',(\s*[\]}])'), r'$1');
      
      // Trim any leading/trailing whitespace
      cleanedJson = cleanedJson.trim();
      
      debugPrint('Cleaned JSON: $cleanedJson');
      
      try {
        // Parse the response as JSON
        final workoutPlan = Map<String, dynamic>.from(
          jsonDecode(cleanedJson) as Map
        );
        
        return workoutPlan;
      } catch (jsonError) {
        debugPrint('JSON parsing error: $jsonError');
        
        // Attempt more aggressive cleaning if parsing fails
        cleanedJson = _aggressiveJsonCleaning(cleanedJson);
        
        // Try parsing again
        final workoutPlan = Map<String, dynamic>.from(
          jsonDecode(cleanedJson) as Map
        );
        
        return workoutPlan;
      }
    } catch (e) {
      debugPrint('Error generating workout plan with Gemini: $e');
      throw Exception('Failed to generate workout plan: $e');
    }
  }

  // Generate a nutrition plan using Gemini AI
  static Future<Map<String, dynamic>> generateNutritionPlan(Map<String, dynamic> userProfile) async {
    try {
      // Configure Gemini model
      final model = GenerativeModel(
        model: 'gemini-1.5-pro',
        apiKey: _apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          maxOutputTokens: 2048,
        ),
      );
      
      // Prepare user-specific information for the prompt
      final age = userProfile['age'] ?? 30;
      final gender = userProfile['gender'] ?? 'Not specified';
      final fitnessGoal = userProfile['primary_fitness_goal'] ?? 'General fitness';
      final weight = userProfile['weight_kg'] ?? 70; // kg
      final height = userProfile['height_cm'] ?? 170; // cm
      final workoutDaysPerWeek = userProfile['workout_days_per_week'] ?? 3;
      
      // Detailed diet and nutrition preferences
      final eatingHabits = userProfile['eating_habits'] ?? 'No specific habits';
      final favoriteFoods = userProfile['favorite_foods'] ?? 'Not specified';
      final avoidedFoods = userProfile['avoided_foods'] ?? 'Not specified';
      final dietaryRestrictions = userProfile['dietary_restrictions'] ?? {};
      
      // Health factors
      final activityLevel = userProfile['daily_activity_level'] ?? 'Moderate';
      final sleepHours = userProfile['sleep_hours'] ?? 7;
      final stressLevel = userProfile['stress_level'] ?? 'Medium';
      
      // Create strings from dietary restrictions map
      String dietRestrictionsText = "None specified";
      if (dietaryRestrictions is Map && dietaryRestrictions.isNotEmpty) {
        dietRestrictionsText = dietaryRestrictions.entries
            .where((entry) => entry.value == true)
            .map((entry) => entry.key)
            .join(', ');
      }
      
      // Create the prompt for Gemini
      final prompt = '''
Create a personalized nutrition plan for a ${age}-year-old ${gender} with the following details:
- Primary fitness goal: ${fitnessGoal}
- Weight: ${weight} kg
- Height: ${height} cm
- Workout days per week: ${workoutDaysPerWeek}
- Eating habits: ${eatingHabits}
- Favorite foods: ${favoriteFoods}
- Avoided foods: ${avoidedFoods}
- Dietary restrictions: ${dietRestrictionsText}
- Daily activity level: ${activityLevel}
- Sleep hours: ${sleepHours}
- Stress level: ${stressLevel}

Return ONLY a valid JSON object with this structure and nothing else:
{
  "dailyCalories": 2000,
  "workoutDayCalories": 2200,
  "restDayCalories": 1800,
  "macroDistribution": {
    "protein": "30% (150g)",
    "carbs": "50% (250g)",
    "fat": "20% (44g)"
  },
  "days": [
    {
      "dayOfWeek": 1,
      "isWorkoutDay": true,
      "total_calories": 2200,
      "total_protein": 165,
      "total_carbs": 275,
      "total_fat": 49,
      "waterIntake": "3-4 liters",
      "mealTimingRecommendation": "Eat 4-6 smaller meals, spaced 2-3 hours apart",
      "preworkoutNutrition": "Consume ~300 calories with 25g protein and 40g carbs 1-2 hours before workout",
      "postworkoutNutrition": "Consume 25-30g protein and 30-40g carbs within 30 minutes after training",
      "micronutrients": {
        "vitamin_a": "700-900 mcg",
        "vitamin_c": "75-90 mg",
        "calcium": "1000-1200 mg",
        "iron": "8-18 mg",
        "potassium": "3500-4700 mg"
      },
      "notes": "Focus on complex carbs and lean proteins throughout the day."
    }
  ]
}

Important notes:
1. Include exactly ${workoutDaysPerWeek} workout days, with the rest being rest days
2. Take into account the user's eating habits, dietary restrictions, and food preferences
3. Provide appropriate pre-workout and post-workout nutrition guidance on workout days
4. Adjust calorie intake based on activity level (${activityLevel}) and fitness goal (${fitnessGoal})
5. Consider how stress level (${stressLevel}) and sleep hours (${sleepHours}) might impact nutrition needs
6. DO NOT include specific meals or food recommendations - focus only on macronutrient targets, timing, and general guidelines
7. Include relevant micronutrient targets based on the user's goals
''';
      
      // Generate content with Gemini
      final response = await model.generateContent([Content.text(prompt)]);
      String jsonText = response.text ?? '';
      
      if (jsonText.isEmpty) {
        throw Exception('Empty response from Gemini API');
      }
      
      debugPrint('Raw nutrition JSON: ${jsonText.substring(0, math.min(100, jsonText.length))}...');
      
      // Clean up the response following the same pattern as for workout plans
      String cleanedJson = jsonText;
      
      // Remove markdown code blocks if present
      if (cleanedJson.contains("```json")) {
        cleanedJson = cleanedJson.replaceAll("```json", "").replaceAll("```", "");
      } else if (cleanedJson.contains("```")) {
        cleanedJson = cleanedJson.replaceAll("```", "");
      }
      
      // Find the start and end of the JSON object
      int startBrace = cleanedJson.indexOf('{');
      int endBrace = cleanedJson.lastIndexOf('}');
      
      if (startBrace == -1 || endBrace == -1 || startBrace > endBrace) {
        throw Exception('Invalid JSON format in nutrition response');
      }
      
      // Extract just the JSON part
      cleanedJson = cleanedJson.substring(startBrace, endBrace + 1);
      
      // Additional cleanup
      RegExp commentRegex = RegExp(r'\/\/.*(?=\n|$)');
      cleanedJson = cleanedJson.replaceAll(commentRegex, '');
      cleanedJson = cleanedJson.replaceAll(RegExp(r',(\s*[\]}])'), r'$1');
      cleanedJson = cleanedJson.trim();
      
      try {
        // Parse the response as JSON
        final nutritionPlan = Map<String, dynamic>.from(
          jsonDecode(cleanedJson) as Map
        );
        
        return nutritionPlan;
      } catch (jsonError) {
        debugPrint('Nutrition JSON parsing error: $jsonError');
        
        // Attempt more aggressive cleaning
        cleanedJson = _aggressiveJsonCleaning(cleanedJson);
        
        // Try parsing again
        final nutritionPlan = Map<String, dynamic>.from(
          jsonDecode(cleanedJson) as Map
        );
        
        return nutritionPlan;
      }
    } catch (e) {
      debugPrint('Error generating nutrition plan with Gemini: $e');
      throw Exception('Failed to generate nutrition plan: $e');
    }
  }
  
  // Store the generated workout plan in the database
  static Future<String> _storeWorkoutPlan(String userId, Map<String, dynamic> plan, Map<String, dynamic> userProfile) async {
    try {
      // Create a UUID for the plan
      final planId = const Uuid().v4();
      final now = DateTime.now();
      
      // Count the number of days in the plan that have exercises
      int daysPerWeek = 0;
      if (plan['days'] != null && plan['days'] is List) {
        for (var day in plan['days']) {
          if (day['exercises'] != null && day['exercises'] is List && day['exercises'].isNotEmpty) {
            daysPerWeek++;
          }
        }
      }
      
      // Insert the main workout plan record
      await supabase.from('workout_plans').insert({
        'id': planId,
        'user_id': userId,
        'plan_name': plan['planName'],
        'plan_description': plan['planDescription'],
        'plan_type': plan['planType'],
        'plan_difficulty': userProfile['fitness_level'] ?? 'Intermediate',
        'days_per_week': daysPerWeek,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'start_date': now.toIso8601String().split('T')[0],
        'end_date': now.add(const Duration(days: 28)).toIso8601String().split('T')[0],
      });
      
      // Insert the workout days and exercises
      for (var day in plan['days']) {
        // Create a day record
        final dayId = const Uuid().v4();
        await supabase.from('workout_plan_days').insert({
          'id': dayId,
          'plan_id': planId,
          'day_of_week': day['dayOfWeek'],
          'workout_type': day['focusArea'],
          'session_duration_minutes': 60,  // Default value
          'estimated_calories': 300,  // Default value
          'equipment_needed': 'Basic gym equipment',  // Default value
          'notes': 'Follow instructions carefully for each exercise'  // Default value
        });
        
        // Insert exercises for this day
        if (day['exercises'] != null && day['exercises'].isNotEmpty) {
          int exerciseOrder = 0;
          for (var exercise in day['exercises']) {
            // Convert rest time from string (e.g., "60 seconds") to integer seconds
            int restSeconds = 60; // Default
            if (exercise['restTime'] != null && exercise['restTime'] != 'N/A') {
              final restMatch = RegExp(r'(\d+)').firstMatch(exercise['restTime'].toString());
              if (restMatch != null) {
                restSeconds = int.tryParse(restMatch.group(1) ?? '60') ?? 60;
              }
            }
            
            await supabase.from('workout_exercises').insert({
              'id': const Uuid().v4(),
              'day_id': dayId,
              'exercise_name': exercise['name'],
              'sets': exercise['sets'],
              'reps': exercise['reps'],
              'instructions': exercise['instructions'],
              'rest_seconds': restSeconds,
              'exercise_order': exerciseOrder++,
              'equipment': 'Standard gym equipment', // Default value
              'muscle_group': day['focusArea'], // Use focus area as muscle group
            });
          }
        }
      }
      
      return planId;
    } catch (e) {
      debugPrint('Error storing workout plan: $e');
      throw Exception('Failed to store workout plan in database: $e');
    }
  }

  // Store the generated nutrition plan in the database
  static Future<String> _storeNutritionPlan(String userId, Map<String, dynamic> plan) async {
    try {
      // Create a UUID for the plan
      final planId = const Uuid().v4();
      final now = DateTime.now();
      
      // Extract macro values and convert to actual grams
      Map<String, dynamic> macros = {};
      if (plan['macroDistribution'] != null) {
        // Cast the LinkedMap to Map<String, dynamic>
        macros = Map<String, dynamic>.from(plan['macroDistribution'] as Map);
      }
      
      int proteinGrams = 0;
      int carbsGrams = 0;
      int fatGrams = 0;
      int dailyCalories = plan['dailyCalories'] ?? 2500;
      
      if (macros.isNotEmpty) {
        try {
          // Extract grams from strings like "30% (170g)" or calculate from calories
          if (macros['protein'] != null) {
            final proteinMatch = RegExp(r'(\d+)g').firstMatch(macros['protein'].toString());
            if (proteinMatch != null) {
              proteinGrams = int.tryParse(proteinMatch.group(1) ?? '0') ?? 0;
            } else {
              // Calculate from percentage
              final percentMatch = RegExp(r'(\d+)%').firstMatch(macros['protein'].toString());
              if (percentMatch != null) {
                final percent = int.tryParse(percentMatch.group(1) ?? '0') ?? 30;
                // 4 calories per gram of protein
                proteinGrams = ((dailyCalories * percent / 100) / 4).round();
              }
            }
          }
          
          if (macros['carbs'] != null) {
            final carbsMatch = RegExp(r'(\d+)g').firstMatch(macros['carbs'].toString());
            if (carbsMatch != null) {
              carbsGrams = int.tryParse(carbsMatch.group(1) ?? '0') ?? 0;
            } else {
              // Calculate from percentage
              final percentMatch = RegExp(r'(\d+)%').firstMatch(macros['carbs'].toString());
              if (percentMatch != null) {
                final percent = int.tryParse(percentMatch.group(1) ?? '0') ?? 50;
                // 4 calories per gram of carbs
                carbsGrams = ((dailyCalories * percent / 100) / 4).round();
              }
            }
          }
          
          if (macros['fat'] != null) {
            final fatMatch = RegExp(r'(\d+)g').firstMatch(macros['fat'].toString());
            if (fatMatch != null) {
              fatGrams = int.tryParse(fatMatch.group(1) ?? '0') ?? 0;
            } else {
              // Calculate from percentage
              final percentMatch = RegExp(r'(\d+)%').firstMatch(macros['fat'].toString());
              if (percentMatch != null) {
                final percent = int.tryParse(percentMatch.group(1) ?? '0') ?? 20;
                // 9 calories per gram of fat
                fatGrams = ((dailyCalories * percent / 100) / 9).round();
              }
            }
          }
        } catch (e) {
          debugPrint('Error extracting macro values: $e');
          // Default values if extraction fails
          proteinGrams = (dailyCalories * 0.3 / 4).round(); // 30% protein
          carbsGrams = (dailyCalories * 0.5 / 4).round();   // 50% carbs
          fatGrams = (dailyCalories * 0.2 / 9).round();     // 20% fat
        }
      }
      
      // Calculate meals per day from the plan
      int mealsPerDay = 3; // Default
      List<Map<String, dynamic>> days = [];

      if (plan['days'] != null && plan['days'] is List && plan['days'].isNotEmpty) {
        // Convert days to proper type
        days = (plan['days'] as List).map((dayData) {
          return Map<String, dynamic>.from(dayData as Map);
        }).toList();

        if (days.isNotEmpty && days[0]['mealTimingRecommendation'] != null) {
          final mealMatch = RegExp(r'(\d+)-(\d+)').firstMatch(days[0]['mealTimingRecommendation'].toString());
          if (mealMatch != null) {
            mealsPerDay = int.tryParse(mealMatch.group(2) ?? '3') ?? 3; // Use upper range
          }
        }
      }
      
      // Insert the main nutrition plan record
      await supabase.from('nutrition_plans').insert({
        'id': planId,
        'user_id': userId,
        'total_daily_calories': dailyCalories,
        'protein_daily_grams': proteinGrams,
        'carbs_daily_grams': carbsGrams,
        'fat_daily_grams': fatGrams,
        'meals_per_day': mealsPerDay,
        'plan_notes': 'Nutrition Plan: Daily calories: $dailyCalories, Protein: ${proteinGrams}g, Carbs: ${carbsGrams}g, Fat: ${fatGrams}g',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'start_date': now.toIso8601String().split('T')[0],
        'end_date': now.add(const Duration(days: 28)).toIso8601String().split('T')[0],
      });
      
      // Insert plan days
      for (var i = 0; i < days.length; i++) {
        final day = days[i];
        final isWorkoutDay = day['isWorkoutDay'] ?? false;
        final dayOfWeek = day['dayOfWeek'] ?? (i + 1);
        
        // Create a day record
        final dayId = const Uuid().v4();
        await supabase.from('nutrition_plan_days').insert({
          'id': dayId,
          'plan_id': planId,
          'day_of_week': dayOfWeek,
          'total_calories': day['total_calories'] ?? dailyCalories,
          'total_protein': day['total_protein'] ?? proteinGrams,
          'total_carbs': day['total_carbs'] ?? carbsGrams,
          'total_fat': day['total_fat'] ?? fatGrams,
          'notes': formatNutritionDayNotes(day),
        });
      }
      
      return planId;
    } catch (e) {
      debugPrint('Error storing nutrition plan: $e');
      throw Exception('Failed to store nutrition plan in database: $e');
    }
  }
  
  // Format nutrition day notes to include all relevant information
  static String formatNutritionDayNotes(Map<String, dynamic> day) {
    final buffer = StringBuffer();
    
    // Add meal timing recommendation if available
    if (day['mealTimingRecommendation'] != null) {
      buffer.writeln('Meal Timing: ${day["mealTimingRecommendation"]}');
    }
    
    // Add water intake recommendation if available
    if (day['waterIntake'] != null) {
      buffer.writeln('Water Intake: ${day["waterIntake"]}');
    }
    
    // Add workout day specific recommendations
    if (day['isWorkoutDay'] == true) {
      if (day['preworkoutNutrition'] != null) {
        buffer.writeln('\nPre-workout Nutrition: ${day["preworkoutNutrition"]}');
      }
      
      if (day['postworkoutNutrition'] != null) {
        buffer.writeln('Post-workout Nutrition: ${day["postworkoutNutrition"]}');
      }
    }
    
    // Add micronutrients if available
    if (day['micronutrients'] != null && day['micronutrients'] is Map) {
      final micronutrients = Map<String, dynamic>.from(day['micronutrients'] as Map);
      buffer.writeln('\nMicronutrient Targets:');
      micronutrients.forEach((key, value) {
        final capitalizedKey = _capitalize(key.replaceAll('_', ' '));
        buffer.writeln('• $capitalizedKey: $value');
      });
    }
    
    // Add any day-specific notes
    if (day['notes'] != null && day['notes'].toString().isNotEmpty) {
      buffer.writeln('\nDaily Notes: ${day["notes"]}');
    }
    
    return buffer.toString();
  }
  
  // Helper method to capitalize strings
  static String _capitalize(String s) => s.isNotEmpty ? '${s[0].toUpperCase()}${s.substring(1)}' : '';

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
            .order('meal_order', ascending: true);
        
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
  static String _formatWorkoutPlanSummary(Map<String, dynamic> workoutPlan) {
    if (workoutPlan.isEmpty) return 'No workout plan available';
    
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
            final focus = day['workout_type'] ?? day['focus_area'] ?? 'Rest';
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
  static String _formatNutritionPlanSummary(Map<String, dynamic> nutritionPlan) {
    if (nutritionPlan.isEmpty) return 'No nutrition plan available';
    
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
            final isWorkoutDay = day['is_workout_day'] == true;
            final meals = day['meals'] is List ? 
                (day['meals'] as List).length : 0;
            
            summary += '- $dayName: ${isWorkoutDay ? 'Workout day' : 'Rest day'} ($meals meals)\n';
          }
        }
      }
    }
    
    return summary;
  }
  
  // Helper to get day name from day of week number
  static String _getDayName(int dayOfWeek) {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    if (dayOfWeek >= 1 && dayOfWeek <= 7) {
      return days[dayOfWeek - 1];
    }
    return 'Unknown';
  }

  // Process and apply workout updates
  static Future<Map<String, dynamic>> _processWorkoutUpdates(
    String userId, 
    Map<String, dynamic> workoutUpdates,
    Map<String, dynamic> currentWorkoutPlan
  ) async {
    try {
      if (currentWorkoutPlan.isEmpty || !currentWorkoutPlan.containsKey('plan')) {
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
                  await supabase
                      .from('workout_exercises')
                      .update({
                        'instructions': newInstructions
                      })
                      .eq('id', exercise['id']);
                  
                  updatedExercises++;
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
              // Get highest exercise order
              int maxOrder = 0;
              final existingExercises = await supabase
                  .from('workout_exercises')
                  .select('exercise_order')
                  .eq('day_id', dayId);
              
              for (var ex in existingExercises) {
                if (ex['exercise_order'] > maxOrder) {
                  maxOrder = ex['exercise_order'];
                }
              }
              
              // Add the new exercise
              await supabase
                  .from('workout_exercises')
                  .insert({
                    'id': const Uuid().v4(),
                    'day_id': dayId,
                    'exercise_name': exerciseName,
                    'sets': change['details']?['sets'] ?? 3,
                    'reps': change['details']?['reps'] ?? '8-12',
                    'rest_seconds': change['details']?['restSeconds'] ?? 60,
                    'instructions': change['details']?['instructions'] ?? 'Perform with proper form',
                    'exercise_order': maxOrder + 1,
                    'muscle_group': 'Added via chat', // Default value
                  });
              
              changesMade++;
            } else if (changeType == 'modify_exercise') {
              // Find the exercise
              final existingExercises = await supabase
                  .from('workout_exercises')
          .select('*')
                  .eq('day_id', dayId)
                  .ilike('exercise_name', '%$exerciseName%');
              
              if (existingExercises.isEmpty) {
                continue; // Skip this change
              }
              
              // Update the exercise
              final exerciseId = existingExercises[0]['id'];
              Map<String, dynamic> updateData = {};
              
              if (change['details']?['sets'] != null) updateData['sets'] = change['details']['sets'];
              if (change['details']?['reps'] != null) updateData['reps'] = change['details']['reps'];
              if (change['details']?['restSeconds'] != null) updateData['rest_seconds'] = change['details']['restSeconds'];
              if (change['details']?['instructions'] != null) updateData['instructions'] = change['details']['instructions'];
              
              if (updateData.isNotEmpty) {
                await supabase
                    .from('workout_exercises')
                    .update(updateData)
                    .eq('id', exerciseId);
                
                changesMade++;
              }
            } else if (changeType == 'remove_exercise') {
              // Find the exercise
              final existingExercises = await supabase
            .from('workout_exercises')
            .select('*')
                  .eq('day_id', dayId)
                  .ilike('exercise_name', '%$exerciseName%');
              
              if (existingExercises.isEmpty) {
                continue; // Skip this change
              }
              
              // Delete the exercise
              final exerciseId = existingExercises[0]['id'];
              await supabase
                  .from('workout_exercises')
                  .delete()
                  .eq('id', exerciseId);
              
              changesMade++;
            }
          }
          
          if (changesMade > 0) {
            return {
              "success": true,
              "message": "👍 Updated your workout plan for ${_getDayName(dayOfWeek)}! Made $changesMade changes to your exercises."
            };
          } else {
            return {
              "success": false,
              "message": "I understood your workout update request, but couldn't apply any changes. Please try again with more specific exercise details."
            };
          }
        }
      }
      
      return {
        "success": false,
        "message": "I understood you wanted to update your workout plan, but I couldn't determine the specific changes to make."
      };
      
    } catch (e) {
      debugPrint('Error processing workout updates: $e');
      return {
        "success": false,
        "message": "I encountered an error while trying to update your workout plan. Please try again with more specific instructions."
      };
    }
  }
  
  // Process and apply nutrition updates
  static Future<Map<String, dynamic>> _processNutritionUpdates(
    String userId, 
    Map<String, dynamic> nutritionUpdates,
    Map<String, dynamic> currentNutritionPlan
  ) async {
    try {
      if (currentNutritionPlan.isEmpty || !currentNutritionPlan.containsKey('plan')) {
        return {
          "success": false,
          "message": "Sorry, I couldn't find an existing nutrition plan to update. Please generate a plan first."
        };
      }
      
      final planId = currentNutritionPlan['plan']['id'];
      
      // Handle full plan update - not implemented yet as it requires complex logic
      if (nutritionUpdates['fullPlanUpdate'] == true) {
        return {
          "success": false,
          "message": "Full nutrition plan updates aren't supported yet. Please specify changes to a particular day or meal."
        };
      }
      
      // Handle specific day updates
      if (nutritionUpdates.containsKey('specificDay') && nutritionUpdates['specificDay'] != null) {
        final dayUpdate = nutritionUpdates['specificDay'];
        final dayOfWeek = dayUpdate['dayOfWeek'];
        
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
        
        int changesMade = 0;
        
        // Update macros if provided
        if (dayUpdate.containsKey('macroChanges') && dayUpdate['macroChanges'] != null) {
          final macroChanges = dayUpdate['macroChanges'];
          Map<String, dynamic> updateData = {};
          
          if (macroChanges['totalCalories'] != null) updateData['total_calories'] = macroChanges['totalCalories'];
          if (macroChanges['protein'] != null) updateData['total_protein'] = macroChanges['protein'];
          if (macroChanges['carbs'] != null) updateData['total_carbs'] = macroChanges['carbs'];
          if (macroChanges['fat'] != null) updateData['total_fat'] = macroChanges['fat'];
          
          if (updateData.isNotEmpty) {
            await supabase
                .from('nutrition_plan_days')
                .update(updateData)
                .eq('id', dayId);
            
            changesMade++;
          }
        }
        
        // Process meal changes
        if (dayUpdate.containsKey('mealChanges') && dayUpdate['mealChanges'] is List) {
          final mealChanges = dayUpdate['mealChanges'] as List;
          
          for (var change in mealChanges) {
            final changeType = change['type'];
            final mealName = change['mealName'];
            
            if (changeType == 'add_meal') {
              // Get highest meal order
              int maxOrder = 0;
              final existingMeals = await supabase
                  .from('nutrition_plan_meals')
                  .select('meal_order')
                  .eq('day_id', dayId);
              
              for (var meal in existingMeals) {
                if (meal['meal_order'] > maxOrder) {
                  maxOrder = meal['meal_order'];
                }
              }
              
              // Format foods
              String foodsText = 'No specific foods';
              if (change['details']?['foods'] is List && (change['details']['foods'] as List).isNotEmpty) {
                foodsText = (change['details']['foods'] as List)
                    .map((food) => '${food['name']} (${food['amount']})')
                    .join(', ');
              }
              
              // Add the new meal
              await supabase
                  .from('nutrition_plan_meals')
                  .insert({
                    'id': const Uuid().v4(),
                    'day_id': dayId,
                    'meal_name': mealName,
                    'foods': foodsText,
                    'meal_order': maxOrder + 1,
                  });
              
              changesMade++;
            } else if (changeType == 'modify_meal') {
              // Find the meal
              final existingMeals = await supabase
                  .from('nutrition_plan_meals')
                  .select('*')
                  .eq('day_id', dayId)
                  .ilike('meal_name', '%$mealName%');
              
              if (existingMeals.isEmpty) {
                continue; // Skip this change
              }
              
              // Format foods if provided
              String? foodsText;
              if (change['details']?['foods'] is List && (change['details']['foods'] as List).isNotEmpty) {
                foodsText = (change['details']['foods'] as List)
                    .map((food) => '${food['name']} (${food['amount']})')
                    .join(', ');
              }
              
              // Update the meal
              if (foodsText != null) {
                await supabase
                    .from('nutrition_plan_meals')
                    .update({'foods': foodsText})
                    .eq('id', existingMeals[0]['id']);
                
                changesMade++;
              }
            } else if (changeType == 'remove_meal') {
              // Find the meal
              final existingMeals = await supabase
                  .from('nutrition_plan_meals')
                  .select('*')
                  .eq('day_id', dayId)
                  .ilike('meal_name', '%$mealName%');
              
              if (existingMeals.isEmpty) {
                continue; // Skip this change
              }
              
              // Delete the meal
              await supabase
                  .from('nutrition_plan_meals')
                  .delete()
                  .eq('id', existingMeals[0]['id']);
              
              changesMade++;
            }
          }
        }
        
        if (changesMade > 0) {
      return {
            "success": true,
            "message": "👍 Updated your nutrition plan for ${_getDayName(dayOfWeek)}! Made $changesMade changes to your macros and meals."
          };
        } else {
          return {
            "success": false,
            "message": "I understood your nutrition update request, but couldn't apply any changes. Please try again with more specific details."
          };
        }
      }
      
      return {
        "success": false,
        "message": "I understood you wanted to update your nutrition plan, but I couldn't determine the specific changes to make."
      };
      
    } catch (e) {
      debugPrint('Error processing nutrition updates: $e');
      return {
        "success": false,
        "message": "I encountered an error while trying to update your nutrition plan. Please try again with more specific instructions."
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
      Map<String, dynamic> workoutPlan = {};
            
            try {
              final workoutPlanData = await getLatestWorkoutPlan(userId);
              if (workoutPlanData != null) {
                workoutPlan = Map<String, dynamic>.from(workoutPlanData);
              }
            } catch (e) {
              debugPrint('Error fetching workout plan: $e');
            }
            
            // Process the instruction update
            return await _processWorkoutUpdates(userId, instructionUpdate, workoutPlan);
        }
      } catch (e) {
          debugPrint('Error parsing instruction update JSON: $e');
        }
      }
      
      // Get current workout and nutrition plans to provide context
      Map<String, dynamic> workoutPlan = {};
      Map<String, dynamic> nutritionPlan = {};
      
      try {
        final workoutPlanData = await getLatestWorkoutPlan(userId);
        if (workoutPlanData != null) {
          workoutPlan = Map<String, dynamic>.from(workoutPlanData);
        }
      } catch (e) {
        debugPrint('Error fetching workout plan: $e');
      }
      
      try {
        final nutritionPlanData = await getLatestNutritionPlan(userId);
        if (nutritionPlanData != null) {
          nutritionPlan = Map<String, dynamic>.from(nutritionPlanData);
        }
      } catch (e) {
        debugPrint('Error fetching nutrition plan: $e');
      }
      
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
${workoutPlan.isNotEmpty ? 'Plan ID: ${workoutPlan['plan']?['id'] ?? 'N/A'}' : 'No workout plan available'}
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
${workoutPlan.isNotEmpty ? 'Plan ID: ${workoutPlan['plan']?['id'] ?? 'N/A'}' : 'No workout plan available'}
${_formatWorkoutPlanSummary(workoutPlan)}

Current nutrition plan summary:
${nutritionPlan.isNotEmpty ? 'Plan ID: ${nutritionPlan['plan']?['id'] ?? 'N/A'}' : 'No nutrition plan available'}
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
        apiKey: _apiKey,
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

  // Generate a chat response using Gemini
  static Future<String> generateChatResponse(String userId, String userMessage) async {
    try {
      // Get recent chat history for context
      List<Map<String, dynamic>> chatHistory = [];
      try {
        final data = await supabase
            .from('chat_messages')
            .select('message_text, is_user, created_at')
            .eq('user_id', userId)
            .order('created_at', ascending: false)
            .limit(10); // Get last 10 messages
        
        if (data != null) {
          chatHistory = List<Map<String, dynamic>>.from(data);
          // Reverse to get chronological order
          chatHistory = chatHistory.reversed.toList();
        }
      } catch (e) {
        debugPrint('Error fetching chat history: $e');
      }
      
      // Get user profile data
      Map<String, dynamic> userProfile = {};
      try {
        final data = await supabase
            .from('user_profiles')
            .select()
            .eq('user_id', userId)
            .single();
        
        if (data != null) {
          userProfile = Map<String, dynamic>.from(data);
        }
      } catch (e) {
        debugPrint('Error fetching user profile: $e');
      }

      // Get current workout and nutrition plans to provide context
      Map<String, dynamic> workoutPlan = {};
      Map<String, dynamic> nutritionPlan = {};
      
      try {
        final workoutPlanData = await getLatestWorkoutPlan(userId);
        if (workoutPlanData != null) {
          workoutPlan = Map<String, dynamic>.from(workoutPlanData);
        }
      } catch (e) {
        debugPrint('Error fetching workout plan: $e');
      }
      
      try {
        final nutritionPlanData = await getLatestNutritionPlan(userId);
        if (nutritionPlanData != null) {
          nutritionPlan = Map<String, dynamic>.from(nutritionPlanData);
        }
      } catch (e) {
        debugPrint('Error fetching nutrition plan: $e');
      }

      // Format chat history for Gemini
      List<Content> messages = [];
      
      // First, add a system message to set the context
      messages.add(Content.text('''You are FitCoach, an AI fitness coach for the FitAAI app. You have access to the user's profile information, workout plan, and nutrition plan. 
Always give helpful, concise, and accurate fitness advice. Use appropriate emoji occasionally for friendliness.

User Profile Summary:
${userProfile.isNotEmpty ? 'Name: ${userProfile['full_name'] ?? 'Unknown'}, Age: ${userProfile['age'] ?? 'Unknown'}, Gender: ${userProfile['gender'] ?? 'Unknown'}, Height: ${userProfile['height_cm'] ?? 'Unknown'} cm, Weight: ${userProfile['weight_kg'] ?? 'Unknown'} kg' : 'No profile data available'}

Workout Plan Summary:
${workoutPlan.isNotEmpty ? 'Plan ID: ${workoutPlan['plan']?['id'] ?? 'N/A'}' : 'No workout plan available'}
${_formatWorkoutPlanSummary(workoutPlan)}

Nutrition Plan Summary:
${nutritionPlan.isNotEmpty ? 'Plan ID: ${nutritionPlan['plan']?['id'] ?? 'N/A'}' : 'No nutrition plan available'}
${_formatNutritionPlanSummary(nutritionPlan)}'''));
      
      // Then add chat history messages
      for (var message in chatHistory) {
        messages.add(Content.text(message['message_text']));
      }
      
      // Finally, add the current user message
      messages.add(Content.text(userMessage));
      
      // Configure Gemini model
      final model = GenerativeModel(
        model: 'gemini-1.5-pro',
        apiKey: _apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          maxOutputTokens: 2048,
        ),
      );
      
      // Generate response with Gemini
      final response = await model.generateContent(messages);
      return response.text ?? "I'm sorry, I couldn't generate a response. Please try again.";
      
    } catch (e) {
      debugPrint('Error in generateChatResponse: $e');
      return "I'm sorry, I encountered an error. Please try again later.";
    }
  }
} 