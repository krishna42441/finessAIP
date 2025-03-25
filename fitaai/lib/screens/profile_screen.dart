import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../main.dart';
import 'edit_profile_screen.dart';
import '../utils/onboarding_helper.dart';
import '../services/gemini_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  bool _isProfileComplete = false;
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
  double _goalProgress = 0.0;
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
          
          // Mock goal progress - in real app, calculate based on actual progress
          _goalProgress = 0.65;
          
          // Check if profile is complete
          checkProfileCompletion();
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

  void checkProfileCompletion() {
    // Check if essential fields are filled
    final bool hasName = _fullNameController.text.isNotEmpty;
    final bool hasAge = _ageController.text.isNotEmpty;
    final bool hasGender = _gender.isNotEmpty;
    final bool hasHeight = _heightController.text.isNotEmpty;
    final bool hasWeight = _weightController.text.isNotEmpty;
    final bool hasGoal = _primaryFitnessGoal.isNotEmpty;

    setState(() {
      _isProfileComplete = hasName && hasAge && hasGender && hasHeight && hasWeight && hasGoal;
    });
    
    // If profile is incomplete, show a banner
    if (!_isProfileComplete && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showMaterialBanner(
          MaterialBanner(
            padding: const EdgeInsets.all(16),
            content: const Text(
              'Please complete your profile to get personalized fitness and nutrition plans',
            ),
            leading: const Icon(Icons.info_outline),
            backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
            actions: [
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
                  _navigateToEditProfile();
                },
                child: const Text('COMPLETE NOW'),
              ),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
                },
                child: const Text('DISMISS'),
              ),
            ],
          ),
        );
      });
    }
  }

  void _navigateToEditProfile() async {
    Map<String, dynamic> profileData = {
        'full_name': _fullNameController.text,
      'email': _emailController.text,
      'age': _ageController.text.isNotEmpty ? int.tryParse(_ageController.text) : null,
        'gender': _gender,
      'height_cm': _heightController.text.isNotEmpty ? double.tryParse(_heightController.text) : null,
      'weight_kg': _weightController.text.isNotEmpty ? double.tryParse(_weightController.text) : null,
        'fitness_level': _fitnessLevel,
      'weekly_exercise_days': _weeklyExerciseDaysController.text.isNotEmpty ? int.tryParse(_weeklyExerciseDaysController.text) : null,
        'previous_program_experience': _previousProgramExperience,
        'primary_fitness_goal': _primaryFitnessGoal,
        'specific_targets': _specificTargetsController.text,
        'motivation': _motivationController.text,
        'workout_preferences': _workoutPreferences,
        'indoor_outdoor_preference': _indoorOutdoorPreference,
      'workout_days_per_week': _workoutDaysPerWeekController.text.isNotEmpty ? int.tryParse(_workoutDaysPerWeekController.text) : null,
      'workout_minutes_per_session': _workoutMinutesPerSessionController.text.isNotEmpty ? int.tryParse(_workoutMinutesPerSessionController.text) : null,
        'equipment_access': _equipmentAccessController.text,
        'dietary_restrictions': _dietaryRestrictions,
        'eating_habits': _eatingHabitsController.text,
        'favorite_foods': _favoriteFoodsController.text,
        'avoided_foods': _avoidedFoodsController.text,
        'medical_conditions': _medicalConditions,
        'medications': _medicationsController.text,
        'fitness_concerns': _fitnessConcernsController.text,
        'daily_activity_level': _dailyActivityLevel,
      'sleep_hours': _sleepHoursController.text.isNotEmpty ? int.tryParse(_sleepHoursController.text) : null,
        'stress_level': _stressLevel,
        'progress_photo_url': _progressPhotoUrl,
        'ai_suggestions_enabled': _aiSuggestionsEnabled,
        'additional_notes': _additionalNotesController.text,
    };
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(profileData: profileData),
      ),
    );
    
    // If profile was updated, reload the data
    if (result == true) {
      _loadUserProfile();
    }
  }

  void _showFullScreenImage() {
    if (_progressPhotoUrl == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          backgroundColor: Colors.black,
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                _progressPhotoUrl!,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Profile'),
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              _navigateToEditProfile();
            },
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Profile',
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadUserProfile,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 16),
                  _buildProfileSections(),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: _signOut,
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign Out'),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildProfileHeader() {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile picture
            CircleAvatar(
              radius: 48,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.person,
                size: 48,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 16),
            // Name
            Text(
              _fullNameController.text.isNotEmpty 
                  ? _fullNameController.text 
                  : 'Add your name',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            // Email
            Text(
              _emailController.text,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // Profile completion
            _buildProfileCompletionIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCompletionIndicator() {
    final completionPercentage = _isProfileComplete ? 100 : (checkCompletionPercentage() * 100).round();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Profile Completion',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              '$completionPercentage%',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: completionPercentage / 100,
          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
          color: Theme.of(context).colorScheme.primary,
        ),
        if (!_isProfileComplete) ...[
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _navigateToEditProfile,
            icon: const Icon(Icons.edit),
            label: const Text('Complete Profile'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 40),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProfileSections() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSection('Personal Information', _buildPersonalInfoItems()),
        const SizedBox(height: 16),
        _buildSection('Fitness Goals', _buildFitnessGoalsItems()),
        const SizedBox(height: 16),
        _buildSection('Workout Preferences', _buildWorkoutPreferencesItems()),
        const SizedBox(height: 16),
        _buildSection('Health Information', _buildHealthInfoItems()),
        const SizedBox(height: 16),
        _buildSection('App Settings', _buildSettingsItems()),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> items) {
    return Card(
      elevation: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const Divider(),
          ...items,
        ],
      ),
    );
  }

  double checkCompletionPercentage() {
    int totalFields = 7;
    int completedFields = 0;
    
    if (_fullNameController.text.isNotEmpty) completedFields++;
    if (_ageController.text.isNotEmpty) completedFields++;
    if (_gender.isNotEmpty) completedFields++;
    if (_heightController.text.isNotEmpty) completedFields++;
    if (_weightController.text.isNotEmpty) completedFields++;
    if (_primaryFitnessGoal.isNotEmpty) completedFields++;
    if (_fitnessLevel.isNotEmpty) completedFields++;
    
    return completedFields / totalFields;
  }

  List<Widget> _buildPersonalInfoItems() {
    return [
      _buildInfoItem('Age', _ageController.text),
      _buildInfoItem('Height', '${_heightController.text} cm'),
      _buildInfoItem('Weight', '${_weightController.text} kg'),
    ];
  }

  List<Widget> _buildFitnessGoalsItems() {
    return [
      _buildInfoItem('Fitness Level', _fitnessLevel),
      _buildInfoItem('Workout Days', _workoutDaysPerWeekController.text.isEmpty ? '---' : _workoutDaysPerWeekController.text),
      _buildInfoItem('Goal', _primaryFitnessGoal),
      _buildInfoItem('Target Areas', _specificTargetsController.text.isEmpty ? '---' : _specificTargetsController.text),
      _buildInfoItem('Equipment', _equipmentAccessController.text.isEmpty ? '---' : _equipmentAccessController.text),
    ];
  }

  List<Widget> _buildWorkoutPreferencesItems() {
    return [
      _buildInfoItem('Workout Days per Week', _workoutDaysPerWeekController.text.isEmpty ? '---' : _workoutDaysPerWeekController.text),
      _buildInfoItem('Workout Minutes per Session', _workoutMinutesPerSessionController.text.isEmpty ? '---' : _workoutMinutesPerSessionController.text),
      _buildInfoItem('Indoor/Outdoor Preference', _indoorOutdoorPreference),
    ];
  }

  List<Widget> _buildHealthInfoItems() {
    return [
      _buildInfoItem('Activity Level', _dailyActivityLevel),
      _buildInfoItem('Sleep Hours', _sleepHoursController.text.isEmpty ? '---' : '${_sleepHoursController.text} hours per night'),
      _buildInfoItem('Stress Level', _stressLevel),
    ];
  }

  List<Widget> _buildSettingsItems() {
    return [
      _buildInfoItem('Eating Habits', _eatingHabitsController.text.isEmpty ? '---' : _eatingHabitsController.text),
      _buildInfoItem('Favorite Foods', _favoriteFoodsController.text.isEmpty ? '---' : _favoriteFoodsController.text),
      _buildInfoItem('Avoided Foods', _avoidedFoodsController.text.isEmpty ? '---' : _avoidedFoodsController.text),
      _buildInfoItem('Medications', _medicationsController.text.isEmpty ? '---' : _medicationsController.text),
      _buildInfoItem('Fitness Concerns', _fitnessConcernsController.text.isEmpty ? '---' : _fitnessConcernsController.text),
    ];
  }

  Widget _buildInfoItem(String label, String value) {
    return ListTile(
      leading: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      title: Text(
        value.isEmpty ? '---' : value,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> _signOut() async {
    try {
      await supabase.auth.signOut();
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: ${e.toString()}')),
      );
    }
  }
} 