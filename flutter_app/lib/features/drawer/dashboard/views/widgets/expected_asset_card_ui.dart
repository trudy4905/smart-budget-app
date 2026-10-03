import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_app/core/utils/helpers.dart';
import 'package:flutter_app/core/theme/app_colors.dart';

class ExpectedAssetCardUi extends StatelessWidget {
  final int month;
  final int expectedBalance;
  final int remainingBalance;

  const ExpectedAssetCardUi({
    super.key,
    required this.month,
    required this.expectedBalance,
    required this.remainingBalance,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2.5),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFBBF7D0).withOpacity(0.8),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            padding: EdgeInsets.zero,
            child: Image.asset('assets/expected_assets_icon.png', fit: BoxFit.contain),
          ),
          const SizedBox(width: 8),
          Text(
            '$month월 예상 자산',
            style: GoogleFonts.notoSansKr(
              fontSize: 14,
              color: AppColors.textMain,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${formatNumber(expectedBalance)}원',
                style: GoogleFonts.notoSansKr(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF059669),
                ),
              ),
              Text(
                '${remainingBalance > 0 ? '+' : ''}${formatNumber(remainingBalance)}원',
                style: GoogleFonts.notoSansKr(
                  fontSize: 11,
                  color: const Color(0xFF059669),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
