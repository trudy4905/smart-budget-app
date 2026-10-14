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

  // -------------------------------------------------------------
  // 공통 헬퍼
  // -------------------------------------------------------------
  DateTime _clampDate(int year, int month, int day) {
    int y = year;
    int m = month;
    while (m < 1) { m += 12; y--; }
    while (m > 12) { m -= 12; y++; }
    final lastDay = DateTime(y, m + 1, 0).day;
    final d = day > lastDay ? lastDay : day;
    return DateTime(y, m, d);
  }

  DateTime get _todayOnly {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime? _parseDate(String dateStr) {
    final parts = dateStr.split('-');
    if (parts.length < 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  String _mmdd(DateTime d) => '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';

  String _ymd(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  bool _isAccountSelected(String accountId) =>
      selectedAccountIds.contains('all') || selectedAccountIds.contains(accountId);

  bool isTransactionMatchingSelection(Transaction t, {bool ignoreDrawerFilter = false}) {
    if (!_isAccountSelected(t.accountId)) return false;
    if (!ignoreDrawerFilter && drawerFilter != 'all') {
      if (drawerFilter == 'income' && t.type != 'income') return false;
      if (drawerFilter == 'expense' && t.type != 'expense') return false;
    }
    return true;
  }

  // -------------------------------------------------------------
  // 카드 결제 주기 (카드 계산의 유일한 기준)
  // -------------------------------------------------------------
  /// [card]의 [year]년 [month]월 결제분: 이용 기간(start~end)과 결제일.
  _BillingCycle _billingCycle(Account card, int year, int month) {
    return _BillingCycle(
      start: _clampDate(year, month + (card.billingStartMonth ?? -1), card.billingStartDay ?? 1),
      end: _clampDate(year, month + (card.billingEndMonth ?? -1), card.billingEndDay ?? 31),
      paymentDate: _clampDate(year, month, card.paymentDay ?? 25),
    );
  }

  /// 이용 기간 내 카드 사용액 합계.
  int _sumCardTransactions(String cardId, DateTime start, DateTime end) {
    if (!_isAccountSelected(cardId)) return 0;
    int sum = 0;
    for (final t in transactions) {
      if (t.accountId != cardId || t.type != 'expense') continue;
      final txDate = _parseDate(t.date);
      if (txDate == null) continue;
      if (!txDate.isBefore(start) && !txDate.isAfter(end)) sum += t.amount;
    }
    return sum;
  }

  /// [acc]의 [year]년 [month]월 결제 청구 정보.
  CardPaymentInfo getCardPaymentInfo(Account acc, int year, int month) {
    final cycle = _billingCycle(acc, year, month);

    final recurringTxs = transactions.where((t) {
      if (t.accountId != acc.id || !t.isRecurring || t.type != 'expense') return false;
      final txDate = _parseDate(t.date);
      return txDate != null && cycle.contains(txDate);
    }).toList();

    return CardPaymentInfo(
      account: acc,
      startStr: _mmdd(cycle.start),
      endStr: _mmdd(cycle.end),
      paymentDateStr: _mmdd(cycle.paymentDate),
      amount: _sumCardTransactions(acc.id, cycle.start, cycle.end),
      isFinalized: _todayOnly.isAfter(cycle.end),
      recurringTxs: recurringTxs,
    );
  }

  // -------------------------------------------------------------
  // 거래 조회 (원본 거래만 반환)
  // -------------------------------------------------------------
  /// 달력 표시용: 실제 거래 + 결제일의 카드대금 일정.
  /// 카드대금 일정은 화면 표시 전용이며 어떤 집계에도 사용하지 않는다.
  List<Transaction> getTransactionsForDate(String dateStr) {
    final date = _parseDate(dateStr);
    if (date == null) return [];

    final realTxs = transactions.where((t) => t.date == dateStr && isTransactionMatchingSelection(t));
    final billEvents = _cardBillEvents(date.year, date.month)
        .where((t) => t.date == dateStr && isTransactionMatchingSelection(t));

    return [...realTxs, ...billEvents];
  }

  List<Transaction> _cardBillEvents(int year, int month) {
    final events = <Transaction>[];
    for (final card in accounts.where((a) => a.isCredit)) {
      final bill = getCardPaymentInfo(card, year, month);
      if (bill.amount <= 0) continue;
      final paymentDate = _billingCycle(card, year, month).paymentDate;
      events.add(Transaction(
        id: 'cardbill_${card.id}_${year}_$month',
        date: _ymd(paymentDate),
        accountId: card.linkedBankAccountId ?? card.id,
        type: 'expense',
        amount: bill.amount,
        category: '${card.name} 대금',
        memo: '카드대금 자동계산',
        isSettlement: true, // 삭제 버튼 숨김 & 집계 제외
      ));
    }
    return events;
  }

  /// 해당 월의 원본 거래 (카드대금 등 가상 항목 없음).
  List<Transaction> getTransactionsForMonth(int year, int month, {bool ignoreDrawerFilter = false}) {
    return transactions.where((t) {
      final txDate = _parseDate(t.date);
      return txDate != null &&
          txDate.year == year &&
          txDate.month == month &&
          isTransactionMatchingSelection(t, ignoreDrawerFilter: ignoreDrawerFilter);
    }).toList();
  }

  /// 소비 기준 월 합계 (거래일 기준, 카드 사용분 포함).
  Map<String, int> getMonthlySummary(int year, int month) {
    int income = 0;
    int expense = 0;
    for (final t in getTransactionsForMonth(year, month, ignoreDrawerFilter: true)) {
      if (t.isSettlement) continue;
      if (t.type == 'income') income += t.amount;
      if (t.type == 'expense') expense += t.amount;
    }
    return {'income': income, 'expense': expense};
  }

  // -------------------------------------------------------------
  // 현금흐름 요약
  //   수입 = 해당 월 수입 거래
  //   지출 = 은행·체크 지출 + 결제일이 해당 월인 카드 청구액
  //   오늘 이전/이후로 '완료'와 '예정'을 나눈다.
  // -------------------------------------------------------------
  DashboardSummary getDashboardSummary(int year, int month) {
    final today = _todayOnly;

    int receivedIncome = 0;
    final receivedIncomeList = <Transaction>[];
    final upIncome = <FixedItemInfo>[];
    int cashDebitPaid = 0;
    final cashDebitPaidList = <Transaction>[];
    int fixedPaid = 0;
    final fixedPaidList = <Transaction>[];
    final upExpense = <FixedItemInfo>[];

    // 1. 수입 / 은행·체크 지출
    for (final t in getTransactionsForMonth(year, month, ignoreDrawerFilter: true)) {
      if (t.isSettlement) continue;
      final txDate = _parseDate(t.date);
      if (txDate == null) continue;
      final isDone = !txDate.isAfter(today);

      if (t.type == 'income') {
        if (isDone) {
          receivedIncome += t.amount;
          receivedIncomeList.add(t);
        } else {
          upIncome.add(FixedItemInfo(t, _mmdd(txDate)));
        }
        continue;
      }

      if (t.type != 'expense') continue;

      // 신용카드 사용분은 아래 2단계에서 결제일 청구액으로 반영한다.
      final acc = accounts.firstWhereOrNull((a) => a.id == t.accountId);
      if (acc != null && acc.isCredit) continue;

      if (!isDone) {
        upExpense.add(FixedItemInfo(t, _mmdd(txDate)));
      } else if (t.isRecurring) {
        fixedPaid += t.amount;
        fixedPaidList.add(t);
      } else {
        cashDebitPaid += t.amount;
        cashDebitPaidList.add(t);
      }
    }

    // 2. 신용카드 청구액 (결제일 기준)
    int cardPaid = 0;
    final paidCardList = <CardPaymentInfo>[];
    final upCard = <CardPaymentInfo>[];
    final ongoingCard = <CardPaymentInfo>[];
    final isCurrentMonth = year == today.year && month == today.month;

    for (final acc in accounts.where((a) => a.isCredit)) {
      if (!_isAccountSelected(acc.id)) continue;

      final bill = getCardPaymentInfo(acc, year, month);
      if (!_billingCycle(acc, year, month).paymentDate.isAfter(today)) {
        cardPaid += bill.amount;
        paidCardList.add(bill);
      } else {
        upCard.add(bill);
      }

      // 이번 달이면 다음 달 결제분(현재 누적중)도 함께 제공
      if (isCurrentMonth) {
        ongoingCard.add(getCardPaymentInfo(acc, year, month + 1));
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

  /// 카드 거래가 [upToDate]까지 결제(은행 출금) 완료되었는지.
  bool _isCardTransactionSettled(Account card, DateTime txDate, DateTime upToDate) {
    // 거래일 기준 전월~3개월 뒤 결제분 중 이용 기간에 포함되는 주기를 찾는다.
    for (int offset = -1; offset <= 3; offset++) {
      final cycle = _billingCycle(card, txDate.year, txDate.month + offset);
      if (cycle.contains(txDate)) {
        return !cycle.paymentDate.isAfter(upToDate);
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

/// 카드 한 번의 결제 주기: 이용 기간(start~end)과 결제일.
class _BillingCycle {
  final DateTime start;
  final DateTime end;
  final DateTime paymentDate;

  const _BillingCycle({required this.start, required this.end, required this.paymentDate});

  bool contains(DateTime date) => !date.isBefore(start) && !date.isAfter(end);
}
