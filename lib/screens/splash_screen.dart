// lib/screens/splash_screen.dart - ENHANCED DARK THEME VERSION

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_auth_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  bool _animationStarted = false;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller and animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    // Begin animation as soon as widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_animationStarted) {
        setState(() {
          _animationStarted = true;
        });
        _animationController.forward();

        // Set reasonable navigation timeout
        Future.delayed(Duration(milliseconds: 1500), () {
          _navigateToNextScreen();
        });
      }
    });

    // Start auth initialization in background without blocking
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
      // Non-blocking auth initialization
      authProvider.initializeAuth();
    } catch (e) {
      print('Background auth initialization error: $e');
    }
  }

  void _navigateToNextScreen() {
    if (!mounted) return;

    final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
    if (authProvider.isLoggedIn) {
      Navigator.pushReplacementNamed(context, '/main');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get the current brightness from the theme
    final brightness = Theme.of(context).brightness;
    final isDarkMode = brightness == Brightness.dark;

    // Define gradient colors based on theme
    final List<Color> gradientColors = isDarkMode
        ? [
      AppColors.darkBackground, // Dark background
      Color(0xFF302428), // Dark reddish tint
    ]
        : [
      AppColors.primary, // Tinder red
      AppColors.secondary, // Orange gradient
    ];

    // Icon and text colors based on theme
    final Color iconColor = isDarkMode ? AppColors.primary : Colors.red;
    final Color textColor = Colors.white;
    final Color containerColor = isDarkMode ? AppColors.darkCard : Colors.white;
    final List<BoxShadow> containerShadows = isDarkMode
        ? AppShadows.darkMedium
        : AppShadows.medium;

    return Scaffold(
      backgroundColor: gradientColors[0],
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gradientColors,
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo Animation
                  Opacity(
                    opacity: _opacityAnimation.value,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: containerColor,
                          boxShadow: containerShadows,
                        ),
                        child: Icon(
                          Icons.whatshot,
                          color: iconColor,
                          size: 80,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // App Name
                  Opacity(
                    opacity: _opacityAnimation.value,
                    child: Text(
                      'Marifecto',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        letterSpacing: 8.0,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Tagline with fade-in effect
                  Opacity(
                    opacity: _opacityAnimation.value,
                    child: Text(
                      'Swipe. Match. Chat.',
                      style: TextStyle(
                        fontSize: 18,
                        color: textColor,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}