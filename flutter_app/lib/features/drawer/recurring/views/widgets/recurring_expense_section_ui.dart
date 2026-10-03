import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_app/features/home/add_transaction/models/transaction.dart';
import 'package:flutter_app/features/drawer/accounts/models/account.dart';
import 'package:flutter_app/features/categories/models/category_info.dart';
import 'package:flutter_app/core/utils/helpers.dart';
import 'package:flutter_app/features/drawer/dashboard/models/dashboard_summary.dart' show CardPaymentInfo;
import 'package:flutter_app/features/drawer/recurring/views/widgets/recurring_item_widget.dart';
import 'package:flutter_app/core/theme/app_colors.dart';

class RecurringExpenseSectionUI extends StatelessWidget {
  final bool isExpanded;
  final int totalExpense;
  final List<Transaction> recurringTxs;
  final List<Account> cards;
  final int year;
  final int month;
  final Account? Function(String accountId) getAccount;
  final CardPaymentInfo Function(Account card) getCardPaymentInfo;
  final CategoryInfo Function(String category) getCategoryInfo;
  final VoidCallback onToggleExpanded;
  final void Function(String recurringId) onDelete;

  const RecurringExpenseSectionUI({
    super.key,
    required this.isExpanded,
    required this.totalExpense,
    required this.recurringTxs,
    required this.cards,
    required this.year,
    required this.month,
    required this.getAccount,
    required this.getCardPaymentInfo,
    required this.getCategoryInfo,
    required this.onToggleExpanded,
    required this.onDelete,
  });

  void _confirmDelete(BuildContext context, String recurringId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '고정 지출 삭제',
          style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w700, color: AppColors.expense),
        ),
        content: Text(
          '모든 일정에서 고정 항목이 삭제됩니다.',
          style: GoogleFonts.notoSansKr(color: AppColors.textSub),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소', style: GoogleFonts.notoSansKr(color: AppColors.textHint)),
          ),
          TextButton(
            onPressed: () {
              onDelete(recurringId);
              Navigator.pop(context);
            },
            child: Text(
              '삭제',
              style: GoogleFonts.notoSansKr(color: AppColors.expense, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int displayedItemCount = recurringTxs.length + cards.length;

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
                const Icon(Icons.repeat_rounded, size: 14, color: AppColors.expense),
                const SizedBox(width: 6),
                Text(
                  '고정 지출 ($displayedItemCount)',
                  style: GoogleFonts.notoSansKr(fontSize: 14, color: AppColors.textMain, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Text(
                  formatNumber(totalExpense),
                  style: GoogleFonts.notoSansKr(fontSize: 14, color: AppColors.textMain, fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 8),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                  size: 16,
                  color: AppColors.textHint,
                ),
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
                  child: Text('내역 없음', style: GoogleFonts.notoSansKr(fontSize: 12, color: AppColors.textHint)),
                ),
              ...recurringTxs.where((tx) => getAccount(tx.accountId)?.isCredit != true).toList().asMap().entries.map((e) {
                final tx = e.value;
                final catInfo = getCategoryInfo(tx.category);
                final parts = tx.date.split('-');
                final regYear = parts.isNotEmpty ? int.tryParse(parts[0]) ?? year : year;
                final regMonth = parts.length >= 2 ? int.tryParse(parts[1]) ?? month : month;
                final txDay = parts.length >= 3 ? int.tryParse(parts[2]) ?? 0 : 0;

                bool isPast = (year < regYear) || (year == regYear && month < regMonth);
                final int displayAmount = isPast ? 0 : tx.amount;

                return Column(
                  children: [
                    const Padding(padding: EdgeInsets.only(left: 8, right: 8), child: Divider(color: AppColors.background, height: 1)),
                    RecurringItemWidget(
                      emoji: catInfo.emoji,
                      title: tx.memo.isNotEmpty ? '${tx.category} (${tx.memo})' : tx.category,
                      subtitle: '$month/$txDay',
                      amount: displayAmount,
                      onDelete: tx.recurringId != null ? () => _confirmDelete(context, tx.recurringId!) : null,
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
                    child: Text('확정', style: GoogleFonts.notoSansKr(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.secondary)),
                  );
                } else {
                  titleTag = Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(4)),
                    child: Text('누적중', style: GoogleFonts.notoSansKr(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSub)),
                  );
                }

                final cardRecurringTxs = cardInfo.recurringTxs;

                return Column(
                  children: [
                    const Padding(padding: EdgeInsets.only(left: 8, right: 8), child: Divider(color: AppColors.background, height: 1)),
                    RecurringItemWidget(
                      icon: Icons.credit_card_rounded,
                      iconColor: AppColors.secondary,
                      title: '${c.name} 대금 결제',
                      titleTag: titleTag,
                      subtitle: subtitle,
                      amount: cardPaymentAmount,
                    ),
                    ...cardRecurringTxs.map((tx) {
                      final subCatInfo = getCategoryInfo(tx.category);
                      final parts = tx.date.split('-');
                      final txMonth = parts.length >= 2 ? int.tryParse(parts[1]) ?? month : month;
                      final txDay = parts.length >= 3 ? int.tryParse(parts[2]) ?? 0 : 0;

                      return Column(
                        children: [
                          const Padding(padding: EdgeInsets.only(left: 8, right: 8), child: Divider(color: AppColors.background, height: 1)),
                          RecurringItemWidget(
                            isSubItem: true,
                            emoji: subCatInfo.emoji,
                            title: tx.memo.isNotEmpty ? '${tx.category} (${tx.memo})' : tx.category,
                            subtitle: '$txMonth/$txDay',
                            amount: tx.amount,
                            onDelete: tx.recurringId != null ? () => _confirmDelete(context, tx.recurringId!) : null,
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
