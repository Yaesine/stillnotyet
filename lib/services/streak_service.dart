// lib/services/streak_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StreakService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user's streak data
  Future<StreakData?> getStreakData() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return null;

      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) return null;

      final data = userDoc.data()!;
      final streakData = data['streakData'] as Map<String, dynamic>?;

      if (streakData == null) {
        // Initialize streak data if doesn't exist
        return await _initializeStreakData(userId);
      }

      return StreakData.fromMap(streakData);
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
      rewardsHistory: [],
      claimedRewards: {},
    );

    await _firestore.collection('users').doc(userId).update({
      'streakData': initialData.toMap(),
    });

    return initialData;
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
      if (streakData.lastActiveDate != null) {
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

      // Calculate new streak
      int newStreak = streakData.currentStreak;
      bool streakBroken = false;

      if (streakData.lastActiveDate == null) {
        // First time
        newStreak = 1;
      } else {
        final daysSinceLastActive = today.difference(
          DateTime(
            streakData.lastActiveDate!.year,
            streakData.lastActiveDate!.month,
            streakData.lastActiveDate!.day,
          ),
        ).inDays;

        if (daysSinceLastActive == 1) {
          // Continue streak
          newStreak = streakData.currentStreak + 1;
        } else if (daysSinceLastActive > 1) {
          // Streak broken
          newStreak = 1;
          streakBroken = true;
        }
      }

      // Generate rewards
      final rewards = _generateRewards(newStreak);

      // Update Firestore
      final updatedData = StreakData(
        currentStreak: newStreak,
        longestStreak: newStreak > streakData.longestStreak
            ? newStreak
            : streakData.longestStreak,
        totalDaysActive: streakData.totalDaysActive + 1,
        lastActiveDate: now,
        rewardsHistory: [
          ...streakData.rewardsHistory,
          RewardHistoryEntry(
            date: now,
            rewards: rewards,
            streakDay: newStreak,
          ),
        ],
        claimedRewards: _updateClaimedRewards(
          streakData.claimedRewards,
          rewards,
        ),
      );

      await _firestore.collection('users').doc(userId).update({
        'streakData': updatedData.toMap(),
      });

      // Apply rewards to user account
      await _applyRewards(userId, rewards);

      return StreakUpdateResult(
        success: true,
        message: streakBroken
            ? 'Streak reset! Starting fresh at Day 1'
            : 'Streak continued! Day $newStreak',
        streakData: updatedData,
        rewards: rewards,
        streakBroken: streakBroken,
      );
    } catch (e) {
      print('Error updating streak: $e');
      return StreakUpdateResult(
        success: false,
        message: 'Error updating streak',
      );
    }
  }

  // Generate rewards based on streak
  List<DailyReward> _generateRewards(int streak) {
    List<DailyReward> rewards = [];

    // Base daily reward - 1 super like
    rewards.add(DailyReward(
      type: 'superLike',
      amount: 1,
      description: 'Daily Super Like',
    ));

    // 3-day streak bonus
    if (streak >= 3 && streak % 3 == 0) {
      rewards.add(DailyReward(
        type: 'boost',
        amount: 1,
        description: '3-Day Streak Bonus',
      ));
    }

    // Weekly bonus
    if (streak >= 7 && streak % 7 == 0) {
      rewards.add(DailyReward(
        type: 'superLike',
        amount: 3,
        description: 'Weekly Bonus Super Likes',
      ));
      rewards.add(DailyReward(
        type: 'rewind',
        amount: 5,
        description: 'Weekly Rewinds',
      ));
    }

    // 2-week milestone
    if (streak == 14) {
      rewards.add(DailyReward(
        type: 'topPicks',
        amount: 10,
        description: '2-Week Milestone Reward',
      ));
    }

    // Monthly milestone
    if (streak == 30) {
      rewards.add(DailyReward(
        type: 'boost',
        amount: 3,
        description: '30-Day Achievement',
      ));
      rewards.add(DailyReward(
        type: 'superLike',
        amount: 10,
        description: '30-Day Achievement',
      ));
    }

    // 50-day milestone
    if (streak == 50) {
      rewards.add(DailyReward(
        type: 'premiumTrial',
        amount: 1,
        description: '1-Day Premium Trial',
      ));
    }

    // 100-day milestone
    if (streak == 100) {
      rewards.add(DailyReward(
        type: 'premiumTrial',
        amount: 3,
        description: '3-Day Premium Trial',
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
      updated[reward.type] = (updated[reward.type] ?? 0) + reward.amount;
    }

    return updated;
  }

  // Apply rewards to user account
  Future<void> _applyRewards(String userId, List<DailyReward> rewards) async {
    final batch = _firestore.batch();
    final userRef = _firestore.collection('users').doc(userId);

    for (final reward in rewards) {
      switch (reward.type) {
        case 'superLike':
          batch.update(userRef, {
            'dailySuperLikes': FieldValue.increment(reward.amount),
          });
          break;
        case 'boost':
          batch.update(userRef, {
            'boosts': FieldValue.increment(reward.amount),
          });
          break;
        case 'rewind':
          batch.update(userRef, {
            'rewinds': FieldValue.increment(reward.amount),
          });
          break;
        case 'topPicks':
          batch.update(userRef, {
            'topPicks': FieldValue.increment(reward.amount),
          });
          break;
        case 'premiumTrial':
        // Add premium trial days
          final expiryDate = DateTime.now().add(
            Duration(days: reward.amount),
          );
          batch.update(userRef, {
            'premiumExpiry': Timestamp.fromDate(expiryDate),
          });
          break;
      }
    }

    await batch.commit();
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

      return StreakStats(
        averageStreak: averageStreak,
        totalRewardsClaimed: totalRewards,
        favoriteRewardType: favoriteType,
      );
    } catch (e) {
      print('Error getting streak stats: $e');
      return StreakStats(
        averageStreak: 0,
        totalRewardsClaimed: 0,
        favoriteRewardType: 'superLike',
      );
    }
  }
}

