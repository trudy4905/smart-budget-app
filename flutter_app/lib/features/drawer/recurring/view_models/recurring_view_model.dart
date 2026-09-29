import 'package:flutter/material.dart';
import 'package:flutter_app/features/home/add_transaction/models/transaction.dart';
import 'package:flutter_app/features/drawer/accounts/models/account.dart';
import 'package:flutter_app/features/home/add_transaction/view_models/transaction_view_model.dart';
import 'package:flutter_app/features/drawer/accounts/view_models/account_view_model.dart';
import 'package:flutter_app/core/providers/ui_view_model.dart';

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
}

