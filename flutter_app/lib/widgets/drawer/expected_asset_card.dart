import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../utils/helpers.dart';

class ExpectedAssetCard extends StatelessWidget {
  final DateTime drawerCashFlowDate;
  
  const ExpectedAssetCard({super.key, required this.drawerCashFlowDate});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final dash = state.getDashboardSummary(drawerCashFlowDate.year, drawerCashFlowDate.month);
        final expectedBalance = state.getExpectedNetAssetAtEnd(drawerCashFlowDate.year, drawerCashFlowDate.month);
        
        return Container(
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
              Text('${drawerCashFlowDate.month}월 예상 자산', style: GoogleFonts.notoSansKr(fontSize: 15, color: const Color(0xFF0F172A), fontWeight: FontWeight.w600)),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${formatNumber(expectedBalance)}원', style: GoogleFonts.notoSansKr(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF059669))),
                  Text('${dash.remaining > 0 ? '+' : ''}${formatNumber(dash.remaining)}원', style: GoogleFonts.notoSansKr(fontSize: 11, color: const Color(0xFF059669))),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
