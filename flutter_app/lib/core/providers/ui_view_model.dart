import 'package:flutter/material.dart';
import 'package:flutter_app/core/services/storage_service.dart';

class UiViewModel extends ChangeNotifier {
  final StorageService _storageService = StorageService();

  DateTime currentDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  String selectedDateStr = _formatDate(DateTime.now());
  List<String> selectedAccountIds = ['all'];
  String drawerFilter = 'all'; 
  DateTime assetReferenceDate = DateTime.now();

  bool isAccountsExpanded = true;
  bool isRecurringIncomeExpanded = true;
  bool isRecurringExpenseExpanded = true;
  bool isAssetVisible = true;

  List<String> dashboardItemOrder = [
    'income',
    'expense',
    'upcoming_income',
    'upcoming_expense',
    'expected_asset',
    'recurring_expense',
    'recurring_income'
  ];

  static String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String get currentMonthStr => '${currentDate.year}년 ${currentDate.month}월';

  Future<void> init() async {
    final orderStr = await _storageService.loadDashboardItemOrder();
    if (orderStr != null) {
      dashboardItemOrder = orderStr;
    }
    isAccountsExpanded = await _storageService.loadBool('isAccountsExpanded') ?? true;
    isRecurringIncomeExpanded = await _storageService.loadBool('isRecurringIncomeExpanded') ?? true;
    isRecurringExpenseExpanded = await _storageService.loadBool('isRecurringExpenseExpanded') ?? true;
    isAssetVisible = await _storageService.loadBool('isAssetVisible') ?? true;
    notifyListeners();
  }

  void setCurrentDate(DateTime d) {
    currentDate = DateTime(d.year, d.month, 1);
    notifyListeners();
  }

  void setSelectedDate(String dateStr) {
    selectedDateStr = dateStr;
    notifyListeners();
  }

  void setSelectedAccountIds(List<String> ids) {
    selectedAccountIds = ids;
    notifyListeners();
  }

  void setDrawerFilter(String f) {
    drawerFilter = f;
    notifyListeners();
  }

  void toggleAccountsExpanded() {
    isAccountsExpanded = !isAccountsExpanded;
    notifyListeners();
    _storageService.saveBool('isAccountsExpanded', isAccountsExpanded);
  }

  void toggleRecurringIncomeExpanded() {
    isRecurringIncomeExpanded = !isRecurringIncomeExpanded;
    notifyListeners();
    _storageService.saveBool('isRecurringIncomeExpanded', isRecurringIncomeExpanded);
  }

  void toggleRecurringExpenseExpanded() {
    isRecurringExpenseExpanded = !isRecurringExpenseExpanded;
    notifyListeners();
    _storageService.saveBool('isRecurringExpenseExpanded', isRecurringExpenseExpanded);
  }

  void toggleAssetVisible() {
    isAssetVisible = !isAssetVisible;
    notifyListeners();
    _storageService.saveBool('isAssetVisible', isAssetVisible);
  }

  void setAssetReferenceDate(DateTime date) {
    assetReferenceDate = date;
    notifyListeners();
  }

  Future<void> reorderDashboardItems(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = dashboardItemOrder.removeAt(oldIndex);
    dashboardItemOrder.insert(newIndex, item);
    notifyListeners();
    
    await _storageService.saveDashboardItemOrder(dashboardItemOrder);
  }
}

