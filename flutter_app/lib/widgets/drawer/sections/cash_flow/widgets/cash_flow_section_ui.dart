import 'package:flutter/material.dart';
import '../../../../providers/app_state.dart';
import 'summary/cash_flow_widgets.dart';
import 'expected_asset/expected_asset_card.dart';
import 'recurring/recurring_expense_section.dart';
import 'recurring/recurring_income_section.dart';

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
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
              child: CashFlowHeaderWidget(
                drawerCashFlowDate: drawerCashFlowDate,
                onChangeMonth: onChangeMonth,
              ),
            ),
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              buildDefaultDragHandles: false,
              proxyDecorator: (Widget child, int index, Animation<double> animation) {
                return Material(
                  elevation: 6,
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(16),
                  child: child,
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
                      icon: Icons.download, iconBgColor: const Color(0xFFECFDF5), iconColor: const Color(0xFF059669),
                      title: '수입', amount: dash.alreadyReceivedIncome, isExpanded: openPanel == 'income',
                      onTap: () => onToggleSidePanel('income', context, dash),
                    );
                    break;
                  case 'expense':
                    childWidget = CashFlowRowWidget(
                      type: 'expense',
                      icon: Icons.upload, iconBgColor: const Color(0xFFFFF1F2), iconColor: const Color(0xFFE11D48),
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
                      margin: const EdgeInsets.only(bottom: 4),
                      child: Column(
                        children: [
                          const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Divider(color: Color(0xFFF1F5F9), height: 1)),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: RecurringExpenseSection(drawerCashFlowDate: drawerCashFlowDate),
                          ),
                          const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Divider(color: Color(0xFFF1F5F9), height: 1)),
                        ],
                      ),
                    );
                    break;
                  case 'recurring_income':
                    childWidget = Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      child: Column(
                        children: [
                          const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Divider(color: Color(0xFFF1F5F9), height: 1)),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: RecurringIncomeSection(drawerCashFlowDate: drawerCashFlowDate),
                          ),
                          const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Divider(color: Color(0xFFF1F5F9), height: 1)),
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
