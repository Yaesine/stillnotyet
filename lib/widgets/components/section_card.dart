// lib/widgets/components/section_card.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Color? iconColor;
  final Widget? action;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  const SectionCard({
    Key? key,
    required this.title,
    required this.icon,
    required this.child,
    this.iconColor,
    this.action,
    this.onTap,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color effectiveIconColor = iconColor ?? AppColors.primary;

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: effectiveIconColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: effectiveIconColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  const Spacer(),
                  if (action != null) action!,
                ],
              ),
            ),

            const Divider(),

            // Section content
            Padding(
              padding: padding ?? const EdgeInsets.all(16),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}