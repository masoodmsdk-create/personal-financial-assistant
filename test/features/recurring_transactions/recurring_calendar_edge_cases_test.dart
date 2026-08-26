import 'package:flutter_test/flutter_test.dart';
import 'package:personal_financial_assistant/features/planned_expenses/planned_expense.dart';
import 'package:personal_financial_assistant/features/recurring_transactions/domain/models/recurring_transaction_rule.dart';
import 'package:personal_financial_assistant/features/recurring_transactions/domain/services/recurring_transaction_service.dart';
import 'package:personal_financial_assistant/features/transactions/transaction.dart';

void main() {
  const service = RecurringTransactionService();

  group('Recurring Calendar Edge-Case Audit & Invariant Tests', () {
    test('1. Leap year calculation logic', () {
      expect(RecurringTransactionService.isLeapYear(2024), isTrue);
      expect(RecurringTransactionService.isLeapYear(2026), isFalse);
      expect(RecurringTransactionService.isLeapYear(2027), isFalse);
      expect(RecurringTransactionService.isLeapYear(2028), isTrue);
      expect(RecurringTransactionService.isLeapYear(1900), isFalse);
      expect(RecurringTransactionService.isLeapYear(2000), isTrue);
    });

    test('2. 31st Monthly Recurrence across all 12 month transitions in non-leap year (2027)', () {
      // Intended day: 31
      final rule = RecurringTransactionRule(
        id: 'r_31_non_leap',
        userId: 'u_1',
        createdAt: DateTime(2027, 1, 1),
        updatedAt: DateTime(2027, 1, 1),
        type: TransactionType.expense,
        name: 'Month-end Bill',
        amount: 500.0,
        categoryId: 'cat_bills',
        accountId: 'acc_bank',
        frequency: RecurrenceFrequency.monthly,
        startDate: DateTime(2027, 1, 31),
        nextOccurrence: DateTime(2027, 1, 31),
      );

      expect(rule.effectiveDayOfMonth, 31);

      // Jan 31 -> Feb 28
      var next = service.calculateNextOccurrence(
        fromDate: DateTime(2027, 1, 31),
        frequency: rule.frequency,
        interval: 1,
        dayOfMonth: rule.effectiveDayOfMonth,
      );
      expect(next, DateTime(2027, 2, 28));

      // Feb 28 -> Mar 31 (recovers to 31st!)
      next = service.calculateNextOccurrence(
        fromDate: next!,
        frequency: rule.frequency,
        interval: 1,
        dayOfMonth: rule.effectiveDayOfMonth,
      );
      expect(next, DateTime(2027, 3, 31));

      // Mar 31 -> Apr 30
      next = service.calculateNextOccurrence(
        fromDate: next!,
        frequency: rule.frequency,
        interval: 1,
        dayOfMonth: rule.effectiveDayOfMonth,
      );
      expect(next, DateTime(2027, 4, 30));

      // Apr 30 -> May 31
      next = service.calculateNextOccurrence(
        fromDate: next!,
        frequency: rule.frequency,
        interval: 1,
        dayOfMonth: rule.effectiveDayOfMonth,
      );
      expect(next, DateTime(2027, 5, 31));

      // May 31 -> Jun 30
      next = service.calculateNextOccurrence(
        fromDate: next!,
        frequency: rule.frequency,
        interval: 1,
        dayOfMonth: rule.effectiveDayOfMonth,
      );
      expect(next, DateTime(2027, 6, 30));

      // Jun 30 -> Jul 31
      next = service.calculateNextOccurrence(
        fromDate: next!,
        frequency: rule.frequency,
        interval: 1,
        dayOfMonth: rule.effectiveDayOfMonth,
      );
      expect(next, DateTime(2027, 7, 31));

      // Jul 31 -> Aug 31
      next = service.calculateNextOccurrence(
        fromDate: next!,
        frequency: rule.frequency,
        interval: 1,
        dayOfMonth: rule.effectiveDayOfMonth,
      );
      expect(next, DateTime(2027, 8, 31));

      // Aug 31 -> Sep 30
      next = service.calculateNextOccurrence(
        fromDate: next!,
        frequency: rule.frequency,
        interval: 1,
        dayOfMonth: rule.effectiveDayOfMonth,
      );
      expect(next, DateTime(2027, 9, 30));

      // Sep 30 -> Oct 31
      next = service.calculateNextOccurrence(
        fromDate: next!,
        frequency: rule.frequency,
        interval: 1,
        dayOfMonth: rule.effectiveDayOfMonth,
      );
      expect(next, DateTime(2027, 10, 31));

      // Oct 31 -> Nov 30
      next = service.calculateNextOccurrence(
        fromDate: next!,
        frequency: rule.frequency,
        interval: 1,
        dayOfMonth: rule.effectiveDayOfMonth,
      );
      expect(next, DateTime(2027, 11, 30));

      // Nov 30 -> Dec 31
      next = service.calculateNextOccurrence(
        fromDate: next!,
        frequency: rule.frequency,
        interval: 1,
        dayOfMonth: rule.effectiveDayOfMonth,
      );
      expect(next, DateTime(2027, 12, 31));

      // Dec 31 -> Jan 31 (2028)
      next = service.calculateNextOccurrence(
        fromDate: next!,
        frequency: rule.frequency,
        interval: 1,
        dayOfMonth: rule.effectiveDayOfMonth,
      );
      expect(next, DateTime(2028, 1, 31));
    });

    test('3. 31st Monthly Recurrence in Leap Year (2028)', () {
      final rule = RecurringTransactionRule(
        id: 'r_31_leap',
        userId: 'u_1',
        createdAt: DateTime(2028, 1, 1),
        updatedAt: DateTime(2028, 1, 1),
        type: TransactionType.expense,
        name: 'Month-end Bill',
        amount: 500.0,
        categoryId: 'cat_bills',
        accountId: 'acc_bank',
        frequency: RecurrenceFrequency.monthly,
        startDate: DateTime(2028, 1, 31),
        nextOccurrence: DateTime(2028, 1, 31),
      );

      // Jan 31 -> Feb 29 in leap year
      final feb = service.calculateNextOccurrence(
        fromDate: DateTime(2028, 1, 31),
        frequency: rule.frequency,
        interval: 1,
        dayOfMonth: rule.effectiveDayOfMonth,
      );
      expect(feb, DateTime(2028, 2, 29));

      // Feb 29 -> Mar 31 (recovers to 31st!)
      final mar = service.calculateNextOccurrence(
        fromDate: feb!,
        frequency: rule.frequency,
        interval: 1,
        dayOfMonth: rule.effectiveDayOfMonth,
      );
      expect(mar, DateTime(2028, 3, 31));
    });

    test('4. 30th Monthly Recurrence handling', () {
      final rule = RecurringTransactionRule(
        id: 'r_30',
        userId: 'u_1',
        createdAt: DateTime(2027, 1, 1),
        updatedAt: DateTime(2027, 1, 1),
        type: TransactionType.expense,
        name: 'Rent',
        amount: 15000.0,
        categoryId: 'cat_rent',
        accountId: 'acc_bank',
        frequency: RecurrenceFrequency.monthly,
        startDate: DateTime(2027, 1, 30),
        nextOccurrence: DateTime(2027, 1, 30),
      );

      // Jan 30 -> Feb 28
      final feb = service.calculateNextOccurrence(
        fromDate: DateTime(2027, 1, 30),
        frequency: rule.frequency,
        interval: 1,
        dayOfMonth: rule.effectiveDayOfMonth,
      );
      expect(feb, DateTime(2027, 2, 28));

      // Feb 28 -> Mar 30 (recovers to 30th!)
      final mar = service.calculateNextOccurrence(
        fromDate: feb!,
        frequency: rule.frequency,
        interval: 1,
        dayOfMonth: rule.effectiveDayOfMonth,
      );
      expect(mar, DateTime(2027, 3, 30));
    });

    test('5. 29th Monthly Recurrence across leap & non-leap years', () {
      final rule = RecurringTransactionRule(
        id: 'r_29',
        userId: 'u_1',
        createdAt: DateTime(2027, 1, 1),
        updatedAt: DateTime(2027, 1, 1),
        type: TransactionType.expense,
        name: '29th Bill',
        amount: 1000.0,
        categoryId: 'cat_bills',
        accountId: 'acc_bank',
        frequency: RecurrenceFrequency.monthly,
        startDate: DateTime(2027, 1, 29),
        nextOccurrence: DateTime(2027, 1, 29),
      );

      // In 2027 (non-leap): Jan 29 -> Feb 28 -> Mar 29
      final feb27 = service.calculateNextOccurrence(
        fromDate: DateTime(2027, 1, 29),
        frequency: rule.frequency,
        interval: 1,
        dayOfMonth: rule.effectiveDayOfMonth,
      );
      expect(feb27, DateTime(2027, 2, 28));

      final mar27 = service.calculateNextOccurrence(
        fromDate: feb27!,
        frequency: rule.frequency,
        interval: 1,
        dayOfMonth: rule.effectiveDayOfMonth,
      );
      expect(mar27, DateTime(2027, 3, 29));

      // In 2028 (leap year): Jan 29 -> Feb 29 -> Mar 29
      final feb28 = service.calculateNextOccurrence(
        fromDate: DateTime(2028, 1, 29),
        frequency: rule.frequency,
        interval: 1,
        dayOfMonth: rule.effectiveDayOfMonth,
      );
      expect(feb28, DateTime(2028, 2, 29));

      final mar28 = service.calculateNextOccurrence(
        fromDate: feb28!,
        frequency: rule.frequency,
        interval: 1,
        dayOfMonth: rule.effectiveDayOfMonth,
      );
      expect(mar28, DateTime(2028, 3, 29));
    });

    test(
      '6. February 29 Yearly Recurrence preserves leap day across 4-year cycle',
      () {
        final rule = RecurringTransactionRule(
          id: 'r_leap_yearly',
          userId: 'u_1',
          createdAt: DateTime(2028, 2, 29),
          updatedAt: DateTime(2028, 2, 29),
          type: TransactionType.expense,
          name: 'Leap Year Special',
          amount: 5000.0,
          categoryId: 'cat_other',
          accountId: 'acc_bank',
          frequency: RecurrenceFrequency.yearly,
          startDate: DateTime(2028, 2, 29),
          nextOccurrence: DateTime(2028, 2, 29),
        );

        expect(rule.effectiveDayOfMonth, 29);

        // 2028 (leap) -> 2029 (non-leap: Feb 28)
        var next = service.calculateNextOccurrence(
          fromDate: DateTime(2028, 2, 29),
          frequency: rule.frequency,
          interval: 1,
          dayOfMonth: rule.effectiveDayOfMonth,
        );
        expect(next, DateTime(2029, 2, 28));

        // 2029 -> 2030 (non-leap: Feb 28)
        next = service.calculateNextOccurrence(
          fromDate: next!,
          frequency: rule.frequency,
          interval: 1,
          dayOfMonth: rule.effectiveDayOfMonth,
        );
        expect(next, DateTime(2030, 2, 28));

        // 2030 -> 2031 (non-leap: Feb 28)
        next = service.calculateNextOccurrence(
          fromDate: next!,
          frequency: rule.frequency,
          interval: 1,
          dayOfMonth: rule.effectiveDayOfMonth,
        );
        expect(next, DateTime(2031, 2, 28));

        // 2031 -> 2032 (leap year: Feb 29 recovered!)
        next = service.calculateNextOccurrence(
          fromDate: next!,
          frequency: rule.frequency,
          interval: 1,
          dayOfMonth: rule.effectiveDayOfMonth,
        );
        expect(next, DateTime(2032, 2, 29));
      },
    );

    test('7. Missed occurrences catch-up generation is duplicate-safe and retains 31st', () {
      // 31st Monthly Rule, last generated Jan 31, current date Mar 5
      final rule = RecurringTransactionRule(
        id: 'r_catch_up',
        userId: 'u_1',
        createdAt: DateTime(2027, 1, 1),
        updatedAt: DateTime(2027, 1, 1),
        type: TransactionType.expense,
        name: 'Broadband',
        amount: 999.0,
        categoryId: 'cat_bills',
        accountId: 'acc_bank',
        frequency: RecurrenceFrequency.monthly,
        startDate: DateTime(2027, 1, 31),
        nextOccurrence: DateTime(2027, 2, 28), // Next due was Feb 28
      );

      // As of March 5, 2027:
      final dueDates = service.getDueOccurrences(rule, DateTime(2027, 3, 5));
      expect(dueDates.length, 1);
      expect(dueDates.first, DateTime(2027, 2, 28));

      // Process rule occurrences
      int idCounter = 1;
      final result = service.processRuleOccurrences(
        rule: rule,
        asOfDate: DateTime(2027, 3, 5),
        idGenerator: () => 'tx_${idCounter++}',
      );

      expect(result.transactions.length, 1);
      expect(result.transactions.first.date, DateTime(2027, 2, 28));
      expect(result.transactions.first.recurringRuleId, 'r_catch_up');

      // Rule nextOccurrence is updated to March 31, 2027!
      expect(result.updatedRule.nextOccurrence, DateTime(2027, 3, 31));
      expect(result.updatedRule.effectiveDayOfMonth, 31);

      // Processing again immediately as of March 5 produces ZERO duplicate transactions
      final secondRun = service.processRuleOccurrences(
        rule: result.updatedRule,
        asOfDate: DateTime(2027, 3, 5),
        idGenerator: () => 'tx_${idCounter++}',
      );
      expect(secondRun.transactions, isEmpty);
    });

    test('8. End Date and Interval Edge Cases', () {
      final rule = RecurringTransactionRule(
        id: 'r_end',
        userId: 'u_1',
        createdAt: DateTime(2026, 8, 1),
        updatedAt: DateTime(2026, 8, 1),
        type: TransactionType.expense,
        name: 'Term Gym',
        amount: 2000.0,
        categoryId: 'cat_health',
        accountId: 'acc_bank',
        frequency: RecurrenceFrequency.monthly,
        startDate: DateTime(2026, 8, 15),
        endDate: DateTime(2026, 10, 15),
        nextOccurrence: DateTime(2026, 8, 15),
      );

      // Aug 15 -> Sep 15 -> Oct 15 -> null (exceeds Oct 15)
      final sep = service.calculateNextOccurrence(
        fromDate: DateTime(2026, 8, 15),
        frequency: rule.frequency,
        interval: 1,
        endDate: rule.endDate,
      );
      expect(sep, DateTime(2026, 9, 15));

      final oct = service.calculateNextOccurrence(
        fromDate: sep!,
        frequency: rule.frequency,
        interval: 1,
        endDate: rule.endDate,
      );
      expect(oct, DateTime(2026, 10, 15));

      final nov = service.calculateNextOccurrence(
        fromDate: oct!,
        frequency: rule.frequency,
        interval: 1,
        endDate: rule.endDate,
      );
      expect(nov, isNull);
    });
  });
}
