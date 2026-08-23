import 'package:flutter_test/flutter_test.dart';
import 'package:personal_financial_assistant/features/accounts/account.dart';
import 'package:personal_financial_assistant/features/planned_expenses/planned_expense.dart';
import 'package:personal_financial_assistant/features/planned_expenses/planned_expense_override.dart';
import 'package:personal_financial_assistant/features/transactions/domain/services/financial_aggregation_service.dart';
import 'package:personal_financial_assistant/features/transactions/transaction.dart';

void main() {
  group('Financial Aggregation Engine Tests', () {
    final now = DateTime.parse('2026-08-23T07:00:00.000Z');
    final txDate = DateTime.parse('2026-08-20T00:00:00.000Z');

    test('Net Cash Flow Test: Income ₹100,000, Expense ₹30,000, Transfer ₹20,000 produces Net Cash Flow ₹70,000', () {
      final txs = [
        Transaction(
          id: 't1',
          userId: 'u1',
          createdAt: now,
          updatedAt: now,
          type: TransactionType.income,
          amount: 100000.0,
          accountId: 'acc_1',
          categoryId: 'cat_inc',
          date: txDate,
        ),
        Transaction(
          id: 't2',
          userId: 'u1',
          createdAt: now,
          updatedAt: now,
          type: TransactionType.expense,
          amount: 30000.0,
          accountId: 'acc_1',
          categoryId: 'cat_exp',
          date: txDate,
        ),
        Transaction(
          id: 't3',
          userId: 'u1',
          createdAt: now,
          updatedAt: now,
          type: TransactionType.transfer,
          amount: 20000.0,
          fromAccountId: 'acc_1',
          toAccountId: 'acc_2',
          date: txDate,
        ),
      ];

      final totalIncome = FinancialAggregationService.calculateTotalIncome(txs);
      final totalExpense = FinancialAggregationService.calculateTotalExpense(
        txs,
      );
      final netCashFlow = FinancialAggregationService.calculateNetCashFlow(txs);
      final totalTransfers =
          FinancialAggregationService.calculateTotalTransfers(txs);

      expect(totalIncome, 100000.0);
      expect(totalExpense, 30000.0);
      expect(netCashFlow, 70000.0);
      expect(totalTransfers, 20000.0);
    });

    test('Account Balance Test: Opening ₹25,000 + Income ₹10,000 - Expense ₹4,000 + Transfer In ₹5,000 - Transfer Out ₹2,000 = ₹34,000', () {
      final account = Account(
        id: 'acc_target',
        userId: 'u1',
        createdAt: now,
        updatedAt: now,
        name: 'HDFC Bank',
        type: AccountType.bank,
        openingBalance: 25000.0,
        currency: 'INR',
        active: true,
      );

      final accountOther = Account(
        id: 'acc_other',
        userId: 'u1',
        createdAt: now,
        updatedAt: now,
        name: 'SBI Bank',
        type: AccountType.bank,
        openingBalance: 5000.0,
        currency: 'INR',
        active: true,
      );

      final txs = [
        Transaction(
          id: 't1',
          userId: 'u1',
          createdAt: now,
          updatedAt: now,
          type: TransactionType.income,
          amount: 10000.0,
          accountId: 'acc_target',
          categoryId: 'cat_inc',
          date: txDate,
        ),
        Transaction(
          id: 't2',
          userId: 'u1',
          createdAt: now,
          updatedAt: now,
          type: TransactionType.expense,
          amount: 4000.0,
          accountId: 'acc_target',
          categoryId: 'cat_exp',
          date: txDate,
        ),
        Transaction(
          id: 't3',
          userId: 'u1',
          createdAt: now,
          updatedAt: now,
          type: TransactionType.transfer,
          amount: 5000.0,
          fromAccountId: 'acc_other',
          toAccountId: 'acc_target',
          date: txDate,
        ),
        Transaction(
          id: 't4',
          userId: 'u1',
          createdAt: now,
          updatedAt: now,
          type: TransactionType.transfer,
          amount: 2000.0,
          fromAccountId: 'acc_target',
          toAccountId: 'acc_other',
          date: txDate,
        ),
      ];

      final balances = FinancialAggregationService.calculateAccountBalances([
        account,
        accountOther,
      ], txs);

      expect(balances['acc_target'], 34000.0);
    });

    test('Credit Card balance contributes negatively to total net balance', () {
      final bank = Account(
        id: 'acc_bank',
        userId: 'u1',
        createdAt: now,
        updatedAt: now,
        name: 'HDFC Bank',
        type: AccountType.bank,
        openingBalance: 50000.0,
        currency: 'INR',
        active: true,
      );

      final card = Account(
        id: 'acc_card',
        userId: 'u1',
        createdAt: now,
        updatedAt: now,
        name: 'HDFC Credit Card',
        type: AccountType.creditCard,
        openingBalance: 15000.0, // Represents credit card debt/used limit
        currency: 'INR',
        active: true,
      );

      final balances = FinancialAggregationService.calculateAccountBalances([
        bank,
        card,
      ], []);

      final netBalance = FinancialAggregationService.calculateTotalNetBalance([
        bank,
        card,
      ], balances);

      expect(netBalance, 35000.0); // 50000 - 15000
    });

    test('Credit Card accounting: Expense increases debt, Bank to Card transfer reduces debt without double counting expense', () {
      final bank = Account(
        id: 'acc_bank',
        userId: 'u1',
        createdAt: now,
        updatedAt: now,
        name: 'HDFC Bank',
        type: AccountType.bank,
        openingBalance: 50000.0,
        currency: 'INR',
        active: true,
      );

      final card = Account(
        id: 'acc_card',
        userId: 'u1',
        createdAt: now,
        updatedAt: now,
        name: 'HDFC Credit Card',
        type: AccountType.creditCard,
        openingBalance: 0.0,
        currency: 'INR',
        active: true,
      );

      // Step 1: Expense of ₹10,000 on Credit Card
      final expenseTx = Transaction(
        id: 'tx_exp',
        userId: 'u1',
        createdAt: now,
        updatedAt: now,
        type: TransactionType.expense,
        amount: 10000.0,
        accountId: 'acc_card',
        categoryId: 'cat_shopping',
        date: txDate,
      );

      final balancesAfterExpense =
          FinancialAggregationService.calculateAccountBalances(
            [bank, card],
            [expenseTx],
          );

      expect(balancesAfterExpense['acc_bank'], 50000.0);
      expect(
        balancesAfterExpense['acc_card'],
        10000.0,
      ); // Outstanding debt is ₹10,000

      final netAfterExpense =
          FinancialAggregationService.calculateTotalNetBalance([
            bank,
            card,
          ], balancesAfterExpense);
      expect(netAfterExpense, 40000.0); // 50,000 asset - 10,000 debt = 40,000

      // Step 2: Transfer ₹10,000 from Bank -> Credit Card (Bill Payment)
      final paymentTx = Transaction(
        id: 'tx_pay',
        userId: 'u1',
        createdAt: now,
        updatedAt: now,
        type: TransactionType.transfer,
        amount: 10000.0,
        fromAccountId: 'acc_bank',
        toAccountId: 'acc_card',
        date: txDate,
      );

      final allTxs = [expenseTx, paymentTx];

      final balancesAfterPayment =
          FinancialAggregationService.calculateAccountBalances([
            bank,
            card,
          ], allTxs);

      expect(
        balancesAfterPayment['acc_bank'],
        40000.0,
      ); // Bank reduced by 10,000
      expect(
        balancesAfterPayment['acc_card'],
        0.0,
      ); // Credit card debt reduced to 0

      final netAfterPayment =
          FinancialAggregationService.calculateTotalNetBalance([
            bank,
            card,
          ], balancesAfterPayment);
      expect(netAfterPayment, 40000.0); // 40,000 asset - 0 debt = 40,000

      // Confirm Expenses total remains ₹10,000 (payment transfer did NOT add a 2nd expense)
      final totalExpense = FinancialAggregationService.calculateTotalExpense(
        allTxs,
      );
      expect(totalExpense, 10000.0);
    });

    test('Planned vs Actual Calculation for monthly forecast', () {
      final plans = [
        PlannedExpense(
          id: 'plan_1',
          userId: 'u1',
          createdAt: now,
          updatedAt: now,
          name: 'Rent',
          categoryId: 'cat_rent',
          defaultAmount: 25000.0,
          frequency: RecurrenceFrequency.monthly,
          startDate: DateTime(2026, 1, 1),
          active: true,
        ),
        PlannedExpense(
          id: 'plan_2',
          userId: 'u1',
          createdAt: now,
          updatedAt: now,
          name: 'Electricity',
          categoryId: 'cat_util',
          defaultAmount: 3000.0,
          frequency: RecurrenceFrequency.monthly,
          startDate: DateTime(2026, 1, 1),
          active: true,
        ),
      ];

      final overrides = [
        PlannedExpenseOverride(
          id: 'ov_1',
          userId: 'u1',
          createdAt: now,
          updatedAt: now,
          planId: 'plan_2',
          year: 2026,
          month: 8,
          amount: 2700.0,
        ),
      ];

      final txs = [
        Transaction(
          id: 'tx_act_1',
          userId: 'u1',
          createdAt: now,
          updatedAt: now,
          type: TransactionType.expense,
          amount: 25000.0,
          accountId: 'acc_1',
          categoryId: 'cat_rent',
          date: DateTime(2026, 8, 5),
        ),
      ];

      final res = FinancialAggregationService.calculatePlannedVsActual(
        plans: plans,
        overrides: overrides,
        transactions: txs,
        year: 2026,
        month: 8,
      );

      expect(res.totalPlannedAmount, 27700.0); // 25000 + 2700
      expect(res.totalActualExpense, 25000.0);
      expect(res.remainingPlannedAmount, 2700.0);
    });

    test('Aggregation by Period groups transactions by date properly', () {
      final txs = [
        Transaction(
          id: 't1',
          userId: 'u1',
          createdAt: now,
          updatedAt: now,
          type: TransactionType.income,
          amount: 50000.0,
          accountId: 'acc_1',
          categoryId: 'cat_inc',
          date: DateTime(2026, 1, 15),
        ),
        Transaction(
          id: 't2',
          userId: 'u1',
          createdAt: now,
          updatedAt: now,
          type: TransactionType.expense,
          amount: 12000.0,
          accountId: 'acc_1',
          categoryId: 'cat_exp',
          date: DateTime(2026, 2, 10),
        ),
      ];

      final monthlyAgg = FinancialAggregationService.aggregateByPeriod(
        txs,
        AggregationPeriod.monthly,
      );

      expect(monthlyAgg.length, 2);
    });
  });
}
