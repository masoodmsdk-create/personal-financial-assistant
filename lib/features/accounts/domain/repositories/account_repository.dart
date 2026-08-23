import 'package:personal_financial_assistant/features/accounts/account.dart';

abstract class AccountRepository {
  Future<List<Account>> getAccounts(String userId);
  Stream<List<Account>> watchAccounts(String userId);
  Future<void> createAccount(Account account);
  Future<void> updateAccount(Account account);
  Future<void> deleteAccount({
    required String userId,
    required String accountId,
  });
}
