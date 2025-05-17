// lib/screens/achievements_screen.dart - Fixed version
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/user_badge_model.dart';

class AchievementsScreen extends StatelessWidget {
  final List<UserBadge> unlockedBadges;
  final List<UserBadge> availableBadges;

  const AchievementsScreen({
    Key? key,
    required this.unlockedBadges,
    required this.availableBadges,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Achievements'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            TabBar(
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppColors.primary,
              tabs: [
                Tab(text: 'Unlocked (${unlockedBadges.length})'),
                Tab(text: 'Available (${availableBadges.length})'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildBadgeGrid(context, unlockedBadges, true),
                  _buildBadgeGrid(context, availableBadges, false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeGrid(BuildContext context, List<UserBadge> badges, bool isUnlocked) {
    return GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: badges.length,
      itemBuilder: (context, index) {
        final badge = badges[index];
        return _buildBadgeItem(context, badge, isUnlocked);
      },
    );
  }

  Widget _buildBadgeItem(BuildContext context, UserBadge badge, bool isUnlocked) {
    return GestureDetector(
      onTap: () => _showBadgeDetails(context, badge),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isUnlocked ? AppColors.primary.withOpacity(0.1) : Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _getBadgeEmoji(badge.type),
                style: TextStyle(
                  fontSize: 32,
                  color: isUnlocked ? null : Colors.grey,
                ),
              ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            badge.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isUnlocked ? Colors.black : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  String _getBadgeEmoji(UserBadgeType type) {
    switch (type) {
      case UserBadgeType.match:
        return '💘';
      case UserBadgeType.conversation:
        return '💬';
      case UserBadgeType.profile:
        return '⭐';
      case UserBadgeType.premium:
        return '👑';
      case UserBadgeType.achievement:
        return '🏆';
    }
  }

  void _showBadgeDetails(BuildContext context, UserBadge badge) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _getBadgeEmoji(badge.type),
                style: TextStyle(fontSize: 48),
              ),
              SizedBox(height: 16),
              Text(
                badge.name,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                badge.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}