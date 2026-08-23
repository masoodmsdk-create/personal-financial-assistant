import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_financial_assistant/features/accounts/account.dart';
import 'package:personal_financial_assistant/features/accounts/presentation/providers/account_providers.dart';
import 'package:personal_financial_assistant/features/accounts/presentation/screens/accounts_screen.dart';

void main() {
  final now = DateTime.parse('2026-08-23T06:00:00.000Z');
  final testAccounts = [
    Account(
      id: 'acc_1',
      userId: 'user_1',
      createdAt: now,
      updatedAt: now,
      name: 'Main Bank Account',
      type: AccountType.bank,
      openingBalance: 50000.00,
      currency: 'INR',
      active: true,
    ),
    Account(
      id: 'acc_2',
      userId: 'user_1',
      createdAt: now,
      updatedAt: now,
      name: 'Wallet Cash',
      type: AccountType.cash,
      openingBalance: 2500.00,
      currency: 'INR',
      active: true,
    ),
  ];

  testWidgets(
    'AccountsScreen renders empty state when accounts list is empty',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            accountsStreamProvider.overrideWith((ref) => Stream.value([])),
            totalBalanceProvider.overrideWithValue(0.0),
          ],
          child: const MaterialApp(home: AccountsScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No Accounts Yet'), findsOneWidget);
      expect(
        find.text('Add Account'),
        findsNWidgets(2),
      ); // FAB + Empty state button
    },
  );

  testWidgets('AccountsScreen renders list of accounts correctly', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountsStreamProvider.overrideWith(
            (ref) => Stream.value(testAccounts),
          ),
          totalBalanceProvider.overrideWithValue(52500.00),
        ],
        child: const MaterialApp(home: AccountsScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Total Net Balance'), findsOneWidget);
    expect(find.text('Main Bank Account'), findsOneWidget);
    expect(find.text('Wallet Cash'), findsOneWidget);
    expect(find.text('Bank Account'), findsWidgets);
    expect(find.text('Cash'), findsWidgets);
  });
}
