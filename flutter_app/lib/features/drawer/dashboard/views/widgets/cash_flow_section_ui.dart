import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_app/features/drawer/dashboard/models/dashboard_summary.dart';
import 'package:flutter_app/features/drawer/dashboard/views/cash_flow_widgets.dart';
import 'package:flutter_app/features/drawer/dashboard/views/expected_asset_card.dart';
import 'package:flutter_app/features/drawer/recurring/views/recurring_expense_section.dart';
import 'package:flutter_app/features/drawer/recurring/views/recurring_income_section.dart';
import 'package:flutter_app/core/theme/app_colors.dart';

class CashFlowSectionUI extends StatelessWidget {
  final DateTime drawerCashFlowDate;
  final DashboardSummary dash;
  final List<String> dashboardItemOrder;
  final String openPanel;
  final void Function(String type, BuildContext context, DashboardSummary dash) onToggleSidePanel;
  final void Function(int oldIndex, int newIndex) onReorder;
  final void Function(int delta) onChangeMonth;

  const CashFlowSectionUI({
    super.key,
    required this.drawerCashFlowDate,
    required this.dash,
    required this.dashboardItemOrder,
    required this.openPanel,
    required this.onToggleSidePanel,
    required this.onReorder,
    required this.onChangeMonth,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(color: AppColors.divider.withOpacity(0.8)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: CashFlowHeaderWidget(
                drawerCashFlowDate: drawerCashFlowDate,
                onChangeMonth: onChangeMonth,
              ),
            ),
            const SizedBox(height: 10),
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              buildDefaultDragHandles: false,
              proxyDecorator: (Widget child, int index, Animation<double> animation) {
                return AnimatedBuilder(
                  animation: animation,
                  builder: (BuildContext context, Widget? _) {
                    final double animValue = Curves.easeOutCubic.transform(animation.value);
                    final double scale = lerpDouble(1.0, 1.03, animValue)!;
                    return Transform.scale(
                      scale: scale,
                      alignment: Alignment.center,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15 * animValue),
                              blurRadius: 14 * animValue,
                              spreadRadius: 1 * animValue,
                              offset: Offset(0, 4 * animValue),
                            ),
                          ],
                        ),
                        child: child,
                      ),
                    );
                  },
                );
              },
              onReorder: onReorder,
              children: dashboardItemOrder.asMap().entries.map((entry) {
                final index = entry.key;
                final itemId = entry.value;
                
                Widget childWidget;
                switch (itemId) {
                  case 'income':
                    childWidget = CashFlowRowWidget(
                      type: 'income',
                      icon: Icons.download, iconBgColor: AppColors.incomeBg, iconColor: const Color(0xFF059669),
                      title: '수입', amount: dash.alreadyReceivedIncome, isExpanded: openPanel == 'income',
                      onTap: () => onToggleSidePanel('income', context, dash),
                    );
                    break;
                  case 'expense':
                    childWidget = CashFlowRowWidget(
                      type: 'expense',
                      icon: Icons.upload, iconBgColor: AppColors.expenseBg, iconColor: AppColors.expense,
                      title: '지출', amount: dash.totalAlreadyPaid, isExpanded: openPanel == 'expense',
                      onTap: () => onToggleSidePanel('expense', context, dash),
                    );
                    break;
                  case 'upcoming_income':
                    childWidget = CashFlowRowWidget(
                      type: 'upcoming_income',
                      icon: Icons.next_plan, iconBgColor: const Color(0xFFFEF3C7), iconColor: const Color(0xFFD97706),
                      title: '예정 수입', amount: dash.totalUpcomingIncome, isExpanded: openPanel == 'upcoming_income',
                      onTap: () => onToggleSidePanel('upcoming_income', context, dash),
                    );
                    break;
                  case 'upcoming_expense':
                    childWidget = CashFlowRowWidget(
                      type: 'upcoming_expense',
                      icon: Icons.event_busy, iconBgColor: const Color(0xFFF3E8FF), iconColor: const Color(0xFF7C3AED),
                      title: '예정 지출', amount: dash.totalUpcomingExpense, isExpanded: openPanel == 'upcoming_expense',
                      onTap: () => onToggleSidePanel('upcoming_expense', context, dash),
                    );
                    break;
                  case 'expected_asset':
                    childWidget = ExpectedAssetCard(
                      drawerCashFlowDate: drawerCashFlowDate,
                    );
                    break;
                  case 'recurring_expense':
                    childWidget = Container(
                      margin: const EdgeInsets.symmetric(vertical: 3.5),
                      child: Column(
                        children: [
                          const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Divider(color: AppColors.background, height: 1)),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: RecurringExpenseSection(drawerCashFlowDate: drawerCashFlowDate),
                          ),
                          const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Divider(color: AppColors.background, height: 1)),
                        ],
                      ),
                    );
                    break;
                  case 'recurring_income':
                    childWidget = Container(
                      margin: const EdgeInsets.symmetric(vertical: 3.5),
                      child: Column(
                        children: [
                          const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Divider(color: AppColors.background, height: 1)),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: RecurringIncomeSection(drawerCashFlowDate: drawerCashFlowDate),
                          ),
                          const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Divider(color: AppColors.background, height: 1)),
                        ],
                      ),
                    );
                    break;
                  default:
                    childWidget = const SizedBox.shrink();
                }

                return ReorderableDelayedDragStartListener(
                  key: ValueKey(itemId),
                  index: index,
                  child: childWidget,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

