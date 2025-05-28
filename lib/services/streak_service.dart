// lib/services/streak_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StreakService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Singleton pattern
  static final StreakService _instance = StreakService._internal();
  factory StreakService() => _instance;
  StreakService._internal();

  // Milestones
  static const List<int> milestones = [3, 7, 14, 30, 50, 100];

  // Get current user's streak data
  Future<StreakData?> getStreakData() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return null;

      // Try to get from dedicated streak collection first
      final streakDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('streak_data')
          .doc('current')
          .get();

      if (streakDoc.exists) {
        return StreakData.fromMap(streakDoc.data()!);
      }

      // If not found, initialize new streak data
      return await _initializeStreakData(userId);
    } catch (e) {
      print('Error getting streak data: $e');
      return null;
    }
  }

  // Initialize streak data for new users
  Future<StreakData> _initializeStreakData(String userId) async {
    final initialData = StreakData(
      currentStreak: 0,
      longestStreak: 0,
      totalDaysActive: 0,
      lastActiveDate: null,
      availableRewinds: 1, // Start with 1 free rewind
      availableSuperLikes: 1, // Start with 1 free super like
      availableBoosts: 0,
      claimedToday: false,
      weekActivity: [],
      rewardsHistory: [],
      claimedRewards: {},
      streakStartDate: null,
    );

    await saveStreakData(userId, initialData);
    return initialData;
  }

  // Save streak data
  Future<void> saveStreakData(String userId, StreakData data) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('streak_data')
          .doc('current')
          .set({
        ...data.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving streak data: $e');
      throw e;
    }
  }

  // Check and update streak
  Future<StreakUpdateResult> checkAndUpdateStreak() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        return StreakUpdateResult(
          success: false,
          message: 'User not authenticated',
        );
      }

      final streakData = await getStreakData();
      if (streakData == null) {
        return StreakUpdateResult(
          success: false,
          message: 'Could not load streak data',
        );
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Check if already claimed today
      if (streakData.claimedToday && streakData.lastActiveDate != null) {
        final lastActive = DateTime(
          streakData.lastActiveDate!.year,
          streakData.lastActiveDate!.month,
          streakData.lastActiveDate!.day,
        );

        if (lastActive == today) {
          return StreakUpdateResult(
            success: false,
            message: 'Already claimed today',
            streakData: streakData,
          );
        }
      }

      // Check streak continuity
      final continuityResult = _checkStreakContinuity(streakData);

      // Update streak data based on continuity
      final updatedData = await _updateStreakData(
        userId,
        streakData,
        continuityResult,
        now,
      );

      return StreakUpdateResult(
        success: true,
        message: continuityResult.streakBroken
            ? 'Streak reset! Starting fresh at Day 1'
            : 'Streak continued! Day ${updatedData.currentStreak}',
        streakData: updatedData,
        rewards: updatedData.rewardsHistory.isNotEmpty
            ? updatedData.rewardsHistory.last.rewards
            : [],
        streakBroken: continuityResult.streakBroken,
        isMilestone: milestones.contains(updatedData.currentStreak),
      );
    } catch (e) {
      print('Error updating streak: $e');
      return StreakUpdateResult(
        success: false,
        message: 'Error updating streak',
      );
    }
  }

  // Check streak continuity
  StreakContinuityResult _checkStreakContinuity(StreakData data) {
    if (data.lastActiveDate == null) {
      // First time user
      return StreakContinuityResult(
        shouldContinue: false,
        streakBroken: false,
        isFirstTime: true,
      );
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastActive = DateTime(
      data.lastActiveDate!.year,
      data.lastActiveDate!.month,
      data.lastActiveDate!.day,
    );

    final daysSinceLastActive = today.difference(lastActive).inDays;

    if (daysSinceLastActive == 0) {
      // Already claimed today
      return StreakContinuityResult(
        shouldContinue: false,
        streakBroken: false,
        isFirstTime: false,
      );
    } else if (daysSinceLastActive == 1) {
      // Perfect continuation
      return StreakContinuityResult(
        shouldContinue: true,
        streakBroken: false,
        isFirstTime: false,
      );
    } else {
      // Streak broken
      return StreakContinuityResult(
        shouldContinue: false,
        streakBroken: true,
        isFirstTime: false,
      );
    }
  }

  // Update streak data
  Future<StreakData> _updateStreakData(
      String userId,
      StreakData currentData,
      StreakContinuityResult continuity,
      DateTime now,
      ) async {
    int newStreak;
    DateTime? streakStartDate;
    List<DateTime> weekActivity = List.from(currentData.weekActivity);

    if (continuity.isFirstTime) {
      newStreak = 1;
      streakStartDate = now;
    } else if (continuity.streakBroken) {
      newStreak = 1;
      streakStartDate = now;
      weekActivity.clear(); // Clear week activity on streak break
    } else if (continuity.shouldContinue) {
      newStreak = currentData.currentStreak + 1;
      streakStartDate = currentData.streakStartDate;
    } else {
      // Already claimed today
      return currentData;
    }

    // Update week activity
    weekActivity.add(now);
    // Keep only last 7 days
    if (weekActivity.length > 7) {
      weekActivity = weekActivity.sublist(weekActivity.length - 7);
    }

    // Generate rewards
    final rewards = _generateRewards(newStreak);

    // Calculate new reward totals
    int newRewinds = currentData.availableRewinds;
    int newSuperLikes = currentData.availableSuperLikes;
    int newBoosts = currentData.availableBoosts;

    for (final reward in rewards) {
      switch (reward.type) {
        case RewardType.rewind:
          newRewinds += reward.amount;
          break;
        case RewardType.superLike:
          newSuperLikes += reward.amount;
          break;
        case RewardType.boost:
          newBoosts += reward.amount;
          break;
        default:
          break;
      }
    }

    // Create updated data
    final updatedData = StreakData(
      currentStreak: newStreak,
      longestStreak: newStreak > currentData.longestStreak
          ? newStreak
          : currentData.longestStreak,
      totalDaysActive: currentData.totalDaysActive + 1,
      lastActiveDate: now,
      availableRewinds: newRewinds,
      availableSuperLikes: newSuperLikes,
      availableBoosts: newBoosts,
      claimedToday: true,
      weekActivity: weekActivity,
      rewardsHistory: [
        ...currentData.rewardsHistory,
        RewardHistoryEntry(
          date: now,
          rewards: rewards,
          streakDay: newStreak,
        ),
      ],
      claimedRewards: _updateClaimedRewards(
        currentData.claimedRewards,
        rewards,
      ),
      streakStartDate: streakStartDate,
    );

    // Save to Firestore
    await saveStreakData(userId, updatedData);

    // Apply rewards to user profile
    await _applyRewardsToProfile(userId, rewards);

    return updatedData;
  }

  // Generate rewards based on streak
  List<DailyReward> _generateRewards(int streak) {
    List<DailyReward> rewards = [];

    // Base daily rewards
    rewards.add(DailyReward(
      type: RewardType.superLike,
      amount: 1,
      description: 'Daily Super Like',
      icon: 'star',
    ));

    rewards.add(DailyReward(
      type: RewardType.rewind,
      amount: 1,
      description: 'Daily Rewind',
      icon: 'replay',
    ));

    // Milestone bonuses
    if (streak == 3) {
      rewards.add(DailyReward(
        type: RewardType.superLike,
        amount: 2,
        description: '3-Day Streak Bonus',
        icon: 'star',
      ));
    }

    if (streak == 7) {
      rewards.add(DailyReward(
        type: RewardType.boost,
        amount: 1,
        description: 'Weekly Streak Bonus',
        icon: 'bolt',
      ));
      rewards.add(DailyReward(
        type: RewardType.superLike,
        amount: 3,
        description: 'Weekly Super Likes',
        icon: 'star',
      ));
    }

    if (streak == 14) {
      rewards.add(DailyReward(
        type: RewardType.boost,
        amount: 2,
        description: '2-Week Milestone',
        icon: 'bolt',
      ));
      rewards.add(DailyReward(
        type: RewardType.superLike,
        amount: 5,
        description: '2-Week Super Likes',
        icon: 'star',
      ));
    }

    if (streak == 30) {
      rewards.add(DailyReward(
        type: RewardType.boost,
        amount: 5,
        description: '30-Day Achievement',
        icon: 'bolt',
      ));
      rewards.add(DailyReward(
        type: RewardType.superLike,
        amount: 10,
        description: '30-Day Super Likes',
        icon: 'star',
      ));
      rewards.add(DailyReward(
        type: RewardType.rewind,
        amount: 5,
        description: '30-Day Rewinds',
        icon: 'replay',
      ));
    }

    if (streak == 50) {
      rewards.add(DailyReward(
        type: RewardType.boost,
        amount: 7,
        description: '50-Day Legend',
        icon: 'bolt',
      ));
      rewards.add(DailyReward(
        type: RewardType.superLike,
        amount: 15,
        description: '50-Day Super Likes',
        icon: 'star',
      ));
    }

    if (streak == 100) {
      rewards.add(DailyReward(
        type: RewardType.boost,
        amount: 10,
        description: '100-Day Master',
        icon: 'bolt',
      ));
      rewards.add(DailyReward(
        type: RewardType.superLike,
        amount: 25,
        description: '100-Day Super Likes',
        icon: 'star',
      ));
      rewards.add(DailyReward(
        type: RewardType.premiumTrial,
        amount: 3,
        description: '3-Day Premium Trial',
        icon: 'crown',
      ));
    }

    // Weekly bonuses (every 7 days)
    if (streak > 7 && streak % 7 == 0) {
      rewards.add(DailyReward(
        type: RewardType.boost,
        amount: 1,
        description: 'Weekly Bonus Boost',
        icon: 'bolt',
      ));
    }

    return rewards;
  }

  // Update claimed rewards count
  Map<String, int> _updateClaimedRewards(
      Map<String, int> current,
      List<DailyReward> newRewards,
      ) {
    final updated = Map<String, int>.from(current);

    for (final reward in newRewards) {
      final typeStr = reward.type.toString().split('.').last;
      updated[typeStr] = (updated[typeStr] ?? 0) + reward.amount;
    }

    return updated;
  }

  // Apply rewards to user profile
  Future<void> _applyRewardsToProfile(String userId, List<DailyReward> rewards) async {
    try {
      // This would update the user's main profile with the rewards
      // For now, rewards are stored in the streak data
      // In a full implementation, you might want to update the user's main profile

      // Log rewards for analytics
      for (final reward in rewards) {
        print('Applied reward: ${reward.amount} ${reward.type}');
      }
    } catch (e) {
      print('Error applying rewards to profile: $e');
    }
  }

  // Use a reward (deduct from available)
  Future<bool> useReward(RewardType type, int amount) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final streakData = await getStreakData();
      if (streakData == null) return false;

      bool canUse = false;
      StreakData updatedData = streakData;

      switch (type) {
        case RewardType.rewind:
          if (streakData.availableRewinds >= amount) {
            updatedData = streakData.copyWith(
              availableRewinds: streakData.availableRewinds - amount,
            );
            canUse = true;
          }
          break;
        case RewardType.superLike:
          if (streakData.availableSuperLikes >= amount) {
            updatedData = streakData.copyWith(
              availableSuperLikes: streakData.availableSuperLikes - amount,
            );
            canUse = true;
          }
          break;
        case RewardType.boost:
          if (streakData.availableBoosts >= amount) {
            updatedData = streakData.copyWith(
              availableBoosts: streakData.availableBoosts - amount,
            );
            canUse = true;
          }
          break;
        default:
          break;
      }

      if (canUse) {
        await saveStreakData(userId, updatedData);
      }

      return canUse;
    } catch (e) {
      print('Error using reward: $e');
      return false;
    }
  }

  // Get next milestone
  int getNextMilestone(int currentStreak) {
    return milestones.firstWhere(
          (milestone) => milestone > currentStreak,
      orElse: () => milestones.last,
    );
  }

  // Get milestone rewards preview
  Map<String, int> getMilestoneRewards(int milestone) {
    switch (milestone) {
      case 3:
        return {'superLikes': 3, 'rewinds': 2, 'boosts': 0};
      case 7:
        return {'superLikes': 5, 'rewinds': 3, 'boosts': 1};
      case 14:
        return {'superLikes': 10, 'rewinds': 5, 'boosts': 2};
      case 30:
        return {'superLikes': 20, 'rewinds': 10, 'boosts': 5};
      case 50:
        return {'superLikes': 30, 'rewinds': 15, 'boosts': 7};
      case 100:
        return {'superLikes': 50, 'rewinds': 25, 'boosts': 10};
      default:
        return {'superLikes': 0, 'rewinds': 0, 'boosts': 0};
    }
  }

  // Get streak statistics
  Future<StreakStats> getStreakStats() async {
    try {
      final streakData = await getStreakData();
      if (streakData == null) {
        return StreakStats(
          averageStreak: 0,
          totalRewardsClaimed: 0,
          favoriteRewardType: 'superLike',
          streakPercentile: 0,
        );
      }

      // Calculate average streak from history
      final streaks = streakData.rewardsHistory
          .map((entry) => entry.streakDay)
          .toList();

      final averageStreak = streaks.isEmpty
          ? 0
          : streaks.reduce((a, b) => a + b) ~/ streaks.length;

      // Calculate total rewards
      final totalRewards = streakData.claimedRewards.values
          .fold<int>(0, (sum, count) => sum + count);

      // Find favorite reward type
      String favoriteType = 'superLike';
      int maxCount = 0;
      streakData.claimedRewards.forEach((type, count) {
        if (count > maxCount) {
          maxCount = count;
          favoriteType = type;
        }
      });

      // Calculate percentile (mock data - in real app, compare with other users)
      final percentile = _calculateStreakPercentile(streakData.longestStreak);

      return StreakStats(
        averageStreak: averageStreak,
        totalRewardsClaimed: totalRewards,
        favoriteRewardType: favoriteType,
        streakPercentile: percentile,
      );
    } catch (e) {
      print('Error getting streak stats: $e');
      return StreakStats(
        averageStreak: 0,
        totalRewardsClaimed: 0,
        favoriteRewardType: 'superLike',
        streakPercentile: 0,
      );
    }
  }

  // Calculate streak percentile (mock implementation)
  int _calculateStreakPercentile(int longestStreak) {
    // In a real app, this would compare against all users
    // For now, using a simple formula
    if (longestStreak >= 100) return 99;
    if (longestStreak >= 50) return 95;
    if (longestStreak >= 30) return 90;
    if (longestStreak >= 14) return 80;
    if (longestStreak >= 7) return 70;
    if (longestStreak >= 3) return 50;
    return 30;
  }
}

