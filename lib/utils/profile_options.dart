// lib/utils/profile_options.dart - Constants for profile dropdown options
import 'package:flutter/material.dart';

class ProfileOptions {
  // Gender options
  static const List<String> genders = [
    'Male',
    'Female',
    'Non-binary',
    'Other',
    'Prefer not to say'
  ];

  // Height options (Imperial)
  static const List<String> heights = [
    '4\'8"', '4\'9"', '4\'10"', '4\'11"',
    '5\'0"', '5\'1"', '5\'2"', '5\'3"', '5\'4"', '5\'5"',
    '5\'6"', '5\'7"', '5\'8"', '5\'9"', '5\'10"', '5\'11"',
    '6\'0"', '6\'1"', '6\'2"', '6\'3"', '6\'4"', '6\'5"',
    '6\'6"', '6\'7"', '6\'8"', '6\'9"', '6\'10"', '6\'11"', '7\'0"'
  ];

  // Relationship goals
  static const List<String> relationshipGoals = [
    'Long-term relationship',
    'Something casual',
    'Not sure yet',
    'Prefer not to say'
  ];

  // Zodiac signs
  static const List<String> zodiacSigns = [
    'Aries', 'Taurus', 'Gemini', 'Cancer',
    'Leo', 'Virgo', 'Libra', 'Scorpio',
    'Sagittarius', 'Capricorn', 'Aquarius', 'Pisces'
  ];

  // Education levels
  static const List<String> educationLevels = [
    'High school',
    'Some college',
    'Bachelor\'s degree',
    'Master\'s degree',
    'PhD',
    'Trade school',
    'Other'
  ];

  // Family plans
  static const List<String> familyPlans = [
    'Want children',
    'Don\'t want children',
    'Have children',
    'Open to children',
    'Not sure'
  ];

  // Personality types (MBTI)
  static const List<String> personalityTypes = [
    'INTJ', 'INTP', 'ENTJ', 'ENTP',
    'INFJ', 'INFP', 'ENFJ', 'ENFP',
    'ISTJ', 'ISFJ', 'ESTJ', 'ESFJ',
    'ISTP', 'ISFP', 'ESTP', 'ESFP',
    'Not sure'
  ];

  // Communication styles
  static const List<String> communicationStyles = [
    'Direct',
    'Thoughtful',
    'Playful',
    'Serious',
    'Casual',
    'Formal'
  ];

  // Love languages
  static const List<String> loveLanguages = [
    'Words of affirmation',
    'Physical touch',
    'Quality time',
    'Acts of service',
    'Receiving gifts'
  ];

  // Pet preferences
  static const List<String> petPreferences = [
    'Dog lover',
    'Cat person',
    'Both',
    'Other pets',
    'No pets',
    'Allergic to pets'
  ];

  // Drinking habits
  static const List<String> drinkingHabits = [
    'Never',
    'Socially',
    'Regularly',
    'Prefer not to say'
  ];

  // Smoking habits
  static const List<String> smokingHabits = [
    'Never',
    'Socially',
    'Regularly',
    'Trying to quit',
    'Prefer not to say'
  ];

  // Workout frequency
  static const List<String> workoutFrequency = [
    'Daily',
    'Weekly',
    'Monthly',
    'Never',
    'Prefer not to say'
  ];

  // Dietary preferences
  static const List<String> dietaryPreferences = [
    'Omnivore',
    'Vegetarian',
    'Vegan',
    'Pescatarian',
    'Keto',
    'Paleo',
    'Other'
  ];

  // Social media usage
  static const List<String> socialMediaUsage = [
    'Very active',
    'Active',
    'Passive',
    'Not active',
    'No social media'
  ];

  // Sleeping habits
  static const List<String> sleepingHabits = [
    'Early bird',
    'Night owl',
    'Depends on the day',
    'Insomniac'
  ];

  // Languages
  static const List<String> languages = [
    'English', 'Spanish', 'French', 'German', 'Italian',
    'Portuguese', 'Russian', 'Chinese', 'Japanese', 'Korean',
    'Arabic', 'Hindi', 'Dutch', 'Swedish', 'Norwegian',
    'Danish', 'Finnish', 'Polish', 'Turkish', 'Hebrew',
    'Thai', 'Vietnamese', 'Indonesian', 'Tagalog', 'Other'
  ];

