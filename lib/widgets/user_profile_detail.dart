// lib/widgets/_user_profile_detail.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../animations/modern_match_animation.dart';
import '../models/user_model.dart';
import '../providers/user_provider.dart';
import '../services/profile_view_tracker.dart';
import '../theme/app_theme.dart';
import '../utils/custom_page_route.dart';
import '../screens/modern_chat_screen.dart';
import '../screens/premium_screen.dart';
import '../utils/profile_options.dart';
import 'components/letter_avatar.dart';
import 'components/interest_chip.dart';

class UserProfileDetail extends StatefulWidget {
  final User user;

  const UserProfileDetail({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  _UserProfileDetailState createState() => _UserProfileDetailState();
}
// Add this class to the UserProfileDetail.dart file

class ProfileImageGallery extends StatefulWidget {
  final User user;

  const ProfileImageGallery({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  _ProfileImageGalleryState createState() => _ProfileImageGalleryState();
}

class _ProfileImageGalleryState extends State<ProfileImageGallery> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasMultipleImages = widget.user.imageUrls.length > 1;

    return Stack(
      children: [
        // Image gallery
        Positioned.fill(
          child: widget.user.imageUrls.isEmpty
              ? Center(
            child: LetterAvatar(
              name: widget.user.name,
              size: 150,
              showBorder: false,
            ),
          )
              : PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: widget.user.imageUrls.length,
            itemBuilder: (context, index) {
              return Hero(
                tag: index == 0 ? 'profile_image_${widget.user.id}' : 'profile_image_${widget.user.id}_$index',
                child: CachedNetworkImage(
                  imageUrl: widget.user.imageUrls[index],
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => LetterAvatar(
                    name: widget.user.name,
                    size: double.infinity,
                    showBorder: false,
                  ),
                ),
              );
            },
          ),
        ),

        // Gradient overlays
        Column(
          children: [
            // Top gradient
            Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            const Spacer(),
            // Bottom gradient
            Container(
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ],
        ),

        // Image pagination indicators
        if (hasMultipleImages)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.user.imageUrls.length,
                    (index) => Container(
                  width: _currentPage == index ? 16 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: _currentPage == index ? Colors.white : Colors.white.withOpacity(0.4),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}


class _UserProfileDetailState extends State<UserProfileDetail>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 0;
  bool _isSwipingDown = false;
  double _startDragY = 0;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Track profile view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tracker = ProfileViewTracker();
      tracker.trackProfileView(widget.user.id);
    });

    _pageController = PageController(initialPage: 0);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, 1),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasMultipleImages = widget.user.imageUrls.length > 1;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SlideTransition(
      position: _slideAnimation,
      child: GestureDetector(
        onVerticalDragStart: _handleDragStart,
        onVerticalDragUpdate: _handleDragUpdate,
        onVerticalDragEnd: _handleSwipeDown,
        child: Scaffold(
          backgroundColor: isDarkMode ? AppColors.darkBackground : AppColors.background,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Enhanced app bar with image gallery
              _buildEnhancedAppBar(hasMultipleImages),

              // Enhanced user information
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  decoration: BoxDecoration(
                    color: isDarkMode ? AppColors.darkCard : Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Basic info section
                      _buildBasicInfoSection(),

                      const SizedBox(height: 24),

                      // Professional section
                      if (_hasProfessionalInfo())
                        _buildProfessionalSection(),

                      // About section
                      if (widget.user.bio.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _buildAboutSection(),
                      ],

                      // Basics section
                      if (_hasBasicsInfo()) ...[
                        const SizedBox(height: 24),
                        _buildBasicsSection(),
                      ],

                      // Lifestyle section
                      if (_hasLifestyleInfo()) ...[
                        const SizedBox(height: 24),
                        _buildLifestyleSection(),
                      ],

                      // Languages section
                      if (widget.user.languagesKnown.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _buildLanguagesSection(),
                      ],

                      // Interests section
                      if (widget.user.interests.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _buildInterestsSection(),
                      ],

                      // Ask me about section
                      if (_hasAskMeAboutInfo()) ...[
                        const SizedBox(height: 24),
                        _buildAskMeAboutSection(),
                      ],

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: Container(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottomPadding),
            decoration: BoxDecoration(
              color: isDarkMode ? AppColors.darkCard : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: FutureBuilder<bool>(
              future: _checkIfMatched(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final isMatched = snapshot.data ?? false;

                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _handleSendMessage(context, isMatched),
                    icon: Icon(Icons.message, size: 20),
                    label: const Text(
                      'Send Message',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 3,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedAppBar(bool hasMultipleImages) {
    return SliverAppBar(
      expandedHeight: MediaQuery.of(context).size.height * 0.6,
      pinned: true,
      backgroundColor: Colors.black,
      leading: _buildFloatingBackButton(),
      actions: [
        _buildFloatingActionButton(
          icon: Icons.report_outlined,
          tooltip: 'Report',
          onPressed: () => _showReportDialog(context),
        ),
      ],
      flexibleSpace: Stack(
        children: [
          // Replace the old image gallery with our new component
          Positioned.fill(
            child: ProfileImageGallery(user: widget.user),
          ),

          // Pull down indicator - keep this from the original
          if (_isSwipingDown)
            Positioned(
              top: 80,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.keyboard_arrow_down, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Pull down to dismiss',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name, age and verification
        Row(
          children: [
            Expanded(
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: widget.user.name,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                    if (widget.user.showAge) ...[
                      TextSpan(
                        text: ', ${widget.user.age}',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w400,
                          color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified,
                color: Colors.blue,
                size: 24,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Location and height
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            if (widget.user.showDistance)
              _buildInfoChip(
                icon: Icons.location_on,
                text: widget.user.location,
                color: AppColors.primary,
              ),
            if (widget.user.height.isNotEmpty)
              _buildInfoChip(
                icon: Icons.height,
                text: widget.user.height,
                color: Colors.green,
              ),
            if (widget.user.relationshipGoals.isNotEmpty)
              _buildInfoChip(
                icon: Icons.favorite_border,
                text: widget.user.relationshipGoals,
                color: Colors.pink,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildProfessionalSection() {
    return _buildSection(
      title: 'Professional',
      icon: Icons.work_outline,
      children: [
        if (widget.user.jobTitle.isNotEmpty)
          _buildInfoRow(Icons.work, 'Job Title', widget.user.jobTitle),
        if (widget.user.company.isNotEmpty)
          _buildInfoRow(Icons.business, 'Company', widget.user.company),
        if (widget.user.school.isNotEmpty)
          _buildInfoRow(Icons.school, 'School', widget.user.school),
      ],
    );
  }

  Widget _buildAboutSection() {
    return _buildSection(
      title: 'About Me',
      icon: Icons.person_outline,
      children: [
        Text(
          widget.user.bio,
          style: const TextStyle(
            fontSize: 16,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildBasicsSection() {
    return _buildSection(
      title: 'Basics',
      icon: Icons.star_outline,
      children: [
        if (widget.user.zodiacSign.isNotEmpty)
          _buildInfoRow(Icons.star, 'Zodiac', widget.user.zodiacSign),
        if (widget.user.education.isNotEmpty)
          _buildInfoRow(Icons.school, 'Education', widget.user.education),
        if (widget.user.familyPlans.isNotEmpty)
          _buildInfoRow(Icons.family_restroom, 'Family Plans', widget.user.familyPlans),
        if (widget.user.personalityType.isNotEmpty)
          _buildInfoRow(Icons.psychology, 'Personality', widget.user.personalityType),
        if (widget.user.communicationStyle.isNotEmpty)
          _buildInfoRow(Icons.chat, 'Communication', widget.user.communicationStyle),
        if (widget.user.loveStyle.isNotEmpty)
          _buildInfoRow(Icons.favorite, 'Love Language', widget.user.loveStyle),
      ],
    );
  }

  Widget _buildLifestyleSection() {
    return _buildSection(
      title: 'Lifestyle',
      icon: Icons.style,
      children: [
        if (widget.user.pets.isNotEmpty)
          _buildInfoRow(Icons.pets, 'Pets', widget.user.pets),
        if (widget.user.drinking.isNotEmpty)
          _buildInfoRow(Icons.local_bar, 'Drinking', widget.user.drinking),
        if (widget.user.smoking.isNotEmpty)
          _buildInfoRow(Icons.smoking_rooms, 'Smoking', widget.user.smoking),
        if (widget.user.workout.isNotEmpty)
          _buildInfoRow(Icons.fitness_center, 'Workout', widget.user.workout),
        if (widget.user.dietaryPreference.isNotEmpty)
          _buildInfoRow(Icons.restaurant, 'Diet', widget.user.dietaryPreference),
        if (widget.user.socialMedia.isNotEmpty)
          _buildInfoRow(Icons.share, 'Social Media', widget.user.socialMedia),
        if (widget.user.sleepingHabits.isNotEmpty)
          _buildInfoRow(Icons.bedtime, 'Sleep', widget.user.sleepingHabits),
      ],
    );
  }

  Widget _buildLanguagesSection() {
    return _buildSection(
      title: 'Languages I Know',
      icon: Icons.language,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.user.languagesKnown.map((language) =>
              InterestChip(
                label: language,
                backgroundColor: Colors.blue.withOpacity(0.1),
                textColor: Colors.blue,
                icon: Icons.language,
              )
          ).toList(),
        ),
      ],
    );
  }

  Widget _buildInterestsSection() {
    return _buildSection(
      title: 'Interests',
      icon: Icons.favorite_border,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.user.interests.map((interest) =>
              InterestChip(
                label: interest,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                textColor: AppColors.primary,
                icon: ProfileOptions.interestIcons[interest],
              )
          ).toList(),
        ),
      ],
    );
  }

  Widget _buildAskMeAboutSection() {
    return _buildSection(
      title: 'Ask Me About',
      icon: Icons.question_answer,
      children: [
        if (widget.user.askAboutGoingOut.isNotEmpty)
          _buildAskMeAboutItem('Going Out', widget.user.askAboutGoingOut, Icons.nightlife),
        if (widget.user.askAboutWeekend.isNotEmpty)
          _buildAskMeAboutItem('My Weekend', widget.user.askAboutWeekend, Icons.weekend),
        if (widget.user.askAboutPhone.isNotEmpty)
          _buildAskMeAboutItem('Me & My Phone', widget.user.askAboutPhone, Icons.smartphone),
      ],
    );
  }

  // Helper methods for checking if sections have content
  bool _hasProfessionalInfo() {
    return widget.user.jobTitle.isNotEmpty ||
        widget.user.company.isNotEmpty ||
        widget.user.school.isNotEmpty;
  }

  bool _hasBasicsInfo() {
    return widget.user.zodiacSign.isNotEmpty ||
        widget.user.education.isNotEmpty ||
        widget.user.familyPlans.isNotEmpty ||
        widget.user.personalityType.isNotEmpty ||
        widget.user.communicationStyle.isNotEmpty ||
        widget.user.loveStyle.isNotEmpty;
  }

  bool _hasLifestyleInfo() {
    return widget.user.pets.isNotEmpty ||
        widget.user.drinking.isNotEmpty ||
        widget.user.smoking.isNotEmpty ||
        widget.user.workout.isNotEmpty ||
        widget.user.dietaryPreference.isNotEmpty ||
        widget.user.socialMedia.isNotEmpty ||
        widget.user.sleepingHabits.isNotEmpty;
  }

  bool _hasAskMeAboutInfo() {
    return widget.user.askAboutGoingOut.isNotEmpty ||
        widget.user.askAboutWeekend.isNotEmpty ||
        widget.user.askAboutPhone.isNotEmpty;
  }

  // Rest of the helper widget methods...
  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: 18,
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
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? AppColors.darkTextSecondary : Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAskMeAboutItem(String title, String content, IconData icon) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkElevated : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? AppColors.darkDivider : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 15,
              height: 1.4,
              color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // Action button methods and other existing methods...
  Widget _buildActionButton({
    required String text,
    required IconData icon,
    required Color color,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        elevation: 2,
      ),
    );
  }

  Widget _buildCircularActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  // Existing methods for image gallery, gestures, and actions...
  Widget _buildImageGallery(bool hasMultipleImages) {
    return widget.user.imageUrls.isEmpty
        ? Center(
      child: LetterAvatar(
        name: widget.user.name,
        size: 150,
        showBorder: false,
      ),
    )
        : PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        // Use this approach to prevent a full rebuild
        _currentPage = index;
        // Only rebuild the indicators, not the entire screen
        if (mounted) setState(() {});
      },
      itemCount: widget.user.imageUrls.length,
      itemBuilder: (context, index) {
        return Hero(
          tag: index == 0 ? 'profile_image_${widget.user.id}' : 'profile_image_${widget.user.id}_$index',
          child: CachedNetworkImage(
            imageUrl: widget.user.imageUrls[index],
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey[300],
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ),
            errorWidget: (context, url, error) => LetterAvatar(
              name: widget.user.name,
              size: double.infinity,
              showBorder: false,
            ),
          ),
        );
      },
    );
  }

  Widget _buildGradientOverlays() {
    return Column(
      children: [
        // Top gradient
        Container(
          height: 120,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.6),
                Colors.transparent,
              ],
            ),
          ),
        ),
        const Spacer(),
        // Bottom gradient
        Container(
          height: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.black.withOpacity(0.4),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildPageIndicators(int count) {
    return List.generate(count, (index) {
      return Container(
        width: _currentPage == index ? 16 : 8,
        height: 8,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: _currentPage == index ? Colors.white : Colors.white.withOpacity(0.4),
        ),
      );
    });
  }

  Widget _buildFloatingBackButton() {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }

  Widget _buildFloatingActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }

  // Gesture handlers
  void _handleDragStart(DragStartDetails details) {
    _startDragY = details.globalPosition.dy;
    setState(() => _isSwipingDown = false);
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (details.globalPosition.dy - _startDragY > 50) {
      setState(() => _isSwipingDown = true);
    }
  }

  void _handleSwipeDown(DragEndDetails details) {
    if (_isSwipingDown && details.velocity.pixelsPerSecond.dy > 300) {
      _animationController.forward().then((_) {
        Navigator.of(context).pop();
      });
    } else {
      setState(() => _isSwipingDown = false);
    }
  }

  // Check if current user is matched with this profile
  // Check if current user is matched with this profile
  Future<bool> _checkIfMatched() async {
    try {
      final currentUserId = auth.FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) return false;

      // Check if there's a match document between these users
      final matchQuery = await FirebaseFirestore.instance
          .collection('matches')
          .where('userId', isEqualTo: currentUserId)
          .where('matchedUserId', isEqualTo: widget.user.id)
          .limit(1)
          .get();

      return matchQuery.docs.isNotEmpty;
    } catch (e) {
      print('Error checking match status: $e');
      return false;
    }
  }

  // Handle send message button click
  void _handleSendMessage(BuildContext context, bool isMatched) {
    if (isMatched) {
      // If matched, navigate directly to chat
      Navigator.of(context).push(
        CustomPageRoute(
          child: const ModernChatScreen(),
          settings: RouteSettings(arguments: widget.user),
        ),
      );
    } else {
      // If not matched, show premium upgrade dialog
      _showPremiumUpgradeDialog(context);
    }
  }

  // Show premium upgrade dialog
  // Show premium upgrade dialog
  void _showPremiumUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.amber.shade400,
                  Colors.amber.shade600,
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.workspace_premium,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Upgrade to Premium',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Send messages to anyone with Premium!\n\nUnlock unlimited messaging and connect with ${widget.user.name} instantly.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),
                // Upgrade button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => PremiumScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.amber.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Upgrade Now',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Cancel button
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text(
                    'Maybe Later',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Action handlers
  Future<void> _handleLike(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final matchedUser = await userProvider.swipeRight(widget.user.id);
    Navigator.of(context).pop();

    if (matchedUser != null && context.mounted) {
      final currentUser = userProvider.currentUser;
      if (currentUser != null) {
        Navigator.of(context).push(
          PageRouteBuilder(
            opaque: false,
            pageBuilder: (context, animation, secondaryAnimation) {
              return ModernMatchAnimation(
                currentUser: currentUser,
                matchedUser: matchedUser,
                onDismiss: () => Navigator.of(context).pop(),
                onSendMessage: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    CustomPageRoute(
                      child: const ModernChatScreen(),
                      settings: RouteSettings(arguments: matchedUser),
                    ),
                  );
                },
              );
            },
          ),
        );
      }
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You liked ${widget.user.name}!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleDislike(BuildContext context) {
    Provider.of<UserProvider>(context, listen: false).swipeLeft(widget.user.id);
    Navigator.of(context).pop();
  }

  Future<void> _handleSuperLike(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final matchedUser = await userProvider.superLike(widget.user.id);
    Navigator.of(context).pop();

    if (matchedUser != null && context.mounted) {
      final currentUser = userProvider.currentUser;
      if (currentUser != null) {
        Navigator.of(context).push(
          PageRouteBuilder(
            opaque: false,
            pageBuilder: (context, animation, secondaryAnimation) {
              return ModernMatchAnimation(
                currentUser: currentUser,
                matchedUser: matchedUser,
                onDismiss: () => Navigator.of(context).pop(),
                onSendMessage: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    CustomPageRoute(
                      child: const ModernChatScreen(),
                      settings: RouteSettings(arguments: matchedUser),
                    ),
                  );
                },
              );
            },
          ),
        );
      }
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You super liked ${widget.user.name}!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  void _showReportDialog(BuildContext context) {
    // Implementation for report dialog
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Report ${widget.user.name}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text('Please select a reason for reporting this profile:'),
            const SizedBox(height: 20),
            ListTile(
              title: const Text('Inappropriate photos'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: const Text('Fake profile / Scam'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: const Text('Offensive behavior'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}