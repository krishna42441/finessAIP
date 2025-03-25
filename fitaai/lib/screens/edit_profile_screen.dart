import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../main.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> profileData;
  
  const EditProfileScreen({super.key, required this.profileData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  File? _selectedImageFile;
  Uint8List? _selectedImageBytes;
  
  // User profile data controllers
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

  // Dropdown options
  final List<String> _fitnessLevels = ['Beginner', 'Intermediate', 'Advanced'];
  final List<String> _genderOptions = ['Male', 'Female', 'Non-binary', 'Prefer not to say'];
  final List<String> _fitnessGoals = ['Weight loss', 'Muscle gain', 'Endurance', 'Flexibility', 'Overall fitness'];
  final List<String> _activityLevels = ['Sedentary', 'Moderate', 'Active'];
  final List<String> _stressLevels = ['Low', 'Medium', 'High'];
  final List<String> _locationPreferences = ['Indoor', 'Outdoor', 'Both'];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  void _loadProfileData() {
    final data = widget.profileData;
    _fullNameController.text = data['full_name'] ?? '';
    _emailController.text = data['email'] ?? '';
    _ageController.text = data['age']?.toString() ?? '';
    _gender = data['gender'] ?? 'Prefer not to say';
    _heightController.text = data['height_cm']?.toString() ?? '';
    _weightController.text = data['weight_kg']?.toString() ?? '';
    _fitnessLevel = data['fitness_level'] ?? 'Beginner';
    _weeklyExerciseDaysController.text = data['weekly_exercise_days']?.toString() ?? '';
    _previousProgramExperience = data['previous_program_experience'] ?? false;
    _primaryFitnessGoal = data['primary_fitness_goal'] ?? 'Weight loss';
    _specificTargetsController.text = data['specific_targets'] ?? '';
    _motivationController.text = data['motivation'] ?? '';
    _workoutPreferences = data['workout_preferences'] ?? {};
    _indoorOutdoorPreference = data['indoor_outdoor_preference'] ?? 'Indoor';
    _workoutDaysPerWeekController.text = data['workout_days_per_week']?.toString() ?? '';
    _workoutMinutesPerSessionController.text = data['workout_minutes_per_session']?.toString() ?? '';
    _equipmentAccessController.text = data['equipment_access'] ?? '';
    _dietaryRestrictions = data['dietary_restrictions'] ?? {};
    _eatingHabitsController.text = data['eating_habits'] ?? '';
    _favoriteFoodsController.text = data['favorite_foods'] ?? '';
    _avoidedFoodsController.text = data['avoided_foods'] ?? '';
    _medicalConditions = data['medical_conditions'] ?? {};
    _medicationsController.text = data['medications'] ?? '';
    _fitnessConcernsController.text = data['fitness_concerns'] ?? '';
    _dailyActivityLevel = data['daily_activity_level'] ?? 'Moderate';
    _sleepHoursController.text = data['sleep_hours']?.toString() ?? '';
    _stressLevel = data['stress_level'] ?? 'Medium';
    _progressPhotoUrl = data['progress_photo_url'];
    _aiSuggestionsEnabled = data['ai_suggestions_enabled'] ?? true;
    _additionalNotesController.text = data['additional_notes'] ?? '';
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

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      if (kIsWeb) {
        // For web platform, read as bytes
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _selectedImageFile = null;
        });
      } else {
        // For mobile platforms
        setState(() {
          _selectedImageFile = File(image.path);
          _selectedImageBytes = null;
        });
      }
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImageFile == null && _selectedImageBytes == null) return _progressPhotoUrl;
    
    try {
      final userId = supabase.auth.currentUser!.id;
      final fileName = 'profile_$userId.jpg';
      
      // Try to upload to existing bucket
      try {
        if (kIsWeb && _selectedImageBytes != null) {
          // Upload bytes for web
          await supabase.storage
              .from('profile_images')
              .uploadBinary(fileName, _selectedImageBytes!, fileOptions: FileOptions(upsert: true));
        } else if (_selectedImageFile != null) {
          // Upload file for mobile
          await supabase.storage
              .from('profile_images')
              .upload(fileName, _selectedImageFile!, fileOptions: FileOptions(upsert: true));
        }
      } catch (e) {
        // If bucket doesn't exist, we'd need to create it via the Supabase dashboard
        // For now, show an error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Storage bucket not configured. Please contact admin.')),
        );
        return _progressPhotoUrl;
      }
      
      final imageUrl = supabase.storage.from('profile_images').getPublicUrl(fileName);
      return imageUrl;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: ${e.toString()}')),
      );
      return _progressPhotoUrl;
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

      // Upload image if selected
      final uploadedImageUrl = await _uploadImage();

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
        'progress_photo_url': uploadedImageUrl,
        'ai_suggestions_enabled': _aiSuggestionsEnabled,
        'additional_notes': _additionalNotesController.text,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Update existing profile
      await supabase
          .from('user_profiles')
          .update(data)
          .eq('user_id', userId);

      // Update user's full name in auth metadata
      await supabase.auth.updateUser(
        UserAttributes(
          data: {'full_name': _fullNameController.text},
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(context, true); // Return true to indicate successful update
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
        title: const Text('Edit Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveProfile,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                    ),
                  
                  // Profile photo
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                          backgroundImage: _getProfileImage(),
                          child: (_selectedImageFile == null && _selectedImageBytes == null && _progressPhotoUrl == null)
                              ? Icon(Icons.person, size: 60, color: Theme.of(context).colorScheme.onSecondaryContainer)
                              : null,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            radius: 18,
                            child: IconButton(
                              icon: const Icon(Icons.camera_alt, size: 18),
                              color: Theme.of(context).colorScheme.onPrimary,
                              onPressed: _pickImage,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Basic Information Section
                  _buildSectionHeader(context, 'Basic Information'),
                  
                  TextFormField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Please enter your name' : null,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _emailController,
                    enabled: false, // Email cannot be edited
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _ageController,
                    decoration: const InputDecoration(
                      labelText: 'Age',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.cake),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  DropdownButtonFormField<String>(
                    value: _gender,
                    decoration: const InputDecoration(
                      labelText: 'Gender',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.people),
                    ),
                    items: _genderOptions.map((String item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _gender = value;
                        });
                      }
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _heightController,
                          decoration: const InputDecoration(
                            labelText: 'Height (cm)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.height),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _weightController,
                          decoration: const InputDecoration(
                            labelText: 'Weight (kg)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.monitor_weight),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Fitness Background
                  _buildSectionHeader(context, 'Fitness Background'),
                  
                  DropdownButtonFormField<String>(
                    value: _fitnessLevel,
                    decoration: const InputDecoration(
                      labelText: 'Fitness Level',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.fitness_center),
                    ),
                    items: _fitnessLevels.map((String item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _fitnessLevel = value;
                        });
                      }
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _weeklyExerciseDaysController,
                    decoration: const InputDecoration(
                      labelText: 'Weekly Exercise Days',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  SwitchListTile(
                    title: const Text('Previous Program Experience'),
                    value: _previousProgramExperience,
                    onChanged: (value) {
                      setState(() {
                        _previousProgramExperience = value;
                      });
                    },
                    secondary: const Icon(Icons.history),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Goals
                  _buildSectionHeader(context, 'Goals'),
                  
                  DropdownButtonFormField<String>(
                    value: _primaryFitnessGoal,
                    decoration: const InputDecoration(
                      labelText: 'Primary Fitness Goal',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.flag),
                    ),
                    items: _fitnessGoals.map((String item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _primaryFitnessGoal = value;
                        });
                      }
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _specificTargetsController,
                    decoration: const InputDecoration(
                      labelText: 'Specific Target Areas',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.track_changes),
                    ),
                    maxLines: 2,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _motivationController,
                    decoration: const InputDecoration(
                      labelText: 'Motivation',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.emoji_emotions),
                    ),
                    maxLines: 2,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Workout Preferences
                  _buildSectionHeader(context, 'Workout Preferences'),
                  
                  DropdownButtonFormField<String>(
                    value: _indoorOutdoorPreference,
                    decoration: const InputDecoration(
                      labelText: 'Indoor/Outdoor Preference',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.home_work),
                    ),
                    items: _locationPreferences.map((String item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _indoorOutdoorPreference = value;
                        });
                      }
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _workoutDaysPerWeekController,
                          decoration: const InputDecoration(
                            labelText: 'Workout Days Per Week',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.view_week),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _workoutMinutesPerSessionController,
                          decoration: const InputDecoration(
                            labelText: 'Minutes Per Session',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.timer),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _equipmentAccessController,
                    decoration: const InputDecoration(
                      labelText: 'Equipment Access',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.fitness_center),
                    ),
                    maxLines: 2,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Nutrition
                  _buildSectionHeader(context, 'Nutrition'),
                  
                  TextFormField(
                    controller: _eatingHabitsController,
                    decoration: const InputDecoration(
                      labelText: 'Eating Habits',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.restaurant),
                    ),
                    maxLines: 2,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _favoriteFoodsController,
                    decoration: const InputDecoration(
                      labelText: 'Favorite Foods',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.thumb_up),
                    ),
                    maxLines: 2,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _avoidedFoodsController,
                    decoration: const InputDecoration(
                      labelText: 'Avoided Foods',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.thumb_down),
                    ),
                    maxLines: 2,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Health Considerations
                  _buildSectionHeader(context, 'Health Considerations'),
                  
                  TextFormField(
                    controller: _medicationsController,
                    decoration: const InputDecoration(
                      labelText: 'Medications',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.medication),
                    ),
                    maxLines: 2,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _fitnessConcernsController,
                    decoration: const InputDecoration(
                      labelText: 'Fitness Concerns',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.warning),
                    ),
                    maxLines: 2,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  DropdownButtonFormField<String>(
                    value: _dailyActivityLevel,
                    decoration: const InputDecoration(
                      labelText: 'Daily Activity Level',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.directions_walk),
                    ),
                    items: _activityLevels.map((String item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _dailyActivityLevel = value;
                        });
                      }
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _sleepHoursController,
                    decoration: const InputDecoration(
                      labelText: 'Sleep Hours',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.nightlight),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  DropdownButtonFormField<String>(
                    value: _stressLevel,
                    decoration: const InputDecoration(
                      labelText: 'Stress Level',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.psychology),
                    ),
                    items: _stressLevels.map((String item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _stressLevel = value;
                        });
                      }
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Additional Information
                  _buildSectionHeader(context, 'Additional Information'),
                  
                  SwitchListTile(
                    title: const Text('AI Suggestions Enabled'),
                    value: _aiSuggestionsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _aiSuggestionsEnabled = value;
                      });
                    },
                    secondary: const Icon(Icons.auto_awesome),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _additionalNotesController,
                    decoration: const InputDecoration(
                      labelText: 'Additional Notes',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.note),
                    ),
                    maxLines: 3,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    child: _isSaving 
                        ? const CircularProgressIndicator()
                        : const Text('Save Profile'),
                  ),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
  
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const Divider(),
        ],
      ),
    );
  }
  
  ImageProvider? _getProfileImage() {
    if (_selectedImageBytes != null) {
      return MemoryImage(_selectedImageBytes!);
    } else if (_selectedImageFile != null) {
      return FileImage(_selectedImageFile!);
    } else if (_progressPhotoUrl != null) {
      return NetworkImage(_progressPhotoUrl!);
    }
    return null;
  }
} 