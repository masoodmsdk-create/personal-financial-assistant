import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_financial_assistant/features/legal/presentation/screens/financial_disclaimer_screen.dart';
import 'package:personal_financial_assistant/features/legal/presentation/screens/privacy_notice_screen.dart';
import 'package:personal_financial_assistant/features/legal/presentation/screens/terms_of_service_screen.dart';

void main() {
  group('Legal Screens Rendering Tests', () {
    testWidgets('TermsOfServiceScreen renders 15 terms sections and header', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: TermsOfServiceScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Terms of Service'), findsWidgets);
      expect(
        find.textContaining('1. Nature of the Application'),
        findsOneWidget,
      );
      expect(
        find.textContaining('2. No Custody or Control of Money'),
        findsOneWidget,
      );
      expect(
        find.textContaining('6. Security & Credential Safety Warning'),
        findsOneWidget,
      );
    });

    testWidgets(
      'PrivacyNoticeScreen renders privacy sections and safety warning',
      (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: PrivacyNoticeScreen()));
        await tester.pumpAndSettle();

        expect(find.text('Privacy Notice'), findsWidgets);
        expect(
          find.textContaining('1. Information We Collect'),
          findsOneWidget,
        );
        expect(
          find.textContaining(
            '4. VERY IMPORTANT — Sensitive Banking Credential Warning',
          ),
          findsOneWidget,
        );
        expect(find.textContaining('OTPs'), findsWidgets);
      },
    );

    testWidgets('FinancialDisclaimerScreen renders disclaimer sections', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: FinancialDisclaimerScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Financial Disclaimer'), findsWidgets);
      expect(
        find.textContaining('Software Calculations & Informational Purpose'),
        findsOneWidget,
      );
      expect(find.textContaining('Not Professional Advice'), findsOneWidget);
    });
  });
}
