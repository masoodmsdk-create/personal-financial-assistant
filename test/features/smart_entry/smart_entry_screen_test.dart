import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_financial_assistant/features/accounts/account.dart';
import 'package:personal_financial_assistant/features/accounts/presentation/providers/account_providers.dart';
import 'package:personal_financial_assistant/features/categories/category.dart';
import 'package:personal_financial_assistant/features/categories/presentation/providers/category_providers.dart';
import 'package:personal_financial_assistant/features/smart_entry/presentation/screens/smart_entry_screen.dart';

void main() {
  testWidgets(
    'SmartEntryScreen renders input, prompt chips, and parse button',
    (tester) async {
      final mockAccounts = [
        Account(
          id: 'acc_1',
          userId: 'user_1',
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
          name: 'HDFC Bank',
          type: AccountType.bank,
          openingBalance: 5000.0,
          currency: 'INR',
          active: true,
        ),
      ];

      final mockCategories = [
        Category(
          id: 'cat_1',
          userId: 'user_1',
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
          name: 'Food & Dining',
          type: CategoryType.expense,
          active: true,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            accountsStreamProvider.overrideWith(
              (ref) => Stream.value(mockAccounts),
            ),
            categoriesStreamProvider.overrideWith(
              (ref) => Stream.value(mockCategories),
            ),
          ],
          child: const MaterialApp(home: SmartEntryScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Smart Financial Assistant'), findsOneWidget);
      expect(find.text('Analyze & Parse'), findsOneWidget);
      expect(find.text('Quick Examples (tap to test)'), findsOneWidget);

      // Tap a sample prompt chip
      final promptChip = find.text('Bought groceries 1400 cash');
      expect(promptChip, findsOneWidget);
      await tester.tap(promptChip);
      await tester.pumpAndSettle();

      // Verify parsed transaction draft appears
      expect(find.text('Detected Transactions (1)'), findsOneWidget);
      expect(find.text('EXPENSE'), findsOneWidget);
      expect(find.text('Record All (1)'), findsOneWidget);
    },
  );
}
