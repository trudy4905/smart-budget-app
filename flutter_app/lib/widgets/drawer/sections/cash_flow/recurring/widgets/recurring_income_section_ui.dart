import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../models/transaction.dart';
import '../../../../../../utils/helpers.dart';
import 'recurring_item_widget.dart';

class RecurringIncomeSectionUI extends StatelessWidget {
  final bool isExpanded;
  final int totalIncome;
  final List<Transaction> recurringTxs;
  final int month;
  final VoidCallback onToggleExpanded;
  final void Function(String recurringId) onDelete;

  const RecurringIncomeSectionUI({
    super.key,
    required this.isExpanded,
    required this.totalIncome,
    required this.recurringTxs,
    required this.month,
    required this.onToggleExpanded,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onToggleExpanded,
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
                Icon(isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right, size: 16, color: const Color(0xFF94A3B8)),
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
                      subtitle: '$month/${int.tryParse(tx.date.split('-').last) ?? 0}',
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
                                  onDelete(tx.recurringId!);
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
          crossFadeState: isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }
}
