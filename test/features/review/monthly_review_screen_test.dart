import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_financial_assistant/features/auth/presentation/providers/auth_providers.dart';
import 'package:personal_financial_assistant/features/categories/category.dart';
import 'package:personal_financial_assistant/features/categories/presentation/providers/category_providers.dart';
import 'package:personal_financial_assistant/features/goals/goal.dart';
import 'package:personal_financial_assistant/features/goals/presentation/providers/goal_providers.dart';
import 'package:personal_financial_assistant/features/loans/loan.dart';
import 'package:personal_financial_assistant/features/loans/presentation/providers/loan_providers.dart';
import 'package:personal_financial_assistant/features/planned_expenses/planned_expense.dart';
import 'package:personal_financial_assistant/features/planned_expenses/presentation/providers/planned_expense_providers.dart';
import 'package:personal_financial_assistant/features/review/presentation/screens/monthly_review_screen.dart';
import 'package:personal_financial_assistant/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:personal_financial_assistant/features/transactions/transaction.dart';

void main() {
  final now = DateTime(2026, 8, 1);

  final testCategories = [
    Category(
      id: 'cat_food',
      userId: 'user_1',
      name: 'Food & Groceries',
      type: CategoryType.expense,
      createdAt: now,
      updatedAt: now,
    ),
  ];

  final testTransactions = [
    Transaction(
      id: 'tx_1',
      userId: 'user_1',
      type: TransactionType.income,
      amount: 150000.0,
      accountId: 'acc_bank',
      categoryId: 'cat_food',
      date: DateTime(2026, 8, 5),
      createdAt: now,
      updatedAt: now,
    ),
  ];

  final testPlans = [
    PlannedExpense(
      id: 'plan_rent',
      userId: 'user_1',
      name: 'Rent',
      categoryId: 'cat_food',
      defaultAmount: 25000.0,
      frequency: RecurrenceFrequency.monthly,
      startDate: DateTime(2026, 1, 1),
      createdAt: now,
      updatedAt: now,
    ),
  ];

  final testLoans = [
    Loan(
      id: 'loan_1',
      userId: 'user_1',
      name: 'Home Loan',
      type: LoanType.homeLoan,
      outstandingPrincipal: 3000000.0,
      interestRate: 8.5,
      emiAmount: 35000.0,
      createdAt: now,
      updatedAt: now,
    ),
  ];

  final testGoals = [
    Goal(
      id: 'goal_1',
      userId: 'user_1',
      name: 'Emergency Fund',
      type: GoalType.emergencyFund,
      targetAmount: 100000.0,
      currentAmount: 40000.0,
      createdAt: now,
      updatedAt: now,
    ),
  ];

  Widget createWidgetToTest({bool empty = false}) {
    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWith((ref) => null),
        transactionsStreamProvider.overrideWith(
          (ref) => Stream.value(empty ? [] : testTransactions),
        ),
        plannedExpensesStreamProvider.overrideWith(
          (ref) => Stream.value(empty ? [] : testPlans),
        ),
        monthlyOverridesStreamProvider.overrideWith((ref) => Stream.value([])),
        categoriesStreamProvider.overrideWith(
          (ref) => Stream.value(empty ? [] : testCategories),
        ),
        loansStreamProvider.overrideWith(
          (ref) => Stream.value(empty ? [] : testLoans),
        ),
        goalsStreamProvider.overrideWith(
          (ref) => Stream.value(empty ? [] : testGoals),
        ),
      ],
      child: const MaterialApp(home: MonthlyReviewScreen()),
    );
  }

  group('MonthlyReviewScreen Widget Tests', () {
    testWidgets(
      'MonthlyReviewScreen renders month navigation and summary sections',
      (tester) async {
        await tester.pumpWidget(createWidgetToTest());
        await tester.pumpAndSettle();

        expect(find.text('Monthly Financial Review'), findsOneWidget);
        expect(find.text('Monthly Financial Summary'), findsOneWidget);
        expect(find.text('1. What Happened?'), findsOneWidget);
        expect(find.text('2. Things to Review'), findsOneWidget);
        expect(find.text('3. What\'s Coming Next?'), findsOneWidget);
        expect(
          find.text('4. How are my goals & loans progressing?'),
          findsOneWidget,
        );
      },
    );

    testWidgets('MonthlyReviewScreen handles empty state smoothly', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetToTest(empty: true));
      await tester.pumpAndSettle();

      expect(find.text('No Transactions Recorded Yet'), findsOneWidget);
    });
  });
}
