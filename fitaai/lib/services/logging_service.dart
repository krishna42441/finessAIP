import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

class LoggingService {
  static final SupabaseClient _supabase = supabase;
  
  // Log weight entry
  static Future<String> logWeight({
    required String userId,
    required double weight,
    DateTime? date,
    String? notes,
  }) async {
    try {
      final uuid = const Uuid();
      final entryId = uuid.v4();
      final now = date ?? DateTime.now();
      
      await _supabase.from('weight_logs').insert({
        'id': entryId,
        'user_id': userId,
        'weight': weight,
        'date': now.toIso8601String(),
        'notes': notes,
      });
      
      return entryId;
    } catch (e) {
      debugPrint('Error logging weight: $e');
      rethrow;
    }
  }
  
  // Get weight logs
  static Future<List<WeightLogEntry>> getWeightLogs({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 10,
  }) async {
    try {
      var query = _supabase
          .from('weight_logs')
          .select()
          .eq('user_id', userId)
          .order('date', ascending: false)
          .limit(limit);
      
      final response = await query;
      
      // Convert to WeightLogEntry objects
      return (response as List).map((entry) => WeightLogEntry.fromJson(entry)).toList();
    } catch (e) {
      debugPrint('Error getting weight logs: $e');
      return [];
    }
  }
  
  // Log water intake
  static Future<String> logWater({
    required String userId,
    required int amountMl,
    DateTime? timestamp,
  }) async {
    try {
      final uuid = const Uuid();
      final entryId = uuid.v4();
      final now = timestamp ?? DateTime.now();
      
      await _supabase.from('water_logs').insert({
        'id': entryId,
        'user_id': userId,
        'amount_ml': amountMl,
        'timestamp': now.toIso8601String(),
      });
      
      return entryId;
    } catch (e) {
      debugPrint('Error logging water: $e');
      rethrow;
    }
  }
  
  // Get water logs
  static Future<List<WaterLogEntry>> getWaterLogs({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    try {
      var query = _supabase
          .from('water_logs')
          .select()
          .eq('user_id', userId)
          .order('timestamp', ascending: false)
          .limit(limit);
      
      final response = await query;
      
      // Convert to WaterLogEntry objects
      return (response as List).map((entry) => WaterLogEntry.fromJson(entry)).toList();
    } catch (e) {
      debugPrint('Error getting water logs: $e');
      return [];
    }
  }
  
  // Log workout
  static Future<String> logWorkout({
    required String userId,
    required String workoutType,
    required int durationMinutes,
    DateTime? date,
    int? caloriesBurned,
    String? notes,
  }) async {
    try {
      final uuid = const Uuid();
      final entryId = uuid.v4();
      final now = date ?? DateTime.now();
      
      await _supabase.from('workout_logs').insert({
        'id': entryId,
        'user_id': userId,
        'workout_type': workoutType,
        'duration_minutes': durationMinutes,
        'date': now.toIso8601String(),
        'calories_burned': caloriesBurned,
        'notes': notes,
      });
      
      return entryId;
    } catch (e) {
      debugPrint('Error logging workout: $e');
      rethrow;
    }
  }
  
  // Get workout logs
  static Future<List<WorkoutLogEntry>> getWorkoutLogs({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 10,
  }) async {
    try {
      var query = _supabase
          .from('workout_logs')
          .select()
          .eq('user_id', userId)
          .order('date', ascending: false)
          .limit(limit);
      
      final response = await query;
      
      // Convert to WorkoutLogEntry objects
      return (response as List).map((entry) => WorkoutLogEntry.fromJson(entry)).toList();
    } catch (e) {
      debugPrint('Error getting workout logs: $e');
      return [];
    }
  }
  
  // Log nutrition entry
  static Future<String> logNutrition({
    required String userId,
    required String mealType,
    required String foodName,
    DateTime? date,
    int? calories,
    int? proteinG,
    int? carbsG,
    int? fatG,
    String? notes,
  }) async {
    try {
      final uuid = const Uuid();
      final entryId = uuid.v4();
      final now = date ?? DateTime.now();
      
      await _supabase.from('nutrition_logs').insert({
        'id': entryId,
        'user_id': userId,
        'meal_type': mealType,
        'food_name': foodName,
        'date': now.toIso8601String(),
        'calories': calories,
        'protein_g': proteinG,
        'carbs_g': carbsG,
        'fat_g': fatG,
        'notes': notes,
      });
      
      return entryId;
    } catch (e) {
      debugPrint('Error logging nutrition: $e');
      rethrow;
    }
  }
  
  // Get nutrition logs
  static Future<List<NutritionLogEntry>> getNutritionLogs({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
    String? mealType,
    int limit = 20,
  }) async {
    try {
      var query = _supabase
          .from('nutrition_logs')
          .select()
          .eq('user_id', userId)
          .order('date', ascending: false)
          .limit(limit);
      
      // Filter by meal type after fetching results
      final response = await query;
      
      // Convert to NutritionLogEntry objects
      var entries = (response as List).map((entry) => NutritionLogEntry.fromJson(entry)).toList();
      
      // Apply meal type filter if needed
      if (mealType != null) {
        entries = entries.where((entry) => entry.mealType == mealType).toList();
      }
      
      return entries;
    } catch (e) {
      debugPrint('Error getting nutrition logs: $e');
      return [];
    }
  }
  
  // Get nutrition summary for a specific day
  static Future<NutritionSummary> getNutritionSummaryForDay({
    required String userId,
    DateTime? date,
  }) async {
    try {
      final logs = await getNutritionLogs(
        userId: userId,
        limit: 100,
      );
      
      if (logs.isEmpty) {
        return NutritionSummary(
          totalCalories: 0,
          totalProteinG: 0,
          totalCarbsG: 0,
          totalFatG: 0,
        );
      }
      
      // Filter logs for the specific day
      final targetDate = date ?? DateTime.now();
      final startDate = DateTime(targetDate.year, targetDate.month, targetDate.day);
      final endDate = startDate.add(const Duration(days: 1));
      
      final logsForDay = logs.where((log) {
        final logDate = log.date;
        return logDate.isAfter(startDate) && logDate.isBefore(endDate);
      }).toList();
      
      // Calculate totals
      int totalCalories = 0;
      int totalProtein = 0;
      int totalCarbs = 0;
      int totalFat = 0;
      Map<String, int> mealCounts = {};
      
      for (var log in logsForDay) {
        totalCalories += log.calories ?? 0;
        totalProtein += log.proteinG ?? 0;
        totalCarbs += log.carbsG ?? 0;
        totalFat += log.fatG ?? 0;
        
        mealCounts[log.mealType] = (mealCounts[log.mealType] ?? 0) + 1;
      }
      
      return NutritionSummary(
        totalCalories: totalCalories,
        totalProteinG: totalProtein,
        totalCarbsG: totalCarbs,
        totalFatG: totalFat,
        mealCounts: mealCounts,
      );
    } catch (e) {
      debugPrint('Error getting nutrition summary for day: $e');
      return NutritionSummary(
        totalCalories: 0,
        totalProteinG: 0,
        totalCarbsG: 0,
        totalFatG: 0,
      );
    }
  }
}

class WeightLogEntry {
  final String id;
  final String userId;
  final double weight;
  final DateTime date;
  final String? notes;
  final DateTime createdAt;

