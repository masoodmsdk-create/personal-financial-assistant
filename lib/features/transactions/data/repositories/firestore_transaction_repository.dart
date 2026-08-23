import 'package:firebase_auth/firebase_auth.dart';
import 'package:personal_financial_assistant/core/errors/app_exception.dart';
import 'package:personal_financial_assistant/core/services/firestore_service.dart';
import 'package:personal_financial_assistant/features/accounts/domain/repositories/account_repository.dart';
import 'package:personal_financial_assistant/features/categories/domain/repositories/category_repository.dart';
import 'package:personal_financial_assistant/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:personal_financial_assistant/features/transactions/transaction.dart';

class FirestoreTransactionRepository implements TransactionRepository {
  final FirestoreService _firestoreService;
  final FirebaseAuth _firebaseAuth;

  static const String _collectionPath = 'transactions';
  static const int maxNoteLength = 200;

  FirestoreTransactionRepository({
    FirestoreService? firestoreService,
    FirebaseAuth? firebaseAuth,
    CategoryRepository? categoryRepository,
    AccountRepository? accountRepository,
  }) : _firestoreService = firestoreService ?? FirestoreService(),
       _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;


  String _requireCurrentUserId() {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw const AuthException('User is not authenticated');
    }
    return uid;
  }

  Future<void> _validateTransaction(
    Transaction transaction,
    String currentUid,
  ) async {
    if (transaction.amount <= 0) {
      throw const ValidationException(
        'Transaction amount must be greater than zero',
      );
    }

    final note = transaction.note?.trim();
    if (note != null && note.length > maxNoteLength) {
      throw ValidationException('Note cannot exceed $maxNoteLength characters');
    }

    switch (transaction.type) {
      case TransactionType.income:
        if (transaction.accountId == null || transaction.accountId!.isEmpty) {
          throw const ValidationException(
            'Account is required for Income transaction',
          );
        }
        if (transaction.categoryId == null || transaction.categoryId!.isEmpty) {
          throw const ValidationException(
            'Category is required for Income transaction',
          );
        }
        break;

      case TransactionType.expense:
        if (transaction.accountId == null || transaction.accountId!.isEmpty) {
          throw const ValidationException(
            'Account is required for Expense transaction',
          );
        }
        if (transaction.categoryId == null || transaction.categoryId!.isEmpty) {
          throw const ValidationException(
            'Category is required for Expense transaction',
          );
        }
        break;

      case TransactionType.transfer:
        if (transaction.fromAccountId == null ||
            transaction.fromAccountId!.isEmpty) {
          throw const ValidationException(
            'From Account is required for Transfer',
          );
        }
        if (transaction.toAccountId == null ||
            transaction.toAccountId!.isEmpty) {
          throw const ValidationException(
            'To Account is required for Transfer',
          );
        }
        if (transaction.fromAccountId == transaction.toAccountId) {
          throw const ValidationException(
            'From Account and To Account must be different',
          );
        }
        if (transaction.categoryId != null) {
          throw const ValidationException('Transfers cannot have a category');
        }
        break;
    }
  }

  @override
  Future<List<Transaction>> getTransactions(
    String userId, {
    TransactionType? type,
    String? accountId,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final currentUid = _requireCurrentUserId();
    final dataList = await _firestoreService.queryCollection(
      userId: currentUid,
      collection: _collectionPath,
      params: const QueryParams(orderBy: 'date', descending: true),
    );

    var transactions = dataList
        .map((data) => Transaction.fromJson(data))
        .toList();

    // In-memory filter for flexible querying
    if (type != null) {
      transactions = transactions.where((t) => t.type == type).toList();
    }
    if (accountId != null) {
      transactions = transactions.where((t) {
        if (t.type == TransactionType.transfer) {
          return t.fromAccountId == accountId || t.toAccountId == accountId;
        }
        return t.accountId == accountId;
      }).toList();
    }
    if (categoryId != null) {
      transactions = transactions
          .where((t) => t.categoryId == categoryId)
          .toList();
    }
    if (startDate != null) {
      transactions = transactions
          .where((t) => !t.date.isBefore(startDate))
          .toList();
    }
    if (endDate != null) {
      transactions = transactions
          .where((t) => !t.date.isAfter(endDate))
          .toList();
    }

    return transactions;
  }

  @override
  Stream<List<Transaction>> watchTransactions(
    String userId, {
    TransactionType? type,
    String? accountId,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final currentUid = _requireCurrentUserId();
    return _firestoreService
        .watchCollection(
          userId: currentUid,
          collection: _collectionPath,
          params: const QueryParams(orderBy: 'date', descending: true),
        )
        .map((dataList) {
          var transactions = dataList
              .map((data) => Transaction.fromJson(data))
              .toList();

          if (type != null) {
            transactions = transactions.where((t) => t.type == type).toList();
          }
          if (accountId != null) {
            transactions = transactions.where((t) {
              if (t.type == TransactionType.transfer) {
                return t.fromAccountId == accountId ||
                    t.toAccountId == accountId;
              }
              return t.accountId == accountId;
            }).toList();
          }
          if (categoryId != null) {
            transactions = transactions
                .where((t) => t.categoryId == categoryId)
                .toList();
          }
          if (startDate != null) {
            transactions = transactions
                .where((t) => !t.date.isBefore(startDate))
                .toList();
          }
          if (endDate != null) {
            transactions = transactions
                .where((t) => !t.date.isAfter(endDate))
                .toList();
          }

          return transactions;
        });
  }

  @override
  Future<void> createTransaction(Transaction transaction) async {
    final currentUid = _requireCurrentUserId();
    final cleanTransaction = transaction.copyWith(
      userId: currentUid,
      note: transaction.note?.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _validateTransaction(cleanTransaction, currentUid);

    await _firestoreService.setData(
      userId: currentUid,
      collection: _collectionPath,
      docId: cleanTransaction.id,
      data: cleanTransaction.toJson(),
    );
  }

  @override
  Future<void> updateTransaction(Transaction transaction) async {
    final currentUid = _requireCurrentUserId();
    final cleanTransaction = transaction.copyWith(
      userId: currentUid,
      note: transaction.note?.trim(),
      updatedAt: DateTime.now(),
    );

    await _validateTransaction(cleanTransaction, currentUid);

    await _firestoreService.setData(
      userId: currentUid,
      collection: _collectionPath,
      docId: cleanTransaction.id,
      data: cleanTransaction.toJson(),
      merge: true,
    );
  }

  @override
  Future<void> deleteTransaction({
    required String userId,
    required String transactionId,
  }) async {
    final currentUid = _requireCurrentUserId();
    await _firestoreService.deleteData(
      userId: currentUid,
      collection: _collectionPath,
      docId: transactionId,
    );
  }
}
