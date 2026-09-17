import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// ============================================================
// CONSTANTS
// ============================================================
const kStorageKeyTx = 'smart_budget_transactions_v5.0';
const kStorageKeyAcc = 'smart_budget_accounts_v5.0';
const kStorageKeyRec = 'smart_budget_recurring_v5.0';

class CategoryInfo {
  final String name;
  final String emoji;
  final Color color;
  final String type; // 'expense' or 'income'
  const CategoryInfo({required this.name, required this.emoji, required this.color, required this.type});
}

const kExpenseCategories = [
  CategoryInfo(name: '식당', emoji: '🍽️', color: Color(0xFFF43F5E), type: 'expense'),
  CategoryInfo(name: '장보기', emoji: '🛒', color: Color(0xFFFB923C), type: 'expense'),
  CategoryInfo(name: '카페/디저트', emoji: '☕', color: Color(0xFFA855F7), type: 'expense'),
  CategoryInfo(name: '교통/차량', emoji: '🚌', color: Color(0xFF06B6D4), type: 'expense'),
  CategoryInfo(name: '문화/쇼핑', emoji: '🎬', color: Color(0xFFEC4899), type: 'expense'),
  CategoryInfo(name: '적금/저축', emoji: '💰', color: Color(0xFF3B82F6), type: 'expense'),
  CategoryInfo(name: '기타', emoji: '📌', color: Color(0xFF64748B), type: 'expense'),
];

const kIncomeCategories = [
  CategoryInfo(name: '수입/월급', emoji: '💵', color: Color(0xFF10B981), type: 'income'),
  CategoryInfo(name: '용돈', emoji: '🎁', color: Color(0xFFF59E0B), type: 'income'),
  CategoryInfo(name: '부수입', emoji: '📈', color: Color(0xFF6366F1), type: 'income'),
  CategoryInfo(name: '상여금', emoji: '🏆', color: Color(0xFF8B5CF6), type: 'income'),
];

CategoryInfo getCategoryInfo(String name) {
  for (final c in kExpenseCategories) {
    if (c.name == name) return c;
  }
  for (final c in kIncomeCategories) {
    if (c.name == name) return c;
  }
  return const CategoryInfo(name: '기타', emoji: '📌', color: Color(0xFF64748B), type: 'expense');
}

// ============================================================
// DATA MODELS
// ============================================================
class Account {
  String id;
  String type; // 'bank', 'card'
  String name;
  String bank;
  String? accountNumber;
  int initialBalance;
  String? cardKind; // 'credit', 'debit'
  int? paymentDay;
  String? linkedBankAccountId;
  String color;

  Account({
    required this.id,
    required this.type,
    required this.name,
    required this.bank,
    this.accountNumber,
    this.initialBalance = 0,
    this.cardKind,
    this.paymentDay,
    this.linkedBankAccountId,
    required this.color,
  });

  bool get isCredit => type == 'card' && cardKind == 'credit';
  bool get isDebit => type == 'card' && cardKind == 'debit';
  bool get isBank => type == 'bank';

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'name': name,
        'bank': bank,
        'accountNumber': accountNumber,
        'initialBalance': initialBalance,
        'cardKind': cardKind,
        'paymentDay': paymentDay,
        'linkedBankAccountId': linkedBankAccountId,
        'color': color,
      };

  factory Account.fromJson(Map<String, dynamic> json) => Account(
        id: json['id'] ?? '',
        type: json['type'] ?? 'bank',
        name: json['name'] ?? '',
        bank: json['bank'] ?? '',
        accountNumber: json['accountNumber'],
        initialBalance: (json['initialBalance'] ?? 0) is int
            ? json['initialBalance']
            : int.tryParse(json['initialBalance'].toString()) ?? 0,
        cardKind: json['cardKind'],
        paymentDay: json['paymentDay'],
        linkedBankAccountId: json['linkedBankAccountId'],
        color: json['color'] ?? '#6366f1',
      );
}

