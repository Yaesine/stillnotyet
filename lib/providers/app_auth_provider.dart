// lib/providers/app_auth_provider.dart - Updated with Apple Sign In

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../services/firestore_service.dart';
import '../services/notifications_service.dart';

class AppAuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final NotificationsService _notificationsService = NotificationsService();
  User? _user;
  String? _errorMessage;
  bool _isLoading = true;
  bool _isInitialized = false;

  // Getters
  User? get user => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;
  String get currentUserId => _auth.currentUser?.uid ?? '';
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isInitialized => _isInitialized;

  AppAuthProvider() {
    _user = _auth.currentUser;
    if (_user != null) {
      print('User is already authenticated: ${_user?.uid}');
    } else {
      print('No authenticated user at startup');
    }

    _auth.authStateChanges().listen((User? user) {
      print('Auth state changed: ${user?.uid ?? 'No user'}');
      _user = user;
      notifyListeners();
    });
  }

  Future<void> initializeAuth() async {
    if (_isInitialized) return;

    _isInitialized = true;
    _isLoading = false;
    notifyListeners();

    try {
      _continueAuthInitialization();
    } catch (e) {
      print('Initial auth check error: $e');
    }
  }

  Future<void> _continueAuthInitialization() async {
    try {
      _user = _auth.currentUser;
    } catch (e) {
      print('Background auth initialization error: $e');
    }
  }

  // Login with email and password
  Future<bool> login(String email, String password) async {
    try {
      _errorMessage = null;
      _isLoading = true;
      notifyListeners();

      print('Attempting login with email: $email');

      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = result.user;

      if (user != null) {
        await _notificationsService.saveTokenToDatabase(user.uid);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', user.uid);
        print('User logged in successfully: ${user.uid}');
      }

      _isLoading = false;
      notifyListeners();
      return user != null;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getReadableAuthError(e);
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      print('Login error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Register new user
  Future<bool> register(String name, String email, String password) async {
    try {
      _errorMessage = null;
      _isLoading = true;
      notifyListeners();

      final formattedEmail = email.trim().toLowerCase();

      print('Starting registration for $formattedEmail...');

      final tempResult = await _auth.createUserWithEmailAndPassword(
        email: formattedEmail,
        password: password,
      );

      final tempUser = tempResult.user;
      if (tempUser == null) {
        print('Failed to create Firebase Auth account');
        _errorMessage = 'Failed to create user account';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final userId = tempUser.uid;
      print('Firebase Auth account created with ID: $userId');

      await _auth.signOut();
      print('Temporary signout to avoid PigeonUserDetails error');

      try {
        await _firestoreService.createNewUser(userId, name, formattedEmail);
        print('Firestore profile created for user: $name ($formattedEmail)');
      } catch (e) {
        print('Error creating Firestore profile: $e');
      }

      try {
        final signInResult = await _auth.signInWithEmailAndPassword(
          email: formattedEmail,
          password: password,
        );

        final signedInUser = signInResult.user;
        if (signedInUser == null) {
          print('Failed to sign back in after profile creation');
          _errorMessage = 'Account created but login failed. Please try logging in manually.';
          _isLoading = false;
          notifyListeners();
          return false;
        }

        print('Successfully signed back in as: $userId');
      } catch (e) {
        print('Error signing back in: $e');
        _errorMessage = 'Account created but login failed. Please try logging in manually.';
        _isLoading = false;
        notifyListeners();
        return true;
      }

      try {
        await _notificationsService.saveTokenToDatabase(userId);
        print('FCM token saved');
      } catch (e) {
        print('Non-critical error saving FCM token: $e');
      }

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', userId);
      } catch (e) {
        print('Error saving to SharedPreferences: $e');
      }

      print('Registration completed successfully with bypass method');
      _isLoading = false;
      notifyListeners();
      return true;

    } on FirebaseAuthException catch (e) {
      _errorMessage = _getReadableAuthError(e);
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      print('Registration error: $e');
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Google Sign In using Firebase Auth directly
  Future<bool> signInWithGoogle() async {
    try {
      // The actual Google sign-in is handled by the native implementation
      // This method now just handles the post-sign-in setup

      // Check if user is already signed in (from native sign-in)
      final user = _auth.currentUser;

      if (user != null) {
        print('Google Sign-In successful, setting up user: ${user.uid}');

        // Create/update user in Firestore
        await _firestoreService.createNewUser(
            user.uid,
            user.displayName ?? 'New User',
            user.email ?? ''
        );

        // Try to save notification token, but don't fail if it doesn't work
        try {
          await _notificationsService.saveTokenToDatabase(user.uid);
        } catch (e) {
          print('Notification token error (non-blocking): $e');
          // Continue anyway - notifications aren't critical for sign-in
        }

        // Save to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', user.uid);

        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      print('Google Sign In setup error: $e');
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
  // APPLE SIGN IN IMPLEMENTATION
  Future<bool> signInWithApple() async {
    try {
      print('Starting Apple Sign In...');

      // To prevent replay attacks with Firebase, we will generate a nonce
      // and include it in the request
      final rawNonce = generateNonce();
      final nonce = sha256ofString(rawNonce);

      // Request credential for the currently signed in Apple account
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      print('Apple Sign In credential received');

      // Create an OAuth credential from the credential returned by Apple
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      // Sign in the user with Firebase. If the nonce we generated earlier does
      // not match the nonce in the credential, sign in will fail.
      final authResult = await _auth.signInWithCredential(oauthCredential);

      final user = authResult.user;

      if (user != null) {
        print('Apple Sign In successful: ${user.uid}');

        // Get the display name from Apple credential if available
        String displayName = user.displayName ?? '';

        // If no display name from Firebase, try to construct from Apple credential
        if (displayName.isEmpty && appleCredential.givenName != null) {
          displayName = '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'.trim();
        }

        // If still no name, use a default
        if (displayName.isEmpty) {
          displayName = 'Apple User';
        }

        // Create or update user in Firestore
        await _firestoreService.createNewUser(
            user.uid,
            displayName,
            user.email ?? appleCredential.email ?? ''
        );

        // Save FCM token
        await _notificationsService.saveTokenToDatabase(user.uid);

        // Save to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', user.uid);

        notifyListeners();
        return true;
      }

      return false;
    } on SignInWithAppleAuthorizationException catch (e) {
      print('Apple Sign In authorization error: ${e.code} - ${e.message}');

      switch (e.code) {
        case AuthorizationErrorCode.canceled:
          _errorMessage = 'Sign in was cancelled';
          break;
        case AuthorizationErrorCode.failed:
          _errorMessage = 'Sign in failed. Please try again.';
          break;
        case AuthorizationErrorCode.invalidResponse:
          _errorMessage = 'Invalid response from Apple. Please try again.';
          break;
        case AuthorizationErrorCode.notHandled:
          _errorMessage = 'Sign in not handled. Please try again.';
          break;
        case AuthorizationErrorCode.unknown:
          _errorMessage = 'An unknown error occurred. Please try again.';
          break;
        default:
          _errorMessage = 'Apple sign in failed. Please try again.';
      }

      notifyListeners();
      return false;
    } catch (e) {
      print('Apple Sign In error: $e');
      _errorMessage = 'Apple sign in failed: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Generates a cryptographically secure random nonce
  String generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  // Returns the sha256 hash of [input] in hex notation
  String sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Phone Auth methods remain the same
  Future<String?> sendOtp(String phoneNumber, {bool useWhatsApp = false}) async {
    try {
      _errorMessage = null;
      _isLoading = true;
      notifyListeners();

      print('Attempting to send OTP to: $phoneNumber');

      // For WhatsApp simulation (development purposes only)
      if (useWhatsApp) {
        final simulatedOtp = '123456';
        print('Simulated WhatsApp OTP: $simulatedOtp');
        return 'whatsapp-verification-${DateTime.now().millisecondsSinceEpoch}';
      }

      // Regular SMS verification
      Completer<String?> completer = Completer<String?>();

      // Ensure the phone number is properly formatted in E.164 format
      // This is critical - the number must start with + and include country code
      if (!phoneNumber.startsWith('+')) {
        phoneNumber = '+' + phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
      }

      print('Formatted phone number for verification: $phoneNumber');

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 120),
        verificationCompleted: (PhoneAuthCredential credential) async {
          print('Auto-verification completed (Android only)');
          try {
            final userCredential = await _auth.signInWithCredential(credential);
            final user = userCredential.user;

            if (user != null) {
              print('User auto-signed in with phone: ${user.uid}');
              await _firestoreService.createNewUser(
                  user.uid,
                  user.displayName ?? 'Phone User',
                  user.phoneNumber ?? ''
              );
              await _notificationsService.saveTokenToDatabase(user.uid);

              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('userId', user.uid);

              _isLoading = false;
              notifyListeners();

              if (!completer.isCompleted) {
                completer.complete('auto-verified');
              }
            }
          } catch (e) {
            print('Error in auto-verification: $e');
            _errorMessage = 'Verification error: ${e.toString()}';
            _isLoading = false;
            notifyListeners();

            if (!completer.isCompleted) {
              completer.complete(null);
            }
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          print('Phone verification failed: ${e.code} - ${e.message}');
          _errorMessage = _getReadablePhoneAuthError(e);
          _isLoading = false;
          notifyListeners();

          if (!completer.isCompleted) {
            completer.complete(null);
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          print('SMS code sent, verification ID: $verificationId');
          _isLoading = false;
          notifyListeners();

          if (!completer.isCompleted) {
            completer.complete(verificationId);
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print('Auto-retrieval timeout for verification ID: $verificationId');
          _isLoading = false;
          notifyListeners();

          if (!completer.isCompleted) {
            completer.complete(verificationId);
          }
        },
        // Force using test phone numbers in test environment (remove in production)
        // forceResendingToken: forceResendingToken,
      );

      return completer.future;
    } catch (e) {
      print('Send OTP error: $e');
      _errorMessage = 'Error sending verification code: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

// Add this helper method to provide better error messages
// Update the _getReadablePhoneAuthError method in lib/providers/app_auth_provider.dart
  String _getReadablePhoneAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'The phone number format is incorrect. Please enter a valid number with country code.';
      case 'missing-phone-number':
        return 'Please provide a phone number.';
      case 'quota-exceeded':
        return 'SMS quota exceeded. Please try again later or use WhatsApp verification.';
      case 'user-disabled':
        return 'This phone number has been disabled.';
      case 'captcha-check-failed':
        return 'reCAPTCHA verification failed. Please try again.';
      case 'app-not-authorized':
        return 'This app is not authorized to use Firebase Authentication.';
      case 'network-request-failed':
        return 'Network error. Please check your connection and try again.';
      case 'too-many-requests':
        return 'Too many verification attempts. For security reasons, please wait 1 hour and try again, or use WhatsApp verification instead.';
      default:
        return e.message ?? 'An error occurred during phone verification.';
    }
  }
  Future<bool> verifyOtp(String verificationId, String otp) async {
    try {
      _errorMessage = null;
      _isLoading = true;
      notifyListeners();

      print('Verifying OTP: verification ID=$verificationId, OTP=$otp');

      if (verificationId.startsWith('whatsapp-verification-')) {
        // This is a simulated WhatsApp verification
        if (otp.length == 6 && RegExp(r'^\d{6}$').hasMatch(otp)) {
          print('Simulated WhatsApp OTP verification successful');

          // For development/testing only
          // In production, use actual phone verification instead
          final userCredential = await _auth.signInAnonymously();
          final user = userCredential.user;

          if (user != null) {
            await _firestoreService.createNewUser(
                user.uid,
                'WhatsApp User',
                ''
            );

            await _notificationsService.saveTokenToDatabase(user.uid);

            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('userId', user.uid);

            _isLoading = false;
            notifyListeners();
            return true;
          }
          _isLoading = false;
          notifyListeners();
          return false;
        } else {
          print('Invalid OTP format for WhatsApp verification');
          _errorMessage = 'Invalid verification code. Please enter a 6-digit number.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } else {
        // Standard SMS verification
        try {
          PhoneAuthCredential credential = PhoneAuthProvider.credential(
            verificationId: verificationId,
            smsCode: otp,
          );

          UserCredential userCredential = await _auth.signInWithCredential(credential);
          final user = userCredential.user;

          if (user != null) {
            print('Phone verification successful for user ID: ${user.uid}');

            await _firestoreService.createNewUser(
                user.uid,
                user.displayName ?? 'Phone User',
                user.phoneNumber ?? ''
            );

            await _notificationsService.saveTokenToDatabase(user.uid);

            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('userId', user.uid);

            _isLoading = false;
            notifyListeners();
            return true;
          }
          _isLoading = false;
          notifyListeners();
          return false;
        } catch (e) {
          print('Error verifying OTP: $e');
          _errorMessage = 'Invalid verification code. Please check and try again.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }
    } catch (e) {
      print('Verify OTP error: $e');
      _errorMessage = 'Error verifying code: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  // Logout
  Future<void> logout() async {
    try {
      print('Attempting logout');

      await _auth.signOut();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('userId');

      _user = null;
      print('User logged out successfully');
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      print('Logout error: $e');
      notifyListeners();
    }
  }

  // Convert Firebase auth errors to user-friendly messages
  String _getReadableAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password. Please try again.';
      case 'email-already-in-use':
        return 'This email is already registered. Please login or use a different email.';
      case 'weak-password':
        return 'Password is too weak. Please use a stronger password.';
      case 'invalid-email':
        return 'Invalid email address. Please enter a valid email.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'operation-not-allowed':
        return 'Operation not allowed. Please contact support.';
      case 'too-many-requests':
        return 'Too many login attempts. Please try again later.';
      case 'invalid-verification-code':
        return 'Invalid verification code. Please check and try again.';
      case 'invalid-verification-id':
        return 'Invalid verification ID. Please request a new code.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email but different sign-in credentials.';
      default:
        return e.message ?? 'An error occurred during authentication.';
    }
  }

  // Check if user exists in SharedPreferences
  Future<bool> checkUserLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    print('Checking if user is logged in from SharedPreferences: $userId');

    if (userId != null && userId.isNotEmpty) {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        await prefs.remove('userId');
        print('User ID found in SharedPreferences but not in Firebase Auth, clearing preferences');
        return false;
      }
      print('User is logged in: $userId');
      return true;
    }
    print('User is not logged in');
    return false;
  }
}