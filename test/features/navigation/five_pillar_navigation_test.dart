import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_financial_assistant/features/accounts/account.dart';
import 'package:personal_financial_assistant/features/accounts/domain/models/account_type_definition.dart';
import 'package:personal_financial_assistant/features/accounts/presentation/providers/account_providers.dart';
import 'package:personal_financial_assistant/features/auth/presentation/providers/auth_providers.dart';
import 'package:personal_financial_assistant/features/budgets/presentation/providers/budget_providers.dart';
import 'package:personal_financial_assistant/features/categories/presentation/providers/category_providers.dart';
import 'package:personal_financial_assistant/features/goals/presentation/providers/goal_providers.dart';
import 'package:personal_financial_assistant/features/insights/presentation/screens/insights_hub_screen.dart';
import 'package:personal_financial_assistant/features/loans/presentation/providers/loan_providers.dart';
import 'package:personal_financial_assistant/features/money/presentation/screens/money_hub_screen.dart';
import 'package:personal_financial_assistant/features/planned_expenses/presentation/providers/planned_expense_providers.dart';
import 'package:personal_financial_assistant/features/plans/presentation/screens/plans_hub_screen.dart';
import 'package:personal_financial_assistant/features/recurring_transactions/presentation/providers/recurring_transaction_providers.dart';
import 'package:personal_financial_assistant/features/transactions/presentation/providers/transaction_providers.dart';

void main() {
  final now = DateTime(2026, 1, 1);

  final testAccount = Account(
    id: 'acc_salary',
    userId: 'user_1',
    name: 'Main Bank',
    type: AccountType.bank,
    openingBalance: 50000.0,
    currency: 'INR',
    active: true,
    createdAt: now,
    updatedAt: now,
  );

  Widget createTestWidget({required Widget child}) {
    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(null),
        accountsStreamProvider.overrideWith(
          (ref) => Stream.value([testAccount]),
        ),
        accountTypesStreamProvider.overrideWith(
          (ref) => Stream.value(AccountTypeDefinition.defaultTypes),
        ),
        categoriesStreamProvider.overrideWith((ref) => Stream.value([])),
        recurringTransactionsStreamProvider.overrideWith(
          (ref) => Stream.value([]),
        ),
        loansStreamProvider.overrideWith((ref) => Stream.value([])),
        goalsStreamProvider.overrideWith((ref) => Stream.value([])),
        plannedExpensesStreamProvider.overrideWith((ref) => Stream.value([])),
        monthlyOverridesStreamProvider.overrideWith((ref) => Stream.value([])),
        budgetsStreamProvider.overrideWith((ref) => Stream.value([])),
        transactionsStreamProvider.overrideWith((ref) => Stream.value([])),
      ],
      child: MaterialApp(home: child),
    );
  }

  group('Five-Pillar Hub Architecture Tests', () {
    testWidgets(
      'MoneyHubScreen renders tabs for Accounts, Transactions, and Recurring Rules',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          createTestWidget(child: const MoneyHubScreen()),
        );
        await tester.pumpAndSettle();

        expect(find.text('Accounts'), findsWidgets);
        expect(find.text('Transactions'), findsWidgets);
        expect(find.text('Recurring Rules'), findsWidgets);
        expect(find.text('Main Bank'), findsOneWidget);
      },
    );

    testWidgets(
      'PlansHubScreen renders tabs for Budgets, Goals, Loans & Debt, and Trade-Offs',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          createTestWidget(child: const PlansHubScreen()),
        );
        await tester.pumpAndSettle();

        expect(find.text('Budgets'), findsWidgets);
        expect(find.text('Goals'), findsWidgets);
        expect(find.text('Loans & Debt'), findsWidgets);
        expect(find.text('Trade-Offs'), findsWidgets);
      },
    );

    testWidgets(
      'InsightsHubScreen renders tabs for Analytics, Monthly Review, and Forecast',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          createTestWidget(child: const InsightsHubScreen()),
        );
        await tester.pumpAndSettle();

        expect(find.text('Analytics'), findsWidgets);
        expect(find.text('Monthly Review'), findsWidgets);
        expect(find.text('Forecast'), findsWidgets);
      },
    );
  });
}
