import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

class OnboardingHelper {
  /// Checks if the user has completed their profile
  static Future<bool> isProfileComplete() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        return false;
      }
      
      final response = await supabase
          .from('user_profiles')
          .select('full_name, age, gender, height_cm, weight_kg, primary_fitness_goal')
          .eq('user_id', userId)
          .single();
      
      if (response == null) {
        return false;
      }
      
      // Check for required fields
      final bool hasName = response['full_name'] != null && response['full_name'].toString().isNotEmpty;
      final bool hasAge = response['age'] != null;
      final bool hasGender = response['gender'] != null && response['gender'].toString().isNotEmpty;
      final bool hasHeight = response['height_cm'] != null;
      final bool hasWeight = response['weight_kg'] != null;
      final bool hasGoal = response['primary_fitness_goal'] != null && response['primary_fitness_goal'].toString().isNotEmpty;
      
      // Consider profile complete if all required fields are filled
      return hasName && hasAge && hasGender && hasHeight && hasWeight && hasGoal;
      
    } catch (e) {
      print('Error checking profile completion: $e');
      return false;
    }
  }
  
  /// Shows the onboarding notification if profile is incomplete
  static Future<void> showOnboardingNotificationIfNeeded(BuildContext context) async {
    final bool isComplete = await isProfileComplete();
    
    if (!isComplete && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Complete your profile to get personalized plans'),
          backgroundColor: Theme.of(context).colorScheme.secondary,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'COMPLETE',
            textColor: Colors.white,
            onPressed: () {
              Navigator.of(context).pushNamed('/profile');
            },
          ),
        ),
      );
    }
  }
} 