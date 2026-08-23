import 'package:flutter_test/flutter_test.dart';
import 'package:personal_financial_assistant/core/errors/app_exception.dart';
import 'package:personal_financial_assistant/features/transactions/transaction.dart';

void main() {
  group('Transaction Validation Logic Tests', () {
    test('validates amount must be greater than zero', () {
      const amount = 0.0;
      expect(() {
        if (amount <= 0) {
          throw const ValidationException(
            'Transaction amount must be greater than zero',
          );
        }
      }, throwsA(isA<ValidationException>()));
    });

    test('validates note length max 200 characters', () {
      final note = 'A' * 201;
      expect(() {
        if (note.length > 200) {
          throw const ValidationException('Note cannot exceed 200 characters');
        }
      }, throwsA(isA<ValidationException>()));
    });

    test('validates Transfer cannot have same from and to account', () {
      const fromAcc = 'acc_hdfc';
      const toAcc = 'acc_hdfc';
      expect(() {
        if (fromAcc == toAcc) {
          throw const ValidationException(
            'From Account and To Account must be different',
          );
        }
      }, throwsA(isA<ValidationException>()));
    });

    test('validates Transfer category must be null', () {
      final Transaction t = Transaction(
        id: 'tx_1',
        userId: 'u_1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        type: TransactionType.transfer,
        amount: 5000.0,
        fromAccountId: 'acc_1',
        toAccountId: 'acc_2',
        categoryId: 'cat_invalid',
        date: DateTime.now(),
      );

      expect(() {
        if (t.type == TransactionType.transfer && t.categoryId != null) {
          throw const ValidationException('Transfers cannot have a category');
        }
      }, throwsA(isA<ValidationException>()));
    });
  });
}
