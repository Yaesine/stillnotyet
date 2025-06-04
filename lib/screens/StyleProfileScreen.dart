// lib/screens/StyleProfileScreen.dart
import 'dart:io';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:new_tinder_clone/screens/privacy_safety_screen.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/user_provider.dart';
import '../providers/app_auth_provider.dart';
import '../theme/app_theme.dart';
import '../models/user_model.dart';
import '../screens/modern_profile_edit_screen.dart';
import '../screens/photo_manager_screen.dart';
import '../screens/profile_verification_screen.dart';
import '../screens/premium_screen.dart';
import '../screens/boost_screen.dart';
import '../screens/streak_screen.dart';
import '../widgets/components/letter_avatar.dart';
import '../animations/animations.dart';
import '../providers/theme_provider.dart';
import 'help_support_screen.dart';
import 'notifications_screen.dart';


class StyleProfileScreen extends StatefulWidget {
  const StyleProfileScreen({Key? key}) : super(key: key);

  @override
  _StyleProfileScreenState createState() => _StyleProfileScreenState();
}

class _StyleProfileScreenState extends State<StyleProfileScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String _errorMessage = '';
  int _profileCompletion = 0;
  late AnimationController _animationController;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _loadUserData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Updated calculateProfileCompletion method for StyleProfileScreen.dart

  int calculateProfileCompletion(User user) {
    int completedFields = 0;
    int totalFields = 35; // Updated total number of profile fields

    // Basic required fields (higher weight)
    if (user.imageUrls.isNotEmpty) completedFields += 3; // Profile pictures are important
    if (user.bio.length > 20) completedFields += 2; // Meaningful bio
    if (user.name.isNotEmpty) completedFields += 2; // Name is required
    if (user.location.isNotEmpty) completedFields += 2; // Location is important
    if (user.interests.length >= 3) completedFields += 2; // Multiple interests

    // Basic info
    if (user.gender.isNotEmpty) completedFields++;
    if (user.height.isNotEmpty) completedFields++;

    // Professional info
    if (user.jobTitle.isNotEmpty) completedFields++;
    if (user.company.isNotEmpty) completedFields++;
    if (user.school.isNotEmpty) completedFields++;

    // Relationship & personal
    if (user.relationshipGoals.isNotEmpty) completedFields++;
    if (user.languagesKnown.isNotEmpty) completedFields++;

    // Basics section
    if (user.zodiacSign.isNotEmpty) completedFields++;
    if (user.education.isNotEmpty) completedFields++;
    if (user.familyPlans.isNotEmpty) completedFields++;
    if (user.personalityType.isNotEmpty) completedFields++;
    if (user.communicationStyle.isNotEmpty) completedFields++;
    if (user.loveStyle.isNotEmpty) completedFields++;

    // Lifestyle section
    if (user.pets.isNotEmpty) completedFields++;
    if (user.drinking.isNotEmpty) completedFields++;
    if (user.smoking.isNotEmpty) completedFields++;
    if (user.workout.isNotEmpty) completedFields++;
    if (user.dietaryPreference.isNotEmpty) completedFields++;
    if (user.socialMedia.isNotEmpty) completedFields++;
    if (user.sleepingHabits.isNotEmpty) completedFields++;

    // Ask me about section
    if (user.askAboutGoingOut.isNotEmpty) completedFields++;
    if (user.askAboutWeekend.isNotEmpty) completedFields++;
    if (user.askAboutPhone.isNotEmpty) completedFields++;

    // Additional basic fields
    if (user.lookingFor.isNotEmpty) completedFields++;

    // Make sure we don't exceed 100%
    int percentage = ((completedFields / totalFields) * 100).round();
    return percentage > 100 ? 100 : percentage;
  }

