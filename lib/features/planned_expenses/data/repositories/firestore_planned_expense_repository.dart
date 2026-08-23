import 'package:firebase_auth/firebase_auth.dart';
import 'package:personal_financial_assistant/core/errors/app_exception.dart';
import 'package:personal_financial_assistant/core/services/firestore_service.dart';
import 'package:personal_financial_assistant/features/categories/domain/repositories/category_repository.dart';
import 'package:personal_financial_assistant/features/planned_expenses/domain/repositories/planned_expense_repository.dart';
import 'package:personal_financial_assistant/features/planned_expenses/planned_expense.dart';
import 'package:personal_financial_assistant/features/planned_expenses/planned_expense_override.dart';

class FirestorePlannedExpenseRepository implements PlannedExpenseRepository {
  final FirestoreService _firestoreService;
  final FirebaseAuth _firebaseAuth;

  static const String _plansCollection = 'planned_expenses';
  static const String _overridesCollection = 'planned_expense_overrides';
  static const int maxPlanNameLength = 50;

  FirestorePlannedExpenseRepository({
    FirestoreService? firestoreService,
    FirebaseAuth? firebaseAuth,
    CategoryRepository? categoryRepository,
  }) : _firestoreService = firestoreService ?? FirestoreService(),
       _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;


  String _requireCurrentUserId() {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw const AuthException('User is not authenticated');
    }
    return uid;
  }

  Future<void> _validatePlan(PlannedExpense plan, String currentUid) async {
    final name = plan.name.trim();
    if (name.isEmpty) {
      throw const ValidationException('Expense name is required');
    }
    if (name.length > maxPlanNameLength) {
      throw ValidationException(
        'Expense name cannot exceed $maxPlanNameLength characters',
      );
    }
    if (plan.defaultAmount <= 0) {
      throw const ValidationException(
        'Planned amount must be greater than zero',
      );
    }

    final endDate = plan.endDate;
    if (endDate != null && endDate.isBefore(plan.startDate)) {
      throw const ValidationException('End date cannot be before start date');
    }
  }

  @override
  Future<List<PlannedExpense>> getPlannedExpenses(String userId) async {
    final currentUid = _requireCurrentUserId();
    final dataList = await _firestoreService.queryCollection(
      userId: currentUid,
      collection: _plansCollection,
      params: const QueryParams(orderBy: 'createdAt', descending: true),
    );
    return dataList.map((data) => PlannedExpense.fromJson(data)).toList();
  }

  @override
  Stream<List<PlannedExpense>> watchPlannedExpenses(String userId) {
    final currentUid = _requireCurrentUserId();
    return _firestoreService
        .watchCollection(
          userId: currentUid,
          collection: _plansCollection,
          params: const QueryParams(orderBy: 'createdAt', descending: true),
        )
        .map(
          (dataList) =>
              dataList.map((data) => PlannedExpense.fromJson(data)).toList(),
        );
  }

  @override
  Future<void> createPlannedExpense(PlannedExpense plan) async {
    final currentUid = _requireCurrentUserId();
    final cleanPlan = plan.copyWith(
      userId: currentUid,
      name: plan.name.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _validatePlan(cleanPlan, currentUid);

    await _firestoreService.setData(
      userId: currentUid,
      collection: _plansCollection,
      docId: cleanPlan.id,
      data: cleanPlan.toJson(),
    );
  }

  @override
  Future<void> updatePlannedExpense(PlannedExpense plan) async {
    final currentUid = _requireCurrentUserId();
    final cleanPlan = plan.copyWith(
      userId: currentUid,
      name: plan.name.trim(),
      updatedAt: DateTime.now(),
    );

    await _validatePlan(cleanPlan, currentUid);

    await _firestoreService.setData(
      userId: currentUid,
      collection: _plansCollection,
      docId: cleanPlan.id,
      data: cleanPlan.toJson(),
      merge: true,
    );
  }

  @override
  Future<void> archivePlannedExpense({
    required String userId,
    required String planId,
  }) async {
    final currentUid = _requireCurrentUserId();
    final existing = await getPlannedExpenses(currentUid);
    final target = existing.firstWhere(
      (p) => p.id == planId,
      orElse: () =>
          throw const ValidationException('Planned expense not found'),
    );

    final updated = target.copyWith(active: false, updatedAt: DateTime.now());

    await _firestoreService.setData(
      userId: currentUid,
      collection: _plansCollection,
      docId: planId,
      data: updated.toJson(),
      merge: true,
    );
  }

  @override
  Future<void> restorePlannedExpense({
    required String userId,
    required String planId,
  }) async {
    final currentUid = _requireCurrentUserId();
    final existing = await getPlannedExpenses(currentUid);
    final target = existing.firstWhere(
      (p) => p.id == planId,
      orElse: () =>
          throw const ValidationException('Planned expense not found'),
    );

    final updated = target.copyWith(active: true, updatedAt: DateTime.now());

    await _firestoreService.setData(
      userId: currentUid,
      collection: _plansCollection,
      docId: planId,
      data: updated.toJson(),
      merge: true,
    );
  }

  @override
  Stream<List<PlannedExpenseOverride>> watchMonthlyOverrides({
    required String userId,
    required int year,
    required int month,
  }) {
    final currentUid = _requireCurrentUserId();
    return _firestoreService
        .watchCollection(
          userId: currentUid,
          collection: _overridesCollection,
          params: QueryParams(filters: {'year': year, 'month': month}),
        )
        .map(
          (dataList) => dataList
              .map((data) => PlannedExpenseOverride.fromJson(data))
              .toList(),
        );
  }

  @override
  Future<void> setMonthlyOverride(PlannedExpenseOverride override) async {
    final currentUid = _requireCurrentUserId();
    if (override.amount < 0) {
      throw const ValidationException('Override amount cannot be negative');
    }

    final cleanOverride = override.copyWith(
      userId: currentUid,
      updatedAt: DateTime.now(),
    );

    await _firestoreService.setData(
      userId: currentUid,
      collection: _overridesCollection,
      docId: cleanOverride.id,
      data: cleanOverride.toJson(),
      merge: true,
    );
  }

  @override
  Future<void> removeMonthlyOverride({
    required String userId,
    required String overrideId,
  }) async {
    final currentUid = _requireCurrentUserId();
    await _firestoreService.deleteData(
      userId: currentUid,
      collection: _overridesCollection,
      docId: overrideId,
    );
  }
}
