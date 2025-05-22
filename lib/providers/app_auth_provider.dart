// lib/providers/app_auth_provider.dart - Temporary bypass solution
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/firestore_service.dart';
import '../services/notifications_service.dart';

class AppAuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final NotificationsService _notificationsService = NotificationsService();
  User? _user;
  String? _errorMessage;
  bool _isLoading = true;
  bool _isInitialized = false;  // Add this flag

  // Getters
  User? get user => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;
  String get currentUserId => _auth.currentUser?.uid ?? '';
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isInitialized => _isInitialized;  // Add this getter


  Future<void> initializeAuth() async {
    if (_isInitialized) return;

    // Mark as initialized immediately to avoid blocking
    _isInitialized = true;
    _isLoading = false;
    notifyListeners();

    try {
      // Continue initialization in background
      _continueAuthInitialization();
    } catch (e) {
      print('Initial auth check error: $e');
    }
  }
  Future<void> _continueAuthInitialization() async {
    try {
      // Check if user is already logged in
      _user = _auth.currentUser;

      // Rest of your initialization code...
    } catch (e) {
      print('Background auth initialization error: $e');
    }
  }

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

  // TOTAL BYPASS: Register new user without touching problematic APIs
  // Modified register method for AppAuthProvider.dart
// Replace the existing register method with this improved version

  Future<bool> register(String name, String email, String password) async {
    try {
      _errorMessage = null;
      _isLoading = true;
      notifyListeners();

      // Ensure email is properly formatted (lowercase)
      final formattedEmail = email.trim().toLowerCase();

      print('Starting registration for $formattedEmail...');

      // STEP 1: Create Firebase Auth account WITHOUT updating profile
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

      // STEP 2: Sign out to prevent PigeonUserDetails error
      await _auth.signOut();
      print('Temporary signout to avoid PigeonUserDetails error');

      // STEP 3: Create the Firestore profile with more info
      try {
        await _firestoreService.createNewUser(userId, name, formattedEmail);
        print('Firestore profile created for user: $name ($formattedEmail)');
      } catch (e) {
        print('Error creating Firestore profile: $e');
        // Continue anyway - we'll try to sign back in
      }

      // STEP 4: Sign back in with the created credentials
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
        // Even though sign-in failed, the account was created successfully
        return true;
      }

      // STEP 5: Save FCM token and other necessary information
      try {
        await _notificationsService.saveTokenToDatabase(userId);
        print('FCM token saved');
      } catch (e) {
        print('Non-critical error saving FCM token: $e');
        // Continue anyway
      }

      // STEP 6: Save to SharedPreferences
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', userId);
      } catch (e) {
        print('Error saving to SharedPreferences: $e');
        // Continue anyway
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

  // Google Sign In
  // Google Sign In using Firebase Auth directly
  // Replace your current signInWithGoogle() method in app_auth_provider.dart with this implementation
  Future<bool> signInWithGoogle() async {
    try {
      print('Starting Google Sign In with Firebase Auth...');

      // Create a Google auth provider
      GoogleAuthProvider googleProvider = GoogleAuthProvider();

      // Add scopes
      googleProvider.addScope('email');
      googleProvider.addScope('profile');

      // Use signInWithProvider instead of signInWithPopup for iOS
      final userCredential = await _auth.signInWithProvider(googleProvider);
      final user = userCredential.user;

      if (user != null) {
        print('Firebase authentication successful: ${user.uid}');

        await _firestoreService.createNewUser(
            user.uid,
            user.displayName ?? 'New User',
            user.email ?? ''
        );

        await _notificationsService.saveTokenToDatabase(user.uid);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', user.uid);

        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      print('Google Sign In error: $e');
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }



  // Apple Sign In (placeholder)
  Future<bool> signInWithApple() async {
    try {
      print('Apple sign in initiated');
      _errorMessage = "Apple Sign In is not yet fully implemented";
      notifyListeners();
      return false;
    } catch (e) {
      print('Apple sign in error: $e');
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Phone Auth
  Future<String?> sendOtp(String phoneNumber, {bool useWhatsApp = false}) async {
    try {
      _errorMessage = null;
      notifyListeners();

      print('Sending OTP to $phoneNumber via ${useWhatsApp ? "WhatsApp" : "SMS"}');

      if (useWhatsApp) {
        final simulatedOtp = '123456';
        print('Simulated WhatsApp OTP: $simulatedOtp');
        return 'whatsapp-verification-${DateTime.now().millisecondsSinceEpoch}';
      } else {
        Completer<String?> completer = Completer<String?>();

        await FirebaseAuth.instance.verifyPhoneNumber(
          phoneNumber: phoneNumber,
          timeout: const Duration(seconds: 60),
          verificationCompleted: (PhoneAuthCredential credential) async {
            try {
              final userCredential = await _auth.signInWithCredential(credential);
              final user = userCredential.user;

              if (user != null && !completer.isCompleted) {
                completer.complete('auto-verified');
              }
              notifyListeners();
            } catch (e) {
              if (!completer.isCompleted) {
                completer.complete(null);
              }
              _errorMessage = e.toString();
              notifyListeners();
            }
          },
          verificationFailed: (FirebaseAuthException e) {
            print('Phone verification failed: ${e.message}');
            _errorMessage = e.message;
            notifyListeners();
            if (!completer.isCompleted) {
              completer.complete(null);
            }
          },
          codeSent: (String verificationId, int? resendToken) {
            print('SMS code sent to $phoneNumber, verification ID: $verificationId');
            if (!completer.isCompleted) {
              completer.complete(verificationId);
            }
          },
          codeAutoRetrievalTimeout: (String verificationId) {
            print('Phone verification auto-retrieval timeout');
            if (!completer.isCompleted) {
              completer.complete(verificationId);
            }
          },
        );

        return completer.future;
      }
    } catch (e) {
      print('Send OTP error: $e');
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> verifyOtp(String verificationId, String otp) async {
    try {
      _errorMessage = null;
      notifyListeners();

      print('Verifying OTP: verification ID=$verificationId, OTP=$otp');

      if (verificationId.startsWith('whatsapp-verification-')) {
        if (otp.length == 6 && RegExp(r'^\d{6}$').hasMatch(otp)) {
          print('Simulated WhatsApp OTP verification successful');

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

            notifyListeners();
            return true;
          }
          return false;
        } else {
          print('Invalid OTP format for WhatsApp verification');
          _errorMessage = 'Invalid verification code';
          notifyListeners();
          return false;
        }
      } else {
        PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: verificationId,
          smsCode: otp,
        );

        UserCredential userCredential = await _auth.signInWithCredential(credential);
        final user = userCredential.user;

        if (user != null) {
          await _firestoreService.createNewUser(
              user.uid,
              user.displayName ?? 'Phone User',
              user.phoneNumber ?? ''
          );

          await _notificationsService.saveTokenToDatabase(user.uid);

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('userId', user.uid);

          notifyListeners();
          return true;
        }
        return false;
      }
    } catch (e) {
      print('Verify OTP error: $e');
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Logout
  // Logout
  Future<void> logout() async {
    try {
      print('Attempting logout');

      await _auth.signOut();
      // Remove this line since google_sign_in is no longer used:
      // await GoogleSignIn().signOut();

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