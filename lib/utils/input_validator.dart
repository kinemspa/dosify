import 'dart:math';

/// Comprehensive input validation utility for the Dosify app
class InputValidator {
  // Constants for validation limits
  static const int maxMedicationNameLength = 100;
  static const int maxNotesLength = 500;
  static const int maxPasswordLength = 128;
  static const int minPasswordLength = 8;
  static const double maxMedicationStrength = 10000.0;
  static const double maxInventoryCount = 9999.0;
  static const double maxDoseAmount = 1000.0;
  
  // Email regex pattern
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  
  // Password regex pattern (at least 8 chars, 1 uppercase, 1 lowercase, 1 number)
  static final RegExp _passwordRegex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$',
  );
  
  // Name regex pattern (letters, spaces, hyphens, apostrophes only)
  static final RegExp _nameRegex = RegExp(r"^[a-zA-Z\s\-']+$");
  
  // Medication name regex (letters, numbers, spaces, hyphens, parentheses)
  static final RegExp _medicationNameRegex = RegExp(r'^[a-zA-Z0-9\s\-()]+$');

  /// Validate email address
  static ValidationResult validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return ValidationResult.failure('Email is required');
    }
    
    if (email.length > 254) {
      return ValidationResult.failure('Email is too long');
    }
    
    if (!_emailRegex.hasMatch(email)) {
      return ValidationResult.failure('Please enter a valid email address');
    }
    
    return ValidationResult.success();
  }

  /// Validate password with security requirements
  static ValidationResult validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return ValidationResult.failure('Password is required');
    }
    
    if (password.length < minPasswordLength) {
      return ValidationResult.failure('Password must be at least $minPasswordLength characters');
    }
    
    if (password.length > maxPasswordLength) {
      return ValidationResult.failure('Password is too long');
    }
    
    if (!_passwordRegex.hasMatch(password)) {
      return ValidationResult.failure(
        'Password must contain at least:\n'
        '• 1 uppercase letter\n'
        '• 1 lowercase letter\n'
        '• 1 number\n'
        '• 1 special character (@\$!%*?&)'
      );
    }
    
    return ValidationResult.success();
  }

  /// Validate password confirmation
  static ValidationResult validatePasswordConfirmation(String? password, String? confirmation) {
    if (confirmation == null || confirmation.isEmpty) {
      return ValidationResult.failure('Please confirm your password');
    }
    
    if (password != confirmation) {
      return ValidationResult.failure('Passwords do not match');
    }
    
    return ValidationResult.success();
  }

  /// Validate medication name
  static ValidationResult validateMedicationName(String? name) {
    if (name == null || name.isEmpty) {
      return ValidationResult.failure('Medication name is required');
    }
    
    final trimmed = name.trim();
    if (trimmed.length < 2) {
      return ValidationResult.failure('Medication name must be at least 2 characters');
    }
    
    if (trimmed.length > maxMedicationNameLength) {
      return ValidationResult.failure('Medication name is too long');
    }
    
    if (!_medicationNameRegex.hasMatch(trimmed)) {
      return ValidationResult.failure('Medication name contains invalid characters');
    }
    
    return ValidationResult.success();
  }

  /// Validate medication strength
  static ValidationResult validateMedicationStrength(String? strength) {
    if (strength == null || strength.isEmpty) {
      return ValidationResult.failure('Medication strength is required');
    }
    
    final parsed = double.tryParse(strength);
    if (parsed == null) {
      return ValidationResult.failure('Please enter a valid number');
    }
    
    if (parsed <= 0) {
      return ValidationResult.failure('Strength must be greater than 0');
    }
    
    if (parsed > maxMedicationStrength) {
      return ValidationResult.failure('Strength is too high');
    }
    
    return ValidationResult.success();
  }

  /// Validate inventory count
  static ValidationResult validateInventoryCount(String? count) {
    if (count == null || count.isEmpty) {
      return ValidationResult.failure('Inventory count is required');
    }
    
    final parsed = double.tryParse(count);
    if (parsed == null) {
      return ValidationResult.failure('Please enter a valid number');
    }
    
    if (parsed < 0) {
      return ValidationResult.failure('Inventory count cannot be negative');
    }
    
    if (parsed > maxInventoryCount) {
      return ValidationResult.failure('Inventory count is too high');
    }
    
    return ValidationResult.success();
  }

  /// Validate dose amount
  static ValidationResult validateDoseAmount(String? amount) {
    if (amount == null || amount.isEmpty) {
      return ValidationResult.failure('Dose amount is required');
    }
    
    final parsed = double.tryParse(amount);
    if (parsed == null) {
      return ValidationResult.failure('Please enter a valid number');
    }
    
    if (parsed <= 0) {
      return ValidationResult.failure('Dose amount must be greater than 0');
    }
    
    if (parsed > maxDoseAmount) {
      return ValidationResult.failure('Dose amount is too high');
    }
    
    return ValidationResult.success();
  }

  /// Validate notes field
  static ValidationResult validateNotes(String? notes) {
    if (notes == null || notes.isEmpty) {
      return ValidationResult.success(); // Notes are optional
    }
    
    if (notes.length > maxNotesLength) {
      return ValidationResult.failure('Notes are too long');
    }
    
    return ValidationResult.success();
  }

  /// Validate required text field
  static ValidationResult validateRequiredText(String? text, String fieldName) {
    if (text == null || text.trim().isEmpty) {
      return ValidationResult.failure('$fieldName is required');
    }
    
    return ValidationResult.success();
  }

  /// Validate text length
  static ValidationResult validateTextLength(String? text, String fieldName, int maxLength) {
    if (text != null && text.length > maxLength) {
      return ValidationResult.failure('$fieldName is too long (max $maxLength characters)');
    }
    
    return ValidationResult.success();
  }

  /// Validate positive number
  static ValidationResult validatePositiveNumber(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return ValidationResult.failure('$fieldName is required');
    }
    
    final parsed = double.tryParse(value);
    if (parsed == null) {
      return ValidationResult.failure('Please enter a valid number for $fieldName');
    }
    
    if (parsed <= 0) {
      return ValidationResult.failure('$fieldName must be greater than 0');
    }
    
    return ValidationResult.success();
  }

  /// Validate non-negative number
  static ValidationResult validateNonNegativeNumber(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return ValidationResult.failure('$fieldName is required');
    }
    
    final parsed = double.tryParse(value);
    if (parsed == null) {
      return ValidationResult.failure('Please enter a valid number for $fieldName');
    }
    
    if (parsed < 0) {
      return ValidationResult.failure('$fieldName cannot be negative');
    }
    
    return ValidationResult.success();
  }

  /// Validate date is not in the past
  static ValidationResult validateFutureDate(DateTime? date, String fieldName) {
    if (date == null) {
      return ValidationResult.failure('$fieldName is required');
    }
    
    final now = DateTime.now();
    if (date.isBefore(now)) {
      return ValidationResult.failure('$fieldName cannot be in the past');
    }
    
    return ValidationResult.success();
  }

  /// Validate date range
  static ValidationResult validateDateRange(DateTime? startDate, DateTime? endDate) {
    if (startDate == null || endDate == null) {
      return ValidationResult.failure('Both start and end dates are required');
    }
    
    if (endDate.isBefore(startDate)) {
      return ValidationResult.failure('End date cannot be before start date');
    }
    
    return ValidationResult.success();
  }

  /// Sanitize input text (remove potentially dangerous characters)
  static String sanitizeInput(String input) {
    // Remove HTML tags, scripts, and other potentially dangerous content
    return input
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll(RegExp(r'[<>"\x27]'), '') // Remove dangerous characters
        .trim();
  }

  /// Validate and sanitize medication name
  static ValidationResult validateAndSanitizeMedicationName(String? name) {
    if (name == null || name.isEmpty) {
      return ValidationResult.failure('Medication name is required');
    }
    
    final sanitized = sanitizeInput(name);
    return validateMedicationName(sanitized);
  }

  /// Validate and sanitize notes
  static ValidationResult validateAndSanitizeNotes(String? notes) {
    if (notes == null || notes.isEmpty) {
      return ValidationResult.success();
    }
    
    final sanitized = sanitizeInput(notes);
    return validateNotes(sanitized);
  }
}

