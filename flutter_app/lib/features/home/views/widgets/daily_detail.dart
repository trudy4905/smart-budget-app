import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_app/features/home/add_transaction/models/transaction.dart';
import 'package:flutter_app/features/drawer/accounts/models/account.dart';
import 'package:flutter_app/features/categories/models/category_info.dart';
import 'package:flutter_app/core/utils/helpers.dart';
import 'package:flutter_app/core/theme/app_colors.dart';

class DailyDetail extends StatelessWidget {
  final String selectedDateStr;
  final List<Transaction> transactions;
  final List<Account> accounts;
  final CategoryInfo Function(String category) getCategoryInfo;
  final void Function(String id) onDeleteTransaction;
  final void Function(String recurringId) onDeleteRecurringTransactions;

  const DailyDetail({
    super.key,
    required this.selectedDateStr,
    required this.transactions,
    required this.accounts,
    required this.getCategoryInfo,
    required this.onDeleteTransaction,
    required this.onDeleteRecurringTransactions,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = selectedDateStr;
    final parts = dateStr.split('-');
    final dateObj = parts.length == 3
        ? DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]))
        : DateTime.now();
    final dayNames = ['일', '월', '화', '수', '목', '금', '토'];
    final titleText = '${dateObj.month}월 ${dateObj.day}일 (${dayNames[dateObj.weekday % 7]})';
    final txs = transactions;
    final dailyExpense = txs.where((t) => t.type == 'expense').fold(0, (s, t) => s + t.amount);
    final dailyIncome = txs.where((t) => t.type == 'income').fold(0, (s, t) => s + t.amount);
    final total = dailyIncome - dailyExpense;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(titleText, style: GoogleFonts.notoSansKr(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textMain)),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('수입 ₩${formatNumber(dailyIncome)}', style: GoogleFonts.notoSansKr(fontSize: 11, color: const Color(0xFF059669))),
                      const SizedBox(width: 6),
                      Text('지출 ₩${formatNumber(dailyExpense)}', style: GoogleFonts.notoSansKr(fontSize: 11, color: AppColors.expense)),
                      const SizedBox(width: 6),
                      Text('합계 ₩${formatNumber(total)}', style: GoogleFonts.notoSansKr(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMain)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: txs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.receipt_long_outlined, color: AppColors.divider, size: 40),
                      const SizedBox(height: 8),
                      Text('등록된 내역이 없습니다', style: GoogleFonts.notoSansKr(color: AppColors.textHint, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text('+ 항목 추가를 눌러 기록해보세요', style: GoogleFonts.notoSansKr(color: const Color(0xFFF8FAFC), fontSize: 11)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: txs.length,
                  itemBuilder: (context, i) => _TxItem(
                    tx: txs[i],
                    accounts: accounts,
                    getCategoryInfo: getCategoryInfo,
                    onDeleteTransaction: onDeleteTransaction,
                    onDeleteRecurringTransactions: onDeleteRecurringTransactions,
                  ),
                ),
        ),
      ],
    );
  }
}

class _TxItem extends StatelessWidget {
  final Transaction tx;
  final List<Account> accounts;
  final CategoryInfo Function(String category) getCategoryInfo;
  final void Function(String id) onDeleteTransaction;
  final void Function(String recurringId) onDeleteRecurringTransactions;

  const _TxItem({
    required this.tx,
    required this.accounts,
    required this.getCategoryInfo,
    required this.onDeleteTransaction,
    required this.onDeleteRecurringTransactions,
  });

  @override
  Widget build(BuildContext context) {
    final acc = accounts.firstWhereOrNull((a) => a.id == tx.accountId);
    final catInfo = getCategoryInfo(tx.category);
    final isExpense = tx.type == 'expense';
    final amountColor = isExpense ? AppColors.expense : const Color(0xFF059669);
    final accLabel = acc != null
        ? (acc.isCredit ? '💳[신용] ${acc.name}' : acc.isDebit ? '💳[체크] ${acc.name}' : '🏦 ${acc.name}')
        : '미지정 결제수단';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: catInfo.color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: Center(child: Text(catInfo.emoji, style: const TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.memo.isNotEmpty ? '${tx.category} (${tx.memo})' : tx.category,
                    style: GoogleFonts.notoSansKr(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMain),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(accLabel,
                    style: GoogleFonts.notoSansKr(fontSize: 10, color: AppColors.textHint),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${isExpense ? '-' : '+'}₩${formatNumber(tx.amount)}',
                  style: GoogleFonts.notoSansKr(fontSize: 13, fontWeight: FontWeight.w700, color: amountColor)),
              const SizedBox(height: 4),
              if (!tx.isSettlement)
                GestureDetector(
                  onTap: () => _confirmDelete(context, tx),
                  child: const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(Icons.delete_outline, size: 16, color: AppColors.textHint),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Transaction tx) {
    if (tx.isRecurring && tx.recurringId != null) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('고정 지출 삭제', style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w700, color: AppColors.textMain)),
          content: Text('이 항목은 매달 반복되는 고정 지출입니다.\n어떻게 삭제하시겠습니까?', style: GoogleFonts.notoSansKr(color: AppColors.textSub)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('취소', style: GoogleFonts.notoSansKr(color: AppColors.textHint))),
            TextButton(
              onPressed: () { onDeleteTransaction(tx.id); Navigator.pop(context); },
              child: Text('이 항목만', style: GoogleFonts.notoSansKr(color: AppColors.expense, fontWeight: FontWeight.w700)),
            ),
            TextButton(
              onPressed: () { onDeleteRecurringTransactions(tx.recurringId!); Navigator.pop(context); },
              child: Text('모든 일정', style: GoogleFonts.notoSansKr(color: AppColors.expense, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('삭제', style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w700, color: AppColors.textMain)),
          content: Text('해당 내역을 삭제하시겠습니까?', style: GoogleFonts.notoSansKr(color: AppColors.textSub)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('취소', style: GoogleFonts.notoSansKr(color: AppColors.textHint))),
            TextButton(
              onPressed: () { onDeleteTransaction(tx.id); Navigator.pop(context); },
              child: Text('삭제', style: GoogleFonts.notoSansKr(color: AppColors.expense, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
    }
  }
}
