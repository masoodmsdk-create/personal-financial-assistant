import 'package:flutter_test/flutter_test.dart';
import 'package:personal_financial_assistant/features/auth/presentation/utils/auth_validators.dart';

void main() {
  group('AuthValidators - Email Validation', () {
    test('returns error when email is null or empty', () {
      expect(AuthValidators.validateEmail(null), 'Email is required');
      expect(AuthValidators.validateEmail(''), 'Email is required');
      expect(AuthValidators.validateEmail('   '), 'Email is required');
    });

    test('returns error for invalid email formats', () {
      expect(
        AuthValidators.validateEmail('invalid-email'),
        'Enter a valid email address',
      );
      expect(
        AuthValidators.validateEmail('user@'),
        'Enter a valid email address',
      );
      expect(
        AuthValidators.validateEmail('user@domain'),
        'Enter a valid email address',
      );
      expect(
        AuthValidators.validateEmail('@domain.com'),
        'Enter a valid email address',
      );
    });

    test('returns null for valid email formats', () {
      expect(AuthValidators.validateEmail('user@example.com'), null);
      expect(AuthValidators.validateEmail('test.user+1@domain.co.in'), null);
    });
  });

  group('AuthValidators - Password Validation', () {
    test('returns error when password is null or empty', () {
      expect(AuthValidators.validatePassword(null), 'Password is required');
      expect(AuthValidators.validatePassword(''), 'Password is required');
    });

    test('returns error when password is less than 6 characters', () {
      expect(
        AuthValidators.validatePassword('12345'),
        'Password must be at least 6 characters long',
      );
    });

    test('returns null for valid password (>= 6 chars)', () {
      expect(AuthValidators.validatePassword('123456'), null);
      expect(AuthValidators.validatePassword('SecurePass123!'), null);
    });
  });

  group('AuthValidators - Confirm Password Validation', () {
    test('returns error when confirm password is null or empty', () {
      expect(
        AuthValidators.validateConfirmPassword('password123', null),
        'Confirm password is required',
      );
      expect(
        AuthValidators.validateConfirmPassword('password123', ''),
        'Confirm password is required',
      );
    });

    test('returns error when passwords do not match', () {
      expect(
        AuthValidators.validateConfirmPassword('password123', 'password456'),
        'Passwords do not match',
      );
    });

    test('returns null when passwords match', () {
      expect(
        AuthValidators.validateConfirmPassword('password123', 'password123'),
        null,
      );
    });
  });
}
