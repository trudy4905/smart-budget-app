import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../utils/helpers.dart';

class CashFlowHeaderWidget extends StatelessWidget {
  final DateTime drawerCashFlowDate;
  final Function(int) onChangeMonth;

  const CashFlowHeaderWidget({super.key, required this.drawerCashFlowDate, required this.onChangeMonth});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, color: Color(0xFF64748B)),
          onPressed: () => onChangeMonth(-1),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        Text('${drawerCashFlowDate.month}월 현금 흐름', style: GoogleFonts.notoSansKr(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
        IconButton(
          icon: const Icon(Icons.chevron_right, color: Color(0xFF64748B)),
          onPressed: () => onChangeMonth(1),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }
}

class CashFlowRowWidget extends StatelessWidget {
  final String type;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String title;
  final int amount;
  final bool isExpanded;
  final VoidCallback onTap;

  const CashFlowRowWidget({
    super.key, required this.type, required this.icon, required this.iconBgColor, required this.iconColor,
    required this.title, required this.amount, required this.isExpanded, required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 14, color: iconColor),
                ),
                const SizedBox(width: 12),
                Text(title, style: GoogleFonts.notoSansKr(fontSize: 13, color: const Color(0xFF334155), fontWeight: FontWeight.w600)),
                const Spacer(),
                Text('${formatNumber(amount)}원', style: GoogleFonts.notoSansKr(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
                const SizedBox(width: 8),
                Icon(Icons.keyboard_arrow_right, size: 16, color: isExpanded ? const Color(0xFF0F172A) : const Color(0xFF94A3B8)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
