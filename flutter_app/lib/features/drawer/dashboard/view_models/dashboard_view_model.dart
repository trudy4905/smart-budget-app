import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:flutter_app/features/drawer/accounts/models/account.dart';
import 'package:flutter_app/features/home/add_transaction/models/transaction.dart';
import 'package:flutter_app/features/drawer/dashboard/models/dashboard_summary.dart';
import 'package:flutter_app/features/drawer/accounts/view_models/account_view_model.dart';
import 'package:flutter_app/features/home/add_transaction/view_models/transaction_view_model.dart';
import 'package:flutter_app/core/providers/ui_view_model.dart';

class DashboardViewModel extends ChangeNotifier {
  final AccountViewModel accountVM;
  final TransactionViewModel transactionVM;
  final UiViewModel uiVM;

  DashboardViewModel(this.accountVM, this.transactionVM, this.uiVM) {
    accountVM.addListener(_onChanged);
    transactionVM.addListener(_onChanged);
    uiVM.addListener(_onChanged);
  }

  @override
  void dispose() {
    accountVM.removeListener(_onChanged);
    transactionVM.removeListener(_onChanged);
    uiVM.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    notifyListeners();
  }

  List<Account> get accounts => accountVM.accounts;
  List<Transaction> get transactions => transactionVM.transactions;
  List<String> get selectedAccountIds => uiVM.selectedAccountIds;
  DateTime get assetReferenceDate => uiVM.assetReferenceDate;
  String get drawerFilter => uiVM.drawerFilter;

  DateTime _clampDate(int year, int month, int day) {
    int y = year;
    int m = month;
    while (m < 1) { m += 12; y--; }
    while (m > 12) { m -= 12; y++; }
    final lastDay = DateTime(y, m + 1, 0).day;
    final d = day > lastDay ? lastDay : day;
    return DateTime(y, m, d);
  }

  bool isTransactionMatchingSelection(Transaction t, {bool ignoreDrawerFilter = false}) {
    if (!selectedAccountIds.contains('all') && !selectedAccountIds.contains(t.accountId)) {
      return false;
    }
    if (!ignoreDrawerFilter && drawerFilter != 'all') {
      if (drawerFilter == 'income' && t.type != 'income') return false;
      if (drawerFilter == 'expense' && t.type != 'expense') return false;
    }
    return true;
  }

  List<Transaction> _getVirtualSettlements(int year, int month) {
    List<Transaction> virtualTxs = [];
    final endOfMonth = DateTime(year, month + 1, 0);

    for (final acc in accounts.where((a) => a.isCredit)) {
      final paymentDate = _clampDate(year, month, acc.paymentDay ?? 25);
      if (paymentDate.month == month && paymentDate.year == year) {
        final start = _clampDate(year, month + (acc.billingStartMonth ?? -1), acc.billingStartDay ?? 1);
        final end = _clampDate(year, month + (acc.billingEndMonth ?? -1), acc.billingEndDay ?? 31);
        final endActual = endOfMonth.isBefore(end) ? endOfMonth : end;
        
        int sum = _sumCardTransactions(acc.id, start, endActual);
        if (sum > 0) {
          virtualTxs.add(Transaction(
            id: 'virtual_${acc.id}_${year}_$month',
            date: '${paymentDate.year}-${paymentDate.month.toString().padLeft(2,'0')}-${paymentDate.day.toString().padLeft(2,'0')}',
            accountId: acc.linkedBankAccountId ?? acc.id,
            type: 'expense',
            amount: sum,
            category: '${acc.name} 대금',
            memo: '카드대금 자동계산',
            isRecurring: false,
          ));
        }
      }
    }
    return virtualTxs;
  }

  List<Transaction> getTransactionsForDate(String dateStr) {
    final parts = dateStr.split('-');
    if (parts.length < 3) return [];
    int year = int.tryParse(parts[0]) ?? 0;
    int month = int.tryParse(parts[1]) ?? 0;
    
    final realTxs = transactions.where((t) => t.date == dateStr && isTransactionMatchingSelection(t)).toList();
    final virtualTxs = _getVirtualSettlements(year, month).where((t) => t.date == dateStr && isTransactionMatchingSelection(t)).toList();
    
    return [...realTxs, ...virtualTxs];
  }