// Data models
class StreakData {
  final int currentStreak;
  final int longestStreak;
  final int totalDaysActive;
  final DateTime? lastActiveDate;
  final int availableRewinds;
  final int availableSuperLikes;
  final int availableBoosts;
  final bool claimedToday;
  final List<DateTime> weekActivity;
  final List<RewardHistoryEntry> rewardsHistory;
  final Map<String, int> claimedRewards;
  final DateTime? streakStartDate;

  StreakData({
    required this.currentStreak,
    required this.longestStreak,
    required this.totalDaysActive,
    required this.lastActiveDate,
    required this.availableRewinds,
    required this.availableSuperLikes,
    required this.availableBoosts,
    required this.claimedToday,
    required this.weekActivity,
    required this.rewardsHistory,
    required this.claimedRewards,
    this.streakStartDate,
  });

  factory StreakData.fromMap(Map<String, dynamic> map) {
    return StreakData(
      currentStreak: map['currentStreak'] ?? 0,
      longestStreak: map['longestStreak'] ?? 0,
      totalDaysActive: map['totalDaysActive'] ?? 0,
      lastActiveDate: map['lastActiveDate']?.toDate(),
      availableRewinds: map['availableRewinds'] ?? 0,
      availableSuperLikes: map['availableSuperLikes'] ?? 0,
      availableBoosts: map['availableBoosts'] ?? 0,
      claimedToday: map['claimedToday'] ?? false,
      weekActivity: (map['weekActivity'] as List<dynamic>?)
          ?.map((timestamp) => (timestamp as Timestamp).toDate())
          .toList() ??
          [],
      rewardsHistory: (map['rewardsHistory'] as List<dynamic>?)
          ?.map((e) => RewardHistoryEntry.fromMap(e))
          .toList() ??
          [],
      claimedRewards: Map<String, int>.from(map['claimedRewards'] ?? {}),
      streakStartDate: map['streakStartDate']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'totalDaysActive': totalDaysActive,
      'lastActiveDate': lastActiveDate != null
          ? Timestamp.fromDate(lastActiveDate!)
          : null,
      'availableRewinds': availableRewinds,
      'availableSuperLikes': availableSuperLikes,
      'availableBoosts': availableBoosts,
      'claimedToday': claimedToday,
      'weekActivity': weekActivity
          .map((date) => Timestamp.fromDate(date))
          .toList(),
      'rewardsHistory': rewardsHistory.map((e) => e.toMap()).toList(),
      'claimedRewards': claimedRewards,
      'streakStartDate': streakStartDate != null
          ? Timestamp.fromDate(streakStartDate!)
          : null,
    };
  }

