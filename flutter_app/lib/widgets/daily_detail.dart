import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_state.dart';
import '../models/transaction.dart';
import '../utils/helpers.dart';

class DailyDetail extends StatelessWidget {
  final AppState state;
  const DailyDetail({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final dateStr = state.selectedDateStr;
    final parts = dateStr.split('-');
    final dateObj = parts.length == 3
        ? DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]))
        : DateTime.now();
    final dayNames = ['일', '월', '화', '수', '목', '금', '토'];
    final titleText = '${dateObj.month}월 ${dateObj.day}일 (${dayNames[dateObj.weekday % 7]})';
    final txs = state.getTransactionsForDate(dateStr);
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
              Text(titleText, style: GoogleFonts.notoSansKr(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('수입 ₩${formatNumber(dailyIncome)}', style: GoogleFonts.notoSansKr(fontSize: 11, color: const Color(0xFF059669))),
                      const SizedBox(width: 6),
                      Text('지출 ₩${formatNumber(dailyExpense)}', style: GoogleFonts.notoSansKr(fontSize: 11, color: const Color(0xFFE11D48))),
                      const SizedBox(width: 6),
                      Text('합계 ₩${formatNumber(total)}', style: GoogleFonts.notoSansKr(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
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
                      const Icon(Icons.receipt_long_outlined, color: Color(0xFFE2E8F0), size: 40),
                      const SizedBox(height: 8),
                      Text('등록된 내역이 없습니다', style: GoogleFonts.notoSansKr(color: const Color(0xFF94A3B8), fontSize: 13)),
                      const SizedBox(height: 4),
                      Text('+ 항목 추가를 눌러 기록해보세요', style: GoogleFonts.notoSansKr(color: const Color(0xFFF8FAFC), fontSize: 11)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: txs.length,
                  itemBuilder: (context, i) => _TxItem(tx: txs[i], state: state),
                ),
        ),
      ],
    );
  }
}

class _TxItem extends StatelessWidget {
  final Transaction tx;
  final AppState state;
  const _TxItem({required this.tx, required this.state});

  @override
  Widget build(BuildContext context) {
    final acc = state.accounts.firstWhereOrNull((a) => a.id == tx.accountId);
    final catInfo = state.getCategoryInfo(tx.category);
    final isExpense = tx.type == 'expense';
    final amountColor = isExpense ? const Color(0xFFE11D48) : const Color(0xFF059669);
    final accLabel = acc != null
        ? (acc.isCredit ? '💳[신용] ${acc.name}' : acc.isDebit ? '💳[체크] ${acc.name}' : '🏦 ${acc.name}')
        : '미지정 결제수단';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
                    style: GoogleFonts.notoSansKr(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(accLabel,
                    style: GoogleFonts.notoSansKr(fontSize: 10, color: const Color(0xFF94A3B8)),
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
              GestureDetector(
                onTap: () => _confirmDelete(context, tx.id, state),
                child: const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Icon(Icons.delete_outline, size: 16, color: Color(0xFF94A3B8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id, AppState state) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFFFFFFF),
        title: Text('삭제', style: GoogleFonts.notoSansKr(color: const Color(0xFF0F172A))),
        content: Text('해당 내역을 삭제하시겠습니까?', style: GoogleFonts.notoSansKr(color: const Color(0xFF64748B))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('취소', style: GoogleFonts.notoSansKr(color: const Color(0xFF94A3B8)))),
          TextButton(
            onPressed: () { state.deleteTransaction(id); Navigator.pop(context); },
            child: Text('삭제', style: GoogleFonts.notoSansKr(color: const Color(0xFFE11D48))),
          ),
        ],
      ),
    );
  }
}
