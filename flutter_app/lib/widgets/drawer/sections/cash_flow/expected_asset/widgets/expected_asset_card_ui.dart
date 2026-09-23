import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../utils/helpers.dart';

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
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4), // Lighter green
        borderRadius: BorderRadius.circular(12),
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
          Text('$month월 예상 자산', style: GoogleFonts.notoSansKr(fontSize: 15, color: const Color(0xFF0F172A), fontWeight: FontWeight.w600)),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${formatNumber(expectedBalance)}원', style: GoogleFonts.notoSansKr(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF059669))),
              Text('${remainingBalance > 0 ? '+' : ''}${formatNumber(remainingBalance)}원', style: GoogleFonts.notoSansKr(fontSize: 11, color: const Color(0xFF059669))),
            ],
          ),
        ],
      ),
    );
  }
}
