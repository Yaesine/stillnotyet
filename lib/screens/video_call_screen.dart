// lib/screens/video_call_screen.dart
import 'package:flutter/material.dart';
import '../screens/agora_one_on_one_call_screen.dart';
import '../theme/app_theme.dart';

class VideoCallScreen extends StatelessWidget {
  const VideoCallScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Video Chat',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isDarkMode ? AppColors.darkSurface : Colors.white,
        foregroundColor: isDarkMode ? AppColors.darkTextPrimary : Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: const AgoraOneOnOneCallScreen(),
    );
  }
}