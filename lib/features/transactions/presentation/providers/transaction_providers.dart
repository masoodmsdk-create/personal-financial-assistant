import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_financial_assistant/features/accounts/presentation/providers/account_providers.dart';
import 'package:personal_financial_assistant/features/auth/presentation/providers/auth_providers.dart';
import 'package:personal_financial_assistant/features/categories/presentation/providers/category_providers.dart';
import 'package:personal_financial_assistant/features/planned_expenses/presentation/providers/planned_expense_providers.dart';
import 'package:personal_financial_assistant/features/transactions/data/repositories/firestore_transaction_repository.dart';
import 'package:personal_financial_assistant/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:personal_financial_assistant/features/transactions/domain/services/financial_aggregation_service.dart';
import 'package:personal_financial_assistant/features/transactions/transaction.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return FirestoreTransactionRepository(
    categoryRepository: ref.watch(categoryRepositoryProvider),
    accountRepository: ref.watch(accountRepositoryProvider),
  );
});

final transactionsStreamProvider = StreamProvider<List<Transaction>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return Stream.value(const []);
  }
  final repository = ref.watch(transactionRepositoryProvider);
  return repository.watchTransactions(user.uid);
});

class TransactionFilterState {
  final TransactionType? type;
  final String? accountId;
  final String? categoryId;
  final DateTime? startDate;
  final DateTime? endDate;

  const TransactionFilterState({
    this.type,
    this.accountId,
    this.categoryId,
    this.startDate,
    this.endDate,
  });

  TransactionFilterState copyWith({
    TransactionType? Function()? type,
    String? Function()? accountId,
    String? Function()? categoryId,
    DateTime? Function()? startDate,
    DateTime? Function()? endDate,
  }) {
    return TransactionFilterState(
      type: type != null ? type() : this.type,
      accountId: accountId != null ? accountId() : this.accountId,
      categoryId: categoryId != null ? categoryId() : this.categoryId,
      startDate: startDate != null ? startDate() : this.startDate,
      endDate: endDate != null ? endDate() : this.endDate,
    );
  }
}

final transactionFilterProvider = StateProvider<TransactionFilterState>(
  (ref) => const TransactionFilterState(),
);

final filteredTransactionsProvider = Provider<AsyncValue<List<Transaction>>>((
  ref,
) {
  final transactionsAsync = ref.watch(transactionsStreamProvider);
  final filter = ref.watch(transactionFilterProvider);

  return transactionsAsync.whenData((transactions) {
    var result = transactions;
    if (filter.type != null) {
      result = result.where((t) => t.type == filter.type).toList();
    }
    if (filter.accountId != null) {
      result = result.where((t) {
        if (t.type == TransactionType.transfer) {
          return t.fromAccountId == filter.accountId ||
              t.toAccountId == filter.accountId;
        }
        return t.accountId == filter.accountId;
      }).toList();
    }
    if (filter.categoryId != null) {
      result = result.where((t) => t.categoryId == filter.categoryId).toList();
    }
    if (filter.startDate != null) {
      result = result
          .where((t) => !t.date.isBefore(filter.startDate!))
          .toList();
    }
    if (filter.endDate != null) {
      result = result.where((t) => !t.date.isAfter(filter.endDate!)).toList();
    }
    return result;
  });
});

final calculatedAccountBalancesProvider = Provider<Map<String, double>>((ref) {
  final accountsAsync = ref.watch(accountsStreamProvider);
  final transactionsAsync = ref.watch(transactionsStreamProvider);

  final accounts = accountsAsync.value ?? [];
  final transactions = transactionsAsync.value ?? [];

  return FinancialAggregationService.calculateAccountBalances(
    accounts,
    transactions,
  );
});

final calculatedTotalBalanceProvider = Provider<double>((ref) {
  final accountsAsync = ref.watch(accountsStreamProvider);
  final calculatedBalances = ref.watch(calculatedAccountBalancesProvider);

  final accounts = accountsAsync.value ?? [];
  return FinancialAggregationService.calculateTotalNetBalance(
    accounts,
    calculatedBalances,
  );
});

class MonthlySummaryData {
  final int year;
  final int month;
  final double totalIncome;
  final double totalExpense;
  final double netCashFlow;

  const MonthlySummaryData({
    required this.year,
    required this.month,
    required this.totalIncome,
    required this.totalExpense,
    required this.netCashFlow,
  });
}

