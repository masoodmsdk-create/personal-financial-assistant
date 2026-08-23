import 'package:flutter_test/flutter_test.dart';
import 'package:personal_financial_assistant/features/accounts/account.dart';
import 'package:personal_financial_assistant/features/blueprint/domain/services/financial_situation_parser.dart';
import 'package:personal_financial_assistant/features/categories/category.dart';
import 'package:personal_financial_assistant/features/goals/goal.dart';

void main() {
  late FinancialSituationParser parser;
  late List<Account> accounts;
  late List<Category> categories;

  setUp(() {
    parser = const FinancialSituationParser();
    final now = DateTime(2026, 8, 23);
    accounts = [
      Account(
        id: 'acc_hdfc',
        userId: 'user1',
        createdAt: now,
        updatedAt: now,
        name: 'HDFC Salary Account',
        type: AccountType.bank,
        openingBalance: 50000,
        currency: 'INR',
        active: true,
      ),
    ];
    categories = Category.generateDefaults('user1');
  });

  group('FinancialSituationParser Tests', () {
    test(
      'Acceptance Test 1: Multi-Income, EMI, and Multiple Living Expenses',
      () {
        const input = '''
My salary is ₹1,000.
My wife earns ₹1,000.
I have an EMI of ₹1,200.
Personal expenses ₹100.
Groceries ₹150.
Petrol ₹100.
''';

        final bp = parser.parseSituation(
          rawText: input,
          accounts: accounts,
          categories: categories,
        );

        // Incomes
        expect(bp.incomes.length, 2);
        expect(
          bp.incomes.any(
            (i) => i.monthlyAmount == 1000 && i.label == 'My Salary',
          ),
          isTrue,
        );
        expect(
          bp.incomes.any(
            (i) => i.monthlyAmount == 1000 && i.ownerLabel == 'Wife Salary',
          ),
          isTrue,
        );
        expect(bp.totalMonthlyIncome, 2000);

        // Loans / EMI
        expect(bp.loans.length, 1);
        expect(bp.loans.first.emiAmount, 1200);

        // Expenses
        expect(bp.recurringExpenses.length, 3);
        expect(
          bp.recurringExpenses.any(
            (e) => e.monthlyAmount == 100 && e.categoryName == 'Personal Care',
          ),
          isTrue,
        );
        expect(
          bp.recurringExpenses.any(
            (e) => e.monthlyAmount == 150 && e.categoryName == 'Groceries',
          ),
          isTrue,
        );
        expect(
          bp.recurringExpenses.any(
            (e) => e.monthlyAmount == 100 && e.categoryName == 'Fuel',
          ),
          isTrue,
        );
        expect(bp.totalMonthlyExpenses, 350);

        // Cash flow
        expect(bp.totalMonthlyCommitments, 1550);
        expect(bp.knownRemainingMonthlyCashFlow, 450);
      },
    );

    test('Acceptance Test 2: Comprehensive Setup with Incomes, Loan, Expenses, Savings, Goal', () {
      const input =
          'I earn ₹1 lakh monthly, my wife earns ₹60k, home loan EMI is ₹45k, rent ₹20k, groceries around ₹8k and petrol ₹5k. I have ₹2 lakh savings and want an emergency fund of ₹5 lakh.';

      final bp = parser.parseSituation(
        rawText: input,
        accounts: accounts,
        categories: categories,
      );

      // Incomes
      expect(bp.incomes.length, 2);
      expect(bp.incomes.any((i) => i.monthlyAmount == 100000), isTrue);
      expect(bp.incomes.any((i) => i.monthlyAmount == 60000), isTrue);
      expect(bp.totalMonthlyIncome, 160000);

      // Loan
      expect(bp.loans.length, 1);
      expect(bp.loans.first.loanName, 'Home Loan');
      expect(bp.loans.first.emiAmount, 45000);
      expect(bp.loans.first.missingFields, contains('principal'));
      expect(bp.loans.first.missingFields, contains('interestRate'));

      // Expenses
      expect(bp.recurringExpenses.length, 3);
      expect(
        bp.recurringExpenses.any(
          (e) => e.monthlyAmount == 20000 && e.categoryName == 'Rent',
        ),
        isTrue,
      );
      expect(
        bp.recurringExpenses.any(
          (e) => e.monthlyAmount == 8000 && e.categoryName == 'Groceries',
        ),
        isTrue,
      );
      expect(
        bp.recurringExpenses.any(
          (e) => e.monthlyAmount == 5000 && e.categoryName == 'Fuel',
        ),
        isTrue,
      );
      expect(bp.totalMonthlyExpenses, 33000);

      // Savings
      expect(bp.savings.length, 1);
      expect(bp.savings.first.amount, 200000);

      // Goal
      expect(bp.goals.length, 1);
      expect(bp.goals.first.goalName, 'Emergency Fund');
      expect(bp.goals.first.targetAmount, 500000);
      expect(bp.goals.first.goalType, GoalType.emergencyFund);

      // Cash flow summary
      expect(bp.totalMonthlyCommitments, 78000);
      expect(bp.knownRemainingMonthlyCashFlow, 82000);
    });

    test('Acceptance Test 3: Ambiguous EMI triggers targeted Clarification Question', () {
      const input = 'Paid ₹1,200 EMI yesterday.';

      final bp = parser.parseSituation(
        rawText: input,
        accounts: accounts,
        categories: categories,
      );

      expect(bp.clarifications.length, 1);
      final question = bp.clarifications.first;
      expect(question.question, contains('What does ₹1200 represent?'));
      expect(question.options.any((o) => o.id == 'actual_payment'), isTrue);
      expect(
        question.options.any((o) => o.id == 'recurring_commitment'),
        isTrue,
      );
    });

    test('Acceptance Test 4: Workspace Purpose does not invent financial records', () {
      const purpose =
          'My wife and I manage household finances. We want to reduce debt and build an emergency fund.';
      const input = 'I earn ₹1 lakh and my wife earns ₹60k.';

      final bp = parser.parseSituation(
        rawText: input,
        workspaceContext: purpose,
        accounts: accounts,
        categories: categories,
      );

      expect(bp.incomes.length, 2);
      expect(bp.totalMonthlyIncome, 160000);
      // Invariant check: Must NOT fabricate loan or emergency fund since not in text
      expect(bp.loans, isEmpty);
      expect(bp.goals, isEmpty);
      expect(bp.savings, isEmpty);
    });
  });
}
