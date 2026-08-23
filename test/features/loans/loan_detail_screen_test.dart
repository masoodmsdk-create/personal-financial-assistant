import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_financial_assistant/features/accounts/presentation/providers/account_providers.dart';
import 'package:personal_financial_assistant/features/auth/presentation/providers/auth_providers.dart';
import 'package:personal_financial_assistant/features/goals/presentation/providers/goal_providers.dart';
import 'package:personal_financial_assistant/features/loans/loan.dart';
import 'package:personal_financial_assistant/features/loans/presentation/providers/loan_providers.dart';
import 'package:personal_financial_assistant/features/loans/presentation/screens/loan_detail_screen.dart';

void main() {
  final now = DateTime(2026, 8, 1);
  final testLoan = Loan(
    id: 'loan_hdfc',
    userId: 'user_1',
    name: 'HDFC Home Loan',
    type: LoanType.homeLoan,
    outstandingPrincipal: 4500000.0,
    interestRate: 8.5,
    emiAmount: 42000.0,
    remainingTenureMonths: 240,
    lenderName: 'HDFC Bank',
    createdAt: now,
    updatedAt: now,
  );

  testWidgets(
    'LoanDetailScreen renders tabs, cost breakdown, and what-if simulator',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => null),
            accountsStreamProvider.overrideWith(
              (ref) => Stream.value(const []),
            ),
            goalsStreamProvider.overrideWith((ref) => Stream.value(const [])),
            loansStreamProvider.overrideWith((ref) => Stream.value([testLoan])),
            selectedLoanIdProvider.overrideWith((ref) => 'loan_hdfc'),
          ],
          child: const MaterialApp(home: LoanDetailScreen(loanId: 'loan_hdfc')),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('HDFC Home Loan'), findsWidgets);
      expect(find.text('Cost & Breakdown'), findsOneWidget);
      expect(find.text('What-If Simulator'), findsOneWidget);
      expect(find.text('Amortization'), findsOneWidget);
      expect(find.text('Cash Flow & Goals'), findsOneWidget);

      // Verify Cost & Breakdown elements
      expect(
        find.text('Total Remaining Repayment Composition'),
        findsOneWidget,
      );
      expect(find.text('Next 12 Months Payment Trajectory'), findsOneWidget);

      // Tap What-If Simulator tab
      await tester.tap(find.text('What-If Simulator'));
      await tester.pumpAndSettle();
      expect(find.text('What-If Scenario Simulator'), findsOneWidget);
      expect(find.text('Refinancing / Rate Reduction'), findsOneWidget);

      // Tap Amortization tab
      await tester.tap(find.text('Amortization'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Complete Amortization Schedule'),
        findsOneWidget,
      );
    },
  );
}
