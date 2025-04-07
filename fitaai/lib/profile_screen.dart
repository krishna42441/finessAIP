import 'package:flutter/material.dart';
import 'package:fitaai/services/plan_service.dart';
import 'package:fitaai/models/plan_type.dart';

class ProfileScreen extends StatefulWidget {
  // ... (existing code)
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ... (existing code)

  void _generateWorkoutPlan() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You need to be logged in to generate a workout plan.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Generating your workout and nutrition plans...'),
          ],
        ),
      ),
    );
    
    try {
      // Use the PlanService to generate both plans together
      final result = await PlanService.generatePlans(userId, PlanType.both);
      
      // Close loading dialog
      if (context.mounted) Navigator.of(context).pop();
      
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workout and nutrition plans generated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception(result['message']);
      }
    } catch (e) {
      debugPrint('Error generating plans: $e');
      
      // Close loading dialog if still showing
      if (context.mounted) Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate plans: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _generateNutritionPlan() async {
    // Redirect to workout plan generator which will generate both plans
    _generateWorkoutPlan();
  }

  @override
  Widget build(BuildContext context) {
    // ... (existing code)
  }
} 