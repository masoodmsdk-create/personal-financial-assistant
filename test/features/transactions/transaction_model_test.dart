import 'package:flutter_test/flutter_test.dart';
import 'package:personal_financial_assistant/features/transactions/transaction.dart';

void main() {
  group('Transaction Model Tests', () {
    final now = DateTime.parse('2026-08-23T07:00:00.000Z');
    final txDate = DateTime.parse('2026-08-20T00:00:00.000Z');

    final incomeTx = Transaction(
      id: 'tx_inc_1',
      userId: 'user_123',
      createdAt: now,
      updatedAt: now,
      type: TransactionType.income,
      amount: 100000.00,
      accountId: 'acc_hdfc',
      categoryId: 'cat_salary',
      date: txDate,
      note: 'August Salary',
    );

    final expenseTx = Transaction(
      id: 'tx_exp_1',
      userId: 'user_123',
      createdAt: now,
      updatedAt: now,
      type: TransactionType.expense,
      amount: 30000.00,
      accountId: 'acc_hdfc',
      categoryId: 'cat_rent',
      date: txDate,
      note: 'House Rent',
    );

    final transferTx = Transaction(
      id: 'tx_trf_1',
      userId: 'user_123',
      createdAt: now,
      updatedAt: now,
      type: TransactionType.transfer,
      amount: 20000.00,
      fromAccountId: 'acc_hdfc',
      toAccountId: 'acc_sbi',
      date: txDate,
      note: 'Savings Transfer',
    );

    test('serializes and deserializes Income transaction correctly', () {
      final json = incomeTx.toJson();
      expect(json['id'], 'tx_inc_1');
      expect(json['type'], 'income');
      expect(json['amount'], 100000.00);
      expect(json['accountId'], 'acc_hdfc');
      expect(json['categoryId'], 'cat_salary');

      final deserialized = Transaction.fromJson(json);
      expect(deserialized.type, TransactionType.income);
      expect(deserialized.amount, 100000.00);
    });

    test('serializes and deserializes Expense transaction correctly', () {
      final json = expenseTx.toJson();
      expect(json['id'], 'tx_exp_1');
      expect(json['type'], 'expense');
      expect(json['amount'], 30000.00);
      expect(json['accountId'], 'acc_hdfc');
      expect(json['categoryId'], 'cat_rent');

      final deserialized = Transaction.fromJson(json);
      expect(deserialized.type, TransactionType.expense);
      expect(deserialized.amount, 30000.00);
    });

    test(
      'serializes and deserializes Transfer transaction without category',
      () {
        final json = transferTx.toJson();
        expect(json['id'], 'tx_trf_1');
        expect(json['type'], 'transfer');
        expect(json['amount'], 20000.00);
        expect(json['categoryId'], null);
        expect(json['fromAccountId'], 'acc_hdfc');
        expect(json['toAccountId'], 'acc_sbi');

        final deserialized = Transaction.fromJson(json);
        expect(deserialized.type, TransactionType.transfer);
        expect(deserialized.categoryId, null);
        expect(deserialized.fromAccountId, 'acc_hdfc');
        expect(deserialized.toAccountId, 'acc_sbi');
      },
    );

    test('TransactionType extension helpers return correct values', () {
      expect(TransactionType.income.value, 'income');
      expect(TransactionType.income.displayName, 'Income');
      expect(TransactionType.expense.displayName, 'Expense');
      expect(TransactionType.transfer.displayName, 'Transfer');
      expect(TransactionTypeX.fromString('transfer'), TransactionType.transfer);
    });
  });
}
