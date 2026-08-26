import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_financial_assistant/features/goals/goal.dart';
import 'package:personal_financial_assistant/features/goals/presentation/providers/goal_providers.dart';
import 'package:personal_financial_assistant/features/loans/loan.dart';
import 'package:personal_financial_assistant/features/loans/presentation/providers/loan_providers.dart';
import 'package:personal_financial_assistant/features/trade_off/presentation/screens/trade_off_screen.dart';
import 'package:personal_financial_assistant/features/workspaces/presentation/providers/workspace_providers.dart';
import 'package:personal_financial_assistant/features/workspaces/workspace.dart';

void main() {
  final now = DateTime.now();

  final testLoan = Loan(
    id: 'loan_1',
    userId: 'u1',
    name: 'Home Loan',
    type: LoanType.homeLoan,
    originalPrincipal: 5000000.0,
    outstandingPrincipal: 4000000.0,
    interestRate: 8.5,
    remainingTenureMonths: 147,
    emiAmount: 52000.0,
    startDate: DateTime(2022, 1, 1),
    nextEmiDate: DateTime(now.year, now.month, 15),
    createdAt: now,
    updatedAt: now,
  );

  final testGoal = Goal(
    id: 'goal_1',
    userId: 'u1',
    name: 'Emergency Fund',
    type: GoalType.emergencyFund,
    targetAmount: 500000.0,
    currentAmount: 150000.0,
    targetDate: DateTime(now.year + 1, 12, 1),
    createdAt: now,
    updatedAt: now,
  );

  final mockWorkspace = Workspace.createDefault('u1').copyWith(
    name: 'Family Finances',
    purpose: 'Pay off home loan faster and build emergency fund.',
    priorities: ['Reduce debt', 'Build emergency savings'],
  );

  testWidgets(
    'TradeOffScreen renders header, amount inputs, strategy chips, and recommendation banner',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            loansStreamProvider.overrideWith((ref) => Stream.value([testLoan])),
            goalsStreamProvider.overrideWith((ref) => Stream.value([testGoal])),
            workspacesStreamProvider.overrideWith(
              (ref) => Stream.value([mockWorkspace]),
            ),
            activeWorkspaceProvider.overrideWithValue(mockWorkspace),
          ],
          child: const MaterialApp(home: TradeOffScreen()),
        ),
      );

      await tester.pump(Duration.zero);
      await tester.pumpAndSettle();

      // 1. Page Header
      expect(find.text('Loan vs Goal Trade-Offs'), findsOneWidget);

      // 2. Card Header & Inputs
      expect(find.text('Loan Prepayment vs Goal Savings'), findsOneWidget);
      expect(find.text('Extra Cash Amount'), findsOneWidget);
      expect(find.text('Monthly'), findsOneWidget);
      expect(find.text('Lump Sum'), findsOneWidget);

      // 3. Strategy Chips
      expect(find.text('Loan-First'), findsOneWidget);
      expect(find.text('Goal-First'), findsOneWidget);
      expect(find.text('Balanced (50/50)'), findsOneWidget);
      expect(find.text('Custom Split'), findsOneWidget);

      // 4. Recommendation Banner
      expect(find.textContaining('Recommendation:'), findsOneWidget);
    },
  );

  testWidgets('TradeOffScreen switching to Custom Split reveals slider', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          loansStreamProvider.overrideWith((ref) => Stream.value([testLoan])),
          goalsStreamProvider.overrideWith((ref) => Stream.value([testGoal])),
          workspacesStreamProvider.overrideWith(
            (ref) => Stream.value([mockWorkspace]),
          ),
          activeWorkspaceProvider.overrideWithValue(mockWorkspace),
        ],
        child: const MaterialApp(home: TradeOffScreen()),
      ),
    );

    await tester.pump(Duration.zero);
    await tester.pumpAndSettle();

    // Tap on Custom Split chip
    await tester.tap(find.text('Custom Split'));
    await tester.pumpAndSettle();

    expect(find.byType(Slider), findsOneWidget);
    expect(find.textContaining('Custom Split: 50% Loan'), findsOneWidget);
  });
}
