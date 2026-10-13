class MonthlyAssetData {
  final DateTime month;
  final int totalAsset;
  final int income;
  final int expense;
  final int upcomingIncome;
  final int upcomingExpense;

  const MonthlyAssetData({
    required this.month,
    required this.totalAsset,
    required this.income,
    required this.expense,
    required this.upcomingIncome,
    required this.upcomingExpense,
  });

  int get totalIncome => income + upcomingIncome;
  int get totalExpense => expense + upcomingExpense;
  int get netFlow => totalIncome - totalExpense;

  bool get isCurrentMonth {
    final now = DateTime.now();
    return month.year == now.year && month.month == now.month;
  }

  bool get isFutureMonth {
    final now = DateTime.now();
    return month.year > now.year || (month.year == now.year && month.month > now.month);
  }
}
