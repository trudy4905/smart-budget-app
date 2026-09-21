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

class CardPaymentInfo {
  final Account account;
  final String startStr;
  final String endStr;
  final String paymentDateStr; // e.g., '9.25'
  final int amount;
  final bool isFinalized;

  CardPaymentInfo({
    required this.account, required this.startStr, required this.endStr, 
    required this.paymentDateStr, required this.amount, required this.isFinalized
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
        accountId: acc.linkedBankAccountId ?? 'none',
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
    int income = 0, bankExpense = 0, debitExpense = 0, card = 0, noneIncome = 0, noneExpense = 0;
    for (final t in getTransactionsForMonth(year, month, ignoreDrawerFilter: true)) {
      if (t.isSettlement) continue;
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
            upIncome.add(FixedItemInfo(t, '${txDate.month}.${txDate.day}'));
          }
        } else {
          receivedIncome += t.amount;
          receivedIncomeList.add(t);
        }
      } else if (t.type == 'expense') {
        final acc = accounts.firstWhereOrNull((a) => a.id == t.accountId);
        if (t.isRecurring) {
          if (isPastOrToday) {
            fixedPaid += t.amount;
            fixedPaidList.add(t);
          } else {
            upExpense.add(FixedItemInfo(t, '${txDate.month}.${txDate.day}'));
          }
        } else {
          // Cash or Debit (excluding 'none' ? user wants all non-credit to be cash/debit)
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
      
      if (amountM > 0) {
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
        int amountNext = _sumCardTransactions(acc.id, startNext, todayOnly.isBefore(endNext) ? todayOnly : endNext);
        
        if (amountNext > 0) {
          ongoingCard.add(CardPaymentInfo(
            account: acc, 
            startStr: '${startNext.month}.${startNext.day}', 
            endStr: '진행중', 
            paymentDateStr: '${paymentDateNext.month}.${paymentDateNext.day}', 
            amount: amountNext,
            isFinalized: false
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

    return CardPaymentInfo(
      account: acc, 
      startStr: '${startM.month}.${startM.day}', 
      endStr: '${endM.month}.${endM.day}', 
      paymentDateStr: '${paymentDateM.month}.${paymentDateM.day}', 
      amount: amountM,
      isFinalized: isFinalized
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
  static List<Account> _sampleAccounts() => [];

  static List<Transaction> _sampleTransactions() => [];
}
