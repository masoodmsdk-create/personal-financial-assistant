import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_financial_assistant/features/auth/presentation/providers/auth_providers.dart';
import 'package:personal_financial_assistant/features/settings/presentation/screens/settings_screen.dart';

void main() {
  testWidgets('SettingsScreen renders reorganized user-centric sections', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [currentUserProvider.overrideWithValue(null)],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('PROFILE'), findsOneWidget);
    expect(find.text('FINANCIAL SETUP'), findsOneWidget);
    expect(find.text('Account Types'), findsOneWidget);
    expect(find.text('Transaction Categories'), findsOneWidget);
    expect(find.text('Planned Expenses & Forecast'), findsOneWidget);
    expect(find.text('Financial Goals'), findsOneWidget);
    expect(find.text('Loans & What-If Forecasts'), findsOneWidget);
    expect(find.text('Monthly Financial Review'), findsOneWidget);

    expect(find.text('APP INFORMATION'), findsOneWidget);
    expect(find.text('MSD FINAURA'), findsOneWidget);

    expect(find.text('LEGAL & PRIVACY'), findsOneWidget);
    expect(find.text('Terms of Service'), findsOneWidget);
    expect(find.text('Privacy Notice'), findsOneWidget);
    expect(find.text('Financial Disclaimer'), findsOneWidget);

    expect(find.text('Sign Out'), findsOneWidget);
  });
}
