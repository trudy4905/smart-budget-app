import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../models/transaction.dart';
import '../../../../../../models/account.dart';
import '../../../../../../utils/helpers.dart';
import '../../../../../../providers/app_state.dart' show CardPaymentInfo;
import 'recurring_item_widget.dart';

class RecurringExpenseSectionUI extends StatelessWidget {
  final bool isExpanded;
  final int totalExpense;
  final List<Transaction> recurringTxs;
  final List<Account> cards;
  final int month;
  final Account? Function(String accountId) getAccount;
  final CardPaymentInfo Function(Account card) getCardPaymentInfo;
  final VoidCallback onToggleExpanded;
  final void Function(String recurringId) onDelete;

  const RecurringExpenseSectionUI({
    super.key,
    required this.isExpanded,
    required this.totalExpense,
    required this.recurringTxs,
    required this.cards,
    required this.month,
    required this.getAccount,
    required this.getCardPaymentInfo,
    required this.onToggleExpanded,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final nonCreditRecurringCount = recurringTxs.where((tx) => getAccount(tx.accountId)?.isCredit != true).length;
    int displayedItemCount = nonCreditRecurringCount + cards.length;
    for (final c in cards) {
      final info = getCardPaymentInfo(c);
      displayedItemCount += info.recurringTxs.length;
    }

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
                Text('고정 지출 ($displayedItemCount)', style: GoogleFonts.notoSansKr(fontSize: 14, color: const Color(0xFF0F172A), fontWeight: FontWeight.w700)),
                const Spacer(),
                Text(formatNumber(totalExpense), style: GoogleFonts.notoSansKr(fontSize: 14, color: const Color(0xFF0F172A), fontWeight: FontWeight.w700)),
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
              if (recurringTxs.isEmpty && cards.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 24, top: 4, bottom: 12),
                  child: Text('내역 없음', style: GoogleFonts.notoSansKr(fontSize: 12, color: const Color(0xFF94A3B8))),
                ),
              ...recurringTxs.where((tx) => getAccount(tx.accountId)?.isCredit != true).toList().asMap().entries.map((e) {
                final tx = e.value;
                final txAccount = getAccount(tx.accountId);
                final parts = tx.date.split('-');
                final txMonth = parts.length >= 2 ? int.tryParse(parts[1]) ?? month : month;
                final txDay = parts.length >= 3 ? int.tryParse(parts[2]) ?? 0 : 0;

                return Column(
                  children: [
                    const Padding(padding: EdgeInsets.only(left: 8, right: 8), child: Divider(color: Color(0xFFF1F5F9), height: 1)),
                    RecurringItemWidget(
                      icon: txAccount == null ? Icons.calendar_today : (txAccount.isBank ? Icons.account_balance : Icons.credit_card),
                      iconBgColor: const Color(0xFFFFF1F2),
                      iconColor: const Color(0xFFE11D48),
                      title: tx.memo.isNotEmpty ? '${tx.category} (${tx.memo})' : tx.category,
                      subtitle: '$txMonth/$txDay',
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
              ...cards.asMap().entries.map((e) {
                final c = e.value;
                final cardInfo = getCardPaymentInfo(c);
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
                
                final cardRecurringTxs = cardInfo.recurringTxs;

                return Column(
                  children: [
                    const Padding(padding: EdgeInsets.only(left: 8, right: 8), child: Divider(color: Color(0xFFF1F5F9), height: 1)),
                    RecurringItemWidget(
                      icon: Icons.credit_card,
                      iconBgColor: const Color(0xFFFFF1F2),
                      iconColor: const Color(0xFFE11D48),
                      title: '${c.name} 대금 결제',
                      titleTag: titleTag,
                      subtitle: subtitle,
                      amount: cardPaymentAmount,
                    ),
                    ...cardRecurringTxs.map((tx) {
                      final parts = tx.date.split('-');
                      final txMonth = parts.length >= 2 ? int.tryParse(parts[1]) ?? month : month;
                      final txDay = parts.length >= 3 ? int.tryParse(parts[2]) ?? 0 : 0;

                      return Column(
                        children: [
                          const Padding(padding: EdgeInsets.only(left: 8, right: 8), child: Divider(color: Color(0xFFF1F5F9), height: 1)),
                          RecurringItemWidget(
                            isSubItem: true,
                            icon: Icons.credit_card,
                            iconBgColor: const Color(0xFFFFF1F2).withOpacity(0.5),
                            iconColor: const Color(0xFFE11D48).withOpacity(0.5),
                            title: tx.memo.isNotEmpty ? '${tx.category} (${tx.memo})' : tx.category,
                            subtitle: '$txMonth/$txDay',
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
