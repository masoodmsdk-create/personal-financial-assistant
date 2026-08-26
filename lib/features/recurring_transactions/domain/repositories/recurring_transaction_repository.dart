import 'package:personal_financial_assistant/features/recurring_transactions/domain/models/recurring_transaction_rule.dart';

abstract class RecurringTransactionRepository {
  /// Streams all recurring transaction rules for [userId].
  Stream<List<RecurringTransactionRule>> getRecurringTransactions(
    String userId,
  );

  /// Fetches a single recurring transaction rule by [id].
  Future<RecurringTransactionRule?> getRecurringTransactionById(
    String userId,
    String id,
  );

  /// Creates a new recurring transaction rule in Firestore.
  Future<void> createRecurringTransaction(RecurringTransactionRule rule);

  /// Updates an existing recurring transaction rule.
  Future<void> updateRecurringTransaction(RecurringTransactionRule rule);

  /// Deletes a recurring transaction rule.
  Future<void> deleteRecurringTransaction(String userId, String id);

  /// Toggles active/paused status of a rule.
  Future<void> toggleRecurringTransactionStatus(
    String userId,
    String id,
    bool active,
  );
}
