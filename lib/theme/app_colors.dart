import 'package:flutter/material.dart';

class AppColors {
  // Dark Theme Colors - Updated for better readability
  static const Color darkPrimary = Color(0xFF212121);  // Standard dark gray
  static const Color darkPrimaryDark = Color(0xFF121212); // Darker gray
  static const Color darkPrimaryLight = Color(0xFF303030); // Lighter variant
  
  static const Color darkSecondary = Color(0xFF2196F3);  // Blue accent
  static const Color darkSecondaryDark = Color(0xFF1976D2);
  static const Color darkSecondaryLight = Color(0xFF64B5F6);

  static const Color darkBackground = Color(0xFF121212); // Standard dark background
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkCardBackground = Color(0xFF2C2C2C);

  static const Color darkTextPrimary = Colors.white;
  static const Color darkTextSecondary = Color(0xFFB0BEC5);
  static const Color darkTextHint = Color(0xFF78909C);
  static const Color darkCursor = Color(0xFF64B5F6); // Light blue cursor color

  static const Color darkBorder = Color(0xFF424242);
  static const Color darkDivider = Color(0xFF323232);
  
  static const Color darkActionButton = Color(0xFF2196F3);
  static const Color darkActionButtonPressed = Color(0xFF1976D2);

  // Light Theme Colors - Updated to use darker teal-blue colors with less green
  static const Color lightPrimary = Color(0xFF00556C);  // Dark Teal-Blue primary
  static const Color lightPrimaryDark = Color(0xFF003A4F); // Darker teal-blue
  static const Color lightPrimaryLight = Color(0xFF006F8F); // Lighter teal-blue variant
  
  static const Color lightSecondary = Color(0xFF00556C);  // Dark Teal-Blue accent
  static const Color lightSecondaryDark = Color(0xFF003A4F);
  static const Color lightSecondaryLight = Color(0xFF006F8F);

  static const Color lightBackground = Color(0xFFF5F5F5); // Light gray background
  static const Color lightSurface = Color(0xFFFFFFFF); // White surface
  static const Color lightCardBackground = Color(0xFFFFFFFF); // White cards

  static const Color lightTextPrimary = Color(0xFF003A4F); // Dark teal-blue text for headings
  static const Color lightTextSecondary = Color(0xFF00556C); // Medium teal-blue text
  static const Color lightTextHint = Color(0xFF0288A7); // Light teal-blue text
  static const Color lightCursor = Color(0xFF00556C); // Teal-blue cursor color

  static const Color lightBorder = Color(0xFFE0E0E0);
  static const Color lightDivider = Color(0xFFEEEEEE);
  
  static const Color lightActionButton = Color(0xFF00556C);
  static const Color lightActionButtonPressed = Color(0xFF003A4F);

  // Status Colors (same for both themes)
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFA726);
  static const Color info = Color(0xFF29B6F6);

  // Current theme colors (will be set dynamically)
  // Default to dark theme
  static Color primary = darkPrimary;
  static Color primaryDark = darkPrimaryDark;
  static Color primaryLight = darkPrimaryLight;
  
  static Color secondary = darkSecondary;
  static Color secondaryDark = darkSecondaryDark;
  static Color secondaryLight = darkSecondaryLight;

  static Color background = darkBackground;
  static Color surface = darkSurface;
  static Color cardBackground = darkCardBackground;

  static Color textPrimary = darkTextPrimary;
  static Color textSecondary = darkTextSecondary;
  static Color textHint = darkTextHint;

  static Color border = darkBorder;
  static Color divider = darkDivider;
  
  static Color actionButton = darkActionButton;
  static Color actionButtonPressed = darkActionButtonPressed;

  // Method to update colors based on theme mode
  static void setThemeMode(bool isDark) {
    primary = isDark ? darkPrimary : lightPrimary;
    primaryDark = isDark ? darkPrimaryDark : lightPrimaryDark;
    primaryLight = isDark ? darkPrimaryLight : lightPrimaryLight;
    
    secondary = isDark ? darkSecondary : lightSecondary;
    secondaryDark = isDark ? darkSecondaryDark : lightSecondaryDark;
    secondaryLight = isDark ? darkSecondaryLight : lightSecondaryLight;

    background = isDark ? darkBackground : lightBackground;
    surface = isDark ? darkSurface : lightSurface;
    cardBackground = isDark ? darkCardBackground : lightCardBackground;

    textPrimary = isDark ? darkTextPrimary : lightTextPrimary;
    textSecondary = isDark ? darkTextSecondary : lightTextSecondary;
    textHint = isDark ? darkTextHint : lightTextHint;

    border = isDark ? darkBorder : lightBorder;
    divider = isDark ? darkDivider : lightDivider;
    
    actionButton = isDark ? darkActionButton : lightActionButton;
    actionButtonPressed = isDark ? darkActionButtonPressed : lightActionButtonPressed;
  }
} 