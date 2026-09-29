import 'package:flutter/material.dart';
import 'package:flutter_app/features/drawer/accounts/models/account.dart';
import 'package:flutter_app/features/home/add_transaction/models/transaction.dart';
import 'package:flutter_app/features/categories/models/category_info.dart';
import 'package:flutter_app/core/providers/ui_view_model.dart';
import 'package:flutter_app/features/drawer/accounts/view_models/account_view_model.dart';
import 'package:flutter_app/features/home/add_transaction/view_models/transaction_view_model.dart';
import 'package:flutter_app/features/categories/view_models/category_view_model.dart';

export 'package:flutter_app/features/drawer/dashboard/models/dashboard_summary.dart';

class AppState extends ChangeNotifier {
  final AccountViewModel accountVM;
  final TransactionViewModel transactionVM;
  final CategoryViewModel categoryVM;
  final UiViewModel uiState;

  AppState(this.accountVM, this.transactionVM, this.categoryVM, this.uiState) {
    accountVM.addListener(notifyListeners);
    transactionVM.addListener(notifyListeners);
    categoryVM.addListener(notifyListeners);
    uiState.addListener(notifyListeners);
  }

  List<Account> get accounts => accountVM.accounts;
  List<Transaction> get transactions => transactionVM.transactions;
  List<CategoryInfo> get categories => categoryVM.categories;

  // ---- UI State Facade ----
  DateTime get currentDate => uiState.currentDate;
  String get selectedDateStr => uiState.selectedDateStr;
  List<String> get selectedAccountIds => uiState.selectedAccountIds;
  String get drawerFilter => uiState.drawerFilter;
  DateTime get assetReferenceDate => uiState.assetReferenceDate;
  List<String> get dashboardItemOrder => uiState.dashboardItemOrder;

  void setAssetReferenceDate(DateTime date) => uiState.setAssetReferenceDate(date);
  void setCurrentDate(DateTime d) => uiState.setCurrentDate(d);
  void setSelectedDate(String dateStr) => uiState.setSelectedDate(dateStr);
  void setSelectedAccountIds(List<String> ids) => uiState.setSelectedAccountIds(ids);
  void setDrawerFilter(String f) => uiState.setDrawerFilter(f);
  Future<void> reorderDashboardItems(int oldIndex, int newIndex) => uiState.reorderDashboardItems(oldIndex, newIndex);

  String get currentMonthStr => '${currentDate.year}년 ${currentDate.month}월';

  bool get loaded => true;

  // ---- Clear Data ----
  Future<void> clearAllData() async {
    accountVM.clearAccounts();
    transactionVM.clearTransactions();
    uiState.setSelectedAccountIds(['all']);
    notifyListeners();
  }

  Future<void> resetAllData() async {
    accountVM.clearAccounts();
    transactionVM.clearTransactions();
  }

  // ---- Account CRUD ----
  void addAccount(Account acc) => accountVM.addAccount(acc);
  void updateAccount(Account acc) => accountVM.updateAccount(acc);
  void deleteAccount(String id) => accountVM.deleteAccount(id);

  // ---- Transaction CRUD ----
  void addTransaction(Transaction tx) => transactionVM.addTransaction(tx);
  void addTransactions(List<Transaction> txs) => transactionVM.addTransactions(txs);
  void deleteTransaction(String id) => transactionVM.deleteTransaction(id);
  void deleteRecurringTransactions(String recurringId) => transactionVM.deleteRecurringTransactions(recurringId);

  // ---- Category Management ----
  CategoryInfo getCategoryInfo(String name) => categoryVM.getCategoryInfo(name);
  void addCategory(CategoryInfo cat) => categoryVM.addCategory(cat);
  void updateCategory(CategoryInfo cat, String oldName) => categoryVM.updateCategory(cat, oldName);
  
  void deleteCategory(String name, String? transferToName) {
    if (transferToName != null) {
      transactionVM.transferCategory(name, transferToName);
    }
    categoryVM.deleteCategory(name);
  }
}
