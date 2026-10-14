import 'package:flutter/material.dart';
import 'package:flutter_app/features/drawer/dashboard/view_models/dashboard_view_model.dart';
import 'package:flutter_app/features/categories/view_models/category_view_model.dart';
import 'package:flutter_app/features/home/add_transaction/models/transaction.dart';
import 'package:flutter_app/features/asset_detail/models/asset_view_mode.dart';
import 'package:flutter_app/features/asset_detail/models/monthly_asset_data.dart';
import 'package:flutter_app/features/asset_detail/models/category_spending_item.dart';

class AssetDetailViewModel extends ChangeNotifier {
  final DashboardViewModel dashboardVM;
  final CategoryViewModel categoryVM;

  /// 미래 표시 범위 (월별: 36개월, 연도별: 3년)
  static const int _futureMonths = 36;
  static const int _futureYears = 3;

  AssetViewMode _viewMode = AssetViewMode.monthly;
  late DateTime _selectedDate;

  AssetDetailViewModel({
    required this.dashboardVM,
    required this.categoryVM,
  }) {
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, 1);
  }

  AssetViewMode get viewMode => _viewMode;
  DateTime get selectedDate => _selectedDate;
  // 호환성을 위한 게터
  DateTime get selectedMonth => _selectedDate;

  void setViewMode(AssetViewMode mode) {
    if (_viewMode == mode) return;
    _viewMode = mode;
    final now = DateTime.now();
    if (_viewMode == AssetViewMode.monthly) {
      _selectedDate = DateTime(now.year, now.month, 1);
    } else {
      _selectedDate = DateTime(now.year, 1, 1);
    }
    notifyListeners();
  }

  void selectDate(DateTime date) {
    if (_viewMode == AssetViewMode.monthly) {
      _selectedDate = DateTime(date.year, date.month, 1);
    } else {
      _selectedDate = DateTime(date.year, 1, 1);
    }
    notifyListeners();
  }

  void selectMonth(DateTime month) => selectDate(month);

  List<MonthlyAssetData> getDataList() {
    return _viewMode == AssetViewMode.monthly ? _getMonthlyDataList() : _getYearlyDataList();
  }

  List<MonthlyAssetData> getMonthlyDataList() => getDataList();

  MonthlyAssetData getSelectedData() {
    final list = getDataList();
    if (_viewMode == AssetViewMode.monthly) {
      return list.firstWhere(
        (d) => d.date.year == _selectedDate.year && d.date.month == _selectedDate.month,
        orElse: () => list.firstWhere((d) => d.isCurrentMonth, orElse: () => list.first),
      );
    } else {
      return list.firstWhere(
        (d) => d.date.year == _selectedDate.year,
        orElse: () => list.firstWhere((d) => d.date.year == DateTime.now().year, orElse: () => list.first),
      );
    }
  }

  MonthlyAssetData getSelectedMonthData() => getSelectedData();

  // -------------------------------------------------------------
  // 월별 데이터 (과거 첫 거래월 ~ 현재 + 36개월)
  // -------------------------------------------------------------
  List<MonthlyAssetData> _getMonthlyDataList() {
    final now = DateTime.now();
    final flows = _buildMonthlyFlows(
      _earliestMonth(),
      DateTime(now.year, now.month + _futureMonths, 1),
    );

    return flows.map((f) => MonthlyAssetData(
      date: f.month,
      label: '${f.month.month}월',
      fullTitle: '${f.month.year}년 ${f.month.month}월',
      totalAsset: f.endAsset,
      income: f.income,
      expense: f.expense,
      upcomingIncome: f.upcomingIncome,
      upcomingExpense: f.upcomingExpense,
      categorySpendings: _categoryBreakdown(f.transactions, 'expense'),
      categoryIncomes: _categoryBreakdown(f.transactions, 'income'),
    )).toList();
  }

  // -------------------------------------------------------------
  // 연도별 데이터 (과거 첫 거래연도 ~ 현재 + 3년) — 월별 흐름을 연 단위로 합산
  // -------------------------------------------------------------
  List<MonthlyAssetData> _getYearlyDataList() {
    final now = DateTime.now();
    final flows = _buildMonthlyFlows(
      DateTime(_earliestMonth().year, 1, 1),
      DateTime(now.year + _futureYears, 12, 1),
    );

    final byYear = <int, List<_MonthFlow>>{};
    for (final f in flows) {
      byYear.putIfAbsent(f.month.year, () => []).add(f);
    }

    return byYear.entries.map((e) {
      final months = e.value;
      int sum(int Function(_MonthFlow f) pick) => months.fold(0, (s, f) => s + pick(f));
      final txs = months.expand((f) => f.transactions).toList();

      return MonthlyAssetData(
        date: DateTime(e.key, 1, 1),
        label: '${e.key}년',
        fullTitle: '${e.key}년 연간',
        totalAsset: months.last.endAsset, // 연말(12월 말) 자산
        income: sum((f) => f.income),
        expense: sum((f) => f.expense),
        upcomingIncome: sum((f) => f.upcomingIncome),
        upcomingExpense: sum((f) => f.upcomingExpense),
        categorySpendings: _categoryBreakdown(txs, 'expense'),
        categoryIncomes: _categoryBreakdown(txs, 'income'),
      );
    }).toList();
  }

  /// 가장 오래된 거래월 (거래가 없으면 2년 전 1월).
  DateTime _earliestMonth() {
    final now = DateTime.now();
    DateTime earliest = DateTime(now.year - 2, 1, 1);
    for (final t in dashboardVM.transactions) {
      final parts = t.date.split('-');
      if (parts.length < 2) continue;
      final y = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (y == null || m == null) continue;
      final d = DateTime(y, m, 1);
      if (d.isBefore(earliest)) earliest = d;
    }
    return earliest;
  }

  /// [from]~[to] 각 월의 현금흐름과 월말 자산.
  ///
  /// 월말 자산 = 기준점(이번 달 말)에서 앞뒤로 월 순현금흐름을 더하거나 뺀 값.
  ///   이번 달 말 = 현재 자산 + 이번 달 남은 예정 수입 − 예정 지출
  ///   다음 달 말 = 이번 달 말 + 다음 달 순현금흐름
  ///   지난달 말 = 이번 달 말 − 이번 달 순현금흐름
  List<_MonthFlow> _buildMonthlyFlows(DateTime from, DateTime to) {
    final now = DateTime.now();

    final flows = <_MonthFlow>[];
    for (var m = from; !m.isAfter(to); m = DateTime(m.year, m.month + 1, 1)) {
      final s = dashboardVM.getDashboardSummary(m.year, m.month);
      flows.add(_MonthFlow(
        month: m,
        income: s.alreadyReceivedIncome,
        expense: s.totalAlreadyPaid,
        upcomingIncome: s.totalUpcomingIncome,
        upcomingExpense: s.totalUpcomingExpense,
        transactions: dashboardVM.getTransactionsForMonth(m.year, m.month, ignoreDrawerFilter: true),
      ));
    }

    final currentIdx = flows.indexWhere((f) => f.month.year == now.year && f.month.month == now.month);
    if (currentIdx == -1) return flows;

    final current = flows[currentIdx];
    current.endAsset = dashboardVM.getFilteredNetAssets() + current.upcomingIncome - current.upcomingExpense;

    for (int i = currentIdx + 1; i < flows.length; i++) {
      flows[i].endAsset = flows[i - 1].endAsset + flows[i].netFlow;
    }
    for (int i = currentIdx - 1; i >= 0; i--) {
      flows[i].endAsset = flows[i + 1].endAsset - flows[i + 1].netFlow;
    }
    return flows;
  }

  // -------------------------------------------------------------
  // 카테고리별 통계 (거래일 기준 원본 거래를 카테고리로 묶음)
  //   카드로 결제한 소비도 원래 카테고리로 잡히고, 카드대금은 원본 거래가 아니므로 애초에 없다.
  // -------------------------------------------------------------
  List<CategorySpendingItem> _categoryBreakdown(List<Transaction> txs, String type) {
    final Map<String, int> catAmounts = {};
    for (final t in txs) {
      if (t.type != type || t.isSettlement) continue;
      final cat = t.category.isNotEmpty ? t.category : '기타';
      catAmounts[cat] = (catAmounts[cat] ?? 0) + t.amount;
    }

    final total = catAmounts.values.fold(0, (s, v) => s + v);
    if (total == 0) return [];

    final sortedEntries = catAmounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries.map((e) {
      final info = categoryVM.getCategoryInfo(e.key);
      return CategorySpendingItem(
        category: e.key,
        emoji: info.emoji,
        color: info.color,
        amount: e.value,
        percentage: e.value / total,
      );
    }).toList();
  }
}

/// 한 달의 현금흐름 집계와 월말 자산.
class _MonthFlow {
  final DateTime month;
  final int income;
  final int expense;
  final int upcomingIncome;
  final int upcomingExpense;
  final List<Transaction> transactions;
  int endAsset = 0;

  _MonthFlow({
    required this.month,
    required this.income,
    required this.expense,
    required this.upcomingIncome,
    required this.upcomingExpense,
    required this.transactions,
  });

  int get netFlow => (income + upcomingIncome) - (expense + upcomingExpense);
}
