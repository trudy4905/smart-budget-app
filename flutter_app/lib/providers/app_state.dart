import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/account.dart';
import '../models/transaction.dart';
import '../utils/helpers.dart';

import '../models/category_info.dart';

const kStorageKeyTx = 'smart_budget_transactions_v6.0';
const kStorageKeyAcc = 'smart_budget_accounts_v6.0';
const kStorageKeyRec = 'smart_budget_recurring_v6.0';
const kStorageKeyCat = 'smart_budget_categories_v6.0';

class AppState extends ChangeNotifier {
  List<Account> accounts = [];
  List<Transaction> transactions = [];
  List<CategoryInfo> categories = [];
  DateTime currentDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  String selectedDateStr = _formatDate(DateTime.now());
  List<String> selectedAccountIds = ['all'];
  String drawerFilter = 'all'; // 'all', 'income', 'cash', 'card', 'total_expense', 'next_all', 'next_card'
  DateTime assetReferenceDate = DateTime.now();

  void setAssetReferenceDate(DateTime date) {
    assetReferenceDate = date;
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
    final prefs = await SharedPreferences.getInstance();

    final accStr = prefs.getString(kStorageKeyAcc);
    if (accStr != null) {
      try {
        final List dec = jsonDecode(accStr);
        accounts = dec.map((e) => Account.fromJson(e)).toList();
      } catch (_) {
        accounts = _sampleAccounts();
        _saveAccounts(prefs);
      }
    } else {
      accounts = _sampleAccounts();
      _saveAccounts(prefs);
    }

    final txStr = prefs.getString(kStorageKeyTx);
    if (txStr != null) {
      try {
        final List dec = jsonDecode(txStr);
        transactions = dec.map((e) => Transaction.fromJson(e)).toList();
      } catch (_) {
        transactions = _sampleTransactions();
        _saveTransactions(prefs);
      }
    } else {
      transactions = _sampleTransactions();
      _saveTransactions(prefs);
    }

    final catStr = prefs.getString(kStorageKeyCat);
    if (catStr != null) {
      try {
        final List dec = jsonDecode(catStr);
        categories = dec.map((e) => CategoryInfo.fromJson(e)).toList();
      } catch (_) {
        categories = [...kExpenseCategories, ...kIncomeCategories];
        _saveCategories(prefs);
      }
    } else {
      categories = [...kExpenseCategories, ...kIncomeCategories];
      _saveCategories(prefs);
    }

    _loaded = true;
    notifyListeners();
  }

  Future<void> _saveAccounts([SharedPreferences? prefs]) async {
    prefs ??= await SharedPreferences.getInstance();
    await prefs.setString(kStorageKeyAcc, jsonEncode(accounts.map((e) => e.toJson()).toList()));
  }

  Future<void> _saveTransactions([SharedPreferences? prefs]) async {
    prefs ??= await SharedPreferences.getInstance();
    await prefs.setString(kStorageKeyTx, jsonEncode(transactions.map((e) => e.toJson()).toList()));
  }

  Future<void> _saveCategories([SharedPreferences? prefs]) async {
    prefs ??= await SharedPreferences.getInstance();
    await prefs.setString(kStorageKeyCat, jsonEncode(categories.map((e) => e.toJson()).toList()));
  }

  // ---- Navigation ----
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

    if (txAcc != null && txAcc.isDebit && txAcc.linkedBankAccountId != null) {
      if (selectedAccountIds.contains(txAcc.linkedBankAccountId)) return true;
    }
    return false;
  }

  List<Transaction> getTransactionsForDate(String dateStr) {
    return transactions.where((t) => t.date == dateStr && isTransactionMatchingSelection(t)).toList();
  }

  List<Transaction> getTransactionsForMonth(int year, int month, {bool ignoreDrawerFilter = false}) {
    return transactions.where((t) {
      final parts = t.date.split('-');
      if (parts.length < 3) return false;
      final y = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      return y == year && m == month && isTransactionMatchingSelection(t, ignoreDrawerFilter: ignoreDrawerFilter);
    }).toList();
  }

  // ---- Computed summaries ----
  Map<String, int> getMonthlySummary(int year, int month) {
    int income = 0, bankExpense = 0, debitExpense = 0, card = 0, noneIncome = 0, noneExpense = 0;
    for (final t in getTransactionsForMonth(year, month, ignoreDrawerFilter: true)) {
      final acc = accounts.firstWhereOrNull((a) => a.id == t.accountId);
      if (t.type == 'income') {
        income += t.amount;
        if (t.accountId == 'none') noneIncome += t.amount;
      } else if (t.type == 'expense') {
        if (t.accountId == 'none') {
          noneExpense += t.amount;
          bankExpense += t.amount; // Treat 'none' expense as bank expense (cash)
        } else if (acc != null && acc.isCredit) {
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
      'noneIncome': noneIncome,
      'noneExpense': noneExpense,
    };
  }

  int getNetAssets() {
    int bankInitial = 0;
    int bankIncome = 0;
    int bankExpense = 0;
    final now = assetReferenceDate;
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    for (final a in accounts.where((a) => a.isBank)) {
      bankInitial += a.initialBalance;
    }
    for (final t in transactions) {
      if (t.date.compareTo(todayStr) > 0) continue;
      final acc = accounts.firstWhereOrNull((a) => a.id == t.accountId);
      if (acc != null && (acc.isBank || acc.isDebit)) {
        if (t.type == 'income') bankIncome += t.amount;
        if (t.type == 'expense') bankExpense += t.amount;
      }
    }

    int cardBills = 0;
    for (final card in accounts.where((a) => a.isCredit)) {
      cardBills += getCardBillForMonth(card.id, currentDate.year, currentDate.month);
    }

    return bankInitial + bankIncome - bankExpense - cardBills;
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
  static List<Account> _sampleAccounts() => [];

  static List<Transaction> _sampleTransactions() => [];
}
