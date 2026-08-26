import 'package:flutter_test/flutter_test.dart';
import 'package:personal_financial_assistant/features/planned_expenses/planned_expense.dart';
import 'package:personal_financial_assistant/features/recurring_transactions/domain/models/recurring_transaction_rule.dart';
import 'package:personal_financial_assistant/features/recurring_transactions/domain/services/recurring_transaction_service.dart';
import 'package:personal_financial_assistant/features/transactions/transaction.dart';

void main() {
  const service = RecurringTransactionService();

  group('RecurringTransactionService — Leap Year & Month Day Math', () {
    test('isLeapYear identifies leap years correctly', () {
      expect(RecurringTransactionService.isLeapYear(2024), isTrue);
      expect(RecurringTransactionService.isLeapYear(2028), isTrue);
      expect(RecurringTransactionService.isLeapYear(2000), isTrue);
      expect(RecurringTransactionService.isLeapYear(2025), isFalse);
      expect(RecurringTransactionService.isLeapYear(2026), isFalse);
      expect(RecurringTransactionService.isLeapYear(2100), isFalse);
    });

    test('daysInMonth returns correct days across regular and leap years', () {
      expect(RecurringTransactionService.daysInMonth(2026, 1), 31);
      expect(RecurringTransactionService.daysInMonth(2026, 2), 28);
      expect(RecurringTransactionService.daysInMonth(2024, 2), 29); // leap year
      expect(RecurringTransactionService.daysInMonth(2026, 4), 30);
      expect(RecurringTransactionService.daysInMonth(2026, 12), 31);
    });
  });

  group('RecurringTransactionService — calculateNextOccurrence', () {
    test('Daily recurrence with interval = 1 and interval = 3', () {
      final start = DateTime(2026, 8, 1, 9, 0);
      final next1 = service.calculateNextOccurrence(
        fromDate: start,
        frequency: RecurrenceFrequency.daily,
        interval: 1,
      );
      expect(next1, DateTime(2026, 8, 2, 9, 0));

      final next3 = service.calculateNextOccurrence(
        fromDate: start,
        frequency: RecurrenceFrequency.daily,
        interval: 3,
      );
      expect(next3, DateTime(2026, 8, 4, 9, 0));
    });

    test('Weekly recurrence with interval = 1 and dayOfWeek', () {
      // 2026-08-03 is a Monday (weekday 1)
      final monday = DateTime(2026, 8, 3, 10, 0);
      final nextWeek = service.calculateNextOccurrence(
        fromDate: monday,
        frequency: RecurrenceFrequency.weekly,
        interval: 1,
      );
      expect(nextWeek, DateTime(2026, 8, 10, 10, 0));

      // Bi-weekly on Friday (weekday 5)
      final biWeeklyFriday = service.calculateNextOccurrence(
        fromDate: monday,
        frequency: RecurrenceFrequency.weekly,
        interval: 2,
        dayOfWeek: 5,
      );
      expect(biWeeklyFriday?.weekday, DateTime.friday);
      expect(biWeeklyFriday?.isAfter(monday), isTrue);
    });

    test('Monthly recurrence (Salary on 1st of month)', () {
      final aug1 = DateTime(2026, 8, 1);
      final nextSalary = service.calculateNextOccurrence(
        fromDate: aug1,
        frequency: RecurrenceFrequency.monthly,
        interval: 1,
        dayOfMonth: 1,
      );
      expect(nextSalary, DateTime(2026, 9, 1));
    });

    test('Monthly recurrence across year boundary (Dec -> Jan)', () {
      final dec1 = DateTime(2026, 12, 1);
      final nextMonth = service.calculateNextOccurrence(
        fromDate: dec1,
        frequency: RecurrenceFrequency.monthly,
        interval: 1,
        dayOfMonth: 1,
      );
      expect(nextMonth, DateTime(2027, 1, 1));
    });

    test('Month-end safe clamping (31st in Jan -> Feb 28 -> Mar 31 -> Apr 30)', () {
      final jan31 = DateTime(2026, 1, 31);
      final feb = service.calculateNextOccurrence(
        fromDate: jan31,
        frequency: RecurrenceFrequency.monthly,
        interval: 1,
        dayOfMonth: 31,
      );
      expect(feb, DateTime(2026, 2, 28)); // 2026 is non-leap year

      final mar = service.calculateNextOccurrence(
        fromDate: feb!,
        frequency: RecurrenceFrequency.monthly,
        interval: 1,
        dayOfMonth: 31,
      );
      expect(mar, DateTime(2026, 3, 31));

      final apr = service.calculateNextOccurrence(
        fromDate: mar!,
        frequency: RecurrenceFrequency.monthly,
        interval: 1,
        dayOfMonth: 31,
      );
      expect(apr, DateTime(2026, 4, 30));
    });

    test('Month-end safe clamping in leap year (Jan 31, 2024 -> Feb 29, 2024)', () {
      final jan31_2024 = DateTime(2024, 1, 31);
      final feb2024 = service.calculateNextOccurrence(
        fromDate: jan31_2024,
        frequency: RecurrenceFrequency.monthly,
        interval: 1,
        dayOfMonth: 31,
      );
      expect(feb2024, DateTime(2024, 2, 29));
    });

    test('Quarterly and Half-Yearly recurrence intervals', () {
      final start = DateTime(2026, 1, 15);
      final quarterly = service.calculateNextOccurrence(
        fromDate: start,
        frequency: RecurrenceFrequency.quarterly,
        interval: 1,
      );
      expect(quarterly, DateTime(2026, 4, 15));

      final halfYearly = service.calculateNextOccurrence(
        fromDate: start,
        frequency: RecurrenceFrequency.halfYearly,
        interval: 1,
      );
      expect(halfYearly, DateTime(2026, 7, 15));
    });

    test('Yearly recurrence (handles leap year Feb 29)', () {
      final leapDate = DateTime(2024, 2, 29);
      final nextYear = service.calculateNextOccurrence(
        fromDate: leapDate,
        frequency: RecurrenceFrequency.yearly,
        interval: 1,
        dayOfMonth: 29,
      );
      expect(nextYear, DateTime(2025, 2, 28));
    });

    test('End date boundary returns null when occurrence exceeds end date', () {
      final start = DateTime(2026, 8, 1);
      final endDate = DateTime(2026, 8, 15);
      final exceeded = service.calculateNextOccurrence(
        fromDate: start,
        frequency: RecurrenceFrequency.monthly,
        interval: 1,
        endDate: endDate,
      );
      expect(exceeded, isNull);
    });
  });

  group('RecurringTransactionService — getDueOccurrences & Catch-up', () {
    final now = DateTime(2026, 8, 15);

    test('Returns empty when rule is paused (active = false)', () {
      final rule = RecurringTransactionRule(
        id: 'rule_1',
        userId: 'u1',
        createdAt: now,
        updatedAt: now,
        type: TransactionType.expense,
        name: 'Gym',
        amount: 2000,
        categoryId: 'cat_fit',
        accountId: 'acc_bank',
        frequency: RecurrenceFrequency.monthly,
        startDate: DateTime(2026, 8, 1),
        nextOccurrence: DateTime(2026, 8, 1),
        active: false,
      );

      final due = service.getDueOccurrences(rule, now);
      expect(due, isEmpty);
    });

    test('Returns single due occurrence when due today/past', () {
      final rule = RecurringTransactionRule(
        id: 'rule_salary',
        userId: 'u1',
        createdAt: now,
        updatedAt: now,
        type: TransactionType.income,
        name: 'Salary',
        amount: 80000,
        categoryId: 'cat_sal',
        accountId: 'acc_hdfc',
        frequency: RecurrenceFrequency.monthly,
        startDate: DateTime(2026, 8, 1),
        nextOccurrence: DateTime(2026, 8, 1),
        dayOfMonth: 1,
        active: true,
      );

      final due = service.getDueOccurrences(rule, DateTime(2026, 8, 15));
      expect(due.length, 1);
      expect(due.first, DateTime(2026, 8, 1));
    });

    test('Catch-up: Missed 3 monthly occurrences', () {
      final rule = RecurringTransactionRule(
        id: 'rule_rent',
        userId: 'u1',
        createdAt: now,
        updatedAt: now,
        type: TransactionType.expense,
        name: 'Rent',
        amount: 25000,
        categoryId: 'cat_rent',
        accountId: 'acc_hdfc',
        frequency: RecurrenceFrequency.monthly,
        startDate: DateTime(2026, 5, 1),
        nextOccurrence: DateTime(2026, 5, 1),
        dayOfMonth: 1,
        active: true,
      );

      // Current date is Aug 15: May 1, Jun 1, Jul 1, Aug 1 are all due (4 occurrences)
      final due = service.getDueOccurrences(rule, DateTime(2026, 8, 15));
      expect(due.length, 4);
      expect(due[0], DateTime(2026, 5, 1));
      expect(due[1], DateTime(2026, 6, 1));
      expect(due[2], DateTime(2026, 7, 1));
      expect(due[3], DateTime(2026, 8, 1));
    });

    test('Future occurrence returns empty list', () {
      final rule = RecurringTransactionRule(
        id: 'rule_future',
        userId: 'u1',
        createdAt: now,
        updatedAt: now,
        type: TransactionType.expense,
        name: 'Insurance',
        amount: 12000,
        categoryId: 'cat_ins',
        accountId: 'acc_bank',
        frequency: RecurrenceFrequency.monthly,
        startDate: DateTime(2026, 9, 1),
        nextOccurrence: DateTime(2026, 9, 1),
        active: true,
      );

      final due = service.getDueOccurrences(rule, DateTime(2026, 8, 15));
      expect(due, isEmpty);
    });
  });

  group('RecurringTransactionService — processRuleOccurrences & Linkage', () {
    test('Generates transactions and advances rule correctly (Salary example)', () {
      final rule = RecurringTransactionRule(
        id: 'rule_salary_hdfc',
        userId: 'u_masood',
        createdAt: DateTime(2026, 8, 1),
        updatedAt: DateTime(2026, 8, 1),
        type: TransactionType.income,
        name: 'Monthly Salary',
        amount: 80000.0,
        categoryId: 'cat_salary',
        accountId: 'acc_hdfc',
        frequency: RecurrenceFrequency.monthly,
        startDate: DateTime(2026, 8, 1),
        nextOccurrence: DateTime(2026, 8, 1),
        dayOfMonth: 1,
        active: true,
      );

      int idCounter = 1;
      final result = service.processRuleOccurrences(
        rule: rule,
        asOfDate: DateTime(2026, 8, 15),
        idGenerator: () => 'tx_${idCounter++}',
      );

      // Verify generated transaction
      expect(result.transactions.length, 1);
      final tx = result.transactions.first;
      expect(tx.id, 'tx_1');
      expect(tx.userId, 'u_masood');
      expect(tx.type, TransactionType.income);
      expect(tx.amount, 80000.0);
      expect(tx.accountId, 'acc_hdfc');
      expect(tx.categoryId, 'cat_salary');
      expect(tx.date, DateTime(2026, 8, 1));
      expect(tx.recurringRuleId, 'rule_salary_hdfc');
      expect(tx.note, contains('Monthly Salary'));

      // Verify updated rule next occurrence is advanced to 2026-09-01
      final updated = result.updatedRule;
      expect(updated.lastGeneratedDate, DateTime(2026, 8, 1));
      expect(updated.nextOccurrence, DateTime(2026, 9, 1));

      // Duplicate protection: Processing again immediately generates 0 transactions
      final rerun = service.processRuleOccurrences(
        rule: updated,
        asOfDate: DateTime(2026, 8, 15),
        idGenerator: () => 'tx_${idCounter++}',
      );
      expect(rerun.transactions, isEmpty);
      expect(rerun.updatedRule.nextOccurrence, DateTime(2026, 9, 1));
    });
  });
}

