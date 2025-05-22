// lib/widgets/components/theme_switcher.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'dart:io' show Platform;
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';

class ThemeSwitcher extends StatelessWidget {
  const ThemeSwitcher({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Determine which icon to show based on theme and platform
    IconData getThemeIcon() {
      if (themeProvider.followSystem) {
        return Icons.brightness_auto;
      } else if (themeProvider.isDarkMode) {
        return Icons.dark_mode;
      } else {
        return Icons.light_mode;
      }
    }

    // Build iOS-style segmented control
    if (Platform.isIOS) {
      // Calculate which segment is selected
      int currentSegment = themeProvider.followSystem
          ? 0
          : (themeProvider.isDarkMode ? 2 : 1);

      return CupertinoSlidingSegmentedControl<int>(
        thumbColor: isDarkMode
            ? AppColors.darkElevated
            : Colors.white,
        backgroundColor: isDarkMode
            ? AppColors.darkCard
            : Colors.grey.shade200,
        children: {
          0: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Icon(
              Icons.brightness_auto,
              color: currentSegment == 0
                  ? AppColors.primary
                  : isDarkMode
                  ? AppColors.darkTextSecondary
                  : Colors.grey.shade700,
            ),
          ),
          1: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Icon(
              Icons.light_mode,
              color: currentSegment == 1
                  ? AppColors.primary
                  : isDarkMode
                  ? AppColors.darkTextSecondary
                  : Colors.grey.shade700,
            ),
          ),
          2: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Icon(
              Icons.dark_mode,
              color: currentSegment == 2
                  ? AppColors.primary
                  : isDarkMode
                  ? AppColors.darkTextSecondary
                  : Colors.grey.shade700,
            ),
          ),
        },
        groupValue: currentSegment,
        onValueChanged: (int? value) {
          if (value == 0) {
            // System
            themeProvider.setFollowSystem(true);
          } else if (value == 1) {
            // Light
            themeProvider.setFollowSystem(false);
            if (themeProvider.isDarkMode) {
              themeProvider.toggleTheme();
            }
          } else if (value == 2) {
            // Dark
            themeProvider.setFollowSystem(false);
            if (!themeProvider.isDarkMode) {
              themeProvider.toggleTheme();
            }
          }
        },
      );
    }

    // For Android, use a more material design approach
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDarkMode
            ? AppShadows.darkSmall
            : AppShadows.small,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Auto (System) button
          _buildIconButton(
            context: context,
            icon: Icons.brightness_auto,
            isSelected: themeProvider.followSystem,
            onTap: () => themeProvider.setFollowSystem(true),
          ),

          // Light theme button
          _buildIconButton(
            context: context,
            icon: Icons.light_mode,
            isSelected: !themeProvider.followSystem && !themeProvider.isDarkMode,
            onTap: () {
              themeProvider.setFollowSystem(false);
              if (themeProvider.isDarkMode) {
                themeProvider.toggleTheme();
              }
            },
          ),

          // Dark theme button
          _buildIconButton(
            context: context,
            icon: Icons.dark_mode,
            isSelected: !themeProvider.followSystem && themeProvider.isDarkMode,
            onTap: () {
              themeProvider.setFollowSystem(false);
              if (!themeProvider.isDarkMode) {
                themeProvider.toggleTheme();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required BuildContext context,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withOpacity(0.2)
                : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isSelected
                ? AppColors.primary
                : isDarkMode
                ? AppColors.darkTextSecondary
                : Colors.grey.shade600,
            size: 24,
          ),
        ),
      ),
    );
  }
}

// Simplified version that can be used in places where space is limited
class SimplifiedThemeSwitch extends StatelessWidget {
  const SimplifiedThemeSwitch({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Skip the system option for simplicity
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isDarkMode ? Icons.dark_mode : Icons.light_mode,
          color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
          size: 20,
        ),
        const SizedBox(width: 8),
        Platform.isIOS
            ? CupertinoSwitch(
          value: themeProvider.isDarkMode,
          activeColor: AppColors.primary,
          onChanged: (value) {
            themeProvider.setFollowSystem(false);
            if (themeProvider.isDarkMode != value) {
              themeProvider.toggleTheme();
            }
          },
        )
            : Switch(
          value: themeProvider.isDarkMode,
          activeColor: AppColors.primary,
          onChanged: (value) {
            themeProvider.setFollowSystem(false);
            if (themeProvider.isDarkMode != value) {
              themeProvider.toggleTheme();
            }
          },
        ),
      ],
    );
  }
}

// A theme mode selector with labels - good for settings pages
class LabeledThemeSelector extends StatelessWidget {
  const LabeledThemeSelector({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Appearance',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),

        // System setting
        _buildOptionTile(
          context: context,
          title: 'System',
          subtitle: 'Follow device theme',
          icon: Icons.brightness_auto,
          isSelected: themeProvider.followSystem,
          onTap: () => themeProvider.setFollowSystem(true),
        ),

        const SizedBox(height: 8),

        // Light mode
        _buildOptionTile(
          context: context,
          title: 'Light',
          subtitle: 'Light theme always',
          icon: Icons.light_mode,
          isSelected: !themeProvider.followSystem && !themeProvider.isDarkMode,
          onTap: () {
            themeProvider.setFollowSystem(false);
            if (themeProvider.isDarkMode) {
              themeProvider.toggleTheme();
            }
          },
        ),

        const SizedBox(height: 8),

        // Dark mode
        _buildOptionTile(
          context: context,
          title: 'Dark',
          subtitle: 'Dark theme always',
          icon: Icons.dark_mode,
          isSelected: !themeProvider.followSystem && themeProvider.isDarkMode,
          onTap: () {
            themeProvider.setFollowSystem(false);
            if (!themeProvider.isDarkMode) {
              themeProvider.toggleTheme();
            }
          },
        ),
      ],
    );
  }

  Widget _buildOptionTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  color: isSelected
                      ? AppColors.primary.withOpacity(0.2)
                      : isDarkMode
                      ? AppColors.darkElevated
                      : Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isSelected
                      ? AppColors.primary
                      : isDarkMode
                      ? AppColors.darkTextSecondary
                      : Colors.grey.shade700,
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
                ),
            ],
          ),
        ),
      ),
    );
  }
}