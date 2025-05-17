// lib/screens/modern_profile_edit_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../theme/app_theme.dart';
import '../models/user_model.dart';
import '../widgets/components/app_button.dart';
import '../widgets/components/loading_indicator.dart';
import '../widgets/components/interest_chip.dart';

class ModernProfileEditScreen extends StatefulWidget {
  const ModernProfileEditScreen({Key? key}) : super(key: key);

  @override
  _ModernProfileEditScreenState createState() => _ModernProfileEditScreenState();
}

class _ModernProfileEditScreenState extends State<ModernProfileEditScreen> {
  // Form controllers
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _ageController = TextEditingController();
  final _locationController = TextEditingController();
  final _interestController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Form state
  List<String> _interests = [];
  bool _isLoading = false;
  bool _hasChanges = false;

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
    super.dispose();
  }

  // Load user data from provider
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = Provider.of<UserProvider>(context, listen: false).currentUser;
      if (user != null) {
        _nameController.text = user.name;
        _bioController.text = user.bio;
        _ageController.text = user.age.toString();
        _locationController.text = user.location;
        setState(() {
          _interests = List.from(user.interests);
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

  // Add a new interest
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

  // Remove an interest
  void _removeInterest(String interest) {
    setState(() {
      _interests.remove(interest);
      _hasChanges = true;
    });
  }

  // Save profile changes
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

  // Check for unsaved changes
  void _checkForChanges() {
    final user = Provider.of<UserProvider>(context, listen: false).currentUser;
    if (user == null) return;

    bool hasChanges = _nameController.text != user.name ||
        _bioController.text != user.bio ||
        _ageController.text != user.age.toString() ||
        _locationController.text != user.location ||
        !_areListsEqual(_interests, user.interests);

    setState(() {
      _hasChanges = hasChanges;
    });
  }

  // Helper to compare lists
  bool _areListsEqual(List<String> list1, List<String> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  // Confirm discard dialog
  Future<bool> _confirmDiscard() async {
    if (!_hasChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text('You have unsaved changes. Are you sure you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _confirmDiscard,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Profile'),
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: AppColors.text,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            onPressed: () async {
              if (await _confirmDiscard()) {
                Navigator.of(context).pop();
              }
            },
          ),
          actions: [
            if (_hasChanges)
              TextButton(
                onPressed: _isLoading ? null : _saveProfile,
                child: Text(
                  'Save',
                  style: TextStyle(
                    color: _isLoading ? AppColors.textTertiary : AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
          ],
        ),
        body: _isLoading
            ? const Center(
          child: LoadingIndicator(
            type: LoadingIndicatorType.circular,
            size: LoadingIndicatorSize.large,
            message: 'Loading profile...',
          ),
        )
            : Form(
          key: _formKey,
          onChanged: _checkForChanges,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Profile header
              const Center(
                child: Text(
                  'Edit Your Profile',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Update your information to help others get to know you better',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),

              // Name field
              _buildLabeledField(
                label: 'Name',
                child: TextFormField(
                  controller: _nameController,
                  decoration: _buildInputDecoration(
                    hintText: 'Your name',
                    prefixIcon: Icons.person_outline,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Age field
              _buildLabeledField(
                label: 'Age',
                child: TextFormField(
                  controller: _ageController,
                  decoration: _buildInputDecoration(
                    hintText: 'Your age',
                    prefixIcon: Icons.calendar_today,
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your age';
                    }
                    final age = int.tryParse(value);
                    if (age == null || age < 18) {
                      return 'You must be at least 18 years old';
                    }
                    if (age > 100) {
                      return 'Please enter a valid age';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Location field
              _buildLabeledField(
                label: 'Location',
                child: TextFormField(
                  controller: _locationController,
                  decoration: _buildInputDecoration(
                    hintText: 'Your location',
                    prefixIcon: Icons.location_on_outlined,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.my_location, color: AppColors.primary),
                      onPressed: () {
                        // Get current location (optional - would need to implement)
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Getting your location...')),
                        );
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your location';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Bio field
              _buildLabeledField(
                label: 'About Me',
                child: TextFormField(
                  controller: _bioController,
                  decoration: _buildInputDecoration(
                    hintText: 'Tell others about yourself...',
                    prefixIcon: Icons.edit_outlined,
                  ),
                  maxLines: 4,
                  maxLength: 300,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please write something about yourself';
                    }
                    if (value.length < 20) {
                      return 'Bio should be at least 20 characters';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Interests section
              _buildLabeledField(
                label: 'Interests',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add things you love or enjoy doing',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Interest input field
                    TextFormField(
                      controller: _interestController,
                      decoration: _buildInputDecoration(
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

                    // Interests list
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
                            color: AppColors.textTertiary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Save button
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

  // Helper method to build form field with label
  Widget _buildLabeledField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  // Helper method to build consistent input decoration
  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(prefixIcon, color: AppColors.primary),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.divider),
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