final monthlyFinancialSummaryProvider = Provider<MonthlySummaryData>((ref) {
  final transactionsAsync = ref.watch(transactionsStreamProvider);
  final transactions = transactionsAsync.value ?? [];
  final now = DateTime.now();

  final currentMonthTransactions = transactions.where((t) {
    return t.date.year == now.year && t.date.month == now.month;
  }).toList();

  final income = FinancialAggregationService.calculateTotalIncome(
    currentMonthTransactions,
  );
  final expense = FinancialAggregationService.calculateTotalExpense(
    currentMonthTransactions,
  );

  return MonthlySummaryData(
    year: now.year,
    month: now.month,
    totalIncome: income,
    totalExpense: expense,
    netCashFlow: income - expense,
  );
});

final plannedVsActualProvider = Provider<PlannedVsActualData?>((ref) {
  final plansAsync = ref.watch(plannedExpensesStreamProvider);
  final overridesAsync = ref.watch(monthlyOverridesStreamProvider);
  final transactionsAsync = ref.watch(transactionsStreamProvider);
  final selectedDate = ref.watch(selectedForecastDateProvider);

  if (plansAsync.isLoading ||
      overridesAsync.isLoading ||
      transactionsAsync.isLoading) {
    return null;
  }

  final plans = plansAsync.value ?? [];
  final overrides = overridesAsync.value ?? [];
  final transactions = transactionsAsync.value ?? [];

  return FinancialAggregationService.calculatePlannedVsActual(
    plans: plans,
    overrides: overrides,
    transactions: transactions,
    year: selectedDate.year,
    month: selectedDate.month,
  );
});

class TransactionController extends StateNotifier<AsyncValue<void>> {
  final TransactionRepository _repository;
  final Ref _ref;

  TransactionController(this._repository, this._ref)
    : super(const AsyncData(null));

  String? _getCurrentUserId() {
    return _ref.read(currentUserProvider)?.uid;
  }

  Future<bool> createIncomeTransaction({
    required double amount,
    required String accountId,
    required String categoryId,
    required DateTime date,
    String? note,
  }) async {
    final userId = _getCurrentUserId();
    if (userId == null) {
      state = AsyncError('User not authenticated', StackTrace.current);
      return false;
    }

    state = const AsyncLoading();
    final now = DateTime.now();
    final transaction = Transaction(
      id: 'tx_${now.microsecondsSinceEpoch}',
      userId: userId,
      type: TransactionType.income,
      amount: amount,
      accountId: accountId,
      categoryId: categoryId,
      date: date,
      note: note,
      createdAt: now,
      updatedAt: now,
    );

    state = await AsyncValue.guard(
      () => _repository.createTransaction(transaction),
    );
    return !state.hasError;
  }

  Future<bool> createExpenseTransaction({
    required double amount,
    required String accountId,
    required String categoryId,
    required DateTime date,
    String? note,
  }) async {
    final userId = _getCurrentUserId();
    if (userId == null) {
      state = AsyncError('User not authenticated', StackTrace.current);
      return false;
    }

    state = const AsyncLoading();
    final now = DateTime.now();
    final transaction = Transaction(
      id: 'tx_${now.microsecondsSinceEpoch}',
      userId: userId,
      type: TransactionType.expense,
      amount: amount,
      accountId: accountId,
      categoryId: categoryId,
      date: date,
      note: note,
      createdAt: now,
      updatedAt: now,
    );

    state = await AsyncValue.guard(
      () => _repository.createTransaction(transaction),
    );
    return !state.hasError;
  }

  Future<bool> createTransferTransaction({
    required double amount,
    required String fromAccountId,
    required String toAccountId,
    required DateTime date,
    String? note,
  }) async {
    final userId = _getCurrentUserId();
    if (userId == null) {
      state = AsyncError('User not authenticated', StackTrace.current);
      return false;
    }

    state = const AsyncLoading();
    final now = DateTime.now();
    final transaction = Transaction(
      id: 'tx_${now.microsecondsSinceEpoch}',
      userId: userId,
      type: TransactionType.transfer,
      amount: amount,
      fromAccountId: fromAccountId,
      toAccountId: toAccountId,
      date: date,
      note: note,
      createdAt: now,
      updatedAt: now,
    );

    state = await AsyncValue.guard(
      () => _repository.createTransaction(transaction),
    );
    return !state.hasError;
  }

  Future<bool> updateTransaction(Transaction transaction) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repository.updateTransaction(transaction),
    );
    return !state.hasError;
  }

  Future<bool> deleteTransaction(String transactionId) async {
    final userId = _getCurrentUserId();
    if (userId == null) {
      state = AsyncError('User not authenticated', StackTrace.current);
      return false;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repository.deleteTransaction(
        userId: userId,
        transactionId: transactionId,
      ),
    );
    return !state.hasError;
  }
}

final transactionControllerProvider =
    StateNotifierProvider<TransactionController, AsyncValue<void>>((ref) {
      return TransactionController(
        ref.watch(transactionRepositoryProvider),
        ref,
      );
    });
