import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/logging_service.dart';
import '../main.dart';
import '../utils/motion_utils.dart';

class QuickLogWidget extends StatefulWidget {
  final Function? onLogComplete;
  
  const QuickLogWidget({super.key, this.onLogComplete});

  @override
  State<QuickLogWidget> createState() => _QuickLogWidgetState();
}

class _QuickLogWidgetState extends State<QuickLogWidget> with SingleTickerProviderStateMixin {
  final String? userId = supabase.auth.currentUser?.id;
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    // Initialize animation controller for staggered animations
    _animationController = MotionUtils.createStaggeredController(
      vsync: this,
      itemCount: 4, // Number of quick log options
    );
    
    // Start the animation when the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.background,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Row(
              children: [
                Text(
                  'Quick Log',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                // Material 3 Close button with animation
                Material(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.transparent,
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      // Reverse animation before popping
                      _animationController.reverse().then((_) {
                        Navigator.of(context).pop();
                      });
                    },
                    child: Ink(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: colorScheme.surfaceVariant.withOpacity(0.3),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.close_rounded,
                          color: colorScheme.onSurfaceVariant,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.3,
            children: [
              _buildLogOption(
                context,
                index: 0,
                icon: Icons.monitor_weight_rounded,
                title: 'Weight',
                color: colorScheme.primary,
                onTap: () => _showWeightLogDialog(context),
              ),
              _buildLogOption(
                context,
                index: 1,
                icon: Icons.water_drop_rounded,
                title: 'Water',
                color: colorScheme.tertiary,
                onTap: () => _showWaterLogDialog(context),
              ),
              _buildLogOption(
                context,
                index: 2,
                icon: Icons.fitness_center_rounded,
                title: 'Workout',
                color: colorScheme.secondary,
                onTap: () => _showWorkoutLogDialog(context),
              ),
              _buildLogOption(
                context,
                index: 3,
                icon: Icons.restaurant_rounded,
                title: 'Nutrition',
                color: colorScheme.error,
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
    required int index,
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // Get staggered animation for this item
    final animation = MotionUtils.getStaggeredAnimation(
      controller: _animationController,
      index: index,
      itemCount: 4,
    );
    
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - animation.value)),
          child: Opacity(
            opacity: animation.value,
            child: child,
          ),
        );
      },
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: color.withOpacity(0.1),
          highlightColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  void _showWeightLogDialog(BuildContext context) {
    final weightController = TextEditingController();
    final notesController = TextEditingController();
    // Create a new key each time the dialog is shown
    final formKey = GlobalKey<FormState>(debugLabel: 'weightFormKey_${DateTime.now().millisecondsSinceEpoch}');
    
    // Use Motion Utils fade scale transition for dialogs
    Navigator.of(context).push(
      MotionUtils.createFadeScale(
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.monitor_weight_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text('Log Weight'),
            ],
          ),
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
                    prefixIcon: Icon(Icons.scale),
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
                    prefixIcon: Icon(Icons.note),
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
            FilledButton.icon(
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
                        _showSuccessSnackBar(context, 'Weight logged successfully');
                        widget.onLogComplete?.call();
                      } else {
                        _showErrorSnackBar(context, 'Failed to log weight');
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      _showErrorSnackBar(context, 'Error: $e');
                    }
                  }
                }
              },
              icon: const Icon(Icons.save_rounded),
              label: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showWaterLogDialog(BuildContext context) {
    final waterController = TextEditingController();
    // Create a new key each time the dialog is shown
    final formKey = GlobalKey<FormState>(debugLabel: 'waterFormKey_${DateTime.now().millisecondsSinceEpoch}');
    final colorScheme = Theme.of(context).colorScheme;
    
    // Use Motion Utils fade scale transition for dialogs
    Navigator.of(context).push(
      MotionUtils.createFadeScale(
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.tertiary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.water_drop_rounded,
                  color: colorScheme.tertiary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text('Log Water'),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: waterController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount (ml)',
                    prefixIcon: Icon(Icons.local_drink),
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
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildQuickAmountChip(context, 250, waterController),
                    _buildQuickAmountChip(context, 500, waterController),
                    _buildQuickAmountChip(context, 750, waterController),
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
            FilledButton.icon(
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
                        _showSuccessSnackBar(context, 'Water logged successfully');
                        widget.onLogComplete?.call();
                      } else {
                        _showErrorSnackBar(context, 'Failed to log water');
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      _showErrorSnackBar(context, 'Error: $e');
                    }
                  }
                }
              },
              icon: const Icon(Icons.save_rounded),
              label: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQuickAmountChip(
    BuildContext context,
    int amount,
    TextEditingController controller,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return InputChip(
      label: Text('$amount ml'),
      avatar: Icon(Icons.water_drop_rounded, size: 18, color: colorScheme.tertiary),
      backgroundColor: colorScheme.surfaceVariant,
      labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
      onPressed: () {
        controller.text = amount.toString();
      },
    );
  }
  
  void _showWorkoutLogDialog(BuildContext context) {
    final workoutNameController = TextEditingController();
    final durationController = TextEditingController();
    final caloriesController = TextEditingController();
    final notesController = TextEditingController();
    // Create a new key each time the dialog is shown
    final formKey = GlobalKey<FormState>(debugLabel: 'workoutFormKey_${DateTime.now().millisecondsSinceEpoch}');
    final colorScheme = Theme.of(context).colorScheme;
    
    // Predefined workout types
    final workoutTypes = [
      'Running', 'Walking', 'Cycling', 'Swimming',
      'Weightlifting', 'HIIT', 'Yoga', 'Pilates',
      'CrossFit', 'Cardio', 'Other'
    ];
    
    // Use Motion Utils fade scale transition for dialogs
    Navigator.of(context).push(
      MotionUtils.createFadeScale(
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.secondary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.fitness_center_rounded,
                  color: colorScheme.secondary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text('Log Workout'),
            ],
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Workout Type',
                      prefixIcon: Icon(Icons.category_rounded),
                    ),
                    items: workoutTypes.map((type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        workoutNameController.text = value;
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
                      prefixIcon: Icon(Icons.timer_rounded),
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
                      prefixIcon: Icon(Icons.local_fire_department_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      prefixIcon: Icon(Icons.note_rounded),
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
            FilledButton.icon(
              onPressed: () async {
                if (formKey.currentState!.validate() && userId != null) {
                  final workoutType = workoutNameController.text;
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
                        _showSuccessSnackBar(context, 'Workout logged successfully');
                        widget.onLogComplete?.call();
                      } else {
                        _showErrorSnackBar(context, 'Failed to log workout');
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      _showErrorSnackBar(context, 'Error: $e');
                    }
                  }
                }
              },
              icon: const Icon(Icons.save_rounded),
              label: const Text('Save'),
            ),
          ],
        ),
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
    // Create a new key each time the dialog is shown
    final formKey = GlobalKey<FormState>(debugLabel: 'nutritionFormKey_${DateTime.now().millisecondsSinceEpoch}');
    final colorScheme = Theme.of(context).colorScheme;
    
    // Predefined meal types
    final mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];
    
    // Use Motion Utils fade scale transition for dialogs
    Navigator.of(context).push(
      MotionUtils.createFadeScale(
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.error.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.restaurant_rounded,
                  color: colorScheme.error,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text('Log Nutrition'),
            ],
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Meal Type',
                      prefixIcon: Icon(Icons.category_rounded),
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
                      prefixIcon: Icon(Icons.fastfood_rounded),
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
                      prefixIcon: Icon(Icons.local_fire_department_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: proteinController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Protein (g)',
                            prefixIcon: Icon(Icons.egg_rounded),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: carbsController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Carbs (g)',
                            prefixIcon: Icon(Icons.bakery_dining_rounded),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: fatController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Fat (g)',
                      prefixIcon: Icon(Icons.oil_barrel_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      prefixIcon: Icon(Icons.note_rounded),
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
            FilledButton.icon(
              onPressed: () async {
                if (formKey.currentState!.validate() && userId != null) {
                  final mealType = mealTypeController.text;
                  final foodName = foodNameController.text;
                  final calories = caloriesController.text.isNotEmpty 
                      ? int.parse(caloriesController.text) 
                      : null;
                  final protein = proteinController.text.isNotEmpty 
                      ? int.parse(proteinController.text) 
                      : null;
                  final carbs = carbsController.text.isNotEmpty 
                      ? int.parse(carbsController.text) 
                      : null;
                  final fat = fatController.text.isNotEmpty 
                      ? int.parse(fatController.text) 
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
                      proteinG: protein,
                      carbsG: carbs,
                      fatG: fat,
                      notes: notes,
                    );
                    
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      if (entryId.isNotEmpty) {
                        _showSuccessSnackBar(context, 'Nutrition logged successfully');
                        widget.onLogComplete?.call();
                      } else {
                        _showErrorSnackBar(context, 'Failed to log nutrition');
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      _showErrorSnackBar(context, 'Error: $e');
                    }
                  }
                }
              },
              icon: const Icon(Icons.save_rounded),
              label: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showSuccessSnackBar(BuildContext context, String message) {
    final colorScheme = Theme.of(context).colorScheme;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white24,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Text(message),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.successColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
  
  void _showErrorSnackBar(BuildContext context, String message) {
    final colorScheme = Theme.of(context).colorScheme;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white24,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(message)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.error,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}