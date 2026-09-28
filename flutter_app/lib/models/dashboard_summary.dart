import 'account.dart';
import 'transaction.dart';

class CardPaymentInfo {
  final Account account;
  final String startStr;
  final String endStr;
  final String paymentDateStr; 
  final int amount;
  final bool isFinalized;
  final List<Transaction> recurringTxs;

  CardPaymentInfo({
    required this.account, required this.startStr, required this.endStr, 
    required this.paymentDateStr, required this.amount, required this.isFinalized,
    this.recurringTxs = const [],
  });
}

class FixedItemInfo {
  final Transaction tx;
  final String dateStr;
  FixedItemInfo(this.tx, this.dateStr);
}

class DashboardSummary {
  final int alreadyReceivedIncome;
  final List<Transaction> alreadyReceivedIncomeList;
  final List<FixedItemInfo> upcomingIncomeList;
  final int alreadyPaidCashDebit;
  final List<Transaction> alreadyPaidCashDebitList;
  final int alreadyPaidFixed;
  final List<Transaction> alreadyPaidFixedList;
  final int alreadyPaidCard;
  final List<CardPaymentInfo> alreadyPaidCardList;
  final List<FixedItemInfo> upcomingExpenseList;
  final List<CardPaymentInfo> upcomingCardPayments;
  final List<CardPaymentInfo> ongoingCardAccumulations;

  DashboardSummary({
    required this.alreadyReceivedIncome, required this.alreadyReceivedIncomeList, required this.upcomingIncomeList,
    required this.alreadyPaidCashDebit, required this.alreadyPaidCashDebitList, required this.alreadyPaidFixed, required this.alreadyPaidFixedList,
    required this.alreadyPaidCard, required this.alreadyPaidCardList, required this.upcomingExpenseList, required this.upcomingCardPayments,
    required this.ongoingCardAccumulations,
  });

  int get totalAlreadyReceived => alreadyReceivedIncome;
  int get totalUpcomingIncome => upcomingIncomeList.fold(0, (s, e) => s + e.tx.amount);
  
  int get totalAlreadyPaid => alreadyPaidCashDebit + alreadyPaidFixed + alreadyPaidCard;
  int get totalUpcomingFixedExpense => upcomingExpenseList.fold(0, (s, e) => s + e.tx.amount);
  int get totalUpcomingCard => upcomingCardPayments.fold(0, (s, e) => s + e.amount);
  int get totalOngoingCard => ongoingCardAccumulations.fold(0, (s, e) => s + e.amount);
  int get totalUpcomingExpense => totalUpcomingFixedExpense + totalUpcomingCard;
  
  int get remaining => (totalAlreadyReceived + totalUpcomingIncome) - (totalAlreadyPaid + totalUpcomingExpense);
}
