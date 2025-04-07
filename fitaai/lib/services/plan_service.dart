import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../models/plan_models.dart';
import 'gemini_service.dart';
import 'mcp_service.dart';
import 'cache_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart'; // Import for supabase

/// Type of plan to generate
enum PlanType {
  workout,
  nutrition,
  both,
}

/// Service for unified plan generation
class PlanService {
  // Cache for plan data
  static Map<String, dynamic>? _cachedWorkoutPlan;
  static Map<String, dynamic>? _cachedNutritionPlan;

  /// Generate plans based on user profile
  static Future<bool> generatePlans(String userId, PlanType planType) async {
    try {
      // Get the user profile
      final userProfile = await getUserProfile(userId);
      if (userProfile == null) {
        debugPrint('No user profile found for user: $userId');
        return false;
      }

      if (planType == PlanType.both) {
        // Generate both workout and nutrition plans, ensuring they are linked
        return await _generateCombinedPlans(userId, userProfile);
      } else if (planType == PlanType.workout) {
        // Generate only workout plan
        final workoutPlan = await GeminiService.generateWorkoutPlan(userProfile);
        final workoutPlanId = await GeminiService.storeWorkoutPlan(userId, workoutPlan);
        debugPrint('Generated workout plan: $workoutPlanId');
        return workoutPlanId != null;
      } else if (planType == PlanType.nutrition) {
        // Generate only nutrition plan
        // First try to get the existing workout plan to inform nutrition recommendations
        Map<String, dynamic>? existingWorkoutPlan;
        try {
          final workoutPlanObj = await getWorkoutPlan(userId);
          existingWorkoutPlan = workoutPlanObj?.toDbJson();
          debugPrint('Found existing workout plan for nutrition planning');
        } catch (e) {
          debugPrint('No existing workout plan found, generating nutrition independently: $e');
        }
        
        final nutritionPlan = await GeminiService.generateNutritionPlan(userProfile, workoutPlan: existingWorkoutPlan);
        final nutritionPlanId = await GeminiService.storeNutritionPlan(userId, nutritionPlan);
        debugPrint('Generated nutrition plan: $nutritionPlanId');
        return nutritionPlanId != null;
      }

      return false;
    } catch (e) {
      debugPrint('Error generating plans: $e');
      return false;
    }
  }

  /// Generates both workout and nutrition plans together, ensuring they're optimized for each other
  static Future<bool> _generateCombinedPlans(String userId, Map<String, dynamic> userProfile) async {
    try {
      // Generate workout plan first
      final workoutPlan = await GeminiService.generateWorkoutPlan(userProfile);
      final workoutPlanId = await GeminiService.storeWorkoutPlan(userId, workoutPlan);
      
      if (workoutPlanId == null) {
        debugPrint('Failed to generate workout plan');
        return false;
      }
      
      debugPrint('Successfully generated workout plan: $workoutPlanId');
      
      // Now generate nutrition plan based on the workout plan - workoutPlan is already a Map<String, dynamic>
      final nutritionPlan = await GeminiService.generateNutritionPlan(userProfile, workoutPlan: workoutPlan);
      final nutritionPlanId = await GeminiService.storeNutritionPlan(userId, nutritionPlan);
      
      if (nutritionPlanId == null) {
        debugPrint('Failed to generate nutrition plan');
        return false;
      }
      
      debugPrint('Successfully generated nutrition plan: $nutritionPlanId');
      
      // Clear cached plans
      _cachedWorkoutPlan = null;
      _cachedNutritionPlan = null;
      
      return true;
    } catch (e) {
      debugPrint('Error generating combined plans: $e');
      return false;
    }
  }

  /// Gets the latest workout plan for a user
  static Future<WorkoutPlan?> getWorkoutPlan(String userId) async {
    try {
      // Check cache first
      final cachedPlan = CacheService.getWorkoutPlan(userId);
      if (cachedPlan != null) {
        return WorkoutPlan.fromJson(cachedPlan);
      }
      
      // Get from database
      final planData = await McpService.getLatestWorkoutPlan(userId);
      if (planData == null) return null;
      
      // Create model
      final plan = WorkoutPlan.fromJson(planData);
      
      // Cache for future use
      await CacheService.cacheWorkoutPlan(userId, planData);
      
      return plan;
    } catch (e) {
      debugPrint('Error getting workout plan: $e');
      return null;
    }
  }

  /// Gets the latest nutrition plan for a user
  static Future<NutritionPlan?> getNutritionPlan(String userId) async {
    try {
      // Check cache first
      final cachedPlan = CacheService.getNutritionPlan(userId);
      if (cachedPlan != null) {
        return NutritionPlan.fromJson(cachedPlan);
      }
      
      // Get from database
      final planData = await McpService.getLatestNutritionPlan(userId);
      if (planData == null) return null;
      
      // Create model
      final plan = NutritionPlan.fromJson(planData);
      
      // Cache for future use
      await CacheService.cacheNutritionPlan(userId, planData);
      
      return plan;
    } catch (e) {
      debugPrint('Error getting nutrition plan: $e');
      return null;
    }
  }
  
  /// Format workout plan to text summary
  static String formatWorkoutPlanSummary(WorkoutPlan plan) {
    String summary = 'Workout Plan: ${plan.planName}\n\n';
    
    summary += 'Plan Type: ${plan.planType}\n';
    summary += 'Difficulty: ${plan.planDifficulty}\n';
    summary += 'Days Per Week: ${plan.daysPerWeek}\n\n';
    
    summary += 'Schedule:\n';
    
    for (var day in plan.days) {
      final dayName = _getDayName(day.dayOfWeek);
      summary += '• $dayName: ${day.workoutType} | ${day.exercises.length} exercises\n';
    }
    
    return summary;
  }
  
  /// Format nutrition plan to text summary
  static String formatNutritionPlanSummary(NutritionPlan plan) {
    String summary = 'Nutrition Plan\n\n';
    
    summary += 'Daily Targets:\n';
    summary += '• Calories: ${plan.totalDailyCalories}\n';
    summary += '• Protein: ${plan.proteinDailyGrams}g\n';
    summary += '• Carbs: ${plan.carbsDailyGrams}g\n';
    summary += '• Fat: ${plan.fatDailyGrams}g\n\n';
    
    summary += 'Meal Schedule:\n';
    
    for (var day in plan.days) {
      final dayName = _getDayName(day.dayOfWeek);
      summary += '• $dayName: (${day.meals.length} meals)\n';
      
      for (var meal in day.meals) {
        summary += '  - ${meal.mealName} (${meal.totalCalories} cal) at ${meal.mealTime}\n';
      }
    }
    
    return summary;
  }
  
  /// Helper to get day name from day of week number
  static String _getDayName(int dayOfWeek) {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    if (dayOfWeek >= 1 && dayOfWeek <= 7) {
      return days[dayOfWeek - 1];
    }
    return 'Unknown';
  }

  /// Gets the user profile from the database
  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final userProfileData = await supabase
          .from('user_profiles')
          .select()
          .eq('user_id', userId)
          .single();
      
      return userProfileData;
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      return null;
    }
  }
} 