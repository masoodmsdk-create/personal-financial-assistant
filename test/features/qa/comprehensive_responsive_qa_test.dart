import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_financial_assistant/features/accounts/account.dart';
import 'package:personal_financial_assistant/features/accounts/domain/repositories/account_repository.dart';
import 'package:personal_financial_assistant/features/accounts/presentation/providers/account_providers.dart';
import 'package:personal_financial_assistant/features/accounts/presentation/screens/account_types_screen.dart';
import 'package:personal_financial_assistant/features/accounts/presentation/screens/accounts_screen.dart';
import 'package:personal_financial_assistant/features/analytics/presentation/screens/analytics_screen.dart';
import 'package:personal_financial_assistant/features/auth/domain/repositories/auth_repository.dart';
import 'package:personal_financial_assistant/features/auth/presentation/providers/auth_providers.dart';
import 'package:personal_financial_assistant/features/auth/presentation/screens/login_screen.dart';
import 'package:personal_financial_assistant/features/auth/presentation/screens/register_screen.dart';
import 'package:personal_financial_assistant/features/blueprint/domain/services/blueprint_persistence_service.dart';
import 'package:personal_financial_assistant/features/blueprint/domain/services/financial_situation_parser.dart';
import 'package:personal_financial_assistant/features/blueprint/presentation/providers/blueprint_providers.dart';
import 'package:personal_financial_assistant/features/blueprint/presentation/screens/financial_setup_screen.dart';
import 'package:personal_financial_assistant/features/categories/category.dart';
import 'package:personal_financial_assistant/features/categories/presentation/providers/category_providers.dart';
import 'package:personal_financial_assistant/features/categories/presentation/screens/categories_screen.dart';
import 'package:personal_financial_assistant/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:personal_financial_assistant/features/goals/domain/repositories/goal_repository.dart';
import 'package:personal_financial_assistant/features/goals/goal.dart';
import 'package:personal_financial_assistant/features/goals/presentation/providers/goal_providers.dart';
import 'package:personal_financial_assistant/features/goals/presentation/screens/goals_screen.dart';
import 'package:personal_financial_assistant/features/loans/domain/repositories/loan_repository.dart';
import 'package:personal_financial_assistant/features/loans/loan.dart';
import 'package:personal_financial_assistant/features/loans/presentation/providers/loan_providers.dart';
import 'package:personal_financial_assistant/features/loans/presentation/screens/loans_screen.dart';
import 'package:personal_financial_assistant/features/planned_expenses/domain/repositories/planned_expense_repository.dart';
import 'package:personal_financial_assistant/features/planned_expenses/planned_expense.dart';
import 'package:personal_financial_assistant/features/planned_expenses/presentation/providers/planned_expense_providers.dart';
import 'package:personal_financial_assistant/features/planned_expenses/presentation/screens/planned_expenses_screen.dart';
import 'package:personal_financial_assistant/features/recurring_transactions/presentation/providers/recurring_transaction_providers.dart';
import 'package:personal_financial_assistant/features/recurring_transactions/presentation/screens/recurring_transactions_screen.dart';
import 'package:personal_financial_assistant/features/review/presentation/screens/monthly_review_screen.dart';
import 'package:personal_financial_assistant/features/settings/presentation/screens/settings_screen.dart';
import 'package:personal_financial_assistant/features/smart_entry/presentation/screens/smart_entry_screen.dart';
import 'package:personal_financial_assistant/features/trade_off/presentation/screens/trade_off_screen.dart';
import 'package:personal_financial_assistant/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:personal_financial_assistant/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:personal_financial_assistant/features/transactions/presentation/screens/transactions_screen.dart';
import 'package:personal_financial_assistant/features/transactions/transaction.dart';
import 'package:personal_financial_assistant/features/workspaces/presentation/providers/workspace_providers.dart';
import 'package:personal_financial_assistant/features/workspaces/workspace.dart';

class _FakeUser extends Fake implements User {
  @override
  String get uid => 'u1';
  @override
  String? get email => 'test@finaura.com';
  @override
  String? get displayName => 'Masood';
}

class _FakeAuthRepository implements AuthRepository {
  final User? _user;
  _FakeAuthRepository([this._user]);

  @override
  User? get currentUser => _user;
  @override
  Stream<User?> get authStateChanges => Stream.value(_user);
  @override
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async => throw UnimplementedError();
  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async => throw UnimplementedError();
  @override
  Future<void> signOut() async {}
  @override
  Future<void> sendPasswordResetEmail(String email) async =>
      throw UnimplementedError();
  @override
  Future<void> updateDisplayName(String displayName) async {}
}