class Transaction {
  String id;
  String date; // YYYY-MM-DD
  String accountId;
  String type; // 'income', 'expense'
  int amount;
  String category;
  String memo;
  String payment;
  bool isRecurring;
  String? recurringId;
  bool isSettlement;

  Transaction({
    required this.id,
    required this.date,
    required this.accountId,
    required this.type,
    required this.amount,
    required this.category,
    this.memo = '',
    this.payment = '',
    this.isRecurring = false,
    this.recurringId,
    this.isSettlement = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'accountId': accountId,
        'type': type,
        'amount': amount,
        'category': category,
        'memo': memo,
        'payment': payment,
        'isRecurring': isRecurring,
        'recurringId': recurringId,
        'isSettlement': isSettlement,
      };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'] ?? '',
        date: json['date'] ?? '',
        accountId: json['accountId'] ?? '',
        type: json['type'] ?? 'expense',
        amount: (json['amount'] ?? 0) is int
            ? json['amount']
            : int.tryParse(json['amount'].toString()) ?? 0,
        category: json['category'] ?? '기타',
        memo: json['memo'] ?? '',
        payment: json['payment'] ?? '',
        isRecurring: json['isRecurring'] ?? false,
        recurringId: json['recurringId'],
        isSettlement: json['isSettlement'] ?? false,
      );
}

