// lib/widgets/components/app_button.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

enum AppButtonType { primary, secondary, text, outline }
enum AppButtonSize { small, medium, large }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final AppButtonType type;
  final AppButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final double? width;

  const AppButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.type = AppButtonType.primary,
    this.size = AppButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.width,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine button styling based on type
    Color backgroundColor;
    Color textColor;
    Color borderColor;
    double elevation;

    switch (type) {
      case AppButtonType.primary:
        backgroundColor = AppColors.primary;
        textColor = Colors.white;
        borderColor = Colors.transparent;
        elevation = 2;
        break;
      case AppButtonType.secondary:
        backgroundColor = AppColors.secondary;
        textColor = Colors.white;
        borderColor = Colors.transparent;
        elevation = 2;
        break;
      case AppButtonType.outline:
        backgroundColor = Colors.transparent;
        textColor = AppColors.primary;
        borderColor = AppColors.primary;
        elevation = 0;
        break;
      case AppButtonType.text:
        backgroundColor = Colors.transparent;
        textColor = AppColors.primary;
        borderColor = Colors.transparent;
        elevation = 0;
        break;
    }

    // Determine button size
    double horizontalPadding;
    double verticalPadding;
    double fontSize;

    switch (size) {
      case AppButtonSize.small:
        horizontalPadding = 16;
        verticalPadding = 8;
        fontSize = 14;
        break;
      case AppButtonSize.medium:
        horizontalPadding = 24;
        verticalPadding = 12;
        fontSize = 16;
        break;
      case AppButtonSize.large:
        horizontalPadding = 32;
        verticalPadding = 16;
        fontSize = 18;
        break;
    }

    // Build the button content
    Widget buttonContent = isLoading
        ? SizedBox(
      width: 24,
      height: 24,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(textColor),
      ),
    )
        : Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, color: textColor),
          const SizedBox(width: 8),
        ],
        Text(
          text,
          style: TextStyle(
            color: textColor,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );

    // Create the button with appropriate styling
    return SizedBox(
      width: isFullWidth ? double.infinity : width,
      child: type == AppButtonType.text
          ? TextButton(
        onPressed: isLoading ? null : onPressed,
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          foregroundColor: textColor,
          textStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: buttonContent,
      )
          : ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: elevation,
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
            side: BorderSide(color: borderColor, width: 1.5),
          ),
        ),
        child: buttonContent,
      ),
    );
  }
}

// Social auth button for login screen
class SocialAuthButton extends StatelessWidget {
  final String text;
  final dynamic icon; // Can be IconData or String (network image URL)
  final Color color;
  final VoidCallback onTap;
  final bool isLoading;
  final bool isAsset;

  const SocialAuthButton({
    Key? key,
    required this.text,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isLoading = false,
    this.isAsset = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 3,
          shadowColor: Colors.black.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(27),
          ),
          disabledBackgroundColor: Colors.white.withOpacity(0.5),
        ),
        child: isLoading
            ? SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isAsset && icon is IconData)
              Icon(icon, size: 22, color: color)
            else if (!isAsset && icon is String)
              Image.network(
                icon,
                width: 22,
                height: 22,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(Icons.error, size: 22, color: color),
              ),
            const SizedBox(width: 12),
            Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Swipe action button for modern_home_screen
class SwipeActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isSuper;
  final double size;

  const SwipeActionButton({
    Key? key,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isSuper = false,
    this.size = 60,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isSuper ? color.withOpacity(0.1) : Colors.white,
          shape: BoxShape.circle,
          border: isSuper ? Border.all(color: color, width: 2) : null,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 8,
              spreadRadius: 2,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: color,
          size: size * 0.4,
        ),
      ),
    );
  }
}

// Gradient button for premium features
class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final double? width;
  final List<Color>? gradientColors;

  const GradientButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.width,
    this.gradientColors,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use default gradient colors if not provided
    final colors = gradientColors ?? [
      AppColors.primary,
      AppColors.secondary,
    ];

    return SizedBox(
      width: isFullWidth ? double.infinity : width,
      height: 54,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          elevation: 3,
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isLoading ? [Colors.grey, Colors.grey.shade400] : colors,
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            alignment: Alignment.center,
            child: isLoading
                ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.white),
                  const SizedBox(width: 8),
                ],
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}