import 'package:flutter/material.dart';
class CustomPageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  final RouteSettings settings;

  CustomPageRoute({
    required this.child,
    required this.settings,
  }) : super(
    settings: settings,
    pageBuilder: (context, animation, secondaryAnimation) => child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      const curve = Curves.easeInOut;

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      var offsetAnimation = animation.drive(tween);

      return SlideTransition(
        position: offsetAnimation,
        child: FadeTransition(
          opacity: animation,
          child: child,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
}