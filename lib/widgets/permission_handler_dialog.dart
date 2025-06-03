// lib/widgets/permission_handler_dialog.dart
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_theme.dart';

class PermissionHandlerDialog {
  static Future<bool> checkAndRequestPermissions(BuildContext context) async {
    // First check current status without requesting
    final cameraStatus = await Permission.camera.status;
    final micStatus = await Permission.microphone.status;

    print('Current permission status - Camera: $cameraStatus, Mic: $micStatus');

    // If both granted, return true
    if (cameraStatus == PermissionStatus.granted &&
        micStatus == PermissionStatus.granted) {
      return true;
    }

    // For iOS, if the permission has never been requested, it won't show in settings
    // So we need to request it at least once
    if (cameraStatus == PermissionStatus.denied || micStatus == PermissionStatus.denied ||
        cameraStatus.isDenied || micStatus.isDenied) {
      // Show explanation and request permissions
      final shouldRequest = await _showExplanationDialog(context);

      if (!shouldRequest) {
        return false;
      }

      // Request permissions - this will make them appear in iOS Settings
      Map<Permission, PermissionStatus> statuses = await [
        Permission.camera,
        Permission.microphone,
      ].request();

      print('Permission request result - Camera: ${statuses[Permission.camera]}, Mic: ${statuses[Permission.microphone]}');

      // Check final status
      bool cameraGranted = statuses[Permission.camera] == PermissionStatus.granted;
      bool micGranted = statuses[Permission.microphone] == PermissionStatus.granted;

      if (cameraGranted && micGranted) {
        return true;
      }

      // If denied after request, they should now appear in settings
      if (!cameraGranted || !micGranted) {
        return await _showSettingsDialog(context, statuses[Permission.camera]!, statuses[Permission.microphone]!);
      }
    }

    // If permanently denied or restricted
    if (cameraStatus == PermissionStatus.permanentlyDenied ||
        micStatus == PermissionStatus.permanentlyDenied ||
        cameraStatus == PermissionStatus.restricted ||
        micStatus == PermissionStatus.restricted) {
      // Show settings dialog
      return await _showSettingsDialog(context, cameraStatus, micStatus);
    }

    return false;
  }

  static Future<bool> _showExplanationDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.video_call,
                color: AppColors.primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text('Enable Video Calling'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'To start video calls, we need access to:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              _buildPermissionItem(
                Icons.videocam,
                'Camera',
                'See and be seen during calls',
              ),
              const SizedBox(height: 8),
              _buildPermissionItem(
                Icons.mic,
                'Microphone',
                'Talk during video calls',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Allow Access'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  static Future<bool> _showSettingsDialog(
      BuildContext context,
      PermissionStatus cameraStatus,
      PermissionStatus micStatus,
      ) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.settings,
                color: Colors.orange,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text('Permission Required'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.videocam_off,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              const Text(
                'Camera and microphone access has been disabled.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Please enable them in your device settings to use video calling.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Settings > Marifecto > Camera & Microphone',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await openAppSettings();
                Navigator.of(context).pop(false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  static Widget _buildPermissionItem(
      IconData icon,
      String title,
      String description,
      ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}