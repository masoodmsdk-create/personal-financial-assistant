import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_financial_assistant/features/analytics/presentation/providers/analytics_providers.dart';
import 'package:personal_financial_assistant/features/auth/presentation/providers/auth_providers.dart';
import 'package:personal_financial_assistant/features/goals/presentation/providers/goal_providers.dart';
import 'package:personal_financial_assistant/features/loans/data/repositories/firestore_loan_repository.dart';
import 'package:personal_financial_assistant/features/loans/domain/models/debt_intelligence.dart';
import 'package:personal_financial_assistant/features/loans/domain/models/loan_forecast.dart';
import 'package:personal_financial_assistant/features/loans/domain/models/what_if_scenario.dart';
import 'package:personal_financial_assistant/features/loans/domain/repositories/loan_repository.dart';
import 'package:personal_financial_assistant/features/loans/domain/services/debt_intelligence_service.dart';
import 'package:personal_financial_assistant/features/loans/domain/services/loan_forecast_service.dart';
import 'package:personal_financial_assistant/features/loans/loan.dart';

final loanRepositoryProvider = Provider<LoanRepository>((ref) {
  return FirestoreLoanRepository();
});

final loansStreamProvider = StreamProvider<List<Loan>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return Stream.value(const []);
  }
  final repository = ref.watch(loanRepositoryProvider);
  return repository.watchLoans(user.uid);
});

final selectedLoanIdProvider = StateProvider<String?>((ref) => null);

final selectedLoanProvider = Provider<Loan?>((ref) {
  final loansAsync = ref.watch(loansStreamProvider);
  final loans = loansAsync.value ?? [];
  if (loans.isEmpty) return null;

  final selectedId = ref.watch(selectedLoanIdProvider);
  if (selectedId != null) {
    final match = loans.where((l) => l.id == selectedId).firstOrNull;
    if (match != null) return match;
  }
  return loans.first;
});

final loanForecastProvider = Provider<LoanForecastResult?>((ref) {
  final loan = ref.watch(selectedLoanProvider);
  if (loan == null) return null;
  return LoanForecastService.calculateForecast(loan);
});

final loanForecastByIdProvider = Provider.family<LoanForecastResult?, String>((
  ref,
  loanId,
) {
  final loansAsync = ref.watch(loansStreamProvider);
  final loans = loansAsync.value ?? [];
  final loan = loans.where((l) => l.id == loanId).firstOrNull;
  if (loan == null) return null;
  return LoanForecastService.calculateForecast(loan);
});

final loanInterestAnalysisProvider =
    Provider.family<LoanInterestAnalysis?, String>((ref, loanId) {
      final loansAsync = ref.watch(loansStreamProvider);
      final loans = loansAsync.value ?? [];
      final loan = loans.where((l) => l.id == loanId).firstOrNull;
      if (loan == null) return null;
      final forecast = LoanForecastService.calculateForecast(loan);
      return DebtIntelligenceService.analyzeLoanInterest(loan, forecast);
    });

/// Portfolio summary aggregating all user debts & calculating metrics
final debtPortfolioSummaryProvider = Provider<DebtPortfolioSummary>((ref) {
  final loansAsync = ref.watch(loansStreamProvider);
  final loans = loansAsync.value ?? [];
  final monthlySummary = ref.watch(periodSummaryProvider);

  return DebtIntelligenceService.analyzePortfolio(
    loans: loans,
    recordedMonthlyIncome: monthlySummary.totalIncome > 0
        ? monthlySummary.totalIncome
        : null,
  );
});

final selectedDebtStrategyProvider = StateProvider<DebtStrategyType>(
  (ref) => DebtStrategyType.avalanche,
);

/// Debt Prioritization plan (Avalanche vs Snowball vs Cash Flow Relief)
final debtPrioritizationProvider = Provider<DebtPrioritizationPlan>((ref) {
  final loansAsync = ref.watch(loansStreamProvider);
  final loans = loansAsync.value ?? [];
  final strategy = ref.watch(selectedDebtStrategyProvider);

  return DebtIntelligenceService.calculatePrioritization(
    loans: loans,
    strategy: strategy,
  );
});