// Data models
class StreakData {
  final int currentStreak;
  final int longestStreak;
  final int totalDaysActive;
  final DateTime? lastActiveDate;
  final List<RewardHistoryEntry> rewardsHistory;
  final Map<String, int> claimedRewards;

  StreakData({
    required this.currentStreak,
    required this.longestStreak,
    required this.totalDaysActive,
    required this.lastActiveDate,
    required this.rewardsHistory,
    required this.claimedRewards,
  });

  factory StreakData.fromMap(Map<String, dynamic> map) {
    return StreakData(
      currentStreak: map['currentStreak'] ?? 0,
      longestStreak: map['longestStreak'] ?? 0,
      totalDaysActive: map['totalDaysActive'] ?? 0,
      lastActiveDate: map['lastActiveDate']?.toDate(),
      rewardsHistory: (map['rewardsHistory'] as List<dynamic>?)
          ?.map((e) => RewardHistoryEntry.fromMap(e))
          .toList() ?? [],
      claimedRewards: Map<String, int>.from(map['claimedRewards'] ?? {}),
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
      'rewardsHistory': rewardsHistory.map((e) => e.toMap()).toList(),
      'claimedRewards': claimedRewards,
    };
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

class DailyReward {
  final String type;
  final int amount;
  final String description;

  DailyReward({
    required this.type,
    required this.amount,
    required this.description,
  });

  factory DailyReward.fromMap(Map<String, dynamic> map) {
    return DailyReward(
      type: map['type'] ?? '',
      amount: map['amount'] ?? 0,
      description: map['description'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'amount': amount,
      'description': description,
    };
  }
}

class StreakUpdateResult {
  final bool success;
  final String message;
  final StreakData? streakData;
  final List<DailyReward>? rewards;
  final bool streakBroken;

  StreakUpdateResult({
    required this.success,
    required this.message,
    this.streakData,
    this.rewards,
    this.streakBroken = false,
  });
}

class StreakStats {
  final int averageStreak;
  final int totalRewardsClaimed;
  final String favoriteRewardType;

  StreakStats({
    required this.averageStreak,
    required this.totalRewardsClaimed,
    required this.favoriteRewardType,
  });
}