// Enhanced completion message based on new fields
  String _getCompletionMessage() {
    if (_profileCompletion >= 80) {
      return 'Excellent! Your detailed profile will attract quality matches.';
    } else if (_profileCompletion >= 60) {
      return 'Great progress! Consider adding lifestyle details.';
    } else if (_profileCompletion >= 40) {
      return 'Good start! Add more details to stand out.';
    } else if (_profileCompletion >= 20) {
      return 'Keep going! More details mean better matches.';
    } else {
      return 'Complete your profile to start getting amazing matches.';
    }
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.loadCurrentUser();

      if (mounted) {
        final user = userProvider.currentUser;

        // Calculate profile completion percentage
        if (user != null) {
          setState(() {
            _profileCompletion = calculateProfileCompletion(user);
            _isLoading = false;
          });

          _animationController.forward();
        }
      }
    } catch (e) {
      print('Error loading profile data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load profile: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get current brightness to determine if we're in dark mode
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // Make sure the Scaffold's background color respects dark mode
      backgroundColor: isDarkMode ? AppColors.darkBackground : AppColors.background,
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _loadUserData,
        color: AppColors.primary,
        child: _isLoading
            ? _buildLoadingView(isDarkMode)
            : _errorMessage.isNotEmpty
            ? _buildErrorView(isDarkMode)
            : Consumer<UserProvider>(
          builder: (context, userProvider, _) {
            final user = userProvider.currentUser;
            if (user == null) {
              return _buildNoUserView(isDarkMode);
            }

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Profile Header with Image - Updated without back button
                _buildProfileHeader(user, isDarkMode),

                // Profile Content
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile Completion Card
                        FadeInAnimation(
                          delay: const Duration(milliseconds: 200),
                          child: _buildProfileCompletionCard(isDarkMode),
                        ),

                        const SizedBox(height: 24),

                        // Quick Action Buttons
                        FadeInAnimation(
                          delay: const Duration(milliseconds: 300),
                          child: _buildQuickActions(user, isDarkMode),
                        ),

                        const SizedBox(height: 24),

                        // Premium Promo Card
                        FadeInAnimation(
                          delay: const Duration(milliseconds: 400),
                          child: _buildPremiumPromo(),
                        ),

                        const SizedBox(height: 24),

                        // About Me Section
                        FadeInAnimation(
                          delay: const Duration(milliseconds: 500),
                          child: _buildAboutMeSection(user, isDarkMode),
                        ),

                        const SizedBox(height: 24),

                        // Interests Section
                        FadeInAnimation(
                          delay: const Duration(milliseconds: 600),
                          child: _buildInterestsSection(user, isDarkMode),
                        ),

                        const SizedBox(height: 24),

                        // Photos Gallery Section
                        if (user.imageUrls.length > 1)
                          FadeInAnimation(
                            delay: const Duration(milliseconds: 700),
                            child: _buildPhotosSection(user, isDarkMode),
                          ),

                        // Settings Section
                        FadeInAnimation(
                          delay: const Duration(milliseconds: 800),
                          child: _buildSettingsSection(isDarkMode),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

// Modified section for lib/screens/StyleProfileScreen.dart

// This is the updated _buildProfileHeader method that fixes the text overlap issue
  Widget _buildProfileHeader(User user, bool isDarkMode) {
    return SliverAppBar(
      expandedHeight: 340,
      pinned: true,
      stretch: true,
      backgroundColor: isDarkMode ? AppColors.darkSurface : Colors.white,
      // Remove the leading property to hide the back button
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Profile Image
            Hero(
              tag: 'profile_image_${user.id}',
              child: user.imageUrls.isNotEmpty
                  ? CachedNetworkImage(
                imageUrl: user.imageUrls[0],
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                  child: const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppColors.primary,
                  child: Center(
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 80,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              )
                  : Container(
                color: AppColors.primary,
                child: Center(
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 80,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                  stops: const [0.6, 1.0],
                ),
              ),
            ),

            // User info overlay - FIXED to prevent text overlap
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name, age and verified badge in a single row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            '${user.name}, ${user.age}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  blurRadius: 8,
                                  color: Colors.black45,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (user.isVerified)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.verified,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Location info remains unchanged
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            user.location,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                              shadows: [
                                Shadow(
                                  blurRadius: 4,
                                  color: Colors.black38,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Small icon buttons in top right
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: Row(
                children: [
                  // Settings button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.tune, color: Colors.white),
                      onPressed: () {
                        Navigator.of(context).pushNamed('/filters')
                            .then((_) => _loadUserData());
                      },
                      tooltip: 'Filters',
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Edit profile button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ModernProfileEditScreen(),
                          ),
                        ).then((_) => _loadUserData());
                      },
                      tooltip: 'Edit Profile',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

// Also, add this method to ProfileImageGallery class to fix any similar issues there
// Method to be added in the _ProfileImageGalleryState class in the same file
  Widget _buildGradientOverlayWithText(User user) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.8),
            ],
            stops: const [0.0, 1.0],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${user.name}, ${user.age}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 8,
                          color: Colors.black45,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: Colors.white70,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    user.location,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCompletionCard(bool isDarkMode) {
    final completionColor = _getCompletionColor();

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(
                      value: _profileCompletion / 100,
                      strokeWidth: 6,
                      backgroundColor: isDarkMode ? AppColors.darkElevated : Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(completionColor),
                    ),
                  ),
                  Text(
                    "$_profileCompletion%",
                    style: TextStyle(
                      color: completionColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(_getCompletionIcon(), color: completionColor, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          "Profile Completion",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _getCompletionMessage(),
                      style: TextStyle(
                        fontSize: 13,
                        color: isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Action button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ModernProfileEditScreen(),
                  ),
                ).then((_) => _loadUserData());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: completionColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Complete Your Profile',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(User user, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildActionButton(
              icon: Icons.photo_camera,
              label: 'Photos',
              color: Colors.purple,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const PhotoManagerScreen(),
                  ),
                ).then((_) => _loadUserData());
              },
              isDarkMode: isDarkMode,
            ),
            _buildActionButton(
              icon: Icons.verified_user,
              label: 'Verify',
              color: Colors.blue,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ProfileVerificationScreen(),
                  ),
                );
              },
              isDarkMode: isDarkMode,
            ),
            _buildActionButton(
              icon: Icons.bolt,
              label: 'Boost',
              color: Colors.orange,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => BoostScreen()),
                );
              },
              isDarkMode: isDarkMode,
            ),
            _buildActionButton(
              icon: Icons.local_fire_department,
              label: 'Streak',
              color: Colors.red,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const StreakScreen(),

                  ),
                );
              },
              isDarkMode: isDarkMode,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isDarkMode
                  ? color.withOpacity(0.2)
                  : color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumPromo() {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => PremiumScreen()),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFB900),
              Color(0xFFFF8A00),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFB900).withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.workspace_premium,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Flexible(
                        child: Text(
                          'Upgrade to Premium',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Transform.translate(
                        offset: const Offset(0, -2),  // Move slightly upward
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'SALE',
                            style: TextStyle(
                              color: Color(0xFFFF8A00),
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'See who likes you & unlock all premium features',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Colors.white,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutMeSection(User user, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'About Me',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            IconButton(
              icon: Icon(Icons.edit,
                  color: AppColors.primary,
                  size: 18
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ModernProfileEditScreen(),
                  ),
                ).then((_) => _loadUserData());
              },
            ),
          ],
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDarkMode ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: isDarkMode
                    ? Colors.black.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.bio.isNotEmpty ? user.bio : 'Add something about yourself...',
                style: TextStyle(
                  fontSize: 15,
                  color: user.bio.isNotEmpty
                      ? (isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary)
                      : (isDarkMode ? Colors.grey[600] : Colors.grey),
                  height: 1.5,
                ),
              ),
              if (user.bio.length < 20)
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: Colors.amber[800], size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Profiles with detailed bios get up to 50% more matches!',
                          style: TextStyle(color: Colors.amber[800], fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInterestsSection(User user, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Interests',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            IconButton(
              icon: Icon(Icons.edit,
                  color: AppColors.primary,
                  size: 18
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ModernProfileEditScreen(),
                  ),
                ).then((_) => _loadUserData());
              },
            ),
          ],
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDarkMode ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: isDarkMode
                    ? Colors.black.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: user.interests.isNotEmpty
              ? Wrap(
            spacing: 8,
            runSpacing: 8,
            children: user.interests.map((interest) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  interest,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          )
              : Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 40,
                    color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Add your interests to help us find better matches',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey[500] : Colors.grey[500],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotosSection(User user, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Photos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            TextButton.icon(
              icon: const Icon(Icons.add_photo_alternate, size: 18),
              label: const Text('Manage'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const PhotoManagerScreen(),
                  ),
                ).then((_) => _loadUserData());
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: user.imageUrls.length,
            itemBuilder: (context, index) {
              return Container(
                width: 100,
                height: 120,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: isDarkMode
                          ? Colors.black.withOpacity(0.3)
                          : Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: user.imageUrls[index],
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                      child: const Icon(Icons.error, color: Colors.red),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildThemeToggleItem(bool isDarkMode) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final iconColor = isDarkMode ?
    Colors.indigo : // Dark mode icon color
    Colors.amber;   // Light mode icon color

    final iconData = isDarkMode ?
    Icons.dark_mode : // Dark mode icon
    Icons.light_mode; // Light mode icon

    final bgColor = isDarkMode ?
    AppColors.darkCard :
    Colors.white;

    final labelColor = isDarkMode ?
    AppColors.darkTextPrimary :
    AppColors.textPrimary;

    final subLabelColor = isDarkMode ?
    AppColors.darkTextSecondary :
    Colors.grey[700];

    final title = isDarkMode ? 'Dark Mode' : 'Light Mode';
    final subtitle = themeProvider.followSystem ?
    'Following system setting' :
    'Tap to switch to ${isDarkMode ? 'light' : 'dark'} mode';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDarkMode ?
          AppColors.darkDivider :
          Colors.grey.shade200,
        ),
      ),
      color: bgColor,
      child: InkWell(
        onTap: () {
          if (themeProvider.followSystem) {
            // If following system, turn that off and use current theme
            themeProvider.setFollowSystem(false);
          } else {
            // Otherwise toggle the theme
            themeProvider.toggleTheme();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  iconData,
                  color: iconColor,
                  size: 22,
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
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: labelColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: subLabelColor,
                      ),
                    ),
                  ],
                ),
              ),
              // Show a switch instead of a regular toggle
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Platform.isIOS ?
                CupertinoSwitch(
                  value: isDarkMode,
                  activeColor: AppColors.primary,
                  onChanged: (value) {
                    themeProvider.setFollowSystem(false);
                    if (isDarkMode != value) {
                      themeProvider.toggleTheme();
                    }
                  },
                ) :
                Switch(
                  value: isDarkMode,
                  activeColor: AppColors.primary,
                  onChanged: (value) {
                    themeProvider.setFollowSystem(false);
                    if (isDarkMode != value) {
                      themeProvider.toggleTheme();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Optional: System theme setting toggle
  Widget _buildSystemThemeToggle(bool isDarkMode) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    final textColor = isDarkMode ?
    AppColors.darkTextSecondary :
    Colors.grey[600];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Icon(
            Icons.brightness_auto,
            size: 18,
            color: textColor,
          ),
          const SizedBox(width: 8),
          Text(
            'Follow system settings',
            style: TextStyle(
              fontSize: 14,
              color: textColor,
            ),
          ),
          const Spacer(),
          Switch(
            value: themeProvider.followSystem,
            activeColor: AppColors.primary,
            onChanged: (value) {
              themeProvider.setFollowSystem(value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(bool isDarkMode) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Settings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),

        _buildThemeToggleItem(isDarkMode),

        _buildSystemThemeToggle(isDarkMode),

        // Settings items - Updated Discovery Settings to be more prominent
        _buildSettingItem(
          icon: Icons.tune,
          iconColor: AppColors.primary,
          title: 'Discovery Settings',
          subtitle: 'Preferences, distance, age range',
          onTap: () {
            Navigator.of(context).pushNamed('/filters')
                .then((_) => _loadUserData());
          },
          isDarkMode: isDarkMode,
        ),

        // NEW: Notifications Setting Item
        _buildSettingItem(
          icon: Icons.notifications_none,
          iconColor: Colors.blue,
          title: 'Notifications',
          subtitle: 'Manage your notification preferences',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const NotificationsScreen(),
              ),
            );
          },
          isDarkMode: isDarkMode,
        ),

        // NEW: Privacy & Safety Setting Item
        _buildSettingItem(
          icon: Icons.privacy_tip_outlined,
          iconColor: Colors.green,
          title: 'Privacy & Safety',
          subtitle: 'Control your privacy settings',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const PrivacySafetyScreen(),
              ),
            );
          },
          isDarkMode: isDarkMode,
        ),

        // NEW: Help & Support Setting Item
        _buildSettingItem(
          icon: Icons.help_outline,
          iconColor: Colors.purple,
          title: 'Help & Support',
          subtitle: 'FAQs, contact us, report a problem',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const HelpSupportScreen(),
              ),
            );
          },
          isDarkMode: isDarkMode,
        ),

        // Logout button
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              onPressed: () async {
                try {
                  await Provider.of<AppAuthProvider>(context, listen: false).logout();
                  if (mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error logging out: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDarkMode,
    Widget? trailing,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
            color: isDarkMode ? AppColors.darkDivider : Colors.grey.shade200
        ),
      ),
      color: isDarkMode ? AppColors.darkCard : Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 22,
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
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDarkMode ? AppColors.darkTextSecondary : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              trailing ?? Icon(
                Icons.chevron_right,
                color: isDarkMode ? AppColors.darkTextSecondary : Colors.grey,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCompletionColor() {
    if (_profileCompletion >= 80) return Colors.green;
    if (_profileCompletion >= 40) return Colors.amber;
    return AppColors.primary;
  }

  IconData _getCompletionIcon() {
    if (_profileCompletion >= 80) return Icons.check_circle;
    if (_profileCompletion >= 40) return Icons.star;
    return Icons.warning;
  }



  Widget _buildLoadingView(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading your profile...',
            style: TextStyle(
              color: isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(bool isDarkMode) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red.withOpacity(0.7),
            ),
            const SizedBox(height: 24),
            Text(
              'Error Loading Profile',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDarkMode ? AppColors.darkTextSecondary : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadUserData,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoUserView(bool isDarkMode) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_outline,
              size: 80,
              color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Profile Not Available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your profile could not be loaded. Please create a profile to continue.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDarkMode ? AppColors.darkTextSecondary : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                final userProvider = Provider.of<UserProvider>(context, listen: false);
                await userProvider.forceSyncCurrentUser();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Creating user profile...')),
                  );
                  _loadUserData();
                }
              },
              icon: const Icon(Icons.person_add),
              label: const Text('Create Profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}