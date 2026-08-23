import 'package:flutter_test/flutter_test.dart';
import 'package:personal_financial_assistant/features/accounts/account.dart';
import 'package:personal_financial_assistant/features/categories/category.dart';
import 'package:personal_financial_assistant/features/smart_entry/domain/services/smart_parser_service.dart';
import 'package:personal_financial_assistant/features/transactions/transaction.dart';

void main() {
  group('SmartParserService Unit Tests', () {
    late SmartParserService parser;
    late List<Account> mockAccounts;
    late List<Category> mockCategories;

    setUp(() {
      parser = const SmartParserService();

      mockAccounts = [
        Account(
          id: 'acc_sbi',
          userId: 'user_1',
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
          name: 'SBI Bank',
          type: AccountType.bank,
          openingBalance: 10000.0,
          currency: 'INR',
          active: true,
        ),
        Account(
          id: 'acc_hdfc',
          userId: 'user_1',
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
          name: 'HDFC Credit Card',
          type: AccountType.creditCard,
          openingBalance: 0.0,
          currency: 'INR',
          active: true,
        ),
        Account(
          id: 'acc_cash',
          userId: 'user_1',
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
          name: 'Cash Wallet',
          type: AccountType.cash,
          openingBalance: 2000.0,
          currency: 'INR',
          active: true,
        ),
      ];

      mockCategories = [
        Category(
          id: 'cat_food',
          userId: 'user_1',
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
          name: 'Food & Dining',
          type: CategoryType.expense,
          active: true,
        ),
        Category(
          id: 'cat_groceries',
          userId: 'user_1',
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
          name: 'Groceries',
          type: CategoryType.expense,
          active: true,
        ),
        Category(
          id: 'cat_fuel',
          userId: 'user_1',
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
          name: 'Transportation',
          type: CategoryType.expense,
          active: true,
        ),
        Category(
          id: 'cat_salary',
          userId: 'user_1',
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
          name: 'Salary',
          type: CategoryType.income,
          active: true,
        ),
      ];
    });

    test(
      'Parses single expense with amount, category, account, and relative date',
      () {
        const input = 'Paid 450 for lunch on HDFC card yesterday';
        final results = parser.parseText(
          rawText: input,
          accounts: mockAccounts,
          categories: mockCategories,
        );

        expect(results.length, 1);
        final draft = results.first;
        expect(draft.type, TransactionType.expense);
        expect(draft.amount, 450.0);
        expect(draft.accountId, 'acc_hdfc');
        expect(draft.categoryId, 'cat_food');
        expect(draft.note, contains('Lunch'));
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        expect(draft.date.day, yesterday.day);
      },
    );

    test('Parses income with salary keyword', () {
      const input = 'Salary 75000 credited to SBI today';
      final results = parser.parseText(
        rawText: input,
        accounts: mockAccounts,
        categories: mockCategories,
      );

      expect(results.length, 1);
      final draft = results.first;
      expect(draft.type, TransactionType.income);
      expect(draft.amount, 75000.0);
      expect(draft.accountId, 'acc_sbi');
      expect(draft.categoryId, 'cat_salary');
    });

    test('Parses bank transfer between accounts', () {
      const input = 'Transferred 5000 from SBI to HDFC';
      final results = parser.parseText(
        rawText: input,
        accounts: mockAccounts,
        categories: mockCategories,
      );

      expect(results.length, 1);
      final draft = results.first;
      expect(draft.type, TransactionType.transfer);
      expect(draft.amount, 5000.0);
      expect(draft.fromAccountId, 'acc_sbi');
      expect(draft.toAccountId, 'acc_hdfc');
    });

    test('Parses multi-line batch text correctly', () {
      const input = '''
        Paid 450 for lunch on HDFC
        Salary 80000 into SBI
        Bought groceries 1400 cash
      ''';
      final results = parser.parseText(
        rawText: input,
        accounts: mockAccounts,
        categories: mockCategories,
      );

      expect(results.length, 3);
      expect(results[0].amount, 450.0);
      expect(results[0].type, TransactionType.expense);

      expect(results[1].amount, 80000.0);
      expect(results[1].type, TransactionType.income);

      expect(results[2].amount, 1400.0);
      expect(results[2].type, TransactionType.expense);
      expect(results[2].accountId, 'acc_cash');
      expect(results[2].categoryId, 'cat_groceries');
    });

    test('Handles suffixes like k and L', () {
      const input = 'Invested 50k into stocks';
      final results = parser.parseText(
        rawText: input,
        accounts: mockAccounts,
        categories: mockCategories,
      );

      expect(results.length, 1);
      expect(results.first.amount, 50000.0);
    });

    test('Returns empty list when input has no detectable amount', () {
      const input = 'Just a casual random text without numbers';
      final results = parser.parseText(
        rawText: input,
        accounts: mockAccounts,
        categories: mockCategories,
      );

      expect(results.isEmpty, true);
    });
  });
}