  StreakData copyWith({
    int? currentStreak,
    int? longestStreak,
    int? totalDaysActive,
    DateTime? lastActiveDate,
    int? availableRewinds,
    int? availableSuperLikes,
    int? availableBoosts,
    bool? claimedToday,
    List<DateTime>? weekActivity,
    List<RewardHistoryEntry>? rewardsHistory,
    Map<String, int>? claimedRewards,
    DateTime? streakStartDate,
  }) {
    return StreakData(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      totalDaysActive: totalDaysActive ?? this.totalDaysActive,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      availableRewinds: availableRewinds ?? this.availableRewinds,
      availableSuperLikes: availableSuperLikes ?? this.availableSuperLikes,
      availableBoosts: availableBoosts ?? this.availableBoosts,
      claimedToday: claimedToday ?? this.claimedToday,
      weekActivity: weekActivity ?? this.weekActivity,
      rewardsHistory: rewardsHistory ?? this.rewardsHistory,
      claimedRewards: claimedRewards ?? this.claimedRewards,
      streakStartDate: streakStartDate ?? this.streakStartDate,
    );
  }
}

class RewardHistoryEntry {
  final DateTime date;
  final List<DailyReward> rewards;
  final int streakDay;

  RewardHistoryEntry({
    required this.date,
    required this.rewards,
    required this.streakDay,
  });

