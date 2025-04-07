import 'package:uuid/uuid.dart';
import 'dart:convert';

/// Represents a complete workout plan
class WorkoutPlan {
  final String id;
  final String planName;
  final String planDescription;
  final String planType;
  final String planDifficulty;
  final int daysPerWeek;
  final DateTime createdAt;
  final List<WorkoutDay> days;
  
  WorkoutPlan({
    required this.id,
    required this.planName,
    required this.planDescription,
    required this.planType,
    required this.planDifficulty,
    required this.daysPerWeek,
    required this.createdAt,
    required this.days,
  });
  
  /// Create a WorkoutPlan from JSON data
  factory WorkoutPlan.fromJson(Map<String, dynamic> json) {
    final planData = json['plan'] as Map<String, dynamic>;
    final daysData = json['days'] as List<dynamic>;
    
    return WorkoutPlan(
      id: planData['id'],
      planName: planData['plan_name'] ?? 'Workout Plan',
      planDescription: planData['plan_description'] ?? '',
      planType: planData['plan_type'] ?? 'Standard',
      planDifficulty: planData['plan_difficulty'] ?? 'Intermediate',
      daysPerWeek: planData['days_per_week'] ?? daysData.length,
      createdAt: DateTime.parse(planData['created_at']),
      days: daysData.map((day) => WorkoutDay.fromJson(day)).toList(),
    );
  }
  
  /// Convert plan to database JSON format
  Map<String, dynamic> toDbJson() {
    return {
      'plan': {
        'id': id,
        'plan_name': planName,
        'plan_description': planDescription,
        'plan_type': planType,
        'plan_difficulty': planDifficulty,
        'days_per_week': daysPerWeek,
        'created_at': createdAt.toIso8601String(),
      },
      'days': days.map((day) => day.toJson()).toList(),
    };
  }
}

/// Represents a single day in a workout plan
class WorkoutDay {
  final String id;
  final String dayId;
  final int dayOfWeek;
  final String workoutType;
  final int? sessionDurationMinutes;
  final int? estimatedCalories;
  final String? equipmentNeeded;
  final String? notes;
  final List<Exercise> exercises;
  
  WorkoutDay({
    required this.id,
    required this.dayId,
    required this.dayOfWeek,
    required this.workoutType,
    this.sessionDurationMinutes,
    this.estimatedCalories,
    this.equipmentNeeded,
    this.notes,
    required this.exercises,
  });
  
  /// Create a WorkoutDay from JSON data
  factory WorkoutDay.fromJson(Map<String, dynamic> json) {
    return WorkoutDay(
      id: json['id'],
      dayId: json['plan_id'],
      dayOfWeek: json['day_of_week'],
      workoutType: json['workout_type'] ?? 'General',
      sessionDurationMinutes: json['session_duration_minutes'],
      estimatedCalories: json['estimated_calories'],
      equipmentNeeded: json['equipment_needed'],
      notes: json['notes'],
      exercises: (json['exercises'] as List<dynamic>)
          .map((e) => Exercise.fromJson(e))
          .toList(),
    );
  }
  
  /// Convert day to JSON format
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plan_id': dayId,
      'day_of_week': dayOfWeek,
      'workout_type': workoutType,
      'session_duration_minutes': sessionDurationMinutes,
      'estimated_calories': estimatedCalories,
      'equipment_needed': equipmentNeeded,
      'notes': notes,
      'exercises': exercises.map((e) => e.toJson()).toList(),
    };
  }
}

/// Represents an exercise in a workout day
class Exercise {
  final String id;
  final String dayId;
  final String name;
  final int sets;
  final String reps;
  final String? weight;
  final int? restSeconds;
  final String? instructions;
  final String? equipment;
  final String? muscleGroup;
  final int exerciseOrder;
  
  Exercise({
    required this.id,
    required this.dayId,
    required this.name,
    required this.sets,
    required this.reps,
    this.weight,
    this.restSeconds,
    this.instructions,
    this.equipment,
    this.muscleGroup,
    required this.exerciseOrder,
  });
  
  /// Create an Exercise from JSON data
  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'],
      dayId: json['day_id'],
      name: json['exercise_name'],
      sets: json['sets'] ?? 3,
      reps: json['reps'] ?? '10-12',
      weight: json['weight'],
      restSeconds: json['rest_seconds'],
      instructions: json['instructions'],
      equipment: json['equipment'],
      muscleGroup: json['muscle_group'],
      exerciseOrder: json['exercise_order'] ?? 0,
    );
  }
  
  /// Convert exercise to JSON format
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'day_id': dayId,
      'exercise_name': name,
      'sets': sets,
      'reps': reps,
      'weight': weight,
      'rest_seconds': restSeconds,
      'instructions': instructions,
      'equipment': equipment,
      'muscle_group': muscleGroup,
      'exercise_order': exerciseOrder,
    };
  }
}

