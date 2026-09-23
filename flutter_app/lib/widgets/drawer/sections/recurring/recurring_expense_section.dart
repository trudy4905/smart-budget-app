import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../providers/app_state.dart';
import '../../../../models/transaction.dart';
import '../../../../utils/helpers.dart';
import '../../components/shared_drawer_components.dart';

class RecurringExpenseSection extends StatefulWidget {
  final DateTime drawerCashFlowDate;

  const RecurringExpenseSection({super.key, required this.drawerCashFlowDate});

  @override
  State<RecurringExpenseSection> createState() => _RecurringExpenseSectionState();
}

class _RecurringExpenseSectionState extends State<RecurringExpenseSection> {
  bool _isRecurringExpenseExpanded = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isRecurringExpenseExpanded = prefs.getBool('isRecurringExpenseExpanded') ?? true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final dash = state.getDashboardSummary(widget.drawerCashFlowDate.year, widget.drawerCashFlowDate.month);
        
        final Map<String, Transaction> recurringMap = {};
        for (final t in state.transactions) {
          if (t.isRecurring && t.recurringId != null && t.type == 'expense') {
            if (!state.selectedAccountIds.contains('all') && !state.selectedAccountIds.contains(t.accountId)) continue;
            recurringMap[t.recurringId!] = t;
          }
        }
        final recurringTxs = recurringMap.values.toList();
        final cards = state.accounts.where((a) => a.isCredit && a.paymentDay != null && (state.selectedAccountIds.contains('all') || state.selectedAccountIds.contains(a.id))).toList();
        
        int totalExpense = recurringTxs.fold(0, (sum, tx) => sum + (tx.amount ?? 0));
        for (final c in cards) {
          for (final info in dash.alreadyPaidCardList) {
            if (info.account.id == c.id) totalExpense += info.amount;
          }
          for (final info in dash.upcomingCardPayments) {
            if (info.account.id == c.id) totalExpense += info.amount;
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                setState(() => _isRecurringExpenseExpanded = !_isRecurringExpenseExpanded);
                SharedPreferences.getInstance().then((prefs) => prefs.setBool('isRecurringExpenseExpanded', _isRecurringExpenseExpanded));
              },
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('고정 지출 (${recurringTxs.length + cards.length})', style: GoogleFonts.notoSansKr(fontSize: 14, color: const Color(0xFF0F172A), fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Text(formatNumber(totalExpense), style: GoogleFonts.notoSansKr(fontSize: 14, color: const Color(0xFF0F172A), fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    Icon(_isRecurringExpenseExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right, size: 16, color: const Color(0xFF94A3B8)),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (recurringTxs.isEmpty && cards.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 36, top: 4, bottom: 12),
                      child: Text('내역 없음', style: GoogleFonts.notoSansKr(fontSize: 12, color: const Color(0xFF94A3B8))),
                    ),
                  ...recurringTxs.asMap().entries.map((e) {
                    final tx = e.value;
                    final txAccount = state.accounts.firstWhereOrNull((a) => a.id == tx.accountId);
                    return Column(
                      children: [
                        const Padding(padding: EdgeInsets.only(left: 20, right: 20), child: Divider(color: Color(0xFFF1F5F9), height: 1)),
                        RecurringItemWidget(
                          iconBgColor: const Color(0xFFFFF1F2),
                          iconColor: const Color(0xFFE11D48),
                          title: tx.memo.isNotEmpty ? '${tx.category} (${tx.memo})' : tx.category,
                          titleTag: (txAccount?.isCredit ?? false)
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4)),
                                  child: Text('신용', style: GoogleFonts.notoSansKr(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
                                )
                              : null,
                          subtitle: '${widget.drawerCashFlowDate.month}/${int.tryParse(tx.date.split('-').last) ?? 0}',
                          amount: tx.amount,
                          onDelete: () {
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                backgroundColor: const Color(0xFFFFFFFF),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                title: Text('고정 지출 삭제', style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w700, color: const Color(0xFFE11D48))),
                                content: Text('모든 일정에서 고정 항목이 삭제됩니다.', style: GoogleFonts.notoSansKr(color: const Color(0xFF64748B))),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context), child: Text('취소', style: GoogleFonts.notoSansKr(color: const Color(0xFF94A3B8)))),
                                  TextButton(
                                    onPressed: () {
                                      state.deleteRecurringTransactions(tx.recurringId!);
                                      Navigator.pop(context);
                                    },
                                    child: Text('삭제', style: GoogleFonts.notoSansKr(color: const Color(0xFFE11D48), fontWeight: FontWeight.w700)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  }),
                  ...cards.asMap().entries.map((e) {
                    final c = e.value;
                    final cardInfo = state.getCardPaymentInfo(c, widget.drawerCashFlowDate.year, widget.drawerCashFlowDate.month);
                    int cardPaymentAmount = cardInfo.amount;
                    
                    String subtitle = '${cardInfo.startStr}~${cardInfo.endStr} | ${cardInfo.paymentDateStr}';
                    Widget titleTag;
                    if (cardInfo.isFinalized) {
                      titleTag = Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(4)),
                        child: Text('확정', style: GoogleFonts.notoSansKr(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF2563EB))),
                      );
                    } else {
                      titleTag = Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4)),
                        child: Text('누적중', style: GoogleFonts.notoSansKr(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
                      );
                    }
                    
                    return Column(
                      children: [
                        const Padding(padding: EdgeInsets.only(left: 20, right: 20), child: Divider(color: Color(0xFFF1F5F9), height: 1)),
                        RecurringItemWidget(
                          iconBgColor: const Color(0xFFFFF1F2),
                          iconColor: const Color(0xFFE11D48),
                          title: '${c.name} 대금 결제',
                          titleTag: titleTag,
                          subtitle: subtitle,
                          amount: cardPaymentAmount,
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: 8),
                ],
              ),
              secondChild: const SizedBox(width: double.infinity),
              crossFadeState: _isRecurringExpenseExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        );
      }
    );
  }
}
