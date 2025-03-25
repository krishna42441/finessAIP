import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/logging_service.dart';
import '../main.dart';

class QuickLogWidget extends StatefulWidget {
  final Function? onLogComplete;
  
  const QuickLogWidget({super.key, this.onLogComplete});

  @override
  State<QuickLogWidget> createState() => _QuickLogWidgetState();
}

class _QuickLogWidgetState extends State<QuickLogWidget> {
  final String? userId = supabase.auth.currentUser?.id;
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Text(
                  'Quick Log',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            childAspectRatio: 1.5,
            children: [
              _buildLogOption(
                context,
                icon: Icons.monitor_weight,
                title: 'Weight',
                color: Colors.purple,
                onTap: () => _showWeightLogDialog(context),
              ),
              _buildLogOption(
                context,
                icon: Icons.water_drop,
                title: 'Water',
                color: Colors.blue,
                onTap: () => _showWaterLogDialog(context),
              ),
              _buildLogOption(
                context,
                icon: Icons.fitness_center,
                title: 'Workout',
                color: Colors.orange,
                onTap: () => _showWorkoutLogDialog(context),
              ),
              _buildLogOption(
                context,
                icon: Icons.restaurant,
                title: 'Nutrition',
                color: Colors.green,
                onTap: () => _showNutritionLogDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
  
  Widget _buildLogOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      color: AppTheme.surfaceColor,
      margin: const EdgeInsets.all(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showWeightLogDialog(BuildContext context) {
    final weightController = TextEditingController();
    final notesController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text('Log Weight'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Weight (kg)',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your weight';
                  }
                  final weight = double.tryParse(value);
                  if (weight == null || weight <= 0) {
                    return 'Please enter a valid weight';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (formKey.currentState!.validate() && userId != null) {
                final weight = double.parse(weightController.text);
                final notes = notesController.text.isNotEmpty ? notesController.text : null;
                
                try {
                  final entryId = await LoggingService.logWeight(
                    userId: userId!,
                    weight: weight,
                    date: DateTime.now(),
                    notes: notes,
                  );
                  
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    if (entryId.isNotEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Weight logged successfully')),
                      );
                      widget.onLogComplete?.call();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to log weight')),
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
  
  void _showWaterLogDialog(BuildContext context) {
    final waterController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text('Log Water'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: waterController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Amount (ml)',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter amount';
                        }
                        final amount = int.tryParse(value);
                        if (amount == null || amount <= 0) {
                          return 'Please enter a valid amount';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildQuickAmountButton(context, 250, waterController),
                  _buildQuickAmountButton(context, 500, waterController),
                  _buildQuickAmountButton(context, 750, waterController),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (formKey.currentState!.validate() && userId != null) {
                final amount = int.parse(waterController.text);
                
                try {
                  final entryId = await LoggingService.logWater(
                    userId: userId!,
                    amountMl: amount,
                  );
                  
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    if (entryId.isNotEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Water logged successfully')),
                      );
                      widget.onLogComplete?.call();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to log water')),
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuickAmountButton(
    BuildContext context,
    int amount,
    TextEditingController controller,
  ) {
    return FilledButton.tonal(
      onPressed: () {
        controller.text = amount.toString();
      },
      child: Text('$amount ml'),
    );
  }
  
  void _showWorkoutLogDialog(BuildContext context) {
    final typeController = TextEditingController();
    final durationController = TextEditingController();
    final caloriesController = TextEditingController();
    final notesController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    
    // Predefined workout types
    final workoutTypes = [
      'Running', 'Walking', 'Cycling', 'Swimming',
      'Weightlifting', 'HIIT', 'Yoga', 'Pilates',
      'CrossFit', 'Cardio', 'Other'
    ];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text('Log Workout'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  dropdownColor: AppTheme.backgroundColor,
                  decoration: const InputDecoration(
                    labelText: 'Workout Type',
                  ),
                  items: workoutTypes.map((type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      typeController.text = value;
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a workout type';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: durationController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Duration (minutes)',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter duration';
                    }
                    final duration = int.tryParse(value);
                    if (duration == null || duration <= 0) {
                      return 'Please enter a valid duration';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: caloriesController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Calories Burned (optional)',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (formKey.currentState!.validate() && userId != null) {
                final workoutType = typeController.text;
                final duration = int.parse(durationController.text);
                final calories = caloriesController.text.isNotEmpty 
                    ? int.parse(caloriesController.text) 
                    : null;
                final notes = notesController.text.isNotEmpty 
                    ? notesController.text 
                    : null;
                
                try {
                  final entryId = await LoggingService.logWorkout(
                    userId: userId!,
                    workoutType: workoutType,
                    durationMinutes: duration,
                    date: DateTime.now(),
                    caloriesBurned: calories,
                    notes: notes,
                  );
                  
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    if (entryId.isNotEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Workout logged successfully')),
                      );
                      widget.onLogComplete?.call();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to log workout')),
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
  
  void _showNutritionLogDialog(BuildContext context) {
    final mealTypeController = TextEditingController();
    final foodNameController = TextEditingController();
    final caloriesController = TextEditingController();
    final proteinController = TextEditingController();
    final carbsController = TextEditingController();
    final fatController = TextEditingController();
    final notesController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    
    // Predefined meal types
    final mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text('Log Nutrition'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  dropdownColor: AppTheme.backgroundColor,
                  decoration: const InputDecoration(
                    labelText: 'Meal Type',
                  ),
                  items: mealTypes.map((type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      mealTypeController.text = value;
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a meal type';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: foodNameController,
                  decoration: const InputDecoration(
                    labelText: 'Food Name',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter food name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: caloriesController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Calories',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: proteinController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Protein (g)',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: carbsController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Carbs (g)',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: fatController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Fat (g)',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (formKey.currentState!.validate() && userId != null) {
                final mealType = mealTypeController.text;
                final foodName = foodNameController.text;
                final calories = caloriesController.text.isNotEmpty 
                    ? int.parse(caloriesController.text) 
                    : null;
                final protein = proteinController.text.isNotEmpty 
                    ? double.parse(proteinController.text) 
                    : null;
                final carbs = carbsController.text.isNotEmpty 
                    ? double.parse(carbsController.text) 
                    : null;
                final fat = fatController.text.isNotEmpty 
                    ? double.parse(fatController.text) 
                    : null;
                final notes = notesController.text.isNotEmpty 
                    ? notesController.text 
                    : null;
                
                try {
                  final entryId = await LoggingService.logNutrition(
                    userId: userId!,
                    mealType: mealType,
                    foodName: foodName,
                    date: DateTime.now(),
                    calories: calories,
                    proteinG: protein != null ? protein.toInt() : null,
                    carbsG: carbs != null ? carbs.toInt() : null,
                    fatG: fat != null ? fat.toInt() : null,
                    notes: notes,
                  );
                  
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    if (entryId.isNotEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Nutrition logged successfully')),
                      );
                      widget.onLogComplete?.call();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to log nutrition')),
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
} 