import 'dart:math' as math;

import 'package:personal_financial_assistant/core/errors/app_exception.dart';

class FinancialCalculator {
  static double sumAmounts(Iterable<double> amounts) {
    return amounts.fold(0.0, (sum, amount) => sum + amount);
  }

  static double calculateIncome(Iterable<double> amounts) {
    return sumAmounts(amounts);
  }

  static double calculateExpense(Iterable<double> amounts) {
    return sumAmounts(amounts);
  }

  static double calculateSavings(double income, double expense) {
    return income - expense;
  }

  static double calculateSavingsRate(double income, double expense) {
    if (income <= 0) return 0.0;
    final savings = calculateSavings(income, expense);
    return (savings / income).clamp(-1.0, 1.0);
  }

  static double calculateNetWorth(double totalAssets, double totalLiabilities) {
    return totalAssets - totalLiabilities;
  }

  static double calculateEMI({
    required double principal,
    required double annualInterestRate,
    required int tenureMonths,
  }) {
    if (principal <= 0) {
      throw const CalculationException('Principal must be positive');
    }
    if (tenureMonths <= 0) {
      throw const CalculationException('Tenure must be positive');
    }
    if (annualInterestRate < 0) {
      throw const CalculationException('Interest rate cannot be negative');
    }

    if (annualInterestRate == 0) {
      return principal / tenureMonths;
    }

    final monthlyRate = annualInterestRate / 12 / 100;
    final factor = (1 + monthlyRate);
    final numerator = principal * monthlyRate * _pow(factor, tenureMonths);
    final denominator = _pow(factor, tenureMonths) - 1;
    return numerator / denominator;
  }

  static double _pow(double base, int exponent) {
    double result = 1.0;
    for (int i = 0; i < exponent; i++) {
      result *= base;
    }
    return result;
  }

  static LoanAmortizationSchedule calculateAmortization({
    required double principal,
    required double annualInterestRate,
    required int tenureMonths,
    required DateTime startDate,
  }) {
    final emi = calculateEMI(
      principal: principal,
      annualInterestRate: annualInterestRate,
      tenureMonths: tenureMonths,
    );

    final schedule = <AmortizationEntry>[];
    double remainingPrincipal = principal;
    final monthlyRate = annualInterestRate / 12 / 100;
    DateTime paymentDate = startDate;

    for (int month = 1; month <= tenureMonths; month++) {
      final interestComponent = remainingPrincipal * monthlyRate;
      final principalComponent = emi - interestComponent;
      remainingPrincipal -= principalComponent;

      if (remainingPrincipal < 0.01) {
        remainingPrincipal = 0;
      }

      schedule.add(
        AmortizationEntry(
          month: month,
          paymentDate: paymentDate,
          emi: emi,
          principalComponent: principalComponent,
          interestComponent: interestComponent,
          remainingPrincipal: remainingPrincipal.clamp(0, double.infinity),
        ),
      );

      paymentDate = DateTime(
        paymentDate.year,
        paymentDate.month + 1,
        paymentDate.day,
      );
    }

    return LoanAmortizationSchedule(
      principal: principal,
      annualInterestRate: annualInterestRate,
      tenureMonths: tenureMonths,
      emi: emi,
      schedule: schedule,
      totalInterest: schedule.fold(
        0.0,
        (sum, entry) => sum + entry.interestComponent,
      ),
      totalPayment: emi * tenureMonths,
    );
  }

