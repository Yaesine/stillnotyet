import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;

class ThemeProvider with ChangeNotifier {
  final String key = "theme_mode";
  SharedPreferences? _prefs;
  bool _isDarkMode = false;

  // New property to track if we should follow system
  bool _followSystem = true;
  final String _followSystemKey = "follow_system";

  bool get isDarkMode => _isDarkMode;
  bool get followSystem => _followSystem;

  // The actual theme mode considering all factors
  ThemeMode get themeMode {
    if (_followSystem) {
      // This will automatically update when system changes
      final window = WidgetsBinding.instance.platformDispatcher;
      final brightness = window.platformBrightness;
      return brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light;
    } else {
      return _isDarkMode ? ThemeMode.dark : ThemeMode.light;
    }
  }

  ThemeProvider() {
    _loadFromPrefs();
  }

  _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  _loadFromPrefs() async {
    await _initPrefs();
    _isDarkMode = _prefs?.getBool(key) ?? false;

    // Default to system for iOS, manual for Android
    _followSystem = _prefs?.getBool(_followSystemKey) ?? Platform.isIOS;

    notifyListeners();
  }

  _saveToPrefs() async {
    await _initPrefs();
    _prefs?.setBool(key, _isDarkMode);
    _prefs?.setBool(_followSystemKey, _followSystem);
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _followSystem = false; // When manually toggling, turn off follow system
    _saveToPrefs();
    notifyListeners();
  }

  void setFollowSystem(bool follow) {
    _followSystem = follow;
    _saveToPrefs();
    notifyListeners();
  }

  // Method to update the theme based on system brightness
  void updateWithSystemTheme(Brightness brightness) {
    if (_followSystem) {
      _isDarkMode = brightness == Brightness.dark;
      notifyListeners();
    }
  }
}