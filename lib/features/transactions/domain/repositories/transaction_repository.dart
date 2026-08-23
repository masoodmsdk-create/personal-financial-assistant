import 'package:personal_financial_assistant/features/transactions/transaction.dart';

abstract class TransactionRepository {
  Future<List<Transaction>> getTransactions(
    String userId, {
    TransactionType? type,
    String? accountId,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
  });

  Stream<List<Transaction>> watchTransactions(
    String userId, {
    TransactionType? type,
    String? accountId,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<void> createTransaction(Transaction transaction);
  Future<void> updateTransaction(Transaction transaction);
  Future<void> deleteTransaction({
    required String userId,
    required String transactionId,
  });
}