  static PrepaymentResult calculatePrepayment({
    required double currentPrincipal,
    required double annualInterestRate,
    required int remainingMonths,
    required double prepaymentAmount,
    required double currentEMI,
  }) {
    if (prepaymentAmount <= 0) {
      throw const CalculationException('Prepayment amount must be positive');
    }
    if (prepaymentAmount > currentPrincipal) {
      throw const CalculationException(
        'Prepayment cannot exceed current principal',
      );
    }

    final newPrincipal = currentPrincipal - prepaymentAmount;

    if (newPrincipal <= 0) {
      return PrepaymentResult(
        currentPrincipal: currentPrincipal,
        prepaymentAmount: prepaymentAmount,
        newPrincipal: 0,
        interestSaved: _calculateTotalInterest(
          currentPrincipal,
          annualInterestRate,
          remainingMonths,
          currentEMI,
        ),
        tenureReductionMonths: remainingMonths,
        newTenureMonths: 0,
        newEMI: 0,
        currentEMI: currentEMI,
      );
    }

    final newTenureResult = _calculateNewTenure(
      newPrincipal: newPrincipal,
      annualInterestRate: annualInterestRate,
      currentEMI: currentEMI,
    );

    final originalTotalInterest = _calculateTotalInterest(
      currentPrincipal,
      annualInterestRate,
      remainingMonths,
      currentEMI,
    );
    final newTotalInterest = _calculateTotalInterest(
      newPrincipal,
      annualInterestRate,
      newTenureResult.newTenureMonths,
      currentEMI,
    );

    return PrepaymentResult(
      currentPrincipal: currentPrincipal,
      prepaymentAmount: prepaymentAmount,
      newPrincipal: newPrincipal,
      interestSaved: originalTotalInterest - newTotalInterest,
      tenureReductionMonths: remainingMonths - newTenureResult.newTenureMonths,
      newTenureMonths: newTenureResult.newTenureMonths,
      newEMI: currentEMI,
      currentEMI: currentEMI,
    );
  }

  static double _calculateTotalInterest(
    double principal,
    double annualInterestRate,
    int months,
    double emi,
  ) {
    return (emi * months) - principal;
  }

  static _NewTenureResult _calculateNewTenure({
    required double newPrincipal,
    required double annualInterestRate,
    required double currentEMI,
  }) {
    if (annualInterestRate == 0) {
      final months = (newPrincipal / currentEMI).ceil();
      return _NewTenureResult(newTenureMonths: months);
    }

    final monthlyRate = annualInterestRate / 12 / 100;
    final ratio = 1 - (newPrincipal * monthlyRate / currentEMI);

    if (ratio <= 0) {
      return _NewTenureResult(newTenureMonths: 1);
    }

    final months = math.log(ratio) / math.log(1 + monthlyRate);
    return _NewTenureResult(newTenureMonths: months.abs().ceil());
  }
}

class _NewTenureResult {
  final int newTenureMonths;
  _NewTenureResult({required this.newTenureMonths});
}

class LoanAmortizationSchedule {
  final double principal;
  final double annualInterestRate;
  final int tenureMonths;
  final double emi;
  final List<AmortizationEntry> schedule;
  final double totalInterest;
  final double totalPayment;

  LoanAmortizationSchedule({
    required this.principal,
    required this.annualInterestRate,
    required this.tenureMonths,
    required this.emi,
    required this.schedule,
    required this.totalInterest,
    required this.totalPayment,
  });

  AmortizationEntry? getEntryForMonth(int month) {
    if (month < 1 || month > schedule.length) return null;
    return schedule[month - 1];
  }

  double getRemainingPrincipalAtMonth(int month) {
    final entry = getEntryForMonth(month);
    return entry?.remainingPrincipal ?? principal;
  }
}

class AmortizationEntry {
  final int month;
  final DateTime paymentDate;
  final double emi;
  final double principalComponent;
  final double interestComponent;
  final double remainingPrincipal;

  AmortizationEntry({
    required this.month,
    required this.paymentDate,
    required this.emi,
    required this.principalComponent,
    required this.interestComponent,
    required this.remainingPrincipal,
  });
}

class PrepaymentResult {
  final double currentPrincipal;
  final double prepaymentAmount;
  final double newPrincipal;
  final double interestSaved;
  final int tenureReductionMonths;
  final int newTenureMonths;
  final double newEMI;
  final double currentEMI;

  PrepaymentResult({
    required this.currentPrincipal,
    required this.prepaymentAmount,
    required this.newPrincipal,
    required this.interestSaved,
    required this.tenureReductionMonths,
    required this.newTenureMonths,
    required this.newEMI,
    required this.currentEMI,
  });

