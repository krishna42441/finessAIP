import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/plan_models.dart';

/// Service for caching data to improve app performance
class CacheService {
  static late Box _cache;
  static const String _workoutPlansKey = 'workout_plans';
  static const String _nutritionPlansKey = 'nutrition_plans';
  static const String _userProfileKey = 'user_profile';
  
  /// Initialize the cache service
  static Future<void> initialize() async {
    await Hive.initFlutter();
    _cache = await Hive.openBox('app_cache');
    
    print('Cache service initialized');
  }
  
  /// Store workout plan in cache with expiration
  static Future<void> cacheWorkoutPlan(String userId, Map<String, dynamic> plan) async {
    final cacheItem = {
      'data': plan,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    
    await _cache.put('${_workoutPlansKey}_$userId', jsonEncode(cacheItem));
  }
  
  /// Get cached workout plan if it exists and is not expired
  static Map<String, dynamic>? getWorkoutPlan(String userId, {int maxAgeMinutes = 60}) {
    final cachedData = _cache.get('${_workoutPlansKey}_$userId');
    if (cachedData == null) return null;
    
    final cacheItem = jsonDecode(cachedData);
    final timestamp = cacheItem['timestamp'] as int;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    // Check if cache is expired
    if (now - timestamp > maxAgeMinutes * 60 * 1000) {
      _cache.delete('${_workoutPlansKey}_$userId');
      return null;
    }
    
    return cacheItem['data'];
  }
  
  /// Store nutrition plan in cache with expiration
  static Future<void> cacheNutritionPlan(String userId, Map<String, dynamic> plan) async {
    final cacheItem = {
      'data': plan,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    
    await _cache.put('${_nutritionPlansKey}_$userId', jsonEncode(cacheItem));
  }
  
  /// Get cached nutrition plan if it exists and is not expired
  static Map<String, dynamic>? getNutritionPlan(String userId, {int maxAgeMinutes = 60}) {
    final cachedData = _cache.get('${_nutritionPlansKey}_$userId');
    if (cachedData == null) return null;
    
    final cacheItem = jsonDecode(cachedData);
    final timestamp = cacheItem['timestamp'] as int;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    // Check if cache is expired
    if (now - timestamp > maxAgeMinutes * 60 * 1000) {
      _cache.delete('${_nutritionPlansKey}_$userId');
      return null;
    }
    
    return cacheItem['data'];
  }
  
  /// Store user profile in cache
  static Future<void> cacheUserProfile(String userId, Map<String, dynamic> profile) async {
    final cacheItem = {
      'data': profile,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    
    await _cache.put('${_userProfileKey}_$userId', jsonEncode(cacheItem));
  }
  
  /// Get cached user profile if it exists and is not expired
  static Map<String, dynamic>? getUserProfile(String userId, {int maxAgeMinutes = 30}) {
    final cachedData = _cache.get('${_userProfileKey}_$userId');
    if (cachedData == null) return null;
    
    final cacheItem = jsonDecode(cachedData);
    final timestamp = cacheItem['timestamp'] as int;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    // Check if cache is expired
    if (now - timestamp > maxAgeMinutes * 60 * 1000) {
      _cache.delete('${_userProfileKey}_$userId');
      return null;
    }
    
    return cacheItem['data'];
  }
  
  /// Clear specific cache
  static Future<void> clearCache(String key, String userId) async {
    await _cache.delete('${key}_$userId');
  }
  
  /// Clear all cache for a user
  static Future<void> clearAllUserCache(String userId) async {
    await _cache.delete('${_workoutPlansKey}_$userId');
    await _cache.delete('${_nutritionPlansKey}_$userId');
    await _cache.delete('${_userProfileKey}_$userId');
  }
  
  /// Clear all cache
  static Future<void> clearAllCache() async {
    await _cache.clear();
  }
} 