/// High-value deterministic loan insights
final loanInsightsProvider = Provider<List<LoanInsight>>((ref) {
  final loansAsync = ref.watch(loansStreamProvider);
  final loans = loansAsync.value ?? [];
  final monthlySummary = ref.watch(periodSummaryProvider);
  final goalsAsync = ref.watch(goalsStreamProvider);
  final goals = goalsAsync.value;

  return DebtIntelligenceService.generateLoanInsights(
    loans: loans,
    recordedMonthlyIncome: monthlySummary.totalIncome > 0
        ? monthlySummary.totalIncome
        : null,
    goals: goals,
  );
});

final activeWhatIfTypeProvider = StateProvider<WhatIfType>(
  (ref) => WhatIfType.extraMonthly,
);

final activeWhatIfParamsProvider = StateProvider<WhatIfScenarioParams>(
  (ref) => const WhatIfScenarioParams(extraMonthlyAmount: 5000.0),
);

final whatIfScenarioResultProvider = Provider<WhatIfScenarioResult?>((ref) {
  final loan = ref.watch(selectedLoanProvider);
  if (loan == null) return null;

  final scenarioType = ref.watch(activeWhatIfTypeProvider);
  final params = ref.watch(activeWhatIfParamsProvider);

  return LoanForecastService.calculateWhatIfScenario(
    loan: loan,
    params: params,
    scenarioType: scenarioType,
  );
});

class LoanController extends StateNotifier<AsyncValue<void>> {
  final LoanRepository _repository;
  final Ref _ref;

  LoanController(this._repository, this._ref) : super(const AsyncData(null));

  String? _getCurrentUserId() {
    return _ref.read(currentUserProvider)?.uid;
  }

  Future<bool> createLoan({
    required String name,
    required LoanType type,
    double? originalPrincipal,
    double? outstandingPrincipal,
    double? interestRate,
    InterestRateType interestRateType = InterestRateType.fixed,
    double? emiAmount,
    int? remainingTenureMonths,
    DateTime? startDate,
    DateTime? nextEmiDate,
    DateTime? targetClosureDate,
    String? linkedAccountId,
    String? lenderName,
    double? processingFee,
    double? prepaymentCharges,
    String? notes,
  }) async {
    final userId = _getCurrentUserId();
    if (userId == null) {
      state = AsyncError('User not authenticated', StackTrace.current);
      return false;
    }

    state = const AsyncLoading();
    final now = DateTime.now();
    final loan = Loan(
      id: 'loan_${now.microsecondsSinceEpoch}',
      userId: userId,
      name: name,
      type: type,
      originalPrincipal: originalPrincipal,
      outstandingPrincipal: outstandingPrincipal,
      interestRate: interestRate,
      interestRateType: interestRateType,
      emiAmount: emiAmount,
      remainingTenureMonths: remainingTenureMonths,
      startDate: startDate,
      nextEmiDate: nextEmiDate,
      targetClosureDate: targetClosureDate,
      linkedAccountId: linkedAccountId,
      lenderName: lenderName,
      processingFee: processingFee,
      prepaymentCharges: prepaymentCharges,
      notes: notes,
      active: true,
      createdAt: now,
      updatedAt: now,
    );

    state = await AsyncValue.guard(() => _repository.createLoan(loan));
    if (!state.hasError) {
      _ref.read(selectedLoanIdProvider.notifier).state = loan.id;
    }
    return !state.hasError;
  }

  Future<bool> updateLoan(Loan loan) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.updateLoan(loan));
    return !state.hasError;
  }

  Future<bool> archiveLoan(String loanId) async {
    final userId = _getCurrentUserId();
    if (userId == null) return false;

    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repository.archiveLoan(userId: userId, loanId: loanId),
    );
    return !state.hasError;
  }

  Future<bool> deleteLoan(String loanId) async {
    final userId = _getCurrentUserId();
    if (userId == null) return false;

    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repository.deleteLoan(userId: userId, loanId: loanId),
    );
    return !state.hasError;
  }
}

final loanControllerProvider =
    StateNotifierProvider<LoanController, AsyncValue<void>>((ref) {
      return LoanController(ref.watch(loanRepositoryProvider), ref);
    });
