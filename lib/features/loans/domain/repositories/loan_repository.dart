import 'package:personal_financial_assistant/features/loans/loan.dart';

abstract class LoanRepository {
  Future<List<Loan>> getLoans(String userId);
  Stream<List<Loan>> watchLoans(String userId);
  Future<void> createLoan(Loan loan);
  Future<void> updateLoan(Loan loan);
  Future<void> archiveLoan({
    required String userId,
    required String loanId,
  });
  Future<void> deleteLoan({
    required String userId,
    required String loanId,
  });
}