  // Helper method to get icon for interests
  static Map<String, IconData> get interestIcons => {
    'Travel': Icons.flight_takeoff,
    'Music': Icons.music_note,
    'Sports': Icons.sports_basketball,
    'Cooking': Icons.restaurant,
    'Reading': Icons.menu_book,
    'Movies': Icons.movie,
    'Art': Icons.palette,
    'Photography': Icons.camera_alt,
    'Fitness': Icons.fitness_center,
    'Gaming': Icons.sports_esports,
    'Dancing': Icons.nightlife,
    'Technology': Icons.devices,
    'Fashion': Icons.shopping_bag,
    'Food': Icons.fastfood,
    'Outdoors': Icons.terrain,
    'Coffee': Icons.coffee,
    'Wine': Icons.wine_bar,
    'Beer': Icons.sports_bar,
    'Hiking': Icons.hiking,
    'Swimming': Icons.pool,
    'Running': Icons.directions_run,
    'Cycling': Icons.directions_bike,
    'Yoga': Icons.self_improvement,
    'Meditation': Icons.spa,
    'Concerts': Icons.library_music,
    'Theater': Icons.theater_comedy,
    'Museums': Icons.museum,
    'Shopping': Icons.shopping_cart,
    'Volunteering': Icons.volunteer_activism,
    'Writing': Icons.edit,
    'Podcasts': Icons.podcasts,
    'Board Games': Icons.casino,
    'Karaoke': Icons.mic,
    'Stand-up Comedy': Icons.sentiment_very_satisfied,
  };

  // Helper method to get display text for profile completion
  static String getCompletionLabel(int percentage) {
    if (percentage >= 90) return 'Profile Master';
    if (percentage >= 80) return 'Almost Perfect';
    if (percentage >= 70) return 'Looking Good';
    if (percentage >= 60) return 'Getting There';
    if (percentage >= 50) return 'Halfway';
    if (percentage >= 40) return 'Making Progress';
    if (percentage >= 30) return 'Getting Started';
    if (percentage >= 20) return 'Just Beginning';
    return 'New Profile';
  }

  // Helper method to get motivational message
  static String getMotivationalMessage(int percentage) {
    if (percentage >= 90) {
      return 'Amazing! Your profile is incredibly detailed and attractive.';
    } else if (percentage >= 80) {
      return 'Excellent! Just a few more details to make your profile perfect.';
    } else if (percentage >= 70) {
      return 'Great job! Your profile is looking really good.';
    } else if (percentage >= 60) {
      return 'Nice work! Consider adding lifestyle and preference details.';
    } else if (percentage >= 50) {
      return 'Good progress! Add more personality details to stand out.';
    } else if (percentage >= 40) {
      return 'Keep going! More details help you find better matches.';
    } else if (percentage >= 30) {
      return 'You\'re on the right track! Add more interests and basics.';
    } else if (percentage >= 20) {
      return 'Good start! Complete more sections to attract matches.';
    } else {
      return 'Welcome! Complete your profile to start meeting amazing people.';
    }
  }

  // Profile sections for organization
  static const Map<String, List<String>> profileSections = {
    'Basic Information': [
      'name', 'age', 'gender', 'location', 'bio', 'height'
    ],
    'Professional': [
      'jobTitle', 'company', 'school'
    ],
    'Relationship & Goals': [
      'relationshipGoals', 'lookingFor'
    ],
    'Basics': [
      'zodiacSign', 'education', 'familyPlans', 'personalityType',
      'communicationStyle', 'loveStyle'
    ],
    'Lifestyle': [
      'pets', 'drinking', 'smoking', 'workout', 'dietaryPreference',
      'socialMedia', 'sleepingHabits'
    ],
    'Languages & Interests': [
      'languagesKnown', 'interests'
    ],
    'Ask Me About': [
      'askAboutGoingOut', 'askAboutWeekend', 'askAboutPhone'
    ],
    'Privacy': [
      'showAge', 'showDistance'
    ]
  };

  // Method to validate profile field
  static String? validateField(String fieldName, dynamic value) {
    switch (fieldName) {
      case 'name':
        if (value == null || value.toString().trim().isEmpty) {
          return 'Name is required';
        }
        if (value.toString().length < 2) {
          return 'Name must be at least 2 characters';
        }
        break;
      case 'age':
        if (value == null) return 'Age is required';
        int? age = int.tryParse(value.toString());
        if (age == null || age < 18) {
          return 'You must be at least 18 years old';
        }
        if (age > 100) {
          return 'Please enter a valid age';
        }
        break;
      case 'bio':
        if (value == null || value.toString().trim().isEmpty) {
          return 'Bio is required';
        }
        if (value.toString().length < 20) {
          return 'Bio should be at least 20 characters';
        }
        if (value.toString().length > 300) {
          return 'Bio should not exceed 300 characters';
        }
        break;
      case 'location':
        if (value == null || value.toString().trim().isEmpty) {
          return 'Location is required';
        }
        break;
      case 'interests':
        if (value is List && value.isEmpty) {
          return 'Add at least one interest';
        }
        break;
    }
    return null; // No validation error
  }
}