  List<Transaction> getTransactionsForMonth(int year, int month, {bool ignoreDrawerFilter = false}) {
    final realTxs = transactions.where((t) {
      final parts = t.date.split('-');
      if (parts.length < 2) return false;
      final y = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      return y == year && m == month && isTransactionMatchingSelection(t, ignoreDrawerFilter: ignoreDrawerFilter);
    }).toList();

    final virtualTxs = _getVirtualSettlements(year, month).where((t) {
      final parts = t.date.split('-');
      if (parts.length < 2) return false;
      final y = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      return y == year && m == month && isTransactionMatchingSelection(t, ignoreDrawerFilter: ignoreDrawerFilter);
    }).toList();

    return [...realTxs, ...virtualTxs];
  }

  Map<String, int> getMonthlySummary(int year, int month) {
    int income = 0;
    int expense = 0;
    for (final t in getTransactionsForMonth(year, month, ignoreDrawerFilter: true)) {
      if (t.type == 'income') income += t.amount;
      if (t.type == 'expense') expense += t.amount;
    }
    return {'income': income, 'expense': expense};
  }

  DashboardSummary getDashboardSummary(int year, int month) {
    int receivedIncome = 0;
    List<Transaction> receivedIncomeList = [];
    List<FixedItemInfo> upIncome = [];
    int cashDebitPaid = 0;
    List<Transaction> cashDebitPaidList = [];
    int fixedPaid = 0;
    List<Transaction> fixedPaidList = [];
    int cardPaid = 0;
    List<FixedItemInfo> upExpense = [];
    
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    // 1. Income, Cash/Debit, Fixed
    for (final t in getTransactionsForMonth(year, month, ignoreDrawerFilter: true)) {
      if (t.isSettlement) continue;
      final parts = t.date.split('-');
      if (parts.length < 3) continue;
      final txDate = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      final isPastOrToday = !txDate.isAfter(todayOnly);
      
      if (t.type == 'income') {
        if (t.isRecurring) {
          if (isPastOrToday) {
            receivedIncome += t.amount;
            receivedIncomeList.add(t);
          } else {
            upIncome.add(FixedItemInfo(t, '${txDate.month.toString().padLeft(2, '0')}/${txDate.day.toString().padLeft(2, '0')}'));
          }
        } else {
          if (isPastOrToday) {
            receivedIncome += t.amount;
            receivedIncomeList.add(t);
          } else {
            upIncome.add(FixedItemInfo(t, '${txDate.month.toString().padLeft(2, '0')}/${txDate.day.toString().padLeft(2, '0')}'));
          }
        }
      } else if (t.type == 'expense') {
        final acc = accounts.firstWhereOrNull((a) => a.id == t.accountId);
        if (t.isRecurring) {
          if (acc == null || !acc.isCredit) {
            if (isPastOrToday) {
              fixedPaid += t.amount;
              fixedPaidList.add(t);
            } else {
              upExpense.add(FixedItemInfo(t, '${txDate.month.toString().padLeft(2, '0')}/${txDate.day.toString().padLeft(2, '0')}'));
            }
          }
        } else {
          // Cash or Debit
          if (acc == null || acc.isBank || acc.isDebit) {
            if (isPastOrToday) {
              cashDebitPaid += t.amount;
              cashDebitPaidList.add(t);
            } else {
              cashDebitPaid += t.amount;
              cashDebitPaidList.add(t);
            }
          }
        }
      }
    }

    // 2. Credit Cards
    List<CardPaymentInfo> paidCardList = [];
    List<CardPaymentInfo> upCard = [];
    List<CardPaymentInfo> ongoingCard = [];

    for (final acc in accounts.where((a) => a.isCredit)) {
      if (!selectedAccountIds.contains('all') && !selectedAccountIds.contains(acc.id)) continue;

      // Payment in month M
      final infoM = getCardPaymentInfo(acc, year, month);
      int amountM = infoM.amount;
      
      if (amountM >= 0) { // changed from > 0 to >= 0 so cards with 0 bill are shown
        final paymentDateM = _clampDate(year, month, acc.paymentDay ?? 25);
        if (!paymentDateM.isAfter(todayOnly)) {
          cardPaid += amountM;
          paidCardList.add(infoM);
        } else {
          upCard.add(infoM);
        }
      }

      // If viewing current real month, also calculate ongoing accumulation (Payment in month M+1)
      if (year == today.year && month == today.month) {
        final paymentDateNext = _clampDate(year, month + 1, acc.paymentDay ?? 25);
        final startNext = _clampDate(year, month + 1 + (acc.billingStartMonth ?? -1), acc.billingStartDay ?? 1);
        final endNext = _clampDate(year, month + 1 + (acc.billingEndMonth ?? -1), acc.billingEndDay ?? 31);
        
        // Sum up to today
        final endNextActual = todayOnly.isBefore(endNext) ? todayOnly : endNext;
        int amountNext = _sumCardTransactions(acc.id, startNext, endNextActual);
        
        List<Transaction> recurringTxsNext = [];
        for (final t in transactions) {
          if (t.accountId == acc.id && t.isRecurring && t.type == 'expense') {
            final parts = t.date.split('-');
            if (parts.length >= 3) {
              final txDate = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
              // For ongoing accumulation, we can show all recurring items falling in the billing period
              if (!txDate.isBefore(startNext) && !txDate.isAfter(endNext)) {
                recurringTxsNext.add(t);
              }
            }
          }
        }
        
        if (amountNext >= 0) {
          ongoingCard.add(CardPaymentInfo(
            account: acc, 
            startStr: '${startNext.month.toString().padLeft(2, '0')}/${startNext.day.toString().padLeft(2, '0')}', 
            endStr: '진행중', 
            paymentDateStr: '${paymentDateNext.month.toString().padLeft(2, '0')}/${paymentDateNext.day.toString().padLeft(2, '0')}', 
            amount: amountNext,
            isFinalized: false,
            recurringTxs: recurringTxsNext,
          ));
        }
      }
    }

    return DashboardSummary(
      alreadyReceivedIncome: receivedIncome,
      alreadyReceivedIncomeList: receivedIncomeList,
      upcomingIncomeList: upIncome,
      alreadyPaidCashDebit: cashDebitPaid,
      alreadyPaidCashDebitList: cashDebitPaidList,
      alreadyPaidFixed: fixedPaid,
      alreadyPaidFixedList: fixedPaidList,
      alreadyPaidCard: cardPaid,
      alreadyPaidCardList: paidCardList,
      upcomingExpenseList: upExpense,
      upcomingCardPayments: upCard,
      ongoingCardAccumulations: ongoingCard,
    );
  }

