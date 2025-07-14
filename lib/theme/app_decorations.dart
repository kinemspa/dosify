import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppDecorations {
  // Card Decorations
  static BoxDecoration card = BoxDecoration(
    color: AppColors.cardBackground,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.2),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );
  
  // Gradient Background
  static BoxDecoration gradientBackground = const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        AppColors.primary,
        AppColors.primaryDark,
      ],
    ),
  );

  // Input Decorations
  static InputDecoration inputField({
    String? labelText,
    String? hintText,
    String? suffixText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      suffixText: suffixText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.secondary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      labelStyle: TextStyle(color: AppColors.textSecondary),
      hintStyle: TextStyle(color: AppColors.textHint),
    );
  }

  // Button Decorations
  static ButtonStyle primaryButton = ElevatedButton.styleFrom(
    backgroundColor: AppColors.actionButton,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    elevation: 2,
  );

  static ButtonStyle secondaryButton = ElevatedButton.styleFrom(
    backgroundColor: AppColors.secondary,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    elevation: 2,
  );

  static ButtonStyle outlinedButton = OutlinedButton.styleFrom(
    foregroundColor: AppColors.secondary,
    side: const BorderSide(color: AppColors.secondary),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
  );
  
  // Section Header
  static TextStyle sectionHeader = const TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.bold,
    fontSize: 16,
  );
  
  // Card Content
  static BoxDecoration contentCard = BoxDecoration(
    color: AppColors.cardBackground.withOpacity(0.8),
    borderRadius: BorderRadius.circular(8),
  );
}

// Spacing Constants
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // Padding
  static const EdgeInsets paddingXS = EdgeInsets.all(xs);
  static const EdgeInsets paddingSM = EdgeInsets.all(sm);
  static const EdgeInsets paddingMD = EdgeInsets.all(md);
  static const EdgeInsets paddingLG = EdgeInsets.all(lg);
  static const EdgeInsets paddingXL = EdgeInsets.all(xl);

  // Margin
  static const EdgeInsets marginXS = EdgeInsets.all(xs);
  static const EdgeInsets marginSM = EdgeInsets.all(sm);
  static const EdgeInsets marginMD = EdgeInsets.all(md);
  static const EdgeInsets marginLG = EdgeInsets.all(lg);
  static const EdgeInsets marginXL = EdgeInsets.all(xl);
} 