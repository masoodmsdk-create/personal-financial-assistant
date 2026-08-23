import 'package:personal_financial_assistant/core/services/firestore_service.dart';
import 'package:personal_financial_assistant/features/accounts/domain/models/account_type_definition.dart';
import 'package:personal_financial_assistant/features/accounts/domain/repositories/account_type_repository.dart';

class FirestoreAccountTypeRepository implements AccountTypeRepository {
  final FirestoreService _firestoreService;
  static const String _collection = 'account_types';

  FirestoreAccountTypeRepository({FirestoreService? firestoreService})
    : _firestoreService = firestoreService ?? FirestoreService();

  @override
  Stream<List<AccountTypeDefinition>> watchAccountTypes(String userId) {
    final stream = _firestoreService.watchCollection(
      userId: userId,
      collection: _collection,
      params: const QueryParams(orderBy: 'sortOrder', descending: false),
    );

    return stream.map((docs) {
      final customTypes = docs
          .map((d) => AccountTypeDefinition.fromJson(d))
          .toList();
      final combined = [...AccountTypeDefinition.defaultTypes, ...customTypes];
      combined.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return combined;
    });
  }

  @override
  Future<List<AccountTypeDefinition>> getAccountTypes(String userId) async {
    final docs = await _firestoreService.queryCollection(
      userId: userId,
      collection: _collection,
      params: const QueryParams(orderBy: 'sortOrder', descending: false),
    );

    final customTypes = docs
        .map((d) => AccountTypeDefinition.fromJson(d))
        .toList();
    final combined = [...AccountTypeDefinition.defaultTypes, ...customTypes];
    combined.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return combined;
  }

  @override
  Future<void> createAccountType(AccountTypeDefinition typeDef) async {
    if (typeDef.userId == 'system') {
      throw ArgumentError('Cannot create custom type with userId=system');
    }
    await _firestoreService.setData(
      userId: typeDef.userId,
      collection: _collection,
      docId: typeDef.id,
      data: typeDef.toJson(),
    );
  }

  @override
  Future<void> updateAccountType(AccountTypeDefinition typeDef) async {
    if (typeDef.isDefault || typeDef.userId == 'system') {
      throw ArgumentError('System default account types cannot be updated');
    }
    await _firestoreService.setData(
      userId: typeDef.userId,
      collection: _collection,
      docId: typeDef.id,
      data: typeDef.toJson(),
      merge: true,
    );
  }

  @override
  Future<void> archiveAccountType({
    required String userId,
    required String typeId,
  }) async {
    if (AccountTypeDefinition.defaultTypes.any((t) => t.id == typeId)) {
      throw ArgumentError('System default account types cannot be archived');
    }
    await _firestoreService.setData(
      userId: userId,
      collection: _collection,
      docId: typeId,
      data: {'active': false, 'updatedAt': DateTime.now().toIso8601String()},
      merge: true,
    );
  }
}