// ============================================================
// APP STATE
// ============================================================
class AppState extends ChangeNotifier {
  List<Account> accounts = [];
  List<Transaction> transactions = [];
  DateTime currentDate = DateTime.now();
  String selectedDateStr = _formatDate(DateTime.now());
  List<String> selectedAccountIds = ['all'];
  String drawerFilter = 'all'; // 'all', 'income', 'cash', 'card', 'total_expense'

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
    int income = 0, cash = 0, card = 0;
    for (final t in getTransactionsForMonth(year, month, ignoreDrawerFilter: true)) {
      final acc = accounts.firstWhereOrNull((a) => a.id == t.accountId);
      if (t.type == 'income') {
        income += t.amount;
      } else if (t.type == 'expense') {
        if (acc != null && acc.isCredit) {
          card += t.amount;
        } else {
          cash += t.amount;
        }
      }
    }
    return {'income': income, 'cash': cash, 'card': card, 'total': cash + card};
  }

  int getNetAssets() {
    int bankInitial = 0;
    int bankIncome = 0;
    int bankExpense = 0;

    for (final a in accounts.where((a) => a.isBank)) {
      bankInitial += a.initialBalance;
    }
    for (final t in transactions) {
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
    return transactions.where((t) {
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

  void deleteTransaction(String id) {
    transactions.removeWhere((t) => t.id == id);
    _saveTransactions();
    notifyListeners();
  }

  // ---- Sample data ----
  static List<Account> _sampleAccounts() => [
        Account(id: 'acc_shinhan_bank', type: 'bank', name: '주거래 통장', bank: '신한은행', accountNumber: '110-123-4567', initialBalance: 5420000, color: '#6366f1'),
        Account(id: 'acc_shinhan_card', type: 'card', cardKind: 'credit', name: '신한 쏠 신용카드', bank: '신한카드', paymentDay: 25, linkedBankAccountId: 'acc_shinhan_bank', color: '#8b5cf6'),
        Account(id: 'acc_hyundai_card', type: 'card', cardKind: 'credit', name: '현대 ZERO 카드', bank: '현대카드', paymentDay: 25, linkedBankAccountId: 'acc_shinhan_bank', color: '#ec4899'),
        Account(id: 'acc_toss_bank', type: 'bank', name: '토스 비상금통장', bank: '토스뱅크', accountNumber: '1000-01-23456', initialBalance: 1200000, color: '#3b82f6'),
      ];

  static List<Transaction> _sampleTransactions() {
    const yr = 2026;
    const mo = '09';
    return [
      Transaction(id: 'tx_s1', date: '$yr-$mo-01', accountId: 'acc_shinhan_bank', type: 'expense', amount: 2091, category: '식당', memo: '식비 💰 -2091', payment: '계좌이체'),
      Transaction(id: 'tx_s2', date: '$yr-$mo-01', accountId: 'acc_shinhan_card', type: 'expense', amount: 4500, category: '카페/디저트', memo: 'er, 커피', payment: '신용카드'),
      Transaction(id: 'tx_s5', date: '$yr-$mo-07', accountId: 'acc_shinhan_bank', type: 'expense', amount: 211, category: '식당', memo: '간식 💰 -211', payment: '현금'),
      Transaction(id: 'tx_s6', date: '$yr-$mo-08', accountId: 'acc_toss_bank', type: 'expense', amount: 35000, category: '기타', memo: '이자(마통)', payment: '계좌이체'),
      Transaction(id: 'tx_s9', date: '$yr-$mo-09', accountId: 'acc_shinhan_bank', type: 'expense', amount: 50000, category: '기타', memo: '출금', payment: '현금'),
      Transaction(id: 'tx_s10', date: '$yr-$mo-10', accountId: 'acc_shinhan_bank', type: 'expense', amount: 32000, category: '식당', memo: '저녁 약속', payment: '계좌이체'),
      Transaction(id: 'tx_s12', date: '$yr-$mo-11', accountId: 'acc_shinhan_card', type: 'expense', amount: 18500, category: '교통/차량', memo: '가스비-', payment: '신용카드'),
      Transaction(id: 'tx_s13', date: '$yr-$mo-11', accountId: 'acc_toss_bank', type: 'expense', amount: 17000, category: '문화/쇼핑', memo: '폰(넷플릭스)', payment: '계좌이체'),
      Transaction(id: 'tx_s14', date: '$yr-$mo-11', accountId: 'acc_shinhan_bank', type: 'expense', amount: 45000, category: '식당', memo: '오빠랑 데이트', payment: '계좌이체'),
      Transaction(id: 'tx_s16', date: '$yr-$mo-12', accountId: 'acc_hyundai_card', type: 'expense', amount: 12000, category: '교통/차량', memo: '수도(홀릭)', payment: '신용카드'),
      Transaction(id: 'tx_s18', date: '$yr-$mo-12', accountId: 'acc_shinhan_bank', type: 'expense', amount: 100000, category: '기타', memo: '경호 결혼 13시', payment: '계좌이체'),
      Transaction(id: 'tx_s19', date: '$yr-$mo-14', accountId: 'acc_shinhan_bank', type: 'expense', amount: 2133, category: '식당', memo: '편의점 💰 -2133', payment: '현금'),
      Transaction(id: 'tx_s20', date: '$yr-$mo-14', accountId: 'acc_toss_bank', type: 'expense', amount: 450000, category: '기타', memo: '전월 카드', payment: '계좌이체'),
      Transaction(id: 'tx_s21', date: '$yr-$mo-16', accountId: 'acc_shinhan_bank', type: 'income', amount: 3500000, category: '수입/월급', memo: '9월 급여', payment: '계좌이체'),
      Transaction(id: 'tx_s23', date: '$yr-$mo-18', accountId: 'acc_shinhan_bank', type: 'expense', amount: 40000, category: '식당', memo: '저녁 약속', payment: '계좌이체'),
      Transaction(id: 'tx_s24', date: '$yr-$mo-19', accountId: 'acc_shinhan_card', type: 'expense', amount: 185000, category: '교통/차량', memo: '관리비-', payment: '신용카드'),
      Transaction(id: 'tx_s25', date: '$yr-$mo-19', accountId: 'acc_shinhan_bank', type: 'expense', amount: 35000, category: '문화/쇼핑', memo: '남한산성 데이트', payment: '계좌이체'),
      Transaction(id: 'tx_s26', date: '$yr-$mo-20', accountId: 'acc_shinhan_card', type: 'expense', amount: 23900, category: '교통/차량', memo: '코웨이', payment: '신용카드'),
      Transaction(id: 'tx_s27', date: '$yr-$mo-20', accountId: 'acc_toss_bank', type: 'expense', amount: 55000, category: '기타', memo: '교보(생명)', payment: '계좌이체'),
      Transaction(id: 'tx_s28', date: '$yr-$mo-20', accountId: 'acc_toss_bank', type: 'expense', amount: 120000, category: '기타', memo: '이자(주택)', payment: '계좌이체'),
      Transaction(id: 'tx_s29', date: '$yr-$mo-20', accountId: 'acc_toss_bank', type: 'expense', amount: 500000, category: '적금/저축', memo: '적금-1', payment: '계좌이체'),
      Transaction(id: 'tx_s30', date: '$yr-$mo-21', accountId: 'acc_shinhan_bank', type: 'expense', amount: 14500, category: '교통/차량', memo: '💰 ?? 💳?', payment: '현금'),
      Transaction(id: 'tx_s31', date: '$yr-$mo-21', accountId: 'acc_toss_bank', type: 'expense', amount: 33000, category: '기타', memo: 'SKB(인터넷)', payment: '계좌이체'),
      Transaction(id: 'tx_s32', date: '$yr-$mo-21', accountId: 'acc_toss_bank', type: 'expense', amount: 42000, category: '기타', memo: '메리츠(보험)', payment: '계좌이체'),
      Transaction(id: 'tx_s34', date: '$yr-$mo-24', accountId: 'acc_shinhan_bank', type: 'expense', amount: 58000, category: '교통/차량', memo: '추석 연휴', payment: '계좌이체'),
      Transaction(id: 'tx_s35', date: '$yr-$mo-25', accountId: 'acc_shinhan_card', type: 'expense', amount: 4990, category: '장보기', memo: '쿠팡-09', payment: '신용카드'),
      Transaction(id: 'tx_s36', date: '$yr-$mo-25', accountId: 'acc_shinhan_bank', type: 'expense', amount: 300000, category: '기타', memo: '추석', payment: '계좌이체'),
      Transaction(id: 'tx_s37', date: '$yr-$mo-26', accountId: 'acc_shinhan_bank', type: 'expense', amount: 80000, category: '식당', memo: '추석 연휴', payment: '계좌이체'),
      Transaction(id: 'tx_s38', date: '$yr-$mo-27', accountId: 'acc_toss_bank', type: 'income', amount: 25000, category: '부수입', memo: '러그빼기 거래', payment: '계좌이체'),
      Transaction(id: 'tx_s39', date: '$yr-$mo-28', accountId: 'acc_shinhan_bank', type: 'expense', amount: 68400, category: '장보기', memo: '💰 ??', payment: '현금'),
      Transaction(id: 'tx_s41', date: '$yr-$mo-30', accountId: 'acc_shinhan_card', type: 'expense', amount: 54000, category: '교통/차량', memo: '교통비-', payment: '신용카드'),
      Transaction(id: 'tx_s42', date: '$yr-$mo-30', accountId: 'acc_shinhan_bank', type: 'expense', amount: 15000, category: '식당', memo: '💰 ??', payment: '현금'),
    ];
  }
}

// Extension helper
extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}

// Number formatting helpers
String formatNumber(int n) {
  final s = n.abs().toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

String formatCompactNumber(int n) {
  if (n >= 10000) {
    final man = n ~/ 10000;
    final rem = (n % 10000) ~/ 1000;
    return rem > 0 ? '${man}만${rem}천' : '${man}만';
  } else if (n >= 1000) {
    return '${n ~/ 1000}천';
  }
  return n.toString();
}

Color hexToColor(String hex) {
  final h = hex.replaceAll('#', '');
  return Color(int.parse('FF$h', radix: 16));
}
