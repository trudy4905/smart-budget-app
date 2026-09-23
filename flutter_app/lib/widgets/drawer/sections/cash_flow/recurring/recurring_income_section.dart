import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../providers/app_state.dart';
import '../../../../../models/transaction.dart';
import '../../../../../utils/helpers.dart';
import '../../components/shared_drawer_components.dart';

class RecurringIncomeSection extends StatefulWidget {
  final DateTime drawerCashFlowDate;

  const RecurringIncomeSection({super.key, required this.drawerCashFlowDate});

  @override
  State<RecurringIncomeSection> createState() => _RecurringIncomeSectionState();
}

class _RecurringIncomeSectionState extends State<RecurringIncomeSection> {
  bool _isRecurringIncomeExpanded = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isRecurringIncomeExpanded = prefs.getBool('isRecurringIncomeExpanded') ?? true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final Map<String, Transaction> recurringMap = {};
        for (final t in state.transactions) {
          if (t.isRecurring && t.recurringId != null && t.type == 'income') {
            if (!state.selectedAccountIds.contains('all') && !state.selectedAccountIds.contains(t.accountId)) continue;
            recurringMap[t.recurringId!] = t;
          }
        }
        final recurringTxs = recurringMap.values.toList();
        
        int totalIncome = recurringTxs.fold(0, (sum, tx) => sum + (tx.amount ?? 0));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                setState(() => _isRecurringIncomeExpanded = !_isRecurringIncomeExpanded);
                SharedPreferences.getInstance().then((prefs) => prefs.setBool('isRecurringIncomeExpanded', _isRecurringIncomeExpanded));
              },
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('고정 수입 (${recurringTxs.length})', style: GoogleFonts.notoSansKr(fontSize: 14, color: const Color(0xFF0F172A), fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Text(formatNumber(totalIncome), style: GoogleFonts.notoSansKr(fontSize: 14, color: const Color(0xFF0F172A), fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    Icon(_isRecurringIncomeExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right, size: 16, color: const Color(0xFF94A3B8)),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (recurringTxs.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 24, top: 4, bottom: 12),
                      child: Text('내역 없음', style: GoogleFonts.notoSansKr(fontSize: 12, color: const Color(0xFF94A3B8))),
                    ),
                  ...recurringTxs.asMap().entries.map((e) {
                    final tx = e.value;
                    return Column(
                      children: [
                        const Padding(padding: EdgeInsets.only(left: 8, right: 8), child: Divider(color: Color(0xFFF1F5F9), height: 1)),
                        RecurringItemWidget(
                          iconBgColor: const Color(0xFFECFDF5),
                          iconColor: const Color(0xFF059669),
                          title: tx.memo.isNotEmpty ? '${tx.category} (${tx.memo})' : tx.category,
                          subtitle: '${widget.drawerCashFlowDate.month}/${int.tryParse(tx.date.split('-').last) ?? 0}',
                          amount: tx.amount,
                          onDelete: () {
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                backgroundColor: const Color(0xFFFFFFFF),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                title: Text('고정 수입 삭제', style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w700, color: const Color(0xFFE11D48))),
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
                ],
              ),
              secondChild: const SizedBox(width: double.infinity),
              crossFadeState: _isRecurringIncomeExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        );
      }
    );
  }
}
