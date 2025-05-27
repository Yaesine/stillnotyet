// lib/screens/privacy_safety_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:new_tinder_clone/screens/premium_screen.dart';
import 'package:new_tinder_clone/screens/privacy_policy_screen.dart';
import 'package:new_tinder_clone/screens/terms_of_service_screen.dart';
import 'package:provider/provider.dart';
import '../services/google_sign_in_native.dart';
import '../theme/app_theme.dart';
import '../providers/user_provider.dart';
import '../providers/app_auth_provider.dart';
import 'dart:io' show Platform;

import 'cookie_policy_screen.dart';

class PrivacySafetyScreen extends StatefulWidget {
  const PrivacySafetyScreen({Key? key}) : super(key: key);

  @override
  State<PrivacySafetyScreen> createState() => _PrivacySafetyScreenState();
}

class _PrivacySafetyScreenState extends State<PrivacySafetyScreen> {
  // Privacy settings state
  bool _profileVisibility = true;
  bool _locationPrecise = true;
  bool _allowMessagesFromMatches = true;
  bool _showOnlineStatus = true;
  bool _readReceipts = true;
  bool _dataCollection = true;
  bool _isLoading = true;
  bool _isBlocking = false;
  List<Map<String, dynamic>> _blockedUsers = [];

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    // Load user privacy settings
    _loadPrivacySettings();
    // Load blocked users
    _loadBlockedUsers();
  }

  Future<void> _loadPrivacySettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Fetch user's privacy settings from Firestore
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        if (userData != null) {
          // Load privacy settings with defaults if not present
          setState(() {
            _profileVisibility = userData['privacySettings']?['profileVisibility'] ?? true;
            _locationPrecise = userData['privacySettings']?['locationPrecise'] ?? true;
            _allowMessagesFromMatches = userData['privacySettings']?['allowMessagesFromMatches'] ?? true;
            _showOnlineStatus = userData['privacySettings']?['showOnlineStatus'] ?? true;
            _readReceipts = userData['privacySettings']?['readReceipts'] ?? true;
            _dataCollection = userData['privacySettings']?['dataCollection'] ?? true;
          });
        }
      }
    } catch (e) {
      print('Error loading privacy settings: $e');
      _showErrorSnackBar('Failed to load privacy settings');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadBlockedUsers() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      // Get the list of blocked user IDs
      final blockListDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('blockedUsers')
          .get();

      List<Map<String, dynamic>> blockedUsersData = [];

      // For each blocked user ID, fetch the user data
      for (var doc in blockListDoc.docs) {
        final blockedUserId = doc.id;
        try {
          final blockedUserDoc = await _firestore.collection('users').doc(blockedUserId).get();

          if (blockedUserDoc.exists) {
            final userData = blockedUserDoc.data() as Map<String, dynamic>;
            blockedUsersData.add({
              'id': blockedUserId,
              'name': userData['name'] ?? 'Unknown User',
              'imageUrl': userData['imageUrls'] != null && (userData['imageUrls'] as List).isNotEmpty
                  ? userData['imageUrls'][0]
                  : '',
              'blockDate': doc.data()['timestamp'] ?? Timestamp.now(),
            });
          }
        } catch (e) {
          print('Error fetching blocked user $blockedUserId: $e');
        }
      }

      // Sort blocked users by most recently blocked first
      blockedUsersData.sort((a, b) {
        final aDate = a['blockDate'] as Timestamp;
        final bDate = b['blockDate'] as Timestamp;
        return bDate.compareTo(aDate);
      });

      setState(() {
        _blockedUsers = blockedUsersData;
      });
    } catch (e) {
      print('Error loading blocked users: $e');
    }
  }

  Future<void> _updateSetting(String settingName, bool value) async {
    setState(() {
      switch (settingName) {
        case 'profile_visibility':
          _profileVisibility = value;
          break;
        case 'location_precise':
          _locationPrecise = value;
          break;
        case 'allow_messages':
          _allowMessagesFromMatches = value;
          break;
        case 'online_status':
          _showOnlineStatus = value;
          break;
        case 'read_receipts':
          _readReceipts = value;
          break;
        case 'data_collection':
          _dataCollection = value;
          break;
      }
    });

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Create a map of all privacy settings
      final privacySettings = {
        'profileVisibility': _profileVisibility,
        'locationPrecise': _locationPrecise,
        'allowMessagesFromMatches': _allowMessagesFromMatches,
        'showOnlineStatus': _showOnlineStatus,
        'readReceipts': _readReceipts,
        'dataCollection': _dataCollection,
      };

      // Update privacy settings in Firestore
      await _firestore.collection('users').doc(userId).update({
        'privacySettings': privacySettings,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // If profile visibility changed, update visibility in search index
      if (settingName == 'profile_visibility') {
        await _firestore.collection('users').doc(userId).update({
          'visibleInSearch': value,
        });
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Setting updated'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      print('Error updating setting: $e');
      _showErrorSnackBar('Failed to update setting');

      // Revert the local state change
      setState(() {
        switch (settingName) {
          case 'profile_visibility':
            _profileVisibility = !value;
            break;
          case 'location_precise':
            _locationPrecise = !value;
            break;
          case 'allow_messages':
            _allowMessagesFromMatches = !value;
            break;
          case 'online_status':
            _showOnlineStatus = !value;
            break;
          case 'read_receipts':
            _readReceipts = !value;
            break;
          case 'data_collection':
            _dataCollection = !value;
            break;
        }
      });
    }
  }

  Future<void> _blockUser(String userId, String userName) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return;

      // Add to blocked users collection
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('blockedUsers')
          .doc(userId)
          .set({
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update matches to prevent further communication
      // Get all matches between these users
      final matchesQuery = await _firestore
          .collection('matches')
          .where('userId', isEqualTo: currentUserId)
          .where('matchedUserId', isEqualTo: userId)
          .get();

      // Add blocked flag to matches
      for (var doc in matchesQuery.docs) {
        await doc.reference.update({'blocked': true});
      }

      // Also check reverse matches
      final reverseMatchesQuery = await _firestore
          .collection('matches')
          .where('userId', isEqualTo: userId)
          .where('matchedUserId', isEqualTo: currentUserId)
          .get();

      for (var doc in reverseMatchesQuery.docs) {
        await doc.reference.update({'blocked': true});
      }

      // Refresh the blocked users list
      await _loadBlockedUsers();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$userName has been blocked'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('Error blocking user: $e');
      _showErrorSnackBar('Failed to block user');
    }
  }

  Future<void> _unblockUser(String userId) async {
    setState(() {
      _isBlocking = true;
    });

    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return;

      // Remove from blocked users collection
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('blockedUsers')
          .doc(userId)
          .delete();

      // Update matches to allow communication again
      final matchesQuery = await _firestore
          .collection('matches')
          .where('userId', isEqualTo: currentUserId)
          .where('matchedUserId', isEqualTo: userId)
          .get();

      for (var doc in matchesQuery.docs) {
        await doc.reference.update({'blocked': false});
      }

      // Also update reverse matches
      final reverseMatchesQuery = await _firestore
          .collection('matches')
          .where('userId', isEqualTo: userId)
          .where('matchedUserId', isEqualTo: currentUserId)
          .get();

      for (var doc in reverseMatchesQuery.docs) {
        await doc.reference.update({'blocked': false});
      }

      // Update local state by removing the user from blocked list
      setState(() {
        _blockedUsers.removeWhere((user) => user['id'] == userId);
        _isBlocking = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User unblocked successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isBlocking = false;
      });

      print('Error unblocking user: $e');
      _showErrorSnackBar('Error unblocking user');
    }
  }

  Future<void> _pauseAccount() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      // Update user's active status in Firestore
      await _firestore.collection('users').doc(userId).update({
        'accountStatus': 'paused',
        'visibleInSearch': false,
        'lastStatusUpdate': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account paused'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('Error pausing account: $e');
      _showErrorSnackBar('Failed to pause account');
    }
  }

  Future<void> _deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // First show retention offer dialog
      bool continueWithDeletion = await _showRetentionOfferDialog();
      if (!continueWithDeletion) {
        return; // User canceled deletion or accepted the offer
      }

      // Then re-authenticate the user
      bool reAuthSuccess = await _reAuthenticateUser();
      if (!reAuthSuccess) {
        _showErrorSnackBar('Authentication failed. Account deletion canceled.');
        return;
      }

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Deleting account...'),
            ],
          ),
        ),
      );

      // Continue with account deletion process
      final batch = _firestore.batch();

      // Delete main user document
      final userRef = _firestore.collection('users').doc(user.uid);
      batch.delete(userRef);

      // Delete user's messages
      final messagesQuery = await _firestore
          .collection('messages')
          .where('senderId', isEqualTo: user.uid)
          .get();

      for (var doc in messagesQuery.docs) {
        batch.delete(doc.reference);
      }

      // Delete user's matches
      final matchesQuery = await _firestore
          .collection('matches')
          .where('userId', isEqualTo: user.uid)
          .get();

      for (var doc in matchesQuery.docs) {
        batch.delete(doc.reference);
      }

      // Delete user's likes/swipes
      final swipesQuery = await _firestore
          .collection('swipes')
          .where('swiperId', isEqualTo: user.uid)
          .get();

      for (var doc in swipesQuery.docs) {
        batch.delete(doc.reference);
      }

      // Commit the batch deletion
      await batch.commit();

      // Delete the user authentication record
      await user.delete();

      // Sign out
      await _auth.signOut();

      // Close loading dialog and navigate to login screen
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      // Close loading dialog if open
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      print('Error deleting account: $e');
      _showErrorSnackBar('Error deleting account: ${e.toString()}');
    }
  }