  CardPaymentInfo getCardPaymentInfo(Account acc, int year, int month) {
    final paymentDateM = _clampDate(year, month, acc.paymentDay ?? 25);
    final startM = _clampDate(year, month + (acc.billingStartMonth ?? -1), acc.billingStartDay ?? 1);
    final endM = _clampDate(year, month + (acc.billingEndMonth ?? -1), acc.billingEndDay ?? 31);
    
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    
    final endActualM = todayOnly.isBefore(endM) ? todayOnly : endM;
    int amountM = _sumCardTransactions(acc.id, startM, endActualM);
    
    bool isFinalized = todayOnly.isAfter(endM);

    List<Transaction> recurringTxsM = [];
    for (final t in transactions) {
      if (t.accountId == acc.id && t.isRecurring && t.type == 'expense') {
        final parts = t.date.split('-');
        if (parts.length >= 3) {
          final txDate = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
          if (!txDate.isBefore(startM) && !txDate.isAfter(endM)) {
            recurringTxsM.add(t);
          }
        }
      }
    }

    return CardPaymentInfo(
      account: acc, 
      startStr: '${startM.month.toString().padLeft(2, '0')}/${startM.day.toString().padLeft(2, '0')}', 
      endStr: '${endM.month.toString().padLeft(2, '0')}/${endM.day.toString().padLeft(2, '0')}', 
      paymentDateStr: '${paymentDateM.month.toString().padLeft(2, '0')}/${paymentDateM.day.toString().padLeft(2, '0')}', 
      amount: amountM,
      isFinalized: isFinalized,
      recurringTxs: recurringTxsM,
    );
  }

