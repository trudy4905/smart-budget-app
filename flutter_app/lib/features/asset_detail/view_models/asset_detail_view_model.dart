import 'package:flutter/material.dart';
import 'package:flutter_app/features/drawer/dashboard/view_models/dashboard_view_model.dart';
import 'package:flutter_app/features/categories/view_models/category_view_model.dart';
import 'package:flutter_app/features/asset_detail/models/asset_view_mode.dart';
import 'package:flutter_app/features/asset_detail/models/monthly_asset_data.dart';
import 'package:flutter_app/features/asset_detail/models/category_spending_item.dart';

class AssetDetailViewModel extends ChangeNotifier {
  final DashboardViewModel dashboardVM;
  final CategoryViewModel categoryVM;

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
  // 월별 데이터 집계 (과거 전체 ~ 미래 3년치)
  // -------------------------------------------------------------
  List<MonthlyAssetData> _getMonthlyDataList() {
    final now = DateTime.now();
    final currentMonthStart = DateTime(now.year, now.month, 1);
    final currentNetAsset = dashboardVM.getFilteredNetAssets();

    // 1. 가장 과거 거래 일자 탐색 (기본값: 최소 2년 전)
    DateTime earliest = DateTime(now.year - 2, 1, 1);
    for (final t in dashboardVM.transactions) {
      final parts = t.date.split('-');
      if (parts.length >= 3) {
        final y = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        if (y != null && m != null) {
          final d = DateTime(y, m, 1);
          if (d.isBefore(earliest)) {
            earliest = d;
          }
        }
      }
    }

    // 과거 개월 수 및 미래 3년(36개월) 계산
    final pastMonthsCount = (now.year * 12 + now.month) - (earliest.year * 12 + earliest.month);
    const futureMonthsCount = 36; // 미래 3년치

    final months = <DateTime>[];
    for (int i = -pastMonthsCount; i <= futureMonthsCount; i++) {
      int y = now.year;
      int m = now.month + i;
      while (m < 1) { m += 12; y--; }
      while (m > 12) { m -= 12; y++; }
      months.add(DateTime(y, m, 1));
    }

    final summaries = <DateTime, Map<String, int>>{};
    for (final m in months) {
      final summary = dashboardVM.getDashboardSummary(m.year, m.month);
      summaries[m] = {
        'income': summary.alreadyReceivedIncome,
        'expense': summary.totalAlreadyPaid,
        'upIncome': summary.totalUpcomingIncome,
        'upExpense': summary.totalUpcomingExpense,
      };
    }

    // 자산 누적 계산
    final assetMap = <DateTime, int>{};
    assetMap[currentMonthStart] = currentNetAsset;

    // 미래 (+1 ~ +36)
    int runningAsset = currentNetAsset;
    for (int i = 1; i <= futureMonthsCount; i++) {
      int y = now.year;
      int m = now.month + i;
      while (m < 1) { m += 12; y--; }
      while (m > 12) { m -= 12; y++; }
      final target = DateTime(y, m, 1);
      final data = summaries[target]!;
      final net = (data['income']! + data['upIncome']!) - (data['expense']! + data['upExpense']!);
      runningAsset += net;
      assetMap[target] = runningAsset;
    }

    // 과거 (-1 ~ -pastMonthsCount)
    int backAsset = currentNetAsset;
    for (int i = -1; i >= -pastMonthsCount; i--) {
      int y = now.year;
      int m = now.month + i;
      while (m < 1) { m += 12; y--; }
      while (m > 12) { m -= 12; y++; }
      final target = DateTime(y, m, 1);

      int prevY = now.year;
      int prevM = now.month + i + 1;
      while (prevM < 1) { prevM += 12; prevY--; }
      while (prevM > 12) { prevM -= 12; prevY++; }
      final nextMonthOfTarget = DateTime(prevY, prevM, 1);
      final nextData = summaries[nextMonthOfTarget]!;
      final nextNet = (nextData['income']! + nextData['upIncome']!) - (nextData['expense']! + nextData['upExpense']!);
      backAsset -= nextNet;
      assetMap[target] = backAsset;
    }

    return months.map((m) {
      final s = summaries[m]!;
      final catSpendings = _getCategorySpendingsForMonth(m.year, m.month);
      final catIncomes = _getCategoryIncomesForMonth(m.year, m.month);

      return MonthlyAssetData(
        date: m,
        label: '${m.month}월',
        fullTitle: '${m.year}년 ${m.month}월',
        totalAsset: assetMap[m] ?? currentNetAsset,
        income: s['income']!,
        expense: s['expense']!,
        upcomingIncome: s['upIncome']!,
        upcomingExpense: s['upExpense']!,
        categorySpendings: catSpendings,
        categoryIncomes: catIncomes,
      );
    }).toList();
  }

