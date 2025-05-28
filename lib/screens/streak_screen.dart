// lib/screens/streak_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:confetti/confetti.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';
import '../providers/user_provider.dart';
import '../services/streak_service.dart';

class StreakScreen extends StatefulWidget {
  final int? initialStreakCount;
  final int? initialRewindCount;
  final int? initialSuperLikeCount;

  const StreakScreen({
    Key? key,
    this.initialStreakCount,
    this.initialRewindCount,
    this.initialSuperLikeCount,
  }) : super(key: key);

  @override
  _StreakScreenState createState() => _StreakScreenState();
}

class _StreakScreenState extends State<StreakScreen> with TickerProviderStateMixin {
  late AnimationController _streakAnimationController;
  late AnimationController _pulseAnimationController;
  late AnimationController _slideAnimationController;
  late AnimationController _sparkleAnimationController;
  late AnimationController _rewardAnimationController;
  late Animation<double> _streakScaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _sparkleAnimation;
  late Animation<double> _rewardScaleAnimation;
  late ConfettiController _confettiController;

  // Streak data
  int _currentStreak = 0;
  int _longestStreak = 0;
  int _totalDaysActive = 0;
  DateTime? _lastActiveDate;
  List<DateTime> _weekActivity = [];

  // Rewards
  int _availableRewinds = 0;
  int _availableSuperLikes = 0;
  int _availableBoosts = 0;

  // Milestones
  final List<int> _milestones = [3, 7, 14, 30, 50, 100];
  int _nextMilestone = 3;

