import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
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
      
      debugPrint('Raw JSON response: ${jsonText.substring(0, min(100, jsonText.length))}...');
      
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
      
      debugPrint('Raw nutrition JSON: ${jsonText.substring(0, min(100, jsonText.length))}...');
      
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

  // Fetch the latest nutrition plan for a user
  static Future<Map<String, dynamic>> getLatestNutritionPlan(String userId) async {
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
        // If no plan found, generate a new one
        final result = await generatePlans(userId);
        if (result['success'] && result['nutrition_plan_id'] != null) {
          return await getLatestNutritionPlan(userId);
        }
        throw Exception('No nutrition plan available and failed to generate one');
      }

      // Get the nutrition plan days
      final nutritionDays = await supabase
          .from('nutrition_plan_days')
          .select('*')
          .eq('plan_id', nutritionPlan['id'])
          .order('day_of_week');

      // Return the complete nutrition plan
      return {
        'plan': nutritionPlan,
        'days': nutritionDays,
      };
    } catch (e) {
      debugPrint('Error retrieving nutrition plan: $e');
      throw Exception('Failed to retrieve nutrition plan: $e');
    }
  }

  // Fetch the latest workout plan for a user
  static Future<Map<String, dynamic>> getLatestWorkoutPlan(String userId) async {
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
        // If no plan found, generate a new one
        final result = await generatePlans(userId);
        if (result['success'] && result['workout_plan_id'] != null) {
          return await getLatestWorkoutPlan(userId);
        }
        throw Exception('No workout plan available and failed to generate one');
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
      debugPrint('Error getting workout plan: $e');
      rethrow;
    }
  }

  // Generate a chat response using Gemini AI with workout and nutrition context
  static Future<String> generateChatResponse(String userId, String userMessage) async {
    try {
      // Configure Gemini model
      final model = GenerativeModel(
        model: 'gemini-1.5-pro',
        apiKey: _apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          maxOutputTokens: 1024,
        ),
      );
      
      // Get user profile data
      Map<String, dynamic> userProfile = {};
      Map<String, dynamic> workoutPlan = {};
      Map<String, dynamic> nutritionPlan = {};
      
      try {
        final userProfileData = await supabase
            .from('user_profiles')
            .select('*')
            .eq('user_id', userId)
            .single();
        
        if (userProfileData != null) {
          userProfile = Map<String, dynamic>.from(userProfileData);
        }
      } catch (e) {
        debugPrint('Error fetching user profile: $e');
        userProfile = {};
      }
      
      try {
        final workoutPlanData = await getLatestWorkoutPlan(userId);
        if (workoutPlanData != null) {
          workoutPlan = Map<String, dynamic>.from(workoutPlanData);
        }
      } catch (e) {
        debugPrint('Error fetching workout plan: $e');
        workoutPlan = {};
      }
      
      try {
        final nutritionPlanData = await getLatestNutritionPlan(userId);
        if (nutritionPlanData != null) {
          nutritionPlan = Map<String, dynamic>.from(nutritionPlanData);
        }
      } catch (e) {
        debugPrint('Error fetching nutrition plan: $e');
        nutritionPlan = {};
      }
      
      // Get today's date information
      final now = DateTime.now();
      final currentDayOfWeek = now.weekday; // 1 = Monday, 7 = Sunday
      
      // Extract today's workout and nutrition data
      Map<String, dynamic> todayWorkout = {};
      Map<String, dynamic> todayNutrition = {};
      
      if (workoutPlan.containsKey('days') && workoutPlan['days'] is List && (workoutPlan['days'] as List).isNotEmpty) {
        var days = workoutPlan['days'] as List;
        var foundDay = days.where((day) => day is Map && day['day_of_week'] == currentDayOfWeek).toList();
        
        if (foundDay.isNotEmpty && foundDay.first is Map) {
          todayWorkout = Map<String, dynamic>.from(foundDay.first);
        }
      }
      
      if (nutritionPlan.containsKey('days') && nutritionPlan['days'] is List && (nutritionPlan['days'] as List).isNotEmpty) {
        var days = nutritionPlan['days'] as List;
        var foundDay = days.where((day) => day is Map && day['day_of_week'] == currentDayOfWeek).toList();
        
        if (foundDay.isNotEmpty && foundDay.first is Map) {
          todayNutrition = Map<String, dynamic>.from(foundDay.first);
        }
      }
      
      // Format workout plan for context
      String workoutPlanContext = '';
      if (workoutPlan.containsKey('plan') && workoutPlan.containsKey('days') && workoutPlan['plan'] is Map) {
        final plan = workoutPlan['plan'] as Map;
        workoutPlanContext = '''
Workout plan name: ${plan['plan_name'] ?? 'Custom Workout Plan'}
Plan description: ${plan['plan_description'] ?? 'A personalized workout plan'}
Plan type: ${plan['plan_type'] ?? 'General Fitness'}
Plan difficulty: ${plan['plan_difficulty'] ?? 'Intermediate'}
Days per week: ${plan['days_per_week'] ?? 7}

Workout schedule:
''';
        
        for (var dayData in workoutPlan['days']) {
          if (dayData is Map) {
            final day = Map<String, dynamic>.from(dayData);
            final dayOfWeek = _getDayName(day['day_of_week']);
            final focusArea = day['workout_type'] ?? day['focus_area'] ?? 'Rest day';
            final exercises = day['exercises'] is List ? day['exercises'] as List : [];
            
            workoutPlanContext += '- $dayOfWeek: $focusArea (${exercises.length} exercises)\n';
            
            if (day['day_of_week'] == currentDayOfWeek) {
              workoutPlanContext += '  TODAY\'S WORKOUT - Details:\n';
              
              for (var exerciseData in exercises) {
                if (exerciseData is Map) {
                  final exercise = Map<String, dynamic>.from(exerciseData);
                  final name = exercise['exercise_name'] ?? exercise['name'] ?? 'Exercise';
                  final sets = exercise['sets'] ?? '-';
                  final reps = exercise['reps'] ?? '-';
                  final restTime = exercise['rest_seconds'] != null 
                      ? '${exercise['rest_seconds']}s rest' 
                      : exercise['restTime'] ?? '60s rest';
                  
                  workoutPlanContext += '  * $name: $sets sets x $reps ($restTime)\n';
                }
              }
            }
          }
        }
      }
      
      // Format nutrition plan for context
      String nutritionPlanContext = '';
      if (nutritionPlan.containsKey('plan') && nutritionPlan.containsKey('days') && nutritionPlan['plan'] is Map) {
        final plan = nutritionPlan['plan'] as Map;
        nutritionPlanContext = '''
Nutrition plan details:
Daily calories: ${plan['total_daily_calories'] ?? 'Variable'}
Protein (daily): ${plan['protein_daily_grams'] ?? '-'}g
Carbs (daily): ${plan['carbs_daily_grams'] ?? '-'}g
Fat (daily): ${plan['fat_daily_grams'] ?? '-'}g

Today's nutrition targets:
''';
        
        if (todayNutrition.isNotEmpty) {
          final isWorkoutDay = todayNutrition['isWorkoutDay'] ?? false;
          final calories = todayNutrition['total_calories'] ?? plan['total_daily_calories'] ?? '-';
          final protein = todayNutrition['total_protein'] ?? plan['protein_daily_grams'] ?? '-';
          final carbs = todayNutrition['total_carbs'] ?? plan['carbs_daily_grams'] ?? '-';
          final fat = todayNutrition['total_fat'] ?? plan['fat_daily_grams'] ?? '-';
          
          nutritionPlanContext += '''
- Day type: ${isWorkoutDay ? 'Workout day' : 'Rest day'}
- Target calories: ${calories}
- Protein: ${protein}g
- Carbs: ${carbs}g
- Fat: ${fat}g
''';
          
          if (todayNutrition['waterIntake'] != null) {
            nutritionPlanContext += '- Water intake: ${todayNutrition['waterIntake']}\n';
          }
          
          if (isWorkoutDay) {
            if (todayNutrition['preworkoutNutrition'] != null) {
              nutritionPlanContext += '- Pre-workout: ${todayNutrition['preworkoutNutrition']}\n';
            }
            
            if (todayNutrition['postworkoutNutrition'] != null) {
              nutritionPlanContext += '- Post-workout: ${todayNutrition['postworkoutNutrition']}\n';
            }
          }
          
          if (todayNutrition['mealTimingRecommendation'] != null) {
            nutritionPlanContext += '- Meal timing: ${todayNutrition['mealTimingRecommendation']}\n';
          }
        }
      }
      
      // Prepare user information context
      String userContext = '';
      if (userProfile.isNotEmpty) {
        userContext = '''
User profile:
- Name: ${userProfile['full_name'] ?? 'Not provided'}
- Age: ${userProfile['age'] ?? 'Not specified'}
- Gender: ${userProfile['gender'] ?? 'Not specified'}
- Weight: ${userProfile['weight_kg'] ?? 'Not specified'} kg
- Height: ${userProfile['height_cm'] ?? 'Not specified'} cm
- Fitness level: ${userProfile['fitness_level'] ?? 'Intermediate'}
- Primary fitness goal: ${userProfile['primary_fitness_goal'] ?? 'General fitness'}
- Specific target areas: ${userProfile['specific_targets'] ?? 'Full body'}
- Motivation: ${userProfile['motivation'] ?? 'Not specified'}
- Workout days per week: ${userProfile['workout_days_per_week'] ?? 'Not specified'}
- Workout duration: ${userProfile['workout_minutes_per_session'] ?? 'Not specified'} minutes
- Equipment access: ${userProfile['equipment_access'] ?? 'Not specified'}
- Indoor/outdoor preference: ${userProfile['indoor_outdoor_preference'] ?? 'Not specified'}
- Previous program experience: ${userProfile['previous_program_experience'] ?? 'None'}
- Daily activity level: ${userProfile['daily_activity_level'] ?? 'Moderate'}
- Sleep hours: ${userProfile['sleep_hours'] ?? 'Not specified'} hours
- Stress level: ${userProfile['stress_level'] ?? 'Not specified'}
- Eating habits: ${userProfile['eating_habits'] ?? 'Not specified'}
- Dietary restrictions: ${_formatJsonField(userProfile['dietary_restrictions'])}
- Favorite foods: ${userProfile['favorite_foods'] ?? 'Not specified'}
- Avoided foods: ${userProfile['avoided_foods'] ?? 'Not specified'}
- Medical conditions: ${userProfile['medical_conditions'] ?? 'None'}
- Fitness concerns: ${userProfile['fitness_concerns'] ?? 'None'}
- Additional notes: ${userProfile['additional_notes'] ?? 'None'}
''';
      }
      
      // Create the prompt for Gemini
      final dateStr = '${now.day}/${now.month}/${now.year}';
      final dayName = _getDayName(currentDayOfWeek);
      
      final prompt = '''
You are a fitness and nutrition assistant for a mobile fitness app called FitAI. Today is $dateStr ($dayName).

${userContext}

${workoutPlanContext}

${nutritionPlanContext}

The user has asked: "$userMessage"

Please provide a helpful, conversational response that directly addresses their question. If they ask about today's workout or meal plan, prioritize providing specific information about what's scheduled for today. Be supportive and encouraging, offering actionable advice based on their fitness goals and nutrition plan.

Keep your response concise and focused on answering their specific question.
''';
      
      // Generate content with Gemini
      final response = await model.generateContent([Content.text(prompt)]);
      String responseText = response.text ?? '';
      
      if (responseText.isEmpty) {
        return "I'm sorry, I couldn't generate a response at the moment. Please try again later.";
      }
      
      return responseText;
    } catch (e) {
      debugPrint('Error generating chat response with Gemini: $e');
      return "I apologize, but I'm having trouble accessing your fitness data right now. Can you please try asking me again in a moment?";
    }
  }
  
  // Helper to format JSON fields for display
  static String _formatJsonField(dynamic jsonField) {
    if (jsonField == null) return 'None';
    
    try {
      if (jsonField is String) {
        final Map<String, dynamic> parsed = jsonDecode(jsonField);
        return parsed.entries
            .where((entry) => entry.value == true)
            .map((entry) => entry.key)
            .join(', ');
      } else if (jsonField is Map) {
        return jsonField.entries
            .where((entry) => entry.value == true)
            .map((entry) => entry.key)
            .join(', ');
      }
    } catch (e) {
      debugPrint('Error formatting JSON field: $e');
    }
    
    return jsonField.toString();
  }

  // Helper to get day name from day of week number
  static String _getDayName(int dayOfWeek) {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    if (dayOfWeek >= 1 && dayOfWeek <= 7) {
      return days[dayOfWeek - 1];
    }
    return 'Unknown';
  }
} 