  DateTime? getEstimatedCompletionDate(DateTime currentNextPaymentDate) {
    if (newTenureMonths <= 0) return null;
    return DateTime(
      currentNextPaymentDate.year,
      currentNextPaymentDate.month + newTenureMonths,
      currentNextPaymentDate.day,
    );
  }
}

class GoalCalculator {
  static double calculateProgress(double currentAmount, double targetAmount) {
    if (targetAmount <= 0) return 0.0;
    return (currentAmount / targetAmount).clamp(0.0, 1.0);
  }

  static double calculateRemainingAmount(
    double currentAmount,
    double targetAmount,
  ) {
    return (targetAmount - currentAmount).clamp(0.0, double.infinity);
  }

  static double calculateRequiredMonthlySaving({
    required double targetAmount,
    required double currentAmount,
    required int remainingMonths,
    double expectedReturnRate = 0,
  }) {
    final remaining = calculateRemainingAmount(currentAmount, targetAmount);
    if (remainingMonths <= 0) return remaining;
    if (expectedReturnRate == 0) {
      return remaining / remainingMonths;
    }
    final monthlyRate = expectedReturnRate / 12 / 100;
    return remaining *
        monthlyRate /
        ((1 + monthlyRate) * _pow(1 + monthlyRate, remainingMonths) - 1);
  }

  static DateTime? calculateProjectedCompletionDate({
    required double targetAmount,
    required double currentAmount,
    required double monthlySaving,
    double expectedReturnRate = 0,
    DateTime? startDate,
  }) {
    if (monthlySaving <= 0) return null;
    final remaining = calculateRemainingAmount(currentAmount, targetAmount);
    if (remaining <= 0) return startDate ?? DateTime.now();

    final start = startDate ?? DateTime.now();
    if (expectedReturnRate == 0) {
      final months = (remaining / monthlySaving).ceil();
      return DateTime(start.year, start.month + months, start.day);
    }

    final monthlyRate = expectedReturnRate / 12 / 100;
    final ratio = 1 + (remaining * monthlyRate / monthlySaving);
    if (ratio <= 1) return null;
    final months = (math.log(ratio) / math.log(1 + monthlyRate)).ceil();
    return DateTime(start.year, start.month + months, start.day);
  }

  static bool isOnTrack({
    required double targetAmount,
    required double currentAmount,
    required DateTime targetDate,
    required double monthlySaving,
    double expectedReturnRate = 0,
  }) {
    final projectedDate = calculateProjectedCompletionDate(
      targetAmount: targetAmount,
      currentAmount: currentAmount,
      monthlySaving: monthlySaving,
      expectedReturnRate: expectedReturnRate,
    );
    if (projectedDate == null) return false;
    return projectedDate.isBefore(targetDate) ||
        projectedDate.isAtSameMomentAs(targetDate);
  }

  static double _pow(double base, int exponent) {
    double result = 1.0;
    for (int i = 0; i < exponent; i++) {
      result *= base;
    }
    return result;
  }
}

class BudgetCalculator {
  static double calculateSpent(double budgetAmount, double actualSpent) {
    return actualSpent;
  }

  static double calculateRemaining(double budgetAmount, double actualSpent) {
    return (budgetAmount - actualSpent).clamp(
      -double.infinity,
      double.infinity,
    );
  }

  static double calculatePercentageUsed(
    double budgetAmount,
    double actualSpent,
  ) {
    if (budgetAmount <= 0) return 0.0;
    return (actualSpent / budgetAmount).clamp(0.0, double.infinity);
  }

  static BudgetStatus getStatus(double budgetAmount, double actualSpent) {
    final percentage = calculatePercentageUsed(budgetAmount, actualSpent);
    if (percentage >= 1.0) return BudgetStatus.exceeded;
    if (percentage >= 0.8) return BudgetStatus.warning;
    return BudgetStatus.onTrack;
  }
}

enum BudgetStatus { onTrack, warning, exceeded }
