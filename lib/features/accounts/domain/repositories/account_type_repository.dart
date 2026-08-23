import 'package:personal_financial_assistant/features/accounts/domain/models/account_type_definition.dart';

abstract class AccountTypeRepository {
  Stream<List<AccountTypeDefinition>> watchAccountTypes(String userId);
  Future<List<AccountTypeDefinition>> getAccountTypes(String userId);
  Future<void> createAccountType(AccountTypeDefinition typeDef);
  Future<void> updateAccountType(AccountTypeDefinition typeDef);
  Future<void> archiveAccountType({
    required String userId,
    required String typeId,
  });
}
