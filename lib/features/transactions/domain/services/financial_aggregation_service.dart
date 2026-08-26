import 'package:intl/intl.dart';
import 'package:personal_financial_assistant/features/accounts/account.dart';
import 'package:personal_financial_assistant/features/categories/category.dart';
import 'package:personal_financial_assistant/features/planned_expenses/planned_expense.dart';

import 'package:personal_financial_assistant/features/planned_expenses/planned_expense_override.dart';
import 'package:personal_financial_assistant/features/transactions/transaction.dart';

enum AggregationPeriod { weekly, monthly, yearly }

class PeriodAggregateData {
  final String label;
  final DateTime startDate;
  final DateTime endDate;
  final double totalIncome;
  final double totalExpense;
  final double netCashFlow;
  final double totalTransfers;

  const PeriodAggregateData({
    required this.label,
    required this.startDate,
    required this.endDate,
    required this.totalIncome,
    required this.totalExpense,
    required this.netCashFlow,
    required this.totalTransfers,
  });
}

class PlannedVsActualData {
  final int year;
  final int month;
  final double totalPlannedAmount;
  final double totalActualExpense;
  final double remainingPlannedAmount;

  const PlannedVsActualData({
    required this.year,
    required this.month,
    required this.totalPlannedAmount,
    required this.totalActualExpense,
    required this.remainingPlannedAmount,
  });
}

class FinancialAggregationService {
  static double calculateTotalIncome(List<Transaction> transactions) {
    double total = 0.0;
    for (final t in transactions) {
      if (t.type == TransactionType.income) {
        total += t.amount;
      }
    }
    return total;
  }

  static double calculateTotalExpense(List<Transaction> transactions) {
    double total = 0.0;
    for (final t in transactions) {
      if (t.type == TransactionType.expense) {
        total += t.amount;
      }
    }
    return total;
  }

  static double calculateNetCashFlow(List<Transaction> transactions) {
    final income = calculateTotalIncome(transactions);
    final expense = calculateTotalExpense(transactions);
    return income - expense;
  }

  static double calculateTotalTransfers(List<Transaction> transactions) {
    double total = 0.0;
    for (final t in transactions) {
      if (t.type == TransactionType.transfer) {
        total += t.amount;
      }
    }
    return total;
  }

  static Map<String, double> calculateExpenseByCategory(
    List<Transaction> transactions,
  ) {
    final Map<String, double> result = {};
    for (final t in transactions) {
      if (t.type == TransactionType.expense && t.categoryId != null) {
        result[t.categoryId!] = (result[t.categoryId!] ?? 0.0) + t.amount;
      }
    }
    return result;
  }

  static Map<String, double> calculateIncomeByCategory(
    List<Transaction> transactions,
  ) {
    final Map<String, double> result = {};
    for (final t in transactions) {
      if (t.type == TransactionType.income && t.categoryId != null) {
        result[t.categoryId!] = (result[t.categoryId!] ?? 0.0) + t.amount;
      }
    }
    return result;
  }

  static Map<String, double> calculateAccountBalances(
    List<Account> accounts,
    List<Transaction> transactions,
  ) {
    final Map<String, Account> accountMap = {for (final a in accounts) a.id: a};
    final Map<String, double> balances = {};
    for (final account in accounts) {
      balances[account.id] = account.openingBalance;
    }

    for (final t in transactions) {
      switch (t.type) {
        case TransactionType.income:
          if (t.accountId != null && balances.containsKey(t.accountId)) {
            final acc = accountMap[t.accountId!];
            if (acc != null && acc.isLiabilityAccount) {
              // Income/refund on liability reduces outstanding debt
              balances[t.accountId!] = balances[t.accountId!]! - t.amount;
            } else {
              // Income on asset account increases asset balance
              balances[t.accountId!] = balances[t.accountId!]! + t.amount;
            }
          }
          break;

        case TransactionType.expense:
          if (t.accountId != null && balances.containsKey(t.accountId)) {
            final acc = accountMap[t.accountId!];
            if (acc != null && acc.isLiabilityAccount) {
              // Expense on liability increases outstanding debt
              balances[t.accountId!] = balances[t.accountId!]! + t.amount;
            } else {
              // Expense on asset account decreases asset balance
              balances[t.accountId!] = balances[t.accountId!]! - t.amount;
            }
          }
          break;

        case TransactionType.transfer:
          if (t.fromAccountId != null &&
              balances.containsKey(t.fromAccountId)) {
            final fromAcc = accountMap[t.fromAccountId!];
            if (fromAcc != null && fromAcc.isLiabilityAccount) {
              // Cash advance from liability increases outstanding debt
              balances[t.fromAccountId!] =
                  balances[t.fromAccountId!]! + t.amount;
            } else {
              // Transfer out of asset account decreases asset balance
              balances[t.fromAccountId!] =
                  balances[t.fromAccountId!]! - t.amount;
            }
          }
          if (t.toAccountId != null && balances.containsKey(t.toAccountId)) {
            final toAcc = accountMap[t.toAccountId!];
            if (toAcc != null && toAcc.isLiabilityAccount) {
              // Transfer in / payment to liability decreases outstanding debt
              balances[t.toAccountId!] = balances[t.toAccountId!]! - t.amount;
            } else {
              // Transfer in to asset account increases asset balance
              balances[t.toAccountId!] = balances[t.toAccountId!]! + t.amount;
            }
          }
          break;
      }
    }

    return balances;
  }

