// lib/screens/category_users_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';
import '../providers/user_provider.dart';
import '../models/user_model.dart';
import '../widgets/components/loading_indicator.dart';
import '../widgets/components/letter_avatar.dart';
import '../animations/animations.dart';
import '../widgets/user_profile_detail.dart';
import 'explore_screen.dart';

class CategoryUsersScreen extends StatefulWidget {
  final ExploreCategory category;

  const CategoryUsersScreen({
    Key? key,
    required this.category,
  }) : super(key: key);

  @override
  _CategoryUsersScreenState createState() => _CategoryUsersScreenState();
}

class _CategoryUsersScreenState extends State<CategoryUsersScreen> {
  bool _isLoading = true;
  List<User> _categoryUsers = [];
  String _sortBy = 'active'; // active, distance, new
  bool _showOnlineOnly = false;

  @override
  void initState() {
    super.initState();
    _loadCategoryUsers();
  }

  Future<void> _loadCategoryUsers() async {
    setState(() => _isLoading = true);

    try {
      // Simulate loading users with matching interests
      await Future.delayed(const Duration(seconds: 1));

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final allUsers = userProvider.potentialMatches;

      // Filter users by category interests
      _categoryUsers = allUsers.where((user) {
        return user.interests.any((interest) =>
            widget.category.relatedInterests.contains(interest));
      }).toList();

      // Apply sorting
      _sortUsers();
    } catch (e) {
      print('Error loading category users: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _sortUsers() {
    switch (_sortBy) {
      case 'active':
      // In production, sort by last active timestamp
        _categoryUsers.shuffle(); // Simulate randomness
        break;
      case 'distance':
      // In production, sort by actual distance
        _categoryUsers.sort((a, b) => a.location.compareTo(b.location));
        break;
      case 'new':
      // In production, sort by join date
        _categoryUsers = _categoryUsers.reversed.toList();
        break;
    }

    if (_showOnlineOnly) {
      // In production, filter by online status
      _categoryUsers = _categoryUsers.take((_categoryUsers.length * 0.3).round()).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            _buildHeader(isDarkMode),

            // Filter Bar
            _buildFilterBar(isDarkMode),

            // Users Grid
            Expanded(
              child: _isLoading
                  ? const Center(
                child: LoadingIndicator(
                  type: LoadingIndicatorType.pulse,
                  size: LoadingIndicatorSize.large,
                  color: AppColors.primary,
                ),
              )
                  : _buildUsersGrid(isDarkMode),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkSurface : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.arrow_back,
                  color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: widget.category.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    widget.category.emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.category.name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${widget.category.activeUsers} active members',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Category tags
          Row(
            children: widget.category.relatedInterests.map((interest) {
              return Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.category.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: widget.category.color.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  interest,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: widget.category.color,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // Sort dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDarkMode ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                ),
              ],
            ),
            child: DropdownButton<String>(
              value: _sortBy,
              isDense: true,
              underline: const SizedBox(),
              icon: Icon(
                Icons.arrow_drop_down,
                color: AppColors.primary,
              ),
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
              items: [
                DropdownMenuItem(value: 'active', child: Text('Recently Active')),
                DropdownMenuItem(value: 'distance', child: Text('Nearest First')),
                DropdownMenuItem(value: 'new', child: Text('New Members')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _sortBy = value;
                    _sortUsers();
                  });
                }
              },
            ),
          ),
          const SizedBox(width: 12),

          // Online only toggle
          GestureDetector(
            onTap: () {
              setState(() {
                _showOnlineOnly = !_showOnlineOnly;
                _loadCategoryUsers();
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _showOnlineOnly
                    ? AppColors.primary
                    : (isDarkMode ? AppColors.darkCard : Colors.white),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _showOnlineOnly
                        ? AppColors.primary.withOpacity(0.3)
                        : Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _showOnlineOnly
                          ? Colors.white
                          : Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Online Only',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _showOnlineOnly
                          ? Colors.white
                          : (isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),

          // Results count
          Flexible(
            child: Text(
              '${_categoryUsers.length} results',
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersGrid(bool isDarkMode) {
    if (_categoryUsers.isEmpty) {
      return _buildEmptyState(isDarkMode);
    }

    return RefreshIndicator(
      onRefresh: _loadCategoryUsers,
      color: AppColors.primary,
      child: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _categoryUsers.length,
        itemBuilder: (context, index) {
          final user = _categoryUsers[index];
          return FadeInAnimation(
            delay: Duration(milliseconds: index * 50),
            child: _buildUserCard(user, isDarkMode),
          );
        },
      ),
    );
  }

  Widget _buildUserCard(User user, bool isDarkMode) {
    // Check if user shares multiple interests with category
    final sharedInterests = user.interests.where((interest) =>
        widget.category.relatedInterests.contains(interest)).toList();
    final isHighMatch = sharedInterests.length >= 2;

    return GestureDetector(
      onTap: () => _openUserProfile(user),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isHighMatch
                  ? widget.category.color.withOpacity(0.2)
                  : Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: isHighMatch ? 2 : 0,
            ),
          ],
        ),
        child: Stack(
          children: [
            // User image
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: user.imageUrls.isNotEmpty
                  ? CachedNetworkImage(
                imageUrl: user.imageUrls.first,
                fit: BoxFit.cover,
                height: double.infinity,
                width: double.infinity,
              )
                  : Container(
                color: widget.category.color.withOpacity(0.1),
                child: Center(
                  child: Text(
                    user.name.isNotEmpty ? user.name[0] : '?',
                    style: TextStyle(
                      color: widget.category.color,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            // Gradient overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                    ],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
            ),

            // High match badge
            if (isHighMatch)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.category.color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_fire_department,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'HIGH MATCH',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Online indicator
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
              ),
            ),

            // User info
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${user.name}, ${user.age}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.white70,
                        size: 14,
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          user.location,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (sharedInterests.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: sharedInterests.take(2).map((interest) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            interest,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: widget.category.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                widget.category.emoji,
                style: const TextStyle(fontSize: 48),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No ${widget.category.name} found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later or adjust your filters',
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _loadCategoryUsers,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.category.color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openUserProfile(User user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileDetail(user: user),
      ),
    );
  }
}