import 'package:personal_financial_assistant/features/planned_expenses/planned_expense.dart';
import 'package:personal_financial_assistant/features/planned_expenses/planned_expense_override.dart';

abstract class PlannedExpenseRepository {
  Future<List<PlannedExpense>> getPlannedExpenses(String userId);
  Stream<List<PlannedExpense>> watchPlannedExpenses(String userId);
  Future<void> createPlannedExpense(PlannedExpense plan);
  Future<void> updatePlannedExpense(PlannedExpense plan);
  Future<void> archivePlannedExpense({
    required String userId,
    required String planId,
  });
  Future<void> restorePlannedExpense({
    required String userId,
    required String planId,
  });

  Stream<List<PlannedExpenseOverride>> watchMonthlyOverrides({
    required String userId,
    required int year,
    required int month,
  });
  Future<void> setMonthlyOverride(PlannedExpenseOverride override);
  Future<void> removeMonthlyOverride({
    required String userId,
    required String overrideId,
  });
}
