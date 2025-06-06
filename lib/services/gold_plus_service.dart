import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GoldPlusService extends ChangeNotifier {
  static const String _isGoldPlusKey = 'is_gold_plus';
  static const String _subscriptionEndDateKey = 'gold_plus_end_date';

  bool _isGoldPlus = false;
  DateTime? _subscriptionEndDate;

  GoldPlusService() {
    _loadSubscriptionStatus();
  }

  bool get isGoldPlus => _isGoldPlus;
  DateTime? get subscriptionEndDate => _subscriptionEndDate;

  Future<void> _loadSubscriptionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isGoldPlus = prefs.getBool(_isGoldPlusKey) ?? false;

    final endDateString = prefs.getString(_subscriptionEndDateKey);
    if (endDateString != null) {
      _subscriptionEndDate = DateTime.parse(endDateString);
      // Check if subscription has expired
      if (_subscriptionEndDate!.isBefore(DateTime.now())) {
        await cancelSubscription();
      }
    }

    notifyListeners();
  }

  Future<bool> upgradeToGoldPlus() async {
    try {
      // TODO: Implement actual payment processing
      // This is a placeholder for the payment integration

      // For demo purposes, we'll just set the subscription
      final prefs = await SharedPreferences.getInstance();
      _isGoldPlus = true;
      _subscriptionEndDate = DateTime.now().add(const Duration(days: 30));

      await prefs.setBool(_isGoldPlusKey, true);
      await prefs.setString(_subscriptionEndDateKey, _subscriptionEndDate!.toIso8601String());

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error upgrading to Gold Plus: $e');
      return false;
    }
  }

  Future<void> cancelSubscription() async {
    final prefs = await SharedPreferences.getInstance();
    _isGoldPlus = false;
    _subscriptionEndDate = null;

    await prefs.setBool(_isGoldPlusKey, false);
    await prefs.remove(_subscriptionEndDateKey);

    notifyListeners();
  }

  // Feature-specific methods
  bool canAccessPriorityMatching() {
    return _isGoldPlus;
  }

  bool canSeeLikes() {
    return _isGoldPlus;
  }

  bool hasUnlimitedMessages() {
    return _isGoldPlus;
  }

  bool hasVerifiedBadge() {
    return _isGoldPlus;
  }

  // Helper method to check if subscription is active
  bool isSubscriptionActive() {
    if (!_isGoldPlus || _subscriptionEndDate == null) return false;
    return _subscriptionEndDate!.isAfter(DateTime.now());
  }

  // Helper method to get remaining days
  int getRemainingDays() {
    if (!isSubscriptionActive()) return 0;
    return _subscriptionEndDate!.difference(DateTime.now()).inDays;
  }
}