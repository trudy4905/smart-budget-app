import 'package:flutter/material.dart';
import 'package:flutter_app/features/accounts/models/account.dart';
import 'package:flutter_app/features/transactions/models/transaction.dart';
import 'package:flutter_app/core/utils/helpers.dart';

import 'package:flutter_app/features/categories/models/category_info.dart';
import 'package:flutter_app/core/services/storage_service.dart';
import 'package:flutter_app/core/providers/ui_view_model.dart';

import 'package:flutter_app/features/dashboard/models/dashboard_summary.dart';
export 'package:flutter_app/features/dashboard/models/dashboard_summary.dart';

class AppState extends ChangeNotifier {
  List<Account> accounts = [];
  List<Transaction> transactions = [];
  List<CategoryInfo> categories = [];
  final StorageService _storageService = StorageService();
  final UiViewModel uiState = UiViewModel();

  // ---- UI State Facade ----
  DateTime get currentDate => uiState.currentDate;
  String get selectedDateStr => uiState.selectedDateStr;
  List<String> get selectedAccountIds => uiState.selectedAccountIds;
  String get drawerFilter => uiState.drawerFilter;
  DateTime get assetReferenceDate => uiState.assetReferenceDate;
  List<String> get dashboardItemOrder => uiState.dashboardItemOrder;

  void setAssetReferenceDate(DateTime date) {
    uiState.setAssetReferenceDate(date);
    notifyListeners();
  }

  bool _loaded = false;
  bool get loaded => _loaded;

  AppState() {
    _loadAll();
  }

  // ---- Date helpers ----
  static String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String get currentMonthStr {
    return '${currentDate.year}년 ${currentDate.month}월';
  }

  // ---- Load / Save ----
  Future<void> _loadAll() async {
    final loadedAccounts = await _storageService.loadAccounts();
    if (loadedAccounts != null) {
      accounts = loadedAccounts;
    } else {
      accounts = _sampleAccounts();
      _saveAccounts();
    }

    final loadedTransactions = await _storageService.loadTransactions();
    if (loadedTransactions != null) {
      transactions = loadedTransactions;
    } else {
      transactions = _sampleTransactions();
      _saveTransactions();
    }

    final loadedCategories = await _storageService.loadCategories();
    if (loadedCategories != null) {
      categories = loadedCategories;
    } else {
      categories = [...kExpenseCategories, ...kIncomeCategories];
      _saveCategories();
    }

    await uiState.init();

    _loaded = true;
    notifyListeners();
  }

  Future<void> resetAllData() async {
    accounts = _sampleAccounts();
    transactions = [];
    _saveAccounts();
    _saveTransactions();
    notifyListeners();
  }

  Future<void> _saveAccounts() async {
    await _storageService.saveAccounts(accounts);
  }

  Future<void> _saveTransactions() async {
    await _storageService.saveTransactions(transactions);
  }

  Future<void> _saveCategories() async {
    await _storageService.saveCategories(categories);
  }

  Future<void> reorderDashboardItems(int oldIndex, int newIndex) async {
    await uiState.reorderDashboardItems(oldIndex, newIndex);
    notifyListeners();
  }

  // ---- Navigation ----
  void setCurrentDate(DateTime d) {
    uiState.setCurrentDate(d);
    notifyListeners();
  }

  void setSelectedDate(String dateStr) {
    uiState.setSelectedDate(dateStr);
    notifyListeners();
  }

  void setSelectedAccountIds(List<String> ids) {
    uiState.setSelectedAccountIds(ids);
    notifyListeners();
  }

  void setDrawerFilter(String f) {
    uiState.setDrawerFilter(f);
    notifyListeners();
  }

