// lib/widgets/components/interest_chip.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class InterestChip extends StatelessWidget {
  final String label;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const InterestChip({
    Key? key,
    required this.label,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.onTap,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? AppColors.primary.withOpacity(0.1);
    final txtColor = textColor ?? AppColors.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: txtColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: txtColor,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: txtColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (onDelete != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onDelete,
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: txtColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}