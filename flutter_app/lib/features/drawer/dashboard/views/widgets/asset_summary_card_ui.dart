import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_app/core/utils/helpers.dart';
import 'package:flutter_app/core/theme/app_colors.dart';

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
                    Text('내 자산 현황', style: GoogleFonts.notoSansKr(fontSize: 14, color: AppColors.textMain, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: onToggleVisibility,
                      child: Icon(isAssetVisible ? Icons.visibility : Icons.visibility_off, size: 16, color: AppColors.textHint),
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
                      Text('${assetReferenceDate.year.toString().substring(2)}년 ${assetReferenceDate.month}월 ${assetReferenceDate.day}일 기준', style: GoogleFonts.notoSansKr(fontSize: 11, color: AppColors.textSub)),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down, size: 14, color: AppColors.textSub),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: isAssetVisible ? 0 : 8, sigmaY: isAssetVisible ? 0 : 8),
              child: Text('${formatNumber(totalAssets)}원', style: GoogleFonts.notoSansKr(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textMain, letterSpacing: -0.5)),
            ),
          ],
        ),
      ),
    );
  }
}