  factory RewardHistoryEntry.fromMap(Map<String, dynamic> map) {
    return RewardHistoryEntry(
      date: map['date'].toDate(),
      rewards: (map['rewards'] as List<dynamic>)
          .map((e) => DailyReward.fromMap(e))
          .toList(),
      streakDay: map['streakDay'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'rewards': rewards.map((e) => e.toMap()).toList(),
      'streakDay': streakDay,
    };
  }
}

enum RewardType {
  superLike,
  rewind,
  boost,
  topPicks,
  premiumTrial,
}

class DailyReward {
  final RewardType type;
  final int amount;
  final String description;
  final String icon;

  DailyReward({
    required this.type,
    required this.amount,
    required this.description,
    required this.icon,
  });

  factory DailyReward.fromMap(Map<String, dynamic> map) {
    return DailyReward(
      type: RewardType.values.firstWhere(
            (e) => e.toString() == 'RewardType.${map['type']}',
        orElse: () => RewardType.superLike,
      ),
      amount: map['amount'] ?? 0,
      description: map['description'] ?? '',
      icon: map['icon'] ?? 'star',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.toString().split('.').last,
      'amount': amount,
      'description': description,
      'icon': icon,
    };
  }
}

class StreakUpdateResult {
  final bool success;
  final String message;
  final StreakData? streakData;
  final List<DailyReward>? rewards;
  final bool streakBroken;
  final bool isMilestone;

