import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../theme/app_theme.dart';
import '../main.dart';
import '../models/user_profile.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  final _formKey = GlobalKey<FormState>();
  UserProfile? _userProfile;
  File? _selectedImageFile;
  Uint8List? _selectedImageBytes;
  String? _progressPhotoUrl;
  
  // Form controllers
  final _fullNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _specificTargetsController = TextEditingController();
  final _motivationController = TextEditingController();
  final _workoutMinutesController = TextEditingController();
  final _weeklyExerciseDaysController = TextEditingController();
  final _eatingHabitsController = TextEditingController();
  final _favoriteFoodsController = TextEditingController(); 
  final _avoidedFoodsController = TextEditingController();
  final _medicationsController = TextEditingController();
  final _fitnessConcernsController = TextEditingController();
  final _sleepHoursController = TextEditingController();
  final _additionalNotesController = TextEditingController();
  
  // Selected dropdown values
  String? _selectedGender;
  String? _selectedFitnessLevel;
  String? _selectedFitnessGoal;
  String? _selectedWorkoutDays;
  String? _selectedEquipmentAccess;
  String? _selectedIndoorOutdoor;
  String? _selectedActivityLevel;
  String? _selectedStressLevel;
  bool _previousProgramExperience = false;
  bool _aiSuggestionsEnabled = true;
  
  // Options for dropdowns
  final List<String> _genderOptions = ['Male', 'Female', 'Other', 'Prefer not to say'];
  final List<String> _fitnessLevelOptions = ['Beginner', 'Intermediate', 'Advanced'];
  final List<String> _fitnessGoalOptions = ['Weight loss', 'Muscle gain', 'Strength', 'Endurance', 'General fitness', 'Flexibility'];
  final List<String> _workoutDaysOptions = ['1', '2', '3', '4', '5', '6', '7'];
  final List<String> _equipmentAccessOptions = [
    'None', 
    'Limited', 
    'Full gym',
    'Home equipment',
    'Bodyweight only',
    'Resistance bands',
    'Basic weights',
    'Gym membership',
    'Planet Fitness',
    'Complete gym access'
  ];
  final List<String> _indoorOutdoorOptions = ['Indoor', 'Outdoor', 'Both'];
  final List<String> _activityLevelOptions = ['Sedentary', 'Light', 'Moderate', 'Active', 'Very Active'];
  final List<String> _stressLevelOptions = ['Low', 'Medium', 'High'];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _specificTargetsController.dispose();
    _motivationController.dispose();
    _workoutMinutesController.dispose();
    _weeklyExerciseDaysController.dispose();
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

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final userId = supabase.auth.currentUser!.id;
      
      final response = await supabase
          .from('user_profiles')
          .select()
          .eq('user_id', userId)
          .single();
      
      if (response != null) {
        setState(() {
          _userProfile = UserProfile.fromJson(response);
          _progressPhotoUrl = _userProfile?.progressPhotoUrl;
          
          // Set form values from profile
          _fullNameController.text = _userProfile?.fullName ?? '';
          _ageController.text = _userProfile?.age?.toString() ?? '';
          _heightController.text = _userProfile?.heightCm?.toString() ?? '';
          _weightController.text = _userProfile?.weightKg?.toString() ?? '';
          _specificTargetsController.text = _userProfile?.specificTargets ?? '';
          _motivationController.text = _userProfile?.motivation ?? '';
          _workoutMinutesController.text = _userProfile?.workoutMinutesPerSession?.toString() ?? '';
          _weeklyExerciseDaysController.text = _userProfile?.weeklyExerciseDays?.toString() ?? '';
          _eatingHabitsController.text = _userProfile?.eatingHabits ?? '';
          _favoriteFoodsController.text = _userProfile?.favoriteFoods ?? '';
          _avoidedFoodsController.text = _userProfile?.avoidedFoods ?? '';
          _medicationsController.text = _userProfile?.medications ?? '';
          _fitnessConcernsController.text = _userProfile?.fitnessConcerns ?? '';
          _sleepHoursController.text = _userProfile?.sleepHours?.toString() ?? '';
          _additionalNotesController.text = _userProfile?.additionalNotes ?? '';
          
          // Set dropdown values
          _selectedGender = _ensureValidOption(_userProfile?.gender, _genderOptions);
          _selectedFitnessLevel = _ensureValidOption(_userProfile?.fitnessLevel, _fitnessLevelOptions);
          _selectedFitnessGoal = _ensureValidOption(_userProfile?.primaryFitnessGoal, _fitnessGoalOptions);
          _selectedWorkoutDays = _ensureValidOption(_userProfile?.workoutDaysPerWeek?.toString(), _workoutDaysOptions);
          _selectedEquipmentAccess = _ensureValidOption(_userProfile?.equipmentAccess, _equipmentAccessOptions);
          _selectedIndoorOutdoor = _ensureValidOption(_userProfile?.indoorOutdoorPreference, _indoorOutdoorOptions);
          _selectedActivityLevel = _ensureValidOption(_userProfile?.dailyActivityLevel, _activityLevelOptions);
          _selectedStressLevel = _ensureValidOption(_userProfile?.stressLevel, _stressLevelOptions);
          
          // Set boolean values
          _previousProgramExperience = _userProfile?.previousProgramExperience ?? false;
          _aiSuggestionsEnabled = _userProfile?.aiSuggestionsEnabled ?? true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Helper method to ensure dropdown values are valid options
  String? _ensureValidOption(String? value, List<String> options) {
    if (value == null) return null;
    return options.contains(value) ? value : null;
  }

  Future<String?> _uploadImage() async {
    if (_selectedImageFile == null && _selectedImageBytes == null) return _progressPhotoUrl;
    
    try {
      final userId = supabase.auth.currentUser!.id;
      final fileName = 'profile_$userId.jpg';
      
      if (kIsWeb && _selectedImageBytes != null) {
        // Upload bytes for web
        await supabase.storage
            .from('profile_images')
            .uploadBinary(fileName, _selectedImageBytes!);
      } else if (_selectedImageFile != null) {
        // Upload file for mobile
        await supabase.storage
            .from('profile_images')
            .upload(fileName, _selectedImageFile!);
      }
      
      return supabase.storage.from('profile_images').getPublicUrl(fileName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return _progressPhotoUrl;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      final userId = supabase.auth.currentUser!.id;
      
      // Upload image if selected
      final uploadedImageUrl = await _uploadImage();
      
      // Prepare data to update
      final data = {
        'full_name': _fullNameController.text.trim(),
        'age': _ageController.text.isEmpty ? null : int.parse(_ageController.text),
        'gender': _selectedGender,
        'height_cm': _heightController.text.isEmpty ? null : double.parse(_heightController.text),
        'weight_kg': _weightController.text.isEmpty ? null : double.parse(_weightController.text),
        'fitness_level': _selectedFitnessLevel,
        'primary_fitness_goal': _selectedFitnessGoal,
        'specific_targets': _specificTargetsController.text,
        'motivation': _motivationController.text,
        'workout_days_per_week': _selectedWorkoutDays == null ? null : int.parse(_selectedWorkoutDays!),
        'workout_minutes_per_session': _workoutMinutesController.text.isEmpty ? null : int.parse(_workoutMinutesController.text),
        'equipment_access': _selectedEquipmentAccess,
        'weekly_exercise_days': _weeklyExerciseDaysController.text.isEmpty ? null : int.parse(_weeklyExerciseDaysController.text),
        'previous_program_experience': _previousProgramExperience,
        'indoor_outdoor_preference': _selectedIndoorOutdoor,
        'eating_habits': _eatingHabitsController.text,
        'favorite_foods': _favoriteFoodsController.text,
        'avoided_foods': _avoidedFoodsController.text,
        'medications': _medicationsController.text,
        'fitness_concerns': _fitnessConcernsController.text,
        'daily_activity_level': _selectedActivityLevel,
        'sleep_hours': _sleepHoursController.text.isEmpty ? null : int.parse(_sleepHoursController.text),
        'stress_level': _selectedStressLevel,
        'progress_photo_url': uploadedImageUrl,
        'ai_suggestions_enabled': _aiSuggestionsEnabled,
        'additional_notes': _additionalNotesController.text,
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      await supabase
          .from('user_profiles')
          .update(data)
          .eq('user_id', userId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return with success result
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _saveProfile,
            icon: _isSaving 
                ? SizedBox(
                    width: 16, 
                    height: 16, 
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.primary,
                    ),
                  )
                : const Icon(Icons.save),
            label: const Text('Save'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Photo
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: colorScheme.primaryContainer,
                            backgroundImage: _getProfileImage(),
                            child: (_selectedImageFile == null && 
                                    _selectedImageBytes == null && 
                                    _progressPhotoUrl == null)
                                ? Text(
                                    _getInitials(),
                                    style: TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onPrimaryContainer,
                                    ),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: colorScheme.primary,
                              child: IconButton(
                                icon: const Icon(Icons.camera_alt),
                                color: colorScheme.onPrimary,
                                iconSize: 20,
                                onPressed: _pickImage,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Basic Information
                    _buildSectionHeader('Basic Information'),
                    _buildTextField(
                      controller: _fullNameController,
                      label: 'Full Name',
                      icon: Icons.person,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _ageController,
                      label: 'Age',
                      icon: Icons.cake,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final age = int.tryParse(value);
                          if (age == null || age < 1 || age > 120) {
                            return 'Please enter a valid age';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildDropdown(
                      value: _selectedGender,
                      label: 'Gender',
                      icon: Icons.person_outline,
                      items: _genderOptions,
                      onChanged: (String? value) {
                        setState(() {
                          _selectedGender = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _heightController,
                            label: 'Height (cm)',
                            icon: Icons.height,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                            ],
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                final height = double.tryParse(value);
                                if (height == null || height < 50 || height > 250) {
                                  return 'Valid height required';
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            controller: _weightController,
                            label: 'Weight (kg)',
                            icon: Icons.monitor_weight,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                            ],
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                final weight = double.tryParse(value);
                                if (weight == null || weight < 20 || weight > 300) {
                                  return 'Valid weight required';
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    // Fitness Goals
                    _buildSectionHeader('Fitness Goals'),
                    _buildDropdown(
                      value: _selectedFitnessLevel,
                      label: 'Fitness Level',
                      icon: Icons.fitness_center,
                      items: _fitnessLevelOptions,
                      onChanged: (String? value) {
                        setState(() {
                          _selectedFitnessLevel = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildDropdown(
                      value: _selectedFitnessGoal,
                      label: 'Primary Fitness Goal',
                      icon: Icons.flag,
                      items: _fitnessGoalOptions,
                      onChanged: (String? value) {
                        setState(() {
                          _selectedFitnessGoal = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _specificTargetsController,
                      label: 'Specific Targets',
                      icon: Icons.track_changes,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _motivationController,
                      label: 'Motivation',
                      icon: Icons.emoji_emotions,
                      maxLines: 2,
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
                    // Workout Preferences
                    _buildSectionHeader('Workout Preferences'),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _weeklyExerciseDaysController,
                            label: 'Exercise Days',
                            icon: Icons.calendar_today,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDropdown(
                            value: _selectedWorkoutDays,
                            label: 'Workout Days',
                            icon: Icons.fitness_center,
                            items: _workoutDaysOptions,
                            onChanged: (String? value) {
                              setState(() {
                                _selectedWorkoutDays = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _workoutMinutesController,
                      label: 'Minutes Per Session',
                      icon: Icons.timer,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 16),
                    _buildDropdown(
                      value: _selectedIndoorOutdoor,
                      label: 'Indoor/Outdoor Preference',
                      icon: Icons.home_work,
                      items: _indoorOutdoorOptions,
                      onChanged: (String? value) {
                        setState(() {
                          _selectedIndoorOutdoor = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildDropdown(
                      value: _selectedEquipmentAccess,
                      label: 'Equipment Access',
                      icon: Icons.sports_gymnastics,
                      items: _equipmentAccessOptions,
                      onChanged: (String? value) {
                        setState(() {
                          _selectedEquipmentAccess = value;
                        });
                      },
                      isSearchable: true,
                    ),
                    
                    const SizedBox(height: 24),
                    // Nutrition
                    _buildSectionHeader('Nutrition'),
                    _buildTextField(
                      controller: _eatingHabitsController,
                      label: 'Eating Habits',
                      icon: Icons.restaurant,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _favoriteFoodsController,
                      label: 'Favorite Foods',
                      icon: Icons.thumb_up,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _avoidedFoodsController,
                      label: 'Avoided Foods',
                      icon: Icons.thumb_down,
                      maxLines: 2,
                    ),
                    
                    const SizedBox(height: 24),
                    // Health Information
                    _buildSectionHeader('Health Information'),
                    _buildTextField(
                      controller: _medicationsController,
                      label: 'Medications',
                      icon: Icons.medication,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _fitnessConcernsController,
                      label: 'Fitness Concerns',
                      icon: Icons.warning,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    _buildDropdown(
                      value: _selectedActivityLevel,
                      label: 'Daily Activity Level',
                      icon: Icons.directions_walk,
                      items: _activityLevelOptions,
                      onChanged: (String? value) {
                        setState(() {
                          _selectedActivityLevel = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _sleepHoursController,
                      label: 'Sleep Hours',
                      icon: Icons.nightlight,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 16),
                    _buildDropdown(
                      value: _selectedStressLevel,
                      label: 'Stress Level',
                      icon: Icons.psychology,
                      items: _stressLevelOptions,
                      onChanged: (String? value) {
                        setState(() {
                          _selectedStressLevel = value;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    // Additional Information
                    _buildSectionHeader('Additional Information'),
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
                    _buildTextField(
                      controller: _additionalNotesController,
                      label: 'Additional Notes',
                      icon: Icons.note,
                      maxLines: 3,
                    ),
                    
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Save Profile', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      maxLines: maxLines,
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String label,
    required IconData icon,
    required List<String> items,
    required void Function(String?) onChanged,
    bool isSearchable = false,
  }) {
    if (isSearchable && items.length > 8) {
      return Autocomplete<String>(
        optionsBuilder: (TextEditingValue textEditingValue) {
          if (textEditingValue.text.isEmpty) {
            return items;
          }
          return items.where((String option) {
            return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
          });
        },
        initialValue: TextEditingValue(text: value ?? ''),
        fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
          return TextFormField(
            controller: textEditingController,
            focusNode: focusNode,
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: Icon(icon),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onFieldSubmitted: (String text) {
              onFieldSubmitted();
            },
          );
        },
        onSelected: onChanged,
      );
    }
    
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  String _getInitials() {
    final name = _fullNameController.text;
    if (name.isEmpty) {
      final email = supabase.auth.currentUser?.email ?? '';
      return email.isNotEmpty ? email[0].toUpperCase() : '?';
    }
    
    final nameParts = name.split(' ');
    if (nameParts.length > 1) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
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