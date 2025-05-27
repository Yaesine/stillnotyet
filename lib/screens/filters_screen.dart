// lib/screens/filters_screen.dart - Enhanced with all profile features for filtering fi
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../utils/profile_options.dart';
import '../widgets/components/modern_selection_widgets.dart';

class FiltersScreen extends StatefulWidget {
  const FiltersScreen({Key? key}) : super(key: key);

  @override
  _FiltersScreenState createState() => _FiltersScreenState();
}

class _FiltersScreenState extends State<FiltersScreen> {
  // Basic filter settings
  RangeValues _ageRange = const RangeValues(18, 50);
  double _maxDistance = 50;
  String _genderPreference = 'Everyone';
  bool _isLoading = false;

  // Advanced filters
  bool _showProfilesWithPhoto = true;
  bool _showVerifiedOnly = false;
  List<String> _selectedInterests = [];
  bool _advancedMatchingEnabled = false;
  double _activityLevel = 3;

  // Professional filters
  bool _filterByProfessional = false;
  bool _hasJobTitle = false;
  String _educationLevel = '';

  // Relationship filters
  List<String> _relationshipGoals = [];

  // Physical filters
  List<String> _heightPreferences = [];

  // Basics filters
  List<String> _zodiacSigns = [];
  List<String> _familyPlans = [];
  List<String> _personalityTypes = [];
  List<String> _communicationStyles = [];
  List<String> _loveLanguages = [];

  // Lifestyle filters
  List<String> _petPreferences = [];
  List<String> _drinkingHabits = [];
  List<String> _smokingHabits = [];
  List<String> _workoutFrequency = [];
  List<String> _dietaryPreferences = [];
  List<String> _socialMediaUsage = [];
  List<String> _sleepingHabits = [];

  // Language filters
  List<String> _languagePreferences = [];

  final FirestoreService _firestoreService = FirestoreService();

  // Track which sections are expanded
  bool _basicFiltersExpanded = true;
  bool _advancedFiltersExpanded = false;
  bool _professionalFiltersExpanded = false;
  bool _relationshipFiltersExpanded = false;
  bool _basicsFiltersExpanded = false;
  bool _lifestyleFiltersExpanded = false;
  bool _languageFiltersExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
  }

  Future<void> _loadUserPreferences() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.currentUser;

    if (user != null) {
      setState(() {
        _ageRange = RangeValues(
            user.ageRangeStart.toDouble(),
            user.ageRangeEnd.toDouble()
        );
        _maxDistance = user.distance.toDouble();
        _genderPreference = user.lookingFor.isEmpty ? 'Everyone' : user.lookingFor;
      });

      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.id)
            .get();
        Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;

        if (userData != null && mounted) {
          setState(() {
            // Load existing preferences
            _showProfilesWithPhoto = userData['showProfilesWithPhoto'] ?? true;
            _showVerifiedOnly = userData['showVerifiedOnly'] ?? false;
            _advancedMatchingEnabled = userData['advancedMatchingEnabled'] ?? false;
            _activityLevel = (userData['activityLevel'] ?? 3).toDouble();

            if (userData['prioritizedInterests'] != null) {
              _selectedInterests = List<String>.from(userData['prioritizedInterests']);
            }

            // Load new filter preferences
            _filterByProfessional = userData['filterByProfessional'] ?? false;
            _hasJobTitle = userData['filterHasJobTitle'] ?? false;
            _educationLevel = userData['filterEducationLevel'] ?? '';

            // Load multi-select filters
            _relationshipGoals = List<String>.from(userData['filterRelationshipGoals'] ?? []);
            _heightPreferences = List<String>.from(userData['filterHeightPreferences'] ?? []);
            _zodiacSigns = List<String>.from(userData['filterZodiacSigns'] ?? []);
            _familyPlans = List<String>.from(userData['filterFamilyPlans'] ?? []);
            _personalityTypes = List<String>.from(userData['filterPersonalityTypes'] ?? []);
            _communicationStyles = List<String>.from(userData['filterCommunicationStyles'] ?? []);
            _loveLanguages = List<String>.from(userData['filterLoveLanguages'] ?? []);
            _petPreferences = List<String>.from(userData['filterPetPreferences'] ?? []);
            _drinkingHabits = List<String>.from(userData['filterDrinkingHabits'] ?? []);
            _smokingHabits = List<String>.from(userData['filterSmokingHabits'] ?? []);
            _workoutFrequency = List<String>.from(userData['filterWorkoutFrequency'] ?? []);
            _dietaryPreferences = List<String>.from(userData['filterDietaryPreferences'] ?? []);
            _socialMediaUsage = List<String>.from(userData['filterSocialMediaUsage'] ?? []);
            _sleepingHabits = List<String>.from(userData['filterSleepingHabits'] ?? []);
            _languagePreferences = List<String>.from(userData['filterLanguagePreferences'] ?? []);
          });
        }
      } catch (e) {
        print('Error loading advanced preferences: $e');
      }
    }
  }

  String _getActivityLabel(double value) {
    switch (value.round()) {
      case 1: return 'rarely active';
      case 2: return 'occasionally active';
      case 3: return 'moderately active';
      case 4: return 'very active';
      case 5: return 'extremely active';
      default: return 'active';
    }
  }