/// Result of a validation operation
class ValidationResult {
  final bool isValid;
  final String? errorMessage;
  
  const ValidationResult._(this.isValid, this.errorMessage);
  
  factory ValidationResult.success() => const ValidationResult._(true, null);
  factory ValidationResult.failure(String message) => ValidationResult._(false, message);
  
  /// Get error message or null if valid
  String? get error => errorMessage;
  
  /// Check if validation failed
  bool get hasError => !isValid;
}

/// Extension methods for easier validation
extension ValidationExtensions on String? {
  ValidationResult validateEmail() => InputValidator.validateEmail(this);
  ValidationResult validatePassword() => InputValidator.validatePassword(this);
  ValidationResult validateMedicationName() => InputValidator.validateMedicationName(this);
  ValidationResult validateMedicationStrength() => InputValidator.validateMedicationStrength(this);
  ValidationResult validateInventoryCount() => InputValidator.validateInventoryCount(this);
  ValidationResult validateDoseAmount() => InputValidator.validateDoseAmount(this);
  ValidationResult validateNotes() => InputValidator.validateNotes(this);
  ValidationResult validateRequired(String fieldName) => InputValidator.validateRequiredText(this, fieldName);
  ValidationResult validatePositiveNumber(String fieldName) => InputValidator.validatePositiveNumber(this, fieldName);
  ValidationResult validateNonNegativeNumber(String fieldName) => InputValidator.validateNonNegativeNumber(this, fieldName);
}