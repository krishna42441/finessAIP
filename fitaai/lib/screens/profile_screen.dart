import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../main.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;
  String? _errorMessage;
  
  // User profile data
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  String _gender = 'Prefer not to say';
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  String _fitnessLevel = 'Beginner';
  final TextEditingController _weeklyExerciseDaysController = TextEditingController();
  bool _previousProgramExperience = false;
  String _primaryFitnessGoal = 'Weight loss';
  final TextEditingController _specificTargetsController = TextEditingController();
  final TextEditingController _motivationController = TextEditingController();
  Map<String, dynamic> _workoutPreferences = {};
  String _indoorOutdoorPreference = 'Indoor';
  final TextEditingController _workoutDaysPerWeekController = TextEditingController();
  final TextEditingController _workoutMinutesPerSessionController = TextEditingController();
  final TextEditingController _equipmentAccessController = TextEditingController();
  Map<String, dynamic> _dietaryRestrictions = {};
  final TextEditingController _eatingHabitsController = TextEditingController();
  final TextEditingController _favoriteFoodsController = TextEditingController();
  final TextEditingController _avoidedFoodsController = TextEditingController();
  Map<String, dynamic> _medicalConditions = {};
  final TextEditingController _medicationsController = TextEditingController();
  final TextEditingController _fitnessConcernsController = TextEditingController();
  String _dailyActivityLevel = 'Moderate';
  final TextEditingController _sleepHoursController = TextEditingController();
  String _stressLevel = 'Medium';
  String? _progressPhotoUrl;
  bool _aiSuggestionsEnabled = true;
  final TextEditingController _additionalNotesController = TextEditingController();

  final List<String> _fitnessLevels = ['Beginner', 'Intermediate', 'Advanced'];
  final List<String> _genderOptions = ['Male', 'Female', 'Non-binary', 'Prefer not to say'];
  final List<String> _fitnessGoals = ['Weight loss', 'Muscle gain', 'Endurance', 'Flexibility', 'Overall fitness'];
  final List<String> _activityLevels = ['Sedentary', 'Moderate', 'Active'];
  final List<String> _stressLevels = ['Low', 'Medium', 'High'];
  final List<String> _locationPreferences = ['Indoor', 'Outdoor', 'Both'];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    // Dispose all controllers
    _fullNameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _weeklyExerciseDaysController.dispose();
    _specificTargetsController.dispose();
    _motivationController.dispose();
    _workoutDaysPerWeekController.dispose();
    _workoutMinutesPerSessionController.dispose();
    _equipmentAccessController.dispose();
    _eatingHabitsController.dispose();
    _favoriteFoodsController.dispose();
    _avoidedFoodsController.dispose();
    _medicationsController.dispose();
    _fitnessConcernsController.dispose();
    _sleepHoursController.dispose();
    _additionalNotesController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get current user ID
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Fetch user profile data
      final response = await supabase
          .from('user_profiles')
          .select()
          .eq('user_id', userId)
          .single();

      if (response != null) {
        // Populate form fields
        setState(() {
          _fullNameController.text = response['full_name'] ?? '';
          _emailController.text = supabase.auth.currentUser?.email ?? '';
          _ageController.text = response['age']?.toString() ?? '';
          _gender = response['gender'] ?? 'Prefer not to say';
          _heightController.text = response['height_cm']?.toString() ?? '';
          _weightController.text = response['weight_kg']?.toString() ?? '';
          _fitnessLevel = response['fitness_level'] ?? 'Beginner';
          _weeklyExerciseDaysController.text = response['weekly_exercise_days']?.toString() ?? '';
          _previousProgramExperience = response['previous_program_experience'] ?? false;
          _primaryFitnessGoal = response['primary_fitness_goal'] ?? 'Weight loss';
          _specificTargetsController.text = response['specific_targets'] ?? '';
          _motivationController.text = response['motivation'] ?? '';
          _workoutPreferences = response['workout_preferences'] ?? {};
          _indoorOutdoorPreference = response['indoor_outdoor_preference'] ?? 'Indoor';
          _workoutDaysPerWeekController.text = response['workout_days_per_week']?.toString() ?? '';
          _workoutMinutesPerSessionController.text = response['workout_minutes_per_session']?.toString() ?? '';
          _equipmentAccessController.text = response['equipment_access'] ?? '';
          _dietaryRestrictions = response['dietary_restrictions'] ?? {};
          _eatingHabitsController.text = response['eating_habits'] ?? '';
          _favoriteFoodsController.text = response['favorite_foods'] ?? '';
          _avoidedFoodsController.text = response['avoided_foods'] ?? '';
          _medicalConditions = response['medical_conditions'] ?? {};
          _medicationsController.text = response['medications'] ?? '';
          _fitnessConcernsController.text = response['fitness_concerns'] ?? '';
          _dailyActivityLevel = response['daily_activity_level'] ?? 'Moderate';
          _sleepHoursController.text = response['sleep_hours']?.toString() ?? '';
          _stressLevel = response['stress_level'] ?? 'Medium';
          _progressPhotoUrl = response['progress_photo_url'];
          _aiSuggestionsEnabled = response['ai_suggestions_enabled'] ?? true;
          _additionalNotesController.text = response['additional_notes'] ?? '';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading profile: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      // Get current user ID
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Prepare data for update
      final data = {
        'user_id': userId,
        'full_name': _fullNameController.text,
        'age': _ageController.text.isNotEmpty ? int.parse(_ageController.text) : null,
        'gender': _gender,
        'height_cm': _heightController.text.isNotEmpty ? double.parse(_heightController.text) : null,
        'weight_kg': _weightController.text.isNotEmpty ? double.parse(_weightController.text) : null,
        'fitness_level': _fitnessLevel,
        'weekly_exercise_days': _weeklyExerciseDaysController.text.isNotEmpty ? int.parse(_weeklyExerciseDaysController.text) : null,
        'previous_program_experience': _previousProgramExperience,
        'primary_fitness_goal': _primaryFitnessGoal,
        'specific_targets': _specificTargetsController.text,
        'motivation': _motivationController.text,
        'workout_preferences': _workoutPreferences,
        'indoor_outdoor_preference': _indoorOutdoorPreference,
        'workout_days_per_week': _workoutDaysPerWeekController.text.isNotEmpty ? int.parse(_workoutDaysPerWeekController.text) : null,
        'workout_minutes_per_session': _workoutMinutesPerSessionController.text.isNotEmpty ? int.parse(_workoutMinutesPerSessionController.text) : null,
        'equipment_access': _equipmentAccessController.text,
        'dietary_restrictions': _dietaryRestrictions,
        'eating_habits': _eatingHabitsController.text,
        'favorite_foods': _favoriteFoodsController.text,
        'avoided_foods': _avoidedFoodsController.text,
        'medical_conditions': _medicalConditions,
        'medications': _medicationsController.text,
        'fitness_concerns': _fitnessConcernsController.text,
        'daily_activity_level': _dailyActivityLevel,
        'sleep_hours': _sleepHoursController.text.isNotEmpty ? int.parse(_sleepHoursController.text) : null,
        'stress_level': _stressLevel,
        'progress_photo_url': _progressPhotoUrl,
        'ai_suggestions_enabled': _aiSuggestionsEnabled,
        'additional_notes': _additionalNotesController.text,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Check if profile exists
      final exists = await supabase
          .from('user_profiles')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      if (exists == null) {
        // Insert new profile
        await supabase
            .from('user_profiles')
            .insert(data);
      } else {
        // Update existing profile
        await supabase
            .from('user_profiles')
            .update(data)
            .eq('user_id', userId);
      }

      // Update user's full name in auth metadata
      await supabase.auth.updateUser(
        UserAttributes(
          data: {'full_name': _fullNameController.text},
        ),
      );

      setState(() {
        _isEditing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error saving profile: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Profile'),
        elevation: 0,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isEditing = false;
                });
                _loadUserProfile();
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.primaryColor.withOpacity(0.2),
                        AppTheme.backgroundColor,
                      ],
                      stops: const [0.0, 0.3],
                    ),
                  ),
                ),
                Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red[300]),
                          ),
                        ),
                      
                      // Profile photo
                      Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: AppTheme.cardColor,
                              backgroundImage: _progressPhotoUrl != null
                                  ? NetworkImage(_progressPhotoUrl!)
                                  : null,
                              child: _progressPhotoUrl == null
                                  ? const Icon(Icons.person, size: 50)
                                  : null,
                            ),
                            if (_isEditing)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: CircleAvatar(
                                  backgroundColor: AppTheme.primaryColor,
                                  radius: 18,
                                  child: IconButton(
                                    icon: const Icon(Icons.camera_alt, size: 18),
                                    color: Colors.white,
                                    onPressed: () {
                                      // TODO: Implement photo upload
                                    },
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Basic Information Section
                      _buildSectionTitle('Basic Information'),
                      
                      _buildTextField(
                        label: 'Full Name',
                        controller: _fullNameController,
                        enabled: _isEditing,
                        validator: (value) => value == null || value.isEmpty ? 'Please enter your name' : null,
                      ),
                      
                      _buildTextField(
                        label: 'Email',
                        controller: _emailController,
                        enabled: false, // Email is not editable
                        keyboardType: TextInputType.emailAddress,
                      ),
                      
                      _buildTextField(
                        label: 'Age',
                        controller: _ageController,
                        enabled: _isEditing,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                      
                      _buildDropdown(
                        label: 'Gender',
                        value: _gender,
                        items: _genderOptions,
                        onChanged: _isEditing
                            ? (value) {
                                if (value != null) {
                                  setState(() {
                                    _gender = value;
                                  });
                                }
                              }
                            : null,
                      ),
                      
                      _buildTextField(
                        label: 'Height (cm)',
                        controller: _heightController,
                        enabled: _isEditing,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                      ),
                      
                      _buildTextField(
                        label: 'Weight (kg)',
                        controller: _weightController,
                        enabled: _isEditing,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                      ),
                      
                      // Fitness Background Section
                      _buildSectionTitle('Fitness Background'),
                      
                      _buildDropdown(
                        label: 'Fitness Level',
                        value: _fitnessLevel,
                        items: _fitnessLevels,
                        onChanged: _isEditing
                            ? (value) {
                                if (value != null) {
                                  setState(() {
                                    _fitnessLevel = value;
                                  });
                                }
                              }
                            : null,
                      ),
                      
                      _buildTextField(
                        label: 'Weekly Exercise Days',
                        controller: _weeklyExerciseDaysController,
                        enabled: _isEditing,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                      
                      _buildSwitch(
                        label: 'Previous Program Experience',
                        value: _previousProgramExperience,
                        onChanged: _isEditing
                            ? (value) {
                                setState(() {
                                  _previousProgramExperience = value;
                                });
                              }
                            : null,
                      ),
                      
                      // Goals Section
                      _buildSectionTitle('Goals'),
                      
                      _buildDropdown(
                        label: 'Primary Fitness Goal',
                        value: _primaryFitnessGoal,
                        items: _fitnessGoals,
                        onChanged: _isEditing
                            ? (value) {
                                if (value != null) {
                                  setState(() {
                                    _primaryFitnessGoal = value;
                                  });
                                }
                              }
                            : null,
                      ),
                      
                      _buildTextField(
                        label: 'Specific Target Areas',
                        controller: _specificTargetsController,
                        enabled: _isEditing,
                        maxLines: 2,
                      ),
                      
                      _buildTextField(
                        label: 'Motivation',
                        controller: _motivationController,
                        enabled: _isEditing,
                        maxLines: 2,
                      ),
                      
                      // Workout Preferences Section
                      _buildSectionTitle('Workout Preferences'),
                      
                      _buildDropdown(
                        label: 'Indoor/Outdoor Preference',
                        value: _indoorOutdoorPreference,
                        items: _locationPreferences,
                        onChanged: _isEditing
                            ? (value) {
                                if (value != null) {
                                  setState(() {
                                    _indoorOutdoorPreference = value;
                                  });
                                }
                              }
                            : null,
                      ),
                      
                      _buildTextField(
                        label: 'Workout Days Per Week',
                        controller: _workoutDaysPerWeekController,
                        enabled: _isEditing,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                      
                      _buildTextField(
                        label: 'Workout Minutes Per Session',
                        controller: _workoutMinutesPerSessionController,
                        enabled: _isEditing,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                      
                      _buildTextField(
                        label: 'Equipment Access',
                        controller: _equipmentAccessController,
                        enabled: _isEditing,
                        maxLines: 2,
                      ),
                      
                      // Nutrition Section
                      _buildSectionTitle('Nutrition'),
                      
                      _buildTextField(
                        label: 'Eating Habits',
                        controller: _eatingHabitsController,
                        enabled: _isEditing,
                        maxLines: 2,
                      ),
                      
                      _buildTextField(
                        label: 'Favorite Foods',
                        controller: _favoriteFoodsController,
                        enabled: _isEditing,
                        maxLines: 2,
                      ),
                      
                      _buildTextField(
                        label: 'Avoided Foods',
                        controller: _avoidedFoodsController,
                        enabled: _isEditing,
                        maxLines: 2,
                      ),
                      
                      // Health Considerations Section
                      _buildSectionTitle('Health Considerations'),
                      
                      _buildTextField(
                        label: 'Medications',
                        controller: _medicationsController,
                        enabled: _isEditing,
                        maxLines: 2,
                      ),
                      
                      _buildTextField(
                        label: 'Fitness Concerns',
                        controller: _fitnessConcernsController,
                        enabled: _isEditing,
                        maxLines: 2,
                      ),
                      
                      _buildDropdown(
                        label: 'Daily Activity Level',
                        value: _dailyActivityLevel,
                        items: _activityLevels,
                        onChanged: _isEditing
                            ? (value) {
                                if (value != null) {
                                  setState(() {
                                    _dailyActivityLevel = value;
                                  });
                                }
                              }
                            : null,
                      ),
                      
                      _buildTextField(
                        label: 'Sleep Hours',
                        controller: _sleepHoursController,
                        enabled: _isEditing,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                      
                      _buildDropdown(
                        label: 'Stress Level',
                        value: _stressLevel,
                        items: _stressLevels,
                        onChanged: _isEditing
                            ? (value) {
                                if (value != null) {
                                  setState(() {
                                    _stressLevel = value;
                                  });
                                }
                              }
                            : null,
                      ),
                      
                      // Additional Information Section
                      _buildSectionTitle('Additional Information'),
                      
                      _buildSwitch(
                        label: 'AI Suggestions Enabled',
                        value: _aiSuggestionsEnabled,
                        onChanged: _isEditing
                            ? (value) {
                                setState(() {
                                  _aiSuggestionsEnabled = value;
                                });
                              }
                            : null,
                      ),
                      
                      _buildTextField(
                        label: 'Additional Notes',
                        controller: _additionalNotesController,
                        enabled: _isEditing,
                        maxLines: 3,
                      ),
                      
                      const SizedBox(height: 32),
                      
                      if (_isEditing)
                        _isSaving
                            ? const Center(child: CircularProgressIndicator())
                            : ElevatedButton(
                                onPressed: _saveProfile,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  backgroundColor: AppTheme.primaryColor,
                                ),
                                child: const Text('Save Profile'),
                              ),
                      
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: enabled ? AppTheme.cardColor.withOpacity(0.5) : AppTheme.cardColor.withOpacity(0.3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppTheme.primaryColor.withOpacity(0.3),
              width: 1.0,
            ),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        style: TextStyle(
          color: enabled ? Colors.white : Colors.white70,
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    Function(String?)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            decoration: BoxDecoration(
              color: onChanged != null 
                  ? AppTheme.cardColor.withOpacity(0.5) 
                  : AppTheme.cardColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: onChanged != null
                  ? Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      width: 1.0,
                    )
                  : null,
            ),
            child: DropdownButtonFormField<String>(
              value: value,
              onChanged: onChanged,
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              decoration: InputDecoration(
                labelText: label,
                border: InputBorder.none,
              ),
              style: TextStyle(
                color: onChanged != null ? Colors.white : Colors.white70,
              ),
              dropdownColor: AppTheme.cardColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitch({
    required String label,
    required bool value,
    Function(bool)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: onChanged != null ? Colors.white : Colors.white70,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }
} 