  // ---- Filtering ----
  bool isTransactionMatchingSelection(Transaction t, {bool ignoreDrawerFilter = false}) {
    final txAcc = accounts.firstWhereOrNull((a) => a.id == t.accountId);
    final isCardTx = txAcc != null && txAcc.isCredit;
    final isCashTx = txAcc == null || txAcc.isBank || txAcc.isDebit;

    if (!ignoreDrawerFilter) {
      if (drawerFilter == 'income') {
        if (t.type != 'income') return false;
      } else if (drawerFilter == 'cash') {
        if (!isCashTx || t.type != 'expense') return false;
      } else if (drawerFilter == 'card') {
        if (!isCardTx || t.type != 'expense') return false;
      } else if (drawerFilter == 'total_expense') {
        if (t.type != 'expense') return false;
      } else if (drawerFilter == 'next_all') {
        // 다음달 전체 = 이번달 신용카드 사용분 (다음달에 결제)
        if (!isCardTx || t.type != 'expense') return false;
      } else if (drawerFilter == 'next_income') {
        // 다음달 수입 = 해당 없음 (항상 빈 목록)
        return false;
      } else if (drawerFilter == 'next_card') {
        // 다음달 지출 = 이번달 신용카드 사용분
        if (!isCardTx || t.type != 'expense') return false;
      }
    }

    if (selectedAccountIds.contains('all')) return true;
    if (selectedAccountIds.isEmpty) return false;
    if (selectedAccountIds.contains(t.accountId)) return true;

    if (txAcc != null && txAcc.isDebit) {
      if (txAcc.linkedBankAccountId != null) {
        if (selectedAccountIds.contains(txAcc.linkedBankAccountId)) return true;
      }
    }
    return false;
  }

  List<Transaction> _getVirtualSettlements(int year, int month) {
    List<Transaction> vts = [];
    for (final acc in accounts.where((a) => a.isCredit && a.paymentDay != null)) {
      final paymentDateM = _clampDate(year, month, acc.paymentDay!);
      final startM = _clampDate(year, month + (acc.billingStartMonth ?? -1), acc.billingStartDay ?? 1);
      final endM = _clampDate(year, month + (acc.billingEndMonth ?? -1), acc.billingEndDay ?? 31);
      
      int amountM = _sumCardTransactions(acc.id, startM, endM);
      
      String dateStr = '${paymentDateM.year}-${paymentDateM.month.toString().padLeft(2, '0')}-${paymentDateM.day.toString().padLeft(2, '0')}';
      vts.add(Transaction(
        id: 'vt_${acc.id}_${year}_$month',
        date: dateStr,
        accountId: acc.linkedBankAccountId ?? '',
        type: 'expense',
        amount: amountM,
        category: '카드대금 결제',
        memo: '${acc.name} 대금',
        isSettlement: true,
      ));
    }
    return vts;
  }

  List<Transaction> getTransactionsForDate(String dateStr) {
    final parts = dateStr.split('-');
    if (parts.length < 3) return [];
    final year = int.tryParse(parts[0]) ?? 0;
    final month = int.tryParse(parts[1]) ?? 0;

    List<Transaction> result = transactions.where((t) => t.date == dateStr && isTransactionMatchingSelection(t)).toList();
    result.addAll(_getVirtualSettlements(year, month).where((t) => t.date == dateStr && isTransactionMatchingSelection(t)));

    return result;
  }

  List<Transaction> getTransactionsForMonth(int year, int month, {bool ignoreDrawerFilter = false}) {
    List<Transaction> result = transactions.where((t) {
      final parts = t.date.split('-');
      if (parts.length < 3) return false;
      final y = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      return y == year && m == month && isTransactionMatchingSelection(t, ignoreDrawerFilter: ignoreDrawerFilter);
    }).toList();

    result.addAll(_getVirtualSettlements(year, month).where((t) => isTransactionMatchingSelection(t, ignoreDrawerFilter: ignoreDrawerFilter)));

    return result;
  }

  // ---- Computed summaries ----
  Map<String, int> getMonthlySummary(int year, int month) {
    int income = 0, bankExpense = 0, debitExpense = 0, card = 0;
    for (final t in getTransactionsForMonth(year, month, ignoreDrawerFilter: true)) {
      if (t.isSettlement) continue;
      final acc = accounts.firstWhereOrNull((a) => a.id == t.accountId);
      if (t.type == 'income') {
        income += t.amount;

      } else if (t.type == 'expense') {
        if (acc != null && acc.isCredit) {
          card += t.amount;
        } else if (acc != null && acc.isDebit) {
          debitExpense += t.amount;
        } else {
          bankExpense += t.amount;
        }
      }
    }

    // Calculate last month's card bill
    int lastMonthYear = month == 1 ? year - 1 : year;
    int lastMonth = month == 1 ? 12 : month - 1;
    int lastMonthCardBill = 0;
    for (final c in accounts.where((a) => a.isCredit)) {
      lastMonthCardBill += getCardBillForMonth(c.id, lastMonthYear, lastMonth);
    }

    int cash = bankExpense + debitExpense + lastMonthCardBill;

    return {
      'income': income, 
      'cash': cash, 
      'card': card, 
      'total': cash, 
      'bankExpense': bankExpense,
      'debitExpense': debitExpense,
      'lastMonthCardBill': lastMonthCardBill,
    };
  }

