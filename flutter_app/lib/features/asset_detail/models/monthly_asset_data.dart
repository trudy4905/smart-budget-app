import 'package:flutter_app/features/asset_detail/models/category_spending_item.dart';

class MonthlyAssetData {
  final DateTime date;
  final String label; // "10월" 또는 "2026년"
  final String fullTitle; // "2026년 10월" 또는 "2026년 연간"
  final int totalAsset;
  final int income;
  final int expense;
  final int upcomingIncome;
  final int upcomingExpense;
  final List<CategorySpendingItem> categorySpendings;
  final List<CategorySpendingItem> categoryIncomes;

  const MonthlyAssetData({
    required this.date,
    required this.label,
    required this.fullTitle,
    required this.totalAsset,
    required this.income,
    required this.expense,
    required this.upcomingIncome,
    required this.upcomingExpense,
    this.categorySpendings = const [],
    this.categoryIncomes = const [],
  });

  // 호환성을 위한 게터
  DateTime get month => date;

  int get totalIncome => income + upcomingIncome;
  int get totalExpense => expense + upcomingExpense;
  int get netFlow => totalIncome - totalExpense;

  bool get isCurrentMonth {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  bool get isFutureMonth {
    final now = DateTime.now();
    return date.year > now.year || (date.year == now.year && date.month > now.month);
  }
}