  StreakUpdateResult({
    required this.success,
    required this.message,
    this.streakData,
    this.rewards,
    this.streakBroken = false,
    this.isMilestone = false,
  });
}

class StreakContinuityResult {
  final bool shouldContinue;
  final bool streakBroken;
  final bool isFirstTime;

  StreakContinuityResult({
    required this.shouldContinue,
    required this.streakBroken,
    required this.isFirstTime,
  });
}

class StreakStats {
  final int averageStreak;
  final int totalRewardsClaimed;
  final String favoriteRewardType;
  final int streakPercentile;

  StreakStats({
    required this.averageStreak,
    required this.totalRewardsClaimed,
    required this.favoriteRewardType,
    required this.streakPercentile,
  });
}

// Extension for easy reward type display
extension RewardTypeExtension on RewardType {
  String get displayName {
    switch (this) {
      case RewardType.superLike:
        return 'Super Like';
      case RewardType.rewind:
        return 'Rewind';
      case RewardType.boost:
        return 'Boost';
      case RewardType.topPicks:
        return 'Top Picks';
      case RewardType.premiumTrial:
        return 'Premium Trial';
    }
  }

  String get icon {
    switch (this) {
      case RewardType.superLike:
        return 'star';
      case RewardType.rewind:
        return 'replay';
      case RewardType.boost:
        return 'bolt';
      case RewardType.topPicks:
        return 'favorite';
      case RewardType.premiumTrial:
        return 'crown';
    }
  }
}