// Update the _savePreferences method in lib/screens/filters_screen.dart

  Future<void> _savePreferences() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.currentUser;

      if (user != null) {
        final updatedUser = user.copyWith(
          distance: _maxDistance.round(),
          ageRangeStart: _ageRange.start.round(),
          ageRangeEnd: _ageRange.end.round(),
          lookingFor: _genderPreference == 'Everyone' ? '' : _genderPreference,
        );

        await userProvider.updateUserProfile(updatedUser);

        // Save all filter preferences
        await FirebaseFirestore.instance.collection('users').doc(user.id).update({
          'showProfilesWithPhoto': _showProfilesWithPhoto,
          'showVerifiedOnly': _showVerifiedOnly,
          'activityLevel': _activityLevel.round(),
          'advancedMatchingEnabled': _advancedMatchingEnabled,
          'prioritizedInterests': _selectedInterests,

          // Professional filters
          'filterByProfessional': _filterByProfessional,
          'filterHasJobTitle': _hasJobTitle,
          'filterEducationLevel': _educationLevel,

          // Multi-select filters
          'filterRelationshipGoals': _relationshipGoals,
          'filterHeightPreferences': _heightPreferences,
          'filterZodiacSigns': _zodiacSigns,
          'filterFamilyPlans': _familyPlans,
          'filterPersonalityTypes': _personalityTypes,
          'filterCommunicationStyles': _communicationStyles,
          'filterLoveLanguages': _loveLanguages,
          'filterPetPreferences': _petPreferences,
          'filterDrinkingHabits': _drinkingHabits,
          'filterSmokingHabits': _smokingHabits,
          'filterWorkoutFrequency': _workoutFrequency,
          'filterDietaryPreferences': _dietaryPreferences,
          'filterSocialMediaUsage': _socialMediaUsage,
          'filterSleepingHabits': _sleepingHabits,
          'filterLanguagePreferences': _languagePreferences,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Discovery preferences saved'),
              backgroundColor: AppColors.success,
            ),
          );

          // Reload potential matches with new filters
          await userProvider.loadPotentialMatches();

          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      print('Error saving preferences: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving preferences: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildInterestSelectionSection(bool isDarkMode) {
    final List<String> commonInterests = [
      'Travel', 'Music', 'Sports', 'Cooking', 'Reading',
      'Movies', 'Art', 'Photography', 'Fitness', 'Gaming',
      'Dancing', 'Technology', 'Fashion', 'Food', 'Outdoors'
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Must have these interests (select up to 5)',
          style: TextStyle(
            color: isDarkMode ? AppColors.darkTextPrimary : Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: commonInterests.map((interest) {
            final isSelected = _selectedInterests.contains(interest);
            return FilterChip(
              label: Text(interest),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    if (_selectedInterests.length < 5) {
                      _selectedInterests.add(interest);
                    }
                  } else {
                    _selectedInterests.remove(interest);
                  }
                });
              },
              backgroundColor: isDarkMode ? AppColors.darkElevated : Colors.grey.shade200,
              selectedColor: isDarkMode ? AppColors.primary.withOpacity(0.4) : AppColors.primary.withOpacity(0.1),
              checkmarkColor: isDarkMode ? Colors.white : AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected
                    ? (isDarkMode ? Colors.white : AppColors.primary)
                    : (isDarkMode ? AppColors.darkTextPrimary : Colors.black),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final themeColor = AppColors.primary;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.darkBackground : Colors.white,
      appBar: AppBar(
        title: Text(
          'Discovery Preferences',
          style: TextStyle(
            color: isDarkMode ? AppColors.darkTextPrimary : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isDarkMode ? AppColors.darkSurface : Colors.white,
        foregroundColor: isDarkMode ? AppColors.darkTextPrimary : Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            size: 20,
            color: isDarkMode ? AppColors.darkTextPrimary : Colors.black,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          _isLoading
              ? Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(themeColor),
              ),
            ),
          )
              : TextButton(
            onPressed: _savePreferences,
            child: Text(
              'Save',
              style: TextStyle(
                color: themeColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Basic Filters Section
          _buildExpandableSection(
            title: 'Basic Filters',
            icon: Icons.tune,
            expanded: _basicFiltersExpanded,
            onToggle: () => setState(() => _basicFiltersExpanded = !_basicFiltersExpanded),
            isDarkMode: isDarkMode,
            children: [
              // Age Range
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Age Range',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? AppColors.darkTextPrimary : Colors.black,
                    ),
                  ),
                  RangeSlider(
                    values: _ageRange,
                    min: 18,
                    max: 100,
                    divisions: 82,
                    labels: RangeLabels(
                      '${_ageRange.start.round()}',
                      '${_ageRange.end.round()}',
                    ),
                    onChanged: (RangeValues values) {
                      setState(() {
                        _ageRange = values;
                      });
                    },
                    activeColor: themeColor,
                    inactiveColor: isDarkMode ? AppColors.darkElevated : Colors.grey.shade300,
                  ),
                  Text(
                    'Show people aged ${_ageRange.start.round()} to ${_ageRange.end.round()}',
                    style: TextStyle(
                        color: isDarkMode ? AppColors.darkTextSecondary : Colors.grey.shade600
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Distance
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Maximum Distance',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? AppColors.darkTextPrimary : Colors.black,
                    ),
                  ),
                  Slider(
                    value: _maxDistance,
                    min: 1,
                    max: 100,
                    divisions: 99,
                    label: '${_maxDistance.round()} km',
                    onChanged: (double value) {
                      setState(() {
                        _maxDistance = value;
                      });
                    },
                    activeColor: themeColor,
                    inactiveColor: isDarkMode ? AppColors.darkElevated : Colors.grey.shade300,
                  ),
                  Text(
                    'Show people within ${_maxDistance.round()} km',
                    style: TextStyle(
                        color: isDarkMode ? AppColors.darkTextSecondary : Colors.grey.shade600
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Gender Preference
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Show Me',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? AppColors.darkTextPrimary : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildGenderChip('Everyone', isDarkMode, themeColor),
                      _buildGenderChip('Women', isDarkMode, themeColor),
                      _buildGenderChip('Men', isDarkMode, themeColor),
                    ],
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Advanced Filters Section
          _buildExpandableSection(
            title: 'Advanced Filters',
            icon: Icons.filter_alt,
            expanded: _advancedFiltersExpanded,
            onToggle: () => setState(() => _advancedFiltersExpanded = !_advancedFiltersExpanded),
            isDarkMode: isDarkMode,
            children: [
              _buildSwitchRow(
                'Only show profiles with photos',
                _showProfilesWithPhoto,
                    (value) => setState(() => _showProfilesWithPhoto = value),
                isDarkMode,
                themeColor,
              ),
              const SizedBox(height: 16),
              _buildSwitchRow(
                'Only show verified profiles',
                _showVerifiedOnly,
                    (value) => setState(() => _showVerifiedOnly = value),
                isDarkMode,
                themeColor,
              ),
              const SizedBox(height: 20),
              Text(
                'Minimum activity level',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? AppColors.darkTextPrimary : Colors.black,
                ),
              ),
              Slider(
                value: _activityLevel,
                min: 1,
                max: 5,
                divisions: 4,
                label: _getActivityLabel(_activityLevel),
                onChanged: (value) {
                  setState(() {
                    _activityLevel = value;
                  });
                },
                activeColor: themeColor,
                inactiveColor: isDarkMode ? AppColors.darkElevated : Colors.grey.shade300,
              ),
              Text(
                'Show profiles that are ${_getActivityLabel(_activityLevel)} on the app',
                style: TextStyle(
                  color: isDarkMode ? AppColors.darkTextSecondary : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 20),
              _buildSwitchRow(
                'Advanced interest matching',
                _advancedMatchingEnabled,
                    (value) => setState(() => _advancedMatchingEnabled = value),
                isDarkMode,
                themeColor,
              ),
              if (_advancedMatchingEnabled) ...[
                const SizedBox(height: 16),
                _buildInterestSelectionSection(isDarkMode),
              ],
            ],
          ),

          const SizedBox(height: 16),

          // Professional & Education Filters
          _buildExpandableSection(
            title: 'Professional & Education',
            icon: Icons.work_outline,
            expanded: _professionalFiltersExpanded,
            onToggle: () => setState(() => _professionalFiltersExpanded = !_professionalFiltersExpanded),
            isDarkMode: isDarkMode,
            children: [
              _buildSwitchRow(
                'Filter by professional info',
                _filterByProfessional,
                    (value) => setState(() => _filterByProfessional = value),
                isDarkMode,
                themeColor,
              ),
              if (_filterByProfessional) ...[
                const SizedBox(height: 16),
                _buildSwitchRow(
                  'Must have job title',
                  _hasJobTitle,
                      (value) => setState(() => _hasJobTitle = value),
                  isDarkMode,
                  themeColor,
                ),
                const SizedBox(height: 16),
                ModernSelectionField(
                  label: 'Minimum Education Level',
                  hint: 'Any education level',
                  value: _educationLevel,
                  icon: Icons.school,
                  options: ['Any'] + ProfileOptions.educationLevels,
                  onChanged: (value) => setState(() => _educationLevel = value == 'Any' ? '' : value),
                  isDarkMode: isDarkMode,
                ),
              ],
            ],
          ),

          const SizedBox(height: 16),

          // Relationship Goals & Physical
          _buildExpandableSection(
            title: 'Relationship & Physical',
            icon: Icons.favorite_outline,
            expanded: _relationshipFiltersExpanded,
            onToggle: () => setState(() => _relationshipFiltersExpanded = !_relationshipFiltersExpanded),
            isDarkMode: isDarkMode,
            children: [
              ModernMultiSelectionField(
                label: 'Relationship Goals',
                hint: 'Any relationship goals',
                selectedValues: _relationshipGoals,
                icon: Icons.favorite,
                options: ProfileOptions.relationshipGoals,
                onChanged: (values) => setState(() => _relationshipGoals = values),
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 16),
              ModernMultiSelectionField(
                label: 'Height Preferences',
                hint: 'Any height',
                selectedValues: _heightPreferences,
                icon: Icons.height,
                options: ProfileOptions.heights,
                onChanged: (values) => setState(() => _heightPreferences = values),
                isDarkMode: isDarkMode,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Basics Filters
          _buildExpandableSection(
            title: 'Basics',
            icon: Icons.star_outline,
            expanded: _basicsFiltersExpanded,
            onToggle: () => setState(() => _basicsFiltersExpanded = !_basicsFiltersExpanded),
            isDarkMode: isDarkMode,
            children: [
              ModernMultiSelectionField(
                label: 'Zodiac Signs',
                hint: 'Any zodiac sign',
                selectedValues: _zodiacSigns,
                icon: Icons.star,
                options: ProfileOptions.zodiacSigns,
                onChanged: (values) => setState(() => _zodiacSigns = values),
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 16),
              ModernMultiSelectionField(
                label: 'Family Plans',
                hint: 'Any family plans',
                selectedValues: _familyPlans,
                icon: Icons.family_restroom,
                options: ProfileOptions.familyPlans,
                onChanged: (values) => setState(() => _familyPlans = values),
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 16),
              ModernMultiSelectionField(
                label: 'Personality Types',
                hint: 'Any personality type',
                selectedValues: _personalityTypes,
                icon: Icons.psychology,
                options: ProfileOptions.personalityTypes,
                onChanged: (values) => setState(() => _personalityTypes = values),
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 16),
              ModernMultiSelectionField(
                label: 'Communication Styles',
                hint: 'Any communication style',
                selectedValues: _communicationStyles,
                icon: Icons.chat,
                options: ProfileOptions.communicationStyles,
                onChanged: (values) => setState(() => _communicationStyles = values),
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 16),
              ModernMultiSelectionField(
                label: 'Love Languages',
                hint: 'Any love language',
                selectedValues: _loveLanguages,
                icon: Icons.favorite_border,
                options: ProfileOptions.loveLanguages,
                onChanged: (values) => setState(() => _loveLanguages = values),
                isDarkMode: isDarkMode,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Lifestyle Filters
          _buildExpandableSection(
            title: 'Lifestyle',
            icon: Icons.style,
            expanded: _lifestyleFiltersExpanded,
            onToggle: () => setState(() => _lifestyleFiltersExpanded = !_lifestyleFiltersExpanded),
            isDarkMode: isDarkMode,
            children: [
              ModernMultiSelectionField(
                label: 'Pet Preferences',
                hint: 'Any pet preference',
                selectedValues: _petPreferences,
                icon: Icons.pets,
                options: ProfileOptions.petPreferences,
                onChanged: (values) => setState(() => _petPreferences = values),
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 16),
              ModernMultiSelectionField(
                label: 'Drinking Habits',
                hint: 'Any drinking habits',
                selectedValues: _drinkingHabits,
                icon: Icons.local_bar,
                options: ProfileOptions.drinkingHabits,
                onChanged: (values) => setState(() => _drinkingHabits = values),
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 16),
              ModernMultiSelectionField(
                label: 'Smoking Habits',
                hint: 'Any smoking habits',
                selectedValues: _smokingHabits,
                icon: Icons.smoking_rooms,
                options: ProfileOptions.smokingHabits,
                onChanged: (values) => setState(() => _smokingHabits = values),
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 16),
              ModernMultiSelectionField(
                label: 'Workout Frequency',
                hint: 'Any workout frequency',
                selectedValues: _workoutFrequency,
                icon: Icons.fitness_center,
                options: ProfileOptions.workoutFrequency,
                onChanged: (values) => setState(() => _workoutFrequency = values),
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 16),
              ModernMultiSelectionField(
                label: 'Dietary Preferences',
                hint: 'Any dietary preference',
                selectedValues: _dietaryPreferences,
                icon: Icons.restaurant,
                options: ProfileOptions.dietaryPreferences,
                onChanged: (values) => setState(() => _dietaryPreferences = values),
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 16),
              ModernMultiSelectionField(
                label: 'Social Media Usage',
                hint: 'Any social media usage',
                selectedValues: _socialMediaUsage,
                icon: Icons.share,
                options: ProfileOptions.socialMediaUsage,
                onChanged: (values) => setState(() => _socialMediaUsage = values),
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 16),
              ModernMultiSelectionField(
                label: 'Sleeping Habits',
                hint: 'Any sleeping habits',
                selectedValues: _sleepingHabits,
                icon: Icons.bedtime,
                options: ProfileOptions.sleepingHabits,
                onChanged: (values) => setState(() => _sleepingHabits = values),
                isDarkMode: isDarkMode,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Languages
          _buildExpandableSection(
            title: 'Languages',
            icon: Icons.language,
            expanded: _languageFiltersExpanded,
            onToggle: () => setState(() => _languageFiltersExpanded = !_languageFiltersExpanded),
            isDarkMode: isDarkMode,
            children: [
              ModernMultiSelectionField(
                label: 'Must speak these languages',
                hint: 'Any language',
                selectedValues: _languagePreferences,
                icon: Icons.language,
                options: ProfileOptions.languages,
                onChanged: (values) => setState(() => _languagePreferences = values),
                isDarkMode: isDarkMode,
                maxSelections: 10,
              ),
            ],
          ),

          // Bottom spacing
          const SizedBox(height: 40),

          // Reset Filters Button
          Center(
            child: TextButton.icon(
              onPressed: _resetFilters,
              icon: const Icon(Icons.refresh),
              label: const Text('Reset All Filters'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildExpandableSection({
    required String title,
    required IconData icon,
    required bool expanded,
    required VoidCallback onToggle,
    required bool isDarkMode,
    required List<Widget> children,
  }) {
    return Card(
      color: isDarkMode ? AppColors.darkCard : Colors.white,
      elevation: 2,
      shadowColor: isDarkMode ? Colors.black : Colors.grey.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? AppColors.darkTextPrimary : Colors.black,
                      ),
                    ),
                  ),
                  Icon(
                    expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: isDarkMode ? AppColors.darkTextSecondary : Colors.grey,
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(children: children),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSwitchRow(
      String text,
      bool value,
      Function(bool) onChanged,
      bool isDarkMode,
      Color themeColor
      ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: isDarkMode ? AppColors.darkTextPrimary : Colors.black,
            ),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: isDarkMode ? Colors.white : themeColor,
          activeTrackColor: isDarkMode
              ? themeColor
              : themeColor.withOpacity(0.4),
          inactiveThumbColor: isDarkMode ? Colors.grey[400] : Colors.white,
          inactiveTrackColor: isDarkMode
              ? Colors.grey.withOpacity(0.3)
              : Colors.grey.withOpacity(0.4),
        ),
      ],
    );
  }

  Widget _buildGenderChip(String gender, bool isDarkMode, Color themeColor) {
    final isSelected = _genderPreference == gender;

    return ChoiceChip(
      label: Text(gender),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _genderPreference = gender;
          });
        }
      },
      backgroundColor: isDarkMode ? AppColors.darkElevated : Colors.grey.shade200,
      selectedColor: isDarkMode
          ? themeColor.withOpacity(0.3)
          : themeColor.withOpacity(0.1),
      labelStyle: TextStyle(
        color: isSelected
            ? (isDarkMode ? Colors.white : themeColor)
            : (isDarkMode ? AppColors.darkTextPrimary : Colors.black),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  void _resetFilters() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset All Filters?'),
        content: const Text('This will reset all your discovery preferences to default values.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                // Reset all filters to default
                _ageRange = const RangeValues(18, 50);
                _maxDistance = 50;
                _genderPreference = 'Everyone';
                _showProfilesWithPhoto = true;
                _showVerifiedOnly = false;
                _selectedInterests = [];
                _advancedMatchingEnabled = false;
                _activityLevel = 3;
                _filterByProfessional = false;
                _hasJobTitle = false;
                _educationLevel = '';
                _relationshipGoals = [];
                _heightPreferences = [];
                _zodiacSigns = [];
                _familyPlans = [];
                _personalityTypes = [];
                _communicationStyles = [];
                _loveLanguages = [];
                _petPreferences = [];
                _drinkingHabits = [];
                _smokingHabits = [];
                _workoutFrequency = [];
                _dietaryPreferences = [];
                _socialMediaUsage = [];
                _sleepingHabits = [];
                _languagePreferences = [];
              });
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}