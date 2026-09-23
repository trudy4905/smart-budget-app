import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import 'components/drawer_header.dart';
import 'sections/assets/asset_summary_card.dart';
import 'sections/cash_flow/cash_flow_widgets.dart';
import 'sections/assets/expected_asset_card.dart';
import 'sections/recurring/recurring_expense_section.dart';
import 'sections/recurring/recurring_income_section.dart';
import 'sections/accounts/accounts_section.dart';
import 'components/drawer_side_panel.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  DateTime _drawerCashFlowDate = DateTime.now();
  String _openPanel = ''; // 'income', 'expense', 'upcoming_income', 'upcoming_expense'

  void _toggleSidePanel(String type) {
    setState(() {
      if (_openPanel == type) {
        _openPanel = '';
      } else {
        _openPanel = type;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSideListOpen = _openPanel.isNotEmpty;

    return Consumer<AppState>(
      builder: (context, state, _) {
        final dash = state.getDashboardSummary(_drawerCashFlowDate.year, _drawerCashFlowDate.month);

        return Drawer(
          width: MediaQuery.of(context).size.width * 0.85,
          backgroundColor: const Color(0xFFF8FAFC),
          child: SafeArea(
            child: Stack(
              children: [
                GestureDetector(
                  onTap: () {
                    if (isSideListOpen) {
                      setState(() => _openPanel = '');
                    }
                  },
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.85,
                    child: Column(
                      children: [
                        const DrawerHeaderWidget(),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                const AssetSummaryCard(),
                                // Cash flow section
                                Padding(
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
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                          child: Column(
                                            children: [
                                              CashFlowRowWidget(
                                                type: 'income',
                                                icon: Icons.download, iconBgColor: const Color(0xFFECFDF5), iconColor: const Color(0xFF059669),
                                                title: '수입', amount: dash.alreadyReceivedIncome, isExpanded: _openPanel == 'income',
                                                onTap: () => _toggleSidePanel('income'),
                                              ),
                                              CashFlowRowWidget(
                                                type: 'expense',
                                                icon: Icons.upload, iconBgColor: const Color(0xFFFFF1F2), iconColor: const Color(0xFFE11D48),
                                                title: '지출', amount: dash.totalAlreadyPaid, isExpanded: _openPanel == 'expense',
                                                onTap: () => _toggleSidePanel('expense'),
                                              ),
                                              CashFlowRowWidget(
                                                type: 'upcoming_income',
                                                icon: Icons.next_plan, iconBgColor: const Color(0xFFFEF3C7), iconColor: const Color(0xFFD97706),
                                                title: '예정 수입', amount: dash.totalUpcomingIncome, isExpanded: _openPanel == 'upcoming_income',
                                                onTap: () => _toggleSidePanel('upcoming_income'),
                                              ),
                                              CashFlowRowWidget(
                                                type: 'upcoming_expense',
                                                icon: Icons.event_busy, iconBgColor: const Color(0xFFF3E8FF), iconColor: const Color(0xFF7C3AED),
                                                title: '예정 지출', amount: dash.totalUpcomingExpense, isExpanded: _openPanel == 'upcoming_expense',
                                                onTap: () => _toggleSidePanel('upcoming_expense'),
                                              ),
                                            ],
                                          ),
                                        ),

                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                          child: ExpectedAssetCard(drawerCashFlowDate: _drawerCashFlowDate),
                                        ),

                                        const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          child: Divider(color: Color(0xFFF1F5F9), height: 1),
                                        ),
                                        RecurringExpenseSection(drawerCashFlowDate: _drawerCashFlowDate),
                                        const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          child: Divider(color: Color(0xFFF1F5F9), height: 1),
                                        ),
                                        RecurringIncomeSection(drawerCashFlowDate: _drawerCashFlowDate),
                                        const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          child: Divider(color: Color(0xFFF1F5F9), height: 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: AccountsSection(),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: GestureDetector(
                                      onTap: () async {
                                        bool? confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            backgroundColor: const Color(0xFFFFFFFF),
                                            title: Text('데이터 초기화', style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w700, color: const Color(0xFFEF4444))),
                                            content: Text('모든 계좌 및 내역 데이터가 영구적으로 삭제됩니다. 계속하시겠습니까?', style: GoogleFonts.notoSansKr(color: const Color(0xFF64748B))),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('취소', style: GoogleFonts.notoSansKr(color: const Color(0xFF94A3B8)))),
                                              TextButton(
                                                onPressed: () => Navigator.pop(ctx, true),
                                                child: Text('초기화', style: GoogleFonts.notoSansKr(color: const Color(0xFFEF4444), fontWeight: FontWeight.w700)),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirm == true) {
                                          state.resetAllData();
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFEF2F2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.delete_forever, size: 18, color: Color(0xFFEF4444)),
                                            const SizedBox(width: 8),
                                            Text('모든 데이터 초기화', style: GoogleFonts.notoSansKr(color: const Color(0xFFEF4444), fontWeight: FontWeight.w600, fontSize: 13)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (isSideListOpen)
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    width: MediaQuery.of(context).size.width * 0.85 * 0.5,
                    child: DrawerSidePanel(dash: dash, openPanelType: _openPanel),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
