import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_financial_assistant/features/auth/presentation/providers/auth_providers.dart';
import 'package:personal_financial_assistant/features/loans/loan.dart';
import 'package:personal_financial_assistant/features/loans/presentation/providers/loan_providers.dart';
import 'package:personal_financial_assistant/features/loans/presentation/screens/loans_screen.dart';

void main() {
  final now = DateTime(2026, 8, 1);
  final testLoans = [
    Loan(
      id: 'loan_1',
      userId: 'user_1',
      name: 'HDFC Home Loan',
      type: LoanType.homeLoan,
      outstandingPrincipal: 3500000.0,
      interestRate: 8.5,
      emiAmount: 38000.0,
      createdAt: now,
      updatedAt: now,
    ),
    Loan(
      id: 'loan_2',
      userId: 'user_1',
      name: 'ICICI Personal Loan',
      type: LoanType.personalLoan,
      outstandingPrincipal: 150000.0,
      interestRate: 14.0,
      emiAmount: 7500.0,
      createdAt: now,
      updatedAt: now,
    ),
  ];

  Widget createWidgetToTest({List<Loan>? loans}) {
    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWith((ref) => null),
        loansStreamProvider.overrideWith(
          (ref) => Stream.value(loans ?? testLoans),
        ),
      ],
      child: const MaterialApp(home: LoansScreen()),
    );
  }

  group('LoansScreen Widget Tests', () {
    testWidgets('Renders EmptyStateWidget when no loans exist', (tester) async {
      await tester.pumpWidget(createWidgetToTest(loans: []));
      await tester.pumpAndSettle();

      expect(find.text('No Loans Added Yet'), findsOneWidget);
      expect(find.text('Add Your First Loan'), findsOneWidget);
    });

    testWidgets(
      'Renders Portfolio Summary, Strategy Prioritization, and Loan Cards',
      (tester) async {
        await tester.pumpWidget(createWidgetToTest());
        await tester.pumpAndSettle();

        expect(find.text('Loans & Debt Intelligence'), findsOneWidget);
        expect(find.text('Portfolio Debt Burden'), findsOneWidget);
        expect(find.text('Total Outstanding Debt'), findsOneWidget);
        expect(find.text('HDFC Home Loan'), findsWidgets);
        expect(find.text('ICICI Personal Loan'), findsWidgets);

        // Verify Debt Prioritization Strategy
        expect(find.text('Debt Prioritization Strategy'), findsOneWidget);
        expect(find.text('Avalanche'), findsOneWidget);
        expect(find.text('Snowball'), findsOneWidget);
      },
    );
  });
}