  // -------------------------------------------------------------
  // 연도별 데이터 집계 (과거 전체 ~ 미래 3년치)
  // -------------------------------------------------------------
  List<MonthlyAssetData> _getYearlyDataList() {
    final now = DateTime.now();

    // 가장 과거 연도 탐색
    int startYear = now.year - 2;
    for (final t in dashboardVM.transactions) {
      final parts = t.date.split('-');
      if (parts.isNotEmpty) {
        final y = int.tryParse(parts[0]);
        if (y != null && y < startYear) {
          startYear = y;
        }
      }
    }

    // 과거 전체 연도 ~ 미래 3개년 (now.year + 3)
    final years = <int>[];
    for (int y = startYear; y <= now.year + 3; y++) {
      years.add(y);
    }

    final monthlyList = _getMonthlyDataList();

    return years.map((year) {
      int totalIncome = 0;
      int totalExpense = 0;
      int totalUpIncome = 0;
      int totalUpExpense = 0;

      for (int m = 1; m <= 12; m++) {
        final summary = dashboardVM.getDashboardSummary(year, m);
        totalIncome += summary.alreadyReceivedIncome;
        totalExpense += summary.totalAlreadyPaid;
        totalUpIncome += summary.totalUpcomingIncome;
        totalUpExpense += summary.totalUpcomingExpense;
      }

      // 해당 연도 12월 시점의 총자산 추정치
      final decData = monthlyList.firstWhere(
        (d) => d.date.year == year && d.date.month == 12,
        orElse: () => monthlyList.last,
      );
      final estimatedAsset = decData.totalAsset;

      final catSpendings = _getCategorySpendingsForYear(year);
      final catIncomes = _getCategoryIncomesForYear(year);

      return MonthlyAssetData(
        date: DateTime(year, 1, 1),
        label: '$year년',
        fullTitle: '$year년 연간',
        totalAsset: estimatedAsset,
        income: totalIncome,
        expense: totalExpense,
        upcomingIncome: totalUpIncome,
        upcomingExpense: totalUpExpense,
        categorySpendings: catSpendings,
        categoryIncomes: catIncomes,
      );
    }).toList();
  }

  // -------------------------------------------------------------
  // 카테고리별 소비 및 수입 점유율 계산 (카드 대금 등 결제 수단 정산은 제외하고 실제 소비 카테고리만 집계)
  // -------------------------------------------------------------
  bool _isRealExpense(dynamic t) {
    if (t.type != 'expense') return false;

    // 1. 가상 카드 대금 정산 거래 (virtual_로 시작) 제외
    final id = t.id as String? ?? '';
    if (id.startsWith('virtual_')) return false;

    // 2. 정산(isSettlement) 플래그 거래 제외
    if (t.isSettlement == true) return false;

    // 3. 메모에 '카드대금'이 포함된 정산 거래 제외
    final memo = t.memo as String? ?? '';
    if (memo.contains('카드대금')) return false;

    // 4. 카테고리가 카드 대금/정산 관련인 경우 제외 (카드 대금은 결제 수단 정산임)
    final cat = (t.category as String? ?? '').trim();
    if (cat.endsWith('대금') ||
        cat.endsWith('예정대금') ||
        cat.contains('카드대금') ||
        cat.contains('카드 대금')) {
      return false;
    }

    return true;
  }

  bool _isRealIncome(dynamic t) {
    if (t.type != 'income') return false;
    final id = t.id as String? ?? '';
    if (id.startsWith('virtual_')) return false;
    if (t.isSettlement == true) return false;
    return true;
  }

  List<CategorySpendingItem> _getCategorySpendingsForMonth(int year, int month) {
    final txs = dashboardVM.getTransactionsForMonth(year, month, ignoreDrawerFilter: true);
    final expenseTxs = txs.where((t) => _isRealExpense(t)).toList();
    return _calculateCategoryBreakdown(expenseTxs);
  }

  List<CategorySpendingItem> _getCategoryIncomesForMonth(int year, int month) {
    final txs = dashboardVM.getTransactionsForMonth(year, month, ignoreDrawerFilter: true);
    final incomeTxs = txs.where((t) => _isRealIncome(t)).toList();
    return _calculateCategoryBreakdown(incomeTxs);
  }

  List<CategorySpendingItem> _getCategorySpendingsForYear(int year) {
    final allTxs = <dynamic>[];
    for (int m = 1; m <= 12; m++) {
      final txs = dashboardVM.getTransactionsForMonth(year, m, ignoreDrawerFilter: true);
      allTxs.addAll(txs.where((t) => _isRealExpense(t)));
    }
    return _calculateCategoryBreakdown(allTxs);
  }

  List<CategorySpendingItem> _getCategoryIncomesForYear(int year) {
    final allTxs = <dynamic>[];
    for (int m = 1; m <= 12; m++) {
      final txs = dashboardVM.getTransactionsForMonth(year, m, ignoreDrawerFilter: true);
      allTxs.addAll(txs.where((t) => _isRealIncome(t)));
    }
    return _calculateCategoryBreakdown(allTxs);
  }

  List<CategorySpendingItem> _calculateCategoryBreakdown(List<dynamic> txs) {
    if (txs.isEmpty) return [];

    final Map<String, int> catAmounts = {};
    int total = 0;

    for (final t in txs) {
      final cat = (t.category != null && (t.category as String).isNotEmpty) ? (t.category as String) : '기타';
      final amt = (t.amount as int);
      catAmounts[cat] = (catAmounts[cat] ?? 0) + amt;
      total += amt;
    }

    if (total == 0) return [];

    final sortedEntries = catAmounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries.map((e) {
      final info = categoryVM.getCategoryInfo(e.key);
      final pct = e.value / total;
      return CategorySpendingItem(
        category: e.key,
        emoji: info.emoji,
        color: info.color,
        amount: e.value,
        percentage: pct,
      );
    }).toList();
  }
}
