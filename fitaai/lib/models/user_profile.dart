class UserProfile {
  final String? id;
  final String? userId;
  final String? email;
  final String? fullName;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? age;
  final String? gender;
  final dynamic heightCm;
  final dynamic weightKg;
  final String? fitnessLevel;
  final int? weeklyExerciseDays;
  final bool? previousProgramExperience;
  final String? primaryFitnessGoal;
  final String? specificTargets;
  final String? motivation;
  final Map<String, dynamic>? workoutPreferences;
  final String? indoorOutdoorPreference;
  final int? workoutDaysPerWeek;
  final int? workoutMinutesPerSession;
  final String? equipmentAccess;
  final Map<String, dynamic>? dietaryRestrictions;
  final String? eatingHabits;
  final String? favoriteFoods;
  final String? avoidedFoods;
  final Map<String, dynamic>? medicalConditions;
  final String? medications;
  final String? fitnessConcerns;
  final String? dailyActivityLevel;
  final int? sleepHours;
  final String? stressLevel;
  final String? progressPhotoUrl;
  final bool? aiSuggestionsEnabled;
  final String? additionalNotes;

  UserProfile({
    this.id,
    this.userId,
    this.email,
    this.fullName,
    this.createdAt,
    this.updatedAt,
    this.age,
    this.gender,
    this.heightCm,
    this.weightKg,
    this.fitnessLevel,
    this.weeklyExerciseDays,
    this.previousProgramExperience,
    this.primaryFitnessGoal,
    this.specificTargets,
    this.motivation,
    this.workoutPreferences,
    this.indoorOutdoorPreference,
    this.workoutDaysPerWeek,
    this.workoutMinutesPerSession,
    this.equipmentAccess,
    this.dietaryRestrictions,
    this.eatingHabits,
    this.favoriteFoods,
    this.avoidedFoods,
    this.medicalConditions,
    this.medications,
    this.fitnessConcerns,
    this.dailyActivityLevel,
    this.sleepHours,
    this.stressLevel,
    this.progressPhotoUrl,
    this.aiSuggestionsEnabled,
    this.additionalNotes,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      userId: json['user_id'],
      email: json['email'],
      fullName: json['full_name'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      age: json['age'],
      gender: json['gender'],
      heightCm: json['height_cm'],
      weightKg: json['weight_kg'],
      fitnessLevel: json['fitness_level'],
      weeklyExerciseDays: json['weekly_exercise_days'],
      previousProgramExperience: json['previous_program_experience'],
      primaryFitnessGoal: json['primary_fitness_goal'],
      specificTargets: json['specific_targets'],
      motivation: json['motivation'],
      workoutPreferences: json['workout_preferences'],
      indoorOutdoorPreference: json['indoor_outdoor_preference'],
      workoutDaysPerWeek: json['workout_days_per_week'],
      workoutMinutesPerSession: json['workout_minutes_per_session'],
      equipmentAccess: json['equipment_access'],
      dietaryRestrictions: json['dietary_restrictions'],
      eatingHabits: json['eating_habits'],
      favoriteFoods: json['favorite_foods'],
      avoidedFoods: json['avoided_foods'],
      medicalConditions: json['medical_conditions'],
      medications: json['medications'],
      fitnessConcerns: json['fitness_concerns'],
      dailyActivityLevel: json['daily_activity_level'],
      sleepHours: json['sleep_hours'],
      stressLevel: json['stress_level'],
      progressPhotoUrl: json['progress_photo_url'],
      aiSuggestionsEnabled: json['ai_suggestions_enabled'],
      additionalNotes: json['additional_notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'email': email,
      'full_name': fullName,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'age': age,
      'gender': gender,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'fitness_level': fitnessLevel,
      'weekly_exercise_days': weeklyExerciseDays,
      'previous_program_experience': previousProgramExperience,
      'primary_fitness_goal': primaryFitnessGoal,
      'specific_targets': specificTargets,
      'motivation': motivation,
      'workout_preferences': workoutPreferences,
      'indoor_outdoor_preference': indoorOutdoorPreference,
      'workout_days_per_week': workoutDaysPerWeek,
      'workout_minutes_per_session': workoutMinutesPerSession,
      'equipment_access': equipmentAccess,
      'dietary_restrictions': dietaryRestrictions,
      'eating_habits': eatingHabits,
      'favorite_foods': favoriteFoods,
      'avoided_foods': avoidedFoods,
      'medical_conditions': medicalConditions,
      'medications': medications,
      'fitness_concerns': fitnessConcerns,
      'daily_activity_level': dailyActivityLevel,
      'sleep_hours': sleepHours,
      'stress_level': stressLevel,
      'progress_photo_url': progressPhotoUrl,
      'ai_suggestions_enabled': aiSuggestionsEnabled,
      'additional_notes': additionalNotes,
    };
  }
} 