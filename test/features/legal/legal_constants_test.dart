import 'package:flutter_test/flutter_test.dart';
import 'package:personal_financial_assistant/core/constants/app_constants.dart';

void main() {
  group('Legal & Policy Constants Tests', () {
    test('policy version constants are non-empty and formatted', () {
      expect(AppConstants.termsVersion, '1.0');
      expect(AppConstants.privacyVersion, '1.0');
    });

    test(
      'legal messages contain neutral contact and governing law descriptions',
      () {
        expect(
          AppConstants.supportContactMessage,
          contains('official contact mechanism'),
        );
        expect(
          AppConstants.governingLawMessage,
          contains('applicable laws of India'),
        );
      },
    );
  });
}
