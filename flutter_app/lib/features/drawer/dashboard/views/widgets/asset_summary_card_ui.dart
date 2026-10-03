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
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F6FC),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: const Color(0xFF6366F1).withOpacity(0.05),
              blurRadius: 16,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: Colors.white.withOpacity(0.9),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      '내 자산 현황',
                      style: GoogleFonts.notoSansKr(
                        fontSize: 14,
                        color: AppColors.textMain,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: onToggleVisibility,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Icon(
                          isAssetVisible ? Icons.visibility : Icons.visibility_off,
                          size: 14,
                          color: AppColors.textSub,
                        ),
                      ),
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
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${assetReferenceDate.year.toString().substring(2)}년 ${assetReferenceDate.month}월 ${assetReferenceDate.day}일',
                          style: GoogleFonts.notoSansKr(
                            fontSize: 11,
                            color: AppColors.textSub,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Icon(Icons.keyboard_arrow_down, size: 14, color: AppColors.textSub),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ImageFiltered(
              imageFilter: ImageFilter.blur(
                sigmaX: isAssetVisible ? 0 : 8,
                sigmaY: isAssetVisible ? 0 : 8,
              ),
              child: Text(
                '${formatNumber(totalAssets)}원',
                style: GoogleFonts.notoSansKr(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMain,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
