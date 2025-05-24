import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GoogleSignInNative {
  static const platform = MethodChannel('com.yourapp/google_signin');

  static Future<UserCredential?> signIn() async {
    try {
      final result = await platform.invokeMethod('signIn');

      if (result != null) {
        final Map<String, dynamic> userData = Map<String, dynamic>.from(result);

        final credential = GoogleAuthProvider.credential(
          idToken: userData['idToken'],
          accessToken: userData['accessToken'],
        );

        try {
          // Try to sign in with credential
          return await FirebaseAuth.instance.signInWithCredential(credential);
        } catch (e) {
          // If there's a decoding error but user is authenticated, return null
          // The auth state listener will handle the user being signed in
          if (FirebaseAuth.instance.currentUser != null) {
            print('Sign in successful despite decoding error');
            return null;
          }
          // If there's a real error, rethrow it
          rethrow;
        }
      }
      return null;
    } on PlatformException catch (e) {
      if (e.code == 'NO_GOOGLE_APP') {
        throw Exception('Gmail or Google app is required. Please install it from App Store.');
      }
      throw Exception('Sign in failed: ${e.message}');
    }
  }
}