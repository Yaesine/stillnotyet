// lib/screens/modern_profile_edit_screen.dart - Enhanced with comprehensive profile editing
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../theme/app_theme.dart';
import '../models/user_model.dart';
import '../widgets/components/app_button.dart';
import '../widgets/components/loading_indicator.dart';
import '../widgets/components/interest_chip.dart';
import '../widgets/components/modern_selection_widgets.dart';
import '../utils/profile_options.dart';

class ModernProfileEditScreen extends StatefulWidget {
  const ModernProfileEditScreen({Key? key}) : super(key: key);

  @override
  _ModernProfileEditScreenState createState() => _ModernProfileEditScreenState();
}

class _ModernProfileEditScreenState extends State<ModernProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Basic info controllers
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _ageController = TextEditingController();
  final _locationController = TextEditingController();
  final _interestController = TextEditingController();

  // Professional controllers
  final _jobTitleController = TextEditingController();
  final _companyController = TextEditingController();
  final _schoolController = TextEditingController();

  // Ask me about controllers
  final _askGoingOutController = TextEditingController();
  final _askWeekendController = TextEditingController();
  final _askPhoneController = TextEditingController();

  // Form state
  List<String> _interests = [];
  List<String> _languagesKnown = [];
  String _selectedLanguage = '';
  bool _isLoading = false;
  bool _hasChanges = false;

  // New profile fields
  String _gender = '';
  String _height = '';
  String _relationshipGoals = '';
  String _zodiacSign = '';
  String _education = '';
  String _familyPlans = '';
  String _personalityType = '';
  String _communicationStyle = '';
  String _loveStyle = '';
  String _pets = '';
  String _drinking = '';
  String _smoking = '';
  String _workout = '';
  String _dietaryPreference = '';
  String _socialMedia = '';
  String _sleepingHabits = '';
  bool _showAge = true;
  bool _showDistance = true;

  // Dropdown options
  final List<String> _genderOptions = ['Male', 'Female', 'Non-binary', 'Other', 'Prefer not to say'];
  final List<String> _heightOptions = [
    '4\'8"', '4\'9"', '4\'10"', '4\'11"', '5\'0"', '5\'1"', '5\'2"', '5\'3"', '5\'4"', '5\'5"',
    '5\'6"', '5\'7"', '5\'8"', '5\'9"', '5\'10"', '5\'11"', '6\'0"', '6\'1"', '6\'2"', '6\'3"',
    '6\'4"', '6\'5"', '6\'6"', '6\'7"', '6\'8"', '6\'9"', '6\'10"', '6\'11"', '7\'0"'
  ];
  final List<String> _relationshipGoalsOptions = [
    'Long-term relationship', 'Something casual', 'Not sure yet', 'Prefer not to say'
  ];
  final List<String> _zodiacOptions = [
    'Aries', 'Taurus', 'Gemini', 'Cancer', 'Leo', 'Virgo',
    'Libra', 'Scorpio', 'Sagittarius', 'Capricorn', 'Aquarius', 'Pisces'
  ];
  final List<String> _educationOptions = [
    'High school', 'Some college', 'Bachelor\'s degree', 'Master\'s degree',
    'PhD', 'Trade school', 'Other'
  ];
  final List<String> _familyPlansOptions = [
    'Want children', 'Don\'t want children', 'Have children', 'Open to children', 'Not sure'
  ];
  final List<String> _personalityOptions = [
    'INTJ', 'INTP', 'ENTJ', 'ENTP', 'INFJ', 'INFP', 'ENFJ', 'ENFP',
    'ISTJ', 'ISFJ', 'ESTJ', 'ESFJ', 'ISTP', 'ISFP', 'ESTP', 'ESFP', 'Not sure'
  ];
  final List<String> _communicationOptions = [
    'Direct', 'Thoughtful', 'Playful', 'Serious', 'Casual', 'Formal'
  ];
  final List<String> _loveStyleOptions = [
    'Words of affirmation', 'Physical touch', 'Quality time', 'Acts of service', 'Receiving gifts'
  ];
  final List<String> _petsOptions = [
    'Dog lover', 'Cat person', 'Both', 'Other pets', 'No pets', 'Allergic to pets'
  ];
  final List<String> _drinkingOptions = [
    'Never', 'Socially', 'Regularly', 'Prefer not to say'
  ];
  final List<String> _smokingOptions = [
    'Never', 'Socially', 'Regularly', 'Trying to quit', 'Prefer not to say'
  ];
  final List<String> _workoutOptions = [
    'Daily', 'Weekly', 'Monthly', 'Never', 'Prefer not to say'
  ];
  final List<String> _dietaryOptions = [
    'Omnivore', 'Vegetarian', 'Vegan', 'Pescatarian', 'Keto', 'Paleo', 'Other'
  ];
  final List<String> _socialMediaOptions = [
    'Very active', 'Active', 'Passive', 'Not active', 'No social media'
  ];
  final List<String> _sleepingOptions = [
    'Early bird', 'Night owl', 'Depends on the day', 'Insomniac'
  ];
  final List<String> _languageOptions = [
    'English', 'Spanish', 'French', 'German', 'Italian', 'Portuguese', 'Russian',
    'Chinese', 'Japanese', 'Korean', 'Arabic', 'Hindi', 'Dutch', 'Swedish', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _ageController.dispose();
    _locationController.dispose();
    _interestController.dispose();
    _jobTitleController.dispose();
    _companyController.dispose();
    _schoolController.dispose();
    _askGoingOutController.dispose();
    _askWeekendController.dispose();
    _askPhoneController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = Provider.of<UserProvider>(context, listen: false).currentUser;
      if (user != null) {
        // Basic info
        _nameController.text = user.name;
        _bioController.text = user.bio;
        _ageController.text = user.age.toString();
        _locationController.text = user.location;

        // Professional info
        _jobTitleController.text = user.jobTitle;
        _companyController.text = user.company;
        _schoolController.text = user.school;

        // Ask me about
        _askGoingOutController.text = user.askAboutGoingOut;
        _askWeekendController.text = user.askAboutWeekend;
        _askPhoneController.text = user.askAboutPhone;

        setState(() {
          _interests = List.from(user.interests);
          _languagesKnown = List.from(user.languagesKnown);
          _gender = user.gender;
          _height = user.height;
          _relationshipGoals = user.relationshipGoals;
          _zodiacSign = user.zodiacSign;
          _education = user.education;
          _familyPlans = user.familyPlans;
          _personalityType = user.personalityType;
          _communicationStyle = user.communicationStyle;
          _loveStyle = user.loveStyle;
          _pets = user.pets;
          _drinking = user.drinking;
          _smoking = user.smoking;
          _workout = user.workout;
          _dietaryPreference = user.dietaryPreference;
          _socialMedia = user.socialMedia;
          _sleepingHabits = user.sleepingHabits;
          _showAge = user.showAge;
          _showDistance = user.showDistance;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading user data: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addInterest(String interest) {
    final trimmedInterest = interest.trim();
    if (trimmedInterest.isEmpty) return;

    if (!_interests.contains(trimmedInterest)) {
      setState(() {
        _interests.add(trimmedInterest);
        _hasChanges = true;
      });
    }
    _interestController.clear();
  }

  void _removeInterest(String interest) {
    setState(() {
      _interests.remove(interest);
      _hasChanges = true;
    });
  }

  void _addLanguage(String language) {
    if (language.isNotEmpty && !_languagesKnown.contains(language)) {
      setState(() {
        _languagesKnown.add(language);
        _selectedLanguage = '';
        _hasChanges = true;
      });
    }
  }

  void _removeLanguage(String language) {
    setState(() {
      _languagesKnown.remove(language);
      _hasChanges = true;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.currentUser;

      if (user != null) {
        final updatedUser = user.copyWith(
          name: _nameController.text,
          bio: _bioController.text,
          age: int.tryParse(_ageController.text) ?? user.age,
          location: _locationController.text,
          interests: _interests,
          gender: _gender,
          height: _height,
          jobTitle: _jobTitleController.text,
          company: _companyController.text,
          school: _schoolController.text,
          relationshipGoals: _relationshipGoals,
          languagesKnown: _languagesKnown,
          zodiacSign: _zodiacSign,
          education: _education,
          familyPlans: _familyPlans,
          personalityType: _personalityType,
          communicationStyle: _communicationStyle,
          loveStyle: _loveStyle,
          pets: _pets,
          drinking: _drinking,
          smoking: _smoking,
          workout: _workout,
          dietaryPreference: _dietaryPreference,
          socialMedia: _socialMedia,
          sleepingHabits: _sleepingHabits,
          askAboutGoingOut: _askGoingOutController.text,
          askAboutWeekend: _askWeekendController.text,
          askAboutPhone: _askPhoneController.text,
          showAge: _showAge,
          showDistance: _showDistance,
        );

        await userProvider.updateUserProfile(updatedUser);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
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

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.darkBackground : Colors.white,
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: TextStyle(
            color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        elevation: 0,
        backgroundColor: isDarkMode ? AppColors.darkSurface : Colors.white,
        foregroundColor: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            size: 20,
            color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _isLoading ? null : _saveProfile,
              child: Text(
                'Save',
                style: TextStyle(
                  color: _isLoading
                      ? (isDarkMode ? AppColors.darkTextTertiary : AppColors.textTertiary)
                      : AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? Center(
        child: LoadingIndicator(
          type: LoadingIndicatorType.circular,
          size: LoadingIndicatorSize.large,
          message: 'Loading profile...',
          color: isDarkMode ? AppColors.primary : null,
        ),
      )
          : Form(
        key: _formKey,
        onChanged: () => setState(() => _hasChanges = true),
        child: Scrollbar(
          controller: _scrollController,
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              // Basic Information Section
              _buildSectionHeader('Basic Information', Icons.person),
              _buildBasicInfoSection(isDarkMode),

              const SizedBox(height: 32),

              // Professional Information
              _buildSectionHeader('Professional', Icons.work),
              _buildProfessionalSection(isDarkMode),

              const SizedBox(height: 32),

              // Physical & Personal
              _buildSectionHeader('Physical & Personal', Icons.fitness_center),
              _buildPhysicalPersonalSection(isDarkMode),

              const SizedBox(height: 32),

              // Basics Section
              _buildSectionHeader('Basics', Icons.star),
              _buildBasicsSection(isDarkMode),

              const SizedBox(height: 32),

              // Lifestyle Section
              _buildSectionHeader('Lifestyle', Icons.style),
              _buildLifestyleSection(isDarkMode),

              const SizedBox(height: 32),

              // Ask Me About Section
              _buildSectionHeader('Ask Me About', Icons.question_answer),
              _buildAskMeAboutSection(isDarkMode),

              const SizedBox(height: 32),

              // Languages Section
              _buildSectionHeader('Languages I Know', Icons.language),
              _buildLanguagesSection(isDarkMode),

              const SizedBox(height: 32),

              // Interests Section
              _buildSectionHeader('Interests', Icons.favorite),
              _buildInterestsSection(isDarkMode),

              const SizedBox(height: 32),

              // Privacy Settings
              _buildSectionHeader('Control Your Profile', Icons.privacy_tip),
              _buildPrivacySection(isDarkMode),

              const SizedBox(height: 40),

              // Save Button
              AppButton(
                text: 'Save Changes',
                onPressed: _saveProfile,
                type: AppButtonType.primary,
                size: AppButtonSize.large,
                isLoading: _isLoading,
                isFullWidth: true,
                icon: Icons.check,
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection(bool isDarkMode) {
    return Column(
      children: [
        _buildTextField(
          controller: _nameController,
          label: 'Name',
          hint: 'Your name',
          icon: Icons.person_outline,
          isDarkMode: isDarkMode,
          validator: (value) => value?.isEmpty == true ? 'Please enter your name' : null,
        ),
        const SizedBox(height: 16),

        _buildTextField(
          controller: _ageController,
          label: 'Age',
          hint: 'Your age',
          icon: Icons.calendar_today,
          isDarkMode: isDarkMode,
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value?.isEmpty == true) return 'Please enter your age';
            final age = int.tryParse(value!);
            if (age == null || age < 18) return 'You must be at least 18 years old';
            if (age > 100) return 'Please enter a valid age';
            return null;
          },
        ),
        const SizedBox(height: 16),

        ModernSelectionField(
          label: 'Gender',
          hint: 'Select your gender',
          value: _gender,
          icon: Icons.wc,
          options: ProfileOptions.genders,
          onChanged: (value) => setState(() => _gender = value),
          isDarkMode: isDarkMode,
        ),
        const SizedBox(height: 16),

        _buildTextField(
          controller: _locationController,
          label: 'Location',
          hint: 'Your location',
          icon: Icons.location_on_outlined,
          isDarkMode: isDarkMode,
          validator: (value) => value?.isEmpty == true ? 'Please enter your location' : null,
        ),
        const SizedBox(height: 16),

        _buildTextField(
          controller: _bioController,
          label: 'About Me',
          hint: 'Tell others about yourself...',
          icon: Icons.edit_outlined,
          isDarkMode: isDarkMode,
          maxLines: 4,
          maxLength: 300,
          validator: (value) {
            if (value?.isEmpty == true) return 'Please write something about yourself';
            if (value!.length < 20) return 'Bio should be at least 20 characters';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildProfessionalSection(bool isDarkMode) {
    return Column(
      children: [
        _buildTextField(
          controller: _jobTitleController,
          label: 'Job Title',
          hint: 'e.g., Software Engineer',
          icon: Icons.work_outline,
          isDarkMode: isDarkMode,
        ),
        const SizedBox(height: 16),

        _buildTextField(
          controller: _companyController,
          label: 'Company',
          hint: 'Where do you work?',
          icon: Icons.business_outlined,
          isDarkMode: isDarkMode,
        ),
        const SizedBox(height: 16),

        _buildTextField(
          controller: _schoolController,
          label: 'School',
          hint: 'Where did you study?',
          icon: Icons.school_outlined,
          isDarkMode: isDarkMode,
        ),
      ],
    );
  }

  Widget _buildPhysicalPersonalSection(bool isDarkMode) {
    return Column(
      children: [
        ModernSelectionField(
          label: 'Height',
          hint: 'Select your height',
          value: _height,
          icon: Icons.height,
          options: ProfileOptions.heights,
          onChanged: (value) => setState(() => _height = value),
          isDarkMode: isDarkMode,
        ),
        const SizedBox(height: 16),

        ModernSelectionField(
          label: 'Relationship Goals',
          hint: 'What are you looking for?',
          value: _relationshipGoals,
          icon: Icons.favorite_outline,
          options: ProfileOptions.relationshipGoals,
          onChanged: (value) => setState(() => _relationshipGoals = value),
          isDarkMode: isDarkMode,
        ),
      ],
    );
  }

  Widget _buildBasicsSection(bool isDarkMode) {
    return Column(
      children: [
        ModernSelectionField(
          label: 'Zodiac Sign',
          hint: 'Select your zodiac sign',
          value: _zodiacSign,
          icon: Icons.star_outline,
          options: ProfileOptions.zodiacSigns,
          onChanged: (value) => setState(() => _zodiacSign = value),
          isDarkMode: isDarkMode,
        ),
        const SizedBox(height: 16),

        ModernSelectionField(
          label: 'Education',
          hint: 'Select your education level',
          value: _education,
          icon: Icons.school,
          options: ProfileOptions.educationLevels,
          onChanged: (value) => setState(() => _education = value),
          isDarkMode: isDarkMode,
        ),
        const SizedBox(height: 16),

        ModernSelectionField(
          label: 'Family Plans',
          hint: 'Your thoughts on children',
          value: _familyPlans,
          icon: Icons.family_restroom,
          options: ProfileOptions.familyPlans,
          onChanged: (value) => setState(() => _familyPlans = value),
          isDarkMode: isDarkMode,
        ),
        const SizedBox(height: 16),

        ModernSelectionField(
          label: 'Personality Type',
          hint: 'MBTI personality type',
          value: _personalityType,
          icon: Icons.psychology,
          options: ProfileOptions.personalityTypes,
          onChanged: (value) => setState(() => _personalityType = value),
          isDarkMode: isDarkMode,
        ),
        const SizedBox(height: 16),

        ModernSelectionField(
          label: 'Communication Style',
          hint: 'How do you communicate?',
          value: _communicationStyle,
          icon: Icons.chat_bubble_outline,
          options: ProfileOptions.communicationStyles,
          onChanged: (value) => setState(() => _communicationStyle = value),
          isDarkMode: isDarkMode,
        ),
        const SizedBox(height: 16),

        ModernSelectionField(
          label: 'Love Language',
          hint: 'How do you show love?',
          value: _loveStyle,
          icon: Icons.favorite_border,
          options: ProfileOptions.loveLanguages,
          onChanged: (value) => setState(() => _loveStyle = value),
          isDarkMode: isDarkMode,
        ),
      ],
    );
  }

  Widget _buildLifestyleSection(bool isDarkMode) {
    return Column(
      children: [
        ModernSelectionField(
          label: 'Pets',
          hint: 'Your pet preferences',
          value: _pets,
          icon: Icons.pets,
          options: ProfileOptions.petPreferences,
          onChanged: (value) => setState(() => _pets = value),
          isDarkMode: isDarkMode,
        ),
        const SizedBox(height: 16),

        ModernSelectionField(
          label: 'Drinking',
          hint: 'Your drinking habits',
          value: _drinking,
          icon: Icons.local_bar,
          options: ProfileOptions.drinkingHabits,
          onChanged: (value) => setState(() => _drinking = value),
          isDarkMode: isDarkMode,
        ),
        const SizedBox(height: 16),

        ModernSelectionField(
          label: 'Smoking',
          hint: 'Your smoking habits',
          value: _smoking,
          icon: Icons.smoking_rooms,
          options: ProfileOptions.smokingHabits,
          onChanged: (value) => setState(() => _smoking = value),
          isDarkMode: isDarkMode,
        ),
        const SizedBox(height: 16),

        ModernSelectionField(
          label: 'Workout',
          hint: 'How often do you exercise?',
          value: _workout,
          icon: Icons.fitness_center,
          options: ProfileOptions.workoutFrequency,
          onChanged: (value) => setState(() => _workout = value),
          isDarkMode: isDarkMode,
        ),
        const SizedBox(height: 16),

        ModernSelectionField(
          label: 'Dietary Preference',
          hint: 'Your dietary choices',
          value: _dietaryPreference,
          icon: Icons.restaurant,
          options: ProfileOptions.dietaryPreferences,
          onChanged: (value) => setState(() => _dietaryPreference = value),
          isDarkMode: isDarkMode,
        ),
        const SizedBox(height: 16),

        ModernSelectionField(
          label: 'Social Media',
          hint: 'Your social media usage',
          value: _socialMedia,
          icon: Icons.share,
          options: ProfileOptions.socialMediaUsage,
          onChanged: (value) => setState(() => _socialMedia = value),
          isDarkMode: isDarkMode,
        ),
        const SizedBox(height: 16),

        ModernSelectionField(
          label: 'Sleeping Habits',
          hint: 'Are you a night owl or early bird?',
          value: _sleepingHabits,
          icon: Icons.bedtime,
          options: ProfileOptions.sleepingHabits,
          onChanged: (value) => setState(() => _sleepingHabits = value),
          isDarkMode: isDarkMode,
        ),
      ],
    );
  }

  Widget _buildAskMeAboutSection(bool isDarkMode) {
    return Column(
      children: [
        _buildTextField(
          controller: _askGoingOutController,
          label: 'Going Out',
          hint: 'Tell others about your going out preferences...',
          icon: Icons.nightlife,
          isDarkMode: isDarkMode,
          maxLines: 2,
        ),
        const SizedBox(height: 16),

        _buildTextField(
          controller: _askWeekendController,
          label: 'My Weekend',
          hint: 'How do you like to spend your weekends?',
          icon: Icons.weekend,
          isDarkMode: isDarkMode,
          maxLines: 2,
        ),
        const SizedBox(height: 16),

        _buildTextField(
          controller: _askPhoneController,
          label: 'Me & My Phone',
          hint: 'Your relationship with technology...',
          icon: Icons.smartphone,
          isDarkMode: isDarkMode,
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildLanguagesSection(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ModernMultiSelectionField(
          label: 'Languages I Know',
          hint: 'Select languages you speak',
          selectedValues: _languagesKnown,
          icon: Icons.language,
          options: ProfileOptions.languages,
          onChanged: (languages) => setState(() => _languagesKnown = languages),
          isDarkMode: isDarkMode,
          maxSelections: 10,
        ),
        const SizedBox(height: 16),

        if (_languagesKnown.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _languagesKnown.map((language) => InterestChip(
              label: language,
              backgroundColor: Colors.blue.withOpacity(0.1),
              textColor: Colors.blue,
              onDelete: () => _removeLanguage(language),
            )).toList(),
          )
        else
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDarkMode ? AppColors.darkElevated : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDarkMode ? AppColors.darkDivider : Colors.grey.shade200,
              ),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.language,
                    size: 48,
                    color: isDarkMode ? AppColors.darkTextTertiary : Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Add languages you know',
                    style: TextStyle(
                      color: isDarkMode ? AppColors.darkTextTertiary : AppColors.textTertiary,
                      fontStyle: FontStyle.italic,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInterestsSection(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add things you love or enjoy doing',
          style: TextStyle(
            fontSize: 14,
            color: isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _interestController,
          style: TextStyle(
            color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
          decoration: _buildInputDecoration(
            isDarkMode: isDarkMode,
            hintText: 'Add an interest',
            prefixIcon: Icons.favorite_border,
            suffixIcon: IconButton(
              icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
              onPressed: () {
                if (_interestController.text.isNotEmpty) {
                  _addInterest(_interestController.text);
                }
              },
            ),
          ),
          onFieldSubmitted: _addInterest,
        ),
        const SizedBox(height: 16),

        if (_interests.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _interests.map((interest) => InterestChip(
              label: interest,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              textColor: AppColors.primary,
              onDelete: () => _removeInterest(interest),
            )).toList(),
          )
        else
          Center(
            child: Text(
              'Add interests to help us find better matches',
              style: TextStyle(
                color: isDarkMode ? AppColors.darkTextTertiary : AppColors.textTertiary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPrivacySection(bool isDarkMode) {
    return Column(
      children: [
        _buildSwitchTile(
          title: 'Show my age',
          subtitle: 'Let others see your age on your profile',
          value: _showAge,
          onChanged: (value) => setState(() => _showAge = value),
          icon: Icons.cake,
          isDarkMode: isDarkMode,
        ),
        const SizedBox(height: 16),

        _buildSwitchTile(
          title: 'Show my distance',
          subtitle: 'Let others see how far away you are',
          value: _showDistance,
          onChanged: (value) => setState(() => _showDistance = value),
          icon: Icons.location_on,
          isDarkMode: isDarkMode,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDarkMode,
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: TextStyle(
            color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
          decoration: _buildInputDecoration(
            isDarkMode: isDarkMode,
            hintText: hint,
            prefixIcon: icon,
          ),
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String value,
    required ValueChanged<String?> onChanged,
    required List<String> items,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDarkMode,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value.isEmpty ? null : value,
          decoration: _buildInputDecoration(
            isDarkMode: isDarkMode,
            hintText: hint,
            prefixIcon: icon,
          ),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
          dropdownColor: isDarkMode ? AppColors.darkCard : Colors.white,
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
    required bool isDarkMode,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? AppColors.darkDivider : AppColors.divider,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required bool isDarkMode,
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: isDarkMode ? AppColors.darkTextTertiary : AppColors.textTertiary,
      ),
      prefixIcon: Icon(prefixIcon, color: AppColors.primary),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: isDarkMode ? AppColors.darkCard : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: isDarkMode ? AppColors.darkDivider : AppColors.divider,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: isDarkMode ? AppColors.darkDivider : AppColors.divider,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.error),
      ),
    );
  }
}