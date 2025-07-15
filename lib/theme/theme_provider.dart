import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for managing app theme settings
class ThemeProvider extends ChangeNotifier {
  /// Key for storing theme preference in SharedPreferences
  static const String _themePreferenceKey = 'theme_mode';
  
  /// Current theme mode
  ThemeMode _themeMode = ThemeMode.system;
  
  /// Get current theme mode
  ThemeMode get themeMode => _themeMode;
  
  /// Check if dark mode is enabled
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  
  /// Check if light mode is enabled
  bool get isLightMode => _themeMode == ThemeMode.light;
  
  /// Check if system mode is enabled
  bool get isSystemMode => _themeMode == ThemeMode.system;

  /// Constructor initializes theme from SharedPreferences
  ThemeProvider() {
    _loadThemePreference();
  }

  /// Load theme preference from SharedPreferences
  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeValue = prefs.getString(_themePreferenceKey);
      
      if (themeValue != null) {
        _themeMode = _parseThemeMode(themeValue);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading theme preference: $e');
    }
  }

  /// Save theme preference to SharedPreferences
  Future<void> _saveThemePreference(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themePreferenceKey, mode.toString());
    } catch (e) {
      debugPrint('Error saving theme preference: $e');
    }
  }

  /// Set theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    
    _themeMode = mode;
    notifyListeners();
    await _saveThemePreference(mode);
  }

  /// Toggle between light and dark mode
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.light) {
      await setThemeMode(ThemeMode.dark);
    } else {
      await setThemeMode(ThemeMode.light);
    }
  }
  
  /// Set theme to system default
  Future<void> useSystemTheme() async {
    await setThemeMode(ThemeMode.system);
  }
  
  /// Set theme to light mode
  Future<void> useLightTheme() async {
    await setThemeMode(ThemeMode.light);
  }
  
  /// Set theme to dark mode
  Future<void> useDarkTheme() async {
    await setThemeMode(ThemeMode.dark);
  }
  
  /// Parse theme mode from string
  ThemeMode _parseThemeMode(String value) {
    switch (value) {
      case 'ThemeMode.dark':
        return ThemeMode.dark;
      case 'ThemeMode.light':
        return ThemeMode.light;
      case 'ThemeMode.system':
      default:
        return ThemeMode.system;
    }
  }
} 