  bool _isLoading = true;
  bool _hasClaimedToday = false;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _streakAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _sparkleAnimationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _rewardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Initialize animations
    _streakScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _streakAnimationController,
      curve: Curves.elasticOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _pulseAnimationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _sparkleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_sparkleAnimationController);

    _rewardScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rewardAnimationController,
      curve: Curves.elasticOut,
    ));

    // Initialize confetti
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));

    // Load streak data
    _loadStreakData();
  }

  @override
  void dispose() {
    _streakAnimationController.dispose();
    _pulseAnimationController.dispose();
    _slideAnimationController.dispose();
    _sparkleAnimationController.dispose();
    _rewardAnimationController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadStreakData() async {
    try {
      // Use the StreakService to load data
      final streakService = StreakService();
      final streakData = await streakService.getStreakData();

      if (streakData != null) {
        setState(() {
          _currentStreak = streakData.currentStreak;
          _longestStreak = streakData.longestStreak;
          _totalDaysActive = streakData.totalDaysActive;
          _lastActiveDate = streakData.lastActiveDate;
          _availableRewinds = streakData.availableRewinds;
          _availableSuperLikes = streakData.availableSuperLikes;
          _availableBoosts = streakData.availableBoosts;
          _hasClaimedToday = streakData.claimedToday;
          _weekActivity = streakData.weekActivity;

          // Calculate next milestone using service
          _nextMilestone = streakService.getNextMilestone(_currentStreak);
        });
      } else {
        // Initialize with provided values or defaults
        setState(() {
          _currentStreak = widget.initialStreakCount ?? 0;
          _availableRewinds = widget.initialRewindCount ?? 1;
          _availableSuperLikes = widget.initialSuperLikeCount ?? 1;
          _nextMilestone = 3;
        });
      }

      setState(() {
        _isLoading = false;
      });

      // Start animations
      _streakAnimationController.forward();
      _slideAnimationController.forward();
      _rewardAnimationController.forward();

    } catch (e) {
      print('Error loading streak data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _claimDailyReward() async {
    if (_hasClaimedToday) return;

    // Haptic feedback
    HapticFeedback.heavyImpact();

    try {
      // Use the StreakService to update streak
      final streakService = StreakService();
      final result = await streakService.checkAndUpdateStreak();

      if (result.success && result.streakData != null) {
        setState(() {
          _currentStreak = result.streakData!.currentStreak;
          _longestStreak = result.streakData!.longestStreak;
          _totalDaysActive = result.streakData!.totalDaysActive;
          _lastActiveDate = result.streakData!.lastActiveDate;
          _availableRewinds = result.streakData!.availableRewinds;
          _availableSuperLikes = result.streakData!.availableSuperLikes;
          _availableBoosts = result.streakData!.availableBoosts;
          _hasClaimedToday = result.streakData!.claimedToday;
          _weekActivity = result.streakData!.weekActivity;

          // Update next milestone
          _nextMilestone = streakService.getNextMilestone(_currentStreak);
        });

        // Show streak broken message if needed
        if (result.streakBroken) {
          _showStreakBrokenMessage();
        }

        // Check for milestone
        if (result.isMilestone) {
          _showMilestoneAchievement();
          _confettiController.play();
        }

        // Show regular reward claimed message
        if (!result.streakBroken && !result.isMilestone) {
          _showRewardClaimedMessage(result.rewards ?? []);
        }

        // Animate
        _streakAnimationController.reset();
        _streakAnimationController.forward();
        _rewardAnimationController.reset();
        _rewardAnimationController.forward();
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error claiming daily reward: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error claiming reward. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showStreakBrokenMessage() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkCard
                : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.heart_broken,
                  color: Colors.red,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Streak Broken!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your streak has been reset to Day 1',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Start Fresh',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRewardClaimedMessage(List<dynamic> rewards) {
    // Count total rewards
    int totalSuperLikes = 0;
    int totalRewinds = 0;
    int totalBoosts = 0;

    for (var reward in rewards) {
      if (reward.type.toString().contains('superLike')) {
        totalSuperLikes += (reward.amount as int?) ?? 0;
      } else if (reward.type.toString().contains('rewind')) {
        totalRewinds += (reward.amount as int?) ?? 0;
      } else if (reward.type.toString().contains('boost')) {
        totalBoosts += (reward.amount as int?) ?? 0;
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.celebration, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Daily rewards claimed! +$totalSuperLikes Super Likes, +$totalRewinds Rewinds${totalBoosts > 0 ? ', +$totalBoosts Boosts' : ''}',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.tertiary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showMilestoneAchievement() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.secondary,
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.5),
                blurRadius: 30,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.celebration,
                      color: Colors.white,
                      size: 60,
                    ),
                    ...List.generate(
                      6,
                          (index) => Transform.rotate(
                        angle: (index * 60) * math.pi / 180,
                        child: Transform.translate(
                          offset: Offset(0, -40),
                          child: Icon(
                            Icons.star,
                            color: Colors.white.withOpacity(0.7),
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'MILESTONE UNLOCKED!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '$_currentStreak DAY STREAK',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2,
                  shadows: [
                    Shadow(
                      blurRadius: 20,
                      color: Colors.black.withOpacity(0.3),
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  '🎁 Bonus rewards unlocked!',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'CLAIM',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.darkBackground : Colors.grey[50],
      body: Stack(
        children: [
          // Animated background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDarkMode
                    ? [
                  AppColors.darkBackground,
                  AppColors.darkSurface,
                  Color(0xFF1A1A2E),
                ]
                    : [
                  Color(0xFFFFF5F5),
                  Color(0xFFFFE5E5),
                  Color(0xFFFFD6D6),
                ],
              ),
            ),
          ),

          // Floating shapes animation
          ..._buildFloatingShapes(),

          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: math.pi / 2,
              emissionFrequency: 0.05,
              numberOfParticles: 30,
              maxBlastForce: 100,
              minBlastForce: 80,
              gravity: 0.2,
              colors: const [
                AppColors.primary,
                AppColors.secondary,
                Colors.yellow,
                Colors.orange,
                Colors.pink,
                Colors.purple,
              ],
            ),
          ),

          // Main content
          SafeArea(
            child: _isLoading
                ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
                : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Custom App Bar
                SliverAppBar(
                  expandedHeight: 60,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  pinned: true,
                  flexibleSpace: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          isDarkMode
                              ? AppColors.darkBackground.withOpacity(0.9)
                              : Colors.white.withOpacity(0.9),
                          isDarkMode
                              ? AppColors.darkBackground.withOpacity(0.7)
                              : Colors.white.withOpacity(0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: FlexibleSpaceBar(
                      titlePadding: EdgeInsets.zero,
                      centerTitle: true,
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.local_fire_department,
                            color: AppColors.primary,
                            size: 28,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Daily Streak',
                            style: TextStyle(
                              color: isDarkMode
                                  ? AppColors.darkTextPrimary
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? AppColors.darkCard.withOpacity(0.5)
                              : Colors.white.withOpacity(0.8),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.info_outline,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      onPressed: _showStreakInfo,
                    ),
                  ],
                ),

                // Content
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Streak counter with enhanced design
                        _buildEnhancedStreakCounter(),

                        const SizedBox(height: 40),

                        // Progress to next milestone
                        _buildEnhancedMilestoneProgress(),

                        const SizedBox(height: 32),

                        // Week activity with modern design
                        _buildEnhancedWeekActivity(),

                        const SizedBox(height: 32),

                        // Stats cards with gradients
                        _buildEnhancedStatsCards(),

                        const SizedBox(height: 32),

                        // Rewards section with animations
                        _buildEnhancedRewardsSection(),

                        const SizedBox(height: 40),

                        // Claim button with gradient
                        _buildEnhancedClaimButton(),

                        const SizedBox(height: 24),

                        // Motivational message with icon
                        _buildEnhancedMotivationalMessage(),

                        const SizedBox(height: 40),

                        // Milestones section with timeline
                        _buildEnhancedMilestonesSection(),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFloatingShapes() {
    return List.generate(5, (index) {
      final random = math.Random(index);
      final size = 40.0 + random.nextDouble() * 60;
      final left = random.nextDouble() * 300;
      final top = random.nextDouble() * 600;

      return Positioned(
        left: left,
        top: top,
        child: AnimatedBuilder(
          animation: _sparkleAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(
                math.sin(_sparkleAnimation.value * 2 * math.pi) * 20,
                math.cos(_sparkleAnimation.value * 2 * math.pi) * 20,
              ),
              child: Opacity(
                opacity: 0.1 + (_sparkleAnimation.value * 0.2),
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.3),
                        AppColors.secondary.withOpacity(0.3),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildEnhancedStreakCounter() {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ScaleTransition(
      scale: _streakScaleAnimation,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _hasClaimedToday ? 1.0 : _pulseAnimation.value,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    AppColors.secondary,
                    AppColors.primary.withOpacity(0.8),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.5),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                  BoxShadow(
                    color: AppColors.secondary.withOpacity(0.3),
                    blurRadius: 60,
                    spreadRadius: 20,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Animated circular progress
                  SizedBox(
                    width: 210,
                    height: 210,
                    child: CircularProgressIndicator(
                      value: _currentStreak / _nextMilestone,
                      strokeWidth: 12,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  // Inner circle with gradient
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(0.15),
                          Colors.white.withOpacity(0.05),
                        ],
                      ),
                    ),
                  ),
                  // Streak content
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_currentStreak >= 7)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.local_fire_department,
                                color: Colors.white,
                                size: 16,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'ON FIRE',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (_currentStreak >= 7) const SizedBox(height: 8),
                      Text(
                        '$_currentStreak',
                        style: const TextStyle(
                          fontSize: 72,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1,
                          shadows: [
                            Shadow(
                              blurRadius: 20,
                              color: Colors.black26,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                      const Text(
                        'DAYS',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white70,
                          letterSpacing: 3,
                        ),
                      ),
                    ],
                  ),
                  // Sparkle effects
                  if (_currentStreak > 0)
                    ...List.generate(
                      8,
                          (index) => Transform.rotate(
                        angle: (index * 45) * math.pi / 180,
                        child: Transform.translate(
                          offset: Offset(0, -90),
                          child: AnimatedBuilder(
                            animation: _sparkleAnimation,
                            builder: (context, child) {
                              return Opacity(
                                opacity: (math.sin(_sparkleAnimation.value * 2 * math.pi + index) + 1) / 2,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white,
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEnhancedMilestoneProgress() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final progress = (_currentStreak % _nextMilestone) / _nextMilestone;
    final daysToMilestone = _nextMilestone - _currentStreak;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [AppColors.darkCard, AppColors.darkElevated]
              : [Colors.white, Colors.grey[50]!],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Next Milestone',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDarkMode
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$_nextMilestone day streak',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$daysToMilestone days left',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Stack(
            children: [
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              AnimatedContainer(
                duration: Duration(milliseconds: 800),
                height: 12,
                width: MediaQuery.of(context).size.width * progress * 0.8, // Account for padding
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.trending_up,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${(progress * 100).toInt()}% complete',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(
                    Icons.emoji_events,
                    size: 16,
                    color: Colors.amber,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Bonus rewards',
                    style: TextStyle(
                      color: Colors.amber[700],
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedWeekActivity() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.calendar_today,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'This Week',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.tertiary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_weekActivity.length}/7 days',
                  style: TextStyle(
                    color: AppColors.tertiary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final dayDate = now.subtract(Duration(days: 6 - index));
              final isActive = _weekActivity.any((date) =>
              date.year == dayDate.year &&
                  date.month == dayDate.month &&
                  date.day == dayDate.day);
              final isToday = index == 6;
              final isFuture = dayDate.isAfter(now);

              return Expanded(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        width: isToday ? 48 : 44,
                        height: isToday ? 48 : 44,
                        decoration: BoxDecoration(
                          gradient: isActive
                              ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.primary, AppColors.secondary],
                          )
                              : null,
                          color: !isActive
                              ? (isToday && !_hasClaimedToday
                              ? AppColors.primary.withOpacity(0.2)
                              : isDarkMode
                              ? AppColors.darkElevated
                              : Colors.grey[100])
                              : null,
                          shape: BoxShape.circle,
                          border: isToday
                              ? Border.all(
                            color: AppColors.primary,
                            width: 2,
                          )
                              : null,
                          boxShadow: isActive
                              ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ]
                              : null,
                        ),
                        child: Center(
                          child: isActive
                              ? Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 20,
                          )
                              : Text(
                            '${dayDate.day}',
                            style: TextStyle(
                              color: isToday && !_hasClaimedToday
                                  ? AppColors.primary
                                  : isDarkMode
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
                              fontWeight: isToday
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        weekDays[index],
                        style: TextStyle(
                          fontSize: 12,
                          color: isToday
                              ? AppColors.primary
                              : isDarkMode
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildEnhancedStatCard(
            icon: Icons.local_fire_department,
            title: 'Best Streak',
            value: '$_longestStreak',
            subtitle: 'days',
            gradient: [Colors.orange, Colors.deepOrange],
            iconBackground: Colors.orange.withOpacity(0.2),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildEnhancedStatCard(
            icon: Icons.star,
            title: 'Total Active',
            value: '$_totalDaysActive',
            subtitle: 'days',
            gradient: [Colors.blue, Colors.indigo],
            iconBackground: Colors.blue.withOpacity(0.2),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedStatCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required List<Color> gradient,
    required Color iconBackground,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient.map((c) => c.withOpacity(0.1)).toList(),
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: gradient.first.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: gradient.first,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: gradient.first,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 16,
                  color: gradient.first.withOpacity(0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedRewardsSection() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withOpacity(0.05),
              AppColors.secondary.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.secondary],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.card_giftcard,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Your Rewards',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.trending_up,
                        color: Colors.green,
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Active',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ScaleTransition(
              scale: _rewardScaleAnimation,
              child: Column(
                children: [
                  _buildEnhancedRewardItem(
                    icon: Icons.star,
                    title: 'Super Likes',
                    count: _availableSuperLikes,
                    color: Colors.blue,
                    description: 'Stand out from the crowd',
                  ),
                  const SizedBox(height: 16),
                  _buildEnhancedRewardItem(
                    icon: Icons.replay,
                    title: 'Rewinds',
                    count: _availableRewinds,
                    color: Colors.orange,
                    description: 'Undo your last swipe',
                  ),
                  const SizedBox(height: 16),
                  _buildEnhancedRewardItem(
                    icon: Icons.bolt,
                    title: 'Boosts',
                    count: _availableBoosts,
                    color: Colors.purple,
                    description: 'Be seen by more people',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedRewardItem({
    required IconData icon,
    required String title,
    required int count,
    required Color color,
    required String description,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode
            ? AppColors.darkElevated.withOpacity(0.5)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDarkMode
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDarkMode
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: color.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.inventory_2,
                  color: color,
                  size: 16,
                ),
                SizedBox(width: 6),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedClaimButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      height: 64,
      child: ElevatedButton(
        onPressed: _hasClaimedToday ? null : _claimDailyReward,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: _hasClaimedToday
                ? LinearGradient(
              colors: [Colors.grey[400]!, Colors.grey[500]!],
            )
                : LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.secondary,
                AppColors.primary.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(32),
            boxShadow: _hasClaimedToday
                ? []
                : [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Container(
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _hasClaimedToday
                      ? Icons.check_circle
                      : Icons.celebration_outlined,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  _hasClaimedToday ? 'Claimed Today!' : 'Claim Daily Reward',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                if (!_hasClaimedToday) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '+3',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedMotivationalMessage() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    String message;
    IconData icon;
    List<Color> gradientColors;

    if (_hasClaimedToday) {
      message = 'Awesome! See you tomorrow to keep the streak alive!';
      icon = Icons.celebration;
      gradientColors = [Colors.green, Colors.teal];
    } else if (_currentStreak == 0) {
      message = 'Start your journey today and unlock amazing rewards!';
      icon = Icons.rocket_launch;
      gradientColors = [Colors.blue, Colors.indigo];
    } else if (_currentStreak < 7) {
      message = 'You\'re doing great! Keep building that streak!';
      icon = Icons.trending_up;
      gradientColors = [Colors.orange, Colors.deepOrange];
    } else if (_currentStreak < 30) {
      message = 'Incredible progress! You\'re on fire!';
      icon = Icons.local_fire_department;
      gradientColors = [Colors.red, Colors.orange];
    } else {
      message = 'Legendary streak! You\'re a true champion!';
      icon = Icons.emoji_events;
      gradientColors = [Colors.amber, Colors.orange];
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors.map((c) => c.withOpacity(0.1)).toList(),
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: gradientColors.first.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradientColors),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isDarkMode
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedMilestonesSection() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.amber, Colors.orange],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.emoji_events,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Milestones',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDarkMode
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDarkMode ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Timeline visualization with horizontal scroll for small screens
              Container(
                height: 130,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: BouncingScrollPhysics(),
                  child: Container(
                    width: math.max(MediaQuery.of(context).size.width - 40, 360),
                    child: _buildMilestoneTimeline(),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Next milestone rewards preview
              _buildNextMilestoneRewards(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMilestoneTimeline() {
    final screenWidth = MediaQuery.of(context).size.width;
    final containerPadding = 48.0; // 24px padding on each side
    final availableWidth = screenWidth - containerPadding - 40; // Extra margin for milestone bubbles

    return Container(
      height: 130, // Increased height for better layout
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background line
          Positioned(
            top: 40,
            left: 25,
            right: 25,
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Progress line
          Positioned(
            top: 40,
            left: 25,
            child: Container(
              width: availableWidth - 10,
              child: Align(
                alignment: Alignment.centerLeft,
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 800),
                  height: 4,
                  width: (availableWidth - 10) * _calculateOverallProgress(),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Milestone points
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _milestones.map((milestone) {
                  final isAchieved = _currentStreak >= milestone;
                  final isNext = milestone == _nextMilestone && !isAchieved;
                  final isCurrent = _currentStreak == milestone;

                  return _buildTimelineMilestone(
                    milestone: milestone,
                    isAchieved: isAchieved,
                    isNext: isNext,
                    isCurrent: isCurrent,
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineMilestone({
    required int milestone,
    required bool isAchieved,
    required bool isNext,
    required bool isCurrent,
  }) {
    return Flexible(
      child: Container(
        width: 50, // Fixed width to prevent overflow
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isNext ? 42 : 36,
              height: isNext ? 42 : 36,
              decoration: BoxDecoration(
                gradient: isAchieved || isCurrent
                    ? LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                )
                    : null,
                color: !isAchieved && !isCurrent
                    ? (isNext
                    ? AppColors.primary.withOpacity(0.2)
                    : Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkElevated
                    : Colors.grey.shade200)
                    : null,
                shape: BoxShape.circle,
                border: isNext
                    ? Border.all(
                  color: AppColors.primary,
                  width: 2,
                )
                    : null,
                boxShadow: isAchieved || isCurrent
                    ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
                    : null,
              ),
              child: Center(
                child: isAchieved
                    ? Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 18,
                )
                    : Text(
                  '$milestone',
                  style: TextStyle(
                    color: isNext
                        ? AppColors.primary
                        : Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                    fontWeight: isNext ? FontWeight.bold : FontWeight.w600,
                    fontSize: isNext ? 14 : 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              milestone < 100 ? '$milestone' : '100',
              style: TextStyle(
                fontSize: 10,
                color: isAchieved || isNext
                    ? AppColors.primary
                    : Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
                fontWeight: isAchieved || isNext ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            Text(
              'days',
              style: TextStyle(
                fontSize: 9,
                color: isAchieved || isNext
                    ? AppColors.primary
                    : Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
            if (isNext) ...[
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'NEXT',
                  style: TextStyle(
                    fontSize: 8,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNextMilestoneRewards() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Find the next milestone and its rewards
    int nextMilestoneIndex = _milestones.indexOf(_nextMilestone);
    if (nextMilestoneIndex == -1 || _currentStreak >= _milestones.last) {
      // All milestones achieved
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.amber.withOpacity(0.1),
              Colors.amber.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.amber.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.amber, Colors.orange],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.star,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Streak Legend!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'You\'ve conquered all milestones. Keep your legendary streak alive!',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Show next milestone rewards
    final streakService = StreakService();
    final rewards = streakService.getMilestoneRewards(_nextMilestone);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.05),
            AppColors.secondary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.card_giftcard,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Unlock at $_nextMilestone days',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildRewardPreview(
                icon: Icons.star,
                count: rewards['superLikes'] ?? 0,
                label: 'Super Likes',
                gradient: [Colors.blue, Colors.lightBlue],
              ),
              _buildRewardPreview(
                icon: Icons.replay,
                count: rewards['rewinds'] ?? 0,
                label: 'Rewinds',
                gradient: [Colors.orange, Colors.deepOrange],
              ),
              if ((rewards['boosts'] ?? 0) > 0)
                _buildRewardPreview(
                  icon: Icons.bolt,
                  count: rewards['boosts'] ?? 0,
                  label: 'Boosts',
                  gradient: [Colors.purple, Colors.deepPurple],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRewardPreview({
    required IconData icon,
    required int count,
    required String label,
    required List<Color> gradient,
  }) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: gradient.first.withOpacity(0.3),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 28,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: gradient.first,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    '+$count',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: gradient.first,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkTextSecondary
                : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  double _calculateOverallProgress() {
    if (_currentStreak >= _milestones.last) {
      return 1.0;
    }

    // Find position between milestones
    int previousMilestone = 0;
    int nextMilestone = _milestones.first;

    for (int i = 0; i < _milestones.length; i++) {
      if (_currentStreak >= _milestones[i]) {
        previousMilestone = _milestones[i];
        if (i < _milestones.length - 1) {
          nextMilestone = _milestones[i + 1];
        }
      } else {
        nextMilestone = _milestones[i];
        break;
      }
    }

    // Calculate progress within current segment
    double segmentProgress = (_currentStreak - previousMilestone) /
        (nextMilestone - previousMilestone);

    // Calculate which segment we're in
    int segmentIndex = _milestones.indexOf(nextMilestone);
    if (segmentIndex == -1) segmentIndex = _milestones.length - 1;

    // Calculate total progress
    double baseProgress = segmentIndex / _milestones.length;
    double additionalProgress = segmentProgress / _milestones.length;

    return baseProgress + additionalProgress;
  }

  void _showStreakInfo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkCard
              : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: 12),
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            // Header
            Container(
              padding: EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.info,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'How Streaks Work',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Your daily motivation system',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildInfoCard(
                      icon: Icons.calendar_today,
                      iconGradient: [Colors.blue, Colors.lightBlue],
                      title: 'Daily Check-In',
                      description: 'Open the app every day and claim your reward to keep your streak alive.',
                    ),
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      icon: Icons.card_giftcard,
                      iconGradient: [AppColors.primary, AppColors.secondary],
                      title: 'Earn Rewards',
                      description: 'Get Super Likes, Rewinds, and Boosts as daily rewards. The longer your streak, the better the rewards!',
                    ),
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      icon: Icons.emoji_events,
                      iconGradient: [Colors.amber, Colors.orange],
                      title: 'Reach Milestones',
                      description: 'Hit special milestones (3, 7, 14, 30, 50, 100 days) for extra bonus rewards.',
                    ),
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      icon: Icons.warning_amber,
                      iconGradient: [Colors.red, Colors.orange],
                      title: 'Don\'t Break the Chain',
                      description: 'Missing a day will reset your streak to zero. Set a daily reminder to keep your streak alive!',
                    ),
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      icon: Icons.local_fire_department,
                      iconGradient: [Colors.orange, Colors.deepOrange],
                      title: 'Build a Habit',
                      description: 'Streaks help you build a daily habit of using the app and increase your chances of finding matches.',
                    ),
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      icon: Icons.star,
                      iconGradient: [Colors.purple, Colors.deepPurple],
                      title: 'Premium Benefits',
                      description: 'Premium members get 2x rewards and exclusive milestone bonuses!',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required List<Color> iconGradient,
    required String title,
    required String description,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode
            ? AppColors.darkElevated.withOpacity(0.5)
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode
              ? AppColors.darkDivider
              : Colors.grey[200]!,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: iconGradient,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDarkMode
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}