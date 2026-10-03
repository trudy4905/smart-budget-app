import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_app/features/home/add_transaction/models/transaction.dart';
import 'package:flutter_app/features/categories/models/category_info.dart';
import 'package:flutter_app/core/utils/helpers.dart';
import 'package:flutter_app/features/drawer/recurring/views/widgets/recurring_item_widget.dart';
import 'package:flutter_app/core/theme/app_colors.dart';

class RecurringIncomeSectionUI extends StatelessWidget {
  final bool isExpanded;
  final int totalIncome;
  final List<Transaction> recurringTxs;
  final int month;
  final CategoryInfo Function(String category)? getCategoryInfo;
  final VoidCallback onToggleExpanded;
  final void Function(String recurringId) onDelete;

  const RecurringIncomeSectionUI({
    super.key,
    required this.isExpanded,
    required this.totalIncome,
    required this.recurringTxs,
    required this.month,
    this.getCategoryInfo,
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
          '고정 수입 삭제',
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
                const Icon(Icons.repeat_rounded, size: 14, color: Color(0xFF059669)),
                const SizedBox(width: 6),
                Text(
                  '고정 수입 (${recurringTxs.length})',
                  style: GoogleFonts.notoSansKr(fontSize: 14, color: AppColors.textMain, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Text(
                  formatNumber(totalIncome),
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
              if (recurringTxs.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 24, top: 4, bottom: 12),
                  child: Text('내역 없음', style: GoogleFonts.notoSansKr(fontSize: 12, color: AppColors.textHint)),
                ),
              ...recurringTxs.asMap().entries.map((e) {
                final tx = e.value;
                final catEmoji = getCategoryInfo?.call(tx.category).emoji;

                return Column(
                  children: [
                    const Padding(padding: EdgeInsets.only(left: 8, right: 8), child: Divider(color: AppColors.background, height: 1)),
                    RecurringItemWidget(
                      emoji: catEmoji,
                      title: tx.memo.isNotEmpty ? '${tx.category} (${tx.memo})' : tx.category,
                      subtitle: '$month/${int.tryParse(tx.date.split('-').last) ?? 0}',
                      amount: tx.amount,
                      onDelete: tx.recurringId != null ? () => _confirmDelete(context, tx.recurringId!) : null,
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
