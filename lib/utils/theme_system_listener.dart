// lib/utils/theme_system_listener.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

/// A widget that listens for system theme changes and updates the app's theme
class ThemeSystemListener extends StatefulWidget {
  final Widget child;

  const ThemeSystemListener({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<ThemeSystemListener> createState() => _ThemeSystemListenerState();
}

class _ThemeSystemListenerState extends State<ThemeSystemListener> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initial update
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateThemeWithSystem();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    _updateThemeWithSystem();
  }

  void _updateThemeWithSystem() {
    final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    themeProvider.updateWithSystemTheme(brightness);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}