class _FakePlannedExpenseRepo implements PlannedExpenseRepository {
  @override
  Future<void> createPlannedExpense(dynamic exp) async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeLoanRepo implements LoanRepository {
  @override
  Future<void> createLoan(dynamic loan) async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAccountRepo implements AccountRepository {
  @override
  Future<void> createAccount(dynamic acc) async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeGoalRepo implements GoalRepository {
  @override
  Future<void> createGoal(dynamic goal) async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeTransactionRepo implements TransactionRepository {
  @override
  Future<void> createTransaction(dynamic tx) async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final fakeUser = _FakeUser();
  final now = DateTime.now();
  final mockWorkspace = Workspace.createDefault('u1').copyWith(
    name: 'Primary Household',
    purpose: 'Pay off home loan and build emergency buffer.',
    priorities: ['Reduce debt', 'Build emergency savings'],
  );

  final sampleAccount = Account(
    id: 'acc_1',
    userId: 'u1',
    name: 'HDFC Salary Bank',
    type: AccountType.bank,
    currency: 'INR',
    openingBalance: 150000.0,
    active: true,
    createdAt: now,
    updatedAt: now,
  );

  final sampleLoan = Loan(
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

  final sampleGoal = Goal(
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

  final sampleCategory = Category(
    id: 'cat_1',
    userId: 'u1',
    name: 'Groceries',
    type: CategoryType.expense,
    active: true,
    isDefault: true,
    createdAt: now,
    updatedAt: now,
  );

  final sampleTransaction = Transaction(
    id: 'txn_1',
    userId: 'u1',
    accountId: 'acc_1',
    type: TransactionType.expense,
    amount: 3200.0,
    date: now,
    categoryId: 'cat_1',
    note: 'Weekly supermarket groceries',
    createdAt: now,
    updatedAt: now,
  );

  final samplePlannedExpense = PlannedExpense(
    id: 'plan_1',
    userId: 'u1',
    name: 'Car Insurance',
    defaultAmount: 18000.0,
    frequency: RecurrenceFrequency.monthly,
    startDate: DateTime(now.year, now.month, 1),
    categoryId: 'cat_1',
    createdAt: now,
    updatedAt: now,
  );

  final persistenceService = BlueprintPersistenceService(
    plannedExpenseRepo: _FakePlannedExpenseRepo(),
    loanRepo: _FakeLoanRepo(),
    accountRepo: _FakeAccountRepo(),
    goalRepo: _FakeGoalRepo(),
    transactionRepo: _FakeTransactionRepo(),
  );

  List<Override> buildOverrides() {
    return [
      authStateChangesProvider.overrideWith((ref) => Stream.value(fakeUser)),
      currentUserProvider.overrideWith((ref) => fakeUser),
      authRepositoryProvider.overrideWithValue(_FakeAuthRepository(fakeUser)),
      workspacesStreamProvider.overrideWith(
        (ref) => Stream.value([mockWorkspace]),
      ),
      activeWorkspaceProvider.overrideWithValue(mockWorkspace),
      accountsStreamProvider.overrideWith(
        (ref) => Stream.value([sampleAccount]),
      ),
      transactionsStreamProvider.overrideWith(
        (ref) => Stream.value([sampleTransaction]),
      ),
      loansStreamProvider.overrideWith((ref) => Stream.value([sampleLoan])),
      goalsStreamProvider.overrideWith((ref) => Stream.value([sampleGoal])),
      plannedExpensesStreamProvider.overrideWith(
        (ref) => Stream.value([samplePlannedExpense]),
      ),
      monthlyOverridesStreamProvider.overrideWith((ref) => Stream.value([])),
      categoriesStreamProvider.overrideWith(
        (ref) => Stream.value([sampleCategory]),
      ),
      incomeCategoriesProvider.overrideWith(
        (ref) => const AsyncValue.data(<Category>[]),
      ),
      expenseCategoriesProvider.overrideWith(
        (ref) => AsyncValue.data(<Category>[sampleCategory]),
      ),
      accountTypesStreamProvider.overrideWith((ref) => Stream.value([])),
      recurringTransactionsStreamProvider.overrideWith(
        (ref) => Stream.value([]),
      ),
      blueprintPersistenceServiceProvider.overrideWithValue(persistenceService),
      blueprintControllerProvider.overrideWith(
        (ref) => BlueprintController(
          const FinancialSituationParser(),
          persistenceService,
        ),
      ),
    ];
  }

  final viewports = [
    {'name': 'Mobile 360px', 'size': const Size(360, 800)},
    {'name': 'Mobile 390px', 'size': const Size(390, 844)},
    {'name': 'Mobile 430px', 'size': const Size(430, 932)},
    {'name': 'Desktop 1280px', 'size': const Size(1280, 800)},
  ];

  group(
    'MANUAL QA — Responsive & Layout Verification across 16 Core Screens',
    () {
      for (final vp in viewports) {
        final vpName = vp['name']! as String;
        final vpSize = vp['size']! as Size;

        testWidgets('1. Login Screen on $vpName', (WidgetTester tester) async {
          tester.view.physicalSize = vpSize;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(
            ProviderScope(
              overrides: buildOverrides(),
              child: const MaterialApp(home: LoginScreen()),
            ),
          );
          await tester.pump(Duration.zero);
          await tester.pumpAndSettle();
          expect(find.text('Sign In'), findsWidgets);
          expect(tester.takeException(), isNull);
        });

        testWidgets('2. Register Screen on $vpName', (
          WidgetTester tester,
        ) async {
          tester.view.physicalSize = vpSize;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(
            ProviderScope(
              overrides: buildOverrides(),
              child: const MaterialApp(home: RegisterScreen()),
            ),
          );
          await tester.pump(Duration.zero);
          await tester.pumpAndSettle();
          expect(find.text('Create My Account'), findsOneWidget);
          expect(tester.takeException(), isNull);
        });

        testWidgets('3. Dashboard Screen on $vpName', (
          WidgetTester tester,
        ) async {
          tester.view.physicalSize = vpSize;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(
            ProviderScope(
              overrides: buildOverrides(),
              child: const MaterialApp(home: Scaffold(body: DashboardScreen())),
            ),
          );
          await tester.pump(Duration.zero);
          await tester.pumpAndSettle();
          expect(find.text('Tell FINAURA About Your Money'), findsOneWidget);
          expect(find.text('Current Financial Situation'), findsOneWidget);
          expect(tester.takeException(), isNull);
        });

        testWidgets('4. Accounts Screen on $vpName', (
          WidgetTester tester,
        ) async {
          tester.view.physicalSize = vpSize;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(
            ProviderScope(
              overrides: buildOverrides(),
              child: const MaterialApp(home: AccountsScreen()),
            ),
          );
          await tester.pump(Duration.zero);
          await tester.pumpAndSettle();
          expect(find.text('Accounts'), findsOneWidget);
          expect(tester.takeException(), isNull);
        });

        testWidgets('5. Transactions Screen on $vpName', (
          WidgetTester tester,
        ) async {
          tester.view.physicalSize = vpSize;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(
            ProviderScope(
              overrides: buildOverrides(),
              child: const MaterialApp(home: TransactionsScreen()),
            ),
          );
          await tester.pump(Duration.zero);
          await tester.pumpAndSettle();
          expect(find.text('Transactions'), findsOneWidget);
          expect(tester.takeException(), isNull);
        });

        testWidgets('6. Analytics Screen on $vpName', (
          WidgetTester tester,
        ) async {
          tester.view.physicalSize = vpSize;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(
            ProviderScope(
              overrides: buildOverrides(),
              child: const MaterialApp(home: AnalyticsScreen()),
            ),
          );
          await tester.pump(Duration.zero);
          await tester.pumpAndSettle();
          expect(find.text('Analytics & Trends'), findsOneWidget);
          expect(find.text('Income'), findsWidgets);
          expect(find.text('Expense'), findsWidgets);
          expect(find.text('Net Cash Flow'), findsWidgets);
          expect(tester.takeException(), isNull);
        });

        testWidgets('7. Settings Screen on $vpName', (
          WidgetTester tester,
        ) async {
          tester.view.physicalSize = vpSize;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(
            ProviderScope(
              overrides: buildOverrides(),
              child: const MaterialApp(home: SettingsScreen()),
            ),
          );
          await tester.pump(Duration.zero);
          await tester.pumpAndSettle();
          expect(find.text('ACTIVE WORKSPACE & PURPOSE'), findsOneWidget);
          expect(tester.takeException(), isNull);
        });

        testWidgets('8. Loans Screen on $vpName', (WidgetTester tester) async {
          tester.view.physicalSize = vpSize;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(
            ProviderScope(
              overrides: buildOverrides(),
              child: const MaterialApp(home: LoansScreen()),
            ),
          );
          await tester.pump(Duration.zero);
          await tester.pumpAndSettle();
          expect(find.text('Loans & Debt Intelligence'), findsOneWidget);
          expect(tester.takeException(), isNull);
        });

        testWidgets('9. Goals Screen on $vpName', (WidgetTester tester) async {
          tester.view.physicalSize = vpSize;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(
            ProviderScope(
              overrides: buildOverrides(),
              child: const MaterialApp(home: GoalsScreen()),
            ),
          );
          await tester.pump(Duration.zero);
          await tester.pumpAndSettle();
          expect(find.text('Financial Goals'), findsOneWidget);
          expect(tester.takeException(), isNull);
        });

        testWidgets('10. Trade-Off Screen on $vpName', (
          WidgetTester tester,
        ) async {
          tester.view.physicalSize = vpSize;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(
            ProviderScope(
              overrides: buildOverrides(),
              child: const MaterialApp(home: TradeOffScreen()),
            ),
          );
          await tester.pump(Duration.zero);
          await tester.pumpAndSettle();
          expect(find.text('Loan vs Goal Trade-Offs'), findsOneWidget);
          expect(tester.takeException(), isNull);
        });

        testWidgets('11. Monthly Review Screen on $vpName', (
          WidgetTester tester,
        ) async {
          tester.view.physicalSize = vpSize;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(
            ProviderScope(
              overrides: buildOverrides(),
              child: const MaterialApp(home: MonthlyReviewScreen()),
            ),
          );
          await tester.pump(Duration.zero);
          await tester.pumpAndSettle();
          expect(find.text('Monthly Review'), findsWidgets);
          expect(tester.takeException(), isNull);
        });

        testWidgets('12. Planned Expenses Screen on $vpName', (
          WidgetTester tester,
        ) async {
          tester.view.physicalSize = vpSize;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(
            ProviderScope(
              overrides: buildOverrides(),
              child: const MaterialApp(home: PlannedExpensesScreen()),
            ),
          );
          await tester.pump(Duration.zero);
          await tester.pumpAndSettle();
          expect(find.text('Planned Expenses'), findsOneWidget);
          expect(tester.takeException(), isNull);
        });

        testWidgets('13. Categories Screen on $vpName', (
          WidgetTester tester,
        ) async {
          tester.view.physicalSize = vpSize;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(
            ProviderScope(
              overrides: buildOverrides(),
              child: const MaterialApp(home: CategoriesScreen()),
            ),
          );
          await tester.pump(Duration.zero);
          await tester.pumpAndSettle();
          expect(find.text('Categories'), findsOneWidget);
          expect(tester.takeException(), isNull);
        });

        testWidgets('14. Account Types Screen on $vpName', (
          WidgetTester tester,
        ) async {
          tester.view.physicalSize = vpSize;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(
            ProviderScope(
              overrides: buildOverrides(),
              child: const MaterialApp(home: AccountTypesScreen()),
            ),
          );
          await tester.pump(Duration.zero);
          await tester.pumpAndSettle();
          expect(find.text('Account Types'), findsOneWidget);
          expect(tester.takeException(), isNull);
        });

        testWidgets('15. Smart Entry Screen on $vpName', (
          WidgetTester tester,
        ) async {
          tester.view.physicalSize = vpSize;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(
            ProviderScope(
              overrides: buildOverrides(),
              child: const MaterialApp(home: SmartEntryScreen()),
            ),
          );
          await tester.pump(Duration.zero);
          await tester.pumpAndSettle();
          expect(find.text('Smart Assistant Entry'), findsOneWidget);
          expect(tester.takeException(), isNull);
        });

        testWidgets('16. Financial Setup Screen on $vpName', (
          WidgetTester tester,
        ) async {
          tester.view.physicalSize = vpSize;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(
            ProviderScope(
              overrides: buildOverrides(),
              child: const MaterialApp(home: FinancialSetupScreen()),
            ),
          );
          await tester.pump(Duration.zero);
          await tester.pumpAndSettle();
          expect(find.text('Tell FINAURA About Your Money'), findsOneWidget);
          expect(tester.takeException(), isNull);
        });

        testWidgets('17. Recurring Transactions Screen on $vpName', (
          WidgetTester tester,
        ) async {
          tester.view.physicalSize = vpSize;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(
            ProviderScope(
              overrides: buildOverrides(),
              child: const MaterialApp(home: RecurringTransactionsScreen()),
            ),
          );
          await tester.pump(Duration.zero);
          await tester.pumpAndSettle();
          expect(find.text('Recurring Transactions'), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    },
  );
}
