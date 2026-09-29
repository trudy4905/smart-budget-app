import 'package:flutter/material.dart';
import 'package:flutter_app/features/home/add_transaction/models/transaction.dart';
import 'package:flutter_app/features/drawer/accounts/models/account.dart';
import 'package:flutter_app/core/providers/app_state.dart';

class RecurringViewModel extends ChangeNotifier {
  final AppState _appState;

  RecurringViewModel(this._appState) {
    _appState.addListener(_onAppStateChanged);
  }

  @override
  void dispose() {
    _appState.removeListener(_onAppStateChanged);
    super.dispose();
  }

  void _onAppStateChanged() {
    notifyListeners();
  }

  List<Transaction> getNonCreditRecurringExpenses() {
    final Map<String, Transaction> recurringMap = {};
    for (final t in _appState.transactions) {
      if (t.isRecurring && t.recurringId != null && t.type == 'expense') {
        if (!_appState.selectedAccountIds.contains('all') && !_appState.selectedAccountIds.contains(t.accountId)) {
          continue;
        }
        final acc = _appState.accounts.where((a) => a.id == t.accountId).firstOrNull;
        if (acc == null || !acc.isCredit) {
          recurringMap[t.recurringId!] = t;
        }
      }
    }
    return recurringMap.values.toList();
  }

  List<Account> getCreditCardsForRecurring() {
    return _appState.accounts.where((a) => 
      a.isCredit && 
      a.paymentDay != null && 
      (_appState.selectedAccountIds.contains('all') || _appState.selectedAccountIds.contains(a.id))
    ).toList();
  }
}
