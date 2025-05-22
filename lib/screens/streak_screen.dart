// lib/screens/streak_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StreakScreen extends StatelessWidget {
  final int streakCount;
  final int rewindCount;
  final int superLikeCount;

  const StreakScreen({
    Key? key,
    required this.streakCount,
    required this.rewindCount,
    required this.superLikeCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Daily Streak'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Streak counter
            Text(
              '$streakCount',
              style: TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            Text(
              'Day Streak',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 32),

            // Streak benefits
            Text(
              'Keep your streak to unlock daily rewards!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 32),

            // Daily rewards
            _buildRewardCard(
              'Super Likes',
              superLikeCount.toString(),
              Icons.star,
              Colors.blue,
            ),
            SizedBox(height: 16),
            _buildRewardCard(
              'Rewinds',
              rewindCount.toString(),
              Icons.replay,
              Colors.orange,
            ),

            Spacer(),

            // Reminder
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.primary),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Log in tomorrow to continue your streak!',
                      style: TextStyle(color: AppColors.primary),
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

  Widget _buildRewardCard(String title, String count, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Available: $count',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}