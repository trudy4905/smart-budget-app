import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../utils/helpers.dart';

class AssetSummaryCardUI extends StatelessWidget {
  final bool isAssetVisible;
  final DateTime assetReferenceDate;
  final int totalAssets;
  final VoidCallback onToggleVisibility;
  final void Function(DateTime date) onChangeDate;
  final Future<DateTime?> Function(BuildContext context, DateTime initialDate) onShowDatePicker;

  const AssetSummaryCardUI({
    super.key,
    required this.isAssetVisible,
    required this.assetReferenceDate,
    required this.totalAssets,
    required this.onToggleVisibility,
    required this.onChangeDate,
    required this.onShowDatePicker,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F6FC),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text('내 자산 현황', style: GoogleFonts.notoSansKr(fontSize: 14, color: const Color(0xFF0F172A), fontWeight: FontWeight.w700)),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: onToggleVisibility,
                      child: Icon(isAssetVisible ? Icons.visibility : Icons.visibility_off, size: 16, color: const Color(0xFF94A3B8)),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () async {
                    final picked = await onShowDatePicker(context, assetReferenceDate);
                    if (picked != null) {
                      onChangeDate(picked);
                    }
                  },
                  child: Row(
                    children: [
                      Text('${assetReferenceDate.year.toString().substring(2)}년 ${assetReferenceDate.month}월 ${assetReferenceDate.day}일 기준', style: GoogleFonts.notoSansKr(fontSize: 11, color: const Color(0xFF64748B))),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down, size: 14, color: Color(0xFF64748B)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: isAssetVisible ? 0 : 8, sigmaY: isAssetVisible ? 0 : 8),
              child: Text('${formatNumber(totalAssets)}원', style: GoogleFonts.notoSansKr(fontSize: 28, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A), letterSpacing: -0.5)),
            ),
          ],
        ),
      ),
    );
  }
}
