// lib/widgets/components/loading_indicator.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

enum LoadingIndicatorType { circular, linear, pulse }
enum LoadingIndicatorSize { small, medium, large }

class LoadingIndicator extends StatefulWidget {
  final LoadingIndicatorType type;
  final LoadingIndicatorSize size;
  final Color? color;
  final String? message;

  const LoadingIndicator({
    Key? key,
    this.type = LoadingIndicatorType.circular,
    this.size = LoadingIndicatorSize.medium,
    this.color,
    this.message,
  }) : super(key: key);

  @override
  State<LoadingIndicator> createState() => _LoadingIndicatorState();
}

class _LoadingIndicatorState extends State<LoadingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller for pulse effect
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    // For pulse animation, repeat indefinitely
    if (widget.type == LoadingIndicatorType.pulse) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color indicatorColor = widget.color ?? AppColors.primary;

    // Determine dimensions based on size
    double diameter;
    double strokeWidth;
    double textSize;

    switch (widget.size) {
      case LoadingIndicatorSize.small:
        diameter = 24;
        strokeWidth = 2;
        textSize = 12;
        break;
      case LoadingIndicatorSize.medium:
        diameter = 40;
        strokeWidth = 3;
        textSize = 14;
        break;
      case LoadingIndicatorSize.large:
        diameter = 60;
        strokeWidth = 4;
        textSize = 16;
        break;
    }

    Widget indicator;

    // Build appropriate indicator based on type
    switch (widget.type) {
      case LoadingIndicatorType.circular:
        indicator = SizedBox(
          width: diameter,
          height: diameter,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
            strokeWidth: strokeWidth,
          ),
        );
        break;

      case LoadingIndicatorType.linear:
        indicator = SizedBox(
          width: diameter * 4,
          height: strokeWidth * 2,
          child: LinearProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
            backgroundColor: indicatorColor.withOpacity(0.2),
          ),
        );
        break;

      case LoadingIndicatorType.pulse:
        indicator = AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: diameter,
                height: diameter,
                decoration: BoxDecoration(
                  color: indicatorColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.favorite,
                  color: indicatorColor,
                  size: diameter * 0.6,
                ),
              ),
            );
          },
        );
        break;
    }

    // Return indicator with optional message
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        indicator,
        if (widget.message != null) ...[
          const SizedBox(height: 16),
          Text(
            widget.message!,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: textSize,
            ),
          ),
        ],
      ],
    );
  }
}
