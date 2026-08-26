import 'package:firebase_auth/firebase_auth.dart';
import 'package:personal_financial_assistant/core/errors/app_exception.dart';
import 'package:personal_financial_assistant/core/services/firestore_service.dart';
import 'package:personal_financial_assistant/features/budgets/domain/models/budget.dart';
import 'package:personal_financial_assistant/features/budgets/domain/repositories/budget_repository.dart';

class FirestoreBudgetRepository implements BudgetRepository {
  final FirestoreService _firestoreService;
  final FirebaseAuth _firebaseAuth;

  static const String _budgetsCollection = 'budgets';

  FirestoreBudgetRepository({
    FirestoreService? firestoreService,
    FirebaseAuth? firebaseAuth,
  }) : _firestoreService = firestoreService ?? FirestoreService(),
       _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  String _requireCurrentUserId() {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw const AuthException('User is not authenticated');
    }
    return uid;
  }

  void _validateBudget(Budget budget) {
    if (budget.categoryId.trim().isEmpty) {
      throw const ValidationException('Category is required');
    }
    if (budget.plannedAmount < 0) {
      throw const ValidationException('Budget amount cannot be negative');
    }
    if (budget.month < 1 || budget.month > 12) {
      throw const ValidationException('Month must be between 1 and 12');
    }
    if (budget.year < 2000 || budget.year > 2100) {
      throw const ValidationException('Invalid year');
    }
  }

  @override
  Future<void> createBudget(Budget budget) async {
    final userId = _requireCurrentUserId();
    if (budget.userId.isNotEmpty && budget.userId != userId) {
      throw const AuthException('Cannot create budget for another user');
    }

    _validateBudget(budget);

    final payload = budget.copyWith(
      userId: userId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _firestoreService.setData(
      userId: userId,
      collection: _budgetsCollection,
      docId: payload.id,
      data: payload.toMap(),
    );
  }

  @override
  Future<void> updateBudget(Budget budget) async {
    final userId = _requireCurrentUserId();
    if (budget.userId.isNotEmpty && budget.userId != userId) {
      throw const AuthException('Cannot update budget for another user');
    }

    _validateBudget(budget);

    final payload = budget.copyWith(userId: userId, updatedAt: DateTime.now());

    await _firestoreService.setData(
      userId: userId,
      collection: _budgetsCollection,
      docId: payload.id,
      data: payload.toMap(),
      merge: true,
    );
  }

  @override
  Future<void> deleteBudget(String userId, String budgetId) async {
    final authUserId = _requireCurrentUserId();
    if (userId != authUserId) {
      throw const AuthException('Cannot delete budget for another user');
    }

    await _firestoreService.deleteData(
      userId: authUserId,
      collection: _budgetsCollection,
      docId: budgetId,
    );
  }

  @override
  Stream<List<Budget>> watchBudgets(String userId, {int? year, int? month}) {
    return _firestoreService
        .watchCollection(userId: userId, collection: _budgetsCollection)
        .map((docs) {
          return docs
              .map((data) => Budget.fromMap(data, data['id'] as String))
              .where((b) {
                if (!b.active) return false;
                if (year != null && b.year != year) return false;
                if (month != null && b.month != month) return false;
                return true;
              })
              .toList();
        });
  }

  @override
  Future<List<Budget>> getBudgets(
    String userId, {
    int? year,
    int? month,
  }) async {
    final docs = await _firestoreService.queryCollection(
      userId: userId,
      collection: _budgetsCollection,
    );

    final budgets = docs
        .map((data) => Budget.fromMap(data, data['id'] as String))
        .where((b) {
          if (!b.active) return false;
          if (year != null && b.year != year) return false;
          if (month != null && b.month != month) return false;
          return true;
        })
        .toList();

    return budgets;
  }
}
