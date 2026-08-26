import 'dart:math';

import 'package:personal_financial_assistant/features/planned_expenses/planned_expense.dart';
import 'package:personal_financial_assistant/features/recurring_transactions/domain/models/recurring_transaction_rule.dart';
import 'package:personal_financial_assistant/features/transactions/transaction.dart';

class RecurringTransactionService {
  const RecurringTransactionService();

  /// Calculates whether a given year is a leap year.
  static bool isLeapYear(int year) {
    return (year % 4 == 0) && ((year % 100 != 0) || (year % 400 == 0));
  }

  /// Calculates the maximum days in a specific month of a given year.
  static int daysInMonth(int year, int month) {
    switch (month) {
      case 1:
      case 3:
      case 5:
      case 7:
      case 8:
      case 10:
      case 12:
        return 31;
      case 4:
      case 6:
      case 9:
      case 11:
        return 30;
      case 2:
        return isLeapYear(year) ? 29 : 28;
      default:
        return 30;
    }
  }

  /// Calculates the next occurrence date after [fromDate] based on recurrence rules.
  /// Returns `null` if the calculated date exceeds [endDate].
  DateTime? calculateNextOccurrence({
    required DateTime fromDate,
    required RecurrenceFrequency frequency,
    int interval = 1,
    int? dayOfMonth,
    int? dayOfWeek,
    DateTime? endDate,
  }) {
    if (frequency == RecurrenceFrequency.oneTime) {
      return null;
    }

    final safeInterval = interval < 1 ? 1 : interval;
    DateTime next;

    switch (frequency) {
      case RecurrenceFrequency.daily:
        next = DateTime(
          fromDate.year,
          fromDate.month,
          fromDate.day + safeInterval,
          fromDate.hour,
          fromDate.minute,
        );
        break;

      case RecurrenceFrequency.weekly:
        final nextWeekBase = fromDate.add(Duration(days: 7 * safeInterval));
        if (dayOfWeek != null && dayOfWeek >= 1 && dayOfWeek <= 7) {
          final diff = dayOfWeek - nextWeekBase.weekday;
          next = DateTime(
            nextWeekBase.year,
            nextWeekBase.month,
            nextWeekBase.day + diff,
            fromDate.hour,
            fromDate.minute,
          );
          if (next.isBefore(fromDate) || next.isAtSameMomentAs(fromDate)) {
            next = next.add(Duration(days: 7 * safeInterval));
          }
        } else {
          next = nextWeekBase;
        }
        break;

      case RecurrenceFrequency.monthly:
      case RecurrenceFrequency.quarterly:
      case RecurrenceFrequency.halfYearly:
        int monthStep = safeInterval;
        if (frequency == RecurrenceFrequency.quarterly) monthStep *= 3;
        if (frequency == RecurrenceFrequency.halfYearly) monthStep *= 6;

        final totalMonths = fromDate.month + monthStep - 1;
        final targetYear = fromDate.year + (totalMonths ~/ 12);
        final targetMonth = (totalMonths % 12) + 1;

        final desiredDay = dayOfMonth ?? fromDate.day;
        final maxDayInTargetMonth = daysInMonth(targetYear, targetMonth);
        final clampedDay = min(desiredDay, maxDayInTargetMonth);

        next = DateTime(
          targetYear,
          targetMonth,
          clampedDay,
          fromDate.hour,
          fromDate.minute,
        );
        break;

      case RecurrenceFrequency.yearly:
        final targetYear = fromDate.year + safeInterval;
        final targetMonth = fromDate.month;
        final desiredDay = dayOfMonth ?? fromDate.day;
        final maxDay = daysInMonth(targetYear, targetMonth);
        final clampedDay = min(desiredDay, maxDay);

        next = DateTime(
          targetYear,
          targetMonth,
          clampedDay,
          fromDate.hour,
          fromDate.minute,
        );
        break;

      case RecurrenceFrequency.oneTime:
        return null;
    }

    if (endDate != null && next.isAfter(endDate)) {
      return null;
    }

    return next;
  }

  /// Returns a list of all due occurrence dates for [rule] as of [asOfDate].
  /// Prevents infinite loops and caps at [maxCatchUpCount] (default 60).
  List<DateTime> getDueOccurrences(
    RecurringTransactionRule rule,
    DateTime asOfDate, {
    int maxCatchUpCount = 60,
  }) {
    if (!rule.active) return [];

    final today = DateTime(
      asOfDate.year,
      asOfDate.month,
      asOfDate.day,
      23,
      59,
      59,
    );
    final dueList = <DateTime>[];
    var current = rule.nextOccurrence;

    while (!current.isAfter(today) &&
        (rule.endDate == null || !current.isAfter(rule.endDate!)) &&
        dueList.length < maxCatchUpCount) {
      dueList.add(current);

      final next = calculateNextOccurrence(
        fromDate: current,
        frequency: rule.frequency,
        interval: rule.interval,
        dayOfMonth: rule.effectiveDayOfMonth,
        dayOfWeek: rule.dayOfWeek,
        endDate: rule.endDate,
      );

      if (next == null ||
          next.isAtSameMomentAs(current) ||
          next.isBefore(current)) {
        break;
      }
      current = next;
    }

    return dueList;
  }

  /// Generates a concrete [Transaction] for a specific occurrence date.
  Transaction generateTransaction({
    required RecurringTransactionRule rule,
    required DateTime occurrenceDate,
    required String transactionId,
  }) {
    final noteSuffix = rule.isIncome ? 'Recurring Income' : 'Recurring Expense';
    final formattedNote = rule.note != null && rule.note!.trim().isNotEmpty
        ? '${rule.name} • ${rule.note!.trim()}'
        : '${rule.name} ($noteSuffix)';

    return Transaction(
      id: transactionId,
      userId: rule.userId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      type: rule.type,
      amount: rule.amount,
      accountId: rule.accountId,
      categoryId: rule.categoryId,
      date: occurrenceDate,
      note: formattedNote,
      recurringRuleId: rule.id,
    );
  }

  /// Processes all due occurrences of a single rule, returning generated transactions
  /// and the updated [RecurringTransactionRule] with new `nextOccurrence` and `lastGeneratedDate`.
  ({List<Transaction> transactions, RecurringTransactionRule updatedRule})
  processRuleOccurrences({
    required RecurringTransactionRule rule,
    required DateTime asOfDate,
    required String Function() idGenerator,
  }) {
    final dueDates = getDueOccurrences(rule, asOfDate);
    if (dueDates.isEmpty) {
      return (transactions: <Transaction>[], updatedRule: rule);
    }

    final generated = <Transaction>[];
    for (final date in dueDates) {
      generated.add(
        generateTransaction(
          rule: rule,
          occurrenceDate: date,
          transactionId: idGenerator(),
        ),
      );
    }

    final lastDate = dueDates.last;
    final next = calculateNextOccurrence(
      fromDate: lastDate,
      frequency: rule.frequency,
      interval: rule.interval,
      dayOfMonth: rule.effectiveDayOfMonth,
      dayOfWeek: rule.dayOfWeek,
      endDate: rule.endDate,
    );

    final updated = rule.copyWith(
      lastGeneratedDate: lastDate,
      nextOccurrence: next ?? lastDate,
      updatedAt: DateTime.now(),
    );

    return (transactions: generated, updatedRule: updated);
  }
}
