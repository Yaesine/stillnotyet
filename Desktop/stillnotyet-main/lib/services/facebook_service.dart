// lib/services/facebook_service.dart
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class FacebookService {
  static Future<void> initialize() async {
    try {
      // Clear any previous Facebook session
      await FacebookAuth.instance.logOut();
      print('Facebook SDK initialized and previous sessions cleared');
    } catch (e) {
      print('Error initializing Facebook SDK: $e');
      // Don't throw the error - we still want to try the login
    }
  }
}