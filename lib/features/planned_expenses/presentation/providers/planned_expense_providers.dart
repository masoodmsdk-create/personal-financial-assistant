import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_financial_assistant/features/auth/presentation/providers/auth_providers.dart';
import 'package:personal_financial_assistant/features/categories/presentation/providers/category_providers.dart';
import 'package:personal_financial_assistant/features/planned_expenses/data/repositories/firestore_planned_expense_repository.dart';
import 'package:personal_financial_assistant/features/planned_expenses/domain/repositories/planned_expense_repository.dart';
import 'package:personal_financial_assistant/features/planned_expenses/planned_expense.dart';
import 'package:personal_financial_assistant/features/planned_expenses/planned_expense_override.dart';

final plannedExpenseRepositoryProvider = Provider<PlannedExpenseRepository>((
  ref,
) {
  return FirestorePlannedExpenseRepository(
    categoryRepository: ref.watch(categoryRepositoryProvider),
  );
});

final plannedExpensesStreamProvider = StreamProvider<List<PlannedExpense>>((
  ref,
) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return Stream.value(const []);
  }
  final repository = ref.watch(plannedExpenseRepositoryProvider);
  return repository.watchPlannedExpenses(user.uid);
});

final selectedForecastDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

final monthlyOverridesStreamProvider =
    StreamProvider<List<PlannedExpenseOverride>>((ref) {
      final user = ref.watch(currentUserProvider);
      if (user == null) {
        return Stream.value(const []);
      }
      final targetDate = ref.watch(selectedForecastDateProvider);
      final repository = ref.watch(plannedExpenseRepositoryProvider);
      return repository.watchMonthlyOverrides(
        userId: user.uid,
        year: targetDate.year,
        month: targetDate.month,
      );
    });

class MonthlyForecastItem {
  final PlannedExpense plan;
  final PlannedExpenseOverride? override;
  final double effectiveAmount;
  final bool hasOverride;

  const MonthlyForecastItem({
    required this.plan,
    this.override,
    required this.effectiveAmount,
    required this.hasOverride,
  });
}

class MonthlyForecastData {
  final int year;
  final int month;
  final List<MonthlyForecastItem> items;
  final double totalPlannedAmount;

  const MonthlyForecastData({
    required this.year,
    required this.month,
    required this.items,
    required this.totalPlannedAmount,
  });
}

final monthlyForecastProvider = Provider<AsyncValue<MonthlyForecastData>>((
  ref,
) {
  final targetDate = ref.watch(selectedForecastDateProvider);
  final plansAsync = ref.watch(plannedExpensesStreamProvider);
  final overridesAsync = ref.watch(monthlyOverridesStreamProvider);

  if (plansAsync.isLoading || overridesAsync.isLoading) {
    return const AsyncLoading();
  }

  if (plansAsync.hasError) {
    return AsyncError(plansAsync.error!, plansAsync.stackTrace!);
  }

  if (overridesAsync.hasError) {
    return AsyncError(overridesAsync.error!, overridesAsync.stackTrace!);
  }

  final plans = plansAsync.value ?? [];
  final overrides = overridesAsync.value ?? [];

  final overridesByPlanId = <String, PlannedExpenseOverride>{};
  for (final o in overrides) {
    overridesByPlanId[o.planId] = o;
  }

  final items = <MonthlyForecastItem>[];
  double total = 0.0;

  for (final plan in plans) {
    if (plan.appliesToMonth(targetDate.year, targetDate.month)) {
      final override = overridesByPlanId[plan.id];
      final effective = override?.amount ?? plan.defaultAmount;
      items.add(
        MonthlyForecastItem(
          plan: plan,
          override: override,
          effectiveAmount: effective,
          hasOverride: override != null,
        ),
      );
      total += effective;
    }
  }

  return AsyncData(
    MonthlyForecastData(
      year: targetDate.year,
      month: targetDate.month,
      items: items,
      totalPlannedAmount: total,
    ),
  );
});

class PlannedExpenseController extends StateNotifier<AsyncValue<void>> {
  final PlannedExpenseRepository _repository;
  final Ref _ref;

  PlannedExpenseController(this._repository, this._ref)
    : super(const AsyncData(null));

  String? _getCurrentUserId() {
    return _ref.read(currentUserProvider)?.uid;
  }

  Future<bool> createPlannedExpense({
    required String name,
    required String categoryId,
    required double defaultAmount,
    required RecurrenceFrequency frequency,
    required DateTime startDate,
    DateTime? endDate,
    String? accountId,
  }) async {
    final userId = _getCurrentUserId();
    if (userId == null) {
      state = AsyncError('User not authenticated', StackTrace.current);
      return false;
    }

    state = const AsyncLoading();
    final now = DateTime.now();
    final plan = PlannedExpense(
      id: 'plan_${now.microsecondsSinceEpoch}',
      userId: userId,
      name: name,
      categoryId: categoryId,
      defaultAmount: defaultAmount,
      frequency: frequency,
      startDate: startDate,
      endDate: endDate,
      active: true,
      accountId: accountId,
      createdAt: now,
      updatedAt: now,
    );

    state = await AsyncValue.guard(
      () => _repository.createPlannedExpense(plan),
    );
    return !state.hasError;
  }

  Future<bool> updatePlannedExpense(PlannedExpense plan) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repository.updatePlannedExpense(plan),
    );
    return !state.hasError;
  }

  Future<bool> archivePlannedExpense(String planId) async {
    final userId = _getCurrentUserId();
    if (userId == null) {
      state = AsyncError('User not authenticated', StackTrace.current);
      return false;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repository.archivePlannedExpense(userId: userId, planId: planId),
    );
    return !state.hasError;
  }

  Future<bool> restorePlannedExpense(String planId) async {
    final userId = _getCurrentUserId();
    if (userId == null) {
      state = AsyncError('User not authenticated', StackTrace.current);
      return false;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repository.restorePlannedExpense(userId: userId, planId: planId),
    );
    return !state.hasError;
  }

  Future<bool> setMonthlyOverride({
    required String planId,
    required int year,
    required int month,
    required double amount,
  }) async {
    final userId = _getCurrentUserId();
    if (userId == null) {
      state = AsyncError('User not authenticated', StackTrace.current);
      return false;
    }

    state = const AsyncLoading();
    final now = DateTime.now();
    final override = PlannedExpenseOverride(
      id: PlannedExpenseOverride.generateId(planId, year, month),
      userId: userId,
      planId: planId,
      year: year,
      month: month,
      amount: amount,
      createdAt: now,
      updatedAt: now,
    );

    state = await AsyncValue.guard(
      () => _repository.setMonthlyOverride(override),
    );
    return !state.hasError;
  }

  Future<bool> removeMonthlyOverride({
    required String planId,
    required int year,
    required int month,
  }) async {
    final userId = _getCurrentUserId();
    if (userId == null) {
      state = AsyncError('User not authenticated', StackTrace.current);
      return false;
    }

    state = const AsyncLoading();
    final overrideId = PlannedExpenseOverride.generateId(planId, year, month);
    state = await AsyncValue.guard(
      () => _repository.removeMonthlyOverride(
        userId: userId,
        overrideId: overrideId,
      ),
    );
    return !state.hasError;
  }
}

final plannedExpenseControllerProvider =
    StateNotifierProvider<PlannedExpenseController, AsyncValue<void>>((ref) {
      return PlannedExpenseController(
        ref.watch(plannedExpenseRepositoryProvider),
        ref,
      );
    });