  int _sumCardTransactions(String cardId, DateTime start, DateTime end) {
    if (!selectedAccountIds.contains('all') && !selectedAccountIds.contains(cardId)) return 0;
    int sum = 0;
    for (final t in transactions) {
      if (t.accountId != cardId || t.type != 'expense') continue;
      final parts = t.date.split('-');
      if (parts.length < 3) continue;
      final txDate = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      if (txDate.isAfter(start.subtract(const Duration(days: 1))) && txDate.isBefore(end.add(const Duration(days: 1)))) {
        sum += t.amount;
      }
    }
    return sum;
  }

  int getExpectedNetAssetAtEnd(int year, int month) {
    int total = 0;
    final endOfMonth = DateTime(year, month + 1, 0);

    for (final a in accounts.where((a) => a.isBank)) {
      total += getBankAccountBalance(a.id, upToDate: endOfMonth);
    }

    return total;
  }

  int getNetAssets() {
    int total = 0;
    final now = assetReferenceDate;

    for (final a in accounts.where((a) => a.isBank)) {
      total += getBankAccountBalance(a.id, upToDate: now);
    }

    return total;
  }

  int getFilteredNetAssets() {
    if (selectedAccountIds.contains('all')) {
      return getNetAssets();
    }
    
    int total = 0;
    for (final acc in accounts) {
      if (!selectedAccountIds.contains(acc.id)) continue;
      if (acc.isBank) {
        total += getBankAccountBalance(acc.id);
      }
    }
    return total;
  }

  bool _isCardTransactionSettled(Account card, DateTime txDate, DateTime upToDate) {
    for (int offset = -1; offset <= 3; offset++) {
      int y = txDate.year;
      int m = txDate.month + offset;
      while (m < 1) { m += 12; y--; }
      while (m > 12) { m -= 12; y++; }
      
      final startM = _clampDate(y, m + (card.billingStartMonth ?? -1), card.billingStartDay ?? 1);
      final endM = _clampDate(y, m + (card.billingEndMonth ?? -1), card.billingEndDay ?? 31);
      
      if (!txDate.isBefore(startM) && !txDate.isAfter(endM)) {
        final paymentDate = _clampDate(y, m, card.paymentDay ?? 25);
        return !paymentDate.isAfter(upToDate);
      }
    }
    return false;
  }

  int getBankAccountBalance(String bankAccountId, {DateTime? upToDate}) {
    final now = upToDate ?? assetReferenceDate;
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final nowOnly = DateTime(now.year, now.month, now.day);
    
    final bank = accounts.firstWhereOrNull((a) => a.id == bankAccountId);
    if (bank == null) return 0;
    
    int bal = bank.initialBalance;
    for (final t in transactions) {
      if (t.date.compareTo(todayStr) > 0) continue;
      
      bool appliesToBank = false;
      if (t.accountId == bankAccountId) {
        appliesToBank = true;
      } else {
        final txAcc = accounts.firstWhereOrNull((a) => a.id == t.accountId);
        if (txAcc != null && txAcc.linkedBankAccountId == bankAccountId) {
          if (txAcc.isDebit) {
            appliesToBank = true;
          } else if (txAcc.isCredit) {
            final parts = t.date.split('-');
            if (parts.length >= 3) {
              final txDate = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
              if (_isCardTransactionSettled(txAcc, txDate, nowOnly)) {
                appliesToBank = true;
              }
            }
          }
        }
      }
      
      if (appliesToBank) {
        if (t.type == 'income') bal += t.amount;
        if (t.type == 'expense') bal -= t.amount;
      }
    }
    return bal;
  }

  int getCreditCardDebt(String cardId, {DateTime? upToDate}) {
    final now = upToDate ?? assetReferenceDate;
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    
    int debt = 0;
    for (final t in transactions) {
      if (t.accountId == cardId) {
        if (t.date.compareTo(todayStr) > 0) continue;
        if (t.type == 'expense') debt -= t.amount;
        if (t.type == 'income') debt += t.amount;
      }
    }
    return debt;
  }

  int getCardBillForMonth(String cardId, int year, int month) {
    final now = assetReferenceDate;
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    return transactions.where((t) {
      if (t.date.compareTo(todayStr) > 0) return false;
      final parts = t.date.split('-');
      final y = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      return t.accountId == cardId && y == year && m == month && t.type == 'expense';
    }).fold(0, (sum, t) => sum + t.amount);
  }
}
