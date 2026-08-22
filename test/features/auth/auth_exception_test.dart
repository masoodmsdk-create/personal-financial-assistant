import 'package:flutter_test/flutter_test.dart';
import 'package:personal_financial_assistant/core/errors/app_exception.dart';

void main() {
  group('AuthException Tests', () {
    test('creates AuthException with message and optional code', () {
      const exception = AuthException(
        'Invalid credentials',
        code: 'INVALID_CREDENTIALS',
      );
      expect(exception.message, 'Invalid credentials');
      expect(exception.code, 'INVALID_CREDENTIALS');
      expect(exception.toString(), contains('Invalid credentials'));
      expect(exception.toString(), contains('INVALID_CREDENTIALS'));
    });

    test('creates AuthException without code', () {
      const exception = AuthException('Authentication failed');
      expect(exception.message, 'Authentication failed');
      expect(exception.code, isNull);
      expect(
        exception.toString(),
        equals('AppException: Authentication failed'),
      );
    });
  });
}
