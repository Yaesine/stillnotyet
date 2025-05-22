// lib/widgets/components/letter_avatar.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class LetterAvatar extends StatelessWidget {
  final String name;
  final double size;
  final List<String>? imageUrls;
  final Color? backgroundColor;
  final Color? textColor;
  final BoxFit fit;
  final bool showBorder;

  const LetterAvatar({
    Key? key,
    required this.name,
    this.size = 40,
    this.imageUrls,
    this.backgroundColor,
    this.textColor,
    this.fit = BoxFit.cover,
    this.showBorder = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Determine if we have a valid image URL to display
    final hasValidImage = imageUrls != null &&
        imageUrls!.isNotEmpty &&
        imageUrls![0].isNotEmpty;

    // Get the first letter of the name, defaulting to '?' if name is empty
    final letter = name.isNotEmpty ? name[0].toUpperCase() : '?';

    // Create a deterministic color based on the name
    final Color avatarColor = backgroundColor ?? _getColorFromName(name);
    final borderColor = isDarkMode ? Colors.black : Colors.white;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: showBorder ? Border.all(
          color: borderColor,
          width: size / 30,
        ) : null,
        boxShadow: showBorder ? [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: hasValidImage
            ? Image.network(
          imageUrls![0],
          fit: fit,
          errorBuilder: (context, url, error) => _buildLetterAvatar(letter, avatarColor),
        )
            : _buildLetterAvatar(letter, avatarColor),
      ),
    );
  }

  Widget _buildLetterAvatar(String letter, Color bgColor) {
    return Container(
      color: bgColor,
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          color: textColor ?? Colors.white,
          fontSize: size * 0.4,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Generate a color based on the name string
  Color _getColorFromName(String name) {
    if (name.isEmpty) return AppColors.primary;

    // Create a simple hash of the name
    int hash = 0;
    for (var i = 0; i < name.length; i++) {
      hash = name.codeUnitAt(i) + ((hash << 5) - hash);
    }

    // Convert hash to a color
    final List<Color> colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.tertiary,
      Colors.blue,
      Colors.purple,
      Colors.teal,
      Colors.amber,
      Colors.indigo,
      Colors.pink,
    ];

    return colors[hash.abs() % colors.length];
  }
}