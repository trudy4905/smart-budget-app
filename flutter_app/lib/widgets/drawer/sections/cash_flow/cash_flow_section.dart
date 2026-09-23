import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/app_state.dart';
import 'cash_flow_widgets.dart';
import '../assets/expected_asset_card.dart';
import 'recurring/recurring_expense_section.dart';
import 'recurring/recurring_income_section.dart';
import 'drawer_side_panel.dart';

class CashFlowSection extends StatefulWidget {
  const CashFlowSection({super.key});

  @override
  State<CashFlowSection> createState() => _CashFlowSectionState();
}

class _CashFlowSectionState extends State<CashFlowSection> {
  DateTime _drawerCashFlowDate = DateTime.now();
  String _openPanel = '';

  void _toggleSidePanel(String type, BuildContext context, DashboardSummary dash) {
    setState(() {
      _openPanel = type;
    });

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.3),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.height * 0.2),
            child: Material(
              color: Colors.transparent,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.5,
                  child: DrawerSidePanel(dash: dash, openPanelType: type),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic)),
          child: child,
        );
      },
    ).then((_) {
      if (mounted) {
        setState(() {
          _openPanel = '';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final dash = state.getDashboardSummary(_drawerCashFlowDate.year, _drawerCashFlowDate.month);

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
                    drawerCashFlowDate: _drawerCashFlowDate,
                    onChangeMonth: (delta) {
                      setState(() {
                        _drawerCashFlowDate = DateTime(_drawerCashFlowDate.year, _drawerCashFlowDate.month + delta, 1);
                        _openPanel = '';
                      });
                    },
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
                  onReorder: (oldIndex, newIndex) {
                    state.reorderDashboardItems(oldIndex, newIndex);
                  },
                  children: state.dashboardItemOrder.asMap().entries.map((entry) {
                    final index = entry.key;
                    final itemId = entry.value;
                    
                    Widget childWidget;
                    switch (itemId) {
                      case 'income':
                        childWidget = CashFlowRowWidget(
                          type: 'income',
                          icon: Icons.download, iconBgColor: const Color(0xFFECFDF5), iconColor: const Color(0xFF059669),
                          title: '수입', amount: dash.alreadyReceivedIncome, isExpanded: _openPanel == 'income',
                          onTap: () => _toggleSidePanel('income', context, dash),
                        );
                        break;
                      case 'expense':
                        childWidget = CashFlowRowWidget(
                          type: 'expense',
                          icon: Icons.upload, iconBgColor: const Color(0xFFFFF1F2), iconColor: const Color(0xFFE11D48),
                          title: '지출', amount: dash.totalAlreadyPaid, isExpanded: _openPanel == 'expense',
                          onTap: () => _toggleSidePanel('expense', context, dash),
                        );
                        break;
                      case 'upcoming_income':
                        childWidget = CashFlowRowWidget(
                          type: 'upcoming_income',
                          icon: Icons.next_plan, iconBgColor: const Color(0xFFFEF3C7), iconColor: const Color(0xFFD97706),
                          title: '예정 수입', amount: dash.totalUpcomingIncome, isExpanded: _openPanel == 'upcoming_income',
                          onTap: () => _toggleSidePanel('upcoming_income', context, dash),
                        );
                        break;
                      case 'upcoming_expense':
                        childWidget = CashFlowRowWidget(
                          type: 'upcoming_expense',
                          icon: Icons.event_busy, iconBgColor: const Color(0xFFF3E8FF), iconColor: const Color(0xFF7C3AED),
                          title: '예정 지출', amount: dash.totalUpcomingExpense, isExpanded: _openPanel == 'upcoming_expense',
                          onTap: () => _toggleSidePanel('upcoming_expense', context, dash),
                        );
                        break;
                      case 'expected_asset':
                        childWidget = ExpectedAssetCard(
                          drawerCashFlowDate: _drawerCashFlowDate,
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
                                child: RecurringExpenseSection(drawerCashFlowDate: _drawerCashFlowDate),
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
                                child: RecurringIncomeSection(drawerCashFlowDate: _drawerCashFlowDate),
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
      },
    );
  }
}
