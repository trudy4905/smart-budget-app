import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_app/core/utils/helpers.dart';
import 'package:flutter_app/core/theme/app_colors.dart';

class CashFlowHeaderWidget extends StatelessWidget {
  final DateTime drawerCashFlowDate;
  final Function(int) onChangeMonth;

  const CashFlowHeaderWidget({
    super.key,
    required this.drawerCashFlowDate,
    required this.onChangeMonth,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => onChangeMonth(-1),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.chevron_left, color: AppColors.textSub, size: 18),
          ),
        ),
        Text(
          '${drawerCashFlowDate.month}월 현금 흐름',
          style: GoogleFonts.notoSansKr(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textMain,
          ),
        ),
        GestureDetector(
          onTap: () => onChangeMonth(1),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.chevron_right, color: AppColors.textSub, size: 18),
          ),
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
    super.key,
    required this.type,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.title,
    required this.amount,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFE2E8F0).withOpacity(0.7),
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 14, color: iconColor),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.notoSansKr(
                fontSize: 13,
                color: const Color(0xFF334155),
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              '${formatNumber(amount)}원',
              style: GoogleFonts.notoSansKr(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.keyboard_arrow_right,
              size: 16,
              color: isExpanded ? AppColors.textMain : AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }
}
