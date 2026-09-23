import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../providers/app_state.dart';
import '../../../../../utils/helpers.dart';

class DrawerSidePanel extends StatelessWidget {
  final DashboardSummary dash;
  final String openPanelType;

  const DrawerSidePanel({super.key, required this.dash, required this.openPanelType});

  @override
  Widget build(BuildContext context) {
    String title = '';
    List<Widget> children = [];

    List<_SortItem> sortItems = [];

    if (openPanelType == 'income') {
      title = '?˜ìž… ?´ì—­';
      sortItems = dash.alreadyReceivedIncomeList.map((tx) => _SortItem(day: tx.date.day, date: tx.date, category: tx.category, memo: tx.memo, amount: tx.amount, color: const Color(0xFF059669))).toList();
    } else if (openPanelType == 'expense') {
      title = 'ì§€ì¶??´ì—­';
      sortItems = [
        ...dash.alreadyPaidFixedList.map((tx) => _SortItem(day: tx.date.day, date: tx.date, category: tx.category, memo: tx.memo, amount: tx.amount, color: const Color(0xFFE11D48))),
        ...dash.alreadyPaidCashDebitList.map((tx) => _SortItem(day: tx.date.day, date: tx.date, category: tx.category, memo: tx.memo, amount: tx.amount, color: const Color(0xFFE11D48))),
        ...dash.alreadyPaidCardList.map((c) => _SortItem(day: int.parse(c.paymentDateStr.split('/')[1]), date: c.paymentDateStr, category: '${c.account.name} ?€ê¸?, memo: '', amount: c.amount, color: const Color(0xFFE11D48))),
      ];
    } else if (openPanelType == 'upcoming_income') {
      title = '?ˆì • ?˜ìž… ?´ì—­';
      sortItems = dash.upcomingIncomeList.map((e) => _SortItem(day: int.parse(e.dateStr.split('/')[1]), date: e.dateStr, category: e.tx.category, memo: e.tx.memo, amount: e.tx.amount, color: const Color(0xFFD97706))).toList();
    } else if (openPanelType == 'upcoming_expense') {
      title = '?ˆì • ì§€ì¶??´ì—­';
      sortItems = [
        ...dash.upcomingExpenseList.map((e) => _SortItem(day: int.parse(e.dateStr.split('/')[1]), date: e.dateStr, category: e.tx.category, memo: e.tx.memo, amount: e.tx.amount, color: const Color(0xFF7C3AED))),
        ...dash.upcomingCardPayments.map((c) => _SortItem(day: int.parse(c.paymentDateStr.split('/')[1]), date: c.paymentDateStr, category: '${c.account.name} ?ˆì •?€ê¸?, memo: '', amount: c.amount, color: const Color(0xFF7C3AED))),
      ];
    }

    sortItems.sort((a, b) => a.day.compareTo(b.day));
    children = sortItems.map((item) => _buildListItem(item.date, item.category, item.memo, item.amount, item.color)).toList();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(-2, 0)),
        ],
        border: const Border(left: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0)))),
            child: Text(title, style: GoogleFonts.notoSansKr(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
          ),
          Expanded(
            child: children.isEmpty
                ? Center(child: Text('?´ì—­ ?†ìŒ', style: GoogleFonts.notoSansKr(color: const Color(0xFF94A3B8))))
                : ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: children,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(String date, String title, String memo, int? amount, Color amountColor) {
    String formattedDate = date;
    if (date.contains('-')) {
      final parts = date.split('-');
      if (parts.length >= 3) {
        formattedDate = '${parts[1]}/${parts[2]}';
      }
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(formattedDate, style: GoogleFonts.notoSansKr(fontSize: 11, color: const Color(0xFF94A3B8))),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.notoSansKr(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF334155))),
                if (memo.isNotEmpty)
                  Text(memo, style: GoogleFonts.notoSansKr(fontSize: 10, color: const Color(0xFF94A3B8))),
              ],
            ),
          ),
          Text(amount != null ? formatNumber(amount) : '', style: GoogleFonts.notoSansKr(fontSize: 12, fontWeight: FontWeight.w700, color: amountColor)),
        ],
      ),
    );
  }
}

class _SortItem {
  final int day;
  final dynamic date;
  final String category;
  final String memo;
  final int amount;
  final Color color;
  _SortItem({required this.day, required this.date, required this.category, required this.memo, required this.amount, required this.color});
}

