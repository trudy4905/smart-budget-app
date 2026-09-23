import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_state.dart';
import '../models/transaction.dart';
import '../models/account.dart';
import '../utils/helpers.dart';

/// Calendar grid widget
class CalendarGrid extends StatelessWidget {
  final AppState state;
  const CalendarGrid({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final year = state.currentDate.year;
    final month = state.currentDate.month;
    final firstDay = DateTime(year, month, 1);
    final startDow = firstDay.weekday % 7;
    final totalDays = DateTime(year, month + 1, 0).day;
    final prevMonthDays = DateTime(year, month, 0).day;
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final rows = ((startDow + totalDays) / 7).ceil();
    final dayHeaders = ['일', '월', '화', '수', '목', '금', '토'];

    return Container(
      color: const Color(0xFFFFFFFF),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: List.generate(7, (i) => Expanded(
                child: Center(
                  child: Text(dayHeaders[i],
                      style: GoogleFonts.notoSansKr(
                        fontSize: 11,
                        color: i == 0 ? const Color(0xFFD93025) : i == 6 ? const Color(0xFF1A73E8) : const Color(0xFF70757A),
                        fontWeight: FontWeight.w500,
                      )),
                ),
              )),
            ),
          ),
          ...List.generate(rows, (row) {
            return Row(
              children: List.generate(7, (col) {
                final cellIdx = row * 7 + col;
                final dayOffset = cellIdx - startDow;

                int dayNum;
                String dateStr;
                bool isOtherMonth;

                if (cellIdx < startDow) {
                  dayNum = prevMonthDays - (startDow - cellIdx - 1);
                  final pm = month - 1 <= 0 ? 12 : month - 1;
                  final py = month - 1 <= 0 ? year - 1 : year;
                  dateStr = '$py-${pm.toString().padLeft(2, '0')}-${dayNum.toString().padLeft(2, '0')}';
                  isOtherMonth = true;
                } else if (dayOffset >= totalDays) {
                  dayNum = dayOffset - totalDays + 1;
                  final nm = month + 1 > 12 ? 1 : month + 1;
                  final ny = month + 1 > 12 ? year + 1 : year;
                  dateStr = '$ny-${nm.toString().padLeft(2, '0')}-${dayNum.toString().padLeft(2, '0')}';
                  isOtherMonth = true;
                } else {
                  dayNum = dayOffset + 1;
                  dateStr = '$year-${month.toString().padLeft(2, '0')}-${dayNum.toString().padLeft(2, '0')}';
                  isOtherMonth = false;
                }

                final isToday = dateStr == todayStr;
                final isSelected = dateStr == state.selectedDateStr;
                final txs = state.getTransactionsForDate(dateStr);

                return Expanded(
                  child: _CalendarCell(
                    dayNum: dayNum, dateStr: dateStr,
                    isOtherMonth: isOtherMonth, isToday: isToday,
                    isSelected: isSelected, txs: txs,
                    accounts: state.accounts,
                    onTap: () {
                      state.setSelectedDate(dateStr);
                      if (isOtherMonth) {
                        final parts = dateStr.split('-');
                        if (parts.length == 3) {
                          state.setCurrentDate(DateTime(int.parse(parts[0]), int.parse(parts[1]), 1));
                        }
                      }
                    },
                  ),
                );
              }),
            );
          }),
        ],
      ),
    );
  }
}

class _CalendarCell extends StatelessWidget {
  final int dayNum;
  final String dateStr;
  final bool isOtherMonth, isToday, isSelected;
  final List<Transaction> txs;
  final List<Account> accounts;
  final VoidCallback onTap;

  const _CalendarCell({
    required this.dayNum, required this.dateStr,
    required this.isOtherMonth, required this.isToday,
    required this.isSelected, required this.txs,
    required this.accounts, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD3E3FD).withOpacity(0.5) : Colors.transparent,
          border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
        ),
        child: Column(
          children: [
            const SizedBox(height: 4),
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                color: isToday ? const Color(0xFF1A73E8) : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text('$dayNum',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 11,
                      fontWeight: isToday || isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isToday ? const Color(0xFFFFFFFF) : (isOtherMonth ? const Color(0xFFD4D4D4) : const Color(0xFF3C4043)),
                    )),
              ),
            ),
            if (txs.isNotEmpty)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: _CellChips(txs: txs, accounts: accounts),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CellChips extends StatelessWidget {
  final List<Transaction> txs;
  final List<Account> accounts;
  const _CellChips({required this.txs, required this.accounts});

  @override
  Widget build(BuildContext context) {
    final visible = txs.take(2).toList();
    final overflow = txs.length - visible.length;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ...visible.map((t) => _Chip(tx: t, accounts: accounts)),
        if (overflow > 0)
          Container(
            margin: const EdgeInsets.only(top: 1),
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
            decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(3)),
            child: Text('+$overflow', style: GoogleFonts.notoSansKr(fontSize: 8, color: const Color(0xFF64748B))),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final Transaction tx;
  final List<Account> accounts;
  const _Chip({required this.tx, required this.accounts});

  @override
  Widget build(BuildContext context) {
    final acc = accounts.firstWhereOrNull((a) => a.id == tx.accountId);
    final isIncome = tx.type == 'income';
    final isCredit = acc != null && acc.isCredit;
    final isDebit = acc != null && acc.isDebit;

    Color chipColor;
    IconData iconData;
    
    if (isIncome) {
      chipColor = const Color(0xFF059669);
    } else {
      chipColor = isCredit ? const Color(0xFF2563EB) : (isDebit ? const Color(0xFFD97706) : const Color(0xFFE11D48));
    }
    
    if (isCredit) {
      iconData = Icons.credit_card;
    } else if (isDebit) {
      iconData = Icons.credit_score;
    } else {
      iconData = Icons.account_balance;
    }

    String text = isIncome ? '+${formatCompactNumber(tx.amount)}' : '-${formatCompactNumber(tx.amount)}';

    return Container(
      margin: const EdgeInsets.only(top: 1),
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      width: double.infinity,
      decoration: BoxDecoration(color: chipColor.withOpacity(0.15), borderRadius: BorderRadius.circular(2)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, size: 8, color: chipColor),
          const SizedBox(width: 2),
          Flexible(
            child: Text(text,
                style: GoogleFonts.notoSansKr(fontSize: 8, color: chipColor, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis, maxLines: 1),
          ),
        ],
      ),
    );
  }
}
