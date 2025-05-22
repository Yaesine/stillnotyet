// animations.dart
import 'package:flutter/material.dart';

// Fade-in animation for list items
class FadeInAnimationList extends StatelessWidget {
  final List<Widget> children;
  final Duration baseDelay;
  final Duration stepDelay;

  const FadeInAnimationList({
    Key? key,
    required this.children,
    this.baseDelay = const Duration(milliseconds: 100),
    this.stepDelay = const Duration(milliseconds: 50),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: children.length,
      itemBuilder: (context, index) {
        return FadeInAnimation(
          delay: baseDelay + (stepDelay * index),
          child: children[index],
        );
      },
    );
  }
}

// Fade-in animation for a single widget
class FadeInAnimation extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;

  const FadeInAnimation({
    Key? key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 500),
  }) : super(key: key);

  @override
  _FadeInAnimationState createState() => _FadeInAnimationState();
}

class _FadeInAnimationState extends State<FadeInAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: widget.child,
    );
  }
}

// Pulse animation for likes/matches
class PulseAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final bool autoPlay;

  const PulseAnimation({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.autoPlay = true,
  }) : super(key: key);

  @override
  _PulseAnimationState createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    if (widget.autoPlay) {
      _playAnimation();
    }
  }

  void _playAnimation() async {
    await _controller.forward();
    await _controller.reverse();
    if (mounted && widget.autoPlay) {
      _playAnimation();
    }
  }

  void play() {
    _controller.reset();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: widget.child,
        );
      },
    );
  }
}

// Page transition for navigating between screens
class SlidePageRoute extends PageRouteBuilder {
  final Widget page;
  final AxisDirection direction;

  SlidePageRoute({
    required this.page,
    this.direction = AxisDirection.right,
  }) : super(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      Offset begin;

      switch (direction) {
        case AxisDirection.up:
          begin = const Offset(0, 1);
          break;
        case AxisDirection.down:
          begin = const Offset(0, -1);
          break;
        case AxisDirection.right:
          begin = const Offset(-1, 0);
          break;
        case AxisDirection.left:
          begin = const Offset(1, 0);
          break;
      }

      const end = Offset.zero;
      const curve = Curves.ease;

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      var offsetAnimation = animation.drive(tween);

      return SlideTransition(
        position: offsetAnimation,
        child: child,
      );
    },
  );
}