  DateTime _clampDate(int y, int m, int d) {
    int year = y;
    int month = m;
    while (month < 1) {
      month += 12;
      year -= 1;
    }
    while (month > 12) {
      month -= 12;
      year += 1;
    }
    int lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, d > lastDay ? lastDay : d);
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
    
    int amountM = _sumCardTransactions(acc.id, startM, endM);
    
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    bool isFinalized = !todayOnly.isBefore(endM);

    // Find all recurring transactions for this card within this billing period
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
    // Calculate the last day of the given month
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

  // ---- Clear Data ----
  Future<void> clearAllData() async {
    await _storageService.clearAll();
    
    accounts = _sampleAccounts();
    transactions = _sampleTransactions();
    categories = [...kExpenseCategories, ...kIncomeCategories];
    
    _saveAccounts();
    _saveTransactions();
    _saveCategories();
    
    uiState.setSelectedAccountIds(['all']);
    
    notifyListeners();
  }

  // ---- CRUD ----
  void addAccount(Account acc) {
    accounts.add(acc);
    _saveAccounts();
    notifyListeners();
  }

  void updateAccount(Account acc) {
    final idx = accounts.indexWhere((e) => e.id == acc.id);
    if (idx != -1) {
      accounts[idx] = acc;
      _saveAccounts();
      notifyListeners();
    }
  }

  void deleteAccount(String id) {
    accounts.removeWhere((e) => e.id == id);
    _saveAccounts();
    notifyListeners();
  }

  void addTransaction(Transaction tx) {
    transactions.insert(0, tx);
    _saveTransactions();
    notifyListeners();
  }

  void addTransactions(List<Transaction> txs) {
    transactions.insertAll(0, txs.reversed);
    _saveTransactions();
    notifyListeners();
  }

  void deleteTransaction(String id) {
    transactions.removeWhere((t) => t.id == id);
    _saveTransactions();
    notifyListeners();
  }

  void deleteRecurringTransactions(String recurringId) {
    transactions.removeWhere((t) => t.recurringId == recurringId);
    _saveTransactions();
    notifyListeners();
  }

  // ---- Category Management ----
  CategoryInfo getCategoryInfo(String name) {
    for (final c in categories) {
      if (c.name == name) return c;
    }
    return const CategoryInfo(name: '기타', emoji: '📌', color: Color(0xFF94A3B8), type: 'expense');
  }

  void addCategory(CategoryInfo cat) {
    categories.add(cat);
    _saveCategories();
    notifyListeners();
  }

  void updateCategory(CategoryInfo cat, String oldName) {
    final idx = categories.indexWhere((e) => e.name == oldName);
    if (idx != -1) {
      categories[idx] = cat;
      // Update transactions
      for (var t in transactions) {
        if (t.category == oldName) {
          t.category = cat.name;
        }
      }
      _saveCategories();
      _saveTransactions();
      notifyListeners();
    }
  }

  void deleteCategory(String name, String? transferToName) {
    categories.removeWhere((e) => e.name == name);
    if (transferToName != null) {
      for (var t in transactions) {
        if (t.category == name) {
          t.category = transferToName;
        }
      }
      _saveTransactions();
    }
    _saveCategories();
    notifyListeners();
  }

  // ---- Sample data ----
  static List<Account> _sampleAccounts() => [
    Account(id: 'acc_main_bank', name: '주거래 통장', type: 'bank', color: '#3B82F6', initialBalance: 0, bank: 'KB국민은행')
  ];

  static List<Transaction> _sampleTransactions() => [];
}
