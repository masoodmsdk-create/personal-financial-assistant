import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_financial_assistant/features/accounts/account.dart';
import 'package:personal_financial_assistant/features/accounts/data/repositories/firestore_account_repository.dart';
import 'package:personal_financial_assistant/features/accounts/data/repositories/firestore_account_type_repository.dart';
import 'package:personal_financial_assistant/features/accounts/domain/models/account_type_definition.dart';
import 'package:personal_financial_assistant/features/accounts/domain/repositories/account_repository.dart';
import 'package:personal_financial_assistant/features/accounts/domain/repositories/account_type_repository.dart';
import 'package:personal_financial_assistant/features/auth/presentation/providers/auth_providers.dart';

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return FirestoreAccountRepository();
});

final accountTypeRepositoryProvider = Provider<AccountTypeRepository>((ref) {
  return FirestoreAccountTypeRepository();
});

final accountsStreamProvider = StreamProvider<List<Account>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return Stream.value(const []);
  }
  final repository = ref.watch(accountRepositoryProvider);
  return repository.watchAccounts(user.uid);
});

final accountTypesStreamProvider = StreamProvider<List<AccountTypeDefinition>>((
  ref,
) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return Stream.value(AccountTypeDefinition.defaultTypes);
  }
  final repository = ref.watch(accountTypeRepositoryProvider);
  return repository.watchAccountTypes(user.uid);
});

final totalBalanceProvider = Provider<double>((ref) {
  final accountsAsync = ref.watch(accountsStreamProvider);
  return accountsAsync.when(
    data: (accounts) {
      return accounts.where((acc) => acc.active).fold(0.0, (sum, acc) {
        if (acc.isLiabilityAccount) {
          // Liability accounts subtract from total net balance
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

  void resetState() {
    state = const AsyncData(null);
  }

  Future<bool> createAccount({
    required String name,
    required AccountType type,
    String? accountTypeId,
    AccountNature? nature,
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
    final randomSuffix = Random().nextInt(10000);
    final newAccount = Account(
      id: 'acc_${now.microsecondsSinceEpoch}_$randomSuffix',
      userId: user.uid,
      createdAt: now,
      updatedAt: now,
      name: name.trim(),
      type: type,
      accountTypeId: accountTypeId,
      nature: nature,
      openingBalance: openingBalance,
      currency: currency,
      active: true,
    );

    state = await AsyncValue.guard(() => _repository.createAccount(newAccount));
    final success = !state.hasError;
    if (success) {
      resetState();
    }
    return success;
  }

  Future<bool> updateAccount({
    required Account account,
    required String name,
    required AccountType type,
    String? accountTypeId,
    AccountNature? nature,
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
      accountTypeId: accountTypeId,
      nature: nature,
      openingBalance: openingBalance,
      updatedAt: DateTime.now(),
    );

    state = await AsyncValue.guard(
      () => _repository.updateAccount(updatedAccount),
    );
    final success = !state.hasError;
    if (success) {
      resetState();
    }
    return success;
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
    final success = !state.hasError;
    if (success) {
      resetState();
    }
    return success;
  }
}

final accountControllerProvider =
    StateNotifierProvider<AccountController, AsyncValue<void>>((ref) {
      return AccountController(ref.watch(accountRepositoryProvider), ref);
    });

class CustomAccountTypeController extends StateNotifier<AsyncValue<void>> {
  final AccountTypeRepository _repository;
  final Ref _ref;

  CustomAccountTypeController(this._repository, this._ref)
    : super(const AsyncData(null));

  void resetState() {
    state = const AsyncData(null);
  }

  Future<bool> createAccountType({
    required String name,
    required AccountNature nature,
  }) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) {
      state = AsyncError('User not authenticated', StackTrace.current);
      return false;
    }

    state = const AsyncLoading();
    final now = DateTime.now();
    final typeDef = AccountTypeDefinition(
      id: 'type_${now.microsecondsSinceEpoch}',
      userId: user.uid,
      createdAt: now,
      updatedAt: now,
      name: name.trim(),
      nature: nature,
      icon: nature == AccountNature.asset
          ? Icons.account_balance_wallet
          : Icons.credit_score,
      color: nature == AccountNature.asset
          ? const Color(0xFF2E7D32)
          : const Color(0xFFC62828),
      active: true,
      isDefault: false,
      sortOrder: 10,
    );

    state = await AsyncValue.guard(
      () => _repository.createAccountType(typeDef),
    );
    final success = !state.hasError;
    if (success) {
      resetState();
    }
    return success;
  }

  Future<bool> archiveAccountType(String typeId) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) {
      state = AsyncError('User not authenticated', StackTrace.current);
      return false;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repository.archiveAccountType(userId: user.uid, typeId: typeId),
    );
    final success = !state.hasError;
    if (success) {
      resetState();
    }
    return success;
  }
}

final customAccountTypeControllerProvider =
    StateNotifierProvider<CustomAccountTypeController, AsyncValue<void>>((ref) {
      return CustomAccountTypeController(
        ref.watch(accountTypeRepositoryProvider),
        ref,
      );
    });
