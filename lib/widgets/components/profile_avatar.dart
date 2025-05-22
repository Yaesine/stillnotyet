// lib/widgets/components/profile_avatar.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'letter_avatar.dart';

enum ProfileAvatarStatus { online, offline, away, none }

class ProfileAvatar extends StatelessWidget {
  final String imageUrl;
  final String userName; // Added userName parameter
  final double size;
  final ProfileAvatarStatus status;
  final VoidCallback? onTap;
  final bool isEditable;

  const ProfileAvatar({
    Key? key,
    required this.imageUrl,
    required this.userName, // Made userName a required parameter
    this.size = 60,
    this.status = ProfileAvatarStatus.none,
    this.onTap,
    this.isEditable = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get status color
    Color statusColor;
    switch (status) {
      case ProfileAvatarStatus.online:
        statusColor = AppColors.secondary;
        break;
      case ProfileAvatarStatus.offline:
        statusColor = Colors.grey;
        break;
      case ProfileAvatarStatus.away:
        statusColor = Colors.amber;
        break;
      case ProfileAvatarStatus.none:
        statusColor = Colors.transparent;
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          // Profile image or letter avatar
          LetterAvatar(
            name: userName,
            size: size,
            imageUrls: imageUrl.isNotEmpty ? [imageUrl] : null,
            showBorder: true,
          ),

          // Status indicator
          if (status != ProfileAvatarStatus.none)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: size / 4,
                height: size / 4,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: size / 30,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      spreadRadius: 0,
                    ),
                  ],
                ),
              ),
            ),

          // Edit indicator
          if (isEditable)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: size / 3,
                height: size / 3,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: size / 30,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.edit,
                  color: Colors.white,
                  size: size / 5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}