import 'package:flutter/material.dart';
import 'package:flutter_app/features/home/add_transaction/models/transaction.dart';
import 'package:flutter_app/features/drawer/accounts/models/account.dart';
import 'package:flutter_app/features/home/add_transaction/view_models/transaction_view_model.dart';
import 'package:flutter_app/features/drawer/accounts/view_models/account_view_model.dart';
import 'package:flutter_app/core/providers/ui_view_model.dart';
import 'package:flutter_app/features/drawer/dashboard/models/dashboard_summary.dart';

class RecurringViewModel extends ChangeNotifier {
  final TransactionViewModel _txVM;
  final AccountViewModel _accVM;
  final UiViewModel _uiVM;

  RecurringViewModel(this._txVM, this._accVM, this._uiVM) {
    _txVM.addListener(_onAppStateChanged);
    _accVM.addListener(_onAppStateChanged);
    _uiVM.addListener(_onAppStateChanged);
  }

  @override
  void dispose() {
    _txVM.removeListener(_onAppStateChanged);
    _accVM.removeListener(_onAppStateChanged);
    _uiVM.removeListener(_onAppStateChanged);
    super.dispose();
  }

  void _onAppStateChanged() {
    notifyListeners();
  }

  List<Transaction> getNonCreditRecurringExpenses() {
    final Map<String, Transaction> recurringMap = {};
    for (final t in _txVM.transactions) {
      if (t.isRecurring && t.recurringId != null && t.type == 'expense') {
        if (!_uiVM.selectedAccountIds.contains('all') && !_uiVM.selectedAccountIds.contains(t.accountId)) {
          continue;
        }
        final acc = _accVM.accounts.where((a) => a.id == t.accountId).firstOrNull;
        if (acc == null || !acc.isCredit) {
          recurringMap[t.recurringId!] = t;
        }
      }
    }
    return recurringMap.values.toList();
  }

  List<Account> getCreditCardsForRecurring() {
    return _accVM.accounts.where((a) => 
      a.isCredit && 
      a.paymentDay != null && 
      (_uiVM.selectedAccountIds.contains('all') || _uiVM.selectedAccountIds.contains(a.id))
    ).toList();
  }

  int getTotalRecurringExpense(int year, int month, DashboardSummary dash) {
    final recurringTxs = getNonCreditRecurringExpenses();
    final cards = getCreditCardsForRecurring();
    int totalExpense = 0;
    
    for (final tx in recurringTxs) {
      final parts = tx.date.split('-');
      final regYear = parts.isNotEmpty ? int.tryParse(parts[0]) ?? year : year;
      final regMonth = parts.length >= 2 ? int.tryParse(parts[1]) ?? month : month;
      
      bool isPast = (year < regYear) || (year == regYear && month < regMonth);
      final acc = _accVM.accounts.where((a) => a.id == tx.accountId).firstOrNull;
      if (acc == null || !acc.isCredit) {
        totalExpense += isPast ? 0 : tx.amount;
      }
    }
    
    for (final c in cards) {
      for (final info in dash.alreadyPaidCardList) {
        if (info.account.id == c.id) totalExpense += info.amount;
      }
      for (final info in dash.upcomingCardPayments) {
        if (info.account.id == c.id) totalExpense += info.amount;
      }
    }
    return totalExpense;
  }

  List<Transaction> getRecurringIncomes() {
    final Map<String, Transaction> recurringMap = {};
    for (final t in _txVM.transactions) {
      if (t.isRecurring && t.recurringId != null && t.type == 'income') {
        if (!_uiVM.selectedAccountIds.contains('all') && !_uiVM.selectedAccountIds.contains(t.accountId)) continue;
        recurringMap[t.recurringId!] = t;
      }
    }
    return recurringMap.values.toList();
  }

  int getTotalRecurringIncome() {
    final incomes = getRecurringIncomes();
    return incomes.fold(0, (sum, tx) => sum + tx.amount);
  }
}

