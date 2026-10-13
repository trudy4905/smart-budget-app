import 'package:flutter/material.dart';
import 'package:flutter_app/features/drawer/dashboard/view_models/dashboard_view_model.dart';
import 'package:flutter_app/features/asset_detail/models/monthly_asset_data.dart';

class AssetDetailViewModel extends ChangeNotifier {
  final DashboardViewModel dashboardVM;
  late DateTime _selectedMonth;

  AssetDetailViewModel(this.dashboardVM) {
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month, 1);
  }

  DateTime get selectedMonth => _selectedMonth;

  void selectMonth(DateTime month) {
    _selectedMonth = DateTime(month.year, month.month, 1);
    notifyListeners();
  }

  /// 과거 5개월 ~ 미래 6개월 총 12개월치의 월별 자산 및 현금 흐름 데이터 생성
  List<MonthlyAssetData> getMonthlyDataList() {
    final now = DateTime.now();
    final currentMonthStart = DateTime(now.year, now.month, 1);
    final currentNetAsset = dashboardVM.getFilteredNetAssets();

    // 12개월 생성 (-5개월 ~ +6개월)
    final months = <DateTime>[];
    for (int i = -5; i <= 6; i++) {
      int y = now.year;
      int m = now.month + i;
      while (m < 1) {
        m += 12;
        y--;
      }
      while (m > 12) {
        m -= 12;
        y++;
      }
      months.add(DateTime(y, m, 1));
    }

    // 각 월별 DashboardSummary 추출
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

    // 미래 월과 과거 월의 예상 총 자산 누적 계산
    final assetMap = <DateTime, int>{};
    assetMap[currentMonthStart] = currentNetAsset;

    // 미래 누적 (+1 ~ +6)
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

    // 과거 역산 (-1 ~ -5)
    int backAsset = currentNetAsset;
    for (int i = -1; i >= -5; i--) {
      int y = now.year;
      int m = now.month + i;
      while (m < 1) { m += 12; y--; }
      while (m > 12) { m -= 12; y++; }
      final target = DateTime(y, m, 1);
      
      // 해당 월의 순흐름 역산
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
      return MonthlyAssetData(
        month: m,
        totalAsset: assetMap[m] ?? currentNetAsset,
        income: s['income']!,
        expense: s['expense']!,
        upcomingIncome: s['upIncome']!,
        upcomingExpense: s['upExpense']!,
      );
    }).toList();
  }

  MonthlyAssetData getSelectedMonthData() {
    final list = getMonthlyDataList();
    return list.firstWhere(
      (d) => d.month.year == _selectedMonth.year && d.month.month == _selectedMonth.month,
      orElse: () => list.firstWhere(
        (d) => d.isCurrentMonth,
        orElse: () => list.first,
      ),
    );
  }
}