  static double calculateTotalNetBalance(
    List<Account> accounts,
    Map<String, double> calculatedBalances,
  ) {
    double total = 0.0;
    for (final account in accounts) {
      if (!account.active) continue;
      final balance = calculatedBalances[account.id] ?? account.openingBalance;
      if (account.isLiabilityAccount) {
        total -= balance;
      } else {
        total += balance;
      }
    }
    return total;
  }

  static List<PeriodAggregateData> aggregateByPeriod(
    List<Transaction> transactions,
    AggregationPeriod period,
  ) {
    if (transactions.isEmpty) return [];

    final Map<String, List<Transaction>> grouped = {};
    final Map<String, DateTime> startDates = {};
    final Map<String, DateTime> endDates = {};
    final Map<String, String> labels = {};

    final monthlyFormat = DateFormat('MMM yyyy');
    final yearlyFormat = DateFormat('yyyy');

    for (final t in transactions) {
      String key;
      String label;
      DateTime start;
      DateTime end;

      final date = t.date;

      switch (period) {
        case AggregationPeriod.weekly:
          final monday = date.subtract(Duration(days: date.weekday - 1));
          final sunday = monday.add(const Duration(days: 6));
          key = '${monday.year}_W${(monday.day / 7).ceil()}';
          label =
              '${DateFormat('MMM dd').format(monday)} - ${DateFormat('MMM dd').format(sunday)}';
          start = DateTime(monday.year, monday.month, monday.day);
          end = DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59);
          break;

        case AggregationPeriod.monthly:
          key = '${date.year}_${date.month}';
          label = monthlyFormat.format(date);
          start = DateTime(date.year, date.month, 1);
          final nextMonth = date.month == 12
              ? DateTime(date.year + 1, 1, 1)
              : DateTime(date.year, date.month + 1, 1);
          end = nextMonth.subtract(const Duration(milliseconds: 1));
          break;

        case AggregationPeriod.yearly:
          key = '${date.year}';
          label = yearlyFormat.format(date);
          start = DateTime(date.year, 1, 1);
          end = DateTime(date.year, 12, 31, 23, 59, 59);
          break;
      }

      grouped.putIfAbsent(key, () => []).add(t);
      startDates.putIfAbsent(key, () => start);
      endDates.putIfAbsent(key, () => end);
      labels.putIfAbsent(key, () => label);
    }

    final keys = grouped.keys.toList();
    keys.sort((a, b) => startDates[b]!.compareTo(startDates[a]!));

    return keys.map((k) {
      final txs = grouped[k]!;
      final income = calculateTotalIncome(txs);
      final expense = calculateTotalExpense(txs);
      final transfers = calculateTotalTransfers(txs);
      return PeriodAggregateData(
        label: labels[k]!,
        startDate: startDates[k]!,
        endDate: endDates[k]!,
        totalIncome: income,
        totalExpense: expense,
        netCashFlow: income - expense,
        totalTransfers: transfers,
      );
    }).toList();
  }

  static PlannedVsActualData calculatePlannedVsActual({
    required List<PlannedExpense> plans,
    required List<PlannedExpenseOverride> overrides,
    required List<Transaction> transactions,
    required int year,
    required int month,
  }) {
    final overridesByPlanId = <String, PlannedExpenseOverride>{};
    for (final o in overrides) {
      if (o.year == year && o.month == month) {
        overridesByPlanId[o.planId] = o;
      }
    }

    double totalPlanned = 0.0;
    for (final plan in plans) {
      if (plan.active && plan.appliesToMonth(year, month)) {
        final override = overridesByPlanId[plan.id];
        totalPlanned += override?.amount ?? plan.defaultAmount;
      }
    }

    double totalActualExpense = 0.0;
    for (final t in transactions) {
      if (t.type == TransactionType.expense &&
          t.date.year == year &&
          t.date.month == month) {
        totalActualExpense += t.amount;
      }
    }

    return PlannedVsActualData(
      year: year,
      month: month,
      totalPlannedAmount: totalPlanned,
      totalActualExpense: totalActualExpense,
      remainingPlannedAmount: totalPlanned - totalActualExpense,
    );
  }

  static List<CategoryBreakdownItem> calculateCategoryBreakdown({
    required List<Transaction> transactions,
    required List<Category> categories,
    required CategoryType categoryType,
  }) {
    final targetType = categoryType == CategoryType.income
        ? TransactionType.income
        : TransactionType.expense;

    final categoryMap = {for (final c in categories) c.id: c};
    final Map<String, double> totalsByCatId = {};

    double totalSum = 0.0;
    for (final t in transactions) {
      if (t.type == targetType && t.categoryId != null) {
        totalsByCatId[t.categoryId!] =
            (totalsByCatId[t.categoryId!] ?? 0.0) + t.amount;
        totalSum += t.amount;
      }
    }

    if (totalSum == 0.0) return [];

    final List<CategoryBreakdownItem> items = [];
    totalsByCatId.forEach((catId, amount) {
      final category = categoryMap[catId];
      final name = category?.name ?? 'Uncategorized';
      final percentage = (amount / totalSum) * 100.0;
      items.add(
        CategoryBreakdownItem(
          categoryId: catId,
          categoryName: name,
          category: category,
          amount: amount,
          percentage: percentage,
        ),
      );
    });

    items.sort((a, b) => b.amount.compareTo(a.amount));
    return items;
  }
}

class CategoryBreakdownItem {
  final String categoryId;
  final String categoryName;
  final Category? category;
  final double amount;
  final double percentage;

  const CategoryBreakdownItem({
    required this.categoryId,
    required this.categoryName,
    this.category,
    required this.amount,
    required this.percentage,
  });
}
