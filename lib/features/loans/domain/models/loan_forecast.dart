import 'package:personal_financial_assistant/features/loans/loan.dart';

class AmortizationScheduleRow {
  final int monthNumber;
  final DateTime date;
  final double payment;
  final double principalComponent;
  final double interestComponent;
  final double remainingBalance;

  const AmortizationScheduleRow({
    required this.monthNumber,
    required this.date,
    required this.payment,
    required this.principalComponent,
    required this.interestComponent,
    required this.remainingBalance,
  });
}

class LoanMissingFieldInfo {
  final String fieldKey;
  final String title;
  final String reason;
  final String suggestedAction;

  const LoanMissingFieldInfo({
    required this.fieldKey,
    required this.title,
    required this.reason,
    required this.suggestedAction,
  });
}

class LoanForecastResult {
  final Loan loan;
  final DateTime calculatedAt;
  final int? estimatedRemainingTenureMonths;
  final DateTime? estimatedClosureDate;
  final double? estimatedRemainingInterest;
  final double? outstandingPrincipal;
  final double? totalRemainingRepayment;
  final double? effectiveEmi;
  final List<AmortizationScheduleRow> schedule;
  final List<LoanMissingFieldInfo> missingFields;
  final String note;

  const LoanForecastResult({
    required this.loan,
    required this.calculatedAt,
    this.estimatedRemainingTenureMonths,
    this.estimatedClosureDate,
    this.estimatedRemainingInterest,
    this.outstandingPrincipal,
    this.totalRemainingRepayment,
    this.effectiveEmi,
    this.schedule = const [],
    this.missingFields = const [],
    this.note = 'Forecast based on the information currently provided.',
  });

  bool get isComplete => missingFields.isEmpty;
  bool get hasTenure => estimatedRemainingTenureMonths != null;
  bool get hasInterest => estimatedRemainingInterest != null;
}