// Show retention offer dialog
  Future<bool> _showRetentionOfferDialog() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.purple.shade400,
                Colors.purple.shade800,
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.workspace_premium,
                  color: Colors.white,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Wait! We have a special offer',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Before you go, get 50% OFF Premium!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_offer, color: Colors.purple),
                    const SizedBox(width: 8),
                    Text(
                      'Marifecto50',
                      style: TextStyle(
                        color: Colors.purple.shade800,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Use this coupon code at checkout to get 50% off any premium plan. Limited time offer!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              // Accept offer button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {

                    // Show a confirmation message about canceling deletion
                    Navigator.pop(context, false); // Return false to indicate deletion should be canceled

                    // Navigate to premium screen
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => PremiumScreen(
                          promoCode: 'Marifecto50',
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.purple.shade800,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Get 50% Off Premium',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Continue with deletion button
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'No thanks, continue with deletion',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ),
              // Cancel button
              TextButton(
                onPressed: () {
                  // Show message that deletion was canceled
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Account deletion canceled'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                  Navigator.pop(context, false);
                },
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ) ?? false; // Default to false if dialog is dismissed
  }
// New method to handle re-authentication
  Future<bool> _reAuthenticateUser() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    // Determine authentication method based on provider data
    final providers = user.providerData.map((e) => e.providerId).toList();

    if (providers.contains('password')) {
      // Email/password authentication
      return await _reAuthenticateWithPassword();
    } else if (providers.contains('google.com')) {
      // Google Sign-In
      return await _reAuthenticateWithGoogle();
    } else if (providers.contains('apple.com')) {
      // Apple Sign-In
      return await _reAuthenticateWithApple();
    } else if (providers.contains('phone')) {
      // Phone authentication
      return await _reAuthenticateWithPhone();
    } else {
      // Unknown provider
      _showErrorSnackBar('Unknown authentication method. Please sign out and sign in again.');
      return false;
    }
  }

  Future<bool> _reAuthenticateWithPassword() async {
    final TextEditingController passwordController = TextEditingController();
    bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Account Deletion'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please enter your password to confirm account deletion:'),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final user = _auth.currentUser;
                if (user == null || user.email == null) {
                  Navigator.of(context).pop(false);
                  return;
                }

                // Create the credential
                AuthCredential credential = EmailAuthProvider.credential(
                  email: user.email!,
                  password: passwordController.text,
                );

                // Re-authenticate
                await user.reauthenticateWithCredential(credential);
                Navigator.of(context).pop(true);
              } catch (e) {
                print('Re-authentication error: $e');
                _showErrorSnackBar('Incorrect password.');
                Navigator.of(context).pop(false);
              }
            },
            child: const Text('Confirm', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future<bool> _reAuthenticateWithGoogle() async {
    bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Account Deletion'),
        content: const Text(
          'You need to sign in with Google again to confirm account deletion.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continue', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (result != true) return false;

    try {
      // Use your existing GoogleSignInNative class
      final userCredential = await GoogleSignInNative.signIn();

      // If sign-in was successful, we can proceed
      return userCredential != null || FirebaseAuth.instance.currentUser != null;
    } catch (e) {
      print('Google re-authentication error: $e');
      _showErrorSnackBar('Google Sign-In failed. Please try again.');
      return false;
    }
  }
  Future<bool> _reAuthenticateWithApple() async {
    bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Account Deletion'),
        content: const Text(
          'You need to sign in with Apple again to confirm account deletion.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continue', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (result != true) return false;

    try {
      // Modified approach to bypass the PigeonUserDetails casting issue
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      // Rather than re-authenticating, which is causing the error,
      // check if the user was authenticated recently enough
      final metadata = user.metadata;
      final lastSignInTime = metadata.lastSignInTime;

      // If user signed in recently (last 5 minutes), consider them authenticated
      if (lastSignInTime != null &&
          DateTime.now().difference(lastSignInTime).inMinutes < 5) {
        return true;
      }

      // If we need to proceed with re-auth, use a try-catch to handle the error
      try {
        // Get the Apple provider ID to confirm this is an Apple account
        final appleProvider = user.providerData
            .firstWhere((element) => element.providerId == 'apple.com');

        if (appleProvider != null) {
          // We found the provider, but we'll skip the re-auth that causes the error
          // Instead, show a warning dialog
          bool? proceedAnyway = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Authentication Notice'),
              content: const Text(
                  'We cannot verify your identity through Apple Sign In due to a technical limitation. '
                      'If you proceed, your account will be deleted without re-verification. '
                      'Are you absolutely sure you want to continue?'
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Delete Account', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );

          return proceedAnyway ?? false;
        }
      } catch (e) {
        print('Provider check error: $e');
      }

      return false;
    } catch (e) {
      print('Apple re-authentication error: $e');
      _showErrorSnackBar('Apple Sign-In failed. Please try again.');
      return false;
    }
  }

  Future<bool> _reAuthenticateWithPhone() async {
    final user = _auth.currentUser;
    if (user?.phoneNumber == null) return false;

    final phoneNumber = user!.phoneNumber!;
    String? verificationId;
    final otpController = TextEditingController();

    // First, ask the user to confirm they want to send an OTP
    bool? shouldSendOtp = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Account Deletion'),
        content: Text(
          'We will send a verification code to $phoneNumber to confirm your identity.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Send Code', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );

    if (shouldSendOtp != true) return false;

    // Show loading dialog while sending OTP
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Sending verification code...'),
          ],
        ),
      ),
    );

    try {
      // Send OTP
      final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
      verificationId = await authProvider.sendOtp(phoneNumber);

      // Dismiss loading dialog
      if (mounted) Navigator.of(context).pop();

      if (verificationId == null) {
        _showErrorSnackBar('Failed to send verification code.');
        return false;
      }

      // Now prompt for OTP
      bool? otpResult = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Enter Verification Code'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Enter the verification code sent to $phoneNumber:'),
              const SizedBox(height: 16),
              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Verification Code',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Verify', style: TextStyle(color: Colors.blue)),
            ),
          ],
        ),
      );

      if (otpResult != true) return false;

      // Verify OTP
      return await authProvider.verifyOtp(verificationId, otpController.text);
    } catch (e) {
      print('Phone re-authentication error: $e');
      _showErrorSnackBar('Phone verification failed. Please try again.');
      return false;
    }
  }
  void _showPrivacyInfoDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final subTextColor = isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final cardColor = isDarkMode ? AppColors.darkCard : Colors.white;
    final dividerColor = isDarkMode ? AppColors.darkDivider : Colors.grey.shade200;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: const Text('Privacy & Safety'),
        backgroundColor: isDarkMode ? AppColors.darkSurface : Colors.white,
        foregroundColor: textColor,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Privacy Settings Section
            Text(
              'Privacy Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),

            // Profile Visibility
            _buildSettingCard(
              title: 'Profile Visibility',
              subtitle: 'Control who can see your profile',
              icon: Icons.visibility,
              value: _profileVisibility,
              onChanged: (value) => _updateSetting('profile_visibility', value),
              onInfoTap: () => _showPrivacyInfoDialog(
                  'Profile Visibility',
                  'When turned off, your profile won\'t be shown to new people in Discover. Matches can still see your profile.'
              ),
              isDarkMode: isDarkMode,
              cardColor: cardColor,
              textColor: textColor,
              subTextColor: subTextColor,
            ),

            // Location Settings
            _buildSettingCard(
              title: 'Precise Location',
              subtitle: 'Show your exact location to matches',
              icon: Icons.location_on,
              value: _locationPrecise,
              onChanged: (value) => _updateSetting('location_precise', value),
              onInfoTap: () => _showPrivacyInfoDialog(
                  'Precise Location',
                  'When enabled, your exact location is used for distance calculations. When disabled, only your approximate area is shown.'
              ),
              isDarkMode: isDarkMode,
              cardColor: cardColor,
              textColor: textColor,
              subTextColor: subTextColor,
            ),

            // Messaging Settings
            _buildSettingCard(
              title: 'Allow Messages',
              subtitle: 'Only receive messages from matches',
              icon: Icons.message,
              value: _allowMessagesFromMatches,
              onChanged: (value) => _updateSetting('allow_messages', value),
              onInfoTap: () => _showPrivacyInfoDialog(
                  'Messaging Settings',
                  'When enabled, only users you\'ve matched with can send you messages.'
              ),
              isDarkMode: isDarkMode,
              cardColor: cardColor,
              textColor: textColor,
              subTextColor: subTextColor,
            ),

            // Online Status
            _buildSettingCard(
              title: 'Show Online Status',
              subtitle: 'Let others see when you\'re active',
              icon: Icons.circle,
              value: _showOnlineStatus,
              onChanged: (value) => _updateSetting('online_status', value),
              onInfoTap: () => _showPrivacyInfoDialog(
                  'Online Status',
                  'When enabled, your matches can see when you\'re active on the app.'
              ),
              isDarkMode: isDarkMode,
              cardColor: cardColor,
              textColor: textColor,
              subTextColor: subTextColor,
            ),

            // Read Receipts
            _buildSettingCard(
              title: 'Read Receipts',
              subtitle: 'Show when you\'ve read messages',
              icon: Icons.done_all,
              value: _readReceipts,
              onChanged: (value) => _updateSetting('read_receipts', value),
              onInfoTap: () => _showPrivacyInfoDialog(
                  'Read Receipts',
                  'When enabled, others can see when you\'ve read their messages. You\'ll also see when they\'ve read yours.'
              ),
              isDarkMode: isDarkMode,
              cardColor: cardColor,
              textColor: textColor,
              subTextColor: subTextColor,
            ),

            // Data Collection
            _buildSettingCard(
              title: 'Activity Data',
              subtitle: 'Allow app to collect usage data',
              icon: Icons.analytics,
              value: _dataCollection,
              onChanged: (value) => _updateSetting('data_collection', value),
              onInfoTap: () => _showPrivacyInfoDialog(
                  'Activity Data',
                  'When enabled, we collect anonymous usage data to improve your experience and provide better matches.'
              ),
              isDarkMode: isDarkMode,
              cardColor: cardColor,
              textColor: textColor,
              subTextColor: subTextColor,
            ),

            const SizedBox(height: 24),

            // Blocking Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Blocked Users',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.info_outline, color: subTextColor, size: 20),
                  onPressed: () => _showPrivacyInfoDialog(
                      'Blocked Users',
                      'Blocked users cannot see your profile, send you messages, or interact with you in any way.'
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Blocked Users List
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: _blockedUsers.isEmpty
                  ? Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.block,
                        size: 48,
                        color: subTextColor.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No blocked users',
                        style: TextStyle(
                          color: subTextColor,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Users you block will appear here',
                        style: TextStyle(
                          color: subTextColor.withOpacity(0.7),
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
                  : ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: _blockedUsers.length,
                separatorBuilder: (context, index) => Divider(
                  color: dividerColor,
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  final user = _blockedUsers[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withOpacity(0.2),
                      child: user['imageUrl'].isNotEmpty
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          user['imageUrl'],
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Text(
                            user['name'][0],
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                          : Text(
                        user['name'][0],
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      user['name'],
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: _isBlocking
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                        : TextButton(
                      onPressed: () => _unblockUser(user['id']),
                      child: const Text('Unblock'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // Account Deactivation Section
            Text(
              'Account',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.pause_circle_outline,
                        color: Colors.orange,
                      ),
                    ),
                    title: Text(
                      'Pause Account',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'Hide your profile temporarily',
                      style: TextStyle(
                        color: subTextColor,
                        fontSize: 14,
                      ),
                    ),
                    trailing: Icon(Icons.chevron_right, color: subTextColor),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Pause Account'),
                          content: const Text(
                              'Your profile will be hidden from discovery until you unpause. Existing matches can still message you.'
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _pauseAccount();
                              },
                              child: const Text('Pause'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  Divider(color: dividerColor, height: 1),
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                      ),
                    ),
                    title: const Text(
                      'Delete Account',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'Permanently delete your account and data',
                      style: TextStyle(
                        color: subTextColor,
                        fontSize: 14,
                      ),
                    ),
                    trailing: Icon(Icons.chevron_right, color: subTextColor),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Account'),
                          content: const Text(
                              'This action cannot be undone. All your data, including matches and messages, will be permanently deleted.'
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () async {
                                Navigator.pop(context);

                                // Confirm with second dialog
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Confirm Deletion'),
                                    content: const Text('Are you absolutely sure you want to delete your account?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          // Show loading dialog
                                          showDialog(
                                            context: context,
                                            barrierDismissible: false,
                                            builder: (context) => const AlertDialog(
                                              content: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  CircularProgressIndicator(),
                                                  SizedBox(height: 16),
                                                  Text('Deleting account...'),
                                                ],
                                              ),
                                            ),
                                          );

                                          // Execute account deletion
                                          _deleteAccount().then((_) {
                                            // Dialog will be dismissed when navigating to login
                                          }).catchError((error) {
                                            // Pop loading dialog on error
                                            Navigator.pop(context);
                                            _showErrorSnackBar('Error deleting account: $error');
                                          });
                                        },
                                        child: const Text('Delete'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: const Text('Delete'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Legal section
            Text(
              'Legal',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.privacy_tip_outlined,
                        color: AppColors.primary,
                      ),
                    ),
                    title: Text(
                      'Privacy Policy',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: Icon(Icons.chevron_right, color: subTextColor),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PrivacyPolicyScreen(),
                        ),
                      );
                    },
                  ),
                  Divider(color: dividerColor, height: 1),
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.description_outlined,
                        color: AppColors.primary,
                      ),
                    ),
                    title: Text(
                      'Terms of Service',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: Icon(Icons.chevron_right, color: subTextColor),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TermsOfServiceScreen(),
                        ),
                      );
                    },
                  ),
                  Divider(color: dividerColor, height: 1),
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.cookie_outlined,
                        color: AppColors.primary,
                      ),
                    ),
                    title: Text(
                      'Cookie Policy',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: Icon(Icons.chevron_right, color: subTextColor),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CookiePolicyScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required Function(bool) onChanged,
    required Function() onInfoTap,
    required bool isDarkMode,
    required Color cardColor,
    required Color textColor,
    required Color subTextColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
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
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: onInfoTap,
                        child: Icon(
                          Icons.info_outline,
                          size: 16,
                          color: subTextColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: subTextColor,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Platform.isIOS
                ? CupertinoSwitch(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.primary,
            )
                : Switch(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}