  WeightLogEntry({
    required this.id,
    required this.userId,
    required this.weight,
    required this.date,
    this.notes,
    required this.createdAt,
  });

  factory WeightLogEntry.fromJson(Map<String, dynamic> json) {
    return WeightLogEntry(
      id: json['id'],
      userId: json['user_id'],
      weight: json['weight'].toDouble(),
      date: DateTime.parse(json['date']),
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'weight': weight,
      'date': date.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class WaterLogEntry {
  final String id;
  final String userId;
  final int amountMl;
  final DateTime timestamp;
  final DateTime createdAt;

  WaterLogEntry({
    required this.id,
    required this.userId,
    required this.amountMl,
    required this.timestamp,
    required this.createdAt,
  });

  factory WaterLogEntry.fromJson(Map<String, dynamic> json) {
    return WaterLogEntry(
      id: json['id'],
      userId: json['user_id'],
      amountMl: json['amount_ml'],
      timestamp: DateTime.parse(json['timestamp']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'amount_ml': amountMl,
      'timestamp': timestamp.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class WorkoutLogEntry {
  final String id;
  final String userId;
  final String workoutType;
  final int durationMinutes;
  final int? caloriesBurned;
  final DateTime date;
  final String? notes;
  final DateTime createdAt;

  WorkoutLogEntry({
    required this.id,
    required this.userId,
    required this.workoutType,
    required this.durationMinutes,
    this.caloriesBurned,
    required this.date,
    this.notes,
    required this.createdAt,
  });

  factory WorkoutLogEntry.fromJson(Map<String, dynamic> json) {
    return WorkoutLogEntry(
      id: json['id'],
      userId: json['user_id'],
      workoutType: json['workout_type'],
      durationMinutes: json['duration_minutes'],
      caloriesBurned: json['calories_burned'],
      date: DateTime.parse(json['date']),
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'workout_type': workoutType,
      'duration_minutes': durationMinutes,
      'calories_burned': caloriesBurned,
      'date': date.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class NutritionLogEntry {
  final String id;
  final String userId;
  final String mealType;
  final String foodName;
  final int? calories;
  final int? proteinG;
  final int? carbsG;
  final int? fatG;
  final DateTime date;
  final String? notes;
  final DateTime createdAt;

  NutritionLogEntry({
    required this.id,
    required this.userId,
    required this.mealType,
    required this.foodName,
    this.calories,
    this.proteinG,
    this.carbsG,
    this.fatG,
    required this.date,
    this.notes,
    required this.createdAt,
  });

  factory NutritionLogEntry.fromJson(Map<String, dynamic> json) {
    return NutritionLogEntry(
      id: json['id'],
      userId: json['user_id'],
      mealType: json['meal_type'],
      foodName: json['food_name'],
      calories: json['calories'],
      proteinG: json['protein_g'],
      carbsG: json['carbs_g'],
      fatG: json['fat_g'],
      date: DateTime.parse(json['date']),
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'meal_type': mealType,
      'food_name': foodName,
      'calories': calories,
      'protein_g': proteinG,
      'carbs_g': carbsG,
      'fat_g': fatG,
      'date': date.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class NutritionSummary {
  final int totalCalories;
  final int totalProteinG;
  final int totalCarbsG;
  final int totalFatG;
  final Map<String, int>? mealCounts;

  NutritionSummary({
    required this.totalCalories,
    required this.totalProteinG,
    required this.totalCarbsG,
    required this.totalFatG,
    this.mealCounts,
  });
} 