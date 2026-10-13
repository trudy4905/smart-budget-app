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
  // 월별 데이터 집계
  // -------------------------------------------------------------
  List<MonthlyAssetData> _getMonthlyDataList() {
    final now = DateTime.now();
    final currentMonthStart = DateTime(now.year, now.month, 1);
    final currentNetAsset = dashboardVM.getFilteredNetAssets();

    // 과거 5개월 ~ 미래 6개월 총 12개월 생성
    final months = <DateTime>[];
    for (int i = -5; i <= 6; i++) {
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

    // 미래 (+1 ~ +6)
    int runningAsset = currentNetAsset;
    for (int i = 1; i <= 6; i++) {
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

    // 과거 (-1 ~ -5)
    int backAsset = currentNetAsset;
    for (int i = -1; i >= -5; i--) {
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
  // 연도별 데이터 집계
  // -------------------------------------------------------------
  List<MonthlyAssetData> _getYearlyDataList() {
    final now = DateTime.now();
    final currentNetAsset = dashboardVM.getFilteredNetAssets();
    // 최근 3개년 ~ 내년 (예: 2024, 2025, 2026, 2027)
    final years = [now.year - 2, now.year - 1, now.year, now.year + 1];

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

      // 해당 연도 말 시점의 총자산 추정치
      int estimatedAsset = currentNetAsset;
      if (year == now.year) {
        // 올해 말 예상 자산: 12월 데이터 기준
        final decData = monthlyList.firstWhere(
          (d) => d.date.year == year && d.date.month == 12,
          orElse: () => monthlyList.last,
        );
        estimatedAsset = decData.totalAsset;
      } else if (year < now.year) {
        final targetDec = DateTime(year, 12, 1);
        final found = monthlyList.firstWhere(
          (d) => d.date.year == targetDec.year && d.date.month == targetDec.month,
          orElse: () => monthlyList.first,
        );
        estimatedAsset = found.totalAsset;
      } else {
        // 미래 연도 말 자산
        final net = (totalIncome + totalUpIncome) - (totalExpense + totalUpExpense);
        estimatedAsset = currentNetAsset + net;
      }

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
  // 카테고리별 소비 및 수입 점유율 계산
  // -------------------------------------------------------------
  List<CategorySpendingItem> _getCategorySpendingsForMonth(int year, int month) {
    final txs = dashboardVM.getTransactionsForMonth(year, month, ignoreDrawerFilter: true);
    final expenseTxs = txs.where((t) => t.type == 'expense').toList();
    return _calculateCategoryBreakdown(expenseTxs);
  }

  List<CategorySpendingItem> _getCategoryIncomesForMonth(int year, int month) {
    final txs = dashboardVM.getTransactionsForMonth(year, month, ignoreDrawerFilter: true);
    final incomeTxs = txs.where((t) => t.type == 'income').toList();
    return _calculateCategoryBreakdown(incomeTxs);
  }

  List<CategorySpendingItem> _getCategorySpendingsForYear(int year) {
    final allTxs = <dynamic>[];
    for (int m = 1; m <= 12; m++) {
      final txs = dashboardVM.getTransactionsForMonth(year, m, ignoreDrawerFilter: true);
      allTxs.addAll(txs.where((t) => t.type == 'expense'));
    }
    return _calculateCategoryBreakdown(allTxs);
  }

  List<CategorySpendingItem> _getCategoryIncomesForYear(int year) {
    final allTxs = <dynamic>[];
    for (int m = 1; m <= 12; m++) {
      final txs = dashboardVM.getTransactionsForMonth(year, m, ignoreDrawerFilter: true);
      allTxs.addAll(txs.where((t) => t.type == 'income'));
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
