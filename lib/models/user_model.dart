// lib/models/user_model.dart - Enhanced with comprehensive profile fields
import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String name;
  final int age;
  final String bio;
  final List<String> imageUrls;
  final List<String> interests;
  final String location;
  final GeoPoint? geoPoint;
  final bool isVerified; // Add this field

  // Basic profile fields
  final String gender;
  final String lookingFor;
  final int distance;
  final int ageRangeStart;
  final int ageRangeEnd;

  // NEW: Extended profile fields
  // Physical attributes
  final String height; // e.g., "5'8\"" or "173 cm"

  // Professional information
  final String jobTitle;
  final String company;
  final String school;

  // Relationship and personal
  final String relationshipGoals; // e.g., "Long-term relationship", "Something casual", etc.
  final List<String> languagesKnown; // e.g., ["English", "Spanish", "French"]

  // Basics section
  final String zodiacSign; // e.g., "Aries", "Leo", etc.
  final String education; // e.g., "Bachelor's degree", "Master's", etc.
  final String familyPlans; // e.g., "Want children", "Don't want children", etc.
  final String personalityType; // e.g., "INTJ", "ENFP", etc.
  final String communicationStyle; // e.g., "Direct", "Thoughtful", etc.
  final String loveStyle; // e.g., "Words of affirmation", "Physical touch", etc.

  // Lifestyle section
  final String pets; // e.g., "Dog lover", "Cat person", "No pets", etc.
  final String drinking; // e.g., "Socially", "Never", "Regularly", etc.
  final String smoking; // e.g., "Never", "Socially", "Regularly", etc.
  final String workout; // e.g., "Daily", "Weekly", "Never", etc.
  final String dietaryPreference; // e.g., "Vegetarian", "Vegan", "Omnivore", etc.
  final String socialMedia; // e.g., "Active", "Passive", "Not active", etc.
  final String sleepingHabits; // e.g., "Early bird", "Night owl", etc.

  // Ask me about section
  final String askAboutGoingOut; // Personal response about going out preferences
  final String askAboutWeekend; // Personal response about weekend activities
  final String askAboutPhone; // Personal response about phone/technology relationship

  // Privacy settings
  final bool showAge; // Whether to display age publicly
  final bool showDistance; // Whether to display distance publicly

  User({
    required this.id,
    required this.name,
    required this.age,
    required this.bio,
    required this.imageUrls,
    required this.interests,
    required this.location,
    this.geoPoint,
    this.gender = '',
    this.lookingFor = '',
    this.distance = 50,
    this.ageRangeStart = 18,
    this.ageRangeEnd = 50,
    // New fields with default values
    this.height = '',
    this.jobTitle = '',
    this.company = '',
    this.school = '',
    this.relationshipGoals = '',
    this.languagesKnown = const [],
    this.zodiacSign = '',
    this.education = '',
    this.familyPlans = '',
    this.personalityType = '',
    this.communicationStyle = '',
    this.loveStyle = '',
    this.pets = '',
    this.drinking = '',
    this.smoking = '',
    this.workout = '',
    this.dietaryPreference = '',
    this.socialMedia = '',
    this.sleepingHabits = '',
    this.askAboutGoingOut = '',
    this.askAboutWeekend = '',
    this.askAboutPhone = '',
    this.showAge = true,
    this.showDistance = true,
    this.isVerified = false, // Default to false

  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      age: json['age'] ?? 25,
      bio: json['bio'] ?? '',
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      interests: List<String>.from(json['interests'] ?? []),
      location: json['location'] ?? '',
      geoPoint: json['geoPoint'],
      gender: json['gender'] ?? '',
      lookingFor: json['lookingFor'] ?? '',
      distance: json['distance'] ?? 50,
      ageRangeStart: json['ageRangeStart'] ?? 18,
      ageRangeEnd: json['ageRangeEnd'] ?? 50,
      // New fields
      height: json['height'] ?? '',
      jobTitle: json['jobTitle'] ?? '',
      company: json['company'] ?? '',
      school: json['school'] ?? '',
      relationshipGoals: json['relationshipGoals'] ?? '',
      languagesKnown: List<String>.from(json['languagesKnown'] ?? []),
      zodiacSign: json['zodiacSign'] ?? '',
      education: json['education'] ?? '',
      familyPlans: json['familyPlans'] ?? '',
      personalityType: json['personalityType'] ?? '',
      communicationStyle: json['communicationStyle'] ?? '',
      loveStyle: json['loveStyle'] ?? '',
      pets: json['pets'] ?? '',
      drinking: json['drinking'] ?? '',
      smoking: json['smoking'] ?? '',
      workout: json['workout'] ?? '',
      dietaryPreference: json['dietaryPreference'] ?? '',
      socialMedia: json['socialMedia'] ?? '',
      sleepingHabits: json['sleepingHabits'] ?? '',
      askAboutGoingOut: json['askAboutGoingOut'] ?? '',
      askAboutWeekend: json['askAboutWeekend'] ?? '',
      askAboutPhone: json['askAboutPhone'] ?? '',
      showAge: json['showAge'] ?? true,
      showDistance: json['showDistance'] ?? true,
    );
  }

  factory User.fromFirestore(DocumentSnapshot doc) {
    try {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      print('Raw user data for ${doc.id}: $data');

      return User(
        id: doc.id,
        name: data['name'] ?? 'Unknown',
        age: data['age'] ?? 25,
        bio: data['bio'] ?? '',
        imageUrls: List<String>.from(data['imageUrls'] ?? []),
        interests: List<String>.from(data['interests'] ?? []),
        location: data['location'] ?? 'Unknown',
        geoPoint: data['geoPoint'],
        gender: data['gender'] ?? '',
        lookingFor: data['lookingFor'] ?? '',
        distance: data['distance'] ?? 50,
        ageRangeStart: data['ageRangeStart'] ?? 18,
        ageRangeEnd: data['ageRangeEnd'] ?? 50,
        // New fields
        height: data['height'] ?? '',
        jobTitle: data['jobTitle'] ?? '',
        company: data['company'] ?? '',
        school: data['school'] ?? '',
        relationshipGoals: data['relationshipGoals'] ?? '',
        languagesKnown: List<String>.from(data['languagesKnown'] ?? []),
        zodiacSign: data['zodiacSign'] ?? '',
        education: data['education'] ?? '',
        familyPlans: data['familyPlans'] ?? '',
        personalityType: data['personalityType'] ?? '',
        communicationStyle: data['communicationStyle'] ?? '',
        loveStyle: data['loveStyle'] ?? '',
        pets: data['pets'] ?? '',
        drinking: data['drinking'] ?? '',
        smoking: data['smoking'] ?? '',
        workout: data['workout'] ?? '',
        dietaryPreference: data['dietaryPreference'] ?? '',
        socialMedia: data['socialMedia'] ?? '',
        sleepingHabits: data['sleepingHabits'] ?? '',
        askAboutGoingOut: data['askAboutGoingOut'] ?? '',
        askAboutWeekend: data['askAboutWeekend'] ?? '',
        askAboutPhone: data['askAboutPhone'] ?? '',
        showAge: data['showAge'] ?? true,
        showDistance: data['showDistance'] ?? true,
        isVerified: data['isVerified'] ?? false, // Add this

      );
    } catch (e) {
      print('Error parsing user data for ${doc.id}: $e');
      return User(
        id: doc.id,
        name: 'Error User',
        age: 0,
        bio: 'Error loading user data',
        imageUrls: [],
        interests: [],
        location: 'Unknown',

      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'bio': bio,
      'imageUrls': imageUrls,
      'interests': interests,
      'location': location,
      'geoPoint': geoPoint,
      'gender': gender,
      'lookingFor': lookingFor,
      'distance': distance,
      'ageRangeStart': ageRangeStart,
      'ageRangeEnd': ageRangeEnd,
      // New fields
      'height': height,
      'jobTitle': jobTitle,
      'company': company,
      'school': school,
      'relationshipGoals': relationshipGoals,
      'languagesKnown': languagesKnown,
      'zodiacSign': zodiacSign,
      'education': education,
      'familyPlans': familyPlans,
      'personalityType': personalityType,
      'communicationStyle': communicationStyle,
      'loveStyle': loveStyle,
      'pets': pets,
      'drinking': drinking,
      'smoking': smoking,
      'workout': workout,
      'dietaryPreference': dietaryPreference,
      'socialMedia': socialMedia,
      'sleepingHabits': sleepingHabits,
      'askAboutGoingOut': askAboutGoingOut,
      'askAboutWeekend': askAboutWeekend,
      'askAboutPhone': askAboutPhone,
      'showAge': showAge,
      'showDistance': showDistance,
      'isVerified': isVerified, // Add this

    };
  }

  User copyWith({
    String? id,
    String? name,
    int? age,
    String? bio,
    List<String>? imageUrls,
    List<String>? interests,
    String? location,
    GeoPoint? geoPoint,
    String? gender,
    String? lookingFor,
    int? distance,
    int? ageRangeStart,
    int? ageRangeEnd,
    // New fields
    String? height,
    String? jobTitle,
    String? company,
    String? school,
    String? relationshipGoals,
    List<String>? languagesKnown,
    String? zodiacSign,
    String? education,
    String? familyPlans,
    String? personalityType,
    String? communicationStyle,
    String? loveStyle,
    String? pets,
    String? drinking,
    String? smoking,
    String? workout,
    String? dietaryPreference,
    String? socialMedia,
    String? sleepingHabits,
    String? askAboutGoingOut,
    String? askAboutWeekend,
    String? askAboutPhone,
    bool? showAge,
    bool? showDistance,
    bool? isVerified, // Add this

  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      bio: bio ?? this.bio,
      imageUrls: imageUrls ?? this.imageUrls,
      interests: interests ?? this.interests,
      location: location ?? this.location,
      geoPoint: geoPoint ?? this.geoPoint,
      gender: gender ?? this.gender,
      lookingFor: lookingFor ?? this.lookingFor,
      distance: distance ?? this.distance,
      ageRangeStart: ageRangeStart ?? this.ageRangeStart,
      ageRangeEnd: ageRangeEnd ?? this.ageRangeEnd,
      // New fields
      height: height ?? this.height,
      jobTitle: jobTitle ?? this.jobTitle,
      company: company ?? this.company,
      school: school ?? this.school,
      relationshipGoals: relationshipGoals ?? this.relationshipGoals,
      languagesKnown: languagesKnown ?? this.languagesKnown,
      zodiacSign: zodiacSign ?? this.zodiacSign,
      education: education ?? this.education,
      familyPlans: familyPlans ?? this.familyPlans,
      personalityType: personalityType ?? this.personalityType,
      communicationStyle: communicationStyle ?? this.communicationStyle,
      loveStyle: loveStyle ?? this.loveStyle,
      pets: pets ?? this.pets,
      drinking: drinking ?? this.drinking,
      smoking: smoking ?? this.smoking,
      workout: workout ?? this.workout,
      dietaryPreference: dietaryPreference ?? this.dietaryPreference,
      socialMedia: socialMedia ?? this.socialMedia,
      sleepingHabits: sleepingHabits ?? this.sleepingHabits,
      askAboutGoingOut: askAboutGoingOut ?? this.askAboutGoingOut,
      askAboutWeekend: askAboutWeekend ?? this.askAboutWeekend,
      askAboutPhone: askAboutPhone ?? this.askAboutPhone,
      showAge: showAge ?? this.showAge,
      showDistance: showDistance ?? this.showDistance,
      isVerified: isVerified ?? this.isVerified, // Add this

    );
  }

  // Helper method to calculate profile completion percentage
  int getProfileCompletionPercentage() {
    int completedFields = 0;
    int totalFields = 31; // Total number of profile fields

    if (name.isNotEmpty) completedFields++;
    if (age > 0) completedFields++;
    if (bio.isNotEmpty) completedFields++;
    if (imageUrls.isNotEmpty) completedFields++;
    if (interests.isNotEmpty) completedFields++;
    if (location.isNotEmpty) completedFields++;
    if (gender.isNotEmpty) completedFields++;
    if (lookingFor.isNotEmpty) completedFields++;
    if (height.isNotEmpty) completedFields++;
    if (jobTitle.isNotEmpty) completedFields++;
    if (company.isNotEmpty) completedFields++;
    if (school.isNotEmpty) completedFields++;
    if (relationshipGoals.isNotEmpty) completedFields++;
    if (languagesKnown.isNotEmpty) completedFields++;
    if (zodiacSign.isNotEmpty) completedFields++;
    if (education.isNotEmpty) completedFields++;
    if (familyPlans.isNotEmpty) completedFields++;
    if (personalityType.isNotEmpty) completedFields++;
    if (communicationStyle.isNotEmpty) completedFields++;
    if (loveStyle.isNotEmpty) completedFields++;
    if (pets.isNotEmpty) completedFields++;
    if (drinking.isNotEmpty) completedFields++;
    if (smoking.isNotEmpty) completedFields++;
    if (workout.isNotEmpty) completedFields++;
    if (dietaryPreference.isNotEmpty) completedFields++;
    if (socialMedia.isNotEmpty) completedFields++;
    if (sleepingHabits.isNotEmpty) completedFields++;
    if (askAboutGoingOut.isNotEmpty) completedFields++;
    if (askAboutWeekend.isNotEmpty) completedFields++;
    if (askAboutPhone.isNotEmpty) completedFields++;
    // Privacy settings are always counted as complete since they have defaults

    return ((completedFields / totalFields) * 100).round();
  }
}