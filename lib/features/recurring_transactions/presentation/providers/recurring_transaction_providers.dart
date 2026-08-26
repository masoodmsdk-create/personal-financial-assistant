import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_financial_assistant/features/auth/presentation/providers/auth_providers.dart';
import 'package:personal_financial_assistant/features/recurring_transactions/data/repositories/firestore_recurring_transaction_repository.dart';
import 'package:personal_financial_assistant/features/recurring_transactions/domain/models/recurring_transaction_rule.dart';
import 'package:personal_financial_assistant/features/recurring_transactions/domain/repositories/recurring_transaction_repository.dart';
import 'package:personal_financial_assistant/features/recurring_transactions/domain/services/recurring_transaction_service.dart';
import 'package:personal_financial_assistant/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:personal_financial_assistant/features/transactions/presentation/providers/transaction_providers.dart';

final recurringTransactionRepositoryProvider =
    Provider<RecurringTransactionRepository>((ref) {
      return FirestoreRecurringTransactionRepository();
    });

final recurringTransactionServiceProvider =
    Provider<RecurringTransactionService>((ref) {
      return const RecurringTransactionService();
    });

final recurringTransactionsStreamProvider =
    StreamProvider<List<RecurringTransactionRule>>((ref) {
      final user = ref.watch(currentUserProvider);
      if (user == null) return Stream.value([]);
      final repo = ref.watch(recurringTransactionRepositoryProvider);
      return repo.getRecurringTransactions(user.uid);
    });

/// Provider for recurring rules that are currently due for processing
final dueRecurringTransactionsProvider =
    Provider<List<RecurringTransactionRule>>((ref) {
      final rulesAsync = ref.watch(recurringTransactionsStreamProvider);
      return rulesAsync.when(
        data: (rules) => rules.where((r) => r.isDue()).toList(),
        loading: () => [],
        error: (_, _) => [],
      );
    });

/// Controller for recurring transaction operations and batch due-processing
class RecurringTransactionController extends StateNotifier<AsyncValue<void>> {
  final RecurringTransactionRepository _repository;
  final TransactionRepository _transactionRepository;
  final RecurringTransactionService _service;
  final Ref _ref;

  RecurringTransactionController(
    this._repository,
    this._transactionRepository,
    this._service,
    this._ref,
  ) : super(const AsyncValue.data(null));

  Future<bool> addRule(RecurringTransactionRule rule) async {
    state = const AsyncValue.loading();
    try {
      await _repository.createRecurringTransaction(rule);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateRule(RecurringTransactionRule rule) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateRecurringTransaction(rule);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteRule(String ruleId) async {
    state = const AsyncValue.loading();
    try {
      final user = _ref.read(currentUserProvider);
      if (user == null) throw Exception('User not authenticated');
      await _repository.deleteRecurringTransaction(user.uid, ruleId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> toggleStatus(String ruleId, bool active) async {
    state = const AsyncValue.loading();
    try {
      final user = _ref.read(currentUserProvider);
      if (user == null) throw Exception('User not authenticated');
      await _repository.toggleRecurringTransactionStatus(
        user.uid,
        ruleId,
        active,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Processes all due recurring transactions and generates corresponding
  /// transaction entries in Firestore. Returns count of transactions created.
  Future<int> processAllDueRules([DateTime? asOfDate]) async {
    state = const AsyncValue.loading();
    try {
      final dueRules = _ref.read(dueRecurringTransactionsProvider);
      if (dueRules.isEmpty) {
        state = const AsyncValue.data(null);
        return 0;
      }

      final now = asOfDate ?? DateTime.now();
      int createdCount = 0;

      for (final rule in dueRules) {
        final result = _service.processRuleOccurrences(
          rule: rule,
          asOfDate: now,
          idGenerator: () =>
              'tx_rec_${DateTime.now().microsecondsSinceEpoch}_$createdCount',
        );

        for (final tx in result.transactions) {
          await _transactionRepository.createTransaction(tx);
          createdCount++;
        }

        if (result.transactions.isNotEmpty) {
          await _repository.updateRecurringTransaction(result.updatedRule);
        }
      }

      state = const AsyncValue.data(null);
      return createdCount;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return 0;
    }
  }

  /// Processes a single rule's due occurrences immediately.
  Future<int> processSingleRule(
    RecurringTransactionRule rule, [
    DateTime? asOfDate,
  ]) async {
    state = const AsyncValue.loading();
    try {
      final now = asOfDate ?? DateTime.now();

      final result = _service.processRuleOccurrences(
        rule: rule,
        asOfDate: now,
        idGenerator: () => 'tx_rec_${DateTime.now().microsecondsSinceEpoch}',
      );

      for (final tx in result.transactions) {
        await _transactionRepository.createTransaction(tx);
      }

      if (result.transactions.isNotEmpty) {
        await _repository.updateRecurringTransaction(result.updatedRule);
      }

      state = const AsyncValue.data(null);
      return result.transactions.length;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return 0;
    }
  }
}

final recurringTransactionControllerProvider =
    StateNotifierProvider<RecurringTransactionController, AsyncValue<void>>((
      ref,
    ) {
      return RecurringTransactionController(
        ref.watch(recurringTransactionRepositoryProvider),
        ref.watch(transactionRepositoryProvider),
        ref.watch(recurringTransactionServiceProvider),
        ref,
      );
    });