/// Represents a complete nutrition plan
class NutritionPlan {
  final String id;
  final int totalDailyCalories;
  final int proteinDailyGrams;
  final int carbsDailyGrams;
  final int fatDailyGrams;
  final int mealsPerDay;
  final DateTime createdAt;
  final List<NutritionDay> days;
  
  NutritionPlan({
    required this.id,
    required this.totalDailyCalories,
    required this.proteinDailyGrams,
    required this.carbsDailyGrams,
    required this.fatDailyGrams,
    required this.mealsPerDay,
    required this.createdAt,
    required this.days,
  });
  
  /// Create a NutritionPlan from JSON data
  factory NutritionPlan.fromJson(Map<String, dynamic> json) {
    final planData = json['plan'] as Map<String, dynamic>;
    final daysData = json['days'] as List<dynamic>;
    
    return NutritionPlan(
      id: planData['id'],
      totalDailyCalories: planData['total_daily_calories'] ?? 2000,
      proteinDailyGrams: planData['protein_daily_grams'] ?? 150,
      carbsDailyGrams: planData['carbs_daily_grams'] ?? 200,
      fatDailyGrams: planData['fat_daily_grams'] ?? 70,
      mealsPerDay: planData['meals_per_day'] ?? 3,
      createdAt: DateTime.parse(planData['created_at']),
      days: daysData.map((day) => NutritionDay.fromJson(day)).toList(),
    );
  }
  
  /// Convert plan to database JSON format
  Map<String, dynamic> toDbJson() {
    return {
      'plan': {
        'id': id,
        'total_daily_calories': totalDailyCalories,
        'protein_daily_grams': proteinDailyGrams,
        'carbs_daily_grams': carbsDailyGrams,
        'fat_daily_grams': fatDailyGrams,
        'meals_per_day': mealsPerDay,
        'created_at': createdAt.toIso8601String(),
      },
      'days': days.map((day) => day.toJson()).toList(),
    };
  }
}

/// Represents a single day in a nutrition plan
class NutritionDay {
  final String id;
  final String planId;
  final int dayOfWeek;
  final int? totalCalories;
  final int? totalProtein;
  final int? totalCarbs;
  final int? totalFat;
  final String? notes;
  final List<Meal> meals;
  
  NutritionDay({
    required this.id,
    required this.planId,
    required this.dayOfWeek,
    this.totalCalories,
    this.totalProtein,
    this.totalCarbs,
    this.totalFat,
    this.notes,
    required this.meals,
  });
  
  /// Create a NutritionDay from JSON data
  factory NutritionDay.fromJson(Map<String, dynamic> json) {
    return NutritionDay(
      id: json['id'],
      planId: json['plan_id'],
      dayOfWeek: json['day_of_week'],
      totalCalories: json['total_calories'],
      totalProtein: json['total_protein'],
      totalCarbs: json['total_carbs'],
      totalFat: json['total_fat'],
      notes: json['notes'],
      meals: (json['meals'] as List<dynamic>)
          .map((m) => Meal.fromJson(m))
          .toList(),
    );
  }
  
  /// Convert day to JSON format
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plan_id': planId,
      'day_of_week': dayOfWeek,
      'total_calories': totalCalories,
      'total_protein': totalProtein,
      'total_carbs': totalCarbs,
      'total_fat': totalFat,
      'notes': notes,
      'meals': meals.map((m) => m.toJson()).toList(),
    };
  }
}

/// Represents a meal in a nutrition day
class Meal {
  final String id;
  final String dayId;
  final String mealName;
  final String mealTime;
  final int? totalCalories;
  final int? proteinGrams;
  final int? carbsGrams;
  final int? fatGrams;
  final String? description;
  final List<dynamic> foods;
  
  Meal({
    required this.id,
    required this.dayId,
    required this.mealName,
    required this.mealTime,
    this.totalCalories,
    this.proteinGrams,
    this.carbsGrams,
    this.fatGrams,
    this.description,
    required this.foods,
  });
  
  /// Create a Meal from JSON data
  factory Meal.fromJson(Map<String, dynamic> json) {
    List<dynamic> foodsList = [];
    if (json['foods'] != null) {
      try {
        if (json['foods'] is String) {
          foodsList = List<dynamic>.from(jsonDecode(json['foods']));
        } else if (json['foods'] is List) {
          foodsList = json['foods'];
        }
      } catch (e) {
        print('Error parsing foods JSON: $e');
      }
    }
    
    return Meal(
      id: json['id'],
      dayId: json['day_id'],
      mealName: json['meal_name'],
      mealTime: json['meal_time'].toString(),
      totalCalories: json['total_calories'],
      proteinGrams: json['protein_grams'],
      carbsGrams: json['carbs_grams'],
      fatGrams: json['fat_grams'],
      description: json['description'],
      foods: foodsList,
    );
  }
  
  /// Convert meal to JSON format
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'day_id': dayId,
      'meal_name': mealName,
      'meal_time': mealTime,
      'total_calories': totalCalories,
      'protein_grams': proteinGrams,
      'carbs_grams': carbsGrams,
      'fat_grams': fatGrams,
      'description': description,
      'foods': foods,
    };
  }
} 