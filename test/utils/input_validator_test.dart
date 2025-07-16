import 'package:flutter_test/flutter_test.dart';
import 'package:dosify_cursor/utils/input_validator.dart';

void main() {
  group('InputValidator', () {
    group('validateEmail', () {
      test('should return success for valid email addresses', () {
        final validEmails = [
          'test@example.com',
          'user123@gmail.com',
          'first.last@company.co.uk',
          'test+tag@domain.org',
          'user_name@test-domain.com',
        ];

        for (final email in validEmails) {
          final result = InputValidator.validateEmail(email);
          expect(result.isValid, true, reason: 'Failed for email: $email');
          expect(result.error, null);
        }
      });

      test('should return failure for invalid email addresses', () {
        final invalidEmails = [
          '',
          'invalid-email',
          '@domain.com',
          'user@',
          'user..name@domain.com',
          'user@domain',
          'user name@domain.com', // space not allowed
        ];

        for (final email in invalidEmails) {
          final result = InputValidator.validateEmail(email);
          expect(result.isValid, false, reason: 'Should fail for email: $email');
          expect(result.error, isNotNull);
        }
      });

      test('should return failure for null email', () {
        final result = InputValidator.validateEmail(null);
        expect(result.isValid, false);
        expect(result.error, equals('Email is required'));
      });

      test('should return failure for email that is too long', () {
        final longEmail = '${'a' * 250}@example.com';
        final result = InputValidator.validateEmail(longEmail);
        expect(result.isValid, false);
        expect(result.error, equals('Email is too long'));
      });
    });

    group('validatePassword', () {
      test('should return success for strong passwords', () {
        final strongPasswords = [
          'StrongPass123!',
          'MyPassword#456',
          'TestP@ssw0rd',
          'Complex1ty&Security',
          'Valid123\$Password',
        ];

        for (final password in strongPasswords) {
          final result = InputValidator.validatePassword(password);
          expect(result.isValid, true, reason: 'Failed for password: $password');
          expect(result.error, null);
        }
      });

      test('should return failure for weak passwords', () {
        final weakPasswords = {
          '12345678': 'no letters or special chars',
          'password': 'no uppercase, numbers, or special chars',
          'PASSWORD': 'no lowercase, numbers, or special chars',
          'Pass123': 'no special characters and too short',
          'Password!': 'no numbers',
          'password123': 'no uppercase or special chars',
          'PASSWORD123!': 'no lowercase',
        };

        weakPasswords.forEach((password, reason) {
          final result = InputValidator.validatePassword(password);
          expect(result.isValid, false, reason: 'Should fail for: $password ($reason)');
          expect(result.error, isNotNull);
        });
      });

      test('should return failure for null or empty password', () {
        final result1 = InputValidator.validatePassword(null);
        expect(result1.isValid, false);
        expect(result1.error, equals('Password is required'));

        final result2 = InputValidator.validatePassword('');
        expect(result2.isValid, false);
        expect(result2.error, equals('Password is required'));
      });

      test('should return failure for password that is too short', () {
        final result = InputValidator.validatePassword('Short1!');
        expect(result.isValid, false);
        expect(result.error, equals('Password must be at least 8 characters'));
      });

      test('should return failure for password that is too long', () {
        final longPassword = 'A' * 120 + '1@';
        final result = InputValidator.validatePassword(longPassword);
        expect(result.isValid, false);
        expect(result.error, equals('Password is too long'));
      });
    });

    group('validatePasswordConfirmation', () {
      test('should return success when passwords match', () {
        const password = 'StrongPass123!';
        const confirmation = 'StrongPass123!';
        
        final result = InputValidator.validatePasswordConfirmation(password, confirmation);
        expect(result.isValid, true);
        expect(result.error, null);
      });

      test('should return failure when passwords do not match', () {
        const password = 'StrongPass123!';
        const confirmation = 'DifferentPass456@';
        
        final result = InputValidator.validatePasswordConfirmation(password, confirmation);
        expect(result.isValid, false);
        expect(result.error, equals('Passwords do not match'));
      });

      test('should return failure when confirmation is null or empty', () {
        const password = 'StrongPass123!';
        
        final result1 = InputValidator.validatePasswordConfirmation(password, null);
        expect(result1.isValid, false);
        expect(result1.error, equals('Please confirm your password'));

        final result2 = InputValidator.validatePasswordConfirmation(password, '');
        expect(result2.isValid, false);
        expect(result2.error, equals('Please confirm your password'));
      });
    });

    group('validateMedicationName', () {
      test('should return success for valid medication names', () {
        final validNames = [
          'Aspirin',
          'Tylenol PM',
          'Advil-Extra',
          'Medication (100mg)',
          'Test Med 123',
          'Multi-Word Medication Name',
        ];

        for (final name in validNames) {
          final result = InputValidator.validateMedicationName(name);
          expect(result.isValid, true, reason: 'Failed for name: $name');
          expect(result.error, null);
        }
      });

      test('should return failure for invalid medication names', () {
        final invalidNames = [
          '',
          'A', // too short
          'Med@cation', // invalid character
          'Med&ication', // invalid character
          'Med<script>', // invalid character
          'A' * 101, // too long
        ];

        for (final name in invalidNames) {
          final result = InputValidator.validateMedicationName(name);
          expect(result.isValid, false, reason: 'Should fail for name: $name');
          expect(result.error, isNotNull);
        }
      });

      test('should return failure for null medication name', () {
        final result = InputValidator.validateMedicationName(null);
        expect(result.isValid, false);
        expect(result.error, equals('Medication name is required'));
      });
    });

    group('validateMedicationStrength', () {
      test('should return success for valid strengths', () {
        final validStrengths = [
          '10',
          '250.5',
          '0.25',
          '1000',
          '5.75',
        ];

        for (final strength in validStrengths) {
          final result = InputValidator.validateMedicationStrength(strength);
          expect(result.isValid, true, reason: 'Failed for strength: $strength');
          expect(result.error, null);
        }
      });

      test('should return failure for invalid strengths', () {
        final invalidStrengths = [
          '',
          'abc',
          '-10',
          '0',
          '10001', // too high
          '10.5.5', // invalid format
        ];

        for (final strength in invalidStrengths) {
          final result = InputValidator.validateMedicationStrength(strength);
          expect(result.isValid, false, reason: 'Should fail for strength: $strength');
          expect(result.error, isNotNull);
        }
      });
    });

    group('validateInventoryCount', () {
      test('should return success for valid inventory counts', () {
        final validCounts = [
          '0',
          '10',
          '250.5',
          '1000',
          '9999',
        ];

        for (final count in validCounts) {
          final result = InputValidator.validateInventoryCount(count);
          expect(result.isValid, true, reason: 'Failed for count: $count');
          expect(result.error, null);
        }
      });

      test('should return failure for invalid inventory counts', () {
        final invalidCounts = [
          '',
          'abc',
          '-10',
          '10000', // too high
          '10.5.5', // invalid format
        ];

        for (final count in invalidCounts) {
          final result = InputValidator.validateInventoryCount(count);
          expect(result.isValid, false, reason: 'Should fail for count: $count');
          expect(result.error, isNotNull);
        }
      });
    });

    group('validatePositiveNumber', () {
      test('should return success for valid positive numbers', () {
        final validNumbers = [
          '0.1',
          '10',
          '250.5',
          '1000',
        ];

        for (final number in validNumbers) {
          final result = InputValidator.validatePositiveNumber(number, 'Test Field');
          expect(result.isValid, true, reason: 'Failed for number: $number');
          expect(result.error, null);
        }
      });

      test('should return failure for invalid positive numbers', () {
        final invalidNumbers = [
          '',
          'abc',
          '-10',
          '0',
          '10.5.5', // invalid format
        ];

        for (final number in invalidNumbers) {
          final result = InputValidator.validatePositiveNumber(number, 'Test Field');
          expect(result.isValid, false, reason: 'Should fail for number: $number');
          expect(result.error, isNotNull);
        }
      });
    });

    group('sanitizeInput', () {
      test('should remove HTML tags and dangerous characters', () {
        final testCases = {
          '<script>alert("xss")</script>': 'alert("xss")',
          'Normal text': 'Normal text',
          'Text with <b>bold</b> tags': 'Text with bold tags',
          'Text with "quotes"': 'Text with quotes',
          "Text with 'apostrophes'": 'Text with apostrophes',
          '  Whitespace text  ': 'Whitespace text',
          '<div>Text</div> with < and >': 'Text with  and',
        };

        testCases.forEach((input, expected) {
          final result = InputValidator.sanitizeInput(input);
          expect(result, equals(expected), reason: 'Failed for input: $input');
        });
      });
    });

    group('validateFutureDate', () {
      test('should return success for future dates', () {
        final futureDate = DateTime.now().add(const Duration(days: 1));
        final result = InputValidator.validateFutureDate(futureDate, 'Test Date');
        expect(result.isValid, true);
        expect(result.error, null);
      });

      test('should return failure for past dates', () {
        final pastDate = DateTime.now().subtract(const Duration(days: 1));
        final result = InputValidator.validateFutureDate(pastDate, 'Test Date');
        expect(result.isValid, false);
        expect(result.error, equals('Test Date cannot be in the past'));
      });

      test('should return failure for null date', () {
        final result = InputValidator.validateFutureDate(null, 'Test Date');
        expect(result.isValid, false);
        expect(result.error, equals('Test Date is required'));
      });
    });

    group('validateDateRange', () {
      test('should return success for valid date range', () {
        final startDate = DateTime.now();
        final endDate = DateTime.now().add(const Duration(days: 7));
        
        final result = InputValidator.validateDateRange(startDate, endDate);
        expect(result.isValid, true);
        expect(result.error, null);
      });

      test('should return failure when end date is before start date', () {
        final startDate = DateTime.now();
        final endDate = DateTime.now().subtract(const Duration(days: 1));
        
        final result = InputValidator.validateDateRange(startDate, endDate);
        expect(result.isValid, false);
        expect(result.error, equals('End date cannot be before start date'));
      });

      test('should return failure when dates are null', () {
        final result1 = InputValidator.validateDateRange(null, DateTime.now());
        expect(result1.isValid, false);
        expect(result1.error, equals('Both start and end dates are required'));

        final result2 = InputValidator.validateDateRange(DateTime.now(), null);
        expect(result2.isValid, false);
        expect(result2.error, equals('Both start and end dates are required'));
      });
    });
  });

  group('ValidationResult', () {
    test('should create success result correctly', () {
      final result = ValidationResult.success();
      expect(result.isValid, true);
      expect(result.error, null);
      expect(result.hasError, false);
    });

    test('should create failure result correctly', () {
      const errorMessage = 'Test error message';
      final result = ValidationResult.failure(errorMessage);
      expect(result.isValid, false);
      expect(result.error, equals(errorMessage));
      expect(result.hasError, true);
    });
  });

  group('ValidationExtensions', () {
    test('should provide convenient extension methods', () {
      const validEmail = 'test@example.com';
      final result = validEmail.validateEmail();
      expect(result.isValid, true);

      const invalidEmail = 'invalid';
      final result2 = invalidEmail.validateEmail();
      expect(result2.isValid, false);
    });
  });
}