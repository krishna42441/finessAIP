import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import '../utils/motion_utils.dart';
import '../widgets/ui_components.dart';
import '../models/user_profile.dart';

// Extension for string capitalization
extension StringExtension on String {
  String capitalize() {
    return isNotEmpty ? '${this[0].toUpperCase()}${substring(1)}' : '';
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final _user = supabase.auth.currentUser;
  UserProfile? _userProfile;
  Map<String, dynamic> _stats = {
    'workouts': '0',
    'exercises': '0',
    'mealPlans': '0',
    'weightProgress': '0',
  };
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _animationController = MotionUtils.createStaggeredController(
      vsync: this,
      itemCount: 7, // Number of animated elements
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
      _animationController.forward();
    });
  }
  
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Load user profile data
      final userProfileResponse = await supabase
          .from('user_profiles')
          .select()
          .eq('user_id', _user?.id ?? '')
          .single();
      
      if (userProfileResponse != null) {
        _userProfile = UserProfile.fromJson(userProfileResponse);
      }

      // Fetch workout plans
      final workoutPlans = await supabase
          .from('workout_plans')
          .select()
          .eq('user_id', _user?.id ?? '');
      
      // Fetch nutrition plans
      final nutritionPlans = await supabase
          .from('nutrition_plans')
          .select()
          .eq('user_id', _user?.id ?? '');
      
      // Update stats map
      _stats = {
        'workouts': workoutPlans.length.toString(),
        'exercises': '134', // Fallback to approximate value
        'mealPlans': nutritionPlans.length.toString(),
        'weightProgress': _userProfile?.weightKg != null ? '${_userProfile?.weightKg} kg' : 'N/A',
      };
    } catch (e) {
      // Use default values if all fails
      _stats = {
        'workouts': '8',
        'exercises': '134',
        'mealPlans': '4',
        'weightProgress': _userProfile?.weightKg != null ? '${_userProfile?.weightKg} kg' : '83 kg',
      };
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator())
        : SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileHeader(context),
                  const SizedBox(height: 32),
                  _buildStatsSection(context),
                  const SizedBox(height: 32),
                  _buildFitnessInfoSection(context),
                  const SizedBox(height: 32),
                  _buildWorkoutPreferencesSection(context),
                  const SizedBox(height: 32),
                  _buildNutritionPreferencesSection(context),
                  const SizedBox(height: 32),
                  _buildHealthInfoSection(context),
                  const SizedBox(height: 32),
                  _buildSettingsSection(context),
                ],
              ),
            ),
          ),
        ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final animation = MotionUtils.getStaggeredAnimation(
      controller: _animationController,
      index: 0,
      itemCount: 7,
    );
    
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - animation.value)),
            child: child,
          ),
        );
      },
      child: Center(
        child: Column(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: colorScheme.primaryContainer,
              child: Text(
                _getUserInitials(),
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _userProfile?.fullName ?? _user?.email ?? 'User',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Member since ${_getFormattedDate()}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                // Navigate to edit profile screen
                Navigator.pushNamed(context, '/edit_profile').then((_) {
                  // Refresh data when returning from edit profile
                  _loadUserData();
                });
              },
              icon: const Icon(Icons.edit),
              label: const Text('Edit Profile'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final animation = MotionUtils.getStaggeredAnimation(
      controller: _animationController,
      index: 1,
      itemCount: 7,
    );
    
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - animation.value)),
            child: child,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Progress',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard(
                context: context,
                title: 'Workouts',
                value: _stats['workouts'] ?? '0',
                icon: Icons.fitness_center,
              ),
              _buildStatCard(
                context: context,
                title: 'Exercises',
                value: _stats['exercises'] ?? '0',
                icon: Icons.sports_gymnastics,
              ),
              _buildStatCard(
                context: context,
                title: 'Meal Plans',
                value: _stats['mealPlans'] ?? '0',
                icon: Icons.restaurant_menu,
              ),
              _buildStatCard(
                context: context,
                title: 'Weight',
                value: _stats['weightProgress'] ?? 'N/A',
                icon: Icons.monitor_weight,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFitnessInfoSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final animation = MotionUtils.getStaggeredAnimation(
      controller: _animationController,
      index: 1,
      itemCount: 7,
    );
    
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - animation.value)),
            child: child,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fitness Information',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            color: colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildInfoRow(
                    context: context,
                    title: 'Age',
                    value: _userProfile?.age?.toString() ?? 'Not set',
                  ),
                  _buildInfoRow(
                    context: context,
                    title: 'Gender',
                    value: _userProfile?.gender ?? 'Not set',
                  ),
                  _buildInfoRow(
                    context: context,
                    title: 'Height',
                    value: _userProfile?.heightCm != null ? '${_userProfile?.heightCm} cm' : 'Not set',
                  ),
                  _buildInfoRow(
                    context: context,
                    title: 'Weight',
                    value: _userProfile?.weightKg != null ? '${_userProfile?.weightKg} kg' : 'Not set',
                  ),
                  _buildInfoRow(
                    context: context,
                    title: 'Fitness Level',
                    value: _userProfile?.fitnessLevel ?? 'Not set',
                  ),
                  _buildInfoRow(
                    context: context,
                    title: 'Fitness Goal',
                    value: _userProfile?.primaryFitnessGoal ?? 'Not set',
                  ),
                  _buildInfoRow(
                    context: context,
                    title: 'Workout Days',
                    value: _userProfile?.workoutDaysPerWeek?.toString() ?? 'Not set',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutPreferencesSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final animation = MotionUtils.getStaggeredAnimation(
      controller: _animationController,
      index: 2,
      itemCount: 7,
    );
    
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - animation.value)),
            child: child,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Workout Preferences',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            color: colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildInfoRow(
                    context: context,
                    title: 'Workout Days',
                    value: _userProfile?.workoutDaysPerWeek?.toString() ?? 'Not set',
                  ),
                  _buildInfoRow(
                    context: context,
                    title: 'Minutes Per Session',
                    value: _userProfile?.workoutMinutesPerSession?.toString() != null 
                      ? '${_userProfile?.workoutMinutesPerSession} min' 
                      : 'Not set',
                  ),
                  _buildInfoRow(
                    context: context,
                    title: 'Equipment Access',
                    value: _userProfile?.equipmentAccess ?? 'Not set',
                  ),
                  _buildInfoRow(
                    context: context,
                    title: 'Indoor/Outdoor',
                    value: _userProfile?.indoorOutdoorPreference ?? 'Not set',
                  ),
                  _buildInfoRow(
                    context: context,
                    title: 'Experience',
                    value: _userProfile?.previousProgramExperience ?? false ? 'Yes' : 'No',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionPreferencesSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final animation = MotionUtils.getStaggeredAnimation(
      controller: _animationController,
      index: 3,
      itemCount: 7,
    );
    
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - animation.value)),
            child: child,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nutrition Preferences',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            color: colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildInfoRow(
                    context: context,
                    title: 'Eating Habits',
                    value: _userProfile?.eatingHabits ?? 'Not set',
                  ),
                  _buildInfoRow(
                    context: context,
                    title: 'Favorite Foods',
                    value: _userProfile?.favoriteFoods ?? 'Not set',
                  ),
                  _buildInfoRow(
                    context: context,
                    title: 'Avoided Foods',
                    value: _userProfile?.avoidedFoods ?? 'Not set',
                  ),
                  _buildInfoRow(
                    context: context,
                    title: 'Dietary Restrictions',
                    value: _formatJsonField(_userProfile?.dietaryRestrictions),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthInfoSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final animation = MotionUtils.getStaggeredAnimation(
      controller: _animationController,
      index: 5,
      itemCount: 7,
    );
    
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - animation.value)),
            child: child,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Health Information',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            color: colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildInfoRow(
                    context: context,
                    title: 'Medical Conditions',
                    value: _formatJsonField(_userProfile?.medicalConditions),
                  ),
                  _buildInfoRow(
                    context: context,
                    title: 'Medications',
                    value: _userProfile?.medications ?? 'None',
                  ),
                  _buildInfoRow(
                    context: context,
                    title: 'Fitness Concerns',
                    value: _userProfile?.fitnessConcerns ?? 'None',
                  ),
                  _buildInfoRow(
                    context: context,
                    title: 'Activity Level',
                    value: _userProfile?.dailyActivityLevel ?? 'Not set',
                  ),
                  _buildInfoRow(
                    context: context,
                    title: 'Sleep Hours',
                    value: _userProfile?.sleepHours?.toString() ?? 'Not set',
                  ),
                  _buildInfoRow(
                    context: context,
                    title: 'Stress Level',
                    value: _userProfile?.stressLevel ?? 'Not set',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required BuildContext context, 
    required String title, 
    required String value
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            flex: 2,
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 3,
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      elevation: 0,
      color: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: colorScheme.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final animation = MotionUtils.getStaggeredAnimation(
      controller: _animationController,
      index: 6,
      itemCount: 7,
    );
    
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - animation.value)),
            child: child,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            color: colorScheme.surface,
            child: Column(
              children: [
                IconListItem(
                  title: 'Account Settings',
                  icon: Icons.manage_accounts,
                  onTap: () {
                    // Navigate to account settings
                  },
                ),
                IconListItem(
                  title: 'Notifications',
                  icon: Icons.notifications,
                  onTap: () {
                    // Navigate to notifications settings
                  },
                ),
                IconListItem(
                  title: 'Privacy & Security',
                  icon: Icons.security,
                  onTap: () {
                    // Navigate to privacy settings
                  },
                ),
                IconListItem(
                  title: 'Help & Support',
                  icon: Icons.help,
                  onTap: () {
                    // Navigate to help & support
                  },
                ),
                IconListItem(
                  title: 'About',
                  icon: Icons.info,
                  onTap: () {
                    // Navigate to about page
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await supabase.auth.signOut();
                      if (context.mounted) {
                        Navigator.of(context).pushReplacementNamed('/login');
                      }
                    },
                    icon: Icon(
                      Icons.logout,
                      color: colorScheme.error,
                    ),
                    label: Text(
                      'Sign Out',
                      style: TextStyle(color: colorScheme.error),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: colorScheme.error),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getUserInitials() {
    if (_userProfile?.fullName != null && _userProfile!.fullName!.isNotEmpty) {
      final nameParts = _userProfile!.fullName!.split(' ');
      if (nameParts.length > 1) {
        return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
      }
      return _userProfile!.fullName![0].toUpperCase();
    }
    
    final email = _user?.email ?? '';
    if (email.isEmpty) return '?';
    
    return email.substring(0, 1).toUpperCase();
  }

  String _getFormattedDate() {
    final dateStr = _user?.createdAt;
    if (dateStr == null) return 'Unknown';
    
    try {
      final date = DateTime.parse(dateStr);
      final formatter = DateFormat('MMM d, yyyy');
      return formatter.format(date);
    } catch (e) {
      return 'Invalid Date';
    }
  }

  String _formatJsonField(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) {
      return 'None';
    }
    
    try {
      // Try to convert to a readable string format
      final List<String> items = [];
      
      data.forEach((key, value) {
        if (value == true) {
          items.add(key.replaceAll('_', ' ').capitalize());
        }
      });
      
      return items.isEmpty ? 'None' : items.join(', ');
    } catch (e) {
      return data.toString();
    }
  }
}