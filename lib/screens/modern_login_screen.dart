// lib/screens/modern_login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'dart:io';
import '../providers/app_auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/components/app_button.dart';
import '../animations/animations.dart';

class ModernLoginScreen extends StatefulWidget {
  const ModernLoginScreen({Key? key}) : super(key: key);

  @override
  _ModernLoginScreenState createState() => _ModernLoginScreenState();
}

class _ModernLoginScreenState extends State<ModernLoginScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }





  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
      bool success = await authProvider.signInWithGoogle();

      if (success && mounted) {
        // Navigate to main screen
        Navigator.of(context).pushReplacementNamed('/main');
      } else if (!success && mounted) {
        // Check if the error was the PigeonUserDetails issue but user is actually signed in
        if (authProvider.isLoggedIn) {
          // User is actually signed in, navigate to main
          Navigator.of(context).pushReplacementNamed('/main');
        } else {
          // Show error dialog
          _showErrorDialog('Google sign in failed. Please try again.');
        }
      }
    } catch (error) {
      print('Login screen error: $error');
      if (mounted) {
        _showErrorDialog('Failed to sign in with Google: ${error.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }



  Future<void> _handlePhoneSignIn() async {
    if (mounted) {
      Navigator.of(context).pushNamed('/phone-login');
    }
  }

  Future<void> _handleAppleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
      bool success = await authProvider.signInWithApple();

      if (success && mounted) {
        Navigator.of(context).pushReplacementNamed('/main');
      } else {
        _showErrorDialog('Apple sign in failed. Please try again.');
      }
    } catch (error) {
      _showErrorDialog('Failed to sign in with Apple: ${error.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Oops!', style: TextStyle(color: AppColors.primary)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Beautiful background with gradient and pattern
          Container(
            height: size.height,
            width: size.width,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
          ),

          // Decorative circles
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            left: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),

          // Main content
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SafeArea(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      children: [
                        SizedBox(height: size.height * 0.1),

                        // Logo with flame animation
                        FadeInAnimation(
                          delay: const Duration(milliseconds: 300),
                          child: PulseAnimation(
                            duration: const Duration(milliseconds: 2000),
                            autoPlay: true,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: AppShadows.large,
                              ),
                              child: const Icon(
                                Icons.whatshot,
                                size: 60,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // App name with animation
                        FadeInAnimation(
                          delay: const Duration(milliseconds: 500),
                          child: Text(
                            'STILL',
                            style: AppTextStyles.appLogo,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Tagline with animation
                        FadeInAnimation(
                          delay: const Duration(milliseconds: 700),
                          child: Text(
                            'Swipe. Match. Chat.',
                            style: AppTextStyles.appTagline,
                          ),
                        ),

                        SizedBox(height: size.height * 0.08),

                        // Social login buttons with improved design and animations
                        if (Platform.isIOS) ...[
                          FadeInAnimation(
                            delay: const Duration(milliseconds: 900),
                            child: SocialAuthButton(
                              text: 'Continue with Apple',
                              icon: Icons.apple,
                              color: Colors.black,
                              onTap: () => _handleAppleSignIn(),
                              isLoading: _isLoading,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],



                        const SizedBox(height: 16),

                        FadeInAnimation(
                          delay: const Duration(milliseconds: 1300),
                          child: SocialAuthButton(
                            text: 'Continue with Google',
                            icon: 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/800px-Google_%22G%22_logo.svg.png',
                            color: const Color(0xFF4285F4),
                            onTap: () => _handleGoogleSignIn(),
                            isLoading: _isLoading,
                            isAsset: false,
                          ),
                        ),

                        const SizedBox(height: 16),

                        FadeInAnimation(
                          delay: const Duration(milliseconds: 1500),
                          child: SocialAuthButton(
                            text: 'Continue with Phone',
                            icon: Icons.phone_outlined,
                            color: const Color(0xFF25D366),
                            onTap: () => _handlePhoneSignIn(),
                            isLoading: _isLoading,
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Terms and conditions
                        FadeInAnimation(
                          delay: const Duration(milliseconds: 1700),
                          child: Text(
                            'By signing up, you agree to our Terms of Service\nand Privacy Policy',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),




                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Loading overlay
          if (_isLoading)
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: AppShadows.medium,
                    ),
                    child: const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}