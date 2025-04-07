import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'dart:ui';

class EditPlanDialog extends StatefulWidget {
  final Map<String, dynamic> plan;
  final bool isWorkout; // true for workout, false for nutrition
  final Function(Map<String, dynamic>) onSave;

  const EditPlanDialog({
    super.key,
    required this.plan,
    required this.isWorkout,
    required this.onSave,
  });

  @override
  State<EditPlanDialog> createState() => _EditPlanDialogState();
}

class _EditPlanDialogState extends State<EditPlanDialog> {
  late Map<String, dynamic> _editedPlan;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _editedPlan = Map<String, dynamic>.from(widget.plan);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.cardColor.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.isWorkout ? 'Edit Workout' : 'Edit Meal',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Form(
                  key: _formKey,
                  child: widget.isWorkout
                      ? _buildWorkoutForm()
                      : _buildNutritionForm(),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 16),
                    FilledButton(
                      onPressed: _savePlan,
                      child: const Text('Save Changes'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWorkoutForm() {
    final exercise = _editedPlan['exercise'] ?? {};
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          initialValue: exercise['exercise_name'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Exercise Name',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            setState(() {
              exercise['exercise_name'] = value;
              _editedPlan['exercise'] = exercise;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter an exercise name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: exercise['sets']?.toString() ?? '',
                decoration: const InputDecoration(
                  labelText: 'Sets',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    exercise['sets'] = int.tryParse(value) ?? 0;
                    _editedPlan['exercise'] = exercise;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Invalid number';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                initialValue: exercise['reps']?.toString() ?? '',
                decoration: const InputDecoration(
                  labelText: 'Reps',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    exercise['reps'] = int.tryParse(value) ?? 0;
                    _editedPlan['exercise'] = exercise;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Invalid number';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: exercise['notes'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Notes',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          onChanged: (value) {
            setState(() {
              exercise['notes'] = value;
              _editedPlan['exercise'] = exercise;
            });
          },
        ),
      ],
    );
  }

  Widget _buildNutritionForm() {
    final meal = _editedPlan['meal'] ?? {};
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          initialValue: meal['meal_name'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Meal Name',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            setState(() {
              meal['meal_name'] = value;
              _editedPlan['meal'] = meal;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a meal name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: meal['total_calories']?.toString() ?? '',
                decoration: const InputDecoration(
                  labelText: 'Calories',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    meal['total_calories'] = int.tryParse(value) ?? 0;
                    _editedPlan['meal'] = meal;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Invalid number';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                initialValue: meal['protein_grams']?.toString() ?? '',
                decoration: const InputDecoration(
                  labelText: 'Protein (g)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    meal['protein_grams'] = int.tryParse(value) ?? 0;
                    _editedPlan['meal'] = meal;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Invalid number';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: meal['carbs_grams']?.toString() ?? '',
                decoration: const InputDecoration(
                  labelText: 'Carbs (g)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    meal['carbs_grams'] = int.tryParse(value) ?? 0;
                    _editedPlan['meal'] = meal;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Invalid number';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                initialValue: meal['fat_grams']?.toString() ?? '',
                decoration: const InputDecoration(
                  labelText: 'Fat (g)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    meal['fat_grams'] = int.tryParse(value) ?? 0;
                    _editedPlan['meal'] = meal;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Invalid number';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: meal['description'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Description',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          onChanged: (value) {
            setState(() {
              meal['description'] = value;
              _editedPlan['meal'] = meal;
            });
          },
        ),
      ],
    );
  }

  void _savePlan() {
    if (_formKey.currentState!.validate()) {
      widget.onSave(_editedPlan);
      Navigator.pop(context);
    }
  }
} 