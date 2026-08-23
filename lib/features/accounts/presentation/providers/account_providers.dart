import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_financial_assistant/features/accounts/account.dart';
import 'package:personal_financial_assistant/features/accounts/data/repositories/firestore_account_repository.dart';
import 'package:personal_financial_assistant/features/accounts/domain/repositories/account_repository.dart';
import 'package:personal_financial_assistant/features/auth/presentation/providers/auth_providers.dart';

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return FirestoreAccountRepository();
});

final accountsStreamProvider = StreamProvider<List<Account>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return Stream.value(const []);
  }
  final repository = ref.watch(accountRepositoryProvider);
  return repository.watchAccounts(user.uid);
});

final totalBalanceProvider = Provider<double>((ref) {
  final accountsAsync = ref.watch(accountsStreamProvider);
  return accountsAsync.when(
    data: (accounts) {
      return accounts.where((acc) => acc.active).fold(0.0, (sum, acc) {
        if (acc.isCreditAccount) {
          // Credit card balance subtracts from net asset balance
          return sum - acc.effectiveBalance;
        }
        return sum + acc.effectiveBalance;
      });
    },
    loading: () => 0.0,
    error: (_, _) => 0.0,
  );
});

class AccountController extends StateNotifier<AsyncValue<void>> {
  final AccountRepository _repository;
  final Ref _ref;

  AccountController(this._repository, this._ref) : super(const AsyncData(null));

  Future<bool> createAccount({
    required String name,
    required AccountType type,
    required double openingBalance,
    String currency = 'INR',
  }) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) {
      state = AsyncError('User not authenticated', StackTrace.current);
      return false;
    }

    state = const AsyncLoading();
    final now = DateTime.now();
    final newAccount = Account(
      id: 'acc_${now.millisecondsSinceEpoch}',
      userId: user.uid,
      createdAt: now,
      updatedAt: now,
      name: name.trim(),
      type: type,
      openingBalance: openingBalance,
      currency: currency,
      active: true,
    );

    state = await AsyncValue.guard(() => _repository.createAccount(newAccount));
    return !state.hasError;
  }

  Future<bool> updateAccount({
    required Account account,
    required String name,
    required AccountType type,
    required double openingBalance,
  }) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) {
      state = AsyncError('User not authenticated', StackTrace.current);
      return false;
    }

    state = const AsyncLoading();
    final updatedAccount = account.copyWith(
      name: name.trim(),
      type: type,
      openingBalance: openingBalance,
      updatedAt: DateTime.now(),
    );

    state = await AsyncValue.guard(
      () => _repository.updateAccount(updatedAccount),
    );
    return !state.hasError;
  }

  Future<bool> deleteAccount(String accountId) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) {
      state = AsyncError('User not authenticated', StackTrace.current);
      return false;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repository.deleteAccount(userId: user.uid, accountId: accountId),
    );
    return !state.hasError;
  }
}

final accountControllerProvider =
    StateNotifierProvider<AccountController, AsyncValue<void>>((ref) {
      return AccountController(ref.watch(accountRepositoryProvider), ref);
    });
