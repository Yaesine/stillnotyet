import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';

class FiltersScreen extends StatefulWidget {
  const FiltersScreen({Key? key}) : super(key: key);

  @override
  _FiltersScreenState createState() => _FiltersScreenState();
}

class _FiltersScreenState extends State<FiltersScreen> {
  // Filter settings
  RangeValues _ageRange = const RangeValues(18, 50);
  double _maxDistance = 50;
  String _genderPreference = 'Everyone';
  bool _isLoading = false;

  // New fields to add
  bool _showProfilesWithPhoto = true;
  bool _showVerifiedOnly = false;
  List<String> _selectedInterests = [];
  bool _advancedMatchingEnabled = false;
  double _activityLevel = 3; // 1-5 scale for user activity preference
  final FirestoreService _firestoreService = FirestoreService();



  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
  }

  Future<void> _loadUserPreferences() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.currentUser;

    if (user != null) {
      // Existing code to load basic preferences
      setState(() async {
        _ageRange = RangeValues(
            user.ageRangeStart.toDouble(),
            user.ageRangeEnd.toDouble()
        );
        _maxDistance = user.distance.toDouble();
        _genderPreference = user.lookingFor.isEmpty ? 'Everyone' : user.lookingFor;

        // Add these lines to load new preferences
        // Get user document directly to access fields not in the User model
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.id).get();
        Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
        if (userData != null) {
          _showProfilesWithPhoto = userData['showProfilesWithPhoto'] ?? true;
          _showVerifiedOnly = userData['showVerifiedOnly'] ?? false;
          _advancedMatchingEnabled = userData['advancedMatchingEnabled'] ?? false;
          _activityLevel = (userData['activityLevel'] ?? 3).toDouble();

          // Load selected interests if present
          if (userData['prioritizedInterests'] != null) {
            _selectedInterests = List<String>.from(userData['prioritizedInterests']);
          }
        }
      });
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
  Widget _buildInterestSelectionSection() {
    // Common interests to choose from
    final List<String> commonInterests = [
      'Travel', 'Music', 'Sports', 'Cooking', 'Reading',
      'Movies', 'Art', 'Photography', 'Fitness', 'Gaming',
      'Dancing', 'Technology', 'Fashion', 'Food', 'Outdoors'
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Prioritize these interests (select up to 5)'),
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
              backgroundColor: Colors.grey.shade200,
              selectedColor: Colors.red.shade100,
              checkmarkColor: Colors.red,
              labelStyle: TextStyle(
                color: isSelected ? Colors.red : Colors.black,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _savePreferences() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.currentUser;

      if (user != null) {
        // Create an updated user object with the basic fields
        final updatedUser = user.copyWith(
          distance: _maxDistance.round(),
          ageRangeStart: _ageRange.start.round(),
          ageRangeEnd: _ageRange.end.round(),
          lookingFor: _genderPreference == 'Everyone' ? '' : _genderPreference,
        );

        // Update the user model in the provider
        await userProvider.updateUserProfile(updatedUser);

        // Also update the additional preference fields directly in Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.id).update({
          'showProfilesWithPhoto': _showProfilesWithPhoto,
          'showVerifiedOnly': _showVerifiedOnly,
          'activityLevel': _activityLevel.round(),
          'advancedMatchingEnabled': _advancedMatchingEnabled,
          'prioritizedInterests': _selectedInterests,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preferences saved')),
        );

        Navigator.of(context).pop();
      }
    } catch (e) {
      print('Error saving preferences: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving preferences: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discovery Preferences'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          _isLoading
              ? const Padding(
            padding: EdgeInsets.all(16.0),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
              ),
            ),
          )
              : TextButton(
            onPressed: _savePreferences,
            child: const Text(
              'Save',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Card for Age Range
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Age Range',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
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
                    activeColor: Colors.red,
                  ),
                  Text(
                    'Show people aged ${_ageRange.start.round()} to ${_ageRange.end.round()}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Card for Distance
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Maximum Distance',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
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
                    activeColor: Colors.red,
                  ),
                  Text(
                    'Show people within ${_maxDistance.round()} km',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Card for Gender Preference
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Show Me',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildGenderChip('Everyone'),
                      _buildGenderChip('Women'),
                      _buildGenderChip('Men'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Advanced Filters',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Photos only toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Only show profiles with photos'),
                      Switch(
                        value: _showProfilesWithPhoto,
                        onChanged: (value) {
                          setState(() {
                            _showProfilesWithPhoto = value;
                          });
                        },
                        activeColor: Colors.red,
                      ),
                    ],
                  ),

                  // Verified only toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Only show verified profiles'),
                      Switch(
                        value: _showVerifiedOnly,
                        onChanged: (value) {
                          setState(() {
                            _showVerifiedOnly = value;
                          });
                        },
                        activeColor: Colors.red,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Text('Minimum activity level'),
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
                    activeColor: Colors.red,
                  ),

                  Text(
                    'Show profiles that are ${_getActivityLabel(_activityLevel)} on the app',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // NEW: Interest Preferences Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Interest Preferences',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Advanced matching toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Advanced interest matching'),
                      Switch(
                        value: _advancedMatchingEnabled,
                        onChanged: (value) {
                          setState(() {
                            _advancedMatchingEnabled = value;
                          });
                        },
                        activeColor: Colors.red,
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                  Text(
                    'When enabled, we\'ll prioritize matches based on shared interests',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),

                  const SizedBox(height: 16),
                  _buildInterestSelectionSection(),
                ],
              ),
            ),
          ),
        ],

      ),
    );
  }

  Widget _buildGenderChip(String gender) {
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
      backgroundColor: Colors.grey.shade200,
      selectedColor: Colors.red.shade100,
      labelStyle: TextStyle(
        color: isSelected ? Colors.red : Colors.black,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}