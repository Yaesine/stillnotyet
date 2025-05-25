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
  late Animation<double> _streakScaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
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
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _pulseAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _slideAnimationController = AnimationController(
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
      end: 1.1,
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
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadStreakData() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('streak_data')
          .doc('current')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _currentStreak = data['currentStreak'] ?? 0;
          _longestStreak = data['longestStreak'] ?? 0;
          _totalDaysActive = data['totalDaysActive'] ?? 0;
          _lastActiveDate = (data['lastActiveDate'] as Timestamp?)?.toDate();
          _availableRewinds = data['availableRewinds'] ?? 0;
          _availableSuperLikes = data['availableSuperLikes'] ?? 0;
          _availableBoosts = data['availableBoosts'] ?? 0;
          _hasClaimedToday = data['claimedToday'] ?? false;

          // Load week activity
          if (data['weekActivity'] != null) {
            _weekActivity = (data['weekActivity'] as List)
                .map((timestamp) => (timestamp as Timestamp).toDate())
                .toList();
          }

          // Calculate next milestone
          _nextMilestone = _milestones.firstWhere(
                (milestone) => milestone > _currentStreak,
            orElse: () => _milestones.last,
          );
        });
      } else {
        // Initialize with provided values or defaults
        setState(() {
          _currentStreak = widget.initialStreakCount ?? 0;
          _availableRewinds = widget.initialRewindCount ?? 1;
          _availableSuperLikes = widget.initialSuperLikeCount ?? 1;
        });
      }

      // Check if streak should be reset
      _checkStreakContinuity();

      setState(() {
        _isLoading = false;
      });

      // Start animations
      _streakAnimationController.forward();
      _slideAnimationController.forward();

    } catch (e) {
      print('Error loading streak data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _checkStreakContinuity() {
    if (_lastActiveDate == null) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastActive = DateTime(
      _lastActiveDate!.year,
      _lastActiveDate!.month,
      _lastActiveDate!.day,
    );

    final daysDifference = today.difference(lastActive).inDays;

    if (daysDifference > 1) {
      // Streak broken - reset to 0
      setState(() {
        _currentStreak = 0;
        _hasClaimedToday = false;
      });
      _saveStreakData();
    } else if (daysDifference == 1) {
      // Yesterday was active, can claim today
      setState(() {
        _hasClaimedToday = false;
      });
    }
  }

  Future<void> _claimDailyReward() async {
    if (_hasClaimedToday) return;

    // Haptic feedback
    HapticFeedback.mediumImpact();

    setState(() {
      _currentStreak++;
      _totalDaysActive++;
      _hasClaimedToday = true;
      _lastActiveDate = DateTime.now();

      // Update longest streak if needed
      if (_currentStreak > _longestStreak) {
        _longestStreak = _currentStreak;
      }

      // Add to week activity
      _weekActivity.add(DateTime.now());
      if (_weekActivity.length > 7) {
        _weekActivity.removeAt(0);
      }

      // Calculate rewards based on streak
      _calculateRewards();
    });

    // Check for milestone
    if (_milestones.contains(_currentStreak)) {
      _showMilestoneAchievement();
      _confettiController.play();
    }

    // Save to Firestore
    await _saveStreakData();

    // Animate
    _streakAnimationController.reset();
    _streakAnimationController.forward();
  }

  void _calculateRewards() {
    // Base rewards
    _availableRewinds += 1;
    _availableSuperLikes += 1;

    // Bonus rewards for milestones
    if (_currentStreak % 7 == 0) {
      _availableBoosts += 1;
      _availableSuperLikes += 2;
    }

    if (_currentStreak % 30 == 0) {
      _availableRewinds += 5;
      _availableSuperLikes += 5;
      _availableBoosts += 3;
    }
  }

  Future<void> _saveStreakData() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('streak_data')
          .doc('current')
          .set({
        'currentStreak': _currentStreak,
        'longestStreak': _longestStreak,
        'totalDaysActive': _totalDaysActive,
        'lastActiveDate': Timestamp.fromDate(_lastActiveDate ?? DateTime.now()),
        'availableRewinds': _availableRewinds,
        'availableSuperLikes': _availableSuperLikes,
        'availableBoosts': _availableBoosts,
        'claimedToday': _hasClaimedToday,
        'weekActivity': _weekActivity.map((date) => Timestamp.fromDate(date)).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving streak data: $e');
    }
  }

  void _showMilestoneAchievement() {
    showDialog(
      context: context,
      barrierDismissible: false,
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
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.celebration,
                  color: AppColors.primary,
                  size: 60,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Milestone Achieved!',
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
                '$_currentStreak Day Streak!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'You\'ve earned bonus rewards!',
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
                  'Awesome!',
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

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.darkBackground : AppColors.background,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDarkMode
                    ? [AppColors.darkBackground, AppColors.darkSurface]
                    : [AppColors.background, Colors.white],
              ),
            ),
          ),

          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: math.pi / 2,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              maxBlastForce: 100,
              minBlastForce: 80,
              gravity: 0.1,
              colors: const [
                AppColors.primary,
                AppColors.secondary,
                Colors.yellow,
                Colors.blue,
                Colors.purple,
              ],
            ),
          ),

          // Main content
          SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // App Bar
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  pinned: true,
                  title: Text(
                    'Daily Streak',
                    style: TextStyle(
                      color: isDarkMode
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: Icon(
                        Icons.info_outline,
                        color: isDarkMode
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
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
                        // Streak counter with animation
                        _buildStreakCounter(),

                        const SizedBox(height: 32),

                        // Progress to next milestone
                        _buildMilestoneProgress(),

                        const SizedBox(height: 32),

                        // Week activity
                        _buildWeekActivity(),

                        const SizedBox(height: 32),

                        // Stats cards
                        _buildStatsCards(),

                        const SizedBox(height: 32),

                        // Rewards section
                        _buildRewardsSection(),

                        const SizedBox(height: 32),

                        // Claim button
                        _buildClaimButton(),

                        const SizedBox(height: 24),

                        // Motivational message
                        _buildMotivationalMessage(),

                        const SizedBox(height: 32),

                        // Milestones section
                        _buildMilestonesSection(),
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

  Widget _buildStreakCounter() {
    return ScaleTransition(
      scale: _streakScaleAnimation,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _hasClaimedToday ? 1.0 : _pulseAnimation.value,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    AppColors.secondary,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Circular progress
                  SizedBox(
                    width: 180,
                    height: 180,
                    child: CircularProgressIndicator(
                      value: _currentStreak / _nextMilestone,
                      strokeWidth: 8,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  // Streak number
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$_currentStreak',
                        style: const TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                      const Text(
                        'DAYS',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  // Fire icon
                  if (_currentStreak >= 7)
                    const Positioned(
                      top: 20,
                      right: 20,
                      child: Icon(
                        Icons.local_fire_department,
                        color: Colors.white,
                        size: 32,
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

  Widget _buildMilestoneProgress() {
    final progress = (_currentStreak % _nextMilestone) / _nextMilestone;
    final daysToMilestone = _nextMilestone - _currentStreak;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkCard
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Next Milestone',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$daysToMilestone days to go',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$_currentStreak days',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
              Row(
                children: [
                  Icon(
                    Icons.flag,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$_nextMilestone days',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
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

  Widget _buildWeekActivity() {
    final now = DateTime.now();
    final weekDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkCard
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This Week',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkTextPrimary
                  : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final dayDate = now.subtract(Duration(days: 6 - index));
              final isActive = _weekActivity.any((date) =>
              date.year == dayDate.year &&
                  date.month == dayDate.month &&
                  date.day == dayDate.day);
              final isToday = index == 6;

              return Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.primary
                          : isToday && !_hasClaimedToday
                          ? AppColors.primary.withOpacity(0.3)
                          : Colors.grey.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: isToday
                          ? Border.all(
                        color: AppColors.primary,
                        width: 2,
                      )
                          : null,
                    ),
                    child: Center(
                      child: isActive
                          ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 20,
                      )
                          : Text(
                        '${dayDate.day}',
                        style: TextStyle(
                          color: isToday && !_hasClaimedToday
                              ? AppColors.primary
                              : Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
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
                          : Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.local_fire_department,
            title: 'Longest',
            value: '$_longestStreak',
            subtitle: 'days',
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            icon: Icons.calendar_today,
            title: 'Total Active',
            value: '$_totalDaysActive',
            subtitle: 'days',
            color: Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkCard
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).brightness == Brightness.dark
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
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRewardsSection() {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withOpacity(0.1),
              AppColors.secondary.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.card_giftcard,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Your Rewards',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildRewardItem(
              icon: Icons.star,
              title: 'Super Likes',
              count: _availableSuperLikes,
              color: Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildRewardItem(
              icon: Icons.replay,
              title: 'Rewinds',
              count: _availableRewinds,
              color: Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildRewardItem(
              icon: Icons.flash_on,
              title: 'Boosts',
              count: _availableBoosts,
              color: Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardItem({
    required IconData icon,
    required String title,
    required int count,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkTextPrimary
                  : AppColors.textPrimary,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkElevated
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'x$count',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkTextPrimary
                  : AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClaimButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _hasClaimedToday ? null : _claimDailyReward,
        style: ElevatedButton.styleFrom(
          backgroundColor: _hasClaimedToday
              ? Colors.grey
              : AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: _hasClaimedToday ? 0 : 3,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _hasClaimedToday ? Icons.check_circle : Icons.celebration,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Text(
              _hasClaimedToday ? 'Claimed Today!' : 'Claim Daily Reward',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMotivationalMessage() {
    String message;
    IconData icon;

    if (_hasClaimedToday) {
      message = 'Great job! Come back tomorrow to continue your streak.';
      icon = Icons.thumb_up;
    } else if (_currentStreak == 0) {
      message = 'Start your streak today and earn rewards!';
      icon = Icons.rocket_launch;
    } else if (_currentStreak < 7) {
      message = 'Keep going! You\'re building a great habit.';
      icon = Icons.trending_up;
    } else if (_currentStreak < 30) {
      message = 'You\'re on fire! Don\'t break the streak now.';
      icon = Icons.local_fire_department;
    } else {
      message = 'Amazing dedication! You\'re a streak master.';
      icon = Icons.emoji_events;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestonesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.emoji_events,
              color: AppColors.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Milestones',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkCard
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Milestones progress line
              Stack(
                children: [
                  // Background line
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Progress line
                  FractionallySizedBox(
                    widthFactor: _calculateOverallProgress(),
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.secondary],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Milestone indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _milestones.map((milestone) {
                  final isAchieved = _currentStreak >= milestone;
                  final isNext = milestone == _nextMilestone && !isAchieved;

                  return _buildMilestoneIndicator(
                    milestone: milestone,
                    isAchieved: isAchieved,
                    isNext: isNext,
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              // Milestone rewards preview
              _buildMilestoneRewards(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMilestoneIndicator({
    required int milestone,
    required bool isAchieved,
    required bool isNext,
  }) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: isNext ? 48 : 40,
          height: isNext ? 48 : 40,
          decoration: BoxDecoration(
            color: isAchieved
                ? AppColors.primary
                : isNext
                ? AppColors.primary.withOpacity(0.2)
                : Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkElevated
                : Colors.grey.shade200,
            shape: BoxShape.circle,
            border: isNext
                ? Border.all(
              color: AppColors.primary,
              width: 2,
            )
                : null,
            boxShadow: isAchieved
                ? [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ]
                : null,
          ),
          child: Center(
            child: isAchieved
                ? const Icon(
              Icons.check,
              color: Colors.white,
              size: 20,
            )
                : Text(
              '$milestone',
              style: TextStyle(
                color: isNext
                    ? AppColors.primary
                    : Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
                fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
                fontSize: isNext ? 16 : 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$milestone days',
          style: TextStyle(
            fontSize: 12,
            color: isAchieved
                ? AppColors.primary
                : Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkTextSecondary
                : AppColors.textSecondary,
            fontWeight: isAchieved || isNext ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        if (isNext) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'NEXT',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMilestoneRewards() {
    // Find the next milestone and its rewards
    int nextMilestoneIndex = _milestones.indexOf(_nextMilestone);
    if (nextMilestoneIndex == -1 || _currentStreak >= _milestones.last) {
      // All milestones achieved
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.amber.withOpacity(0.1),
              Colors.amber.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.amber.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.star,
              color: Colors.amber,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Streak Master!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'You\'ve achieved all milestones. Keep your streak going!',
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
          ],
        ),
      );
    }

    // Show next milestone rewards
    Map<int, Map<String, dynamic>> milestoneRewards = {
      3: {'superLikes': 3, 'rewinds': 2, 'boosts': 0},
      7: {'superLikes': 5, 'rewinds': 3, 'boosts': 1},
      14: {'superLikes': 10, 'rewinds': 5, 'boosts': 2},
      30: {'superLikes': 20, 'rewinds': 10, 'boosts': 5},
      50: {'superLikes': 30, 'rewinds': 15, 'boosts': 7},
      100: {'superLikes': 50, 'rewinds': 25, 'boosts': 10},
    };

    final rewards = milestoneRewards[_nextMilestone] ?? {'superLikes': 0, 'rewinds': 0, 'boosts': 0};

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.card_giftcard,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Next Milestone Rewards ($_nextMilestone days)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildRewardPreview(
                icon: Icons.star,
                count: rewards['superLikes'],
                label: 'Super Likes',
                color: Colors.blue,
              ),
              _buildRewardPreview(
                icon: Icons.replay,
                count: rewards['rewinds'],
                label: 'Rewinds',
                color: Colors.orange,
              ),
              _buildRewardPreview(
                icon: Icons.flash_on,
                count: rewards['boosts'],
                label: 'Boosts',
                color: Colors.purple,
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
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
                Text(
                  '+$count',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
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
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkCard
              : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'How Streaks Work',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoItem(
              icon: Icons.calendar_today,
              title: 'Daily Login',
              description: 'Open the app every day to maintain your streak.',
            ),
            const SizedBox(height: 12),
            _buildInfoItem(
              icon: Icons.card_giftcard,
              title: 'Earn Rewards',
              description: 'Get Super Likes, Rewinds, and Boosts as rewards.',
            ),
            const SizedBox(height: 12),
            _buildInfoItem(
              icon: Icons.flag,
              title: 'Reach Milestones',
              description: 'Hit milestones for extra bonus rewards.',
            ),
            const SizedBox(height: 12),
            _buildInfoItem(
              icon: Icons.warning_amber,
              title: 'Don\'t Miss a Day',
              description: 'Missing a day will reset your streak to zero.',
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 20,
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
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
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
      ],
    );
  }
}