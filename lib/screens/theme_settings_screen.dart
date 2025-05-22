// lib/screens/theme_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'dart:io' show Platform;
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';

class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final brightness = Theme.of(context).brightness;
    final isDarkMode = brightness == Brightness.dark;

    // Get the appropriate styles for the current theme
    final titleStyle = AppTextStyles.getStyle(
        TextStyleType.headline3,
        brightness
    );

    final subtitleStyle = AppTextStyles.getStyle(
        TextStyleType.body2,
        brightness
    ).copyWith(
        color: isDarkMode
            ? AppColors.darkTextSecondary
            : AppColors.textSecondary
    );

    // Use platform-specific widgets for a more native feel
    return Scaffold(
      appBar: AppBar(
        title: Text('Appearance'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Theme selection section
            Text('Theme', style: titleStyle),
            const SizedBox(height: 8),
            Text(
                'Choose how STILL looks on your device',
                style: subtitleStyle
            ),
            const SizedBox(height: 16),

            // Follow system setting
            _buildThemeOption(
              context: context,
              title: 'System',
              subtitle: 'Follows your device settings',
              isSelected: themeProvider.followSystem,
              icon: Icons.brightness_auto,
              onTap: () {
                themeProvider.setFollowSystem(true);
              },
            ),

            const SizedBox(height: 12),

            // Light theme option
            _buildThemeOption(
              context: context,
              title: 'Light',
              subtitle: 'Light background with dark text',
              isSelected: !themeProvider.followSystem && !themeProvider.isDarkMode,
              icon: Icons.wb_sunny_outlined,
              onTap: () {
                if (themeProvider.isDarkMode || themeProvider.followSystem) {
                  themeProvider.setFollowSystem(false);
                  if (themeProvider.isDarkMode) {
                    themeProvider.toggleTheme();
                  }
                }
              },
            ),

            const SizedBox(height: 12),

            // Dark theme option
            _buildThemeOption(
              context: context,
              title: 'Dark',
              subtitle: 'Dark background with light text',
              isSelected: !themeProvider.followSystem && themeProvider.isDarkMode,
              icon: Icons.nightlight_round,
              onTap: () {
                themeProvider.setFollowSystem(false);
                if (!themeProvider.isDarkMode) {
                  themeProvider.toggleTheme();
                }
              },
            ),

            const SizedBox(height: 32),

            // Preview section
            Text('Preview', style: titleStyle),
            const SizedBox(height: 24),

            // Theme preview
            _buildThemePreview(context),

            const SizedBox(height: 32),

            // iOS-style note about additional settings
            if (Platform.isIOS)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? AppColors.darkCard
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: isDarkMode
                      ? Border.all(color: AppColors.darkDivider)
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.info_circle,
                          color: isDarkMode
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Note',
                          style: AppTextStyles.getStyle(
                              TextStyleType.subtitle2,
                              brightness
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Using system setting will automatically switch themes when your device switches between Light and Dark mode.',
                      style: subtitleStyle,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'You can change your iOS device appearance in Settings > Display & Brightness.',
                      style: subtitleStyle,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    required bool isSelected,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : isDarkMode
                  ? AppColors.darkDivider
                  : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
            color: isSelected
                ? AppColors.primary.withOpacity(0.1)
                : isDarkMode
                ? AppColors.darkCard
                : Colors.white,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? AppColors.primary.withOpacity(0.2)
                      : isDarkMode
                      ? AppColors.darkElevated
                      : Colors.grey.shade100,
                ),
                child: Icon(
                  icon,
                  color: isSelected
                      ? AppColors.primary
                      : isDarkMode
                      ? AppColors.darkTextSecondary
                      : Colors.grey.shade600,
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
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? AppColors.primary
                            : isDarkMode
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: isSelected
                            ? AppColors.primary.withOpacity(0.8)
                            : isDarkMode
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: AppColors.primary,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemePreview(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode
              ? AppColors.darkDivider
              : Colors.grey.shade300,
        ),
        color: isDarkMode ? AppColors.darkBackground : AppColors.background,
      ),
      child: Column(
        children: [
          // App bar simulation
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDarkMode ? AppColors.darkSurface : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDarkMode
                      ? AppColors.darkDivider
                      : Colors.grey.shade200,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.arrow_back,
                  color: isDarkMode
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                  size: 20,
                ),
                const Spacer(),
                Text(
                  'STILL',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.more_vert,
                  color: isDarkMode
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                  size: 20,
                ),
              ],
            ),
          ),

          // Content preview
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withOpacity(0.2),
                    ),
                    child: Icon(
                      Icons.favorite,
                      color: AppColors.primary,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Theme Preview',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}